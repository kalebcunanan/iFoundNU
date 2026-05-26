import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item_post.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/firestore_service.dart';
import '../widgets/item_card.dart';

class ChatScreen extends StatefulWidget {
  final ItemPost item;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({super.key, required this.item, required this.otherUserId, required this.otherUserName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _otherUserProfileUrl = '';
  bool _isResolved = false;

  @override
  void initState() {
    super.initState();

    // Set the initial status when the chat is opened
    _isResolved = widget.item.status == 'Resolved';

    // Fetch the other user's profile picture dynamically to ensure it's up-to-date
    _db.collection('users').doc(widget.otherUserId).get().then((doc) {
      if (doc.exists && mounted) {
        setState(() {
          _otherUserProfileUrl = doc.data()?['profileImageUrl'] ?? '';
        });
      }
    });
  }

  // Generates a unique Room ID based on the Item ID and User IDs.
  String get _chatRoomId {
    String currentId = _auth.currentUser?.uid ?? "";
    if (currentId == widget.item.reporterId) {
      return "${widget.item.id}_${widget.otherUserId}";
    } else {
      return "${widget.item.id}_$currentId";
    }
  }

  // Handles sending the message to the database via our FirestoreService
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    String messageText = _messageController.text.trim();
    _messageController.clear(); // Clear the text box immediately for better UX

    String currentId = _auth.currentUser?.uid ?? "";

    // Delegate the database writing to our service class (Clean Architecture)
    await FirestoreService().sendChatMessage(
      chatRoomId: _chatRoomId,
      messageText: messageText,
      currentUserId: currentId,
      itemReporterId: widget.item.reporterId,
      otherUserId: widget.otherUserId,
      itemId: widget.item.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = _auth.currentUser?.uid ?? "";
    bool isMine = currentUserId == widget.item.reporterId;

    // Automatically resets the unread message counter to 0 when the user opens this chat room
    if (currentUserId.isNotEmpty) {
      _db.collection('chats').doc(_chatRoomId).set({
        'unread_$currentUserId': 0,
      }, SetOptions(merge: true));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        toolbarHeight: 75,
        backgroundColor: const Color(0xFFf1f5f9),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.4),
        titleSpacing: 4,
        iconTheme: const IconThemeData(color: Color(0xFF232d74)),
        title: Row(
          children: [
            FutureBuilder<DocumentSnapshot>(
                future: _db.collection('users').doc(widget.otherUserId).get(),
                builder: (context, snapshot) {
                  String profileUrl = '';
                  if (snapshot.hasData && snapshot.data!.exists) {
                    profileUrl = (snapshot.data!.data() as Map<String, dynamic>)['profileImageUrl'] ?? '';
                  }
                  return CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFe2e8f0),
                    backgroundImage: profileUrl.isNotEmpty ? CachedNetworkImageProvider(profileUrl) : null,
                    child: profileUrl.isEmpty
                        ? Text(widget.otherUserName[0].toUpperCase(), style: GoogleFonts.firaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF94a3b8)))
                        : null,
                  );
                }
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.otherUserName, style: GoogleFonts.firaSans(color: const Color(0xFF232d74), fontWeight: FontWeight.bold, fontSize: 18))),
          ],
        ),
        actions: [
          // If the current user is the owner and the item is NOT resolved yet, show the Resolve button
          if (currentUserId == widget.item.reporterId && !_isResolved)
            Padding(
              padding: const EdgeInsets.only(right: 12.0, top: 10.0, bottom: 10.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16a34a),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: Text("Resolve", style: GoogleFonts.firaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text("Is this resolved?", style: GoogleFonts.firaSans(fontWeight: FontWeight.bold, color: const Color(0xFF232d74))),
                      content: Text(
                        widget.item.isLost
                            ? "Nabalik na ba sa'yo ang gamit mo sa tulong ng chat na ito?"
                            : "Naisauli mo na ba ang item sa kausap mo?",
                        style: GoogleFonts.firaSans(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Wait, cancel", style: GoogleFonts.firaSans(color: const Color(0xFF64748b))),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16a34a)),
                          onPressed: () async {
                            Navigator.pop(context); // Close the dialog
                            String result = await FirestoreService().markPostAsSolved(widget.item.id);

                            if (result == "Success" && mounted) {
                              // Optimistic UI update: Instantly hide the button without requiring a full page refresh
                              setState(() {
                                _isResolved = true;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Item successfully resolved! 🎉"),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: Text("Yes, resolved!", style: GoogleFonts.firaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // The Chat Stream: Listens to the specific room's messages subcollection in real-time
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('chats').doc(_chatRoomId).collection('messages').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF3772FF)));
                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // Chat starts from the bottom (latest messages first)
                  padding: const EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 15),
                  itemCount: messages.length + 1, // +1 is to accommodate the Item Card at the very top of the chat
                  itemBuilder: (context, index) {

                    // If it's the very last index visually at the top, render the Item Card
                    if (index == messages.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                        child: Row(
                          mainAxisAlignment: isMine ? MainAxisAlignment.start : MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (isMine) ...[
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFFe2e8f0),
                                // Kung wala siyang picture, fallback sa initial ng pangalan niya.
                                backgroundImage: _otherUserProfileUrl.isNotEmpty ? CachedNetworkImageProvider(_otherUserProfileUrl) : null,
                                child: _otherUserProfileUrl.isEmpty
                                    ? Text(
                                  widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : "?",
                                  style: GoogleFonts.firaSans(color: const Color(0xFF232d74), fontSize: 14, fontWeight: FontWeight.bold),
                                )
                                    : null, // Tinatago yung initial letter kapag may picture na nag-load
                              ),
                              const SizedBox(width: 8),
                            ],


                            // the other person's UI instantly updates the card to "RESOLVED" while they are chatting!
                            ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 250),
                                child: StreamBuilder<DocumentSnapshot>(
                                  stream: _db.collection('items').doc(widget.item.id).snapshots(),
                                  builder: (context, itemSnapshot) {

                                    ItemPost liveItem = widget.item; // Fallback to initial data

                                    if (itemSnapshot.hasData && itemSnapshot.data!.exists) {
                                      var data = itemSnapshot.data!.data() as Map<String, dynamic>;
                                      liveItem = ItemPost(
                                        id: itemSnapshot.data!.id,
                                        itemName: data['itemName'] ?? widget.item.itemName,
                                        location: data['location'] ?? widget.item.location,
                                        description: data['description'] ?? widget.item.description,
                                        isLost: data['isLost'] ?? widget.item.isLost,
                                        reporterId: data['reporterId'] ?? widget.item.reporterId,
                                        dateReported: (data['dateReported'] as Timestamp?)?.toDate() ?? widget.item.dateReported,
                                        imageUrl: data['imageUrl'] ?? widget.item.imageUrl,
                                        reporterName: data['reporterName'] ?? widget.item.reporterName,
                                        reporterProgram: data['reporterProgram'] ?? widget.item.reporterProgram,
                                        status: data['status'] ?? 'Open',
                                      );
                                    }

                                    return ItemCard(
                                      post: liveItem,
                                      showActions: false, // We hide edit/delete buttons inside the chat
                                      showProfile: false, // We hide the profile header inside the chat
                                    );
                                  },
                                )
                            ),
                          ],
                        ),
                      );
                    }

                    // Otherwise, render standard Chat Bubbles
                    var msgData = messages[index].data() as Map<String, dynamic>;
                    bool isMe = msgData['senderId'] == currentUserId;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe) ...[
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFFe2e8f0),
                              backgroundImage: _otherUserProfileUrl.isNotEmpty ? CachedNetworkImageProvider(_otherUserProfileUrl) : null,
                              child: _otherUserProfileUrl.isEmpty
                                  ? Text(
                                widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : "?",
                                style: GoogleFonts.firaSans(color: const Color(0xFF232d74), fontSize: 16, fontWeight: FontWeight.bold),
                              )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              // Prevent the message bubble from stretching across the entire screen
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? const Color(0xFF232d74) : const Color(0xFFe2e8f0),
                                borderRadius: BorderRadius.circular(20).copyWith(
                                  bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
                                  bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(20),
                                ),
                              ),
                              child: Text(
                                msgData['text'] ?? '',
                                style: GoogleFonts.firaSans(color: isMe ? Colors.white : const Color(0xFF0f172a), fontSize: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Input Field
          Container(
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end, // Aligns send button to bottom for multiline text
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        keyboardType: TextInputType.multiline,
                        minLines: 1,
                        maxLines: 6, // Allows box to expand dynamically like Messenger
                        decoration: InputDecoration(
                          hintText: "Write a message...",
                          hintStyle: const TextStyle(color: Color(0xFF94a3b8)),
                          filled: true,
                          fillColor: const Color(0xFFf1f5f9),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                              color: Color(0xFF232d74),
                              shape: BoxShape.circle
                          ),
                          child: const Icon(Icons.send_rounded, color: Color(0xFFf4cd25), size: 20),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/item_post.dart';
import 'chat_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  Future<Map<String, dynamic>> _fetchInboxData(String itemId, String otherUserId) async {
    var itemSnap = await FirebaseFirestore.instance.collection('items').doc(itemId).get();
    var userSnap = await FirebaseFirestore.instance.collection('users').doc(otherUserId).get();
    return {
      'itemSnap': itemSnap,
      'userSnap': userSnap,
    };
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFeef5fe),
      appBar: AppBar(
        backgroundColor: const Color(0xFF232d74),
        elevation: 0,
        title: Text("Messages", style: GoogleFonts.firaSans(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chats')
            .where(Filter.or(
            Filter('inquirerId', isEqualTo: currentUserId),
            Filter('posterId', isEqualTo: currentUserId)
        ))
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3772FF)));
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading messages."));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No messages yet.", style: GoogleFonts.firaSans(color: const Color(0xFF64748b), fontSize: 16)));
          }

          // LOCAL SORTING: Dito na natin inaayos from Newest to Oldest!
          var chats = snapshot.data!.docs.toList();
          chats.sort((a, b) {
            Timestamp tA = (a.data() as Map<String, dynamic>)['lastUpdated'] ?? Timestamp.now();
            Timestamp tB = (b.data() as Map<String, dynamic>)['lastUpdated'] ?? Timestamp.now();
            return tB.compareTo(tA);
          });

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              var chatData = chats[index].data() as Map<String, dynamic>;
              String itemId = chatData['itemId'] ?? '';
              String lastMessage = chatData['lastMessage'] ?? 'Sent a message';
              String inquirerId = chatData['inquirerId'] ?? '';
              String posterId = chatData['posterId'] ?? '';

              // Hanapin kung sino yung ka-chat mo
              String otherUserId = (currentUserId == inquirerId) ? posterId : inquirerId;

              //Check kung may unread messages para kay current user!
              int unreadCount = chatData['unread_$currentUserId'] ?? 0;
              bool hasUnread = unreadCount > 0;

              return FutureBuilder<Map<String, dynamic>>(
                future: _fetchInboxData(itemId, otherUserId),
                builder: (context, futureSnapshot) {
                  if (!futureSnapshot.hasData) return const SizedBox();

                  var itemSnap = futureSnapshot.data!['itemSnap'] as DocumentSnapshot;
                  var userSnap = futureSnapshot.data!['userSnap'] as DocumentSnapshot;

                  if (!itemSnap.exists) return const SizedBox();

                  String otherName = "NU Student";
                  String otherProfileUrl = "";

                  if (userSnap.exists) {
                    var userData = userSnap.data() as Map<String, dynamic>;
                    String rawName = userData['name'] ?? "NU Student";
                    otherName = rawName.split(' - ')[0].trim();
                    otherProfileUrl = userData['profileImageUrl'] ?? "";
                  }

                  var itemData = itemSnap.data() as Map<String, dynamic>;
                  ItemPost post = ItemPost(
                    id: itemSnap.id,
                    itemName: itemData['itemName'] ?? '',
                    location: itemData['location'] ?? '',
                    description: itemData['description'] ?? '',
                    isLost: itemData['isLost'] ?? true,
                    reporterId: itemData['reporterId'] ?? '',
                    dateReported: (itemData['dateReported'] as Timestamp).toDate(),
                    imageUrl: itemData['imageUrl'] ?? '',
                    reporterName: itemData['reporterName'] ?? '',
                    reporterProgram: itemData['reporterProgram'] ?? '',
                    //  Basahin ang status mula sa database!
                    status: itemData['status'] ?? 'Open',

                  );

                  //  Porma natin yung First Name • Item Type + Name
                  String firstName = otherName.split(' ')[0];
                  String itemType = post.isLost ? 'Lost' : 'Found';
                  String chatTitle = "$firstName • $itemType ${post.itemName}";

                  return Container(
                    margin: const EdgeInsets.only(top: 10, left: 15, right: 15),
                    decoration: BoxDecoration(
                      // Highlight sa background kung may unread!
                      color: hasUnread ? const Color(0xFFeef5fe) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasUnread ? const Color(0xFF232d74).withOpacity(0.3) : Colors.transparent,
                        width: 1,
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(0xFFe2e8f0),
                        backgroundImage: otherProfileUrl.isNotEmpty ? CachedNetworkImageProvider(otherProfileUrl) : null,
                        child: otherProfileUrl.isEmpty
                            ? Text(otherName[0].toUpperCase(), style: GoogleFonts.firaSans(fontWeight: FontWeight.bold, color: const Color(0xFF94a3b8), fontSize: 20))
                            : null,
                      ),
                      // Gamit na natin yung chatTitle na may Name at Item
                      title: Text(chatTitle, style: GoogleFonts.firaSans(fontWeight: hasUnread ? FontWeight.w900 : FontWeight.bold, fontSize: 16, color: const Color(0xFF0f172a))),
                      // Papakapal din natin ang last message kung unread
                      subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.firaSans(color: hasUnread ? const Color(0xFF0f172a) : const Color(0xFF64748b), fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal)),

                      // Kung may unread, magpapakita ng red badge circle, kung wala chevron arrow lang
                      trailing: hasUnread
                          ? Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Color(0xFFef4444), shape: BoxShape.circle),
                        child: Text(unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                          : const Icon(Icons.chevron_right_rounded, color: Color(0xFFcbd5e1)),
                      onTap: () {
                        // IPAPASA NA NATIN YUNG DETAILS NG KAUSAP MO SA CHAT SCREEN!
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(
                          item: post,
                          otherUserId: otherUserId,
                          otherUserName: otherName,
                        )));
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
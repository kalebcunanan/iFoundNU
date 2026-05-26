import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/item_post.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../screens/edit_item_screen.dart';

class ItemCard extends StatelessWidget {
  final ItemPost post;
  final bool showActions;
  final bool showProfile;

  const ItemCard({
    super.key,
    required this.post,
    this.showActions = true,
    this.showProfile = true,
  });

  String _timeAgo(DateTime? date) {
    if (date == null) return "Just now";
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return "${diff.inDays}d";
    if (diff.inHours > 0) return "${diff.inHours}h";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m";
    return "Just now";
  }

  @override
  Widget build(BuildContext context) {
    bool isResolved = post.status == 'Resolved';

    // Magiging Green kapag Resolved!
    Color tagBgColor = isResolved ? Colors.green.shade100 : (post.isLost ? const Color(0xFFfee2e2) : const Color(0xFFf4cd25));
    Color tagTextColor = isResolved ? Colors.green.shade800 : (post.isLost ? const Color(0xFFdc2626) : const Color(0xFF232d74));
    String tagText = isResolved ? "RESOLVED" : (post.isLost ? "LOST" : "FOUND");

    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    bool isMine = currentUserId == post.reporterId;

    return Container(
      margin: showActions ? const EdgeInsets.only(bottom: 25, left: 15, right: 15) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFe2e8f0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. FB-STYLE HEADER
            if (showProfile)
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Row(
                  children: [
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(post.reporterId).get(),
                      builder: (context, snapshot) {
                        String profileUrl = '';
                        if (snapshot.hasData && snapshot.data!.exists) {
                          profileUrl = (snapshot.data!.data() as Map<String, dynamic>)['profileImageUrl'] ?? '';
                        }
                        return CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFFeff6ff),
                          backgroundImage: profileUrl.isNotEmpty ? CachedNetworkImageProvider(profileUrl) : null,
                          child: profileUrl.isEmpty
                              ? Text(
                            post.reporterName.isNotEmpty ? post.reporterName[0].toUpperCase() : "?",
                            style: GoogleFonts.firaSans(color: const Color(0xFF3772FF), fontWeight: FontWeight.bold, fontSize: 18),
                          )
                              : null,
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.reporterName, style: GoogleFonts.firaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0f172a))),
                          Text(
                            "${post.reporterProgram} • ${_timeAgo(post.dateReported)}",
                            style: GoogleFonts.firaSans(fontSize: 13, color: const Color(0xFF64748b)),
                          ),
                        ],
                      ),
                    ),
                    // YUNG "LOST", "FOUND", OR "RESOLVED" TAG
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: tagBgColor, borderRadius: BorderRadius.circular(20)),
                      child: Text(tagText, style: GoogleFonts.firaSans(fontSize: 12, fontWeight: FontWeight.w900, color: tagTextColor)),
                    ),

                    // Itatago na natin ang 3-dots menu kapag Resolved na!
                    if (isMine && showActions && !isResolved)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF64748b)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => EditItemScreen(post: post)),
                            );
                          } else if (value == 'delete') {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: Text("Delete Post?", style: GoogleFonts.firaSans(fontWeight: FontWeight.bold, color: Colors.red)),
                                content: Text("Are you sure you want to delete this? Hindi na ito maibabalik.", style: GoogleFonts.firaSans()),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: GoogleFonts.firaSans(color: const Color(0xFF64748b)))),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      await FirebaseFirestore.instance.collection('items').doc(post.id).delete();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post deleted!"), backgroundColor: Colors.red));
                                      }
                                    },
                                    child: Text("Delete", style: GoogleFonts.firaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [const Icon(Icons.edit_rounded, size: 20, color: Color(0xFF232d74)), const SizedBox(width: 10), Text("Edit Post", style: GoogleFonts.firaSans())]),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [const Icon(Icons.delete_rounded, size: 20, color: Colors.red), const SizedBox(width: 10), Text("Delete Post", style: GoogleFonts.firaSans(color: Colors.red))]),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

            // 2. MALAKING PICTURE
            Stack(
              children: [
                if (post.imageUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            backgroundColor: Colors.black,
                            appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white), elevation: 0),
                            body: Center(
                              child: InteractiveViewer(panEnabled: true, minScale: 0.5, maxScale: 4.0, child: CachedNetworkImage(imageUrl: post.imageUrl)),
                            ),
                          ),
                        ),
                      );
                    },
                    child: SizedBox(
                      width: double.infinity,
                      height: 280,
                      child: CachedNetworkImage(
                        imageUrl: post.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(baseColor: const Color(0xFFe2e8f0), highlightColor: const Color(0xFFf8fafc), child: Container(width: double.infinity, height: 280, color: Colors.white)),
                        errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image_rounded, color: Color(0xFFcbd5e1), size: 50)),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity, height: 200, color: const Color(0xFFf8fafc),
                    child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 50, color: Color(0xFFcbd5e1))),
                  ),

                if (!showProfile)
                  Positioned(
                    top: 15, left: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: tagBgColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)]),
                      child: Text(tagText, style: GoogleFonts.firaSans(fontSize: 12, fontWeight: FontWeight.w900, color: tagTextColor)),
                    ),
                  ),
              ],
            ),

            // 3. DETAILS SA BABA
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF232d74)),
                      const SizedBox(width: 4),
                      Expanded(child: Text(post.location.toUpperCase(), style: GoogleFonts.firaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF232d74), letterSpacing: 0.5))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(post.itemName, style: GoogleFonts.firaSans(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF0f172a))),
                  const SizedBox(height: 6),
                  Text(post.description, style: GoogleFonts.firaSans(fontSize: 15, color: const Color(0xFF475569), height: 1.4)),
                ],
              ),
            ),

            // 4. DIVIDER AT ACTION BUTTONS
            if (showActions) ...[
              // Kung solved na siya o kung HINDI sayo ang post (Message), magpapakita ng divider
              if (!isMine || (isMine && post.isLost && !isResolved))
                const Divider(height: 1, color: Color(0xFFe2e8f0)),

              if (!isMine)
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(backgroundColor: const Color(0xFFeef5fe), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF232d74), size: 20),
                      label: Text("Message ${post.reporterName.split(' ')[0]}", style: GoogleFonts.firaSans(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF232d74))),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(item: post, otherUserId: post.reporterId, otherUserName: post.reporterName)));
                      },
                    ),
                  ),
                ),

              // Itatago na natin 'tong Mark as Solved kung `isResolved` na siya!
              if (isMine && post.isLost && !isResolved)
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(backgroundColor: const Color(0xFFf1f5f9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      icon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16a34a), size: 20),
                      label: Text("Mark as Solved", style: GoogleFonts.firaSans(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF16a34a))),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Text("Mark as Solved?", style: GoogleFonts.firaSans(fontWeight: FontWeight.bold)),
                            content: Text("Nahanap mo na ba ang gamit mo? Matatanggal na ito sa mga nawawalang items.", style: GoogleFonts.firaSans()),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: Text("Wait, cancel", style: GoogleFonts.firaSans(color: const Color(0xFF64748b)))),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16a34a)),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  String result = await FirestoreService().markPostAsSolved(post.id);
                                  if (result == "Success" && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post marked as solved!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
                                  }
                                },
                                child: Text("Yes, it's solved", style: GoogleFonts.firaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

              if (isMine && !post.isLost && !isResolved)
                const SizedBox(height: 15),
            ] else ...[
              const SizedBox(height: 15),
            ],
          ],
        ),
      ),
    );
  }
}
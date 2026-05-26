import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/item_post.dart';
import '../widgets/item_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text("No user logged in."));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFeef5fe), // NU LIGHT BLUE
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("My Profile", style: GoogleFonts.firaSans(color: const Color(0xFF0f172a), fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3772FF)));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3772FF)));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          String rawName = userData['name'] ?? "NU Student - 0000";
          List<String> nameParts = rawName.split(' - ');
          String displayName = nameParts[0];
          String studentId = nameParts.length > 1 ? nameParts[1] : "No ID";

          String program = userData['college'] ?? "Unknown Program";
          String section = userData['section'] ?? "";
          String profileImageUrl = userData['profileImageUrl'] ?? "";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. PROFILE PICTURE AREA
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFFe2e8f0),
                    backgroundImage: profileImageUrl.isNotEmpty ? CachedNetworkImageProvider(profileImageUrl) : null,
                    child: profileImageUrl.isEmpty
                        ? Text(displayName[0].toUpperCase(), style: GoogleFonts.firaSans(fontSize: 40, fontWeight: FontWeight.bold, color: const Color(0xFF94a3b8)))
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                // 2. NAME & STUDENT ID
                Center(child: Text(displayName, style: GoogleFonts.firaSans(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF0f172a)))),
                const SizedBox(height: 5),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFdbeafe), borderRadius: BorderRadius.circular(20)),
                    child: Text("ID: $studentId", style: GoogleFonts.firaSans(color: const Color(0xFF1e40af), fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 30),

                // 3. EDIT PROFILE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF232d74),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),

                    label: Text("Edit Profile", style: GoogleFonts.firaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                            currentProgram: program,
                            currentSection: section,
                            currentImageUrl: profileImageUrl,
                            displayName: displayName,
                            studentId: studentId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // 4. INFO CARDS
                _buildInfoTile(Icons.school_rounded, "Program", program),
                _buildInfoTile(Icons.class_rounded, "Section", section.isNotEmpty ? section : "Not specified"),
                _buildInfoTile(Icons.email_rounded, "NU Email", currentUser.email ?? ""),

                const SizedBox(height: 30),

                // 5. MY REPORTED ITEMS SECTION
                Row(
                  children: [

                    const SizedBox(width: 10),
                    Text("My Reported Items", style: GoogleFonts.firaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0f172a))),
                  ],
                ),
                const SizedBox(height: 15),

                // STREAM BUILDER PARA SA POSTS MO LANG
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('items')
                      .where('reporterId', isEqualTo: currentUser.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF232d74)));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.post_add_rounded, size: 50, color: Color(0xFFcbd5e1)),
                              const SizedBox(height: 10),
                              Text("You haven't reported anything yet.", style: GoogleFonts.firaSans(color: const Color(0xFF94a3b8))),
                            ],
                          ),
                        ),
                      );
                    }

                    var myPosts = snapshot.data!.docs;

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: myPosts.length,
                      itemBuilder: (context, index) {
                        var data = myPosts[index].data() as Map<String, dynamic>;

                        ItemPost post = ItemPost(
                          id: myPosts[index].id,
                          itemName: data['itemName'] ?? 'Unknown Item',
                          location: data['location'] ?? 'Unknown Location',
                          description: data['description'] ?? '',
                          isLost: data['isLost'] ?? true,
                          reporterId: data['reporterId'] ?? '',
                          dateReported: (data['dateReported'] as Timestamp).toDate(),
                          imageUrl: data['imageUrl'] ?? '',
                          reporterName: data['reporterName'] ?? 'NU Student',
                          reporterProgram: data['reporterProgram'] ?? 'Program',

                          // BUG FIX: Idinagdag na natin ang status dito para maging Green Tag!
                          status: data['status'] ?? 'Open',
                        );

                        return ItemCard(post: post);
                      },
                    );
                  },
                ),

                const SizedBox(height: 10),

                // 6. LOGOUT BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFef4444), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.logout_rounded, color: Color(0xFFef4444)),
                    label: Text("Log Out", style: GoogleFonts.firaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFef4444))),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFeef5fe), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFF232d74), size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.firaSans(fontSize: 12, color: const Color(0xFF64748b))),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.firaSans(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0f172a))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'report_item_screen.dart';
import 'inbox_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'home_feed_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeFeedScreen(),
    const SearchScreen(),
    const InboxScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),

      // 1. THE CHANGING BODY
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // 2. THE FLOATING ACTION BUTTON
      floatingActionButton: Transform.translate(
        offset: const Offset(0, 17),
        child: SizedBox(
          height: 56,
          width: 56,
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF232d74),
            foregroundColor: const Color(0xFFf4cd25),
            shape: const CircleBorder(),
            elevation: 4,
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 400),
                  pageBuilder: (context, animation, secondaryAnimation) => const ReportItemScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    var curve = Curves.easeOutBack;
                    var scaleTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
                    var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn));

                    return ScaleTransition(
                      scale: animation.drive(scaleTween),
                      alignment: Alignment.bottomCenter,
                      child: FadeTransition(
                        opacity: animation.drive(fadeTween),
                        child: child,
                      ),
                    );
                  },
                ),
              );
            },
            child: const Icon(Icons.add_rounded, size: 32),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 3. THE CUSTOM CURVED BOTTOM NAV BAR
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(icon: Icons.home_filled, index: 0, customSize: 30.0),
              _buildNavItem(icon: Icons.search_rounded, index: 1, customSize: 33.0),

              const SizedBox(width: 45),

              // Naka-StreamBuilder na para real-time babasahin ang unread count!)
              StreamBuilder<QuerySnapshot>(
                // Hahanapin natin lahat ng chats kung saan ikaw ang poster O ikaw ang inquirer
                  stream: FirebaseFirestore.instance.collection('chats')
                      .where(Filter.or(
                    Filter('posterId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? ""),
                    Filter('inquirerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? ""),
                  )).snapshots(),
                  builder: (context, snapshot) {
                    int totalUnreadCount = 0;
                    String myUid = FirebaseAuth.instance.currentUser?.uid ?? "";

                    // loop natin lahat ng chatsi-plus ang mga unread messages
                    if (snapshot.hasData) {
                      for (var doc in snapshot.data!.docs) {
                        var data = doc.data() as Map<String, dynamic>;
                        totalUnreadCount += (data['unread_$myUid'] ?? 0) as int;
                      }
                    }

                    // Ipasa yung na-compute na total sa badgeCount
                    return _buildNavItem(icon: Icons.chat_bubble_rounded, index: 2, customSize: 26.0, badgeCount: totalUnreadCount);
                  }
              ),

              _buildNavItem(icon: Icons.person_rounded, index: 3, customSize: 31.0),
            ],
          ),
        ),
      ),
    );
  }

  // REBUILT NAV ITEM PARA SA NATIVE FLUTTER BADGE!
  Widget _buildNavItem({required IconData icon, required int index, double customSize = 24, int badgeCount = 0}) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 50,
        height: 50,
        child: Center(
          // THE FLUTTER NATIVE BADGE WIDGET!
          child: Badge(
            isLabelVisible: badgeCount > 0,
            label: Text(
              badgeCount.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFFdc2626),
            offset: const Offset(4, -4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                size: isActive ? customSize + 4 : customSize,
                color: isActive ? const Color(0xFF232d74) : const Color(0xFF94a3b8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
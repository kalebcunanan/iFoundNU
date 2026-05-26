import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_post.dart';
import '../widgets/item_card.dart';
import 'package:provider/provider.dart';
import '../providers/feed_provider.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  // Toggle state: true = Lost, false = Found
  bool _showingLost = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFeef5fe),
      appBar: AppBar(
        backgroundColor: const Color(0xFFeef5fe),
        elevation: 0,
        toolbarHeight: 70,
        title: Image.asset(
          'assets/images/logo.png',
          width: 170,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 10), // Medyo binawasan ko ang top padding para mas dikit sa AppBar
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! > 0) {
                  setState(() => _showingLost = false);
                } else if (details.primaryVelocity! < 0) {
                  setState(() => _showingLost = true);
                }
              },
              child: Container(
                height: 50,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFe2e8f0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      alignment: _showingLost ? Alignment.centerLeft : Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: 0.5,
                        heightFactor: 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _showingLost = true),
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 250),
                                style: GoogleFonts.firaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: _showingLost ? const Color(0xFF232d74) : const Color(0xFF64748b),
                                ),
                                child: const Text("Lost"),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _showingLost = false),
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 250),
                                style: GoogleFonts.firaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: !_showingLost ? const Color(0xFF232d74) : const Color(0xFF64748b),
                                ),
                                child: const Text("Found"),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. FEED TITLE W/ ICON (Para hindi plain tignan)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Row(
              children: [

                Text(
                  _showingLost ? "Reported Lost Items" : "Reported Found Items",
                  style: GoogleFonts.firaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0f172a)),
                ),
              ],
            ),
          ),

          // 4. CLEAN ARCHITECTURE: Gumagamit na tayo ng Provider para sa Data!
          Expanded(
            child: StreamBuilder<List<ItemPost>>(
              // Dito natin tinawag yung Provider!
              stream: Provider.of<FeedProvider>(context, listen: false).getItemsStream(_showingLost),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF232d74)));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                var activeDocs = snapshot.data!; // Malinis na listahan na ito agad!

                return RefreshIndicator(
                  color: const Color(0xFF232d74),
                  backgroundColor: Colors.white,
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 800));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: 80),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: activeDocs.length,
                    itemBuilder: (context, index) {
                      // Wala nang raw map mapping dito, diretso ItemPost na!
                      return ItemCard(post: activeDocs[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 5. PREMIUM EMPTY STATE WIDGET
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showingLost ? Icons.inventory_2_outlined : Icons.inbox_outlined,
            size: 80,
            color: const Color(0xFFcbd5e1),
          ),
          const SizedBox(height: 15),
          Text(
            _showingLost ? "No lost items reported yet." : "No found items reported yet.",
            style: GoogleFonts.firaSans(color: const Color(0xFF94a3b8), fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
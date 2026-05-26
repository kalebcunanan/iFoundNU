import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_post.dart';
import '../widgets/item_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFeef5fe),
      appBar: AppBar(
        backgroundColor: const Color(0xFF232d74),
        elevation: 0,
        title: Text("Search Items", style: GoogleFonts.firaSans(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // 1. THE SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search for 'Wallet', 'ID', 'Keys'...",
                  hintStyle: const TextStyle(color: Color(0xFF94a3b8)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF232d74)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Color(0xFF94a3b8)),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = "");
                    },
                  )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),

          // 2. SEARCH RESULTS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('items').orderBy('dateReported', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF3772FF)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No items reported yet.", style: GoogleFonts.firaSans(color: const Color(0xFF64748b))));
                }

                var allDocs = snapshot.data!.docs;

                // Client-side filtering logic
                var filteredDocs = allDocs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;

                  // Extract fields and convert to lowercase for case-insensitive searching
                  String itemName = (data['itemName'] ?? '').toString().toLowerCase();
                  String description = (data['description'] ?? '').toString().toLowerCase();
                  String location = (data['location'] ?? '').toString().toLowerCase();
                  String status = data['status'] ?? 'Open';

                  //  Do not show items that are already 'Resolved' to keep the search results relevant.
                  if (status == 'Resolved') return false;

                  return itemName.contains(_searchQuery) ||
                      description.contains(_searchQuery) ||
                      location.contains(_searchQuery);
                }).toList();

                // Empty state handler if the search query yields no active results
                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 60, color: Color(0xFFcbd5e1)),
                        const SizedBox(height: 10),
                        Text("No results found for '$_searchQuery'", style: GoogleFonts.firaSans(color: const Color(0xFF64748b), fontSize: 16)),
                      ],
                    ),
                  );
                }

                // Render the filtered results
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 20, bottom: 80),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var data = filteredDocs[index].data() as Map<String, dynamic>;

                    //Converts raw Firestore map into our ItemPost model
                    ItemPost livePost = ItemPost(
                      id: filteredDocs[index].id,
                      itemName: data['itemName'] ?? 'Unknown Item',
                      location: data['location'] ?? 'Unknown Location',
                      description: data['description'] ?? '',
                      isLost: data['isLost'] ?? true,
                      reporterId: data['reporterId'] ?? '',
                      dateReported: (data['dateReported'] as Timestamp).toDate(),
                      imageUrl: data['imageUrl'] ?? '',
                      reporterName: data['reporterName'] ?? 'NU Student',
                      reporterProgram: data['reporterProgram'] ?? 'Program',
                      status: data['status'] ?? 'Open',
                    );

                    return ItemCard(post: livePost);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
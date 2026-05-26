import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_post.dart';

class FeedProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<ItemPost>> getItemsStream(bool isLost) {
    return _db.collection('items')
        .where('isLost', isEqualTo: isLost)
        .snapshots()
        .map((snapshot) {

      var posts = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return ItemPost(
          id: doc.id,
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
      }).toList();

      var activePosts = posts.where((post) => post.status != 'Resolved').toList();

      activePosts.sort((a, b) => b.dateReported.compareTo(a.dateReported));

      return activePosts;
    });
  }
}
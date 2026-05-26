import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/item_post.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> createItemPost({
    required String itemName,
    required String location,
    required String description,
    required bool isLost,
    File? imageFile,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return "Error: No user logged in!";

      // Default values
      String realName = "NU Student";
      String realProgram = "NU Clark Student";

      try {
        DocumentSnapshot userDoc = await _db.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>;

          String rawName = userData['name'] ?? "NU Student";
          realName = rawName.split(' - ')[0].trim();
          String rawCollege = userData['college'] ?? "";
          String shortCollege = rawCollege;

          if (rawCollege.contains('(') && rawCollege.contains(')')) {
            shortCollege = rawCollege.split('(').last.replaceAll(')', '').split('-')[0].trim();
          }

          String section = userData['section'] ?? "";
          realProgram = section.isNotEmpty ? "$shortCollege - $section" : shortCollege;
        }
      } catch (e) {
        print("Error fetching user profile: $e");
      }

      DateTime now = DateTime.now();
      DocumentReference docRef = _db.collection('items').doc();

      String uploadedImageUrl = '';

      if (imageFile != null) {
        String fileName = 'items/${docRef.id}_${now.millisecondsSinceEpoch}.jpg';
        Reference storageRef = _storage.ref().child(fileName);
        await storageRef.putFile(imageFile);
        uploadedImageUrl = await storageRef.getDownloadURL();
      }

      ItemPost newItem = ItemPost(
        id: docRef.id,
        itemName: itemName,
        location: location,
        description: description,
        isLost: isLost,
        reporterId: currentUser.uid,
        dateReported: now,
        imageUrl: uploadedImageUrl,
        reporterName: realName,
        reporterProgram: realProgram,
      );

      await docRef.set(newItem.toMap());

      return "Success";
    } catch (e) {
      return "Error saving post: ${e.toString()}";
    }
  }

  //  EDIT PROFILE
  Future<String> updateUserProfile({
    File? imageFile,
    required String college,
    required String section,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return "Error: No user logged in!";

      String profileImageUrl = '';

      if (imageFile != null) {
        String fileName = 'profiles/${currentUser.uid}.jpg';
        Reference storageRef = _storage.ref().child(fileName);

        await storageRef.putFile(imageFile);
        profileImageUrl = await storageRef.getDownloadURL();
      }

      Map<String, dynamic> updateData = {
        'college': college,
        'section': section,
      };

      if (profileImageUrl.isNotEmpty) {
        updateData['profileImageUrl'] = profileImageUrl;
      }

      await _db.collection('users').doc(currentUser.uid).update(updateData);

      return "Success";
    } catch (e) {
      return "Error updating profile: ${e.toString()}";
    }
  }

  //  MARK AS SOLVED
  Future<String> markPostAsSolved(String postId) async {
    try {
      await _db.collection('items').doc(postId).update({
        'status': 'Resolved',
      });
      return "Success";
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }

  Future<void> sendChatMessage({
    required String chatRoomId,
    required String messageText,
    required String currentUserId,
    required String itemReporterId,
    required String otherUserId,
    required String itemId,
  }) async {
    String inquirerId = (currentUserId == itemReporterId) ? otherUserId : currentUserId;

    // Save message bubble
    await _db.collection('chats').doc(chatRoomId).collection('messages').add({
      'senderId': currentUserId,
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update room info and unread count
    await _db.collection('chats').doc(chatRoomId).set({
      'itemId': itemId,
      'inquirerId': inquirerId,
      'posterId': itemReporterId,
      'lastMessage': messageText,
      'lastUpdated': FieldValue.serverTimestamp(),
      'unread_$otherUserId': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  // 1. REGISTER A NEW STUDENT
  Future<String?> registerUser({
    required String email,
    required String password,
    required String name,
    required String section,
    required String college,
  }) async {
    try {
      // Step A: Create the account in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        // Step B: Send the Email Verification Link!
        await user.sendEmailVerification();

        // Step C: Save their extra details (Name, Section, College) into Firestore
        AppUser newStudent = AppUser(
          uid: user.uid,
          name: name.trim(),
          email: email.trim(),
          section: section.trim(),
          college: college.trim(),
        );

        await _firestore.collection('users').doc(user.uid).set(newStudent.toMap());

        return "Success! Please check your email to verify your account.";
      }
    } on FirebaseAuthException catch (e) {
      // Graceful error handling for the rubric!
      return e.message;
    }
    return "An unknown error occurred.";
  }

  // 2. LOGIN AN EXISTING STUDENT
  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? user = userCredential.user;

      // Step D: The Lockout Mechanism (Check if they actually clicked the link)
      if (user != null && !user.emailVerified) {
        await _auth.signOut(); // Kick them back out if not verified
        return "Please verify your email before logging in.";
      }

      return "Success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // 3. LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  // 4. CHECK CURRENT USER SESSION (For staying logged in on restart)
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
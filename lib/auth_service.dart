import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String mobile,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        // Create a user profile document in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'username': username,
          'email': email,
          'mobile': mobile,
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'exp': 0, // Initial EXP
          'level': 1, // Initial Level
          'friends': [], // Initialize empty friends list
          'pendingRequests': [],
          'sentRequests': [],
        });
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during sign up: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error during sign up: $e');
      rethrow;
    }
  }

  // Log in with email and password
  Future<UserCredential?> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during login: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error during login: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user stream to listen to auth changes
  Stream<User?> get user => _auth.authStateChanges();

  // Send a friend request by username
  Future<void> sendFriendRequest(String currentUserId, String targetUsername) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: targetUsername)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('User $targetUsername not found.');
      }

      final targetUserId = querySnapshot.docs.first.id;

      if (currentUserId == targetUserId) {
         throw Exception('You cannot add yourself as a friend.');
      }
      
      final targetUserData = querySnapshot.docs.first.data();
      List<dynamic> targetFriends = targetUserData['friends'] ?? [];
      List<dynamic> targetPending = targetUserData['pendingRequests'] ?? [];
      
      if (targetFriends.contains(currentUserId)) {
         throw Exception('You are already friends with $targetUsername.');
      }
      if (targetPending.contains(currentUserId)) {
         throw Exception('You have already sent a request to $targetUsername.');
      }

      // Add currentUserId to target user's pendingRequests
      await _firestore.collection('users').doc(targetUserId).update({
        'pendingRequests': FieldValue.arrayUnion([currentUserId])
      });

      // Add targetUserId to current user's sentRequests
      await _firestore.collection('users').doc(currentUserId).update({
        'sentRequests': FieldValue.arrayUnion([targetUserId])
      });

    } catch (e) {
      debugPrint('Error sending friend request: $e');
      rethrow;
    }
  }

  // Accept a friend request
  Future<void> acceptRequest(String currentUserId, String requesterId) async {
    try {
      // 1. Add requester to current user's friends list, remove from pending
      await _firestore.collection('users').doc(currentUserId).update({
        'friends': FieldValue.arrayUnion([requesterId]),
        'pendingRequests': FieldValue.arrayRemove([requesterId])
      });

      // 2. Add current user to requester's friends list, remove from their sent
      await _firestore.collection('users').doc(requesterId).update({
        'friends': FieldValue.arrayUnion([currentUserId]),
        'sentRequests': FieldValue.arrayRemove([currentUserId])
      });
    } catch (e) {
      debugPrint('Error accepting request: $e');
      rethrow;
    }
  }

  // Reject a friend request
  Future<void> rejectRequest(String currentUserId, String requesterId) async {
    try {
      // Remove requester from current user's pending
      await _firestore.collection('users').doc(currentUserId).update({
        'pendingRequests': FieldValue.arrayRemove([requesterId])
      });

      // Remove current user from requester's sent
      await _firestore.collection('users').doc(requesterId).update({
        'sentRequests': FieldValue.arrayRemove([currentUserId])
      });
    } catch (e) {
      debugPrint('Error rejecting request: $e');
      rethrow;
    }
  }
}

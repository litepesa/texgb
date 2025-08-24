// lib/features/authentication/repositories/auth_repository.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../constants.dart';

// Abstract repository interface (simplified for drama app)
abstract class AuthRepository {
  // Authentication operations
  Future<bool> checkAuthenticationState();
  Future<void> signInWithPhoneNumber({
    required String phoneNumber,
    required BuildContext context,
  });
  Future<void> verifyOTPCode({
    required String verificationId,
    required String otpCode,
    required BuildContext context,
    required Function onSuccess,
  });
  Future<void> signOut();

  // User data operations
  Future<bool> checkUserExists(String uid);
  Future<UserModel?> getUserDataFromFireStore(String uid);
  Future<UserModel?> getUserDataById(String userId);
  Future<void> saveUserDataToFireStore({
    required UserModel userModel,
    required File? fileImage,
    required Function onSuccess,
    required Function onFail,
  });
  Future<void> updateUserProfile(UserModel updatedUser);

  // Drama-specific user operations
  Future<void> addToFavorites({required String userUid, required String dramaId});
  Future<void> removeFromFavorites({required String userUid, required String dramaId});
  Future<void> addToWatchHistory({required String userUid, required String episodeId});
  Future<void> updateDramaProgress({required String userUid, required String dramaId, required int episodeNumber});
  Future<void> unlockDrama({required String userUid, required String dramaId});

  // Streams
  Stream<DocumentSnapshot> userStream({required String userID});
  Stream<QuerySnapshot> getAllUsersStream({required String userID});

  // File operations
  Future<String> storeFileToStorage({required File file, required String reference});

  // Current user info
  String? get currentUserId;
  String? get currentUserPhoneNumber;
}

// Firebase implementation
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final String _usersCollection;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    String usersCollection = 'users',
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _usersCollection = usersCollection;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  String? get currentUserPhoneNumber => _auth.currentUser?.phoneNumber;

  @override
  Future<bool> checkAuthenticationState() async {
    await Future.delayed(const Duration(seconds: 2));
    return _auth.currentUser != null;
  }

  @override
  Future<void> signInWithPhoneNumber({
    required String phoneNumber,
    required BuildContext context,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        throw AuthRepositoryException('Phone verification failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) async {
        Navigator.of(context).pushNamed(
          Constants.otpScreen,
          arguments: {
            Constants.verificationId: verificationId,
            Constants.phoneNumber: phoneNumber,
          },
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  @override
  Future<void> verifyOTPCode({
    required String verificationId,
    required String otpCode,
    required BuildContext context,
    required Function onSuccess,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );

      await _auth.signInWithCredential(credential);
      onSuccess();
    } on FirebaseAuthException catch (e) {
      throw AuthRepositoryException('OTP verification failed: ${e.message}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthRepositoryException('Sign out failed: ${e.message}');
    }
  }

  @override
  Future<bool> checkUserExists(String uid) async {
    try {
      DocumentSnapshot documentSnapshot =
          await _firestore.collection(_usersCollection).doc(uid).get();
      return documentSnapshot.exists;
    } catch (e) {
      throw AuthRepositoryException('Failed to check user existence: $e');
    }
  }

  @override
  Future<UserModel?> getUserDataFromFireStore(String uid) async {
    try {
      DocumentSnapshot documentSnapshot =
          await _firestore.collection(_usersCollection).doc(uid).get();
      
      if (!documentSnapshot.exists) return null;
      
      return UserModel.fromMap(documentSnapshot.data() as Map<String, dynamic>);
    } catch (e) {
      throw AuthRepositoryException('Failed to get user data: $e');
    }
  }

  @override
  Future<UserModel?> getUserDataById(String userId) async {
    try {
      DocumentSnapshot documentSnapshot =
          await _firestore.collection(_usersCollection).doc(userId).get();
      
      if (!documentSnapshot.exists) return null;
      
      return UserModel.fromMap(documentSnapshot.data() as Map<String, dynamic>);
    } catch (e) {
      throw AuthRepositoryException('Failed to get user by ID: $e');
    }
  }

  @override
  Future<void> saveUserDataToFireStore({
    required UserModel userModel,
    required File? fileImage,
    required Function onSuccess,
    required Function onFail,
  }) async {
    try {
      UserModel updatedUserModel = userModel;

      // Upload image if provided
      if (fileImage != null) {
        String imageUrl = await storeFileToStorage(
          file: fileImage,
          reference: 'userImages/${userModel.uid}',
        );
        updatedUserModel = updatedUserModel.copyWith(profileImage: imageUrl);
      }

      // Update timestamps
      final now = DateTime.now().microsecondsSinceEpoch.toString();
      final finalUserModel = updatedUserModel.copyWith(
        lastSeen: now,
        createdAt: now,
        updatedAt: now,
      );

      // Save to Firestore
      await _firestore
          .collection(_usersCollection)
          .doc(finalUserModel.uid)
          .set(finalUserModel.toMap());
      
      onSuccess();
    } on FirebaseException catch (e) {
      onFail(e.toString());
    } catch (e) {
      onFail(e.toString());
    }
  }

  @override
  Future<void> updateUserProfile(UserModel updatedUser) async {
    try {
      final userWithTimestamp = updatedUser.copyWith(
        updatedAt: DateTime.now().microsecondsSinceEpoch.toString(),
      );

      await _firestore
          .collection(_usersCollection)
          .doc(userWithTimestamp.uid)
          .update(userWithTimestamp.toMap());
    } on FirebaseException catch (e) {
      throw AuthRepositoryException('Failed to update user profile: ${e.message}');
    }
  }

  // Drama-specific user operations
  @override
  Future<void> addToFavorites({required String userUid, required String dramaId}) async {
    try {
      await _firestore.collection(_usersCollection).doc(userUid).update({
        Constants.favoriteDramas: FieldValue.arrayUnion([dramaId]),
      });
    } on FirebaseException catch (e) {
      throw AuthRepositoryException('Failed to add to favorites: ${e.message}');
    }
  }

  @override
  Future<void> removeFromFavorites({required String userUid, required String dramaId}) async {
    try {
      await _firestore.collection(_usersCollection).doc(userUid).update({
        Constants.favoriteDramas: FieldValue.arrayRemove([dramaId]),
      });
    } on FirebaseException catch (e) {
      throw AuthRepositoryException('Failed to remove from favorites: ${e.message}');
    }
  }

  @override
  Future<void> addToWatchHistory({required String userUid, required String episodeId}) async {
    try {
      await _firestore.collection(_usersCollection).doc(userUid).update({
        Constants.watchHistory: FieldValue.arrayUnion([episodeId]),
      });
    } on FirebaseException catch (e) {
      throw AuthRepositoryException('Failed to add to watch history: ${e.message}');
    }
  }

  @override
  Future<void> updateDramaProgress({required String userUid, required String dramaId, required int episodeNumber}) async {
    try {
      await _firestore.collection(_usersCollection).doc(userUid).update({
        '${Constants.dramaProgress}.$dramaId': episodeNumber,
      });
    } on FirebaseException catch (e) {
      throw AuthRepositoryException('Failed to update drama progress: ${e.message}');
    }
  }

  @override
  Future<void> unlockDrama({required String userUid, required String dramaId}) async {
    try {
      await _firestore.collection(_usersCollection).doc(userUid).update({
        Constants.unlockedDramas: FieldValue.arrayUnion([dramaId]),
      });
    } on FirebaseException catch (e) {
      throw AuthRepositoryException('Failed to unlock drama: ${e.message}');
    }
  }

  @override
  Stream<DocumentSnapshot> userStream({required String userID}) {
    return _firestore.collection(_usersCollection).doc(userID).snapshots();
  }

  @override
  Stream<QuerySnapshot> getAllUsersStream({required String userID}) {
    return _firestore
        .collection(_usersCollection)
        .where('uid', isNotEqualTo: userID)
        .snapshots();
  }

  @override
  Future<String> storeFileToStorage({required File file, required String reference}) async {
    try {
      UploadTask uploadTask = _storage.ref().child(reference).putFile(file);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadURL = await taskSnapshot.ref.getDownloadURL();
      return downloadURL;
    } on FirebaseException catch (e) {
      throw AuthRepositoryException('Failed to upload file: ${e.message}');
    }
  }
}

// Exception class for auth repository errors
class AuthRepositoryException implements Exception {
  final String message;
  const AuthRepositoryException(this.message);
  
  @override
  String toString() => 'AuthRepositoryException: $message';
}
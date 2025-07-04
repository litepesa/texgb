// lib/features/authentication/repositories/auth_repository.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../../../models/user_model.dart';

// Abstract repository interface
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

  // Contact management
  Future<void> addContact({required String userUid, required String contactId});
  Future<void> removeContact({required String userUid, required String contactId});
  Future<void> blockContact({required String userUid, required String contactId});
  Future<void> unblockContact({required String userUid, required String contactId});
  Future<List<UserModel>> getContactsList(String uid, List<String> groupMembersUIDs);
  Future<List<UserModel>> getBlockedContactsList({required String uid});
  Future<UserModel?> searchUserByPhoneNumber({required String phoneNumber});

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
        // Navigate to OTP screen
        Navigator.of(context).pushNamed(
          '/otp', // Replace with your constants
          arguments: {
            'verificationId': verificationId,
            'phoneNumber': phoneNumber,
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
        updatedUserModel = updatedUserModel.copyWith(image: imageUrl);
      }

      // Update timestamps
      final finalUserModel = updatedUserModel.copyWith(
        lastSeen: DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt: DateTime.now().microsecondsSinceEpoch.toString(),
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
      await _firestore
          .collection(_usersCollection)
          .doc(updatedUser.uid)
          .update(updatedUser.toMap());
    } on FirebaseException catch (e) {
      throw AuthRepositoryException('Failed to update user profile: ${e.message}');
    }
  }

  @override
  Future<void> addContact({required String userUid, required String contactId}) async {
    try {
      await _firestore.collection(_usersCollection).doc(userUid).update({
        'contactsUIDs': FieldValue.arrayUnion([contactId]),
      });
    } on FirebaseException catch (e) {
      throw AuthRepositoryException('Failed to add contact: ${e.message}');
    }
  }

  @override
  Future<void> removeContact({required String userUid, required String contactId}) async {
    try {
      await _firestore.collection(_usersCollection).doc(userUid).update({
        'contactsUIDs': FieldValue.arrayRemove([contactId]),
      });
    } on FirebaseException catch (e) {
      throw AuthRepositoryException('Failed to remove contact: ${e.message}');
    }
  }

  @override
  Future<void> blockContact({required String userUid, required String contactId}) async {
    try {
      await _firestore.collection(_usersCollection).doc(userUid).update({
        'blockedUIDs': FieldValue.arrayUnion([contactId]),
      });
    } on FirebaseException catch (e) {
      throw AuthRepositoryException('Failed to block contact: ${e.message}');
    }
  }

  @override
  Future<void> unblockContact({required String userUid, required String contactId}) async {
    try {
      await _firestore.collection(_usersCollection).doc(userUid).update({
        'blockedUIDs': FieldValue.arrayRemove([contactId]),
      });
    } on FirebaseException catch (e) {
      throw AuthRepositoryException('Failed to unblock contact: ${e.message}');
    }
  }

  @override
  Future<List<UserModel>> getContactsList(String uid, List<String> groupMembersUIDs) async {
    try {
      List<UserModel> contactsList = [];

      DocumentSnapshot documentSnapshot =
          await _firestore.collection(_usersCollection).doc(uid).get();

      List<dynamic> contactsUIDs = documentSnapshot.get('contactsUIDs');

      for (String contactUID in contactsUIDs) {
        if (groupMembersUIDs.isNotEmpty && groupMembersUIDs.contains(contactUID)) {
          continue;
        }
        DocumentSnapshot contactSnapshot =
            await _firestore.collection(_usersCollection).doc(contactUID).get();
        UserModel contact =
            UserModel.fromMap(contactSnapshot.data() as Map<String, dynamic>);
        contactsList.add(contact);
      }

      return contactsList;
    } catch (e) {
      throw AuthRepositoryException('Failed to get contacts list: $e');
    }
  }

  @override
  Future<List<UserModel>> getBlockedContactsList({required String uid}) async {
    try {
      List<UserModel> blockedContactsList = [];

      DocumentSnapshot documentSnapshot =
          await _firestore.collection(_usersCollection).doc(uid).get();

      List<dynamic> blockedUIDs = documentSnapshot.get('blockedUIDs');

      for (String blockedUID in blockedUIDs) {
        DocumentSnapshot blockedSnapshot = await _firestore
            .collection(_usersCollection)
            .doc(blockedUID)
            .get();
        UserModel blockedContact =
            UserModel.fromMap(blockedSnapshot.data() as Map<String, dynamic>);
        blockedContactsList.add(blockedContact);
      }

      return blockedContactsList;
    } catch (e) {
      throw AuthRepositoryException('Failed to get blocked contacts: $e');
    }
  }

  @override
  Future<UserModel?> searchUserByPhoneNumber({required String phoneNumber}) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      return UserModel.fromMap(
          querySnapshot.docs.first.data() as Map<String, dynamic>);
    } catch (e) {
      throw AuthRepositoryException('Failed to search user: $e');
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


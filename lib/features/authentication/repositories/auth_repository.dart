// lib/features/authentication/repositories/auth_repository.dart (Updated for Channel-based)
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../../../features/channels/models/channel_model.dart';
import '../../../constants.dart';

// Abstract repository interface (updated for channels)
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

  // Channel data operations
  Future<bool> checkChannelExists(String ownerId);
  Future<ChannelModel?> getChannelDataFromFireStore(String ownerId);
  Future<ChannelModel?> getChannelDataById(String channelId);
  Future<void> saveChannelDataToFireStore({
    required ChannelModel channelModel,
    required File? profileImage,
    required File? coverImage,
    required Function onSuccess,
    required Function onFail,
  });
  Future<void> updateChannelProfile(ChannelModel updatedChannel);

  // Channel interaction operations
  Future<void> followChannel({required String followerId, required String channelId});
  Future<void> unfollowChannel({required String followerId, required String channelId});
  Future<List<ChannelModel>> searchChannels({required String query});

  // Streams
  Stream<DocumentSnapshot> channelStream({required String channelId});
  Stream<QuerySnapshot> getAllChannelsStream({required String excludeChannelId});

  // File operations
  Future<String> storeFileToStorage({required File file, required String reference});

  // Current user info
  String? get currentUserId;
  String? get currentUserPhoneNumber;
}

// Firebase implementation (updated for channels)
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

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
        // Navigate to OTP screen using the correct route from constants
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
  Future<bool> checkChannelExists(String ownerId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(Constants.channels)
          .where('ownerId', isEqualTo: ownerId)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw AuthRepositoryException('Failed to check channel existence: $e');
    }
  }

  @override
  Future<ChannelModel?> getChannelDataFromFireStore(String ownerId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(Constants.channels)
          .where('ownerId', isEqualTo: ownerId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) return null;
      
      final doc = querySnapshot.docs.first;
      return ChannelModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw AuthRepositoryException('Failed to get channel data: $e');
    }
  }

  @override
  Future<ChannelModel?> getChannelDataById(String channelId) async {
    try {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection(Constants.channels)
          .doc(channelId)
          .get();
      
      if (!documentSnapshot.exists) return null;
      
      return ChannelModel.fromMap(
        documentSnapshot.data() as Map<String, dynamic>, 
        documentSnapshot.id
      );
    } catch (e) {
      throw AuthRepositoryException('Failed to get channel by ID: $e');
    }
  }

  @override
  Future<void> saveChannelDataToFireStore({
    required ChannelModel channelModel,
    required File? profileImage,
    required File? coverImage,
    required Function onSuccess,
    required Function onFail,
  }) async {
    try {
      ChannelModel updatedChannelModel = channelModel;

      // Upload profile image if provided
      if (profileImage != null) {
        String profileImageUrl = await storeFileToStorage(
          file: profileImage,
          reference: 'channelImages/${channelModel.ownerId}/profile',
        );
        updatedChannelModel = updatedChannelModel.copyWith(profileImage: profileImageUrl);
      }

      // Upload cover image if provided
      if (coverImage != null) {
        String coverImageUrl = await storeFileToStorage(
          file: coverImage,
          reference: 'channelImages/${channelModel.ownerId}/cover',
        );
        updatedChannelModel = updatedChannelModel.copyWith(coverImage: coverImageUrl);
      }

      // Update timestamps
      final finalChannelModel = updatedChannelModel.copyWith(
        createdAt: Timestamp.now(),
      );

      // Save to Firestore
      await _firestore
          .collection(Constants.channels)
          .add(finalChannelModel.toMap())
          .then((docRef) {
        // Update the channel with the generated ID
        docRef.update({'id': docRef.id});
      });
      
      onSuccess();
    } on FirebaseException catch (e) {
      onFail(e.toString());
    } catch (e) {
      onFail(e.toString());
    }
  }

  @override
  Future<void> updateChannelProfile(ChannelModel updatedChannel) async {
    try {
      await _firestore
          .collection(Constants.channels)
          .doc(updatedChannel.id)
          .update(updatedChannel.toMap());
    } on FirebaseException catch (e) {
      throw AuthRepositoryException('Failed to update channel profile: ${e.message}');
    }
  }

  @override
  Future<void> followChannel({required String followerId, required String channelId}) async {
    try {
      final batch = _firestore.batch();
      
      // Add follower to the channel's followerUIDs
      final channelRef = _firestore.collection(Constants.channels).doc(channelId);
      batch.update(channelRef, {
        'followerUIDs': FieldValue.arrayUnion([followerId]),
        'followers': FieldValue.increment(1),
      });
      
      // You might also want to update the follower's following list
      // This would require a separate collection or field in the follower's channel document
      
      await batch.commit();
    } on FirebaseException catch (e) {
      throw AuthRepositoryException('Failed to follow channel: ${e.message}');
    }
  }

  @override
  Future<void> unfollowChannel({required String followerId, required String channelId}) async {
    try {
      final batch = _firestore.batch();
      
      // Remove follower from the channel's followerUIDs
      final channelRef = _firestore.collection(Constants.channels).doc(channelId);
      batch.update(channelRef, {
        'followerUIDs': FieldValue.arrayRemove([followerId]),
        'followers': FieldValue.increment(-1),
      });
      
      await batch.commit();
    } on FirebaseException catch (e) {
      throw AuthRepositoryException('Failed to unfollow channel: ${e.message}');
    }
  }

  @override
  Future<List<ChannelModel>> searchChannels({required String query}) async {
    try {
      List<ChannelModel> channels = [];
      
      // Search by channel name (case-insensitive)
      QuerySnapshot nameQuery = await _firestore
          .collection(Constants.channels)
          .where('name', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('name', isLessThan: query.toLowerCase() + 'z')
          .limit(20)
          .get();
      
      for (QueryDocumentSnapshot doc in nameQuery.docs) {
        channels.add(ChannelModel.fromMap(
          doc.data() as Map<String, dynamic>, 
          doc.id
        ));
      }
      
      // You could also search by tags or other fields
      
      return channels;
    } catch (e) {
      throw AuthRepositoryException('Failed to search channels: $e');
    }
  }

  @override
  Stream<DocumentSnapshot> channelStream({required String channelId}) {
    return _firestore.collection(Constants.channels).doc(channelId).snapshots();
  }

  @override
  Stream<QuerySnapshot> getAllChannelsStream({required String excludeChannelId}) {
    return _firestore
        .collection(Constants.channels)
        .where('id', isNotEqualTo: excludeChannelId)
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
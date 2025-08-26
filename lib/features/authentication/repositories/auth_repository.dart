// lib/features/authentication/repositories/auth_repository.dart
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../constants.dart';
import '../../../shared/services/http_client.dart';

// Abstract repository interface (unchanged)
abstract class AuthRepository {
  // Authentication operations (Firebase Auth - unchanged)
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

  // User data operations (now HTTP backend)
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

  // Drama-specific user operations (now HTTP backend)
  Future<void> addToFavorites({required String userUid, required String dramaId});
  Future<void> removeFromFavorites({required String userUid, required String dramaId});
  Future<void> addToWatchHistory({required String userUid, required String episodeId});
  Future<void> updateDramaProgress({required String userUid, required String dramaId, required int episodeNumber});
  Future<void> unlockDrama({required String userUid, required String dramaId});

  // Streams (deprecated for HTTP backend)
  Stream<DocumentSnapshot> userStream({required String userID});
  Stream<QuerySnapshot> getAllUsersStream({required String userID});

  // File operations (now backend upload service)
  Future<String> storeFileToStorage({required File file, required String reference});

  // Current user info (Firebase Auth - unchanged)
  String? get currentUserId;
  String? get currentUserPhoneNumber;
}

// Firebase Auth + HTTP Backend implementation
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final HttpClientService _httpClient;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    HttpClientService? httpClient,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _httpClient = httpClient ?? HttpClientService();

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  String? get currentUserPhoneNumber => _auth.currentUser?.phoneNumber;

  // ===============================
  // FIREBASE AUTH METHODS (UNCHANGED)
  // ===============================

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

  // ===============================
  // USER DATA METHODS (HTTP BACKEND)
  // ===============================

  @override
  Future<bool> checkUserExists(String uid) async {
    try {
      final response = await _httpClient.get('/users/$uid');
      return response.statusCode == 200;
    } catch (e) {
      if (e is NotFoundException) return false;
      throw AuthRepositoryException('Failed to check user existence: $e');
    }
  }

  @override
  Future<UserModel?> getUserDataFromFireStore(String uid) async {
    try {
      final response = await _httpClient.get('/users/$uid');
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body) as Map<String, dynamic>;
        return UserModel.fromMap(userData);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw AuthRepositoryException('Failed to get user data: ${response.body}');
      }
    } catch (e) {
      if (e is NotFoundException) return null;
      throw AuthRepositoryException('Failed to get user data: $e');
    }
  }

  @override
  Future<UserModel?> getUserDataById(String userId) async {
    try {
      final response = await _httpClient.get('/users/$userId');
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body) as Map<String, dynamic>;
        return UserModel.fromMap(userData);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw AuthRepositoryException('Failed to get user by ID: ${response.body}');
      }
    } catch (e) {
      if (e is NotFoundException) return null;
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
          reference: 'profile/${userModel.uid}',
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

      // Save to backend
      final response = await _httpClient.post('/users', body: finalUserModel.toMap());
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        onSuccess();
      } else {
        onFail('Failed to save user data: ${response.body}');
      }
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

      final response = await _httpClient.put('/users/${userWithTimestamp.uid}', 
        body: userWithTimestamp.toMap());

      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to update user profile: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to update user profile: $e');
    }
  }

  // ===============================
  // DRAMA-SPECIFIC USER OPERATIONS (HTTP BACKEND)
  // ===============================

  @override
  Future<void> addToFavorites({required String userUid, required String dramaId}) async {
    try {
      final response = await _httpClient.post('/users/$userUid/favorites', body: {
        'dramaId': dramaId,
        'action': 'add',
      });

      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to add to favorites: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to add to favorites: $e');
    }
  }

  @override
  Future<void> removeFromFavorites({required String userUid, required String dramaId}) async {
    try {
      final response = await _httpClient.post('/users/$userUid/favorites', body: {
        'dramaId': dramaId,
        'action': 'remove',
      });

      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to remove from favorites: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to remove from favorites: $e');
    }
  }

  @override
  Future<void> addToWatchHistory({required String userUid, required String episodeId}) async {
    try {
      final response = await _httpClient.post('/users/$userUid/watch-history', body: {
        'episodeId': episodeId,
      });

      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to add to watch history: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to add to watch history: $e');
    }
  }

  @override
  Future<void> updateDramaProgress({required String userUid, required String dramaId, required int episodeNumber}) async {
    try {
      final response = await _httpClient.post('/users/$userUid/progress', body: {
        'dramaId': dramaId,
        'episodeNumber': episodeNumber,
      });

      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to update drama progress: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to update drama progress: $e');
    }
  }

  @override
  Future<void> unlockDrama({required String userUid, required String dramaId}) async {
    try {
      final response = await _httpClient.post('/dramas/$dramaId/unlock', body: {
        'userId': userUid,
      });

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = errorData['error'] ?? 'Failed to unlock drama';
        
        // Map backend errors to known exceptions for drama actions provider
        switch (errorMessage) {
          case 'Insufficient coins':
          case 'insufficient_funds':
            throw AuthRepositoryException('INSUFFICIENT_FUNDS');
          case 'Drama already unlocked':
          case 'already_unlocked':
            throw AuthRepositoryException('ALREADY_UNLOCKED');
          case 'Drama not found':
          case 'drama_not_found':
            throw AuthRepositoryException('DRAMA_NOT_FOUND');
          case 'This drama is free to watch':
          case 'drama_free':
            throw AuthRepositoryException('DRAMA_FREE');
          default:
            throw AuthRepositoryException('Failed to unlock drama: $errorMessage');
        }
      }
    } catch (e) {
      if (e is AuthRepositoryException) rethrow;
      throw AuthRepositoryException('Failed to unlock drama: $e');
    }
  }

  // ===============================
  // DEPRECATED STREAM METHODS
  // ===============================

  @override
  Stream<DocumentSnapshot> userStream({required String userID}) {
    // For HTTP backend, implement polling or WebSocket if needed
    throw UnsupportedError('userStream is deprecated with HTTP backend. Use HTTP polling or WebSocket instead.');
  }

  @override
  Stream<QuerySnapshot> getAllUsersStream({required String userID}) {
    // For HTTP backend, implement polling or WebSocket if needed
    throw UnsupportedError('getAllUsersStream is deprecated with HTTP backend. Use HTTP polling or WebSocket instead.');
  }

  // ===============================
  // FILE OPERATIONS (HTTP BACKEND)
  // ===============================

  @override
  Future<String> storeFileToStorage({required File file, required String reference}) async {
    try {
      final response = await _httpClient.uploadFile(
        '/upload',
        file,
        'file',
        additionalFields: {
          'type': _getFileTypeFromReference(reference),
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return responseData['url'] as String;
      } else {
        throw AuthRepositoryException('Failed to upload file: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to upload file: $e');
    }
  }

  // Helper method to determine file type from reference
  String _getFileTypeFromReference(String reference) {
    if (reference.contains('profile') || reference.contains('userImages')) return 'profile';
    if (reference.contains('banner')) return 'banner';
    if (reference.contains('thumbnail')) return 'thumbnail';
    if (reference.contains('video')) return 'video';
    return 'profile'; // Default to profile
  }
}

// HTTP Auth + Backend implementation (replaces Firebase implementation)
class HttpAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final HttpClientService _httpClient;

  HttpAuthRepository({
    FirebaseAuth? auth,
    HttpClientService? httpClient,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _httpClient = httpClient ?? HttpClientService();

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  String? get currentUserPhoneNumber => _auth.currentUser?.phoneNumber;

  // ===============================
  // FIREBASE AUTH METHODS (UNCHANGED)
  // ===============================

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

  // ===============================
  // USER DATA METHODS (HTTP BACKEND)
  // ===============================

  @override
  Future<bool> checkUserExists(String uid) async {
    try {
      final response = await _httpClient.get('/users/$uid');
      return response.statusCode == 200;
    } catch (e) {
      if (e is NotFoundException) return false;
      throw AuthRepositoryException('Failed to check user existence: $e');
    }
  }

  @override
  Future<UserModel?> getUserDataFromFireStore(String uid) async {
    try {
      final response = await _httpClient.get('/users/$uid');
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body) as Map<String, dynamic>;
        return UserModel.fromMap(userData);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw AuthRepositoryException('Failed to get user data: ${response.body}');
      }
    } catch (e) {
      if (e is NotFoundException) return null;
      throw AuthRepositoryException('Failed to get user data: $e');
    }
  }

  @override
  Future<UserModel?> getUserDataById(String userId) async {
    try {
      final response = await _httpClient.get('/users/$userId');
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body) as Map<String, dynamic>;
        return UserModel.fromMap(userData);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw AuthRepositoryException('Failed to get user by ID: ${response.body}');
      }
    } catch (e) {
      if (e is NotFoundException) return null;
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
          reference: 'profile/${userModel.uid}',
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

      // Save to backend
      final response = await _httpClient.post('/users', body: finalUserModel.toMap());
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        onSuccess();
      } else {
        onFail('Failed to save user data: ${response.body}');
      }
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

      final response = await _httpClient.put('/users/${userWithTimestamp.uid}', 
        body: userWithTimestamp.toMap());

      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to update user profile: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to update user profile: $e');
    }
  }

  // ===============================
  // DRAMA-SPECIFIC USER OPERATIONS (HTTP BACKEND)
  // ===============================

  @override
  Future<void> addToFavorites({required String userUid, required String dramaId}) async {
    try {
      final response = await _httpClient.post('/users/$userUid/favorites', body: {
        'dramaId': dramaId,
        'action': 'add',
      });

      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to add to favorites: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to add to favorites: $e');
    }
  }

  @override
  Future<void> removeFromFavorites({required String userUid, required String dramaId}) async {
    try {
      final response = await _httpClient.post('/users/$userUid/favorites', body: {
        'dramaId': dramaId,
        'action': 'remove',
      });

      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to remove from favorites: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to remove from favorites: $e');
    }
  }

  @override
  Future<void> addToWatchHistory({required String userUid, required String episodeId}) async {
    try {
      final response = await _httpClient.post('/users/$userUid/watch-history', body: {
        'episodeId': episodeId,
      });

      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to add to watch history: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to add to watch history: $e');
    }
  }

  @override
  Future<void> updateDramaProgress({required String userUid, required String dramaId, required int episodeNumber}) async {
    try {
      final response = await _httpClient.post('/users/$userUid/progress', body: {
        'dramaId': dramaId,
        'episodeNumber': episodeNumber,
      });

      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to update drama progress: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to update drama progress: $e');
    }
  }

  @override
  Future<void> unlockDrama({required String userUid, required String dramaId}) async {
    try {
      final response = await _httpClient.post('/dramas/$dramaId/unlock', body: {
        'userId': userUid,
      });

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = errorData['error'] ?? 'Failed to unlock drama';
        
        // Map backend errors to known exceptions for drama actions provider
        switch (errorMessage) {
          case 'Insufficient coins':
          case 'insufficient_funds':
            throw AuthRepositoryException('INSUFFICIENT_FUNDS');
          case 'Drama already unlocked':
          case 'already_unlocked':
            throw AuthRepositoryException('ALREADY_UNLOCKED');
          case 'Drama not found':
          case 'drama_not_found':
            throw AuthRepositoryException('DRAMA_NOT_FOUND');
          case 'This drama is free to watch':
          case 'drama_free':
            throw AuthRepositoryException('DRAMA_FREE');
          default:
            throw AuthRepositoryException('Failed to unlock drama: $errorMessage');
        }
      }
    } catch (e) {
      if (e is AuthRepositoryException) rethrow;
      throw AuthRepositoryException('Failed to unlock drama: $e');
    }
  }

  // ===============================
  // DEPRECATED STREAM METHODS
  // ===============================

  @override
  Stream<DocumentSnapshot> userStream({required String userID}) {
    // For HTTP backend, implement polling or WebSocket if needed
    throw UnsupportedError('userStream is deprecated with HTTP backend. Use HTTP polling or WebSocket instead.');
  }

  @override
  Stream<QuerySnapshot> getAllUsersStream({required String userID}) {
    // For HTTP backend, implement polling or WebSocket if needed
    throw UnsupportedError('getAllUsersStream is deprecated with HTTP backend. Use HTTP polling or WebSocket instead.');
  }

  // ===============================
  // FILE OPERATIONS (HTTP BACKEND)
  // ===============================

  @override
  Future<String> storeFileToStorage({required File file, required String reference}) async {
    try {
      final response = await _httpClient.uploadFile(
        '/upload',
        file,
        'file',
        additionalFields: {
          'type': _getFileTypeFromReference(reference),
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return responseData['url'] as String;
      } else {
        throw AuthRepositoryException('Failed to upload file: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to upload file: $e');
    }
  }

  // Helper method to determine file type from reference
  String _getFileTypeFromReference(String reference) {
    if (reference.contains('profile') || reference.contains('userImages')) return 'profile';
    if (reference.contains('banner')) return 'banner';
    if (reference.contains('thumbnail')) return 'thumbnail';
    if (reference.contains('video')) return 'video';
    return 'profile'; // Default to profile
  }
}

// Exception class for auth repository errors (unchanged)
class AuthRepositoryException implements Exception {
  final String message;
  const AuthRepositoryException(this.message);
  
  @override
  String toString() => 'AuthRepositoryException: $message';
}
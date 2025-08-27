// lib/features/authentication/repositories/auth_repository.dart (Updated for Go Backend Only)
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../constants.dart';
import '../../../shared/services/http_client.dart';

// Abstract repository interface (updated for Go backend)
abstract class AuthRepository {
  // Authentication operations (Firebase Auth only - unchanged)
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

  // User data operations (Go backend via HTTP)
  Future<bool> checkUserExists(String uid);
  Future<UserModel?> getUserDataFromBackend(String uid);
  Future<UserModel?> getUserDataById(String userId);
  Future<UserModel?> syncUserWithBackend(String uid);
  Future<void> saveUserDataToBackend({
    required UserModel userModel,
    required File? fileImage,
    required Function onSuccess,
    required Function onFail,
  });
  Future<void> updateUserProfile(UserModel updatedUser);

  // Drama-specific user operations (Go backend via HTTP)
  Future<void> addToFavorites({required String userUid, required String dramaId});
  Future<void> removeFromFavorites({required String userUid, required String dramaId});
  Future<void> addToWatchHistory({required String userUid, required String episodeId});
  Future<void> updateDramaProgress({required String userUid, required String dramaId, required int episodeNumber});
  Future<void> unlockDrama({required String userUid, required String dramaId});

  // File operations (R2 via Go backend)
  Future<String> storeFileToStorage({required File file, required String reference});

  // Current user info (Firebase Auth - unchanged)
  String? get currentUserId;
  String? get currentUserPhoneNumber;
}

// Firebase Auth + Go Backend implementation
class FirebaseAuthWithGoBackendRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final HttpClientService _httpClient;

  FirebaseAuthWithGoBackendRepository({
    FirebaseAuth? auth,
    HttpClientService? httpClient,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _httpClient = httpClient ?? HttpClientService();

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  String? get currentUserPhoneNumber => _auth.currentUser?.phoneNumber;

  // Helper method to create RFC3339 timestamps
  String _createTimestamp() {
    return DateTime.now().toUtc().toIso8601String();
  }

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
  // USER DATA METHODS (GO BACKEND VIA HTTP)
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
  Future<UserModel?> getUserDataFromBackend(String uid) async {
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
  Future<UserModel?> syncUserWithBackend(String uid) async {
    try {
      // First check if user exists
      final userExists = await checkUserExists(uid);
      
      if (userExists) {
        // Get existing user data
        return await getUserDataFromBackend(uid);
      } else {
        // Create new user with Firebase info using the proper factory constructor
        final firebaseUser = _auth.currentUser;
        if (firebaseUser == null) {
          throw AuthRepositoryException('No Firebase user found');
        }

        final newUser = UserModel.create(
          uid: uid,
          name: firebaseUser.displayName ?? '',
          email: firebaseUser.email ?? '',
          phoneNumber: firebaseUser.phoneNumber ?? '',
          profileImage: firebaseUser.photoURL ?? '',
          bio: 'New to WeiBao, excited to watch amazing dramas!',
        );

        // Create user in backend
        final response = await _httpClient.post('/users', body: newUser.toMap());
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          return newUser;
        } else {
          throw AuthRepositoryException('Failed to create user in backend: ${response.body}');
        }
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to sync user with backend: $e');
    }
  }

  @override
  Future<void> saveUserDataToBackend({
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

      // Update timestamps using proper RFC3339 format
      final timestamp = _createTimestamp();
      final finalUserModel = updatedUserModel.copyWith(
        lastSeen: timestamp,
        updatedAt: timestamp,
        // Keep original createdAt if it exists, otherwise use current timestamp
        createdAt: userModel.createdAt.isEmpty ? timestamp : userModel.createdAt,
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
        updatedAt: _createTimestamp(),
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
  // DRAMA-SPECIFIC USER OPERATIONS (GO BACKEND VIA HTTP)
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
      final response = await _httpClient.post('/users/$userUid/drama-progress', body: {
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
      final response = await _httpClient.post('/unlock-drama', body: {
        'dramaId': dramaId,
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
  // FILE OPERATIONS (R2 VIA GO BACKEND)
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
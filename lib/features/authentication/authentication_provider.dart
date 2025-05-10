import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

part 'authentication_provider.g.dart';

// State class for authentication
class AuthenticationState {
  final bool isLoading;
  final bool isSuccessful;
  final String? uid;
  final String? phoneNumber;
  final UserModel? userModel;
  final String? error;

  const AuthenticationState({
    this.isLoading = false,
    this.isSuccessful = false,
    this.uid,
    this.phoneNumber,
    this.userModel,
    this.error,
  });

  AuthenticationState copyWith({
    bool? isLoading,
    bool? isSuccessful,
    String? uid,
    String? phoneNumber,
    UserModel? userModel,
    String? error,
  }) {
    return AuthenticationState(
      isLoading: isLoading ?? this.isLoading,
      isSuccessful: isSuccessful ?? this.isSuccessful,
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userModel: userModel ?? this.userModel,
      error: error,
    );
  }
}

@riverpod
class Authentication extends _$Authentication {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  FutureOr<AuthenticationState> build() async {
    // Check authentication state on initialization
    final isAuthenticated = await checkAuthenticationState();
    
    if (isAuthenticated && _auth.currentUser != null) {
      final userModel = await getUserDataFromFireStore();
      await saveUserDataToSharedPreferences();
      
      return AuthenticationState(
        isSuccessful: true,
        uid: _auth.currentUser!.uid,
        phoneNumber: _auth.currentUser!.phoneNumber,
        userModel: userModel,
      );
    }
    
    return const AuthenticationState();
  }

  // Check authentication state
  Future<bool> checkAuthenticationState() async {
    await Future.delayed(const Duration(seconds: 2));

    if (_auth.currentUser != null) {
      return true;
    }
    return false;
  }

  // Check if user exists
  Future<bool> checkUserExists() async {
    final currentState = state.value ?? const AuthenticationState();
    final uid = currentState.uid ?? _auth.currentUser?.uid;
    
    if (uid == null) return false;
    
    DocumentSnapshot documentSnapshot =
        await _firestore.collection(Constants.users).doc(uid).get();
    return documentSnapshot.exists;
  }

  // Update user status
  Future<void> updateUserStatus({required bool value}) async {
    if (_auth.currentUser == null) return;
    
    await _firestore
        .collection(Constants.users)
        .doc(_auth.currentUser!.uid)
        .update({Constants.isOnline: value});
  }

  // Get user data from firestore
  Future<UserModel?> getUserDataFromFireStore() async {
    final currentState = state.value ?? const AuthenticationState();
    final uid = currentState.uid ?? _auth.currentUser?.uid;
    
    if (uid == null) return null;
    
    DocumentSnapshot documentSnapshot =
        await _firestore.collection(Constants.users).doc(uid).get();
    
    if (!documentSnapshot.exists) return null;
    
    final userModel = UserModel.fromMap(documentSnapshot.data() as Map<String, dynamic>);
    
    // Update state with user model
    state = AsyncValue.data(currentState.copyWith(userModel: userModel));
    
    return userModel;
  }

  // Save user data to shared preferences
  Future<void> saveUserDataToSharedPreferences() async {
    final currentState = state.value ?? const AuthenticationState();
    if (currentState.userModel == null) return;
    
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString(
        Constants.userModel, jsonEncode(currentState.userModel!.toMap()));
  }

  // Get data from shared preferences
  Future<void> getUserDataFromSharedPreferences() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String userModelString = sharedPreferences.getString(Constants.userModel) ?? '';
    
    if (userModelString.isEmpty) return;
    
    final userModel = UserModel.fromMap(jsonDecode(userModelString));
    final currentState = state.value ?? const AuthenticationState();
    
    state = AsyncValue.data(currentState.copyWith(
      userModel: userModel,
      uid: userModel.uid,
    ));
  }

  // Sign in with phone number
  Future<void> signInWithPhoneNumber({
    required String phoneNumber,
    required BuildContext context,
  }) async {
    state = AsyncValue.data(const AuthenticationState(isLoading: true));

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final userCredential = await _auth.signInWithCredential(credential);
          
          state = AsyncValue.data(AuthenticationState(
            isSuccessful: true,
            uid: userCredential.user!.uid,
            phoneNumber: userCredential.user!.phoneNumber,
          ));
        } catch (e) {
          state = AsyncValue.error(e, StackTrace.current);
          showSnackBar(context, e.toString());
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        state = AsyncValue.error(e, StackTrace.current);
        showSnackBar(context, e.toString());
      },
      codeSent: (String verificationId, int? resendToken) async {
        state = AsyncValue.data(const AuthenticationState());
        
        // Navigate to OTP screen
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

  // Verify OTP code
  Future<void> verifyOTPCode({
    required String verificationId,
    required String otpCode,
    required BuildContext context,
    required Function onSuccess,
  }) async {
    state = AsyncValue.data(const AuthenticationState(isLoading: true));

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otpCode,
    );

    try {
      final userCredential = await _auth.signInWithCredential(credential);
      
      state = AsyncValue.data(AuthenticationState(
        isSuccessful: true,
        uid: userCredential.user!.uid,
        phoneNumber: userCredential.user!.phoneNumber,
      ));
      
      onSuccess();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      showSnackBar(context, e.toString());
    }
  }

  // Save user data to firestore
  Future<void> saveUserDataToFireStore({
    required UserModel userModel,
    required File? fileImage,
    required Function onSuccess,
    required Function onFail,
  }) async {
    state = AsyncValue.data(const AuthenticationState(isLoading: true));

    try {
      if (fileImage != null) {
        // Upload image to storage
        String imageUrl = await storeFileToStorage(
            file: fileImage,
            reference: '${Constants.userImages}/${userModel.uid}');

        userModel.image = imageUrl;
      }

      userModel.lastSeen = DateTime.now().microsecondsSinceEpoch.toString();
      userModel.createdAt = DateTime.now().microsecondsSinceEpoch.toString();

      // Save user data to firestore
      await _firestore
          .collection(Constants.users)
          .doc(userModel.uid)
          .set(userModel.toMap());

      state = AsyncValue.data(AuthenticationState(
        isSuccessful: true,
        userModel: userModel,
        uid: userModel.uid,
      ));
      
      onSuccess();
    } on FirebaseException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      onFail(e.toString());
    }
  }

  // Get user stream
  Stream<DocumentSnapshot> userStream({required String userID}) {
    return _firestore.collection(Constants.users).doc(userID).snapshots();
  }

  // Get all users stream
  Stream<QuerySnapshot> getAllUsersStream({required String userID}) {
    return _firestore
        .collection(Constants.users)
        .where(Constants.uid, isNotEqualTo: userID)
        .snapshots();
  }

  // Add contact to user's contacts
  Future<void> addContact({
    required String contactID,
  }) async {
    final currentState = state.value;
    if (currentState?.userModel == null) return;
    
    try {
      // Add contact to user's contacts list
      await _firestore.collection(Constants.users).doc(currentState!.userModel!.uid).update({
        Constants.contactsUIDs: FieldValue.arrayUnion([contactID]),
      });
      
      // Update local model
      final updatedUser = currentState.userModel!.copyWith();
      updatedUser.contactsUIDs.add(contactID);
      
      state = AsyncValue.data(currentState.copyWith(userModel: updatedUser));
    } on FirebaseException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      debugPrint(e.toString());
    }
  }

  // Remove contact from user's contacts
  Future<void> removeContact({required String contactID}) async {
    final currentState = state.value;
    if (currentState?.userModel == null) return;
    
    try {
      // Remove contact from user's contacts list
      await _firestore.collection(Constants.users).doc(currentState!.userModel!.uid).update({
        Constants.contactsUIDs: FieldValue.arrayRemove([contactID]),
      });
      
      // Update local model
      final updatedUser = currentState.userModel!.copyWith();
      updatedUser.contactsUIDs.remove(contactID);
      
      state = AsyncValue.data(currentState.copyWith(userModel: updatedUser));
    } on FirebaseException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      debugPrint(e.toString());
    }
  }

  // Block a contact
  Future<void> blockContact({required String contactID}) async {
    final currentState = state.value;
    if (currentState?.userModel == null) return;
    
    try {
      // Add contact to blocked list
      await _firestore.collection(Constants.users).doc(currentState!.userModel!.uid).update({
        Constants.blockedUIDs: FieldValue.arrayUnion([contactID]),
      });
      
      // Update local model
      final updatedUser = currentState.userModel!.copyWith();
      updatedUser.blockedUIDs.add(contactID);
      
      state = AsyncValue.data(currentState.copyWith(userModel: updatedUser));
    } on FirebaseException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      debugPrint(e.toString());
    }
  }

  // Unblock a contact
  Future<void> unblockContact({required String contactID}) async {
    final currentState = state.value;
    if (currentState?.userModel == null) return;
    
    try {
      // Remove contact from blocked list
      await _firestore.collection(Constants.users).doc(currentState!.userModel!.uid).update({
        Constants.blockedUIDs: FieldValue.arrayRemove([contactID]),
      });
      
      // Update local model
      final updatedUser = currentState.userModel!.copyWith();
      updatedUser.blockedUIDs.remove(contactID);
      
      state = AsyncValue.data(currentState.copyWith(userModel: updatedUser));
    } on FirebaseException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      debugPrint(e.toString());
    }
  }

  // Get a list of contacts
  Future<List<UserModel>> getContactsList(
    String uid,
    List<String> groupMembersUIDs,
  ) async {
    List<UserModel> contactsList = [];

    DocumentSnapshot documentSnapshot =
        await _firestore.collection(Constants.users).doc(uid).get();

    List<dynamic> contactsUIDs = documentSnapshot.get(Constants.contactsUIDs);

    for (String contactUID in contactsUIDs) {
      // If groupMembersUIDs list is not empty and contains the contactUID we skip this contact
      if (groupMembersUIDs.isNotEmpty && groupMembersUIDs.contains(contactUID)) {
        continue;
      }
      DocumentSnapshot documentSnapshot =
          await _firestore.collection(Constants.users).doc(contactUID).get();
      UserModel contact =
          UserModel.fromMap(documentSnapshot.data() as Map<String, dynamic>);
      contactsList.add(contact);
    }

    return contactsList;
  }

  // Get a list of blocked contacts
  Future<List<UserModel>> getBlockedContactsList({
    required String uid,
  }) async {
    List<UserModel> blockedContactsList = [];

    DocumentSnapshot documentSnapshot =
        await _firestore.collection(Constants.users).doc(uid).get();

    List<dynamic> blockedUIDs = documentSnapshot.get(Constants.blockedUIDs);

    for (String blockedUID in blockedUIDs) {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection(Constants.users)
          .doc(blockedUID)
          .get();
      UserModel blockedContact =
          UserModel.fromMap(documentSnapshot.data() as Map<String, dynamic>);
      blockedContactsList.add(blockedContact);
    }

    return blockedContactsList;
  }

  // Search for users by phone number
  Future<UserModel?> searchUserByPhoneNumber({
    required String phoneNumber,
  }) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(Constants.users)
          .where(Constants.phoneNumber, isEqualTo: phoneNumber)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      return UserModel.fromMap(
          querySnapshot.docs.first.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error searching user: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.clear();
    
    // Reset state
    state = const AsyncValue.data(AuthenticationState());
  }

  // Update user profile data in Firestore
  Future<void> updateUserProfile(UserModel updatedUser) async {
    state = AsyncValue.data(const AuthenticationState(isLoading: true));
    
    try {
      // Update user data in Firestore
      await _firestore
          .collection(Constants.users)
          .doc(updatedUser.uid)
          .update(updatedUser.toMap());

      // Update local user model
      final currentState = state.value ?? const AuthenticationState();
      
      state = AsyncValue.data(currentState.copyWith(
        userModel: updatedUser,
        isLoading: false,
      ));

      // Save updated user data to shared preferences
      await saveUserDataToSharedPreferences();
    } on FirebaseException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      throw e.toString();
    }
  }
}
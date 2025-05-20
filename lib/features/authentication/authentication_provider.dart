// lib/features/authentication/authentication_provider.dart
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
import 'package:textgb/services/api_service.dart';
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
  final List<UserModel>? savedAccounts; // Added for account switching

  const AuthenticationState({
    this.isLoading = false,
    this.isSuccessful = false,
    this.uid,
    this.phoneNumber,
    this.userModel,
    this.error,
    this.savedAccounts,
  });

  AuthenticationState copyWith({
    bool? isLoading,
    bool? isSuccessful,
    String? uid,
    String? phoneNumber,
    UserModel? userModel,
    String? error,
    List<UserModel>? savedAccounts,
  }) {
    return AuthenticationState(
      isLoading: isLoading ?? this.isLoading,
      isSuccessful: isSuccessful ?? this.isSuccessful,
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userModel: userModel ?? this.userModel,
      error: error,
      savedAccounts: savedAccounts ?? this.savedAccounts,
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
      final savedAccounts = await getSavedAccounts();
      
      return AuthenticationState(
        isSuccessful: true,
        uid: _auth.currentUser!.uid,
        phoneNumber: _auth.currentUser!.phoneNumber,
        userModel: userModel,
        savedAccounts: savedAccounts,
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
    
    // Save account to saved accounts list
    await addAccountToSavedAccounts(currentState.userModel!);
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

  // NEW METHODS FOR ACCOUNT SWITCHING
  
  // Get saved accounts from SharedPreferences
  Future<List<UserModel>> getSavedAccounts() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    final savedAccountsJson = sharedPreferences.getStringList('savedAccounts') ?? [];
    
    List<UserModel> savedAccounts = [];
    for (String accountJson in savedAccountsJson) {
      try {
        savedAccounts.add(UserModel.fromMap(jsonDecode(accountJson)));
      } catch (e) {
        debugPrint('Error parsing saved account: $e');
      }
    }
    
    // Update state with saved accounts
    final currentState = state.value ?? const AuthenticationState();
    state = AsyncValue.data(currentState.copyWith(savedAccounts: savedAccounts));
    
    return savedAccounts;
  }
  
  // Add account to saved accounts list
  Future<void> addAccountToSavedAccounts(UserModel userModel) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    List<String> savedAccountsJson = sharedPreferences.getStringList('savedAccounts') ?? [];
    
    // Convert accounts to list of UserModels
    List<UserModel> savedAccounts = [];
    for (String accountJson in savedAccountsJson) {
      try {
        savedAccounts.add(UserModel.fromMap(jsonDecode(accountJson)));
      } catch (e) {
        debugPrint('Error parsing saved account: $e');
      }
    }
    
    // Check if account already exists
    bool accountExists = savedAccounts.any((account) => account.uid == userModel.uid);
    if (!accountExists) {
      // Add the account
      savedAccountsJson.add(jsonEncode(userModel.toMap()));
      await sharedPreferences.setStringList('savedAccounts', savedAccountsJson);
      
      // Add to local list
      savedAccounts.add(userModel);
      
      // Update state
      final currentState = state.value ?? const AuthenticationState();
      state = AsyncValue.data(currentState.copyWith(savedAccounts: savedAccounts));
    }
  }
  
  // Switch to another account
  Future<void> switchAccount(UserModel selectedAccount) async {
    state = AsyncValue.data(const AuthenticationState(isLoading: true));
    
    try {
      // Sign out current user
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }
      
      // We need to sign in with the selected account
      // This would require getting credentials for the selected account
      // Since we can't have stored credentials for security reasons,
      // we'd typically prompt the user for verification
      
      // For demonstration, we'll simply update the state to show loading
      // In a real app, you'd need to implement the authentication flow
      // specific to your auth method (phone, email, etc.)
      
      // Placeholder for authentication logic
      // After successful authentication, you would:
      
      // 1. Update SharedPreferences with the selected account
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.setString(
          Constants.userModel, jsonEncode(selectedAccount.toMap()));
      
      // 2. Update state with the new user model
      final savedAccounts = await getSavedAccounts();
      state = AsyncValue.data(AuthenticationState(
        isSuccessful: true,
        uid: selectedAccount.uid,
        phoneNumber: selectedAccount.phoneNumber,
        userModel: selectedAccount,
        savedAccounts: savedAccounts,
      ));
      
      // Not tracking online status anymore
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      throw e.toString();
    }
  }
  
  // Remove account from saved accounts
  Future<void> removeAccount(String uid) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    List<String> savedAccountsJson = sharedPreferences.getStringList('savedAccounts') ?? [];
    
    // Convert accounts to list of UserModels
    List<UserModel> savedAccounts = [];
    for (String accountJson in savedAccountsJson) {
      try {
        savedAccounts.add(UserModel.fromMap(jsonDecode(accountJson)));
      } catch (e) {
        debugPrint('Error parsing saved account: $e');
      }
    }
    
    // Remove the account
    savedAccounts.removeWhere((account) => account.uid == uid);
    
    // Save updated list
    List<String> updatedAccountsJson = savedAccounts.map((account) => 
        jsonEncode(account.toMap())).toList();
    await sharedPreferences.setStringList('savedAccounts', updatedAccountsJson);
    
    // Update state
    final currentState = state.value ?? const AuthenticationState();
    state = AsyncValue.data(currentState.copyWith(savedAccounts: savedAccounts));
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

  // Add this method to lib/features/authentication/authentication_provider.dart class

// Get user data by ID
Future<UserModel?> getUserDataById(String userId) async {
  try {
    DocumentSnapshot documentSnapshot =
        await _firestore.collection(Constants.users).doc(userId).get();
    
    if (!documentSnapshot.exists) return null;
    
    return UserModel.fromMap(documentSnapshot.data() as Map<String, dynamic>);
  } catch (e) {
    debugPrint('Error getting user by ID: $e');
    return null;
  }
}

  Future<void> verifyAndRegisterUser({
  required UserModel userModel,
  required File? fileImage,
  required Function onSuccess,
  required Function onFail,
}) async {
  try {
    // First check if user exists in our backend
    final result = await ApiService.verifyToken();
    
    if (result['exists'] == true) {
      // User already exists, get data
      final userData = result['data'];
      final user = UserModel.fromMap(userData);
      
      state = AsyncValue.data(AuthenticationState(
        isSuccessful: true,
        userModel: user,
        uid: user.uid,
      ));
      
      onSuccess();
    } else {
      // User does not exist, register
      final user = await ApiService.registerUser(
        name: userModel.name,
        aboutMe: userModel.aboutMe,
        imageFile: fileImage,
      );
      
      state = AsyncValue.data(AuthenticationState(
        isSuccessful: true,
        userModel: user,
        uid: user.uid,
      ));
      
      onSuccess();
    }
  } catch (e) {
    state = AsyncValue.error(e, StackTrace.current);
    onFail(e.toString());
  }
}
  
  // Sign out user
  Future<void> signOut() async {
    state = AsyncValue.data(const AuthenticationState(isLoading: true));
    
    try {
      // No need to update online status when signing out
      await _auth.signOut();
      
      // Clear local user data
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.remove(Constants.userModel);
      
      state = AsyncValue.data(const AuthenticationState());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      throw e.toString();
    }
  }
}
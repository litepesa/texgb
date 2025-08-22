// lib/features/authentication/authentication_provider.dart (Updated)
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import '../repositories/auth_repository.dart';
import 'auth_repository_provider.dart';

part 'authentication_provider.g.dart';

// State class for authentication (unchanged)
class AuthenticationState {
  final bool isLoading;
  final bool isSuccessful;
  final String? uid;
  final String? phoneNumber;
  final UserModel? userModel;
  final String? error;
  final List<UserModel>? savedAccounts;

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
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  FutureOr<AuthenticationState> build() async {
    // Check authentication state on initialization
    final isAuthenticated = await checkAuthenticationState();
    
    if (isAuthenticated && _repository.currentUserId != null) {
      final userModel = await getUserDataFromFireStore();
      await saveUserDataToSharedPreferences();
      final savedAccounts = await getSavedAccounts();
      
      return AuthenticationState(
        isSuccessful: true,
        uid: _repository.currentUserId,
        phoneNumber: _repository.currentUserPhoneNumber,
        userModel: userModel,
        savedAccounts: savedAccounts,
      );
    }
    
    return const AuthenticationState();
  }

  // Check authentication state
  Future<bool> checkAuthenticationState() async {
    try {
      return await _repository.checkAuthenticationState();
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return false;
    }
  }

  // Check if user exists
  Future<bool> checkUserExists() async {
    final currentState = state.value ?? const AuthenticationState();
    final uid = currentState.uid ?? _repository.currentUserId;
    
    if (uid == null) return false;
    
    try {
      return await _repository.checkUserExists(uid);
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return false;
    }
  }

  // Get user data from firestore
  Future<UserModel?> getUserDataFromFireStore() async {
    final currentState = state.value ?? const AuthenticationState();
    final uid = currentState.uid ?? _repository.currentUserId;
    
    if (uid == null) return null;
    
    try {
      final userModel = await _repository.getUserDataFromFireStore(uid);
      
      if (userModel != null) {
        // Update state with user model
        state = AsyncValue.data(currentState.copyWith(userModel: userModel));
      }
      
      return userModel;
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return null;
    }
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

    try {
      await _repository.signInWithPhoneNumber(
        phoneNumber: phoneNumber,
        context: context,
      );
      
      state = AsyncValue.data(AuthenticationState(
        isSuccessful: true,
        uid: _repository.currentUserId,
        phoneNumber: _repository.currentUserPhoneNumber,
      ));
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      showSnackBar(context, e.message);
    }
  }

  // Verify OTP code
  Future<void> verifyOTPCode({
    required String verificationId,
    required String otpCode,
    required BuildContext context,
    required Function onSuccess,
  }) async {
    state = AsyncValue.data(const AuthenticationState(isLoading: true));

    try {
      await _repository.verifyOTPCode(
        verificationId: verificationId,
        otpCode: otpCode,
        context: context,
        onSuccess: onSuccess,
      );
      
      state = AsyncValue.data(AuthenticationState(
        isSuccessful: true,
        uid: _repository.currentUserId,
        phoneNumber: _repository.currentUserPhoneNumber,
      ));
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      showSnackBar(context, e.message);
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
      await _repository.saveUserDataToFireStore(
        userModel: userModel,
        fileImage: fileImage,
        onSuccess: () {
          state = AsyncValue.data(AuthenticationState(
            isSuccessful: true,
            userModel: userModel,
            uid: userModel.uid,
          ));
          onSuccess();
        },
        onFail: (error) {
          state = AsyncValue.error(error, StackTrace.current);
          onFail();
        },
      );
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      onFail();
    }
  }

  // Get user stream
  Stream<DocumentSnapshot> userStream({required String userID}) {
    return _repository.userStream(userID: userID);
  }

  // Get all users stream
  Stream<QuerySnapshot> getAllUsersStream({required String userID}) {
    return _repository.getAllUsersStream(userID: userID);
  }

  // Add contact to user's contacts
  Future<void> addContact({required String contactID}) async {
    final currentState = state.value;
    if (currentState?.userModel == null) return;
    
    try {
      await _repository.addContact(
        userUid: currentState!.userModel!.uid,
        contactId: contactID,
      );
      
      // Update local model
      final updatedUser = currentState.userModel!.copyWith();
      updatedUser.contactsUIDs.add(contactID);
      
      state = AsyncValue.data(currentState.copyWith(userModel: updatedUser));
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      debugPrint(e.toString());
    }
  }

  // Remove contact from user's contacts
  Future<void> removeContact({required String contactID}) async {
    final currentState = state.value;
    if (currentState?.userModel == null) return;
    
    try {
      await _repository.removeContact(
        userUid: currentState!.userModel!.uid,
        contactId: contactID,
      );
      
      // Update local model
      final updatedUser = currentState.userModel!.copyWith();
      updatedUser.contactsUIDs.remove(contactID);
      
      state = AsyncValue.data(currentState.copyWith(userModel: updatedUser));
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      debugPrint(e.toString());
    }
  }

  // Block a contact
  Future<void> blockContact({required String contactID}) async {
    final currentState = state.value;
    if (currentState?.userModel == null) return;
    
    try {
      await _repository.blockContact(
        userUid: currentState!.userModel!.uid,
        contactId: contactID,
      );
      
      // Update local model
      final updatedUser = currentState.userModel!.copyWith();
      updatedUser.blockedUIDs.add(contactID);
      
      state = AsyncValue.data(currentState.copyWith(userModel: updatedUser));
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      debugPrint(e.toString());
    }
  }

  // Unblock a contact
  Future<void> unblockContact({required String contactID}) async {
    final currentState = state.value;
    if (currentState?.userModel == null) return;
    
    try {
      await _repository.unblockContact(
        userUid: currentState!.userModel!.uid,
        contactId: contactID,
      );
      
      // Update local model
      final updatedUser = currentState.userModel!.copyWith();
      updatedUser.blockedUIDs.remove(contactID);
      
      state = AsyncValue.data(currentState.copyWith(userModel: updatedUser));
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      debugPrint(e.toString());
    }
  }

  // Get a list of contacts
  Future<List<UserModel>> getContactsList(
    String uid,
    List<String> groupMembersUIDs,
  ) async {
    try {
      return await _repository.getContactsList(uid, groupMembersUIDs);
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return [];
    }
  }

  // Get a list of blocked contacts
  Future<List<UserModel>> getBlockedContactsList({required String uid}) async {
    try {
      return await _repository.getBlockedContactsList(uid: uid);
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return [];
    }
  }

  // Search for users by phone number
  Future<UserModel?> searchUserByPhoneNumber({required String phoneNumber}) async {
    try {
      return await _repository.searchUserByPhoneNumber(phoneNumber: phoneNumber);
    } on AuthRepositoryException catch (e) {
      debugPrint('Error searching user: ${e.message}');
      return null;
    }
  }

  // Get user data by ID
  Future<UserModel?> getUserDataById(String userId) async {
    try {
      return await _repository.getUserDataById(userId);
    } on AuthRepositoryException catch (e) {
      debugPrint('Error getting user by ID: ${e.message}');
      return null;
    }
  }

  // Update user profile data
  Future<void> updateUserProfile(UserModel updatedUser) async {
    state = AsyncValue.data(const AuthenticationState(isLoading: true));
    
    try {
      await _repository.updateUserProfile(updatedUser);

      // Update local user model
      final currentState = state.value ?? const AuthenticationState();
      
      state = AsyncValue.data(currentState.copyWith(
        userModel: updatedUser,
        isLoading: false,
      ));

      // Save updated user data to shared preferences
      await saveUserDataToSharedPreferences();
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      throw e.message;
    }
  }

  // Account switching methods (kept same for now, can be refactored later if needed)
  
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
      await _repository.signOut();
      
      // Update SharedPreferences with the selected account
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.setString(
          Constants.userModel, jsonEncode(selectedAccount.toMap()));
      
      // Update state with the new user model
      final savedAccounts = await getSavedAccounts();
      state = AsyncValue.data(AuthenticationState(
        isSuccessful: true,
        uid: selectedAccount.uid,
        phoneNumber: selectedAccount.phoneNumber,
        userModel: selectedAccount,
        savedAccounts: savedAccounts,
      ));
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      throw e.message;
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
  
  // Sign out user
  Future<void> signOut() async {
    state = AsyncValue.data(const AuthenticationState(isLoading: true));
    
    try {
      await _repository.signOut();
      
      // Clear local user data
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.remove(Constants.userModel);
      
      state = AsyncValue.data(const AuthenticationState());
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      throw e.message;
    }
  }

  // Store file to storage (kept for backward compatibility)
  Future<String> storeFileToStorage({required File file, required String reference}) async {
    try {
      return await _repository.storeFileToStorage(file: file, reference: reference);
    } on AuthRepositoryException catch (e) {
      throw e.message;
    }
  }
}
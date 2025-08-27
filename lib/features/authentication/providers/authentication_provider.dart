// lib/features/authentication/providers/authentication_provider.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import '../repositories/auth_repository.dart';
import 'auth_repository_provider.dart';

part 'authentication_provider.g.dart';

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
    final isAuthenticated = await checkAuthenticationState();
    
    if (isAuthenticated && _repository.currentUserId != null) {
      final userModel = await getUserDataFromBackend();
      if (userModel != null) {
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
    }
    
    return const AuthenticationState();
  }

  Future<bool> checkAuthenticationState() async {
    try {
      return await _repository.checkAuthenticationState();
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return false;
    }
  }

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

  Future<UserModel?> getUserDataFromBackend() async {
    final currentState = state.value ?? const AuthenticationState();
    final uid = currentState.uid ?? _repository.currentUserId;
    
    if (uid == null) return null;
    
    try {
      final userModel = await _repository.getUserDataFromBackend(uid);
      
      if (userModel != null) {
        state = AsyncValue.data(currentState.copyWith(userModel: userModel));
      }
      
      return userModel;
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return null;
    }
  }

  Future<void> refreshCurrentUser() async {
    final currentState = state.value;
    if (currentState?.userModel?.uid == null) return;

    try {
      final freshUserData = await _repository.getUserDataFromBackend(currentState!.userModel!.uid);
      
      if (freshUserData != null) {
        state = AsyncValue.data(currentState.copyWith(
          userModel: freshUserData,
        ));
        
        await saveUserDataToSharedPreferences();
      }
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
    }
  }

  Future<void> saveUserDataToSharedPreferences() async {
    final currentState = state.value ?? const AuthenticationState();
    if (currentState.userModel == null) return;
    
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString(
        Constants.userModel, jsonEncode(currentState.userModel!.toMap()));
    
    await addAccountToSavedAccounts(currentState.userModel!);
  }

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
        onSuccess: () async {
          await syncUserWithBackend();
          onSuccess();
        },
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

  Future<void> syncUserWithBackend() async {
    final uid = _repository.currentUserId;
    if (uid == null) return;

    try {
      final userModel = await _repository.syncUserWithBackend(uid);
      if (userModel != null) {
        final currentState = state.value ?? const AuthenticationState();
        state = AsyncValue.data(currentState.copyWith(
          userModel: userModel,
          uid: uid,
        ));
        await saveUserDataToSharedPreferences();
      }
    } on AuthRepositoryException catch (e) {
      debugPrint('Failed to sync user with backend: ${e.message}');
    }
  }

  Future<void> saveUserDataToBackend({
    required UserModel userModel,
    required File? fileImage,
    required Function onSuccess,
    required Function onFail,
  }) async {
    state = AsyncValue.data(const AuthenticationState(isLoading: true));

    try {
      await _repository.saveUserDataToBackend(
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

  Future<void> uploadProfileImageAndUpdateUser({
    required File imageFile, 
    required UserModel currentUser,
    String? name,
    String? bio,
  }) async {
    state = AsyncValue.data(const AuthenticationState(isLoading: true));
    
    try {
      final imageUrl = await _repository.storeFileToStorage(
        file: imageFile,
        reference: 'profile/${currentUser.uid}',
      );
      
      final updatedUser = currentUser.copyWith(
        profileImage: imageUrl,
        name: name ?? currentUser.name,
        bio: bio ?? currentUser.bio,
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
      
      await updateUserProfile(updatedUser);
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      throw e.toString();
    }
  }

  Future<void> updateUserProfile(UserModel updatedUser) async {
    try {
      await _repository.updateUserProfile(updatedUser);

      final currentState = state.value ?? const AuthenticationState();
      state = AsyncValue.data(currentState.copyWith(
        userModel: updatedUser,
        isLoading: false,
      ));

      await saveUserDataToSharedPreferences();
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      throw e.toString();
    }
  }

  Future<void> addToFavorites({required String dramaId}) async {
    final currentState = state.value;
    if (currentState?.userModel == null) return;
    
    try {
      await _repository.addToFavorites(
        userUid: currentState!.userModel!.uid,
        dramaId: dramaId,
      );
      
      final updatedUser = currentState.userModel!.copyWith(
        favoriteDramas: [...currentState.userModel!.favoriteDramas, dramaId],
      );
      
      state = AsyncValue.data(currentState.copyWith(userModel: updatedUser));
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      debugPrint(e.toString());
    }
  }

  Future<void> removeFromFavorites({required String dramaId}) async {
    final currentState = state.value;
    if (currentState?.userModel == null) return;
    
    try {
      await _repository.removeFromFavorites(
        userUid: currentState!.userModel!.uid,
        dramaId: dramaId,
      );
      
      final updatedFavorites = List<String>.from(currentState.userModel!.favoriteDramas)
        ..remove(dramaId);
      final updatedUser = currentState.userModel!.copyWith(
        favoriteDramas: updatedFavorites,
      );
      
      state = AsyncValue.data(currentState.copyWith(userModel: updatedUser));
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      debugPrint(e.toString());
    }
  }

  Future<void> addToWatchHistory({required String episodeId}) async {
    final currentState = state.value;
    if (currentState?.userModel == null) return;
    
    try {
      await _repository.addToWatchHistory(
        userUid: currentState!.userModel!.uid,
        episodeId: episodeId,
      );
      
      final updatedUser = currentState.userModel!.copyWith(
        watchHistory: [...currentState.userModel!.watchHistory, episodeId],
      );
      
      state = AsyncValue.data(currentState.copyWith(userModel: updatedUser));
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      debugPrint(e.toString());
    }
  }

  Future<void> updateDramaProgress({required String dramaId, required int episodeNumber}) async {
    final currentState = state.value;
    if (currentState?.userModel == null) return;
    
    try {
      await _repository.updateDramaProgress(
        userUid: currentState!.userModel!.uid,
        dramaId: dramaId,
        episodeNumber: episodeNumber,
      );
      
      final updatedProgress = Map<String, int>.from(currentState.userModel!.dramaProgress);
      updatedProgress[dramaId] = episodeNumber;
      final updatedUser = currentState.userModel!.copyWith(
        dramaProgress: updatedProgress,
      );
      
      state = AsyncValue.data(currentState.copyWith(userModel: updatedUser));
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      debugPrint(e.toString());
    }
  }

  Future<void> unlockDrama({required String dramaId}) async {
    final currentState = state.value;
    if (currentState?.userModel == null) return;
    
    try {
      await _repository.unlockDrama(
        userUid: currentState!.userModel!.uid,
        dramaId: dramaId,
      );
      
      final updatedUser = currentState.userModel!.copyWith(
        unlockedDramas: [...currentState.userModel!.unlockedDramas, dramaId],
      );
      
      state = AsyncValue.data(currentState.copyWith(userModel: updatedUser));
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      debugPrint(e.toString());
    }
  }

  Future<UserModel?> getUserDataById(String userId) async {
    try {
      return await _repository.getUserDataById(userId);
    } on AuthRepositoryException catch (e) {
      debugPrint('Error getting user by ID: ${e.message}');
      return null;
    }
  }

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
    
    final currentState = state.value ?? const AuthenticationState();
    state = AsyncValue.data(currentState.copyWith(savedAccounts: savedAccounts));
    
    return savedAccounts;
  }
  
  Future<void> addAccountToSavedAccounts(UserModel userModel) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    List<String> savedAccountsJson = sharedPreferences.getStringList('savedAccounts') ?? [];
    
    List<UserModel> savedAccounts = [];
    for (String accountJson in savedAccountsJson) {
      try {
        savedAccounts.add(UserModel.fromMap(jsonDecode(accountJson)));
      } catch (e) {
        debugPrint('Error parsing saved account: $e');
      }
    }
    
    bool accountExists = savedAccounts.any((account) => account.uid == userModel.uid);
    if (!accountExists) {
      savedAccountsJson.add(jsonEncode(userModel.toMap()));
      await sharedPreferences.setStringList('savedAccounts', savedAccountsJson);
      
      savedAccounts.add(userModel);
      
      final currentState = state.value ?? const AuthenticationState();
      state = AsyncValue.data(currentState.copyWith(savedAccounts: savedAccounts));
    }
  }
  
  Future<void> switchAccount(UserModel selectedAccount) async {
    state = AsyncValue.data(const AuthenticationState(isLoading: true));
    
    try {
      await _repository.signOut();
      
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.setString(
          Constants.userModel, jsonEncode(selectedAccount.toMap()));
      
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
  
  Future<void> removeAccount(String uid) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    List<String> savedAccountsJson = sharedPreferences.getStringList('savedAccounts') ?? [];
    
    List<UserModel> savedAccounts = [];
    for (String accountJson in savedAccountsJson) {
      try {
        savedAccounts.add(UserModel.fromMap(jsonDecode(accountJson)));
      } catch (e) {
        debugPrint('Error parsing saved account: $e');
      }
    }
    
    savedAccounts.removeWhere((account) => account.uid == uid);
    
    List<String> updatedAccountsJson = savedAccounts.map((account) => 
        jsonEncode(account.toMap())).toList();
    await sharedPreferences.setStringList('savedAccounts', updatedAccountsJson);
    
    final currentState = state.value ?? const AuthenticationState();
    state = AsyncValue.data(currentState.copyWith(savedAccounts: savedAccounts));
  }
  
  Future<void> signOut() async {
    state = AsyncValue.data(const AuthenticationState(isLoading: true));
    
    try {
      await _repository.signOut();
      
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.remove(Constants.userModel);
      
      state = AsyncValue.data(const AuthenticationState());
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      throw e.message;
    }
  }

  Future<String> storeFileToStorage({required File file, required String reference}) async {
    try {
      return await _repository.storeFileToStorage(file: file, reference: reference);
    } on AuthRepositoryException catch (e) {
      throw e.message;
    }
  }
}
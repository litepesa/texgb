// lib/features/authentication/providers/authentication_provider.dart (Updated for Channel-based)
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import '../repositories/auth_repository.dart';
import 'auth_repository_provider.dart';

part 'authentication_provider.g.dart';

// State class for authentication (updated for channels)
class AuthenticationState {
  final bool isLoading;
  final bool isSuccessful;
  final String? uid;
  final String? phoneNumber;
  final ChannelModel? channelModel; // Changed from UserModel to ChannelModel
  final String? error;
  final List<ChannelModel>? savedChannels; // Changed from savedAccounts to savedChannels

  const AuthenticationState({
    this.isLoading = false,
    this.isSuccessful = false,
    this.uid,
    this.phoneNumber,
    this.channelModel,
    this.error,
    this.savedChannels,
  });

  AuthenticationState copyWith({
    bool? isLoading,
    bool? isSuccessful,
    String? uid,
    String? phoneNumber,
    ChannelModel? channelModel,
    String? error,
    List<ChannelModel>? savedChannels,
  }) {
    return AuthenticationState(
      isLoading: isLoading ?? this.isLoading,
      isSuccessful: isSuccessful ?? this.isSuccessful,
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      channelModel: channelModel ?? this.channelModel,
      error: error,
      savedChannels: savedChannels ?? this.savedChannels,
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
      final channelModel = await getChannelDataFromFireStore();
      await saveChannelDataToSharedPreferences();
      final savedChannels = await getSavedChannels();
      
      return AuthenticationState(
        isSuccessful: true,
        uid: _repository.currentUserId,
        phoneNumber: _repository.currentUserPhoneNumber,
        channelModel: channelModel,
        savedChannels: savedChannels,
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

  // Check if channel exists
  Future<bool> checkChannelExists() async {
    final currentState = state.value ?? const AuthenticationState();
    final uid = currentState.uid ?? _repository.currentUserId;
    
    if (uid == null) return false;
    
    try {
      return await _repository.checkChannelExists(uid);
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return false;
    }
  }

  // Get channel data from firestore
  Future<ChannelModel?> getChannelDataFromFireStore() async {
    final currentState = state.value ?? const AuthenticationState();
    final uid = currentState.uid ?? _repository.currentUserId;
    
    if (uid == null) return null;
    
    try {
      final channelModel = await _repository.getChannelDataFromFireStore(uid);
      
      if (channelModel != null) {
        // Update state with channel model
        state = AsyncValue.data(currentState.copyWith(channelModel: channelModel));
      }
      
      return channelModel;
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return null;
    }
  }

  // Save channel data to shared preferences
  Future<void> saveChannelDataToSharedPreferences() async {
    final currentState = state.value ?? const AuthenticationState();
    if (currentState.channelModel == null) return;
    
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString(
        'channelModel', jsonEncode(currentState.channelModel!.toMap()));
    
    // Save channel to saved channels list
    await addChannelToSavedChannels(currentState.channelModel!);
  }

  // Get data from shared preferences
  Future<void> getChannelDataFromSharedPreferences() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String channelModelString = sharedPreferences.getString('channelModel') ?? '';
    
    if (channelModelString.isEmpty) return;
    
    final Map<String, dynamic> channelMap = jsonDecode(channelModelString);
    final channelModel = ChannelModel.fromMap(channelMap, channelMap['id'] ?? '');
    final currentState = state.value ?? const AuthenticationState();
    
    state = AsyncValue.data(currentState.copyWith(
      channelModel: channelModel,
      uid: channelModel.ownerId,
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

  // Save channel data to firestore
  Future<void> saveChannelDataToFireStore({
    required ChannelModel channelModel,
    required File? profileImage,
    required File? coverImage,
    required Function onSuccess,
    required Function onFail,
  }) async {
    state = AsyncValue.data(const AuthenticationState(isLoading: true));

    try {
      await _repository.saveChannelDataToFireStore(
        channelModel: channelModel,
        profileImage: profileImage,
        coverImage: coverImage,
        onSuccess: () {
          state = AsyncValue.data(AuthenticationState(
            isSuccessful: true,
            channelModel: channelModel,
            uid: channelModel.ownerId,
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

  // Get channel stream
  Stream<DocumentSnapshot> channelStream({required String channelId}) {
    return _repository.channelStream(channelId: channelId);
  }

  // Get all channels stream
  Stream<QuerySnapshot> getAllChannelsStream({required String excludeChannelId}) {
    return _repository.getAllChannelsStream(excludeChannelId: excludeChannelId);
  }

  // Follow/Unfollow channel
  Future<void> followChannel({required String channelId}) async {
    final currentState = state.value;
    if (currentState?.channelModel == null) return;
    
    try {
      await _repository.followChannel(
        followerId: currentState!.channelModel!.id,
        channelId: channelId,
      );
      
      // Update local model if needed
      // This would depend on your specific implementation
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      debugPrint(e.toString());
    }
  }

  Future<void> unfollowChannel({required String channelId}) async {
    final currentState = state.value;
    if (currentState?.channelModel == null) return;
    
    try {
      await _repository.unfollowChannel(
        followerId: currentState!.channelModel!.id,
        channelId: channelId,
      );
      
      // Update local model if needed
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      debugPrint(e.toString());
    }
  }

  // Search for channels
  Future<List<ChannelModel>> searchChannels({required String query}) async {
    try {
      return await _repository.searchChannels(query: query);
    } on AuthRepositoryException catch (e) {
      debugPrint('Error searching channels: ${e.message}');
      return [];
    }
  }

  // Get channel data by ID
  Future<ChannelModel?> getChannelDataById(String channelId) async {
    try {
      return await _repository.getChannelDataById(channelId);
    } on AuthRepositoryException catch (e) {
      debugPrint('Error getting channel by ID: ${e.message}');
      return null;
    }
  }

  // Update channel profile data
  Future<void> updateChannelProfile(ChannelModel updatedChannel) async {
    state = AsyncValue.data(const AuthenticationState(isLoading: true));
    
    try {
      await _repository.updateChannelProfile(updatedChannel);

      // Update local channel model
      final currentState = state.value ?? const AuthenticationState();
      
      state = AsyncValue.data(currentState.copyWith(
        channelModel: updatedChannel,
        isLoading: false,
      ));

      // Save updated channel data to shared preferences
      await saveChannelDataToSharedPreferences();
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      throw e.message;
    }
  }

  // Channel switching methods
  
  // Get saved channels from SharedPreferences
  Future<List<ChannelModel>> getSavedChannels() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    final savedChannelsJson = sharedPreferences.getStringList('savedChannels') ?? [];
    
    List<ChannelModel> savedChannels = [];
    for (String channelJson in savedChannelsJson) {
      try {
        final Map<String, dynamic> channelMap = jsonDecode(channelJson);
        savedChannels.add(ChannelModel.fromMap(channelMap, channelMap['id'] ?? ''));
      } catch (e) {
        debugPrint('Error parsing saved channel: $e');
      }
    }
    
    // Update state with saved channels
    final currentState = state.value ?? const AuthenticationState();
    state = AsyncValue.data(currentState.copyWith(savedChannels: savedChannels));
    
    return savedChannels;
  }
  
  // Add channel to saved channels list
  Future<void> addChannelToSavedChannels(ChannelModel channelModel) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    List<String> savedChannelsJson = sharedPreferences.getStringList('savedChannels') ?? [];
    
    // Convert channels to list of ChannelModels
    List<ChannelModel> savedChannels = [];
    for (String channelJson in savedChannelsJson) {
      try {
        final Map<String, dynamic> channelMap = jsonDecode(channelJson);
        savedChannels.add(ChannelModel.fromMap(channelMap, channelMap['id'] ?? ''));
      } catch (e) {
        debugPrint('Error parsing saved channel: $e');
      }
    }
    
    // Check if channel already exists
    bool channelExists = savedChannels.any((channel) => channel.id == channelModel.id);
    if (!channelExists) {
      // Add the channel
      savedChannelsJson.add(jsonEncode(channelModel.toMap()));
      await sharedPreferences.setStringList('savedChannels', savedChannelsJson);
      
      // Add to local list
      savedChannels.add(channelModel);
      
      // Update state
      final currentState = state.value ?? const AuthenticationState();
      state = AsyncValue.data(currentState.copyWith(savedChannels: savedChannels));
    }
  }
  
  // Switch to another channel
  Future<void> switchChannel(ChannelModel selectedChannel) async {
    state = AsyncValue.data(const AuthenticationState(isLoading: true));
    
    try {
      // Sign out current user
      await _repository.signOut();
      
      // Update SharedPreferences with the selected channel
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.setString(
          'channelModel', jsonEncode(selectedChannel.toMap()));
      
      // Update state with the new channel model
      final savedChannels = await getSavedChannels();
      state = AsyncValue.data(AuthenticationState(
        isSuccessful: true,
        uid: selectedChannel.ownerId,
        phoneNumber: '', // Phone number might not be directly available in channel model
        channelModel: selectedChannel,
        savedChannels: savedChannels,
      ));
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      throw e.message;
    }
  }
  
  // Remove channel from saved channels
  Future<void> removeChannel(String channelId) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    List<String> savedChannelsJson = sharedPreferences.getStringList('savedChannels') ?? [];
    
    // Convert channels to list of ChannelModels
    List<ChannelModel> savedChannels = [];
    for (String channelJson in savedChannelsJson) {
      try {
        final Map<String, dynamic> channelMap = jsonDecode(channelJson);
        savedChannels.add(ChannelModel.fromMap(channelMap, channelMap['id'] ?? ''));
      } catch (e) {
        debugPrint('Error parsing saved channel: $e');
      }
    }
    
    // Remove the channel
    savedChannels.removeWhere((channel) => channel.id == channelId);
    
    // Save updated list
    List<String> updatedChannelsJson = savedChannels.map((channel) => 
        jsonEncode(channel.toMap())).toList();
    await sharedPreferences.setStringList('savedChannels', updatedChannelsJson);
    
    // Update state
    final currentState = state.value ?? const AuthenticationState();
    state = AsyncValue.data(currentState.copyWith(savedChannels: savedChannels));
  }
  
  // Sign out channel
  Future<void> signOut() async {
    state = AsyncValue.data(const AuthenticationState(isLoading: true));
    
    try {
      await _repository.signOut();
      
      // Clear local channel data
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.remove('channelModel');
      
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
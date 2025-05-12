import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';

part 'chat_activity_provider.g.dart';

/// State class for chat activity
class ChatActivityState {
  final bool isTyping;
  final bool isOnline;
  final String lastSeen;
  final bool isLoading;
  final String? error;
  
  const ChatActivityState({
    this.isTyping = false,
    this.isOnline = false,
    this.lastSeen = '',
    this.isLoading = false,
    this.error,
  });
  
  ChatActivityState copyWith({
    bool? isTyping,
    bool? isOnline,
    String? lastSeen,
    bool? isLoading,
    String? error,
  }) {
    return ChatActivityState(
      isTyping: isTyping ?? this.isTyping,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for managing chat activity indicators.
/// Handles online status, typing indicators, and read receipts.
@riverpod
class ChatActivityNotifier extends _$ChatActivityNotifier {
  late final FirebaseFirestore _firestore;
  Timer? _typingTimer;
  StreamSubscription? _userStatusSubscription;
  
  @override
  FutureOr<ChatActivityState> build(String contactUID) {
    _firestore = FirebaseFirestore.instance;
    
    // Register cleanup when this provider is disposed
    ref.onDispose(() {
      _typingTimer?.cancel();
      _userStatusSubscription?.cancel();
    });
    
    // Start listening to contact's activity
    return _listenToUserActivity(contactUID);
  }
  

  
  // Listen to user activity changes
  Future<ChatActivityState> _listenToUserActivity(String contactUID) async {
    state = const AsyncValue.loading();
    
    try {
      // Get initial user data
      final userDoc = await _firestore
          .collection(Constants.users)
          .doc(contactUID)
          .get();
      
      if (!userDoc.exists) {
        return const ChatActivityState(error: 'User not found');
      }
      
      final isOnline = userDoc.get(Constants.isOnline) as bool? ?? false;
      final lastSeen = userDoc.get(Constants.lastSeen) as String? ?? '';
      
      // Set up subscription to user status changes
      _userStatusSubscription = _firestore
          .collection(Constants.users)
          .doc(contactUID)
          .snapshots()
          .listen((snapshot) {
            if (!snapshot.exists) return;
            
            final updatedIsOnline = snapshot.get(Constants.isOnline) as bool? ?? false;
            final updatedLastSeen = snapshot.get(Constants.lastSeen) as String? ?? '';
            
            state = AsyncValue.data(state.value!.copyWith(
              isOnline: updatedIsOnline,
              lastSeen: updatedLastSeen,
            ));
          });
      
      // Set up subscription to typing indicators
      _listenToTypingIndicator(contactUID);
      
      return ChatActivityState(
        isOnline: isOnline,
        lastSeen: lastSeen,
      );
    } catch (e) {
      debugPrint('Error listening to user activity: $e');
      return ChatActivityState(error: e.toString());
    }
  }
  
  // Listen to typing indicator changes
  void _listenToTypingIndicator(String contactUID) {
    try {
      // Get current user ID
      final authState = ref.read(authenticationProvider);
      final currentUID = authState.value?.uid;
      
      if (currentUID == null) return;
      
      // Create chat ID
      final sortedUIDs = [currentUID, contactUID]..sort();
      final chatId = '${sortedUIDs[0]}-${sortedUIDs[1]}';
      
      // Listen to typing indicator
      _firestore
          .collection('typing_indicators')
          .doc(chatId)
          .snapshots()
          .listen((snapshot) {
            if (!snapshot.exists) {
              state = AsyncValue.data(state.value!.copyWith(isTyping: false));
              return;
            }
            
            final typingMap = snapshot.data() as Map<String, dynamic>;
            final isTyping = typingMap[contactUID] as bool? ?? false;
            
            state = AsyncValue.data(state.value!.copyWith(isTyping: isTyping));
          });
    } catch (e) {
      debugPrint('Error listening to typing indicator: $e');
    }
  }
  
  // Set typing indicator
  Future<void> setTypingStatus({required bool isTyping}) async {
    try {
      // Get current user ID
      final authState = ref.read(authenticationProvider);
      final currentUID = authState.value?.uid;
      
      if (currentUID == null) return;
      
      // Create chat ID
      final sortedUIDs = [currentUID, contactUID]..sort();
      final chatId = '${sortedUIDs[0]}-${sortedUIDs[1]}';
      
      // Update typing indicator
      await _firestore
          .collection('typing_indicators')
          .doc(chatId)
          .set({
            currentUID: isTyping,
          }, SetOptions(merge: true));
      
      // Set timer to automatically reset typing status
      if (isTyping) {
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 5), () {
          setTypingStatus(isTyping: false);
        });
      }
    } catch (e) {
      debugPrint('Error setting typing status: $e');
    }
  }
  
  // Format last seen time to a readable format
  String getFormattedLastSeen() {
    try {
      if (state.value?.isOnline ?? false) {
        return 'Online';
      }
      
      final lastSeen = state.value?.lastSeen ?? '';
      if (lastSeen.isEmpty) {
        return 'Last seen recently';
      }
      
      final lastSeenTimestamp = int.tryParse(lastSeen);
      if (lastSeenTimestamp == null) {
        return 'Last seen recently';
      }
      
      final lastSeenDateTime = DateTime.fromMicrosecondsSinceEpoch(lastSeenTimestamp);
      final now = DateTime.now();
      final difference = now.difference(lastSeenDateTime);
      
      if (difference.inSeconds < 60) {
        return 'Last seen just now';
      } else if (difference.inMinutes < 60) {
        return 'Last seen ${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        return 'Last seen ${difference.inHours} hours ago';
      } else if (difference.inDays < 7) {
        return 'Last seen ${difference.inDays} days ago';
      } else {
        // Format date
        final day = lastSeenDateTime.day.toString().padLeft(2, '0');
        final month = lastSeenDateTime.month.toString().padLeft(2, '0');
        final year = lastSeenDateTime.year;
        return 'Last seen on $day/$month/$year';
      }
    } catch (e) {
      debugPrint('Error formatting last seen: $e');
      return 'Last seen recently';
    }
  }
}
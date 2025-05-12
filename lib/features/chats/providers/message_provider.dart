import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/chats/providers/chat_provider.dart';
import 'package:textgb/features/chats/models/chat_message_model.dart';
import 'package:textgb/features/chats/providers/message_streams_provider.dart';
import 'package:textgb/features/chats/repository/message_repository.dart';
import 'package:textgb/models/user_model.dart';


part 'message_provider.g.dart';

/// Provider for message operations within a chat.
/// Handles sending and managing messages with a specific contact.
@riverpod
class MessageNotifier extends _$MessageNotifier {
  late final MessageRepository _messageRepository;
  
  @override
  FutureOr<List<ChatMessageModel>> build(String contactUID) {
    _messageRepository = MessageRepository();
    
    // Watch the message stream provider and update this provider's state
    ref.listen(messageStreamProvider(contactUID), (previous, messages) {
      if (messages is AsyncData) {
        state = AsyncData(messages.value);
        
        // Mark chat as seen when messages are loaded
        final authState = ref.read(authenticationProvider);
        final currentUID = authState.value?.uid;
        
        if (currentUID != null) {
          ref.read(chatNotifierProvider.notifier).markChatAsSeen(
            senderUID: currentUID,
            receiverUID: contactUID,
          );
        }
      } else if (messages is AsyncError) {
        state = AsyncError(messages.error, messages.stackTrace);
      }
    });
    
    // Return empty list initially
    return [];
  }
  
  // Send text message
  Future<void> sendTextMessage({
    required String message,
    String? repliedMessage,
    String? repliedTo,
    MessageEnum? repliedMessageType,
  }) async {
    if (message.trim().isEmpty) return;
    
    try {
      // Get current user data
      final authState = ref.read(authenticationProvider);
      final currentUser = authState.value?.userModel;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      await _messageRepository.sendTextMessage(
        message: message,
        senderUID: currentUser.uid,
        senderName: currentUser.name,
        senderImage: currentUser.image,
        receiverUID: contactUID,
        repliedMessage: repliedMessage,
        repliedTo: repliedTo,
        repliedMessageType: repliedMessageType,
      );
    } catch (e) {
      debugPrint('Error sending text message: $e');
      rethrow;
    }
  }
  
  // Send media message (image, video, audio, file)
  Future<void> sendMediaMessage({
    required File file,
    required MessageEnum messageType,
    required String message,
    String? repliedMessage,
    String? repliedTo,
    MessageEnum? repliedMessageType,
    int? mediaDuration,
    String? mediaName,
    int? mediaSize,
    String? thumbnailUrl,
  }) async {
    try {
      // Get current user data
      final authState = ref.read(authenticationProvider);
      final currentUser = authState.value?.userModel;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      await _messageRepository.sendMediaMessage(
        file: file,
        senderUID: currentUser.uid,
        senderName: currentUser.name,
        senderImage: currentUser.image,
        receiverUID: contactUID,
        messageType: messageType,
        message: message,
        repliedMessage: repliedMessage,
        repliedTo: repliedTo,
        repliedMessageType: repliedMessageType,
        mediaDuration: mediaDuration,
        mediaName: mediaName,
        mediaSize: mediaSize,
        thumbnailUrl: thumbnailUrl,
      );
    } catch (e) {
      debugPrint('Error sending media message: $e');
      rethrow;
    }
  }
  
  // Send location message
  Future<void> sendLocationMessage({
    required Map<String, dynamic> locationData,
    String? repliedMessage,
    String? repliedTo,
    MessageEnum? repliedMessageType,
  }) async {
    try {
      // Get current user data
      final authState = ref.read(authenticationProvider);
      final currentUser = authState.value?.userModel;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      await _messageRepository.sendLocationMessage(
        locationData: locationData,
        senderUID: currentUser.uid,
        senderName: currentUser.name,
        senderImage: currentUser.image,
        receiverUID: contactUID,
        repliedMessage: repliedMessage,
        repliedTo: repliedTo,
        repliedMessageType: repliedMessageType,
      );
    } catch (e) {
      debugPrint('Error sending location message: $e');
      rethrow;
    }
  }
  
  // Send contact message
  Future<void> sendContactMessage({
    required UserModel contactToShare,
    String? repliedMessage,
    String? repliedTo,
    MessageEnum? repliedMessageType,
  }) async {
    try {
      // Get current user data
      final authState = ref.read(authenticationProvider);
      final currentUser = authState.value?.userModel;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      await _messageRepository.sendContactMessage(
        contactToShare: contactToShare,
        senderUID: currentUser.uid,
        senderName: currentUser.name,
        senderImage: currentUser.image,
        receiverUID: contactUID,
        repliedMessage: repliedMessage,
        repliedTo: repliedTo,
        repliedMessageType: repliedMessageType,
      );
    } catch (e) {
      debugPrint('Error sending contact message: $e');
      rethrow;
    }
  }
  
  // Forward message to current contact
  Future<void> forwardMessage(ChatMessageModel message) async {
    try {
      // Get current user data
      final authState = ref.read(authenticationProvider);
      final currentUser = authState.value?.userModel;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      await _messageRepository.forwardMessage(
        message: message,
        senderUID: currentUser.uid,
        senderName: currentUser.name,
        senderImage: currentUser.image,
        receiverUID: contactUID,
      );
    } catch (e) {
      debugPrint('Error forwarding message: $e');
      rethrow;
    }
  }
  
  // Get messages by date (for date headers in chat UI)
  Map<String, List<ChatMessageModel>> getMessagesByDate() {
    final messages = state.value ?? [];
    
    // Group messages by date (YYYY-MM-DD)
    final Map<String, List<ChatMessageModel>> groupedMessages = {};
    
    for (final message in messages) {
      final DateTime date = DateTime.fromMillisecondsSinceEpoch(message.timeSent);
      final String dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      if (!groupedMessages.containsKey(dateKey)) {
        groupedMessages[dateKey] = [];
      }
      
      groupedMessages[dateKey]!.add(message);
    }
    
    return groupedMessages;
  }
  
  // Get all media messages
  List<ChatMessageModel> getMediaMessages() {
    final messages = state.value ?? [];
    
    // Filter for media messages
    return messages.where((message) => message.messageType.isMedia).toList();
  }
  
  // Get all text messages
  List<ChatMessageModel> getTextMessages() {
    final messages = state.value ?? [];
    
    // Filter for text messages
    return messages.where((message) => message.messageType == MessageEnum.text).toList();
  }
  
  // Get messages by type
  List<ChatMessageModel> getMessagesByType(MessageEnum type) {
    final messages = state.value ?? [];
    
    // Filter for messages of specified type
    return messages.where((message) => message.messageType == type).toList();
  }
  
  // Get replied messages (for threading context)
  Map<String, ChatMessageModel> getRepliedMessages() {
    final messages = state.value ?? [];
    final Map<String, ChatMessageModel> repliedMessages = {};
    
    // Create map of message ID to message for easy lookup
    for (final message in messages) {
      repliedMessages[message.messageId] = message;
    }
    
    return repliedMessages;
  }
  
  // Check if new messages should be marked as seen
  void checkAndMarkMessagesSeen() {
    final authState = ref.read(authenticationProvider);
    final currentUID = authState.value?.uid;
    
    if (currentUID == null) return;
    
    // Mark chat as seen
    ref.read(chatNotifierProvider.notifier).markChatAsSeen(
      senderUID: currentUID,
      receiverUID: contactUID,
    );
  }
}
// lib/features/chat/providers/chat_provider.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/chat/repositories/chat_repository.dart';
import 'package:textgb/models/user_model.dart';
import 'package:uuid/uuid.dart';

part 'chat_provider.g.dart';

// State class for chat management with added features
class ChatState {
  final bool isLoading;
  final List<ChatModel> chats;
  final List<MessageModel> messages;
  final String? currentChatId;
  final UserModel? currentChatContact;
  final MessageModel? replyingTo;
  final MessageModel? editingMessage; // For message editing
  final String? error;

  const ChatState({
    this.isLoading = false,
    this.chats = const [],
    this.messages = const [],
    this.currentChatId,
    this.currentChatContact,
    this.replyingTo,
    this.editingMessage,
    this.error,
  });

  ChatState copyWith({
    bool? isLoading,
    List<ChatModel>? chats,
    List<MessageModel>? messages,
    String? currentChatId,
    UserModel? currentChatContact,
    MessageModel? replyingTo,
    MessageModel? editingMessage,
    String? error,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      chats: chats ?? this.chats,
      messages: messages ?? this.messages,
      currentChatId: currentChatId ?? this.currentChatId,
      currentChatContact: currentChatContact ?? this.currentChatContact,
      replyingTo: replyingTo ?? this.replyingTo,
      editingMessage: editingMessage ?? this.editingMessage,
      error: error,
    );
  }
}

@riverpod
class ChatNotifier extends _$ChatNotifier {
  late ChatRepository _chatRepository;

  @override
  FutureOr<ChatState> build() {
    _chatRepository = ref.read(chatRepositoryProvider);
    
    // Initialize stream listeners
    _initChatListeners();
    
    return const ChatState();
  }

  void _initChatListeners() {
    // Listen to the chats stream
    ref.listen(chatStreamProvider, (previous, next) {
      if (next.hasValue) {
        state = AsyncValue.data(state.value!.copyWith(chats: next.value!));
      }
    });
    
    // Listen to the current user to update chat if needed
    ref.listen(currentUserProvider, (previous, next) {
      if (next != null && state.value?.currentChatId != null) {
        openChat(state.value!.currentChatId!, state.value!.currentChatContact!);
      }
    });
  }

  // Open a chat and load its messages
  Future<void> openChat(String chatId, UserModel contact) async {
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      currentChatId: chatId,
      currentChatContact: contact,
      messages: [],
    ));
    
    try {
      // Cancel previous listener and listen to the new chat's messages
      ref.read(messageStreamProvider(chatId));
      
      // Mark messages as delivered when opening a chat
      await _chatRepository.markChatAsDelivered(chatId);
      
      // Reset unread counter in Firestore for current user
      await _chatRepository.resetUnreadCounter(chatId);
      
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: 'Error opening chat: $e',
      ));
    }
  }

  // Send a text message
  Future<void> sendTextMessage(String message) async {
    if (message.trim().isEmpty) return;
    if (state.value?.currentChatId == null || state.value?.currentChatContact == null) return;
    
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    
    final chatId = state.value!.currentChatId!;
    final contact = state.value!.currentChatContact!;
    final replyingTo = state.value!.replyingTo;
    
    // Check if we're editing a message
    final editingMessage = state.value!.editingMessage;
    
    if (editingMessage != null) {
      try {
        await _chatRepository.editMessage(
          chatId: chatId,
          messageId: editingMessage.messageId,
          newMessage: message,
        );
        
        // Clear edit state after sending
        state = AsyncValue.data(state.value!.copyWith(
          editingMessage: null,
        ));
      } catch (e) {
        state = AsyncValue.data(state.value!.copyWith(
          error: 'Error editing message: $e',
        ));
      }
    } else {
      // Send new message
      try {
        await _chatRepository.sendMessage(
          chatId: chatId,
          receiverUID: contact.uid,
          message: message,
          messageType: MessageEnum.text,
          senderUser: currentUser,
          receiverUser: contact,
          repliedMessage: replyingTo?.message,
          repliedTo: replyingTo?.senderUID,
          repliedMessageType: replyingTo?.messageType,
        );
        
        // Clear reply state after sending
        if (replyingTo != null) {
          cancelReply();
        }
      } catch (e) {
        state = AsyncValue.data(state.value!.copyWith(
          error: 'Error sending message: $e',
        ));
      }
    }
  }

  // Send a media message (image, video, audio)
  Future<void> sendMediaMessage({
    required File file,
    required MessageEnum messageType,
    String? caption,
  }) async {
    if (state.value?.currentChatId == null || state.value?.currentChatContact == null) return;
    
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    
    final chatId = state.value!.currentChatId!;
    final contact = state.value!.currentChatContact!;
    final replyingTo = state.value!.replyingTo;
    
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
    ));
    
    try {
      await _chatRepository.sendMessage(
        chatId: chatId,
        receiverUID: contact.uid,
        message: caption ?? '',
        messageType: messageType,
        senderUser: currentUser,
        receiverUser: contact,
        repliedMessage: replyingTo?.message,
        repliedTo: replyingTo?.senderUID,
        repliedMessageType: replyingTo?.messageType,
        file: file,
      );
      
      // Clear reply state after sending
      if (replyingTo != null) {
        cancelReply();
      }
      
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: 'Error sending media: $e',
      ));
    }
  }

  // Set a message to reply to
  void setReplyingTo(MessageModel message) {
    state = AsyncValue.data(state.value!.copyWith(
      replyingTo: message,
    ));
  }

  // Cancel reply
  void cancelReply() {
    state = AsyncValue.data(state.value!.copyWith(
      replyingTo: null,
    ));
  }
  
  // Set a message to edit
  void setEditingMessage(MessageModel message) {
    state = AsyncValue.data(state.value!.copyWith(
      editingMessage: message,
    ));
  }
  
  // Cancel editing
  void cancelEditing() {
    state = AsyncValue.data(state.value!.copyWith(
      editingMessage: null,
    ));
  }

  // Mark a message as delivered
  Future<void> markMessageAsDelivered(String messageId) async {
    if (state.value?.currentChatId == null) return;
    
    try {
      await _chatRepository.markMessageAsDelivered(
        chatId: state.value!.currentChatId!,
        messageId: messageId,
      );
    } catch (e) {
      debugPrint('Error marking message as delivered: $e');
    }
  }

  // Delete a message (for current user only)
  Future<void> deleteMessage(String messageId) async {
    if (state.value?.currentChatId == null) return;
    
    try {
      await _chatRepository.deleteMessage(
        chatId: state.value!.currentChatId!,
        messageId: messageId,
      );
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: 'Error deleting message: $e',
      ));
    }
  }
  
  // Delete message for everyone
  Future<void> deleteMessageForEveryone(String messageId) async {
    if (state.value?.currentChatId == null) return;
    
    try {
      await _chatRepository.deleteMessageForEveryone(
        chatId: state.value!.currentChatId!,
        messageId: messageId,
      );
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: 'Error deleting message for everyone: $e',
      ));
    }
  }
  
  // Add reaction to message
  Future<void> addReaction(String messageId, String emoji) async {
    if (state.value?.currentChatId == null) return;
    
    try {
      await _chatRepository.addReaction(
        chatId: state.value!.currentChatId!,
        messageId: messageId,
        emoji: emoji,
      );
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: 'Error adding reaction: $e',
      ));
    }
  }

  // Open a group chat
  Future<void> openGroupChat(String groupId, List<UserModel> members) async {
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      currentChatId: groupId,
      messages: [],
    ));
    
    try {
      // Listen to the group chat's messages
      ref.read(messageStreamProvider(groupId));
      
      // Mark messages as delivered
      await _chatRepository.markChatAsDelivered(groupId);
      
      // Reset unread counter
      await _chatRepository.resetUnreadCounter(groupId);
      
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: 'Error opening group chat: $e',
      ));
    }
  }
  
  // Send a group message
  Future<void> sendGroupMessage({
    required String message,
    MessageEnum messageType = MessageEnum.text,
    File? file,
  }) async {
    if (message.trim().isEmpty && file == null) return;
    if (state.value?.currentChatId == null) return;
    
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    
    final chatId = state.value!.currentChatId!;
    final replyingTo = state.value!.replyingTo;
    
    // Check if we're editing a message
    final editingMessage = state.value!.editingMessage;
    
    if (editingMessage != null) {
      try {
        await _chatRepository.editMessage(
          chatId: chatId,
          messageId: editingMessage.messageId,
          newMessage: message,
        );
        
        // Clear edit state after sending
        state = AsyncValue.data(state.value!.copyWith(
          editingMessage: null,
        ));
      } catch (e) {
        state = AsyncValue.data(state.value!.copyWith(
          error: 'Error editing message: $e',
        ));
      }
    } else {
      try {
        await _chatRepository.sendGroupMessage(
          groupId: chatId,
          message: message,
          messageType: messageType,
          senderUser: currentUser,
          repliedMessage: replyingTo?.message,
          repliedTo: replyingTo?.senderUID,
          repliedMessageType: replyingTo?.messageType,
          file: file,
        );
        
        // Clear reply state after sending
        if (replyingTo != null) {
          cancelReply();
        }
      } catch (e) {
        state = AsyncValue.data(state.value!.copyWith(
          error: 'Error sending group message: $e',
        ));
      }
    }
  }
  
  // Send a group media message
  Future<void> sendGroupMediaMessage({
    required File file,
    required MessageEnum messageType,
    String? caption,
  }) async {
    if (state.value?.currentChatId == null) return;
    
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    
    final chatId = state.value!.currentChatId!;
    
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
    ));
    
    try {
      await sendGroupMessage(
        message: caption ?? '',
        messageType: messageType,
        file: file,
      );
      
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: 'Error sending group media: $e',
      ));
    }
  }
  
  // Remove reaction from message
  Future<void> removeReaction(String messageId) async {
    if (state.value?.currentChatId == null) return;
    
    try {
      await _chatRepository.removeReaction(
        chatId: state.value!.currentChatId!,
        messageId: messageId,
      );
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: 'Error removing reaction: $e',
      ));
    }
  }

  // Create a new chat with a contact
  Future<void> createChat(UserModel contact) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    
    final chatId = _chatRepository.generateChatId(currentUser.uid, contact.uid);
    
    // Open the chat screen
    openChat(chatId, contact);
  }

  // Get chat ID for a contact
  String getChatIdForContact(String contactId) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return const Uuid().v4();
    
    return _chatRepository.generateChatId(currentUser.uid, contactId);
  }
}


// Stream provider for all chats
@riverpod
Stream<List<ChatModel>> chatStream(ChatStreamRef ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getChats();
}

// Stream provider for messages in the current chat
@riverpod
Stream<List<MessageModel>> messageStream(MessageStreamRef ref, String chatId) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getMessages(chatId);
}

// Use the auto-generated provider for ChatNotifier
final chatProvider = chatNotifierProvider;
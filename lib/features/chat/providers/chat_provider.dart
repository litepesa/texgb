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

// State class for chat management
class ChatState {
  final bool isLoading;
  final List<ChatModel> chats;
  final List<MessageModel> messages;
  final String? currentChatId;
  final UserModel? currentChatContact;
  final MessageModel? replyingTo;
  final String? error;

  const ChatState({
    this.isLoading = false,
    this.chats = const [],
    this.messages = const [],
    this.currentChatId,
    this.currentChatContact,
    this.replyingTo,
    this.error,
  });

  ChatState copyWith({
    bool? isLoading,
    List<ChatModel>? chats,
    List<MessageModel>? messages,
    String? currentChatId,
    UserModel? currentChatContact,
    MessageModel? replyingTo,
    String? error,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      chats: chats ?? this.chats,
      messages: messages ?? this.messages,
      currentChatId: currentChatId ?? this.currentChatId,
      currentChatContact: currentChatContact ?? this.currentChatContact,
      replyingTo: replyingTo ?? this.replyingTo,
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
    
    // Listen to the current chat messages if a chat is selected
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
      
      // Clear unread count when opening a chat
      await _chatRepository.clearUnreadCount(chatId);
      
      // Update local chat model to show no unread messages
      final updatedChats = state.value!.chats.map((chat) {
        if (chat.id == chatId) {
          return ChatModel(
            id: chat.id,
            contactUID: chat.contactUID,
            contactName: chat.contactName,
            contactImage: chat.contactImage,
            lastMessage: chat.lastMessage,
            lastMessageType: chat.lastMessageType,
            lastMessageTime: chat.lastMessageTime,
            unreadCount: 0, // Reset to zero when opening chat
            isGroup: chat.isGroup,
            groupId: chat.groupId,
          );
        }
        return chat;
      }).toList();
      
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        chats: updatedChats,
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

  // Delete a message for current user only
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

  // Delete a message for everyone
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

  // Edit a message
  Future<void> editMessage(String messageId, String newText) async {
    if (state.value?.currentChatId == null) return;
    
    try {
      await _chatRepository.editMessage(
        chatId: state.value!.currentChatId!,
        messageId: messageId,
        newMessage: newText,
      );
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: 'Error editing message: $e',
      ));
    }
  }

  // Add reaction to message
  Future<void> addReaction(String messageId, String emoji) async {
    if (state.value?.currentChatId == null) return;
    
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    
    try {
      await _chatRepository.addReaction(
        chatId: state.value!.currentChatId!,
        messageId: messageId,
        userId: currentUser.uid,
        emoji: emoji,
      );
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: 'Error adding reaction: $e',
      ));
    }
  }

  // Remove reaction from message
  Future<void> removeReaction(String messageId) async {
    if (state.value?.currentChatId == null) return;
    
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    
    try {
      await _chatRepository.removeReaction(
        chatId: state.value!.currentChatId!,
        messageId: messageId,
        userId: currentUser.uid,
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

// Provider for total unread count across all chats
@riverpod
Stream<int> totalUnreadCount(TotalUnreadCountRef ref) {
  return ref.watch(chatStreamProvider).when(
    data: (chats) {
      final totalUnread = chats.fold<int>(
        0, 
        (sum, chat) => sum + chat.unreadCount
      );
      return Stream.value(totalUnread);
    },
    loading: () => Stream.value(0),
    error: (_, __) => Stream.value(0),
  );
}

// Use the auto-generated provider for ChatNotifier
final chatProvider = chatNotifierProvider;
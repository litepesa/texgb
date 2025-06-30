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

// Enhanced state class for chat management
class ChatState {
  final bool isLoading;
  final List<ChatModel> chats;
  final List<MessageModel> messages;
  final String? currentChatId;
  final UserModel? currentChatContact;
  final MessageModel? replyingTo;
  final MessageModel? editingMessage;
  final String? error;
  final Map<String, bool> loadingStates; // Track specific operation loading states

  const ChatState({
    this.isLoading = false,
    this.chats = const [],
    this.messages = const [],
    this.currentChatId,
    this.currentChatContact,
    this.replyingTo,
    this.editingMessage,
    this.error,
    this.loadingStates = const {},
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
    Map<String, bool>? loadingStates,
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
      loadingStates: loadingStates ?? this.loadingStates,
    );
  }

  // Helper methods for checking specific loading states
  bool isOperationLoading(String operation) {
    return loadingStates[operation] ?? false;
  }

  ChatState withLoadingState(String operation, bool loading) {
    final newLoadingStates = Map<String, bool>.from(loadingStates);
    if (loading) {
      newLoadingStates[operation] = true;
    } else {
      newLoadingStates.remove(operation);
    }
    return copyWith(loadingStates: newLoadingStates);
  }

  // Get filtered chats (only 1-to-1 chats, no groups)
  List<ChatModel> get directChats {
    return chats.where((chat) => !chat.isGroup).toList();
  }

  // Get total unread count for direct chats only
  int get totalUnreadCount {
    return directChats.fold(0, (sum, chat) => sum + chat.getDisplayUnreadCount());
  }

  // Check if any chat has unread messages
  bool get hasUnreadMessages {
    return directChats.any((chat) => chat.hasUnreadMessages());
  }
}

@riverpod
class ChatNotifier extends _$ChatNotifier {
  late IChatRepository _chatRepository;

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
      if (next.hasValue && state.hasValue) {
        state = AsyncValue.data(state.value!.copyWith(chats: next.value!));
      }
    });
    
    // Listen to current user changes
    ref.listen(currentUserProvider, (previous, next) {
      if (next != null && state.value?.currentChatId != null) {
        // Refresh current chat if user changes
        openChat(state.value!.currentChatId!, state.value!.currentChatContact!);
      }
    });
  }

  // Open a chat and load its messages
  Future<void> openChat(String chatId, UserModel contact) async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      currentChatId: chatId,
      currentChatContact: contact,
      messages: [],
      error: null,
    ));
    
    try {
      // Mark messages as delivered when opening chat
      await _chatRepository.markChatAsDelivered(chatId);
      
      // Reset unread counter
      await _chatRepository.resetUnreadCounter(chatId);
      
      state = AsyncValue.data(state.value!.copyWith(isLoading: false));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: 'Error opening chat: $e',
      ));
    }
  }

  // Send a text message with privacy validation
  Future<void> sendTextMessage(String message) async {
    if (message.trim().isEmpty || !state.hasValue) return;
    
    final currentState = state.value!;
    if (currentState.currentChatId == null || currentState.currentChatContact == null) {
      _setError('No chat selected');
      return;
    }
    
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      _setError('User not authenticated');
      return;
    }
    
    final chatId = currentState.currentChatId!;
    final contact = currentState.currentChatContact!;
    final replyingTo = currentState.replyingTo;
    final editingMessage = currentState.editingMessage;
    
    state = AsyncValue.data(currentState.withLoadingState('sendMessage', true));
    
    try {
      if (editingMessage != null) {
        // Edit existing message
        await _chatRepository.editMessage(
          chatId: chatId,
          messageId: editingMessage.messageId,
          newMessage: message,
        );
        
        // Clear edit state
        state = AsyncValue.data(state.value!.copyWith(
          editingMessage: null,
        ).withLoadingState('sendMessage', false));
      } else {
        // Send new message
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
        
        // Clear reply state
        state = AsyncValue.data(state.value!.copyWith(
          replyingTo: null,
        ).withLoadingState('sendMessage', false));
      }
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: e.toString(),
      ).withLoadingState('sendMessage', false));
    }
  }

  // Send a media message
  Future<void> sendMediaMessage({
    required File file,
    required MessageEnum messageType,
    String? caption,
  }) async {
    if (!state.hasValue) return;
    
    final currentState = state.value!;
    if (currentState.currentChatId == null || currentState.currentChatContact == null) {
      _setError('No chat selected');
      return;
    }
    
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      _setError('User not authenticated');
      return;
    }
    
    final chatId = currentState.currentChatId!;
    final contact = currentState.currentChatContact!;
    final replyingTo = currentState.replyingTo;
    
    state = AsyncValue.data(currentState.withLoadingState('sendMedia', true));
    
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
      
      // Clear reply state
      state = AsyncValue.data(state.value!.copyWith(
        replyingTo: null,
      ).withLoadingState('sendMedia', false));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: e.toString(),
      ).withLoadingState('sendMedia', false));
    }
  }

  // Set message to reply to
  void setReplyingTo(MessageModel message) {
    if (!state.hasValue) return;
    
    state = AsyncValue.data(state.value!.copyWith(
      replyingTo: message,
      editingMessage: null, // Clear editing if replying
    ));
  }

  // Cancel reply
  void cancelReply() {
    if (!state.hasValue) return;
    
    state = AsyncValue.data(state.value!.copyWith(replyingTo: null));
  }
  
  // Set message to edit
  void setEditingMessage(MessageModel message) {
    if (!state.hasValue) return;
    
    state = AsyncValue.data(state.value!.copyWith(
      editingMessage: message,
      replyingTo: null, // Clear reply if editing
    ));
  }
  
  // Cancel editing
  void cancelEditing() {
    if (!state.hasValue) return;
    
    state = AsyncValue.data(state.value!.copyWith(editingMessage: null));
  }

  // Delete a message (for current user only)
  Future<void> deleteMessage(String messageId) async {
    if (!state.hasValue || state.value!.currentChatId == null) return;
    
    state = AsyncValue.data(state.value!.withLoadingState('deleteMessage', true));
    
    try {
      await _chatRepository.deleteMessage(
        chatId: state.value!.currentChatId!,
        messageId: messageId,
      );
      
      state = AsyncValue.data(state.value!.withLoadingState('deleteMessage', false));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: 'Error deleting message: $e',
      ).withLoadingState('deleteMessage', false));
    }
  }
  
  // Add reaction to message
  Future<void> addReaction(String messageId, String emoji) async {
    if (!state.hasValue || state.value!.currentChatId == null) return;
    
    try {
      await _chatRepository.addReaction(
        chatId: state.value!.currentChatId!,
        messageId: messageId,
        emoji: emoji,
      );
    } catch (e) {
      _setError('Error adding reaction: $e');
    }
  }

  // Remove reaction from message
  Future<void> removeReaction(String messageId) async {
    if (!state.hasValue || state.value!.currentChatId == null) return;
    
    try {
      await _chatRepository.removeReaction(
        chatId: state.value!.currentChatId!,
        messageId: messageId,
      );
    } catch (e) {
      _setError('Error removing reaction: $e');
    }
  }

  // Toggle pin status of a chat
  Future<void> togglePinChat(String chatId) async {
    if (!state.hasValue) return;
    
    state = AsyncValue.data(state.value!.withLoadingState('togglePin', true));
    
    try {
      await _chatRepository.togglePinChat(chatId);
      state = AsyncValue.data(state.value!.withLoadingState('togglePin', false));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: 'Error toggling pin: $e',
      ).withLoadingState('togglePin', false));
    }
  }

  // Delete entire chat
  Future<void> deleteChat(String chatId) async {
    if (!state.hasValue) return;
    
    state = AsyncValue.data(state.value!.withLoadingState('deleteChat', true));
    
    try {
      await _chatRepository.deleteChat(chatId);
      
      // If we're deleting the current chat, clear it
      if (state.value!.currentChatId == chatId) {
        state = AsyncValue.data(state.value!.copyWith(
          currentChatId: null,
          currentChatContact: null,
          messages: [],
        ).withLoadingState('deleteChat', false));
      } else {
        state = AsyncValue.data(state.value!.withLoadingState('deleteChat', false));
      }
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: 'Error deleting chat: $e',
      ).withLoadingState('deleteChat', false));
    }
  }

  // Create a new chat with a contact
  Future<void> createChat(UserModel contact) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    
    final chatId = _chatRepository.generateChatId(currentUser.uid, contact.uid);
    await openChat(chatId, contact);
  }

  // Get chat ID for a contact
  String getChatIdForContact(String contactId) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return const Uuid().v4();
    
    return _chatRepository.generateChatId(currentUser.uid, contactId);
  }

  // Clear error state
  void clearError() {
    if (!state.hasValue) return;
    
    state = AsyncValue.data(state.value!.copyWith(error: null));
  }

  // Private helper method to set error
  void _setError(String error) {
    if (!state.hasValue) return;
    
    state = AsyncValue.data(state.value!.copyWith(error: error));
  }

  // Get total unread count across all chats
  Future<int> getTotalUnreadCount() async {
    if (_chatRepository is FirebaseChatRepository) {
      return await (_chatRepository as FirebaseChatRepository).getTotalUnreadCount();
    }
    
    // Fallback for other implementations
    if (state.hasValue) {
      return state.value!.totalUnreadCount;
    }
    
    return 0;
  }
}

// Stream provider for all chats
@riverpod
Stream<List<ChatModel>> chatStream(ChatStreamRef ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getChats();
}

// Stream provider for direct chats only (excluding groups)
@riverpod
Stream<List<ChatModel>> directChatStream(DirectChatStreamRef ref) {
  return ref.watch(chatStreamProvider.stream).map(
    (chats) => chats.where((chat) => !chat.isGroup).toList()
  );
}

// Stream provider for messages in the current chat
@riverpod
Stream<List<MessageModel>> messageStream(MessageStreamRef ref, String chatId) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getMessages(chatId);
}

// Provider for unread message count
@riverpod
Future<int> unreadMessageCount(UnreadMessageCountRef ref) async {
  final chatNotifier = ref.watch(chatNotifierProvider.notifier);
  return await chatNotifier.getTotalUnreadCount();
}

// Use the auto-generated provider for ChatNotifier
final chatProvider = chatNotifierProvider;
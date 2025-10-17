// lib/features/chat/providers/chat_provider.dart
// Main chat provider with state management for chats and messages
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/chat/repositories/chat_repository.dart';
import 'package:textgb/features/chat/repositories/chat_repository_impl.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';

part 'chat_provider.g.dart';

// ========================================
// CHAT STATE
// ========================================

class ChatState {
  final List<ChatModel> chats;
  final Map<String, List<MessageModel>> messages; // chatId -> messages
  final Map<String, int> unreadCounts; // chatId -> count
  final bool isLoading;
  final bool isConnected;
  final String? error;
  final DateTime? lastSync;
  final int totalUnreadCount;
  
  const ChatState({
    this.chats = const [],
    this.messages = const {},
    this.unreadCounts = const {},
    this.isLoading = false,
    this.isConnected = false,
    this.error,
    this.lastSync,
    this.totalUnreadCount = 0,
  });

  ChatState copyWith({
    List<ChatModel>? chats,
    Map<String, List<MessageModel>>? messages,
    Map<String, int>? unreadCounts,
    bool? isLoading,
    bool? isConnected,
    String? error,
    DateTime? lastSync,
    int? totalUnreadCount,
  }) {
    return ChatState(
      chats: chats ?? this.chats,
      messages: messages ?? this.messages,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      error: error,
      lastSync: lastSync ?? this.lastSync,
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
    );
  }
}

// ========================================
// REPOSITORY PROVIDER
// ========================================

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl();
});

// ========================================
// MAIN CHAT PROVIDER
// ========================================

@riverpod
class Chat extends _$Chat {
  late ChatRepository _repository;
  
  @override
  FutureOr<ChatState> build() async {
    _repository = ref.read(chatRepositoryProvider);
    
    // Initialize connection
    await _initialize();
    
    // Load chats
    final chats = await _repository.getChats();
    final totalUnread = await _repository.getTotalUnreadCount();
    
    return ChatState(
      chats: chats,
      isConnected: _repository.isConnected,
      totalUnreadCount: totalUnread,
      lastSync: DateTime.now(),
    );
  }

  // ===============================
  // INITIALIZATION
  // ===============================

  Future<void> _initialize() async {
    try {
      // Connect to WebSocket
      await _repository.connect();
      
      // Listen to connection state
      _repository.connectionStateStream.listen((isConnected) {
        if (state.hasValue) {
          state = AsyncValue.data(state.value!.copyWith(
            isConnected: isConnected,
          ));
        }
      });
      
      // Listen to chat updates
      _repository.watchAllChats().listen((chats) {
        if (state.hasValue) {
          state = AsyncValue.data(state.value!.copyWith(
            chats: chats,
            lastSync: DateTime.now(),
          ));
        }
      });
      
      debugPrint('✅ Chat provider initialized');
    } catch (e) {
      debugPrint('❌ Chat initialization failed: $e');
    }
  }

  // ===============================
  // CONNECTION MANAGEMENT
  // ===============================

  Future<void> reconnect() async {
    if (!state.hasValue) return;
    
    try {
      await _repository.reconnect();
      await refreshChats();
    } catch (e) {
      debugPrint('❌ Reconnection failed: $e');
    }
  }

  // ===============================
  // CHAT OPERATIONS
  // ===============================

  Future<void> loadChats() async {
    if (!state.hasValue) return;
    
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      final chats = await _repository.getChats();
      final totalUnread = await _repository.getTotalUnreadCount();
      
      state = AsyncValue.data(state.value!.copyWith(
        chats: chats,
        isLoading: false,
        totalUnreadCount: totalUnread,
        lastSync: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('❌ Error loading chats: $e');
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> refreshChats() async {
    if (!state.hasValue) return;
    
    try {
      await _repository.syncWithServer();
      await loadChats();
    } catch (e) {
      debugPrint('❌ Error refreshing chats: $e');
    }
  }

  Future<ChatModel?> getChatById(String chatId) async {
    try {
      return await _repository.getChatById(chatId);
    } catch (e) {
      debugPrint('❌ Error getting chat: $e');
      return null;
    }
  }

  Future<ChatModel?> getOrCreateOneOnOneChat({
    required String otherUserId,
    required String otherUserName,
    required String otherUserImage,
  }) async {
    if (!state.hasValue) return null;
    
    final authState = ref.read(authenticationProvider).value;
    if (authState?.currentUser == null) return null;
    
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      final chat = await _repository.getOrCreateOneOnOneChat(
        currentUserId: authState!.currentUser!.uid,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        otherUserImage: otherUserImage,
      );
      
      // Update chats list
      final updatedChats = List<ChatModel>.from(state.value!.chats);
      final existingIndex = updatedChats.indexWhere((c) => c.id == chat.id);
      
      if (existingIndex != -1) {
        updatedChats[existingIndex] = chat;
      } else {
        updatedChats.insert(0, chat);
      }
      
      state = AsyncValue.data(state.value!.copyWith(
        chats: updatedChats,
        isLoading: false,
      ));
      
      return chat;
    } catch (e) {
      debugPrint('❌ Error creating one-on-one chat: $e');
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
      return null;
    }
  }

  Future<ChatModel?> createGroupChat({
    required String groupName,
    required String? groupImage,
    required String? groupDescription,
    required List<String> participantIds,
    required List<String> participantNames,
    required List<String> participantImages,
  }) async {
    if (!state.hasValue) return null;
    
    final authState = ref.read(authenticationProvider).value;
    if (authState?.currentUser == null) return null;
    
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      final chat = await _repository.createGroupChat(
        groupName: groupName,
        groupImage: groupImage,
        groupDescription: groupDescription,
        creatorId: authState!.currentUser!.uid,
        participantIds: participantIds,
        participantNames: participantNames,
        participantImages: participantImages,
      );
      
      // Add to chats list
      final updatedChats = List<ChatModel>.from(state.value!.chats);
      updatedChats.insert(0, chat);
      
      state = AsyncValue.data(state.value!.copyWith(
        chats: updatedChats,
        isLoading: false,
      ));
      
      return chat;
    } catch (e) {
      debugPrint('❌ Error creating group chat: $e');
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
      return null;
    }
  }

  Future<void> deleteChat(String chatId) async {
    if (!state.hasValue) return;
    
    try {
      await _repository.deleteChat(chatId);
      
      // Remove from state
      final updatedChats = state.value!.chats
          .where((chat) => chat.id != chatId)
          .toList();
      
      state = AsyncValue.data(state.value!.copyWith(
        chats: updatedChats,
      ));
    } catch (e) {
      debugPrint('❌ Error deleting chat: $e');
    }
  }

  Future<void> updateChatSettings({
    required String chatId,
    bool? isMuted,
    bool? isPinned,
    bool? isArchived,
    bool? isBlocked,
  }) async {
    if (!state.hasValue) return;
    
    try {
      await _repository.updateChatSettings(
        chatId: chatId,
        isMuted: isMuted,
        isPinned: isPinned,
        isArchived: isArchived,
        isBlocked: isBlocked,
      );
      
      // Update local state
      final updatedChats = state.value!.chats.map((chat) {
        if (chat.id == chatId) {
          return chat.copyWith(
            isMuted: isMuted ?? chat.isMuted,
            isPinned: isPinned ?? chat.isPinned,
            isArchived: isArchived ?? chat.isArchived,
            isBlocked: isBlocked ?? chat.isBlocked,
          );
        }
        return chat;
      }).toList();
      
      state = AsyncValue.data(state.value!.copyWith(
        chats: updatedChats,
      ));
    } catch (e) {
      debugPrint('❌ Error updating chat settings: $e');
    }
  }

  // ===============================
  // MESSAGE OPERATIONS
  // ===============================

  Future<void> loadMessages(String chatId, {int limit = 50}) async {
    if (!state.hasValue) return;
    
    try {
      final messages = await _repository.getMessages(
        chatId: chatId,
        limit: limit,
      );
      
      // Update messages map
      final updatedMessages = Map<String, List<MessageModel>>.from(state.value!.messages);
      updatedMessages[chatId] = messages;
      
      state = AsyncValue.data(state.value!.copyWith(
        messages: updatedMessages,
      ));
    } catch (e) {
      debugPrint('❌ Error loading messages: $e');
    }
  }

  Future<void> sendTextMessage({
    required String chatId,
    required String content,
    String? repliedToMessageId,
  }) async {
    if (!state.hasValue) return;
    
    try {
      final message = await _repository.sendTextMessage(
        chatId: chatId,
        content: content,
        repliedToMessageId: repliedToMessageId,
      );
      
      // Update messages
      _addMessageToState(chatId, message);
      
      // Update chat's last message
      _updateChatLastMessage(chatId, message);
    } catch (e) {
      debugPrint('❌ Error sending text message: $e');
    }
  }

  Future<void> sendImageMessage({
    required String chatId,
    required File imageFile,
    String? caption,
    String? repliedToMessageId,
  }) async {
    if (!state.hasValue) return;
    
    try {
      final message = await _repository.sendImageMessage(
        chatId: chatId,
        imageFile: imageFile,
        caption: caption,
        repliedToMessageId: repliedToMessageId,
      );
      
      _addMessageToState(chatId, message);
      _updateChatLastMessage(chatId, message);
    } catch (e) {
      debugPrint('❌ Error sending image message: $e');
    }
  }

  Future<void> sendVideoMessage({
    required String chatId,
    required File videoFile,
    String? caption,
    String? repliedToMessageId,
  }) async {
    if (!state.hasValue) return;
    
    try {
      final message = await _repository.sendVideoMessage(
        chatId: chatId,
        videoFile: videoFile,
        caption: caption,
        repliedToMessageId: repliedToMessageId,
      );
      
      _addMessageToState(chatId, message);
      _updateChatLastMessage(chatId, message);
    } catch (e) {
      debugPrint('❌ Error sending video message: $e');
    }
  }

  Future<void> sendAudioMessage({
    required String chatId,
    required File audioFile,
    required int duration,
    String? repliedToMessageId,
  }) async {
    if (!state.hasValue) return;
    
    try {
      final message = await _repository.sendAudioMessage(
        chatId: chatId,
        audioFile: audioFile,
        duration: duration,
        repliedToMessageId: repliedToMessageId,
      );
      
      _addMessageToState(chatId, message);
      _updateChatLastMessage(chatId, message);
    } catch (e) {
      debugPrint('❌ Error sending audio message: $e');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    if (!state.hasValue) return;
    
    try {
      await _repository.deleteMessage(messageId);
      
      // Remove from state
      final updatedMessages = Map<String, List<MessageModel>>.from(state.value!.messages);
      
      for (final chatId in updatedMessages.keys) {
        updatedMessages[chatId] = updatedMessages[chatId]!
            .where((msg) => msg.id != messageId)
            .toList();
      }
      
      state = AsyncValue.data(state.value!.copyWith(
        messages: updatedMessages,
      ));
    } catch (e) {
      debugPrint('❌ Error deleting message: $e');
    }
  }

  Future<void> addReaction({
    required String messageId,
    required String emoji,
  }) async {
    try {
      await _repository.addReaction(
        messageId: messageId,
        emoji: emoji,
      );
    } catch (e) {
      debugPrint('❌ Error adding reaction: $e');
    }
  }

  Future<void> removeReaction({
    required String messageId,
    required String emoji,
  }) async {
    try {
      await _repository.removeReaction(
        messageId: messageId,
        emoji: emoji,
      );
    } catch (e) {
      debugPrint('❌ Error removing reaction: $e');
    }
  }

  // ===============================
  // UNREAD COUNT OPERATIONS
  // ===============================

  Future<void> markChatAsRead(String chatId) async {
    if (!state.hasValue) return;
    
    try {
      await _repository.markChatAsRead(chatId);
      
      // Update unread counts
      final updatedCounts = Map<String, int>.from(state.value!.unreadCounts);
      updatedCounts[chatId] = 0;
      
      final totalUnread = await _repository.getTotalUnreadCount();
      
      state = AsyncValue.data(state.value!.copyWith(
        unreadCounts: updatedCounts,
        totalUnreadCount: totalUnread,
      ));
    } catch (e) {
      debugPrint('❌ Error marking chat as read: $e');
    }
  }

  // ===============================
  // HELPER METHODS
  // ===============================

  void _addMessageToState(String chatId, MessageModel message) {
    if (!state.hasValue) return;
    
    final updatedMessages = Map<String, List<MessageModel>>.from(state.value!.messages);
    final chatMessages = List<MessageModel>.from(updatedMessages[chatId] ?? []);
    
    // Add message at the beginning (newest first)
    chatMessages.insert(0, message);
    updatedMessages[chatId] = chatMessages;
    
    state = AsyncValue.data(state.value!.copyWith(
      messages: updatedMessages,
    ));
  }

  void _updateChatLastMessage(String chatId, MessageModel message) {
    if (!state.hasValue) return;
    
    final updatedChats = state.value!.chats.map((chat) {
      if (chat.id == chatId) {
        return chat.copyWith(
          lastMessage: message.content,
          lastMessageId: message.id,
          lastMessageSenderId: message.senderId,
          lastMessageSenderName: message.senderName,
          lastMessageType: message.type.value,
          lastMessageTime: message.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
        );
      }
      return chat;
    }).toList();
    
    state = AsyncValue.data(state.value!.copyWith(
      chats: updatedChats,
    ));
  }

  // ===============================
  // CLEANUP
  // ===============================

  Future<void> dispose() async {
    try {
      await _repository.disconnect();
    } catch (e) {
      debugPrint('❌ Error disposing chat provider: $e');
    }
  }
}

// ========================================
// CONVENIENCE PROVIDERS
// ========================================

// Get all chats
@riverpod
List<ChatModel> allChats(AllChatsRef ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.value?.chats ?? [];
}

// Get specific chat
@riverpod
Future<ChatModel?> chatById(ChatByIdRef ref, String chatId) async {
  final chatNotifier = ref.read(chatProvider.notifier);
  return await chatNotifier.getChatById(chatId);
}

// Get messages for a chat
@riverpod
List<MessageModel> chatMessages(ChatMessagesRef ref, String chatId) {
  final chatState = ref.watch(chatProvider);
  return chatState.value?.messages[chatId] ?? [];
}

// Get unread count for a chat
@riverpod
int chatUnreadCount(ChatUnreadCountRef ref, String chatId) {
  final chatState = ref.watch(chatProvider);
  return chatState.value?.unreadCounts[chatId] ?? 0;
}

// Get total unread count
@riverpod
int totalUnreadCount(TotalUnreadCountRef ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.value?.totalUnreadCount ?? 0;
}

// Check if connected
@riverpod
bool isChatConnected(IsChatConnectedRef ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.value?.isConnected ?? false;
}

// Check if loading
@riverpod
bool isChatLoading(IsChatLoadingRef ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.value?.isLoading ?? false;
}

// Get filtered chats (search)
@riverpod
List<ChatModel> filteredChats(FilteredChatsRef ref, String query) {
  final chats = ref.watch(allChatsProvider);
  
  if (query.isEmpty) return chats;
  
  final lowerQuery = query.toLowerCase();
  return chats.where((chat) {
    final authState = ref.read(authenticationProvider).value;
    final currentUserId = authState?.currentUser?.uid ?? '';
    
    final chatTitle = chat.getChatTitle(currentUserId).toLowerCase();
    final lastMessage = chat.lastMessage?.toLowerCase() ?? '';
    
    return chatTitle.contains(lowerQuery) || lastMessage.contains(lowerQuery);
  }).toList();
}

// Get pinned chats
@riverpod
List<ChatModel> pinnedChats(PinnedChatsRef ref) {
  final chats = ref.watch(allChatsProvider);
  return chats.where((chat) => chat.isPinned).toList();
}

// Get archived chats
@riverpod
List<ChatModel> archivedChats(ArchivedChatsRef ref) {
  final chats = ref.watch(allChatsProvider);
  return chats.where((chat) => chat.isArchived).toList();
}

// Get active (non-archived) chats
@riverpod
List<ChatModel> activeChats(ActiveChatsRef ref) {
  final chats = ref.watch(allChatsProvider);
  return chats.where((chat) => !chat.isArchived).toList();
}
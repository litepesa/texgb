// lib/features/chat/providers/chat_provider.dart (Simplified)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/chat_list_item_model.dart';
import 'package:textgb/features/chat/repositories/chat_repository.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/channels/models/channel_video_model.dart';
import 'package:textgb/models/user_model.dart';

part 'chat_provider.g.dart';

// Simplified Video Context Model
class SimpleVideoContext {
  final String videoId;
  final String videoUrl;
  final String thumbnailUrl;

  const SimpleVideoContext({
    required this.videoId,
    required this.videoUrl,
    required this.thumbnailUrl,
  });

  factory SimpleVideoContext.fromChannelVideo(ChannelVideoModel video) {
    return SimpleVideoContext(
      videoId: video.id,
      videoUrl: video.videoUrl,
      thumbnailUrl: video.isMultipleImages && video.imageUrls.isNotEmpty 
          ? video.imageUrls.first 
          : video.thumbnailUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  factory SimpleVideoContext.fromMap(Map<String, dynamic> map) {
    return SimpleVideoContext(
      videoId: map['videoId'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
    );
  }
}

// Chat List State (unchanged)
class ChatListState {
  final bool isLoading;
  final List<ChatListItemModel> chats;
  final String? error;
  final bool hasMore;
  final String searchQuery;

  const ChatListState({
    this.isLoading = false,
    this.chats = const [],
    this.error,
    this.hasMore = true,
    this.searchQuery = '',
  });

  ChatListState copyWith({
    bool? isLoading,
    List<ChatListItemModel>? chats,
    String? error,
    bool? hasMore,
    String? searchQuery,
  }) {
    return ChatListState(
      isLoading: isLoading ?? this.isLoading,
      chats: chats ?? this.chats,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<ChatListItemModel> get filteredChats {
    if (searchQuery.isEmpty) return chats;
    
    return chats.where((chatItem) {
      final query = searchQuery.toLowerCase();
      return chatItem.contactName.toLowerCase().contains(query) ||
             chatItem.chat.lastMessage.toLowerCase().contains(query);
    }).toList();
  }

  List<ChatListItemModel> get pinnedChats {
    final currentUser = chats.isNotEmpty ? chats.first.chat.participants.firstWhere(
      (id) => id != chats.first.chat.participants.first, 
      orElse: () => chats.first.chat.participants.first
    ) : '';
    return filteredChats.where((chat) => 
        chat.chat.isPinnedForUser(currentUser)).toList();
  }

  List<ChatListItemModel> get regularChats {
    final currentUser = chats.isNotEmpty ? chats.first.chat.participants.firstWhere(
      (id) => id != chats.first.chat.participants.first, 
      orElse: () => chats.first.chat.participants.first
    ) : '';
    return filteredChats.where((chat) => 
        !chat.chat.isPinnedForUser(currentUser)).toList();
  }
}

@riverpod
class ChatList extends _$ChatList {
  ChatRepository get _repository => ref.read(chatRepositoryProvider);
  
  @override
  FutureOr<ChatListState> build() async {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const ChatListState(error: 'User not authenticated');
    }

    // Start listening to chats stream
    _subscribeToChats(currentUser.uid);
    
    return const ChatListState(isLoading: true);
  }

  void _subscribeToChats(String userId) {
    // Listen to chats stream and update state
    _repository.getChatsStream(userId).listen(
      (chats) async {
        try {
          final chatItems = await _buildChatListItems(chats, userId);
          
          state = AsyncValue.data(ChatListState(
            chats: chatItems,
            isLoading: false,
          ));
        } catch (e) {
          state = AsyncValue.data(ChatListState(
            error: e.toString(),
            isLoading: false,
          ));
        }
      },
      onError: (error) {
        state = AsyncValue.data(ChatListState(
          error: error.toString(),
          isLoading: false,
        ));
      },
    );
  }

  Future<List<ChatListItemModel>> _buildChatListItems(
      List<ChatModel> chats, String currentUserId) async {
    final authNotifier = ref.read(authenticationProvider.notifier);
    final chatItems = <ChatListItemModel>[];

    for (final chat in chats) {
      try {
        final otherUserId = chat.getOtherParticipant(currentUserId);
        final contact = await authNotifier.getUserDataById(otherUserId);
        
        if (contact != null) {
          chatItems.add(ChatListItemModel(
            chat: chat,
            contactName: contact.name,
            contactImage: contact.image,
            contactPhone: contact.phoneNumber,
            isOnline: false,
            lastSeen: null,
          ));
        }
      } catch (e) {
        debugPrint('Error building chat item: $e');
      }
    }

    // Sort by last message time
    chatItems.sort((a, b) => b.chat.lastMessageTime.compareTo(a.chat.lastMessageTime));

    return chatItems;
  }

  // Search functionality
  void setSearchQuery(String query) {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(searchQuery: query));
    }
  }

  void clearSearch() {
    setSearchQuery('');
  }

  // Chat actions
  Future<void> togglePinChat(String chatId, String userId) async {
    try {
      await _repository.toggleChatPin(chatId, userId);
    } catch (e) {
      debugPrint('Error toggling pin: $e');
      rethrow;
    }
  }

  Future<void> toggleArchiveChat(String chatId, String userId) async {
    try {
      await _repository.toggleChatArchive(chatId, userId);
    } catch (e) {
      debugPrint('Error toggling archive: $e');
      rethrow;
    }
  }

  Future<void> toggleMuteChat(String chatId, String userId) async {
    try {
      await _repository.toggleChatMute(chatId, userId);
    } catch (e) {
      debugPrint('Error toggling mute: $e');
      rethrow;
    }
  }

  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      await _repository.markChatAsRead(chatId, userId);
    } catch (e) {
      debugPrint('Error marking chat as read: $e');
      rethrow;
    }
  }

  // Delete chat functionality
  Future<void> deleteChat(String chatId, String userId, {bool deleteForEveryone = false}) async {
    try {
      await _repository.deleteChat(chatId, userId, deleteForEveryone: deleteForEveryone);
      
      // Remove from local state immediately for better UX
      final currentState = state.valueOrNull;
      if (currentState != null) {
        final updatedChats = currentState.chats
            .where((chatItem) => chatItem.chat.chatId != chatId)
            .toList();
        
        state = AsyncValue.data(currentState.copyWith(chats: updatedChats));
      }
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      rethrow;
    }
  }

  Future<void> clearChatHistory(String chatId, String userId) async {
    try {
      await _repository.clearChatHistory(chatId, userId);
    } catch (e) {
      debugPrint('Error clearing chat history: $e');
      rethrow;
    }
  }

  // SIMPLIFIED: Create new chat with optional video context
  Future<String?> createChat(String otherUserId, {SimpleVideoContext? videoContext}) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return null;

    try {
      final chatId = await _repository.createOrGetChat(currentUser.uid, otherUserId);
      
      // If video context is provided, send a simple video message
      if (videoContext != null) {
        await _sendSimpleVideoMessage(chatId, currentUser.uid, videoContext);
      }
      
      return chatId;
    } catch (e) {
      debugPrint('Error creating chat: $e');
      return null;
    }
  }

  // SIMPLIFIED: Send simple video message with just thumbnail and URL
  Future<void> _sendSimpleVideoMessage(String chatId, String senderId, SimpleVideoContext videoContext) async {
    try {
      await _repository.sendVideoMessage(
        chatId: chatId,
        senderId: senderId,
        videoUrl: videoContext.videoUrl,
        thumbnailUrl: videoContext.thumbnailUrl,
        videoId: videoContext.videoId,
      );
    } catch (e) {
      debugPrint('Error sending video message: $e');
      // Don't rethrow - chat creation should still succeed
    }
  }

  // Check if chat has messages before creating/showing it
  Future<bool> chatHasMessages(String chatId) async {
    try {
      return await _repository.chatHasMessages(chatId);
    } catch (e) {
      debugPrint('Error checking chat messages: $e');
      return false;
    }
  }

  // Get chat by ID
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      return await _repository.getChatById(chatId);
    } catch (e) {
      debugPrint('Error getting chat by ID: $e');
      return null;
    }
  }

  // Refresh chat list manually
  void refreshChatList() {
    ref.invalidateSelf();
  }
}
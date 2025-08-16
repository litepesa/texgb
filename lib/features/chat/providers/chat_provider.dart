// lib/features/chat/providers/chat_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/chat_list_item_model.dart';
import 'package:textgb/features/chat/repositories/chat_repository.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/models/user_model.dart';

part 'chat_provider.g.dart';

// Chat List State
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
            isOnline: false, // TODO: Implement online status
            lastSeen: null, // TODO: Implement last seen
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

  // Create new chat
  Future<String?> createChat(String otherUserId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return null;

    try {
      final chatId = await _repository.createOrGetChat(currentUser.uid, otherUserId);
      
      // Don't refresh immediately - let the stream handle updates
      // Only refresh if we need to ensure the chat appears
      
      return chatId;
    } catch (e) {
      debugPrint('Error creating chat: $e');
      return null;
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
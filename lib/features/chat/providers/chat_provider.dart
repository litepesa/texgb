// lib/features/chat/providers/chat_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/chat_list_item_model.dart';
import 'package:textgb/features/chat/providers/message_provider.dart';
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
    return filteredChats.where((chat) => 
        chat.chat.isPinnedForUser(chat.chat.participants.first)).toList();
  }

  List<ChatListItemModel> get regularChats {
    return filteredChats.where((chat) => 
        !chat.chat.isPinnedForUser(chat.chat.participants.first)).toList();
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
    
    return const ChatListState();
  }

  void _subscribeToChats(String userId) {
    // Listen to chats stream and update state
    _repository.getChatsStream(userId).listen(
      (chats) async {
        try {
          final chatItems = await _buildChatListItems(chats, userId);
          
          if (!state.hasValue) {
            state = AsyncValue.data(ChatListState(
              chats: chatItems,
              isLoading: false,
            ));
          }
        } catch (e) {
          if (!state.hasValue) {
            state = AsyncValue.data(ChatListState(
              error: e.toString(),
              isLoading: false,
            ));
          }
        }
      },
      onError: (error) {
        if (!state.hasValue) {
          state = AsyncValue.data(ChatListState(
            error: error.toString(),
            isLoading: false,
          ));
        }
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

    return chatItems;
  }

  // Search functionality
  void setSearchQuery(String query) {
    if (state.hasValue) {
      state = AsyncValue.data(state.value!.copyWith(searchQuery: query));
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
      // Error will be handled by stream updates
      debugPrint('Error toggling pin: $e');
    }
  }

  Future<void> toggleArchiveChat(String chatId, String userId) async {
    try {
      await _repository.toggleChatArchive(chatId, userId);
    } catch (e) {
      debugPrint('Error toggling archive: $e');
    }
  }

  Future<void> toggleMuteChat(String chatId, String userId) async {
    try {
      await _repository.toggleChatMute(chatId, userId);
    } catch (e) {
      debugPrint('Error toggling mute: $e');
    }
  }

  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      await _repository.markChatAsRead(chatId, userId);
    } catch (e) {
      debugPrint('Error marking chat as read: $e');
    }
  }

  // Create new chat
  Future<String?> createChat(String otherUserId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return null;

    try {
      return await _repository.createOrGetChat(currentUser.uid, otherUserId);
    } catch (e) {
      debugPrint('Error creating chat: $e');
      return null;
    }
  }
}


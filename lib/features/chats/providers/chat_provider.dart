import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/chats/models/chat_model.dart';
import 'package:textgb/features/chats/providers/chat_streams_provider.dart';
import 'package:textgb/features/chats/repository/chat_repository.dart';

part 'chat_provider.g.dart';

/// Main chat provider for managing chat list and operations.
/// Responsible for tracking chat conversations, their states, and user preferences.
@riverpod
class ChatNotifier extends _$ChatNotifier {
  late final ChatRepository _chatRepository;
  
  @override
  FutureOr<List<ChatModel>> build() {
    _chatRepository = ChatRepository();
    
    // Watch the chat stream provider and update this provider's state
    ref.listen(chatStreamProvider, (previous, chats) {
      if (chats is AsyncData) {
        state = AsyncData(chats.value);
      } else if (chats is AsyncError) {
        state = AsyncError(chats.error, chats.stackTrace);
      }
    });
    
    // Return empty list initially
    return [];
  }
  
  // Mark chat as seen
  Future<void> markChatAsSeen({
    required String senderUID,
    required String receiverUID,
  }) async {
    try {
      await _chatRepository.markChatAsSeen(
        senderUID: senderUID,
        receiverUID: receiverUID,
      );
    } catch (e) {
      debugPrint('Error marking chat as seen: $e');
    }
  }
  
  // Pin/unpin a chat
  Future<void> togglePinChat({
    required String uid,
    required String chatId,
    required bool isPinned,
  }) async {
    try {
      await _chatRepository.togglePinChat(
        uid: uid,
        chatId: chatId,
        isPinned: isPinned,
      );
    } catch (e) {
      debugPrint('Error toggling pin chat: $e');
    }
  }
  
  // Mute/unmute chat notifications
  Future<void> toggleMuteChat({
    required String uid,
    required String chatId,
    required bool isMuted,
  }) async {
    try {
      await _chatRepository.toggleMuteChat(
        uid: uid,
        chatId: chatId,
        isMuted: isMuted,
      );
    } catch (e) {
      debugPrint('Error toggling mute chat: $e');
    }
  }
  
  // Clear chat history
  Future<void> clearChatHistory({
    required String uid,
    required String chatId,
  }) async {
    try {
      await _chatRepository.clearChatHistory(
        uid: uid,
        chatId: chatId,
      );
    } catch (e) {
      debugPrint('Error clearing chat history: $e');
    }
  }
  
  // Delete chat
  Future<void> deleteChat({
    required String uid,
    required String chatId,
  }) async {
    try {
      await _chatRepository.deleteChat(
        uid: uid,
        chatId: chatId,
      );
    } catch (e) {
      debugPrint('Error deleting chat: $e');
    }
  }
  
  // Update chat settings
  Future<void> updateChatSettings({
    required String uid,
    required String chatId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      await _chatRepository.updateChatSettings(
        uid: uid,
        chatId: chatId,
        settings: settings,
      );
    } catch (e) {
      debugPrint('Error updating chat settings: $e');
    }
  }
  
  // Set disappearing messages expiry time
  Future<void> setDisappearingMessages({
    required String uid,
    required String chatId,
    required int? expiryTime, // Null disables disappearing messages
  }) async {
    try {
      await _chatRepository.setDisappearingMessages(
        uid: uid,
        chatId: chatId,
        expiryTime: expiryTime,
      );
    } catch (e) {
      debugPrint('Error setting disappearing messages: $e');
    }
  }
  
  // Get unread chats count
  int getUnreadChatsCount() {
    final chats = state.value ?? [];
    return chats.where((chat) => chat.unreadCount > 0).length;
  }
  
  // Get total unread messages count
  int getTotalUnreadCount() {
    final chats = state.value ?? [];
    return chats.fold(0, (sum, chat) => sum + chat.unreadCount);
  }
  
  // Get pinned chats
  List<ChatModel> getPinnedChats() {
    final chats = state.value ?? [];
    return chats.where((chat) => chat.isPinned).toList();
  }
  
  // Get regular (unpinned) chats
  List<ChatModel> getRegularChats() {
    final chats = state.value ?? [];
    return chats.where((chat) => !chat.isPinned).toList();
  }
  
  // Check if chat exists with a specific contact
  bool chatExistsWithContact(String contactUID) {
    final chats = state.value ?? [];
    return chats.any((chat) => chat.contactUID == contactUID);
  }
}
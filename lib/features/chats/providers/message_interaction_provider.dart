import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/chats/models/chat_message_model.dart';
import 'package:textgb/features/chats/repository/message_interaction_repository.dart';

part 'message_interaction_provider.g.dart';

/// Provider for handling user interactions with messages.
/// Responsible for reactions, deleting, editing, and other message operations.
@riverpod
class MessageInteractionNotifier extends _$MessageInteractionNotifier {
  late final MessageInteractionRepository _messageInteractionRepository;
  
  @override
  FutureOr<void> build() {
    _messageInteractionRepository = MessageInteractionRepository();
  }
  
  // Mark message as seen
  Future<void> markMessageAsSeen({
    required String messageId,
  }) async {
    try {
      // Get current user ID
      final authState = ref.read(authenticationProvider);
      final uid = authState.value?.uid;
      
      if (uid == null) {
        throw Exception('User not authenticated');
      }
      
      await _messageInteractionRepository.markMessageAsSeen(
        messageId: messageId,
        uid: uid,
      );
    } catch (e) {
      debugPrint('Error marking message as seen: $e');
    }
  }
  
  // Delete message for me
  Future<void> deleteMessageForMe({
    required String messageId,
  }) async {
    try {
      // Get current user ID
      final authState = ref.read(authenticationProvider);
      final uid = authState.value?.uid;
      
      if (uid == null) {
        throw Exception('User not authenticated');
      }
      
      await _messageInteractionRepository.deleteMessageForMe(
        messageId: messageId,
        uid: uid,
      );
    } catch (e) {
      debugPrint('Error deleting message for me: $e');
      rethrow;
    }
  }
  
  // Delete message for everyone
  Future<void> deleteMessageForEveryone({
    required String messageId,
  }) async {
    try {
      // Get current user ID
      final authState = ref.read(authenticationProvider);
      final uid = authState.value?.uid;
      
      if (uid == null) {
        throw Exception('User not authenticated');
      }
      
      await _messageInteractionRepository.deleteMessageForEveryone(
        messageId: messageId,
        uid: uid,
      );
    } catch (e) {
      debugPrint('Error deleting message for everyone: $e');
      rethrow;
    }
  }
  
  // Add reaction to message
  Future<void> addReaction({
    required String messageId,
    required String reaction,
  }) async {
    try {
      // Get current user ID
      final authState = ref.read(authenticationProvider);
      final uid = authState.value?.uid;
      
      if (uid == null) {
        throw Exception('User not authenticated');
      }
      
      await _messageInteractionRepository.addReaction(
        messageId: messageId,
        uid: uid,
        reaction: reaction,
      );
    } catch (e) {
      debugPrint('Error adding reaction: $e');
      rethrow;
    }
  }
  
  // Remove reaction from message
  Future<void> removeReaction({
    required String messageId,
  }) async {
    try {
      // Get current user ID
      final authState = ref.read(authenticationProvider);
      final uid = authState.value?.uid;
      
      if (uid == null) {
        throw Exception('User not authenticated');
      }
      
      await _messageInteractionRepository.removeReaction(
        messageId: messageId,
        uid: uid,
      );
    } catch (e) {
      debugPrint('Error removing reaction: $e');
      rethrow;
    }
  }
  
  // Edit a message
  Future<void> editMessage({
    required String messageId,
    required String newMessage,
  }) async {
    try {
      // Get current user ID
      final authState = ref.read(authenticationProvider);
      final uid = authState.value?.uid;
      
      if (uid == null) {
        throw Exception('User not authenticated');
      }
      
      await _messageInteractionRepository.editMessage(
        messageId: messageId,
        uid: uid,
        newMessage: newMessage,
      );
    } catch (e) {
      debugPrint('Error editing message: $e');
      rethrow;
    }
  }
  
  // Star/unstar a message
  Future<void> toggleStarMessage({
    required String messageId,
    required bool isStarred,
  }) async {
    try {
      // Get current user ID
      final authState = ref.read(authenticationProvider);
      final uid = authState.value?.uid;
      
      if (uid == null) {
        throw Exception('User not authenticated');
      }
      
      await _messageInteractionRepository.toggleStarMessage(
        messageId: messageId,
        uid: uid,
        isStarred: isStarred,
      );
    } catch (e) {
      debugPrint('Error toggling star message: $e');
      rethrow;
    }
  }
  
  // Pin/unpin a message
  Future<void> togglePinMessage({
    required String messageId,
    required String chatId,
    required bool isPinned,
  }) async {
    try {
      await _messageInteractionRepository.togglePinMessage(
        messageId: messageId,
        chatId: chatId,
        isPinned: isPinned,
      );
    } catch (e) {
      debugPrint('Error toggling pin message: $e');
      rethrow;
    }
  }
}

/// Provider for accessing all starred messages for current user
@riverpod
Stream<List<ChatMessageModel>> starredMessages(StarredMessagesRef ref) {
  final authState = ref.watch(authenticationProvider);
  final uid = authState.value?.uid;
  
  if (uid == null) {
    return Stream.value([]);
  }
  
  final messageInteractionRepository = MessageInteractionRepository();
  return messageInteractionRepository.getStarredMessages(uid);
}

/// Provider for accessing pinned messages in a specific chat
@riverpod
Stream<List<ChatMessageModel>> pinnedMessages(PinnedMessagesRef ref, String chatId) {
  final messageInteractionRepository = MessageInteractionRepository();
  return messageInteractionRepository.getPinnedMessages(chatId);
}
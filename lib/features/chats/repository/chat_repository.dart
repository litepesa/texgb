import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chats/models/chat_message_model.dart';
import 'package:textgb/features/chats/models/chat_model.dart';
import 'package:uuid/uuid.dart';

/// Main repository for chat-related operations.
/// Focused on managing chat conversations and basic chat features.
class ChatRepository {
  final FirebaseFirestore _firestore;
  
  ChatRepository({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  // Get all chats for a user
  Stream<List<ChatModel>> getAllChatsForUser(String uid) {
    return _firestore
        .collection(Constants.chats)
        .where('participants', arrayContains: uid)
        .orderBy('timeSent', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ChatModel.fromMap(doc.data());
          }).toList();
        });
  }

  // Get chat stream between two users
  Stream<List<ChatMessageModel>> getChatStream({
    required String senderUID,
    required String receiverUID,
  }) {
    // Get both sender-receiver and receiver-sender chat IDs
    final senderChatId = '$senderUID-$receiverUID';
    final receiverChatId = '$receiverUID-$senderUID';
    
    // Query for messages where chat ID is either sender-receiver or receiver-sender
    return _firestore
        .collection(Constants.messages)
        .where('chatId', whereIn: [senderChatId, receiverChatId])
        .orderBy(Constants.timeSent, descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ChatMessageModel.fromMap(doc.data());
          }).toList();
        });
  }

  // Update chat data in Firestore (used after sending messages)
  Future<void> updateChatData({
    required String senderUID,
    required String receiverUID,
    required String lastMessage,
    required MessageEnum messageType,
    required int timestamp,
  }) async {
    try {
      // Create chat document ID (a consistent ID for the chat between these users)
      final chatId = _generateChatId(senderUID, receiverUID);
      final participants = [senderUID, receiverUID];
      
      // Create chat model
      final chatModel = {
        'chatId': chatId,
        'participants': participants,
        Constants.contactUID: receiverUID, // From the sender's perspective
        Constants.lastMessage: lastMessage,
        Constants.senderUID: senderUID,
        Constants.timeSent: timestamp,
        Constants.isSeen: false,
        Constants.messageType: messageType.name,
        'unreadCount': FieldValue.increment(1), // Increment unread count
      };
      
      // Update or create chat document for sender
      await _firestore
          .collection(Constants.chats)
          .doc('$senderUID-$chatId')
          .set(chatModel, SetOptions(merge: true));
      
      // Update or create chat document for receiver (with adjusted perspective)
      await _firestore
          .collection(Constants.chats)
          .doc('$receiverUID-$chatId')
          .set({
            ...chatModel,
            Constants.contactUID: senderUID, // From the receiver's perspective
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating chat data: $e');
      rethrow;
    }
  }

  // Mark messages as seen
  Future<void> markChatAsSeen({
    required String senderUID,
    required String receiverUID,
  }) async {
    try {
      final chatId = _generateChatId(senderUID, receiverUID);
      
      // Update chat document to mark as seen and reset unread count
      await _firestore
          .collection(Constants.chats)
          .doc('$senderUID-$chatId')
          .update({
            Constants.isSeen: true,
            'unreadCount': 0,
          });
    } catch (e) {
      debugPrint('Error marking chat as seen: $e');
      rethrow;
    }
  }

  // Pin/unpin a chat
  Future<void> togglePinChat({
    required String uid,
    required String chatId, 
    required bool isPinned,
  }) async {
    try {
      await _firestore
          .collection(Constants.chats)
          .doc('$uid-$chatId')
          .update({
            'isPinned': isPinned,
          });
    } catch (e) {
      debugPrint('Error toggling pin chat: $e');
      rethrow;
    }
  }

  // Mute/unmute chat notifications
  Future<void> toggleMuteChat({
    required String uid,
    required String chatId,
    required bool isMuted,
  }) async {
    try {
      await _firestore
          .collection(Constants.chats)
          .doc('$uid-$chatId')
          .update({
            'isMuted': isMuted,
          });
    } catch (e) {
      debugPrint('Error toggling mute chat: $e');
      rethrow;
    }
  }

  // Clear chat history
  Future<void> clearChatHistory({
    required String uid,
    required String chatId,
  }) async {
    try {
      // Instead of deleting all messages, mark all as deleted for this user
      final messages = await _firestore
          .collection(Constants.messages)
          .where('chatId', isEqualTo: chatId)
          .get();
      
      // Create a batch for efficient updates
      final batch = _firestore.batch();
      
      for (final doc in messages.docs) {
        batch.update(
          doc.reference, 
          {Constants.deletedBy: FieldValue.arrayUnion([uid])}
        );
      }
      
      await batch.commit();
      
      // Reset the last message in the chat
      await _firestore
          .collection(Constants.chats)
          .doc('$uid-$chatId')
          .update({
            Constants.lastMessage: 'Chat cleared',
            Constants.messageType: MessageEnum.text.name,
            'unreadCount': 0,
          });
    } catch (e) {
      debugPrint('Error clearing chat history: $e');
      rethrow;
    }
  }

  // Delete chat
  Future<void> deleteChat({
    required String uid,
    required String chatId,
  }) async {
    try {
      // Delete the chat document
      await _firestore
          .collection(Constants.chats)
          .doc('$uid-$chatId')
          .delete();
      
      // Mark all messages as deleted for this user (same as clear chat)
      await clearChatHistory(uid: uid, chatId: chatId);
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      rethrow;
    }
  }

  // Update chat settings
  Future<void> updateChatSettings({
    required String uid,
    required String chatId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      await _firestore
          .collection(Constants.chats)
          .doc('$uid-$chatId')
          .update({
            'chatSettings': settings,
          });
    } catch (e) {
      debugPrint('Error updating chat settings: $e');
      rethrow;
    }
  }

  // Set disappearing messages expiry time
  Future<void> setDisappearingMessages({
    required String uid,
    required String chatId,
    required int? expiryTime, // Null disables disappearing messages
  }) async {
    try {
      await _firestore
          .collection(Constants.chats)
          .doc('$uid-$chatId')
          .update({
            'expiryTime': expiryTime,
          });
    } catch (e) {
      debugPrint('Error setting disappearing messages: $e');
      rethrow;
    }
  }
  
  // Helper method to generate a consistent chat ID between two users
  String _generateChatId(String uid1, String uid2) {
    // Sort UIDs to ensure consistent chat ID regardless of sender/receiver order
    final sortedUIDs = [uid1, uid2]..sort();
    return '${sortedUIDs[0]}-${sortedUIDs[1]}';
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chats/models/chat_message_model.dart';

/// Repository focused on message interactions.
/// Handles reactions, deleting messages, marking as seen, etc.
class MessageInteractionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  
  MessageInteractionRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _storage = storage ?? FirebaseStorage.instance;
  
  // Mark message as seen
  Future<void> markMessageAsSeen({
    required String messageId,
    required String uid,
  }) async {
    try {
      await _firestore
          .collection(Constants.messages)
          .doc(messageId)
          .update({
            Constants.isSeen: true,
            Constants.isSeenBy: FieldValue.arrayUnion([uid]),
          });
    } catch (e) {
      debugPrint('Error marking message as seen: $e');
      rethrow;
    }
  }
  
  // Delete message for me (adds user to deletedBy array)
  Future<void> deleteMessageForMe({
    required String messageId,
    required String uid,
  }) async {
    try {
      await _firestore
          .collection(Constants.messages)
          .doc(messageId)
          .update({
            Constants.deletedBy: FieldValue.arrayUnion([uid]),
          });
    } catch (e) {
      debugPrint('Error deleting message for me: $e');
      rethrow;
    }
  }
  
  // Delete message for everyone (completely removes the message)
  Future<void> deleteMessageForEveryone({
    required String messageId,
    required String uid,
  }) async {
    try {
      // First check if user is the sender
      final messageDoc = await _firestore
          .collection(Constants.messages)
          .doc(messageId)
          .get();
      
      if (!messageDoc.exists) {
        return;
      }
      
      final message = ChatMessageModel.fromMap(messageDoc.data()!);
      
      // Only sender can delete for everyone
      if (message.senderUID != uid) {
        throw Exception('Only the sender can delete a message for everyone');
      }
      
      // If message has media, delete it from storage
      if (message.mediaUrl != null && message.mediaUrl!.isNotEmpty) {
        try {
          final ref = _storage.refFromURL(message.mediaUrl!);
          await ref.delete();
        } catch (e) {
          debugPrint('Error deleting media from storage: $e');
          // Continue with message deletion even if media deletion fails
        }
      }
      
      // Delete message from Firestore
      await _firestore
          .collection(Constants.messages)
          .doc(messageId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting message for everyone: $e');
      rethrow;
    }
  }
  
  // Add reaction to message
  Future<void> addReaction({
    required String messageId,
    required String uid,
    required String reaction,
  }) async {
    try {
      await _firestore
          .collection(Constants.messages)
          .doc(messageId)
          .update({
            '${Constants.reactions}.$uid': reaction,
          });
    } catch (e) {
      debugPrint('Error adding reaction: $e');
      rethrow;
    }
  }
  
  // Remove reaction from message
  Future<void> removeReaction({
    required String messageId,
    required String uid,
  }) async {
    try {
      await _firestore
          .collection(Constants.messages)
          .doc(messageId)
          .update({
            '${Constants.reactions}.$uid': FieldValue.delete(),
          });
    } catch (e) {
      debugPrint('Error removing reaction: $e');
      rethrow;
    }
  }
  
  // Edit a message (only text messages can be edited)
  Future<void> editMessage({
    required String messageId,
    required String uid,
    required String newMessage,
  }) async {
    try {
      // Check if user is the sender
      final messageDoc = await _firestore
          .collection(Constants.messages)
          .doc(messageId)
          .get();
      
      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }
      
      final message = ChatMessageModel.fromMap(messageDoc.data()!);
      
      // Only sender can edit the message
      if (message.senderUID != uid) {
        throw Exception('Only the sender can edit a message');
      }
      
      // Only text messages can be edited
      if (message.messageType != MessageEnum.text) {
        throw Exception('Only text messages can be edited');
      }
      
      // Update the message
      await _firestore
          .collection(Constants.messages)
          .doc(messageId)
          .update({
            Constants.message: newMessage,
            'edited': true, // Flag to indicate this message has been edited
            'editedAt': DateTime.now().millisecondsSinceEpoch,
          });
    } catch (e) {
      debugPrint('Error editing message: $e');
      rethrow;
    }
  }
  
  // Star/unstar a message for personal bookmarks
  Future<void> toggleStarMessage({
    required String messageId,
    required String uid,
    required bool isStarred,
  }) async {
    try {
      await _firestore
          .collection(Constants.messages)
          .doc(messageId)
          .update({
            'starredBy': isStarred
                ? FieldValue.arrayUnion([uid])
                : FieldValue.arrayRemove([uid]),
          });
    } catch (e) {
      debugPrint('Error toggling star message: $e');
      rethrow;
    }
  }
  
  // Get all starred messages for a user
  Stream<List<ChatMessageModel>> getStarredMessages(String uid) {
    return _firestore
        .collection(Constants.messages)
        .where('starredBy', arrayContains: uid)
        .orderBy(Constants.timeSent, descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ChatMessageModel.fromMap(doc.data());
          }).toList();
        });
  }
  
  // Pin/unpin a message in a chat
  Future<void> togglePinMessage({
    required String messageId,
    required String chatId,
    required bool isPinned,
  }) async {
    try {
      await _firestore
          .collection(Constants.messages)
          .doc(messageId)
          .update({
            'pinnedInChat': isPinned ? chatId : null,
            'pinnedAt': isPinned ? DateTime.now().millisecondsSinceEpoch : null,
          });
    } catch (e) {
      debugPrint('Error toggling pin message: $e');
      rethrow;
    }
  }
  
  // Get pinned messages in a chat
  Stream<List<ChatMessageModel>> getPinnedMessages(String chatId) {
    return _firestore
        .collection(Constants.messages)
        .where('pinnedInChat', isEqualTo: chatId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ChatMessageModel.fromMap(doc.data());
          }).toList();
        });
  }
}
// lib/features/chat/repositories/chat_repository.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:uuid/uuid.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ChatRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  // Get all chats for the current user
  Stream<List<ChatModel>> getChats() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    // Use Firestore directly since this is a stream
    return _firestore
        .collection(Constants.chats)
        .where('participants', arrayContains: currentUser.uid)
        .orderBy(Constants.timeSent, descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            
            // Determine if this is a group chat
            final isGroup = data['isGroup'] ?? false;
            String? contactUID;
            String contactName = '';
            String contactImage = '';
            String? groupId;

            if (isGroup) {
              groupId = data[Constants.groupId] as String?;
              contactName = data[Constants.groupName] as String? ?? 'Group';
              contactImage = data[Constants.groupImage] as String? ?? '';
            } else {
              // For one-on-one chats, find the other participant
              final participants = List<String>.from(data['participants'] ?? []);
              contactUID = participants.firstWhere(
                (uid) => uid != currentUser.uid,
                orElse: () => '',
              );
              contactName = data[Constants.contactName] as String? ?? '';
              contactImage = data[Constants.contactImage] as String? ?? '';
            }

            return ChatModel.fromMap(data..['id'] = doc.id);
          }).toList();
        });
  }

  // Get messages for a specific chat
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection(Constants.chats)
        .doc(chatId)
        .collection(Constants.messages)
        .orderBy(Constants.timeSent, descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MessageModel.fromMap(doc.data());
          }).toList();
        });
  }

  // Send a message
  Future<void> sendMessage({
    required String chatId,
    required String receiverUID,
    required String message,
    required MessageEnum messageType,
    required UserModel senderUser,
    required UserModel receiverUser,
    String? repliedMessage,
    String? repliedTo,
    MessageEnum? repliedMessageType,
    File? file,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Generate a message ID
      final messageId = const Uuid().v4();
      final timeSent = DateTime.now().millisecondsSinceEpoch.toString();

      // Create message model
      var messageModel = MessageModel(
        messageId: messageId,
        senderUID: currentUser.uid,
        senderName: senderUser.name,
        senderImage: senderUser.image,
        message: message,
        messageType: messageType,
        timeSent: timeSent,
        messageStatus: MessageStatus.sending,
        repliedMessage: repliedMessage,
        repliedTo: repliedTo,
        repliedMessageType: repliedMessageType,
        deletedBy: [],
      );

      // Upload file if present
      if (file != null && messageType.isMedia) {
        final fileRef = '${Constants.chatFiles}/$chatId/$messageId';
        String fileUrl = await storeFileToStorage(file: file, reference: fileRef);
        
        // Update the message with the file URL
        messageModel = messageModel.copyWith(message: fileUrl);
        debugPrint("Repository: Uploaded file: $fileUrl");
      }

      // Check if the chat exists
      final chatDoc = await _firestore.collection(Constants.chats).doc(chatId).get();
      
      if (!chatDoc.exists) {
        // Create a new chat
        await _firestore.collection(Constants.chats).doc(chatId).set({
          'id': chatId,
          'participants': [currentUser.uid, receiverUID],
          Constants.contactUID: receiverUID,
          Constants.contactName: receiverUser.name,
          Constants.contactImage: receiverUser.image,
          Constants.lastMessage: message,
          Constants.messageType: messageType.name,
          Constants.timeSent: timeSent,
          'lastMessageSender': currentUser.uid,
          'unreadCount': 0,
          'unreadCountByUser': {}, // Initialize empty map for user-specific counts
          'isGroup': false,
        });
        debugPrint("Repository: Created new chat in Firestore");
      } else {
        // Update existing chat
        // Calculate unread count for the receiver
        Map<String, dynamic> unreadCountByUser = 
            Map<String, dynamic>.from(chatDoc.data()?['unreadCountByUser'] ?? {});
        
        // Increment unread count for receiver (only if they're not the sender)
        int receiverUnreadCount = unreadCountByUser[receiverUID] ?? 0;
        unreadCountByUser[receiverUID] = receiverUnreadCount + 1;
        
        await _firestore.collection(Constants.chats).doc(chatId).update({
          Constants.lastMessage: message,
          Constants.messageType: messageType.name,
          Constants.timeSent: timeSent,
          'lastMessageSender': currentUser.uid,
          'unreadCountByUser': unreadCountByUser,
          'unreadCount': receiverUnreadCount + 1, // For backward compatibility
        });
        debugPrint("Repository: Updated existing chat in Firestore");
      }

      // Update message status to 'sent'
      messageModel = messageModel.copyWith(messageStatus: MessageStatus.sent);
      
      // Add the message to Firestore
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .set(messageModel.toMap());
      
      debugPrint("Repository: Message saved to Firestore successfully");
      
    } catch (e) {
      debugPrint("Repository: Error in sendMessage: $e");
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  // Update unread counter for a specific chat
  Future<void> updateUnreadCounter(String chatId, String messageId, bool isIncrease) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get the chat document
      final chatDoc = await _firestore.collection(Constants.chats).doc(chatId).get();
      
      if (chatDoc.exists) {
        // Get current unread counts or initialize empty map
        Map<String, dynamic> unreadCountByUser = 
            Map<String, dynamic>.from(chatDoc.data()?['unreadCountByUser'] ?? {});
        
        if (isIncrease) {
          // Increment unread count for current user
          int currentCount = unreadCountByUser[currentUser.uid] ?? 0;
          unreadCountByUser[currentUser.uid] = currentCount + 1;
        } else {
          // Reset unread count for current user
          unreadCountByUser[currentUser.uid] = 0;
        }
        
        // Calculate total unread count (for backwards compatibility)
        int totalUnreadCount = unreadCountByUser[currentUser.uid] ?? 0;
        
        // Update the chat document with new unread counts
        await _firestore.collection(Constants.chats).doc(chatId).update({
          'unreadCountByUser': unreadCountByUser,
          'unreadCount': totalUnreadCount,
        });
      }
    } catch (e) {
      debugPrint('Error updating unread counter: $e');
    }
  }

  // Mark messages as delivered/read
  Future<void> updateMessageStatuses(String chatId, List<String> messageIds, MessageStatus status) async {
    if (messageIds.isEmpty) return;
    
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      // Use a batch write for efficiency
      WriteBatch batch = _firestore.batch();
      
      // Add each message update to the batch
      for (final messageId in messageIds) {
        final messageRef = _firestore
            .collection(Constants.chats)
            .doc(chatId)
            .collection(Constants.messages)
            .doc(messageId);
            
        batch.update(messageRef, {
          'messageStatus': status.name,
        });
      }
      
      // Commit the batch
      await batch.commit();
      
      debugPrint("Repository: Successfully updated status to ${status.name} for ${messageIds.length} messages");
    } catch (e) {
      debugPrint("Repository: Error updating message statuses: $e");
    }
  }

  // Mark a single message as delivered
  Future<void> markMessageAsDelivered({
    required String chatId,
    required String messageId,
  }) async {
    try {
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .update({
            'messageStatus': MessageStatus.delivered.name,
          });
    } catch (e) {
      debugPrint('Error marking message as delivered: $e');
    }
  }

  // Delete a message (for self)
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get the message document
      final messageDoc = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .get();

      if (messageDoc.exists) {
        // Get the current deletedBy list
        final deletedBy = List<String>.from(messageDoc.data()?[Constants.deletedBy] ?? []);
        
        // Add the current user if not already in the list
        if (!deletedBy.contains(currentUser.uid)) {
          deletedBy.add(currentUser.uid);
          
          // Update the message document
          await _firestore
              .collection(Constants.chats)
              .doc(chatId)
              .collection(Constants.messages)
              .doc(messageId)
              .update({
                Constants.deletedBy: deletedBy,
              });
        }
      }
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }
  
  // Delete message for everyone
  Future<void> deleteMessageForEveryone({
    required String chatId,
    required String messageId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      // Update the message document in Firestore
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .update({
            'isDeletedForEveryone': true,
          });
    } catch (e) {
      debugPrint('Error deleting message for everyone: $e');
      rethrow;
    }
  }
  
  // Edit a message
  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String newMessage,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      // Get the original message first
      final messageDoc = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .get();
      
      if (messageDoc.exists) {
        final originalMessage = messageDoc.data()?[Constants.message] as String?;
        
        // Update the message document in Firestore
        await _firestore
            .collection(Constants.chats)
            .doc(chatId)
            .collection(Constants.messages)
            .doc(messageId)
            .update({
              Constants.message: newMessage,
              'isEdited': true,
              'originalMessage': originalMessage,
              'editedAt': DateTime.now().millisecondsSinceEpoch.toString(),
            });
            
        // If this is the last message in the chat, update the chat's last message
        final chatDoc = await _firestore.collection(Constants.chats).doc(chatId).get();
        if (chatDoc.exists) {
          final lastMessage = chatDoc.data()?[Constants.lastMessage] as String?;
          final lastMessageType = chatDoc.data()?[Constants.messageType] as String?;
          
          if (lastMessage == originalMessage && lastMessageType == 'text') {
            await _firestore.collection(Constants.chats).doc(chatId).update({
              Constants.lastMessage: newMessage,
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error editing message: $e');
      rethrow;
    }
  }
  
  // Add reaction to message
  Future<void> addReaction({
    required String chatId,
    required String messageId,
    required String emoji,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      // Get the message document
      final messageDoc = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .get();
      
      if (messageDoc.exists) {
        // Get current reactions or create an empty map
        Map<String, dynamic> reactions = 
            Map<String, dynamic>.from(messageDoc.data()?['reactions'] ?? {});
        
        // Add/update user's reaction
        reactions[currentUser.uid] = {
          'emoji': emoji,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        };
        
        // Update the message document
        await _firestore
            .collection(Constants.chats)
            .doc(chatId)
            .collection(Constants.messages)
            .doc(messageId)
            .update({
              'reactions': reactions,
            });
      }
    } catch (e) {
      debugPrint('Error adding reaction: $e');
      rethrow;
    }
  }
  
  // Remove reaction from message
  Future<void> removeReaction({
    required String chatId,
    required String messageId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      // Get the message document
      final messageDoc = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .get();
      
      if (messageDoc.exists) {
        // Get current reactions
        Map<String, dynamic>? reactions = 
            messageDoc.data()?['reactions'] as Map<String, dynamic>?;
        
        if (reactions != null) {
          // Remove user's reaction
          reactions.remove(currentUser.uid);
          
          // Update the message document
          await _firestore
              .collection(Constants.chats)
              .doc(chatId)
              .collection(Constants.messages)
              .doc(messageId)
              .update({
                'reactions': reactions,
              });
        }
      }
    } catch (e) {
      debugPrint('Error removing reaction: $e');
      rethrow;
    }
  }

  // Generate a chat ID for one-on-one chats
  String generateChatId(String userId, String contactId) {
    // Sort the IDs to ensure consistency
    final sortedIds = [userId, contactId]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }
  
  // Check for unread messages across all chats
  Future<int> getTotalUnreadCount() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return 0;
      
      // Get all chats
      final querySnapshot = await _firestore
          .collection(Constants.chats)
          .where('participants', arrayContains: currentUser.uid)
          .get();
          
      int totalUnread = 0;
      
      for (final doc in querySnapshot.docs) {
        // Check for unread count in unreadCountByUser first
        Map<String, dynamic>? unreadCountByUser = doc.data()['unreadCountByUser'] as Map<String, dynamic>?;
        if (unreadCountByUser != null && unreadCountByUser.containsKey(currentUser.uid)) {
          totalUnread += (unreadCountByUser[currentUser.uid] as int? ?? 0);
        } else {
          // Fall back to the old unreadCount field
          totalUnread += (doc.data()['unreadCount'] as int? ?? 0);
        }
      }
      
      return totalUnread;
    } catch (e) {
      debugPrint('Error getting total unread count: $e');
      return 0;
    }
  }
  
  // Mark all messages in a chat as delivered
  Future<void> markChatAsDelivered(String chatId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      // Get all undelivered messages in this chat
      final querySnapshot = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .where('messageStatus', isEqualTo: MessageStatus.sent.name)
          .where('senderUID', isNotEqualTo: currentUser.uid) // Only mark others' messages
          .get();
          
      if (querySnapshot.docs.isEmpty) return;
      
      // Get message IDs
      final messageIds = querySnapshot.docs.map((doc) => doc.id).toList();
      
      // Update status in batch
      await updateMessageStatuses(chatId, messageIds, MessageStatus.delivered);
    } catch (e) {
      debugPrint('Error marking chat as delivered: $e');
    }
  }

  // Reset unread counter for a chat when opened
  Future<void> resetUnreadCounter(String chatId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get the chat document
      final chatDoc = await _firestore.collection(Constants.chats).doc(chatId).get();
      
      if (chatDoc.exists) {
        // Get current unread counts or initialize empty map
        Map<String, dynamic> unreadCountByUser = 
            Map<String, dynamic>.from(chatDoc.data()?['unreadCountByUser'] ?? {});
        
        // Reset unread count for current user
        unreadCountByUser[currentUser.uid] = 0;
        
        // Update the chat document
        await _firestore.collection(Constants.chats).doc(chatId).update({
          'unreadCountByUser': unreadCountByUser,
          // Also update traditional unreadCount if this user is the receiver
          if (chatDoc.data()?['lastMessageSender'] != currentUser.uid)
            'unreadCount': 0,
        });
      }
    } catch (e) {
      debugPrint('Error resetting unread counter: $e');
    }
  }
}

// Provider for the chat repository
final chatRepositoryProvider = Provider((ref) {
  return ChatRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});
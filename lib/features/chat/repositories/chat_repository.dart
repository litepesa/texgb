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

    return _firestore
        .collection(Constants.chats)
        .where('participants', arrayContains: currentUser.uid)
        .orderBy(Constants.timeSent, descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final List<ChatModel> chats = [];
          
          for (final doc in snapshot.docs) {
            final data = doc.data();
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
              final participants = List<String>.from(data['participants'] ?? []);
              contactUID = participants.firstWhere(
                (uid) => uid != currentUser.uid,
                orElse: () => '',
              );
              contactName = data[Constants.contactName] as String? ?? '';
              contactImage = data[Constants.contactImage] as String? ?? '';
            }
            
            // Use the unreadCount from the chat document
            // This will be updated when messages are sent and when the chat is opened
            final unreadCount = data['unreadCount'] as int? ?? 0;
            
            chats.add(ChatModel(
              id: doc.id,
              contactUID: contactUID ?? '',
              contactName: contactName,
              contactImage: contactImage,
              lastMessage: data[Constants.lastMessage] as String? ?? '',
              lastMessageType: (data[Constants.messageType] as String? ?? 'text').toMessageEnum(),
              lastMessageTime: data[Constants.timeSent] as String? ?? '',
              unreadCount: unreadCount,
              isGroup: isGroup,
              groupId: groupId,
            ));
          }
          
          return chats;
        });
  }

  // Get messages for a specific chat
  Stream<List<MessageModel>> getMessages(String chatId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection(Constants.chats)
        .doc(chatId)
        .collection(Constants.messages)
        .orderBy(Constants.timeSent, descending: true)
        .snapshots()
        .map((snapshot) {
          List<MessageModel> messages = snapshot.docs.map((doc) {
            final messageData = doc.data();
            
            // Filter messages based on deleted status
            if (messageData[Constants.deletedBy]?.contains(currentUser.uid) ?? false) {
              // If message is deleted for this user, return a "deleted" placeholder
              messageData[Constants.message] = 'This message was deleted';
            }
            
            return MessageModel.fromMap(messageData);
          }).toList();
          
          // Mark messages as delivered
          for (var message in messages) {
            if (message.senderUID != currentUser.uid && 
                !message.deliveredTo.contains(currentUser.uid)) {
              markMessageAsDelivered(chatId: chatId, messageId: message.messageId);
            }
          }
          
          return messages;
        });
  }

  // Get unread message count for a chat
  Future<int> getUnreadMessageCount(String chatId, String userId) async {
    try {
      // Only query messages SENT TO the user (not from them)
      final querySnapshot = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .where(Constants.senderUID, isNotEqualTo: userId) // Only count messages not sent by user
          .orderBy(Constants.senderUID) // Required for inequality query
          .orderBy(Constants.timeSent, descending: true) // Get most recent first
          .get();
      
      // Count messages not sent by this user and delivered but not viewed by opening the chat
      int count = 0;
      for (var doc in querySnapshot.docs) {
        final messageData = doc.data();
        final isDeleted = (messageData[Constants.deletedBy] as List<dynamic>?)?.contains(userId) ?? false;
        
        // Don't count messages that were deleted by this user
        if (!isDeleted) {
          count++;
        }
      }
      
      return count;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  // Get total unread count across all chats
  Future<int> getTotalUnreadCount() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return 0;
      
      final querySnapshot = await _firestore
          .collection(Constants.chats)
          .where('participants', arrayContains: currentUser.uid)
          .get();
      
      int totalUnread = 0;
      for (var doc in querySnapshot.docs) {
        final unreadCount = doc.data()['unreadCount'] as int? ?? 0;
        totalUnread += unreadCount;
      }
      
      return totalUnread;
    } catch (e) {
      debugPrint('Error getting total unread count: $e');
      return 0;
    }
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
        isDelivered: false,
        repliedMessage: repliedMessage,
        repliedTo: repliedTo,
        repliedMessageType: repliedMessageType,
        deliveredTo: [currentUser.uid], // Mark as delivered to sender
        deletedBy: [],
        reactions: {},
        deletedForEveryone: false,
      );

      // Upload file if present
      String fileUrl = '';
      if (file != null && messageType.isMedia) {
        final fileRef = '${Constants.chatFiles}/$chatId/$messageId';
        fileUrl = await storeFileToStorage(file: file, reference: fileRef);
        
        // Update the message with the file URL
        messageModel = messageModel.copyWith(message: fileUrl);
      }

      // Check if the chat exists or needs to be created
      final chatDoc = await _firestore.collection(Constants.chats).doc(chatId).get();

      if (!chatDoc.exists) {
        // Create a new chat
        await _createNewChat(
          chatId: chatId,
          currentUser: senderUser,
          receiverUser: receiverUser,
          lastMessage: message,
          messageType: messageType,
          timeSent: timeSent,
          messageId: messageId,
        );
      } else {
        // Update existing chat with last message info
        await _updateChatLastMessage(
          chatId: chatId,
          lastMessage: message,
          messageType: messageType,
          timeSent: timeSent,
          messageId: messageId,
        );
      }

      // Add the message to the messages collection
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .set(messageModel.toMap());
          
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  // Mark a message as delivered
  Future<void> markMessageAsDelivered({
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
        // Get the current deliveredTo list
        final deliveredTo = List<String>.from(messageDoc.data()?[Constants.deliveredTo] ?? []);
        
        // Add the current user if not already in the list
        if (!deliveredTo.contains(currentUser.uid)) {
          deliveredTo.add(currentUser.uid);
          
          // Update the message document
          await _firestore
              .collection(Constants.chats)
              .doc(chatId)
              .collection(Constants.messages)
              .doc(messageId)
              .update({
                Constants.deliveredTo: deliveredTo,
                Constants.isDelivered: true,
              });
        }
      }
    } catch (e) {
      debugPrint('Error marking message as delivered: $e');
    }
  }

  // Clear unread count when opening a chat
  Future<void> clearUnreadCount(String chatId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      // Update the chat document to reset unread count
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .update({
            'unreadCount': 0,
          });
          
      // Update any system notification badges (if needed)
      // This might be platform specific and would require native code
    } catch (e) {
      debugPrint('Error clearing unread count: $e');
    }
  }

  // Create a new chat
  Future<void> _createNewChat({
    required String chatId,
    required UserModel currentUser,
    required UserModel receiverUser,
    required String lastMessage,
    required MessageEnum messageType,
    required String timeSent,
    required String messageId,
  }) async {
    try {
      // Create the chat document
      await _firestore.collection(Constants.chats).doc(chatId).set({
        'id': chatId,
        'participants': [currentUser.uid, receiverUser.uid],
        Constants.contactUID: receiverUser.uid,
        Constants.contactName: receiverUser.name,
        Constants.contactImage: receiverUser.image,
        Constants.lastMessage: lastMessage,
        Constants.messageType: messageType.name,
        Constants.timeSent: timeSent,
        Constants.lastMessageId: messageId,
        'unreadCount': 1, // We'll keep this for tracking undelivered messages
        'isGroup': false,
      });
    } catch (e) {
      debugPrint('Error creating new chat: $e');
      rethrow;
    }
  }

  // Update chat's last message
  Future<void> _updateChatLastMessage({
    required String chatId,
    required String lastMessage,
    required MessageEnum messageType,
    required String timeSent,
    required String messageId,
  }) async {
    try {
      // Get current user ID
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      // Get chat document to check participants
      final chatDoc = await _firestore.collection(Constants.chats).doc(chatId).get();
      if (!chatDoc.exists) return;
      
      // Get the other participants (not the sender)
      final participants = List<String>.from(chatDoc.data()?['participants'] ?? []);
      final otherParticipants = participants.where((uid) => uid != currentUser.uid).toList();
      
      // For each recipient, increment their unread count
      // In a one-on-one chat, this is just one person
      // In a group chat, this would be multiple people
      await _firestore.collection(Constants.chats).doc(chatId).update({
        Constants.lastMessage: lastMessage,
        Constants.messageType: messageType.name,
        Constants.timeSent: timeSent,
        Constants.lastMessageId: messageId,
        'unreadCount': FieldValue.increment(1), // Only increments for messages TO other users
      });
    } catch (e) {
      debugPrint('Error updating chat last message: $e');
      rethrow;
    }
  }

  // Delete a message for current user
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
      
      // Get the message document
      final messageDoc = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .get();
      
      if (!messageDoc.exists) return;
      
      // Check if current user is the sender
      final senderUID = messageDoc.data()?[Constants.senderUID];
      if (senderUID != currentUser.uid) {
        throw Exception('You can only delete your own messages for everyone');
      }
      
      // Mark the message as deleted for everyone by updating with special flag
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .update({
            Constants.deletedForEveryone: true,
            Constants.message: 'This message was deleted',
          });
          
      // Update last message in chat if this was the last message
      final chatDoc = await _firestore.collection(Constants.chats).doc(chatId).get();
      if (chatDoc.exists) {
        final lastMessageId = chatDoc.data()?[Constants.lastMessageId];
        if (lastMessageId == messageId) {
          await _firestore.collection(Constants.chats).doc(chatId).update({
            Constants.lastMessage: 'This message was deleted',
          });
        }
      }
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
      
      // Get the message document
      final messageDoc = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .get();
      
      if (!messageDoc.exists) return;
      
      // Check if current user is the sender
      final senderUID = messageDoc.data()?[Constants.senderUID];
      if (senderUID != currentUser.uid) {
        throw Exception('You can only edit your own messages');
      }
      
      // Update the message
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .update({
            Constants.message: newMessage,
            Constants.editedAt: DateTime.now().millisecondsSinceEpoch.toString(),
          });
          
      // Update last message in chat if this was the last message
      final chatDoc = await _firestore.collection(Constants.chats).doc(chatId).get();
      if (chatDoc.exists) {
        final lastMessageId = chatDoc.data()?[Constants.lastMessageId];
        if (lastMessageId == messageId) {
          await _firestore.collection(Constants.chats).doc(chatId).update({
            Constants.lastMessage: newMessage,
          });
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
    required String userId,
    required String emoji,
  }) async {
    try {
      // Add reaction to reactions map
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .update({
            'reactions.$userId': emoji,
          });
    } catch (e) {
      debugPrint('Error adding reaction: $e');
      rethrow;
    }
  }

  // Remove reaction from message
  Future<void> removeReaction({
    required String chatId,
    required String messageId,
    required String userId,
  }) async {
    try {
      // Remove user's reaction from the reactions map
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .update({
            'reactions.$userId': FieldValue.delete(),
          });
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
}

// Provider for the chat repository
final chatRepositoryProvider = Provider((ref) {
  return ChatRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});
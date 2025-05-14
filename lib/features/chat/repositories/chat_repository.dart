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

            return ChatModel(
              id: doc.id,
              contactUID: contactUID ?? '',
              contactName: contactName,
              contactImage: contactImage,
              lastMessage: data[Constants.lastMessage] as String? ?? '',
              lastMessageType: (data[Constants.messageType] as String? ?? 'text').toMessageEnum(),
              lastMessageTime: data[Constants.timeSent] as String? ?? '',
              unreadCount: data['unreadCount'] as int? ?? 0,
              isGroup: isGroup,
              groupId: groupId,
            );
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
        isSeen: false,
        repliedMessage: repliedMessage,
        repliedTo: repliedTo,
        repliedMessageType: repliedMessageType,
        seenBy: [currentUser.uid],
        deletedBy: [],
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
        );
      } else {
        // Update existing chat with last message info
        await _updateChatLastMessage(
          chatId: chatId,
          lastMessage: message,
          messageType: messageType,
          timeSent: timeSent,
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

  // Mark a message as seen
  Future<void> markMessageAsSeen({
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
        // Get the current seenBy list
        final seenBy = List<String>.from(messageDoc.data()?[Constants.isSeenBy] ?? []);
        
        // Add the current user if not already in the list
        if (!seenBy.contains(currentUser.uid)) {
          seenBy.add(currentUser.uid);
          
          // Update the message document
          await _firestore
              .collection(Constants.chats)
              .doc(chatId)
              .collection(Constants.messages)
              .doc(messageId)
              .update({
                Constants.isSeenBy: seenBy,
                Constants.isSeen: true,
              });
        }
      }
    } catch (e) {
      debugPrint('Error marking message as seen: $e');
      rethrow;
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
        'unreadCount': 1,
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
  }) async {
    try {
      await _firestore.collection(Constants.chats).doc(chatId).update({
        Constants.lastMessage: lastMessage,
        Constants.messageType: messageType.name,
        Constants.timeSent: timeSent,
        'unreadCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error updating chat last message: $e');
      rethrow;
    }
  }

  // Delete a message
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
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chats/models/chat_message_model.dart';
import 'package:textgb/features/chats/repository/chat_repository.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:uuid/uuid.dart';

/// Repository focused specifically on message operations.
/// Handles creating, sending, and managing individual messages.
class MessageRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final ChatRepository _chatRepository;
  
  MessageRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    ChatRepository? chatRepository,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _storage = storage ?? FirebaseStorage.instance,
    _chatRepository = chatRepository ?? ChatRepository();
  
  // Send text message
  Future<void> sendTextMessage({
    required String message,
    required String senderUID,
    required String senderName,
    required String senderImage,
    required String receiverUID,
    String? repliedMessage,
    String? repliedTo,
    MessageEnum? repliedMessageType,
  }) async {
    try {
      // Generate timestamp and message ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final messageId = const Uuid().v4();
      
      // Create chat ID (combination of sender and receiver UIDs)
      final chatId = _generateChatId(senderUID, receiverUID);
      
      // Create message model
      final messageModel = ChatMessageModel(
        messageId: messageId,
        senderUID: senderUID,
        senderName: senderName,
        senderImage: senderImage,
        contactUID: receiverUID,
        message: message,
        messageType: MessageEnum.text,
        timeSent: timestamp,
        isSeen: false,
        repliedMessage: repliedMessage,
        repliedTo: repliedTo,
        repliedMessageType: repliedMessageType,
        isMe: true, // Set to true for sender's perspective
        reactions: {},
        isSeenBy: [],
        deletedBy: [],
      );
      
      // Add message to Firestore
      await _firestore
          .collection(Constants.messages)
          .doc(messageId)
          .set({
            ...messageModel.toMap(),
            'chatId': chatId,
          });
      
      // Update chat data
      await _chatRepository.updateChatData(
        senderUID: senderUID,
        receiverUID: receiverUID,
        lastMessage: message,
        messageType: MessageEnum.text,
        timestamp: timestamp,
      );
    } catch (e) {
      debugPrint('Error sending text message: $e');
      rethrow;
    }
  }

  // Send media message (image, video, audio, file)
  Future<void> sendMediaMessage({
    required File file,
    required String senderUID,
    required String senderName,
    required String senderImage,
    required String receiverUID,
    required MessageEnum messageType,
    required String message,
    String? repliedMessage,
    String? repliedTo,
    MessageEnum? repliedMessageType,
    int? mediaDuration,
    String? mediaName,
    int? mediaSize,
    String? thumbnailUrl,
  }) async {
    try {
      // Generate timestamp and message ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final messageId = const Uuid().v4();
      
      // Create chat ID
      final chatId = _generateChatId(senderUID, receiverUID);
      
      // Create reference for storing the file
      final fileRef = '${Constants.chatFiles}/$chatId/$messageId';
      
      // Upload file to storage
      final mediaUrl = await storeFileToStorage(
        file: file,
        reference: fileRef,
      );
      
      // Create message model
      final messageModel = ChatMessageModel(
        messageId: messageId,
        senderUID: senderUID,
        senderName: senderName,
        senderImage: senderImage,
        contactUID: receiverUID,
        message: message,
        messageType: messageType,
        timeSent: timestamp,
        isSeen: false,
        repliedMessage: repliedMessage,
        repliedTo: repliedTo,
        repliedMessageType: repliedMessageType,
        isMe: true, // Set to true for sender's perspective
        reactions: {},
        isSeenBy: [],
        deletedBy: [],
        mediaUrl: mediaUrl,
        mediaDuration: mediaDuration,
        mediaName: mediaName,
        mediaSize: mediaSize,
        thumbnailUrl: thumbnailUrl,
      );
      
      // Add message to Firestore
      await _firestore
          .collection(Constants.messages)
          .doc(messageId)
          .set({
            ...messageModel.toMap(),
            'chatId': chatId,
          });
      
      // Update chat data
      await _chatRepository.updateChatData(
        senderUID: senderUID,
        receiverUID: receiverUID,
        lastMessage: message.isEmpty 
            ? messageType.displayName 
            : message,
        messageType: messageType,
        timestamp: timestamp,
      );
    } catch (e) {
      debugPrint('Error sending media message: $e');
      rethrow;
    }
  }
  
  // Send location message
  Future<void> sendLocationMessage({
    required Map<String, dynamic> locationData,
    required String senderUID,
    required String senderName,
    required String senderImage,
    required String receiverUID,
    String? repliedMessage,
    String? repliedTo,
    MessageEnum? repliedMessageType,
  }) async {
    try {
      // Generate timestamp and message ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final messageId = const Uuid().v4();
      
      // Create chat ID
      final chatId = _generateChatId(senderUID, receiverUID);
      
      // Create message model
      final messageModel = ChatMessageModel(
        messageId: messageId,
        senderUID: senderUID,
        senderName: senderName,
        senderImage: senderImage,
        contactUID: receiverUID,
        message: 'Location',
        messageType: MessageEnum.location,
        timeSent: timestamp,
        isSeen: false,
        repliedMessage: repliedMessage,
        repliedTo: repliedTo,
        repliedMessageType: repliedMessageType,
        isMe: true, // Set to true for sender's perspective
        reactions: {},
        isSeenBy: [],
        deletedBy: [],
        locationData: locationData,
      );
      
      // Add message to Firestore
      await _firestore
          .collection(Constants.messages)
          .doc(messageId)
          .set({
            ...messageModel.toMap(),
            'chatId': chatId,
          });
      
      // Update chat data
      await _chatRepository.updateChatData(
        senderUID: senderUID,
        receiverUID: receiverUID,
        lastMessage: 'Location',
        messageType: MessageEnum.location,
        timestamp: timestamp,
      );
    } catch (e) {
      debugPrint('Error sending location message: $e');
      rethrow;
    }
  }
  
  // Send contact message
  Future<void> sendContactMessage({
    required UserModel contactToShare,
    required String senderUID,
    required String senderName,
    required String senderImage,
    required String receiverUID,
    String? repliedMessage,
    String? repliedTo,
    MessageEnum? repliedMessageType,
  }) async {
    try {
      // Generate timestamp and message ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final messageId = const Uuid().v4();
      
      // Create chat ID
      final chatId = _generateChatId(senderUID, receiverUID);
      
      // Extract minimal contact data to share
      final contactData = {
        'uid': contactToShare.uid,
        'name': contactToShare.name,
        'phoneNumber': contactToShare.phoneNumber,
        'image': contactToShare.image,
      };
      
      // Create message model
      final messageModel = ChatMessageModel(
        messageId: messageId,
        senderUID: senderUID,
        senderName: senderName,
        senderImage: senderImage,
        contactUID: receiverUID,
        message: contactToShare.name,
        messageType: MessageEnum.contact,
        timeSent: timestamp,
        isSeen: false,
        repliedMessage: repliedMessage,
        repliedTo: repliedTo,
        repliedMessageType: repliedMessageType,
        isMe: true, // Set to true for sender's perspective
        reactions: {},
        isSeenBy: [],
        deletedBy: [],
        contactData: contactData,
      );
      
      // Add message to Firestore
      await _firestore
          .collection(Constants.messages)
          .doc(messageId)
          .set({
            ...messageModel.toMap(),
            'chatId': chatId,
          });
      
      // Update chat data
      await _chatRepository.updateChatData(
        senderUID: senderUID,
        receiverUID: receiverUID,
        lastMessage: 'Contact: ${contactToShare.name}',
        messageType: MessageEnum.contact,
        timestamp: timestamp,
      );
    } catch (e) {
      debugPrint('Error sending contact message: $e');
      rethrow;
    }
  }
  
  // Forward message to another user
  Future<void> forwardMessage({
    required ChatMessageModel message,
    required String senderUID,
    required String senderName,
    required String senderImage,
    required String receiverUID,
  }) async {
    try {
      // Generate new timestamp and message ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final messageId = const Uuid().v4();
      
      // Create chat ID
      final chatId = _generateChatId(senderUID, receiverUID);
      
      // Create forwarded message model based on original message
      final forwardedMessage = ChatMessageModel(
        messageId: messageId,
        senderUID: senderUID,
        senderName: senderName,
        senderImage: senderImage,
        contactUID: receiverUID,
        message: message.message,
        messageType: message.messageType,
        timeSent: timestamp,
        isSeen: false,
        isMe: true,
        reactions: {},
        isSeenBy: [],
        deletedBy: [],
        mediaUrl: message.mediaUrl,
        mediaDuration: message.mediaDuration,
        thumbnailUrl: message.thumbnailUrl,
        mediaSize: message.mediaSize,
        mediaName: message.mediaName,
        locationData: message.locationData,
        contactData: message.contactData,
      );
      
      // Add forwarded message to Firestore
      await _firestore
          .collection(Constants.messages)
          .doc(messageId)
          .set({
            ...forwardedMessage.toMap(),
            'chatId': chatId,
            'forwarded': true, // Add flag to indicate this is a forwarded message
          });
      
      // Update chat data
      await _chatRepository.updateChatData(
        senderUID: senderUID,
        receiverUID: receiverUID,
        lastMessage: message.message.isEmpty 
            ? message.messageType.displayName
            : message.message,
        messageType: message.messageType,
        timestamp: timestamp,
      );
    } catch (e) {
      debugPrint('Error forwarding message: $e');
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
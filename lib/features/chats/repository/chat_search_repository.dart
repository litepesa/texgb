import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chats/models/chat_message_model.dart';

/// Repository for searching through chat messages.
/// Provides functionality to search messages by text, type, date, etc.
class ChatSearchRepository {
  final FirebaseFirestore _firestore;
  
  ChatSearchRepository({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  // Search for messages by text content
  Future<List<ChatMessageModel>> searchMessagesByContent({
    required String uid,
    required String query,
    int limit = 20,
  }) async {
    try {
      // Get all chats that the user is part of
      final chatDocs = await _firestore
          .collection(Constants.chats)
          .where('participants', arrayContains: uid)
          .get();
      
      final chatIds = chatDocs.docs.map((doc) => doc.get('chatId') as String).toList();
      
      if (chatIds.isEmpty) {
        return [];
      }
      
      // Search through messages in these chats
      final messageDocs = await _firestore
          .collection(Constants.messages)
          .where('chatId', whereIn: chatIds)
          .where(Constants.deletedBy, arrayContains: uid, isNotEqualTo: true)
          .orderBy(Constants.timeSent, descending: true)
          .get();
      
      // Filter messages that contain the search query
      final List<ChatMessageModel> matchingMessages = [];
      
      for (final doc in messageDocs.docs) {
        final message = ChatMessageModel.fromMap(doc.data());
        
        // Skip messages that this user has deleted
        if (message.isDeletedBy(uid)) continue;
        
        // Check if message text contains the search query (case insensitive)
        if (message.message.toLowerCase().contains(query.toLowerCase())) {
          matchingMessages.add(message);
          
          // Limit number of results
          if (matchingMessages.length >= limit) break;
        }
      }
      
      return matchingMessages;
    } catch (e) {
      debugPrint('Error searching messages by content: $e');
      return [];
    }
  }
  
  // Search for messages by type
  Future<List<ChatMessageModel>> searchMessagesByType({
    required String uid,
    required String contactUID,
    required String messageType,
    int limit = 20,
  }) async {
    try {
      // Get chat ID
      final sortedUIDs = [uid, contactUID]..sort();
      final chatId = '${sortedUIDs[0]}-${sortedUIDs[1]}';
      
      // Get messages of specified type
      final messageDocs = await _firestore
          .collection(Constants.messages)
          .where('chatId', isEqualTo: chatId)
          .where(Constants.messageType, isEqualTo: messageType)
          .where(Constants.deletedBy, arrayContains: uid, isNotEqualTo: true)
          .orderBy(Constants.timeSent, descending: true)
          .limit(limit)
          .get();
      
      return messageDocs.docs.map((doc) => ChatMessageModel.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Error searching messages by type: $e');
      return [];
    }
  }
  
  // Search for messages by date range
  Future<List<ChatMessageModel>> searchMessagesByDateRange({
    required String uid,
    required String contactUID,
    required int startTimestamp,
    required int endTimestamp,
    int limit = 50,
  }) async {
    try {
      // Get chat ID
      final sortedUIDs = [uid, contactUID]..sort();
      final chatId = '${sortedUIDs[0]}-${sortedUIDs[1]}';
      
      // Get messages within date range
      final messageDocs = await _firestore
          .collection(Constants.messages)
          .where('chatId', isEqualTo: chatId)
          .where(Constants.timeSent, isGreaterThanOrEqualTo: startTimestamp)
          .where(Constants.timeSent, isLessThanOrEqualTo: endTimestamp)
          .where(Constants.deletedBy, arrayContains: uid, isNotEqualTo: true)
          .orderBy(Constants.timeSent, descending: true)
          .limit(limit)
          .get();
      
      return messageDocs.docs.map((doc) => ChatMessageModel.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Error searching messages by date range: $e');
      return [];
    }
  }
  
  // Get all media messages in a chat
  Future<List<ChatMessageModel>> getAllMediaMessages({
    required String uid,
    required String contactUID,
    int limit = 50,
  }) async {
    try {
      // Get chat ID
      final sortedUIDs = [uid, contactUID]..sort();
      final chatId = '${sortedUIDs[0]}-${sortedUIDs[1]}';
      
      // Media types
      final mediaTypes = [
        MessageEnum.image.name,
        MessageEnum.video.name,
        MessageEnum.audio.name,
        MessageEnum.file.name,
      ];
      
      // Get media messages
      final messageDocs = await _firestore
          .collection(Constants.messages)
          .where('chatId', isEqualTo: chatId)
          .where(Constants.messageType, whereIn: mediaTypes)
          .where(Constants.deletedBy, arrayContains: uid, isNotEqualTo: true)
          .orderBy(Constants.timeSent, descending: true)
          .limit(limit)
          .get();
      
      return messageDocs.docs.map((doc) => ChatMessageModel.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Error getting all media messages: $e');
      return [];
    }
  }
  
  // Get all messages containing links
  Future<List<ChatMessageModel>> getMessagesWithLinks({
    required String uid,
    required String contactUID,
    int limit = 30,
  }) async {
    try {
      // Get chat ID
      final sortedUIDs = [uid, contactUID]..sort();
      final chatId = '${sortedUIDs[0]}-${sortedUIDs[1]}';
      
      // Get all text messages first
      final messageDocs = await _firestore
          .collection(Constants.messages)
          .where('chatId', isEqualTo: chatId)
          .where(Constants.messageType, isEqualTo: MessageEnum.text.name)
          .where(Constants.deletedBy, arrayContains: uid, isNotEqualTo: true)
          .orderBy(Constants.timeSent, descending: true)
          .get();
      
      // Filter for messages containing links (simple URL regex pattern)
      final RegExp urlRegex = RegExp(
        r'(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})',
        caseSensitive: false,
      );
      
      final messagesWithLinks = messageDocs.docs
          .map((doc) => ChatMessageModel.fromMap(doc.data()))
          .where((message) => urlRegex.hasMatch(message.message))
          .take(limit)
          .toList();
      
      return messagesWithLinks;
    } catch (e) {
      debugPrint('Error getting messages with links: $e');
      return [];
    }
  }
}
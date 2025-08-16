// lib/features/chat/repositories/chat_repository.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:uuid/uuid.dart';

abstract class ChatRepository {
  // Chat operations
  Future<String> createOrGetChat(String currentUserId, String otherUserId);
  Stream<List<ChatModel>> getChatsStream(String userId);
  Future<ChatModel?> getChatById(String chatId);
  Future<void> updateChatLastMessage(ChatModel chat);
  Future<void> markChatAsRead(String chatId, String userId);
  Future<void> toggleChatPin(String chatId, String userId);
  Future<void> toggleChatArchive(String chatId, String userId);
  Future<void> toggleChatMute(String chatId, String userId);
  Future<void> setChatWallpaper(String chatId, String userId, String? wallpaperUrl);
  Future<void> setChatFontSize(String chatId, String userId, double fontSize);
  Future<void> deleteChat(String chatId, String userId, {bool deleteForEveryone = false});
  Future<void> clearChatHistory(String chatId, String userId);

  // Message operations
  Future<String> sendMessage(MessageModel message);
  Stream<List<MessageModel>> getMessagesStream(String chatId);
  Future<void> updateMessageStatus(String chatId, String messageId, MessageStatus status);
  Future<void> markMessageAsDelivered(String chatId, String messageId, String userId);
  Future<void> editMessage(String chatId, String messageId, String newContent);
  Future<void> deleteMessage(String chatId, String messageId, bool deleteForEveryone);
  Future<void> pinMessage(String chatId, String messageId);
  Future<void> unpinMessage(String chatId, String messageId);
  Future<List<MessageModel>> searchMessages(String chatId, String query);
  Future<List<MessageModel>> getPinnedMessages(String chatId);

  // Media operations
  Future<String> uploadMedia(File file, String fileName, String chatId);
  Future<void> deleteMedia(String mediaUrl);

  // Utility
  String generateChatId(String userId1, String userId2);
  Future<bool> chatHasMessages(String chatId);
}

class FirebaseChatRepository implements ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final Uuid _uuid;

  FirebaseChatRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    Uuid? uuid,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _uuid = uuid ?? const Uuid();

  @override
  String generateChatId(String userId1, String userId2) {
    // Create consistent chat ID regardless of order
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  @override
  Future<bool> chatHasMessages(String chatId) async {
    try {
      final messagesSnapshot = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .limit(1)
          .get();
      
      return messagesSnapshot.docs.isNotEmpty;
    } catch (e) {
      throw ChatRepositoryException('Failed to check chat messages: $e');
    }
  }

  @override
  Future<String> createOrGetChat(String currentUserId, String otherUserId) async {
    try {
      final chatId = generateChatId(currentUserId, otherUserId);
      final chatDoc = await _firestore.collection(Constants.chats).doc(chatId).get();

      if (!chatDoc.exists) {
        // Create new chat
        final newChat = ChatModel(
          chatId: chatId,
          participants: [currentUserId, otherUserId],
          lastMessage: '',
          lastMessageType: MessageEnum.text,
          lastMessageSender: '',
          lastMessageTime: DateTime.now(),
          unreadCounts: {currentUserId: 0, otherUserId: 0},
          isArchived: {currentUserId: false, otherUserId: false},
          isPinned: {currentUserId: false, otherUserId: false},
          isMuted: {currentUserId: false, otherUserId: false},
          createdAt: DateTime.now(),
        );

        await _firestore.collection(Constants.chats).doc(chatId).set(newChat.toMap());
      }

      return chatId;
    } catch (e) {
      throw ChatRepositoryException('Failed to create or get chat: $e');
    }
  }

  @override
  Stream<List<ChatModel>> getChatsStream(String userId) {
    try {
      return _firestore
          .collection(Constants.chats)
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
        final chats = <ChatModel>[];
        
        for (final doc in snapshot.docs) {
          final chat = ChatModel.fromMap(doc.data());
          
          // Only include chats that are not archived and have messages
          if (!chat.isArchivedForUser(userId)) {
            // Check if chat has any messages
            final hasMessages = await chatHasMessages(chat.chatId);
            if (hasMessages) {
              chats.add(chat);
            }
          }
        }
        
        return chats;
      });
    } catch (e) {
      throw ChatRepositoryException('Failed to get chats stream: $e');
    }
  }

  @override
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final doc = await _firestore.collection(Constants.chats).doc(chatId).get();
      if (doc.exists) {
        return ChatModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw ChatRepositoryException('Failed to get chat by ID: $e');
    }
  }

  @override
  Future<void> updateChatLastMessage(ChatModel chat) async {
    try {
      await _firestore.collection(Constants.chats).doc(chat.chatId).update({
        'lastMessage': chat.lastMessage,
        'lastMessageType': chat.lastMessageType.name,
        'lastMessageSender': chat.lastMessageSender,
        'lastMessageTime': chat.lastMessageTime.millisecondsSinceEpoch,
      });
    } catch (e) {
      throw ChatRepositoryException('Failed to update chat last message: $e');
    }
  }

  @override
  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      await _firestore.collection(Constants.chats).doc(chatId).update({
        'unreadCounts.$userId': 0,
      });
    } catch (e) {
      throw ChatRepositoryException('Failed to mark chat as read: $e');
    }
  }

  @override
  Future<void> toggleChatPin(String chatId, String userId) async {
    try {
      final chatDoc = await _firestore.collection(Constants.chats).doc(chatId).get();
      if (chatDoc.exists) {
        final chat = ChatModel.fromMap(chatDoc.data()!);
        final currentPinStatus = chat.isPinnedForUser(userId);
        
        await _firestore.collection(Constants.chats).doc(chatId).update({
          'isPinned.$userId': !currentPinStatus,
        });
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to toggle chat pin: $e');
    }
  }

  @override
  Future<void> toggleChatArchive(String chatId, String userId) async {
    try {
      final chatDoc = await _firestore.collection(Constants.chats).doc(chatId).get();
      if (chatDoc.exists) {
        final chat = ChatModel.fromMap(chatDoc.data()!);
        final currentArchiveStatus = chat.isArchivedForUser(userId);
        
        await _firestore.collection(Constants.chats).doc(chatId).update({
          'isArchived.$userId': !currentArchiveStatus,
        });
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to toggle chat archive: $e');
    }
  }

  @override
  Future<void> toggleChatMute(String chatId, String userId) async {
    try {
      final chatDoc = await _firestore.collection(Constants.chats).doc(chatId).get();
      if (chatDoc.exists) {
        final chat = ChatModel.fromMap(chatDoc.data()!);
        final currentMuteStatus = chat.isMutedForUser(userId);
        
        await _firestore.collection(Constants.chats).doc(chatId).update({
          'isMuted.$userId': !currentMuteStatus,
        });
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to toggle chat mute: $e');
    }
  }

  @override
  Future<void> deleteChat(String chatId, String userId, {bool deleteForEveryone = false}) async {
    try {
      if (deleteForEveryone) {
        // Delete the entire chat document and all messages
        final batch = _firestore.batch();
        
        // Delete all messages
        final messagesSnapshot = await _firestore
            .collection(Constants.chats)
            .doc(chatId)
            .collection(Constants.messages)
            .get();
        
        for (final doc in messagesSnapshot.docs) {
          batch.delete(doc.reference);
        }
        
        // Delete the chat document
        batch.delete(_firestore.collection(Constants.chats).doc(chatId));
        
        await batch.commit();
        
        // Delete associated media files
        try {
          final mediaRef = _storage.ref().child('${Constants.chatFiles}/$chatId');
          final mediaItems = await mediaRef.listAll();
          
          for (final item in mediaItems.items) {
            await item.delete();
          }
        } catch (e) {
          // Media deletion failed, but continue
          debugPrint('Failed to delete media for chat $chatId: $e');
        }
      } else {
        // Archive the chat for this user only
        await _firestore.collection(Constants.chats).doc(chatId).update({
          'isArchived.$userId': true,
        });
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to delete chat: $e');
    }
  }

  @override
  Future<void> clearChatHistory(String chatId, String userId) async {
    try {
      // Delete all messages in the chat
      final batch = _firestore.batch();
      
      final messagesSnapshot = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .get();
      
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Reset chat last message
      batch.update(_firestore.collection(Constants.chats).doc(chatId), {
        'lastMessage': '',
        'lastMessageType': MessageEnum.text.name,
        'lastMessageSender': '',
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
        'unreadCounts.$userId': 0,
      });
      
      await batch.commit();
    } catch (e) {
      throw ChatRepositoryException('Failed to clear chat history: $e');
    }
  }

  @override
  Future<void> setChatWallpaper(String chatId, String userId, String? wallpaperUrl) async {
    try {
      await _firestore.collection(Constants.chats).doc(chatId).update({
        'chatWallpapers.$userId': wallpaperUrl,
      });
    } catch (e) {
      throw ChatRepositoryException('Failed to set chat wallpaper: $e');
    }
  }

  @override
  Future<void> setChatFontSize(String chatId, String userId, double fontSize) async {
    try {
      await _firestore.collection(Constants.chats).doc(chatId).update({
        'fontSizes.$userId': fontSize,
      });
    } catch (e) {
      throw ChatRepositoryException('Failed to set chat font size: $e');
    }
  }

  @override
  Future<String> sendMessage(MessageModel message) async {
    try {
      final messageId = message.messageId.isEmpty ? _uuid.v4() : message.messageId;
      final finalMessage = message.copyWith(messageId: messageId);

      // Add message to subcollection
      await _firestore
          .collection(Constants.chats)
          .doc(message.chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .set(finalMessage.toMap());

      // Update chat's last message
      await _firestore.collection(Constants.chats).doc(message.chatId).update({
        'lastMessage': message.getDisplayContent(),
        'lastMessageType': message.type.name,
        'lastMessageSender': message.senderId,
        'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
      });

      // Increment unread count for other participants and mark as delivered
      final chatDoc = await _firestore.collection(Constants.chats).doc(message.chatId).get();
      if (chatDoc.exists) {
        final chat = ChatModel.fromMap(chatDoc.data()!);
        final updates = <String, dynamic>{};
        
        for (final participantId in chat.participants) {
          if (participantId != message.senderId) {
            final currentUnread = chat.getUnreadCount(participantId);
            updates['unreadCounts.$participantId'] = currentUnread + 1;
            
            // Automatically mark as delivered for other participants
            Future.delayed(const Duration(seconds: 2), () {
              markMessageAsDelivered(message.chatId, messageId, participantId);
            });
          }
        }
        
        if (updates.isNotEmpty) {
          await _firestore.collection(Constants.chats).doc(message.chatId).update(updates);
        }
      }

      return messageId;
    } catch (e) {
      throw ChatRepositoryException('Failed to send message: $e');
    }
  }

  @override
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    try {
      return _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .orderBy('timestamp', descending: true)
          .limit(50) // Pagination can be added later
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data()))
            .toList();
      });
    } catch (e) {
      throw ChatRepositoryException('Failed to get messages stream: $e');
    }
  }

  @override
  Future<void> updateMessageStatus(String chatId, String messageId, MessageStatus status) async {
    try {
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .update({'status': status.name});
    } catch (e) {
      throw ChatRepositoryException('Failed to update message status: $e');
    }
  }

  @override
  Future<void> markMessageAsDelivered(String chatId, String messageId, String userId) async {
    try {
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .update({
        'deliveredTo.$userId': DateTime.now().millisecondsSinceEpoch,
        'status': MessageStatus.delivered.name,
      });
    } catch (e) {
      throw ChatRepositoryException('Failed to mark message as delivered: $e');
    }
  }

  @override
  Future<void> editMessage(String chatId, String messageId, String newContent) async {
    try {
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .update({
        'content': newContent,
        'isEdited': true,
        'editedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw ChatRepositoryException('Failed to edit message: $e');
    }
  }

  @override
  Future<void> deleteMessage(String chatId, String messageId, bool deleteForEveryone) async {
    try {
      if (deleteForEveryone) {
        // Delete the message document entirely
        await _firestore
            .collection(Constants.chats)
            .doc(chatId)
            .collection(Constants.messages)
            .doc(messageId)
            .delete();
      } else {
        // Mark as deleted for sender only
        await _firestore
            .collection(Constants.chats)
            .doc(chatId)
            .collection(Constants.messages)
            .doc(messageId)
            .update({
          'content': 'This message was deleted',
          'type': MessageEnum.text.name,
          'mediaUrl': null,
          'mediaMetadata': null,
        });
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to delete message: $e');
    }
  }

  @override
  Future<void> pinMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .update({'isPinned': true});
    } catch (e) {
      throw ChatRepositoryException('Failed to pin message: $e');
    }
  }

  @override
  Future<void> unpinMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .update({'isPinned': false});
    } catch (e) {
      throw ChatRepositoryException('Failed to unpin message: $e');
    }
  }

  @override
  Future<List<MessageModel>> searchMessages(String chatId, String query) async {
    try {
      final snapshot = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .where('type', isEqualTo: MessageEnum.text.name)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      final messages = snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data()))
          .where((message) => 
              message.content.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return messages;
    } catch (e) {
      throw ChatRepositoryException('Failed to search messages: $e');
    }
  }

  @override
  Future<List<MessageModel>> getPinnedMessages(String chatId) async {
    try {
      final snapshot = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .where('isPinned', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw ChatRepositoryException('Failed to get pinned messages: $e');
    }
  }

  @override
  Future<String> uploadMedia(File file, String fileName, String chatId) async {
    try {
      // Validate file size (50MB limit)
      final fileSize = await file.length();
      if (fileSize > Constants.maxFileSize) {
        throw ChatRepositoryException('File size exceeds 50MB limit');
      }

      final ref = _storage.ref().child('${Constants.chatFiles}/$chatId/$fileName');
      final uploadTask = ref.putFile(file);
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw ChatRepositoryException('Failed to upload media: $e');
    }
  }

  @override
  Future<void> deleteMedia(String mediaUrl) async {
    try {
      final ref = _storage.refFromURL(mediaUrl);
      await ref.delete();
    } catch (e) {
      throw ChatRepositoryException('Failed to delete media: $e');
    }
  }
}

// Repository provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return FirebaseChatRepository();
});

// Exception class
class ChatRepositoryException implements Exception {
  final String message;
  const ChatRepositoryException(this.message);
  
  @override
  String toString() => 'ChatRepositoryException: $message';
}
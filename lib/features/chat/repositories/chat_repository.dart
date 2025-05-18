import 'dart:io';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/database/chat_database.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ChatDatabase _chatDatabase;

  ChatRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    ChatDatabase? chatDatabase,
  })  : _firestore = firestore,
        _auth = auth,
        _chatDatabase = chatDatabase ?? ChatDatabase();

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

      // Check connectivity
      bool isOnline = true;
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        isOnline = connectivityResult != ConnectivityResult.none;
      } catch (e) {
        // If we can't check connectivity, assume we're online
        debugPrint("Repository: Error checking connectivity: $e");
        isOnline = true;
      }

      if (isOnline) {
        // We're online, prioritize Firebase operations
        debugPrint("Repository: Device is online, sending to Firebase");
        
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
        
        // Also save to local database for offline access
        try {
          await _chatDatabase.saveMessage(chatId, messageModel, syncStatus: SyncStatus.synced);
          debugPrint("Repository: Also saved message to local DB for offline access");
        } catch (e) {
          // If saving to local DB fails, it's not critical since we're online
          debugPrint("Repository: Warning - Failed to save message to local DB: $e");
        }
      } else {
        // We're offline, save to local database for later sync
        debugPrint("Repository: Device is offline, queueing message for later sync");
        
        try {
          // Create/update chat in local database
          final chatExists = await _checkChatExistsLocally(chatId);
          
          if (!chatExists) {
            await _createNewChat(
              chatId: chatId,
              currentUser: senderUser,
              receiverUser: receiverUser,
              lastMessage: message,
              messageType: messageType,
              timeSent: timeSent,
            );
          } else {
            await _updateChatLastMessage(
              chatId: chatId,
              lastMessage: message,
              messageType: messageType,
              timeSent: timeSent,
            );
          }
          
          // Save message to local database with pending status
          await _chatDatabase.saveMessage(chatId, messageModel, syncStatus: SyncStatus.pending);
          
          debugPrint("Repository: Message saved locally for later sync");
        } catch (e) {
          debugPrint("Repository: Error saving message locally: $e");
          throw Exception("Failed to save message for offline use: $e");
        }
      }
    } catch (e) {
      debugPrint("Repository: Error in sendMessage: $e");
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  // Helper method to check if chat exists locally
  Future<bool> _checkChatExistsLocally(String chatId) async {
    try {
      final chats = await _chatDatabase.getChats();
      return chats.any((chat) => chat.id == chatId);
    } catch (e) {
      // If there's an error checking, assume it doesn't exist
      debugPrint("Repository: Error checking if chat exists locally: $e");
      return false;
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
        
        // Also update local database
        await _chatDatabase.updateUnreadCounter(chatId, currentUser.uid, isIncrease, totalUnreadCount);
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
      
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        // Save status updates for later
        for (final messageId in messageIds) {
          await _chatDatabase.updateMessageStatus(messageId, status);
        }
        return;
      }
      
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
      
      // Update local database too
      for (final messageId in messageIds) {
        await _chatDatabase.updateMessageStatus(messageId, status);
      }
      
      debugPrint("Repository: Successfully updated status to ${status.name} for ${messageIds.length} messages");
    } catch (e) {
      debugPrint("Repository: Error updating message statuses: $e");
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

      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
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
      }
      
      // Update locally too
      try {
        await _chatDatabase.markMessageAsDeleted(messageId, currentUser.uid);
      } catch (e) {
        debugPrint("Repository: Error marking message as deleted in local DB: $e");
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
      
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // Update the message document in Firestore
        await _firestore
            .collection(Constants.chats)
            .doc(chatId)
            .collection(Constants.messages)
            .doc(messageId)
            .update({
              'isDeletedForEveryone': true,
            });
      }
      
      // Update locally too
      try {
        await _chatDatabase.deleteMessageForEveryone(messageId);
      } catch (e) {
        debugPrint("Repository: Error marking message as deleted for everyone in local DB: $e");
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
      
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
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
      }
      
      // Update locally too
      try {
        await _chatDatabase.editMessage(messageId, newMessage);
      } catch (e) {
        debugPrint("Repository: Error editing message in local DB: $e");
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
      
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
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
      }
      
      // Update locally too
      try {
        await _chatDatabase.addReaction(messageId, currentUser.uid, emoji);
      } catch (e) {
        debugPrint("Repository: Error adding reaction in local DB: $e");
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
      
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
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
      }
      
      // Update locally too
      try {
        await _chatDatabase.removeReaction(messageId, currentUser.uid);
      } catch (e) {
        debugPrint("Repository: Error removing reaction in local DB: $e");
      }
    } catch (e) {
      debugPrint('Error removing reaction: $e');
      rethrow;
    }
  }

  // Create a new chat locally
  Future<void> _createNewChat({
    required String chatId,
    required UserModel currentUser,
    required UserModel receiverUser,
    required String lastMessage,
    required MessageEnum messageType,
    required String timeSent,
  }) async {
    try {
      // Create a chat model
      ChatModel chatModel = ChatModel(
        id: chatId,
        contactUID: receiverUser.uid,
        contactName: receiverUser.name,
        contactImage: receiverUser.image,
        lastMessage: lastMessage,
        lastMessageType: messageType,
        lastMessageTime: timeSent,
        unreadCount: 0, // No unread for sender
        isGroup: false,
      );
      
      // Save to local database
      await _chatDatabase.saveChat(chatModel);
    } catch (e) {
      debugPrint('Error creating new chat: $e');
      rethrow;
    }
  }

  // Update chat's last message locally
  Future<void> _updateChatLastMessage({
    required String chatId,
    required String lastMessage,
    required MessageEnum messageType,
    required String timeSent,
  }) async {
    try {
      await _chatDatabase.updateChatLastMessage(
        chatId,
        lastMessage,
        messageType,
        timeSent,
      );
    } catch (e) {
      debugPrint('Error updating chat last message: $e');
      rethrow;
    }
  }

  // Sync pending messages with Firestore
  Future<void> syncPendingMessages() async {
    try {
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return; // No connectivity, can't sync
      }
      
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      // Get unsynced messages
      final unsyncedMessages = await _chatDatabase.getUnsyncedMessages();
      debugPrint("Repository: Found ${unsyncedMessages.length} unsynced messages to sync");
      
      if (unsyncedMessages.isEmpty) return;
      
      // Group messages by chat ID for more efficient updates
      Map<String, List<MessageModel>> messagesByChat = {};
      
      for (final message in unsyncedMessages) {
        final chatId = await _chatDatabase.getChatIdForMessage(message.messageId);
        if (chatId != null) {
          if (!messagesByChat.containsKey(chatId)) {
            messagesByChat[chatId] = [];
          }
          messagesByChat[chatId]!.add(message);
        }
      }
      
      // Process each chat's messages in batch
      for (final chatId in messagesByChat.keys) {
        final messages = messagesByChat[chatId]!;
        
        // Use a batch write for efficiency
        WriteBatch batch = _firestore.batch();
        
        // Add each message to the batch
        for (final message in messages) {
          final messageRef = _firestore
              .collection(Constants.chats)
              .doc(chatId)
              .collection(Constants.messages)
              .doc(message.messageId);
              
          // Update message status to sent if it was pending
          MessageModel updatedMessage = message;
          if (message.messageStatus == MessageStatus.sending) {
            updatedMessage = message.copyWith(messageStatus: MessageStatus.sent);
          }
          
          batch.set(messageRef, updatedMessage.toMap());
        }
        
        // Find the most recent message for chat update
        messages.sort((a, b) => int.parse(b.timeSent).compareTo(int.parse(a.timeSent)));
        final mostRecentMessage = messages.first;
        
        // Update the chat document with the most recent message
        final chatRef = _firestore.collection(Constants.chats).doc(chatId);
        batch.update(chatRef, {
          Constants.lastMessage: mostRecentMessage.message,
          Constants.messageType: mostRecentMessage.messageType.name,
          Constants.timeSent: mostRecentMessage.timeSent,
          'lastMessageSender': currentUser.uid,
        });
        
        // Commit the batch
        try {
          await batch.commit();
          
          // Mark all messages as synced
          for (final message in messages) {
            await _chatDatabase.markMessageAsSynced(message.messageId);
            // Also update status to sent
            if (message.messageStatus == MessageStatus.sending) {
              await _chatDatabase.updateMessageStatus(message.messageId, MessageStatus.sent);
            }
          }
          
          debugPrint("Repository: Successfully synced ${messages.length} messages for chat $chatId");
        } catch (e) {
          debugPrint("Repository: Error syncing messages for chat $chatId: $e");
          // Continue with other chats even if one fails
        }
      }
    } catch (e) {
      debugPrint("Repository: Error syncing pending messages: $e");
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
      
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) return;
      
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
}

// Provider for the chat repository
final chatRepositoryProvider = Provider((ref) {
  return ChatRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});
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

            // Only count unread messages if they're not from the current user
            int unreadCount = 0;
            if (data['unreadCount'] != null) {
              final lastMessageSender = data['lastMessageSender'] as String?;
              if (lastMessageSender != null && lastMessageSender != currentUser.uid) {
                unreadCount = data['unreadCount'] as int? ?? 0;
              }
            }

            // Create chat model
            return ChatModel(
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
      print("Repository: Sending message to $chatId");
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
        isSent: true,
        isDelivered: false,
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
        print("Repository: Uploaded file: $fileUrl");
      }

      // Check connectivity
      bool isOnline = true;
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        isOnline = connectivityResult != ConnectivityResult.none;
      } catch (e) {
        // If we can't check connectivity, assume we're online
        print("Repository: Error checking connectivity: $e");
        isOnline = true;
      }

      if (isOnline) {
        // We're online, prioritize Firebase operations
        print("Repository: Device is online, sending to Firebase");
        
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
            'unreadCount': 0, // No unread for messages sent by current user
            'isGroup': false,
          });
          print("Repository: Created new chat in Firestore");
        } else {
          // Update existing chat
          await _firestore.collection(Constants.chats).doc(chatId).update({
            Constants.lastMessage: message,
            Constants.messageType: messageType.name,
            Constants.timeSent: timeSent,
            'lastMessageSender': currentUser.uid,
          });
          print("Repository: Updated existing chat in Firestore");
        }

        // Add the message to Firestore
        await _firestore
            .collection(Constants.chats)
            .doc(chatId)
            .collection(Constants.messages)
            .doc(messageId)
            .set(messageModel.toMap());
        
        print("Repository: Message saved to Firestore successfully");
        
        // Also save to local database for offline access
        try {
          await _chatDatabase.saveMessage(chatId, messageModel, syncStatus: SyncStatus.synced);
          print("Repository: Also saved message to local DB for offline access");
        } catch (e) {
          // If saving to local DB fails, it's not critical since we're online
          print("Repository: Warning - Failed to save message to local DB: $e");
        }
      } else {
        // We're offline, save to local database for later sync
        print("Repository: Device is offline, queueing message for later sync");
        
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
          
          print("Repository: Message saved locally for later sync");
        } catch (e) {
          print("Repository: Error saving message locally: $e");
          throw Exception("Failed to save message for offline use: $e");
        }
      }
    } catch (e) {
      print("Repository: Error in sendMessage: $e");
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
      print("Repository: Error checking if chat exists locally: $e");
      return false;
    }
  }

  // Mark a message as delivered
  Future<void> markMessageAsDelivered({
    required String chatId,
    required String messageId,
  }) async {
    try {
      // Update in Firestore
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        await _firestore
            .collection(Constants.chats)
            .doc(chatId)
            .collection(Constants.messages)
            .doc(messageId)
            .update({
              'isDelivered': true,
            });
      }
      
      // Also update in local database
      try {
        await _chatDatabase.updateMessageDeliveryStatus(messageId, true);
      } catch (e) {
        print("Repository: Error updating message delivery status in local DB: $e");
      }
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
        print("Repository: Error marking message as deleted in local DB: $e");
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
        print("Repository: Error marking message as deleted for everyone in local DB: $e");
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
        print("Repository: Error editing message in local DB: $e");
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
        print("Repository: Error adding reaction in local DB: $e");
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
        print("Repository: Error removing reaction in local DB: $e");
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
      print("Repository: Found ${unsyncedMessages.length} unsynced messages to sync");
      
      for (final message in unsyncedMessages) {
        try {
          // We need to know which chat this message belongs to
          // This would be better stored with the message, but for now we'll query
          final chats = await _chatDatabase.getChats();
          
          // Find a chat that might contain this message
          // This is not a perfect solution but works for basic offline functionality
          for (final chat in chats) {
            // Try to add message to Firestore
            await _firestore
                .collection(Constants.chats)
                .doc(chat.id)
                .collection(Constants.messages)
                .doc(message.messageId)
                .set(message.toMap());
            
            // Update chat's last message if this is the most recent
            if (int.parse(message.timeSent) > int.parse(chat.lastMessageTime)) {
              await _firestore.collection(Constants.chats).doc(chat.id).update({
                Constants.lastMessage: message.message,
                Constants.messageType: message.messageType.name,
                Constants.timeSent: message.timeSent,
                'lastMessageSender': currentUser.uid,
              });
            }
            
            // Mark message as synced
            await _chatDatabase.markMessageAsSynced(message.messageId);
            print("Repository: Synced message ${message.messageId} to Firestore");
            
            // Once we find a chat, we can stop looking
            break;
          }
        } catch (e) {
          print("Repository: Error syncing message ${message.messageId}: $e");
          // Continue with other messages even if one fails
        }
      }
    } catch (e) {
      print("Repository: Error syncing pending messages: $e");
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
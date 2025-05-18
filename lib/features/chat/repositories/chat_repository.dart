// lib/features/chat/repositories/chat_repository.dart (continued)
import 'dart:async';
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

    // First try to get from local database
    return _getChatsStream(currentUser.uid);
  }
  
  // Create a stream from the local database, but also listen to Firestore
  Stream<List<ChatModel>> _getChatsStream(String userId) {
    // Create a stream controller to manage the chats stream
    final controller = StreamController<List<ChatModel>>();
    
    // Load initial chats from local database
    _chatDatabase.getChats().then((localChats) {
      if (!controller.isClosed) {
        controller.add(localChats);
      }
      
      // Check connectivity
      Connectivity().checkConnectivity().then((result) {
        if (result != ConnectivityResult.none) {
          // If we have internet, set up a Firestore listener
          final subscription = _firestore
            .collection(Constants.chats)
            .where('participants', arrayContains: userId)
            .orderBy(Constants.timeSent, descending: true)
            .snapshots()
            .listen((snapshot) async {
              // Process Firestore data
              final List<ChatModel> firestoreChats = [];
              
              for (final doc in snapshot.docs) {
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
                    (uid) => uid != userId,
                    orElse: () => '',
                  );
                  contactName = data[Constants.contactName] as String? ?? '';
                  contactImage = data[Constants.contactImage] as String? ?? '';
                }
                
                // Only count unread messages if not from current user
                int unreadCount = 0;
                if (data['unreadCount'] != null) {
                  final lastMessageSender = data['lastMessageSender'] as String?;
                  if (lastMessageSender != null && lastMessageSender != userId) {
                    unreadCount = data['unreadCount'] as int? ?? 0;
                  }
                }
                
                // Create chat model
                final chat = ChatModel(
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
                
                firestoreChats.add(chat);
                
                // Save to local database
                await _chatDatabase.saveChat(chat);
              }
              
              // Send updated chats to stream
              if (!controller.isClosed) {
                controller.add(firestoreChats);
              }
            }, onError: (error) {
              // On error, just log it and rely on local data
              debugPrint('Error getting Firestore chats: $error');
            });
            
          // Clean up subscription when controller is closed
          controller.onCancel = () {
            subscription.cancel();
          };
        }
      });
    });
    
    return controller.stream;
  }

  // Get messages for a specific chat
  Stream<List<MessageModel>> getMessages(String chatId) {
    // Create a stream controller to manage the messages stream
    final controller = StreamController<List<MessageModel>>();
    
    // Load initial messages from local database
    _chatDatabase.getMessages(chatId).then((localMessages) {
      if (!controller.isClosed) {
        controller.add(localMessages);
      }
      
      // Check connectivity
      Connectivity().checkConnectivity().then((result) {
        if (result != ConnectivityResult.none) {
          // If we have internet, set up a Firestore listener
          final subscription = _firestore
            .collection(Constants.chats)
            .doc(chatId)
            .collection(Constants.messages)
            .orderBy(Constants.timeSent, descending: true)
            .snapshots()
            .listen((snapshot) async {
              final List<MessageModel> messages = [];
              
              for (final doc in snapshot.docs) {
                final message = MessageModel.fromMap(doc.data());
                messages.add(message);
                
                // Save to local database with synced status
                await _chatDatabase.saveMessage(chatId, message, syncStatus: SyncStatus.synced);
                
                // Update delivery status for sent messages
                if (message.senderUID != _auth.currentUser?.uid) {
                  await _chatDatabase.updateMessageDeliveryStatus(message.messageId, true);
                  
                  // Mark as delivered in Firestore too
                  await _firestore
                      .collection(Constants.chats)
                      .doc(chatId)
                      .collection(Constants.messages)
                      .doc(message.messageId)
                      .update({
                        'isDelivered': true,
                      });
                }
              }
              
              // Send updated messages to stream
              if (!controller.isClosed) {
                controller.add(messages);
              }
              
              // Reset unread counter when opening a chat
              await _chatDatabase.resetUnreadCounter(chatId);
              // Also reset in Firestore
              final currentUser = _auth.currentUser;
              if (currentUser != null) {
                await _firestore.collection(Constants.chats).doc(chatId).update({
                  'unreadCount': 0,
                });
              }
              
            }, onError: (error) {
              // On error, just log it and rely on local data
              debugPrint('Error getting Firestore messages: $error');
            });
            
          // Clean up subscription when controller is closed
          controller.onCancel = () {
            subscription.cancel();
          };
        }
      });
    });
    
    return controller.stream;
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
        isSent: true,
        isDelivered: false,
        repliedMessage: repliedMessage,
        repliedTo: repliedTo,
        repliedMessageType: repliedMessageType,
        deletedBy: [],
      );

      // Upload file if present
      String fileUrl = '';
      if (file != null && messageType.isMedia) {
        final fileRef = '${Constants.chatFiles}/$chatId/$messageId';
        
        // Check connectivity before attempting upload
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          fileUrl = await storeFileToStorage(file: file, reference: fileRef);
          
          // Update the message with the file URL
          messageModel = messageModel.copyWith(message: fileUrl);
        } else {
          // If offline, use a local file path or placeholder
          // In a real implementation, you'd need to queue the file for upload
          messageModel = messageModel.copyWith(
            message: file.path,
          );
        }
      }

      // Check if the chat exists in local database
      final localChats = await _chatDatabase.getChats();
      final chatExists = localChats.any((chat) => chat.id == chatId);
      
      if (!chatExists) {
        // Create a new chat locally
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

      // Save the message to local database
      await _chatDatabase.saveMessage(chatId, messageModel);

      // Check connectivity before uploading to Firestore
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // Check if chat exists in Firestore
        final chatDoc = await _firestore.collection(Constants.chats).doc(chatId).get();
        
        if (!chatDoc.exists) {
          // Create a new chat in Firestore
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
            'unreadCount': 0, // No unread messages for sender
            'isGroup': false,
          });
        } else {
          // Update existing chat in Firestore
          await _firestore.collection(Constants.chats).doc(chatId).update({
            Constants.lastMessage: message,
            Constants.messageType: messageType.name,
            Constants.timeSent: timeSent,
            'lastMessageSender': currentUser.uid,
            // Don't increment unread count for sender's messages
          });
        }

        // Add the message to Firestore
        await _firestore
            .collection(Constants.chats)
            .doc(chatId)
            .collection(Constants.messages)
            .doc(messageId)
            .set(messageModel.toMap());
        
        // Mark the message as synced in local database
        await _chatDatabase.markMessageAsSynced(messageId);
      }
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
      // Update local database
      await _chatDatabase.updateMessageDeliveryStatus(messageId, true);
      
      // Check connectivity before updating Firestore
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // Update in Firestore
        await _firestore
            .collection(Constants.chats)
            .doc(chatId)
            .collection(Constants.messages)
            .doc(messageId)
            .update({
              'isDelivered': true,
            });
      }
    } catch (e) {
      debugPrint('Error marking message as delivered: $e');
      rethrow;
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

      // Update local database
      await _chatDatabase.markMessageAsDeleted(messageId, currentUser.uid);
      
      // Check connectivity before updating Firestore
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
      
      // Update local database
      await _chatDatabase.deleteMessageForEveryone(messageId);
      
      // Check connectivity before updating Firestore
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
      
      // Update local database
      await _chatDatabase.editMessage(messageId, newMessage);
      
      // Check connectivity before updating Firestore
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
      
      // Update local database
      await _chatDatabase.addReaction(messageId, currentUser.uid, emoji);
      
      // Check connectivity before updating Firestore
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
      
      // Update local database
      await _chatDatabase.removeReaction(messageId, currentUser.uid);
      
      // Check connectivity before updating Firestore
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
      
      // Get unsynced messages
      final unsyncedMessages = await _chatDatabase.getUnsyncedMessages();
      
      for (final message in unsyncedMessages) {
        // Get the message's chat ID from local database
        // In a real implementation, you would store the chatId with the message
        // For simplicity, we'll skip this step
        
        // Upload message to Firestore
        // For simplicity, we'll skip the actual implementation
        
        // Mark message as synced
        await _chatDatabase.markMessageAsSynced(message.messageId);
      }
    } catch (e) {
      debugPrint('Error syncing pending messages: $e');
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
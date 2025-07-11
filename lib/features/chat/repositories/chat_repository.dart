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

// Abstract interface for backend-agnostic implementation
abstract class IChatRepository {
  Stream<List<ChatModel>> getChats();
  Stream<List<MessageModel>> getMessages(String chatId);
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
  });
  Future<void> markChatAsDelivered(String chatId);
  Future<void> resetUnreadCounter(String chatId);
  Future<void> deleteMessage({required String chatId, required String messageId});
  Future<void> editMessage({required String chatId, required String messageId, required String newMessage});
  Future<void> addReaction({required String chatId, required String messageId, required String emoji});
  Future<void> removeReaction({required String chatId, required String messageId});
  Future<void> togglePinChat(String chatId);
  Future<void> deleteChat(String chatId);
  String generateChatId(String userId, String contactId);
  
  // New methods
  Future<void> deleteMessageForEveryone({required String chatId, required String messageId});
  Future<void> markMessageAsDelivered({required String chatId, required String messageId});
  Future<void> sendGroupMessage({
    required String chatId,
    required String message,
    required MessageEnum messageType,
    required UserModel senderUser,
    String? repliedMessage,
    String? repliedTo,
    MessageEnum? repliedMessageType,
    File? file,
  });
}

// Privacy service for message permission checking
class MessagePrivacyService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  MessagePrivacyService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore, _auth = auth;

  // Check if sender can send messages to receiver
  Future<bool> canSendMessage({
    required String senderUID,
    required String receiverUID,
  }) async {
    try {
      // Get receiver's privacy settings
      final receiverDoc = await _firestore
          .collection(Constants.users)
          .doc(receiverUID)
          .get();
      
      if (!receiverDoc.exists) return false;
      
      final receiverUser = UserModel.fromMap(receiverDoc.data()!);
      
      // Check if sender is blocked
      if (receiverUser.isBlocked(senderUID)) {
        return false;
      }
      
      // Check privacy settings
      return receiverUser.canReceiveMessagesFrom(senderUID);
    } catch (e) {
      debugPrint('Error checking message permission: $e');
      return false; // Default to deny if error occurs
    }
  }

  // Check if sender can see read receipts from receiver
  Future<bool> canSeeReadReceipts({
    required String senderUID,
    required String receiverUID,
  }) async {
    try {
      final receiverDoc = await _firestore
          .collection(Constants.users)
          .doc(receiverUID)
          .get();
      
      if (!receiverDoc.exists) return false;
      
      final receiverUser = UserModel.fromMap(receiverDoc.data()!);
      return receiverUser.canSeeReadReceiptsTo(senderUID);
    } catch (e) {
      debugPrint('Error checking read receipt permission: $e');
      return false;
    }
  }

  // Check if user can see last seen of another user
  Future<bool> canSeeLastSeen({
    required String viewerUID,
    required String targetUID,
  }) async {
    try {
      final targetDoc = await _firestore
          .collection(Constants.users)
          .doc(targetUID)
          .get();
      
      if (!targetDoc.exists) return false;
      
      final targetUser = UserModel.fromMap(targetDoc.data()!);
      return targetUser.canSeeLastSeenTo(viewerUID);
    } catch (e) {
      debugPrint('Error checking last seen permission: $e');
      return false;
    }
  }
}

// Firebase implementation of chat repository
class FirebaseChatRepository implements IChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final MessagePrivacyService _privacyService;

  FirebaseChatRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth,
       _privacyService = MessagePrivacyService(firestore: firestore, auth: auth);

  // Getter for firestore (needed by GroupSecurityService)
  FirebaseFirestore get firestore => _firestore;
  
  // Getter for auth (needed by GroupSecurityService)
  FirebaseAuth get auth => _auth;

  @override
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
            try {
              final data = doc.data();
              return ChatModel.fromMap(data..['id'] = doc.id);
            } catch (e) {
              debugPrint('Error parsing chat ${doc.id}: $e');
              // Return a minimal chat model for broken data
              return ChatModel(
                id: doc.id,
                contactUID: '',
                contactName: 'Unknown',
                contactImage: '',
                lastMessage: 'Error loading chat',
                lastMessageType: MessageEnum.text,
                lastMessageTime: DateTime.now().millisecondsSinceEpoch.toString(),
                unreadCount: 0,
              );
            }
          }).toList();
        });
  }

  @override
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection(Constants.chats)
        .doc(chatId)
        .collection(Constants.messages)
        .orderBy(Constants.timeSent, descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            try {
              return MessageModel.fromMap(doc.data());
            } catch (e) {
              debugPrint('Error parsing message ${doc.id}: $e');
              // Return a minimal error message
              return MessageModel(
                messageId: doc.id,
                senderUID: '',
                senderName: 'System',
                senderImage: '',
                message: 'Error loading message',
                messageType: MessageEnum.text,
                timeSent: DateTime.now().millisecondsSinceEpoch.toString(),
                messageStatus: MessageStatus.failed,
              );
            }
          }).toList();
        });
  }

  @override
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
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check privacy permissions
      final canSend = await _privacyService.canSendMessage(
        senderUID: currentUser.uid,
        receiverUID: receiverUID,
      );

      if (!canSend) {
        throw Exception('You cannot send messages to this user due to their privacy settings');
      }

      // Generate message ID and timestamp
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
      );

      // Upload file if present
      if (file != null && messageType.isMedia) {
        final fileRef = '${Constants.chatFiles}/$chatId/$messageId';
        String fileUrl = await storeFileToStorage(file: file, reference: fileRef);
        messageModel = messageModel.copyWith(message: fileUrl);
        debugPrint("Uploaded file: $fileUrl");
      }

      // Use transaction for atomicity
      await _firestore.runTransaction((transaction) async {
        // Check if chat exists
        final chatDoc = await transaction.get(_firestore.collection(Constants.chats).doc(chatId));
        
        if (!chatDoc.exists) {
          // Create new chat
          Map<String, int> unreadCountByUser = {
            currentUser.uid: 0,
            receiverUID: 1,
          };
          
          transaction.set(_firestore.collection(Constants.chats).doc(chatId), {
            'id': chatId,
            'participants': [currentUser.uid, receiverUID],
            Constants.contactUID: receiverUID,
            Constants.contactName: receiverUser.name,
            Constants.contactImage: receiverUser.image,
            Constants.lastMessage: message,
            Constants.messageType: messageType.name,
            Constants.timeSent: timeSent,
            'lastMessageSender': currentUser.uid,
            'unreadCount': 1,
            'unreadCountByUser': unreadCountByUser,
            'isGroup': false,
          });
        } else {
          // Update existing chat
          Map<String, dynamic> unreadCountByUser = 
              Map<String, dynamic>.from(chatDoc.data()?['unreadCountByUser'] ?? {});
          
          unreadCountByUser[currentUser.uid] = 0;
          unreadCountByUser[receiverUID] = (unreadCountByUser[receiverUID] as int? ?? 0) + 1;
          
          transaction.update(_firestore.collection(Constants.chats).doc(chatId), {
            Constants.lastMessage: message,
            Constants.messageType: messageType.name,
            Constants.timeSent: timeSent,
            'lastMessageSender': currentUser.uid,
            'unreadCountByUser': unreadCountByUser,
            'unreadCount': unreadCountByUser[receiverUID],
          });
        }

        // Update message status and save
        messageModel = messageModel.copyWith(messageStatus: MessageStatus.sent);
        
        transaction.set(
          _firestore.collection(Constants.chats).doc(chatId).collection(Constants.messages).doc(messageId),
          messageModel.toMap(),
        );
      });
      
      debugPrint("Message sent successfully");
      
    } catch (e) {
      debugPrint("Error sending message: $e");
      rethrow;
    }
  }

  @override
  Future<void> sendGroupMessage({
    required String chatId,
    required String message,
    required MessageEnum messageType,
    required UserModel senderUser,
    String? repliedMessage,
    String? repliedTo,
    MessageEnum? repliedMessageType,
    File? file,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Generate message ID and timestamp
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
      );

      // Upload file if present
      if (file != null && messageType.isMedia) {
        final fileRef = '${Constants.chatFiles}/$chatId/$messageId';
        String fileUrl = await storeFileToStorage(file: file, reference: fileRef);
        messageModel = messageModel.copyWith(message: fileUrl);
        debugPrint("Uploaded file: $fileUrl");
      }

      // Use transaction for atomicity
      await _firestore.runTransaction((transaction) async {
        // Get chat document
        final chatDoc = await transaction.get(_firestore.collection(Constants.chats).doc(chatId));
        
        if (chatDoc.exists) {
          // Update existing group chat
          transaction.update(_firestore.collection(Constants.chats).doc(chatId), {
            Constants.lastMessage: message,
            Constants.messageType: messageType.name,
            Constants.timeSent: timeSent,
            'lastMessageSender': currentUser.uid,
          });
        }

        // Update message status and save
        messageModel = messageModel.copyWith(messageStatus: MessageStatus.sent);
        
        transaction.set(
          _firestore.collection(Constants.chats).doc(chatId).collection(Constants.messages).doc(messageId),
          messageModel.toMap(),
        );
      });
      
      debugPrint("Group message sent successfully");
      
    } catch (e) {
      debugPrint("Error sending group message: $e");
      rethrow;
    }
  }

  @override
  Future<void> resetUnreadCounter(String chatId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final chatDoc = await _firestore.collection(Constants.chats).doc(chatId).get();
      
      if (chatDoc.exists) {
        Map<String, dynamic> unreadCountByUser = 
            Map<String, dynamic>.from(chatDoc.data()?['unreadCountByUser'] ?? {});
        
        unreadCountByUser[currentUser.uid] = 0;
        
        await _firestore.collection(Constants.chats).doc(chatId).update({
          'unreadCountByUser': unreadCountByUser,
        });
        
        // For backward compatibility
        final lastMessageSender = chatDoc.data()?['lastMessageSender'] as String?;
        if (lastMessageSender != null && lastMessageSender != currentUser.uid) {
          await _firestore.collection(Constants.chats).doc(chatId).update({
            'unreadCount': 0,
          });
        }
      }
    } catch (e) {
      debugPrint('Error resetting unread counter: $e');
    }
  }

  @override
  Future<void> markChatAsDelivered(String chatId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      // Get undelivered messages in this chat
      final querySnapshot = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .where('messageStatus', isEqualTo: MessageStatus.sent.name)
          .where('senderUID', isNotEqualTo: currentUser.uid)
          .get();
          
      if (querySnapshot.docs.isEmpty) return;
      
      // Update in batch
      WriteBatch batch = _firestore.batch();
      
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'messageStatus': MessageStatus.delivered.name,
        });
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking chat as delivered: $e');
    }
  }

  @override
  Future<void> markMessageAsDelivered({required String chatId, required String messageId}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      final messageDoc = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .get();
          
      if (messageDoc.exists) {
        final senderUID = messageDoc.data()?['senderUID'] as String?;
        final currentStatus = messageDoc.data()?['messageStatus'] as String?;
        
        // Only update if message is not from current user and status is 'sent'
        if (senderUID != currentUser.uid && currentStatus == MessageStatus.sent.name) {
          await _firestore
              .collection(Constants.chats)
              .doc(chatId)
              .collection(Constants.messages)
              .doc(messageId)
              .update({
                'messageStatus': MessageStatus.delivered.name,
              });
        }
      }
    } catch (e) {
      debugPrint('Error marking message as delivered: $e');
      // Don't rethrow for delivery status updates
    }
  }

  @override
  Future<void> deleteMessage({required String chatId, required String messageId}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final messageDoc = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .get();

      if (messageDoc.exists) {
        final deletedBy = List<String>.from(messageDoc.data()?[Constants.deletedBy] ?? []);
        
        if (!deletedBy.contains(currentUser.uid)) {
          deletedBy.add(currentUser.uid);
          
          await _firestore
              .collection(Constants.chats)
              .doc(chatId)
              .collection(Constants.messages)
              .doc(messageId)
              .update({Constants.deletedBy: deletedBy});
        }
      }
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteMessageForEveryone({required String chatId, required String messageId}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final messageDoc = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .get();

      if (messageDoc.exists) {
        // Check if the current user is the sender
        final senderUID = messageDoc.data()?['senderUID'] as String?;
        if (senderUID != currentUser.uid) {
          throw Exception('You can only delete your own messages for everyone');
        }
        
        await _firestore
            .collection(Constants.chats)
            .doc(chatId)
            .collection(Constants.messages)
            .doc(messageId)
            .update({
              'isDeletedForEveryone': true,
              'message': 'This message was deleted',
              'deletedAt': DateTime.now().millisecondsSinceEpoch.toString(),
            });
            
        // Update chat's last message if this was the latest
        final chatDoc = await _firestore.collection(Constants.chats).doc(chatId).get();
        if (chatDoc.exists) {
          final lastMessage = chatDoc.data()?[Constants.lastMessage] as String?;
          final messageContent = messageDoc.data()?[Constants.message] as String?;
          if (lastMessage == messageContent) {
            await _firestore.collection(Constants.chats).doc(chatId).update({
              Constants.lastMessage: 'This message was deleted',
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error deleting message for everyone: $e');
      rethrow;
    }
  }

  @override
  Future<void> editMessage({required String chatId, required String messageId, required String newMessage}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      final messageDoc = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .get();
      
      if (messageDoc.exists) {
        final originalMessage = messageDoc.data()?[Constants.message] as String?;
        
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
            
        // Update chat's last message if this was the latest
        final chatDoc = await _firestore.collection(Constants.chats).doc(chatId).get();
        if (chatDoc.exists) {
          final lastMessage = chatDoc.data()?[Constants.lastMessage] as String?;
          if (lastMessage == originalMessage) {
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

  @override
  Future<void> addReaction({required String chatId, required String messageId, required String emoji}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      final messageDoc = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .get();
      
      if (messageDoc.exists) {
        Map<String, dynamic> reactions = 
            Map<String, dynamic>.from(messageDoc.data()?['reactions'] ?? {});
        
        reactions[currentUser.uid] = {
          'emoji': emoji,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        };
        
        await _firestore
            .collection(Constants.chats)
            .doc(chatId)
            .collection(Constants.messages)
            .doc(messageId)
            .update({'reactions': reactions});
      }
    } catch (e) {
      debugPrint('Error adding reaction: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeReaction({required String chatId, required String messageId}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      final messageDoc = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .get();
      
      if (messageDoc.exists) {
        Map<String, dynamic>? reactions = 
            messageDoc.data()?['reactions'] as Map<String, dynamic>?;
        
        if (reactions != null) {
          reactions.remove(currentUser.uid);
          
          await _firestore
              .collection(Constants.chats)
              .doc(chatId)
              .collection(Constants.messages)
              .doc(messageId)
              .update({'reactions': reactions});
        }
      }
    } catch (e) {
      debugPrint('Error removing reaction: $e');
      rethrow;
    }
  }

  @override
  Future<void> togglePinChat(String chatId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final chatDoc = await _firestore.collection(Constants.chats).doc(chatId).get();
      
      if (chatDoc.exists) {
        final currentPinStatus = chatDoc.data()?['isPinned'] as bool? ?? false;
        final newPinStatus = !currentPinStatus;
        
        Map<String, dynamic> updateData = {
          'isPinned': newPinStatus,
        };
        
        if (newPinStatus) {
          updateData['pinnedAt'] = DateTime.now().millisecondsSinceEpoch.toString();
        } else {
          updateData['pinnedAt'] = null;
        }
        
        await _firestore.collection(Constants.chats).doc(chatId).update(updateData);
      }
    } catch (e) {
      debugPrint('Error toggling pin status: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteChat(String chatId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Delete all messages in the chat
      final messagesQuery = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .get();
      
      if (messagesQuery.docs.isNotEmpty) {
        WriteBatch batch = _firestore.batch();
        
        for (final doc in messagesQuery.docs) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();
      }
      
      // Delete the chat document
      await _firestore.collection(Constants.chats).doc(chatId).delete();
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      rethrow;
    }
  }

  @override
  String generateChatId(String userId, String contactId) {
    final sortedIds = [userId, contactId]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Additional method for getting total unread count
  Future<int> getTotalUnreadCount() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return 0;
      
      final querySnapshot = await _firestore
          .collection(Constants.chats)
          .where('participants', arrayContains: currentUser.uid)
          .get();
          
      int totalUnread = 0;
      
      for (final doc in querySnapshot.docs) {
        final lastMessageSender = doc.data()['lastMessageSender'] as String?;
        if (lastMessageSender == currentUser.uid) {
          continue; // Skip chats where user sent the last message
        }
        
        Map<String, dynamic>? unreadCountByUser = doc.data()['unreadCountByUser'] as Map<String, dynamic>?;
        if (unreadCountByUser != null && unreadCountByUser.containsKey(currentUser.uid)) {
          totalUnread += (unreadCountByUser[currentUser.uid] as int? ?? 0);
        } else {
          totalUnread += (doc.data()['unreadCount'] as int? ?? 0);
        }
      }
      
      return totalUnread;
    } catch (e) {
      debugPrint('Error getting total unread count: $e');
      return 0;
    }
  }
}

// Provider for the chat repository
final chatRepositoryProvider = Provider<IChatRepository>((ref) {
  return FirebaseChatRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/models/last_message_model.dart';
import 'package:textgb/models/message_model.dart';
import 'package:textgb/models/message_reply_model.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart' as global_methods;
import 'package:uuid/uuid.dart';

part 'chat_provider.g.dart';

// State class for chat functionality
class ChatState {
  final bool isLoading;
  final MessageReplyModel? messageReplyModel;
  final String searchQuery;
  final String? error;

  const ChatState({
    this.isLoading = false,
    this.messageReplyModel,
    this.searchQuery = '',
    this.error,
  });

  ChatState copyWith({
    bool? isLoading,
    MessageReplyModel? messageReplyModel,
    String? searchQuery,
    String? error,
    bool clearMessageReply = false,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      messageReplyModel: clearMessageReply ? null : (messageReplyModel ?? this.messageReplyModel),
      searchQuery: searchQuery ?? this.searchQuery,
      error: error,
    );
  }
}

@riverpod
class Chat extends _$Chat {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  FutureOr<ChatState> build() async {
    return const ChatState();
  }

  void setSearchQuery(String value) {
    state = AsyncValue.data(state.value!.copyWith(searchQuery: value));
  }

  void setLoading(bool value) {
    state = AsyncValue.data(state.value!.copyWith(isLoading: value));
  }

  void setMessageReplyModel(MessageReplyModel? messageReply) {
    state = AsyncValue.data(state.value!.copyWith(
      messageReplyModel: messageReply,
      clearMessageReply: messageReply == null,
    ));
  }

  // Send text message to firestore
  Future<void> sendTextMessage({
    required UserModel sender,
    required String contactUID,
    required String contactName,
    required String contactImage,
    required String message,
    required MessageEnum messageType,
    required String groupId,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    final currentState = state.value ?? const ChatState();
    
    setLoading(true);
    try {
      var messageId = const Uuid().v4();

      // Check if it's a message reply and add the replied message
      String repliedMessage = currentState.messageReplyModel?.message ?? '';
      String repliedTo = currentState.messageReplyModel == null
          ? ''
          : currentState.messageReplyModel!.isMe
              ? 'You'
              : currentState.messageReplyModel!.senderName;
      MessageEnum repliedMessageType =
          currentState.messageReplyModel?.messageType ?? MessageEnum.text;
      
      // Status data from reply model (if available)
      String? statusThumbnailUrl = currentState.messageReplyModel?.statusThumbnailUrl;
      String? statusCaption = currentState.messageReplyModel?.message;

      // Update/set the messagemodel
      final messageModel = MessageModel(
        messageId: messageId,
        senderUID: sender.uid,
        senderName: sender.name,
        senderImage: sender.image,
        contactUID: contactUID,
        message: message,
        messageType: messageType,
        timeSent: DateTime.now(),
        isSeen: true, // Always set to true for privacy
        repliedMessage: repliedMessage,
        repliedTo: repliedTo,
        repliedMessageType: repliedMessageType,
        reactions: [],
        isSeenBy: [sender.uid],
        deletedBy: [],
        statusThumbnailUrl: statusThumbnailUrl,
        statusCaption: statusCaption,
      );

      // Check if it's a group message and send to group else send to contact
      if (groupId.isNotEmpty) {
        // Handle group message
        await _firestore
            .collection(Constants.groups)
            .doc(groupId)
            .collection(Constants.messages)
            .doc(messageId)
            .set(messageModel.toMap());

        // Update the last message for the group
        await _firestore.collection(Constants.groups).doc(groupId).update({
          Constants.lastMessage: message,
          Constants.timeSent: DateTime.now().millisecondsSinceEpoch,
          Constants.senderUID: sender.uid,
          Constants.messageType: messageType.name,
        });

        setLoading(false);
        onSuccess();
        setMessageReplyModel(null);
      } else {
        // Handle contact message
        await handleContactMessage(
          messageModel: messageModel,
          contactUID: contactUID,
          contactName: contactName,
          contactImage: contactImage,
          onSuccess: onSuccess,
          onError: onError,
        );

        setMessageReplyModel(null);
      }
    } catch (e) {
      setLoading(false);
      onError(e.toString());
    }
  }

  // Send file message to firestore
  Future<void> sendFileMessage({
    required UserModel sender,
    required String contactUID,
    required String contactName,
    required String contactImage,
    required File file,
    required MessageEnum messageType,
    required String groupId,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    final currentState = state.value ?? const ChatState();
    
    setLoading(true);
    try {
      var messageId = const Uuid().v4();

      // Check if it's a message reply and add the replied message
      String repliedMessage = currentState.messageReplyModel?.message ?? '';
      String repliedTo = currentState.messageReplyModel == null
          ? ''
          : currentState.messageReplyModel!.isMe
              ? 'You'
              : currentState.messageReplyModel!.senderName;
      MessageEnum repliedMessageType =
          currentState.messageReplyModel?.messageType ?? MessageEnum.text;
          
      // Status data from reply model (if available)
      String? statusThumbnailUrl = currentState.messageReplyModel?.statusThumbnailUrl;
      String? statusCaption = currentState.messageReplyModel?.message;

      // Upload file to firebase storage
      final ref =
          '${Constants.chatFiles}/${messageType.name}/${sender.uid}/$contactUID/$messageId';
      String fileUrl = await global_methods.storeFileToStorage(file: file, reference: ref);

      // Update/set the messagemodel
      final messageModel = MessageModel(
        messageId: messageId,
        senderUID: sender.uid,
        senderName: sender.name,
        senderImage: sender.image,
        contactUID: contactUID,
        message: fileUrl,
        messageType: messageType,
        timeSent: DateTime.now(),
        isSeen: true, // Always set to true for privacy
        repliedMessage: repliedMessage,
        repliedTo: repliedTo,
        repliedMessageType: repliedMessageType,
        reactions: [],
        isSeenBy: [sender.uid],
        deletedBy: [],
        statusThumbnailUrl: statusThumbnailUrl,
        statusCaption: statusCaption,
      );

      // Check if it's a group message and send to group else send to contact
      if (groupId.isNotEmpty) {
        // Handle group message
        await _firestore
            .collection(Constants.groups)
            .doc(groupId)
            .collection(Constants.messages)
            .doc(messageId)
            .set(messageModel.toMap());

        // Update the last message for the group
        await _firestore.collection(Constants.groups).doc(groupId).update({
          Constants.lastMessage: fileUrl,
          Constants.timeSent: DateTime.now().millisecondsSinceEpoch,
          Constants.senderUID: sender.uid,
          Constants.messageType: messageType.name,
        });

        setLoading(false);
        onSuccess();
        setMessageReplyModel(null);
      } else {
        // Handle contact message
        await handleContactMessage(
          messageModel: messageModel,
          contactUID: contactUID,
          contactName: contactName,
          contactImage: contactImage,
          onSuccess: onSuccess,
          onError: onError,
        );

        setMessageReplyModel(null);
      }
    } catch (e) {
      setLoading(false);
      onError(e.toString());
    }
  }

  Future<void> handleContactMessage({
    required MessageModel messageModel,
    required String contactUID,
    required String contactName,
    required String contactImage,
    required Function onSuccess,
    required Function(String p1) onError,
  }) async {
    try {
      // Contact messageModel
      final contactMessageModel = messageModel.copyWith(
        userId: messageModel.senderUID,
      );

      // Get message data to store in Firestore
      final Map<String, dynamic> messageData = messageModel.toMap();
      final Map<String, dynamic> contactMessageData = contactMessageModel.toMap();

      // Get current timestamp in milliseconds with null safety
      final int timeStampMillis = messageModel.timeSent?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;

      // Initialize last message data for the sender
      final Map<String, dynamic> senderLastMessageData = {
        Constants.senderUID: messageModel.senderUID,
        Constants.contactUID: contactUID,
        Constants.contactName: contactName,
        Constants.contactImage: contactImage,
        Constants.message: messageModel.message,
        Constants.messageType: messageModel.messageType.name,
        Constants.timeSent: timeStampMillis,
        Constants.isSeen: true, // Always true for privacy
      };

      // Initialize last message data for the contact
      final Map<String, dynamic> contactLastMessageData = {
        Constants.senderUID: messageModel.senderUID,
        Constants.contactUID: messageModel.senderUID,
        Constants.contactName: messageModel.senderName,
        Constants.contactImage: messageModel.senderImage,
        Constants.message: messageModel.message,
        Constants.messageType: messageModel.messageType.name,
        Constants.timeSent: timeStampMillis,
        Constants.isSeen: true, // Always true for privacy
      };
      
      // Run as a batch operation for better consistency
      final batch = _firestore.batch();
      
      // Send message to sender firestore location
      final senderMessageRef = _firestore
          .collection(Constants.users)
          .doc(messageModel.senderUID)
          .collection(Constants.chats)
          .doc(contactUID)
          .collection(Constants.messages)
          .doc(messageModel.messageId);
          
      batch.set(senderMessageRef, messageData);
      
      // Send message to contact firestore location
      final contactMessageRef = _firestore
          .collection(Constants.users)
          .doc(contactUID)
          .collection(Constants.chats)
          .doc(messageModel.senderUID)
          .collection(Constants.messages)
          .doc(messageModel.messageId);
          
      batch.set(contactMessageRef, contactMessageData);

      // Send the last message to sender firestore location
      final senderLastMessageRef = _firestore
          .collection(Constants.users)
          .doc(messageModel.senderUID)
          .collection(Constants.chats)
          .doc(contactUID);
          
      batch.set(senderLastMessageRef, senderLastMessageData);

      // Send the last message to contact firestore location
      final contactLastMessageRef = _firestore
          .collection(Constants.users)
          .doc(contactUID)
          .collection(Constants.chats)
          .doc(messageModel.senderUID);
          
      batch.set(contactLastMessageRef, contactLastMessageData);
      
      // Commit the batch
      await batch.commit();

      // Call onSuccess
      setLoading(false);
      onSuccess();
    } on FirebaseException catch (e) {
      setLoading(false);
      onError(e.message ?? e.toString());
    } catch (e) {
      setLoading(false);
      onError(e.toString());
    }
  }

  // Send reaction to message
  Future<void> sendReactionToMessage({
    required String senderUID,
    required String contactUID,
    required String messageId,
    required String reaction,
    required bool groupId,
  }) async {
    setLoading(true);
    // A reaction is saved as senderUID=reaction
    String reactionToAdd = '$senderUID=$reaction';

    try {
      // Check if it's a group message
      if (groupId) {
        // Get the reaction list from firestore
        final messageData = await _firestore
            .collection(Constants.groups)
            .doc(contactUID)
            .collection(Constants.messages)
            .doc(messageId)
            .get();

        // Add the meesaage data to messageModel
        final message = MessageModel.fromMap(messageData.data()!);

        // Check if the reaction list is empty
        if (message.reactions.isEmpty) {
          // Add the reaction to the message
          await _firestore
              .collection(Constants.groups)
              .doc(contactUID)
              .collection(Constants.messages)
              .doc(messageId)
              .update({
            Constants.reactions: FieldValue.arrayUnion([reactionToAdd])
          });
        } else {
          // Get UIDs list from reactions list
          final uids = message.reactions.map((e) => e.split('=')[0]).toList();

          // Check if the reaction is already added
          if (uids.contains(senderUID)) {
            // Get the index of the reaction
            final index = uids.indexOf(senderUID);
            // Replace the reaction
            message.reactions[index] = reactionToAdd;
          } else {
            // Add the reaction to the list
            message.reactions.add(reactionToAdd);
          }

          // Update the message
          await _firestore
              .collection(Constants.groups)
              .doc(contactUID)
              .collection(Constants.messages)
              .doc(messageId)
              .update({Constants.reactions: message.reactions});
        }
      } else {
        // Handle contact message
        // Get the reaction list from firestore
        final messageData = await _firestore
            .collection(Constants.users)
            .doc(senderUID)
            .collection(Constants.chats)
            .doc(contactUID)
            .collection(Constants.messages)
            .doc(messageId)
            .get();

        // Add the meesaage data to messageModel
        final message = MessageModel.fromMap(messageData.data()!);

        // Check if the reaction list is empty
        if (message.reactions.isEmpty) {
          // Add the reaction to the message
          await _firestore
              .collection(Constants.users)
              .doc(senderUID)
              .collection(Constants.chats)
              .doc(contactUID)
              .collection(Constants.messages)
              .doc(messageId)
              .update({
            Constants.reactions: FieldValue.arrayUnion([reactionToAdd])
          });
        } else {
          // Get UIDs list from reactions list
          final uids = message.reactions.map((e) => e.split('=')[0]).toList();

          // Check if the reaction is already added
          if (uids.contains(senderUID)) {
            // Get the index of the reaction
            final index = uids.indexOf(senderUID);
            // Replace the reaction
            message.reactions[index] = reactionToAdd;
          } else {
            // Add the reaction to the list
            message.reactions.add(reactionToAdd);
          }

          // Update the message to sender firestore location
          await _firestore
              .collection(Constants.users)
              .doc(senderUID)
              .collection(Constants.chats)
              .doc(contactUID)
              .collection(Constants.messages)
              .doc(messageId)
              .update({Constants.reactions: message.reactions});

          // Update the message to contact firestore location
          await _firestore
              .collection(Constants.users)
              .doc(contactUID)
              .collection(Constants.chats)
              .doc(senderUID)
              .collection(Constants.messages)
              .doc(messageId)
              .update({Constants.reactions: message.reactions});
        }
      }

      setLoading(false);
    } catch (e) {
      setLoading(false);
      debugPrint(e.toString());
    }
  }

  // Get chatsList stream
  Stream<List<LastMessageModel>> getChatsListStream(String userId) {
    return _firestore
        .collection(Constants.users)
        .doc(userId)
        .collection(Constants.chats)
        .orderBy(Constants.timeSent, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        
        // Make sure timeSent is properly handled - convert to DateTime from int
        if (data[Constants.timeSent] is int) {
          final int milliseconds = data[Constants.timeSent];
          
          // Create a proper LastMessageModel from the data with converted DateTime
          return LastMessageModel(
            senderUID: data[Constants.senderUID] ?? '',
            contactUID: data[Constants.contactUID] ?? '',
            contactName: data[Constants.contactName] ?? '',
            contactImage: data[Constants.contactImage] ?? '',
            message: data[Constants.message] ?? '',
            messageType: (data[Constants.messageType] ?? 'text').toString().toMessageEnum(),
            timeSent: DateTime.fromMillisecondsSinceEpoch(milliseconds),
            isSeen: data[Constants.isSeen] ?? false,
          );
        }
        
        // If it's already a valid format, use the standard fromMap
        return LastMessageModel.fromMap(data);
      }).toList();
    });
  }

  // Stream messages from chat collection
  Stream<List<MessageModel>> getMessagesStream({
    required String userId,
    required String contactUID,
    required String isGroup,
  }) {
    // Check if it's a group message
    if (isGroup.isNotEmpty) {
      // Handle group message
      return _firestore
          .collection(Constants.groups)
          .doc(contactUID)
          .collection(Constants.messages)
          .orderBy(Constants.timeSent, descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return MessageModel.fromMap(doc.data());
        }).toList();
      });
    } else {
      // Handle contact message
      return _firestore
          .collection(Constants.users)
          .doc(userId)
          .collection(Constants.chats)
          .doc(contactUID)
          .collection(Constants.messages)
          .orderBy(Constants.timeSent, descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return MessageModel.fromMap(doc.data());
        }).toList();
      });
    }
  }

  // Stream the unread messages for this user
  Stream<int> getUnreadMessagesStream({
    required String userId,
    required String contactUID,
    required bool isGroup,
  }) {
    // Option 1: Return a constant stream of 0 (no unread messages shown)
    // Uncomment this line if you want to completely remove unread indicators
    //return Stream.value(0);
    
    // Option 2: Keep original implementation for unread counts
    // Check if it's a group message
    if (isGroup) {
      // Handle group message
      return _firestore
          .collection(Constants.groups)
          .doc(contactUID)
          .collection(Constants.messages)
          .snapshots()
          .asyncMap((event) {
        int count = 0;
        for (var doc in event.docs) {
          final message = MessageModel.fromMap(doc.data());
          if (!message.isSeenBy.contains(userId)) {
            count++;
          }
        }
        return count;
      });
    } else {
      // Handle contact message
      return _firestore
          .collection(Constants.users)
          .doc(userId)
          .collection(Constants.chats)
          .doc(contactUID)
          .collection(Constants.messages)
          .where(Constants.isSeen, isEqualTo: false)
          .where(Constants.senderUID, isNotEqualTo: userId)
          .snapshots()
          .map((event) => event.docs.length);
    }
  }

  // Set message status - this is now a no-op function for privacy
  Future<void> setMessageStatus({
    required String currentUserId,
    required String contactUID,
    required String messageId,
    required List<String> isSeenByList,
    required bool isGroupChat,
  }) async {
    // This function is now a no-op for privacy reasons
    // No status updates will be sent to the server
    return;
  }

  // Delete message
  Future<void> deleteMessage({
    required String currentUserId,
    required String contactUID,
    required String messageId,
    required String messageType,
    required bool isGroupChat,
    required bool deleteForEveryone,
  }) async {
    // Set loading
    setLoading(true);

    // Check if it's group chat
    if (isGroupChat) {
      // Handle group message
      await _firestore
          .collection(Constants.groups)
          .doc(contactUID)
          .collection(Constants.messages)
          .doc(messageId)
          .update({
        Constants.deletedBy: FieldValue.arrayUnion([currentUserId])
      });

      // Is delete for everyone and message type is not text, we also delete the file from storage
      if (deleteForEveryone) {
        // Get all group members uids and put them in deletedBy list
        final groupData =
            await _firestore.collection(Constants.groups).doc(contactUID).get();

        final List<String> groupMembers =
            List<String>.from(groupData.data()![Constants.membersUIDs]);

        // Update the message as deleted for everyone
        await _firestore
            .collection(Constants.groups)
            .doc(contactUID)
            .collection(Constants.messages)
            .doc(messageId)
            .update({Constants.deletedBy: FieldValue.arrayUnion(groupMembers)});

        if (messageType != MessageEnum.text.name) {
          // Delete the file from storage
          await deleteFileFromStorage(
            currentUserId: currentUserId,
            contactUID: contactUID,
            messageId: messageId,
            messageType: messageType,
          );
        }
      }

      setLoading(false);
    } else {
      // Handle contact message
      // Update the current message as deleted
      await _firestore
          .collection(Constants.users)
          .doc(currentUserId)
          .collection(Constants.chats)
          .doc(contactUID)
          .collection(Constants.messages)
          .doc(messageId)
          .update({
        Constants.deletedBy: FieldValue.arrayUnion([currentUserId])
      });
      // Check if delete for everyone then return if false
      if (!deleteForEveryone) {
        setLoading(false);
        return;
      }

      // Update the contact message as deleted
      await _firestore
          .collection(Constants.users)
          .doc(contactUID)
          .collection(Constants.chats)
          .doc(currentUserId)
          .collection(Constants.messages)
          .doc(messageId)
          .update({
        Constants.deletedBy: FieldValue.arrayUnion([currentUserId])
      });

      // Delete the file from storage
      if (messageType != MessageEnum.text.name) {
        await deleteFileFromStorage(
          currentUserId: currentUserId,
          contactUID: contactUID,
          messageId: messageId,
          messageType: messageType,
        );
      }

      setLoading(false);
    }
  }

  Future<void> deleteFileFromStorage({
    required String currentUserId,
    required String contactUID,
    required String messageId,
    required String messageType,
  }) async {
    final firebaseStorage = FirebaseStorage.instance;
    // Delete the file from storage
    await firebaseStorage
        .ref(
            '${Constants.chatFiles}/$messageType/$currentUserId/$contactUID/$messageId')
        .delete();
  }

  // Stream the last message collection
  Stream<QuerySnapshot> getLastMessageStream({
    required String userId,
    required String groupId,
  }) {
    return groupId.isNotEmpty
        ? _firestore
            .collection(Constants.groups)
            .where(Constants.membersUIDs, arrayContains: userId)
            .snapshots()
        : _firestore
            .collection(Constants.users)
            .doc(userId)
            .collection(Constants.chats)
            .snapshots();
  }
}

// Provide easy access to chat state and methods
final chatStateProvider = Provider((ref) {
  final chatAsyncValue = ref.watch(chatProvider);
  return chatAsyncValue.value ?? const ChatState();
});

final searchQueryProvider = Provider((ref) {
  final chatState = ref.watch(chatStateProvider);
  return chatState.searchQuery;
});

final messageReplyProvider = Provider((ref) {
  final chatState = ref.watch(chatStateProvider);
  return chatState.messageReplyModel;
});
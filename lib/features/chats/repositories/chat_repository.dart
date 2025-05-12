// lib/features/chat/repositories/chat_repository.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/chats/models/chat_message.dart';
import 'package:textgb/features/chats/models/chat_room.dart';
import 'package:uuid/uuid.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:path/path.dart' as path_util;
import 'package:http/http.dart' as http;

class ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ChatRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  // Create or get an existing chat room between two users
  Future<ChatRoom> createOrGetChatRoom({
    required UserModel currentUser,
    required UserModel otherUser,
  }) async {
    // Create a sorted list of participant UIDs to ensure consistent chat ID
    final List<String> participantsUIDs = [currentUser.uid, otherUser.uid]..sort();
    final String chatId = participantsUIDs.join('_');

    // Check if chat room already exists
    final chatDoc = await _firestore.collection(Constants.chats).doc(chatId).get();

    if (chatDoc.exists) {
      // Chat room exists, return it
      return ChatRoom.fromMap(chatDoc.data()!);
    } else {
      // Create a new chat room
      final Map<String, String> participantsInfo = {
        currentUser.uid: currentUser.name,
        otherUser.uid: otherUser.name,
      };

      final Map<String, String> participantsImages = {
        currentUser.uid: currentUser.image,
        otherUser.uid: otherUser.image,
      };

      final ChatRoom chatRoom = ChatRoom(
        chatId: chatId,
        participantsUIDs: participantsUIDs,
        participantsInfo: participantsInfo,
        participantsImages: participantsImages,
        chatSettings: {
          'isPinned': false,
          'isMuted': false,
          'isArchived': false,
          'wallpaper': null,
          'deletedBy': [],
          'isGroup': false,
        },
        createdAt: DateTime.now(),
        createdBy: currentUser.uid,
        unreadCount: {
          currentUser.uid: 0,
          otherUser.uid: 0,
        },
      );

      // Save to Firestore
      await _firestore.collection(Constants.chats).doc(chatId).set(chatRoom.toMap());

      return chatRoom;
    }
  
  // Get all pinned chats for a user
  Stream<List<ChatRoom>> getPinnedChats(String uid) {
    return _firestore
        .collection(Constants.chats)
        .where('participantsUIDs', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatRoom.fromMap(doc.data()))
          // Filter for pinned chats only
          .where((chatRoom) {
            final deletedBy = List<String>.from(chatRoom.chatSettings['deletedBy'] ?? []);
            final isPinned = chatRoom.chatSettings['isPinned'] as bool? ?? false;
            return isPinned && !deletedBy.contains(uid);
          })
          .toList();
    });
  }
  
  // Global search across all chats
  Future<Map<String, List<dynamic>>> globalSearch({
    required String uid,
    required String query,
  }) async {
    try {
      final result = {
        'messages': <ChatMessage>[],
        'chats': <ChatRoom>[],
      };
      
      if (query.isEmpty) {
        return result;
      }
      
      // Get all chat rooms for the user
      final chatRoomsSnapshot = await _firestore
          .collection(Constants.chats)
          .where('participantsUIDs', arrayContains: uid)
          .get();
      
      // Search in chat room names (participant names)
      final List<ChatRoom> matchingChatRooms = [];
      final List<String> chatIds = [];
      
      for (final doc in chatRoomsSnapshot.docs) {
        final chatRoom = ChatRoom.fromMap(doc.data());
        final deletedBy = List<String>.from(chatRoom.chatSettings['deletedBy'] ?? []);
        
        if (deletedBy.contains(uid)) {
          continue;
        }
        
        chatIds.add(chatRoom.chatId);
        
        // Search in participant names
        final participantNames = chatRoom.participantsInfo.values;
        final hasMatchingName = participantNames.any((name) => 
            name.toLowerCase().contains(query.toLowerCase()));
        
        if (hasMatchingName) {
          matchingChatRooms.add(chatRoom);
        }
      }
      
      result['chats'] = matchingChatRooms;
      
      // Search messages in all chats (this can be resource-intensive)
      // Limit search to recent chats if there are many
      final searchableChatIds = chatIds.length > 10
          ? chatIds.sublist(0, 10)
          : chatIds;
      
      final List<ChatMessage> matchingMessages = [];
      
      for (final chatId in searchableChatIds) {
        // Get messages from this chat
        final messagesQuery = await _firestore
            .collection(Constants.chats)
            .doc(chatId)
            .collection(Constants.messages)
            .where(Constants.messageType, isEqualTo: MessageEnum.text.name)
            .orderBy(Constants.timeSent, descending: true)
            .limit(100) // Limit the number of messages to search
            .get();
        
        // Filter messages that match the query
        final messages = messagesQuery.docs
            .map((doc) => ChatMessage.fromMap(doc.data()))
            .where((message) => 
                !message.deletedBy.contains(uid) &&
                message.message.toLowerCase().contains(query.toLowerCase()))
            .toList();
        
        matchingMessages.addAll(messages);
      }
      
      // Sort messages by time (newest first)
      matchingMessages.sort((a, b) => b.timeSent.compareTo(a.timeSent));
      
      // Limit the number of returned messages
      result['messages'] = matchingMessages.length > 20
          ? matchingMessages.sublist(0, 20)
          : matchingMessages;
      
      return result;
    } catch (e) {
      debugPrint('Error performing global search: $e');
      return {
        'messages': <ChatMessage>[],
        'chats': <ChatRoom>[],
      };
    }
  }
  
  // Get chat statistics (message counts by type, etc.)
  Future<Map<String, dynamic>> getChatStatistics({
    required String chatId,
  }) async {
    try {
      final result = {
        'totalMessages': 0,
        'messageTypes': <String, int>{},
        'mediaCount': 0,
        'firstMessageTime': null,
        'mostActiveDay': null,
        'topReactions': <String, int>{},
      };
      
      // Get all messages
      final messagesSnapshot = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .get();
      
      if (messagesSnapshot.docs.isEmpty) {
        return result;
      }
      
      result['totalMessages'] = messagesSnapshot.docs.length;
      
      DateTime? firstMessageTime;
      final Map<String, int> messageTypes = {};
      final Map<String, int> reactionsCount = {};
      final Map<String, int> messagesByDay = {};
      
      for (final doc in messagesSnapshot.docs) {
        final message = ChatMessage.fromMap(doc.data());
        
        // Count by message type
        final messageType = message.messageType.name;
        messageTypes[messageType] = (messageTypes[messageType] ?? 0) + 1;
        
        // Count media messages
        if (message.messageType != MessageEnum.text) {
          result['mediaCount'] = (result['mediaCount'] as int) + 1;
        }
        
        // Track first message time
        if (firstMessageTime == null || message.timeSent.isBefore(firstMessageTime)) {
          firstMessageTime = message.timeSent;
        }
        
        // Count messages by day
        final day = DateTime(
          message.timeSent.year,
          message.timeSent.month,
          message.timeSent.day,
        ).toString().split(' ')[0]; // Format: YYYY-MM-DD
        
        messagesByDay[day] = (messagesByDay[day] ?? 0) + 1;
        
        // Count reactions
        for (final reaction in message.reactions.values) {
          reactionsCount[reaction] = (reactionsCount[reaction] ?? 0) + 1;
        }
      }
      
      result['messageTypes'] = messageTypes;
      result['firstMessageTime'] = firstMessageTime?.millisecondsSinceEpoch;
      
      // Find most active day
      String? mostActiveDay;
      int maxCount = 0;
      
      messagesByDay.forEach((day, count) {
        if (count > maxCount) {
          maxCount = count;
          mostActiveDay = day;
        }
      });
      
      result['mostActiveDay'] = mostActiveDay;
      
      // Sort reactions by count and get top 5
      final sortedReactions = reactionsCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final topReactions = <String, int>{};
      for (var i = 0; i < sortedReactions.length && i < 5; i++) {
        topReactions[sortedReactions[i].key] = sortedReactions[i].value;
      }
      
      result['topReactions'] = topReactions;
      
      return result;
    } catch (e) {
      debugPrint('Error getting chat statistics: $e');
      return {
        'totalMessages': 0,
        'messageTypes': <String, int>{},
        'mediaCount': 0,
      };
    }
  }
  
  // Export chat history (for backup)
  Future<String> exportChatHistory({
    required String chatId,
    required String uid,
  }) async {
    try {
      // Get chat room info
      final chatDoc = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .get();
      
      if (!chatDoc.exists) {
        throw Exception('Chat room not found');
      }
      
      final chatRoom = ChatRoom.fromMap(chatDoc.data()!);
      
      // Get all messages
      final messagesSnapshot = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .orderBy(Constants.timeSent, descending: false) // Oldest first
          .get();
      
      final messages = messagesSnapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data()))
          .where((message) => !message.deletedBy.contains(uid))
          .toList();
      
      // Create export data
      final exportData = {
        'chatInfo': {
          'chatId': chatRoom.chatId,
          'participants': chatRoom.participantsInfo,
          'createdAt': chatRoom.createdAt.toIso8601String(),
        },
        'messages': messages.map((message) => {
          'senderName': message.senderName,
          'message': message.message,
          'messageType': message.messageType.name,
          'timeSent': message.timeSent.toIso8601String(),
          'mediaMetadata': message.mediaMetadata,
        }).toList(),
      };
      
      // Convert to JSON
      final jsonString = exportData.toString();
      
      // In a real app, you would:
      // 1. Create a file with this JSON data
      // 2. Allow the user to download/share it
      
      return jsonString;
    } catch (e) {
      debugPrint('Error exporting chat history: $e');
      rethrow;
    }
  }
  
  // Check if a user is blocked by another user
  Future<bool> isUserBlocked({
    required String currentUserUID,
    required String otherUserUID,
  }) async {
    try {
      // Check if current user is in otherUser's blockedUIDs
      final otherUserDoc = await _firestore
          .collection(Constants.users)
          .doc(otherUserUID)
          .get();
      
      if (!otherUserDoc.exists) {
        return false;
      }
      
      final otherUserData = otherUserDoc.data()!;
      final blockedUIDs = List<String>.from(otherUserData[Constants.blockedUIDs] ?? []);
      
      return blockedUIDs.contains(currentUserUID);
    } catch (e) {
      debugPrint('Error checking if user is blocked: $e');
      return false;
    }
  }
  
  // Get chat media (images, videos)
  Future<List<ChatMessage>> getChatMedia({
    required String chatId,
    required String uid,
  }) async {
    try {
      // Get messages of type image or video
      final mediaSnapshot = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .where(Constants.messageType, whereIn: [
            MessageEnum.image.name,
            MessageEnum.video.name,
          ])
          .orderBy(Constants.timeSent, descending: true)
          .get();
      
      return mediaSnapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data()))
          .where((message) => !message.deletedBy.contains(uid))
          .toList();
    } catch (e) {
      debugPrint('Error getting chat media: $e');
      return [];
    }
  }
  
  // Get chat documents (files)
  Future<List<ChatMessage>> getChatDocuments({
    required String chatId,
    required String uid,
  }) async {
    try {
      // Get messages of type file
      final docsSnapshot = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .where(Constants.messageType, isEqualTo: MessageEnum.file.name)
          .orderBy(Constants.timeSent, descending: true)
          .get();
      
      return docsSnapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data()))
          .where((message) => !message.deletedBy.contains(uid))
          .toList();
    } catch (e) {
      debugPrint('Error getting chat documents: $e');
      return [];
    }
  }
  
  // Get chat links
  Future<List<ChatMessage>> getChatLinks({
    required String chatId,
    required String uid,
  }) async {
    try {
      // Get text messages that contain URLs
      final messagesSnapshot = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .where(Constants.messageType, isEqualTo: MessageEnum.text.name)
          .orderBy(Constants.timeSent, descending: true)
          .get();
      
      // Use a regex to find messages containing URLs
      final urlRegex = RegExp(
        r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
        caseSensitive: false,
      );
      
      return messagesSnapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data()))
          .where((message) => 
              !message.deletedBy.contains(uid) &&
              urlRegex.hasMatch(message.message))
          .toList();
    } catch (e) {
      debugPrint('Error getting chat links: $e');
      return [];
    }
  }
  
  // Pin a chat
  Future<void> pinChat({
    required String chatId,
    required bool isPinned,
  }) async {
    try {
      // Get current chat settings
      final chatDoc = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .get();
      
      if (chatDoc.exists) {
        final chatData = chatDoc.data()!;
        final chatSettings = Map<String, dynamic>.from(chatData['chatSettings'] ?? {});
        
        // Update isPinned flag
        chatSettings['isPinned'] = isPinned;
        
        // Update chat settings
        await _firestore
            .collection(Constants.chats)
            .doc(chatId)
            .update({
          'chatSettings': chatSettings,
        });
      }
    } catch (e) {
      debugPrint('Error pinning/unpinning chat: $e');
      rethrow;
    }
  }
  
  // Mute/unmute chat notifications
  Future<void> muteChatNotifications({
    required String chatId,
    required bool isMuted,
  }) async {
    try {
      // Get current chat settings
      final chatDoc = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .get();
      
      if (chatDoc.exists) {
        final chatData = chatDoc.data()!;
        final chatSettings = Map<String, dynamic>.from(chatData['chatSettings'] ?? {});
        
        // Update isMuted flag
        chatSettings['isMuted'] = isMuted;
        
        // Update chat settings
        await _firestore
            .collection(Constants.chats)
            .doc(chatId)
            .update({
          'chatSettings': chatSettings,
        });
      }
    } catch (e) {
      debugPrint('Error muting/unmuting chat: $e');
      rethrow;
    }
  }
  
  // Archive/unarchive a chat
  Future<void> archiveChat({
    required String chatId,
    required bool isArchived,
  }) async {
    try {
      // Get current chat settings
      final chatDoc = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .get();
      
      if (chatDoc.exists) {
        final chatData = chatDoc.data()!;
        final chatSettings = Map<String, dynamic>.from(chatData['chatSettings'] ?? {});
        
        // Update isArchived flag
        chatSettings['isArchived'] = isArchived;
        
        // Update chat settings
        await _firestore
            .collection(Constants.chats)
            .doc(chatId)
            .update({
          'chatSettings': chatSettings,
        });
      }
    } catch (e) {
      debugPrint('Error archiving/unarchiving chat: $e');
      rethrow;
    }
  }
  
  // Get chat message by ID
  Future<ChatMessage?> getChatMessageById({
    required String chatId,
    required String messageId,
  }) async {
    try {
      final messageDoc = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .get();
      
      if (messageDoc.exists) {
        return ChatMessage.fromMap(messageDoc.data()!);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting chat message: $e');
      return null;
    }
  }
  
  // Check if a chat exists between two users
  Future<bool> doesChatExistBetweenUsers({
    required String user1UID,
    required String user2UID,
  }) async {
    try {
      // Create a sorted list of UIDs for consistent chat ID
      final List<String> participantsUIDs = [user1UID, user2UID]..sort();
      final String chatId = participantsUIDs.join('_');
      
      final chatDoc = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .get();
      
      return chatDoc.exists;
    } catch (e) {
      debugPrint('Error checking if chat exists: $e');
      return false;
    }
  }
  
  // Get last active time for a user
  Future<DateTime?> getUserLastActive({
    required String uid,
  }) async {
    try {
      final userDoc = await _firestore
          .collection(Constants.users)
          .doc(uid)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final lastSeen = userData[Constants.lastSeen];
        
        if (lastSeen != null) {
          // Convert to DateTime
          if (lastSeen is int) {
            return DateTime.fromMillisecondsSinceEpoch(lastSeen);
          } else if (lastSeen is String) {
            return DateTime.fromMillisecondsSinceEpoch(int.parse(lastSeen));
          }
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting user last active time: $e');
      return null;
    }
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  );
});}

  // Send text message
  Future<void> sendTextMessage({
    required String chatId,
    required UserModel sender,
    required String receiverUID,
    required String message,
    String? repliedTo,
    String? repliedMessage,
    MessageEnum? repliedMessageType,
  }) async {
    try {
      final String messageId = const Uuid().v4();
      final DateTime timeSent = DateTime.now();

      final ChatMessage chatMessage = ChatMessage(
        messageId: messageId,
        senderUID: sender.uid,
        senderName: sender.name,
        senderImage: sender.image,
        message: message,
        messageType: MessageEnum.text,
        timeSent: timeSent,
        isSeen: false,
        isSeenBy: [sender.uid],
        deletedBy: [],
        reactions: {},
        repliedTo: repliedTo,
        repliedMessage: repliedMessage,
        repliedMessageType: repliedMessageType,
      );

      // Save message to Firestore
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .set(chatMessage.toMap());

      // Update last message in chat room
      await _firestore.collection(Constants.chats).doc(chatId).update({
        'lastMessage': chatMessage.toMap(),
        'unreadCount.$receiverUID': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error sending text message: $e');
      rethrow;
    }
  }

  // Send media message (image, video, audio, file)
  Future<void> sendMediaMessage({
    required String chatId,
    required UserModel sender,
    required String receiverUID,
    required File file,
    required MessageEnum messageType,
    required String caption,
    String? repliedTo,
    String? repliedMessage,
    MessageEnum? repliedMessageType,
  }) async {
    try {
      final String messageId = const Uuid().v4();
      final DateTime timeSent = DateTime.now();

      // Prepare storage reference path based on message type
      String storagePath;
      Map<String, dynamic> mediaMetadata = {};

      // Get file size and add to metadata
      final fileSize = await file.length();
      mediaMetadata['size'] = fileSize;
      mediaMetadata['sizeFormatted'] = formatFileSize(fileSize);
      
      // Get file name
      final fileName = path_util.basename(file.path);
      mediaMetadata['fileName'] = fileName;

      switch (messageType) {
        case MessageEnum.image:
          storagePath = '${Constants.chatFiles}/$chatId/images/$messageId';
          break;
        case MessageEnum.video:
          storagePath = '${Constants.chatFiles}/$chatId/videos/$messageId';
          // Add duration metadata for videos (would need actual implementation)
          mediaMetadata['duration'] = '00:30'; // Placeholder
          break;
        case MessageEnum.audio:
          storagePath = '${Constants.chatFiles}/$chatId/audio/$messageId';
          // Add duration metadata for audio (would need actual implementation)
          mediaMetadata['duration'] = '00:15'; // Placeholder
          break;
        case MessageEnum.file:
          storagePath = '${Constants.chatFiles}/$chatId/files/$messageId';
          // Add file extension to metadata
          mediaMetadata['fileExt'] = path_util.extension(file.path);
          break;
        default:
          storagePath = '${Constants.chatFiles}/$chatId/files/$messageId';
          break;
      }

      // Upload file to Firebase Storage
      final String fileUrl = await storeFileToStorage(
        file: file,
        reference: storagePath,
      );

      // For videos, generate thumbnail and upload it
      if (messageType == MessageEnum.video) {
        // This would be implemented with a video thumbnail generation library
        // For now, we'll just use a placeholder
        mediaMetadata['thumbnail'] = '';
        
        // In a real implementation, you would generate and upload a thumbnail:
        /*
        final thumbnailFile = await VideoThumbnail.thumbnailFile(
          video: file.path,
          imageFormat: ImageFormat.JPEG,
          quality: 75,
        );
        
        if (thumbnailFile != null) {
          final thumbnailUrl = await storeFileToStorage(
            file: File(thumbnailFile),
            reference: '${Constants.chatFiles}/$chatId/thumbnails/$messageId',
          );
          
          mediaMetadata['thumbnail'] = thumbnailUrl;
        }
        */
      }

      // Create chat message
      final ChatMessage chatMessage = ChatMessage(
        messageId: messageId,
        senderUID: sender.uid,
        senderName: sender.name,
        senderImage: sender.image,
        message: fileUrl,
        messageType: messageType,
        timeSent: timeSent,
        isSeen: false,
        isSeenBy: [sender.uid],
        deletedBy: [],
        reactions: {},
        repliedTo: repliedTo,
        repliedMessage: repliedMessage,
        repliedMessageType: repliedMessageType,
        mediaMetadata: {
          'caption': caption,
          ...mediaMetadata,
        },
      );

      // Save message to Firestore
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .set(chatMessage.toMap());

      // Update last message in chat room
      await _firestore.collection(Constants.chats).doc(chatId).update({
        'lastMessage': chatMessage.toMap(),
        'unreadCount.$receiverUID': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error sending media message: $e');
      rethrow;
    }
  }
  
  // Send location message
  Future<void> sendLocationMessage({
    required String chatId,
    required UserModel sender,
    required String receiverUID,
    required double latitude,
    required double longitude,
    required String locationName,
    String? repliedTo,
    String? repliedMessage,
    MessageEnum? repliedMessageType,
  }) async {
    try {
      final String messageId = const Uuid().v4();
      final DateTime timeSent = DateTime.now();
      
      // Location data to be sent
      final Map<String, dynamic> locationData = {
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName,
      };
      
      // Convert location data to JSON string
      final String locationDataString = locationData.toString();

      final ChatMessage chatMessage = ChatMessage(
        messageId: messageId,
        senderUID: sender.uid,
        senderName: sender.name,
        senderImage: sender.image,
        message: locationDataString,
        messageType: MessageEnum.location,
        timeSent: timeSent,
        isSeen: false,
        isSeenBy: [sender.uid],
        deletedBy: [],
        reactions: {},
        repliedTo: repliedTo,
        repliedMessage: repliedMessage,
        repliedMessageType: repliedMessageType,
        mediaMetadata: locationData,
      );

      // Save message to Firestore
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .set(chatMessage.toMap());

      // Update last message in chat room
      await _firestore.collection(Constants.chats).doc(chatId).update({
        'lastMessage': chatMessage.toMap(),
        'unreadCount.$receiverUID': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error sending location message: $e');
      rethrow;
    }
  }
  
  // Send contact message
  Future<void> sendContactMessage({
    required String chatId,
    required UserModel sender,
    required String receiverUID,
    required Map<String, dynamic> contactInfo,
    String? repliedTo,
    String? repliedMessage,
    MessageEnum? repliedMessageType,
  }) async {
    try {
      final String messageId = const Uuid().v4();
      final DateTime timeSent = DateTime.now();
      
      // Convert contact data to string for message field
      final String contactDataString = contactInfo.toString();

      final ChatMessage chatMessage = ChatMessage(
        messageId: messageId,
        senderUID: sender.uid,
        senderName: sender.name,
        senderImage: sender.image,
        message: contactDataString,
        messageType: MessageEnum.contact,
        timeSent: timeSent,
        isSeen: false,
        isSeenBy: [sender.uid],
        deletedBy: [],
        reactions: {},
        repliedTo: repliedTo,
        repliedMessage: repliedMessage,
        repliedMessageType: repliedMessageType,
        mediaMetadata: contactInfo,
      );

      // Save message to Firestore
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .set(chatMessage.toMap());

      // Update last message in chat room
      await _firestore.collection(Constants.chats).doc(chatId).update({
        'lastMessage': chatMessage.toMap(),
        'unreadCount.$receiverUID': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error sending contact message: $e');
      rethrow;
    }
  }

  // Mark message as seen
  Future<void> markMessageAsSeen({
    required String chatId,
    required String messageId,
    required String uid,
  }) async {
    try {
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .update({
        Constants.isSeen: true,
        Constants.isSeenBy: FieldValue.arrayUnion([uid]),
      });
    } catch (e) {
      debugPrint('Error marking message as seen: $e');
      rethrow;
    }
  }

  // Mark all messages in a chat as read
  Future<void> markAllMessagesAsRead({
    required String chatId,
    required String uid,
  }) async {
    try {
      // Get all unread messages
      final unreadMessages = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .where(Constants.isSeen, isEqualTo: false)
          .get();

      // Batch update all messages
      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          Constants.isSeen: true,
          Constants.isSeenBy: FieldValue.arrayUnion([uid]),
        });
      }

      // Reset unread count for the current user
      batch.update(_firestore.collection(Constants.chats).doc(chatId), {
        'unreadCount.$uid': 0,
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all messages as read: $e');
      rethrow;
    }
  }

  // Add reaction to message
  Future<void> addReaction({
    required String chatId,
    required String messageId,
    required String uid,
    required String reaction,
  }) async {
    try {
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .update({
        '${Constants.reactions}.$uid': reaction,
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
    required String uid,
  }) async {
    try {
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .update({
        '${Constants.reactions}.$uid': FieldValue.delete(),
      });
    } catch (e) {
      debugPrint('Error removing reaction: $e');
      rethrow;
    }
  }

  // Delete message (for current user only)
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
    required String uid,
  }) async {
    try {
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .update({
        Constants.deletedBy: FieldValue.arrayUnion([uid]),
      });
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }
  
  // Star a message (add to starred messages)
  Future<void> starMessage({
    required String chatId,
    required String messageId,
    required String uid,
  }) async {
    try {
      // Add message reference to user's starred messages collection
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('starredMessages')
          .doc(messageId)
          .set({
        'chatId': chatId,
        'messageId': messageId,
        'starredAt': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Update message in chat to mark it as starred
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .update({
        'starredBy': FieldValue.arrayUnion([uid]),
      });
    } catch (e) {
      debugPrint('Error starring message: $e');
      rethrow;
    }
  }
  
  // Unstar a message (remove from starred messages)
  Future<void> unstarMessage({
    required String chatId,
    required String messageId,
    required String uid,
  }) async {
    try {
      // Remove message reference from user's starred messages collection
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('starredMessages')
          .doc(messageId)
          .delete();
      
      // Update message in chat to unmark it as starred
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageId)
          .update({
        'starredBy': FieldValue.arrayRemove([uid]),
      });
    } catch (e) {
      debugPrint('Error unstarring message: $e');
      rethrow;
    }
  }
  
  // Get starred messages for a user
  Future<List<Map<String, dynamic>>> getStarredMessages({
    required String uid,
  }) async {
    try {
      final starredMessagesSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('starredMessages')
          .orderBy('starredAt', descending: true)
          .get();
      
      List<Map<String, dynamic>> starredMessages = [];
      
      for (final doc in starredMessagesSnapshot.docs) {
        final data = doc.data();
        final chatId = data['chatId'];
        final messageId = data['messageId'];
        
        // Get message details
        final messageDoc = await _firestore
            .collection(Constants.chats)
            .doc(chatId)
            .collection(Constants.messages)
            .doc(messageId)
            .get();
        
        if (messageDoc.exists) {
          // Get chat details
          final chatDoc = await _firestore
              .collection(Constants.chats)
              .doc(chatId)
              .get();
          
          starredMessages.add({
            'message': messageDoc.data(),
            'chat': chatDoc.data(),
            'starredAt': data['starredAt'],
          });
        }
      }
      
      return starredMessages;
    } catch (e) {
      debugPrint('Error getting starred messages: $e');
      rethrow;
    }
  }
  
  // Update chat room settings
  Future<void> updateChatRoomSettings({
    required String chatId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .update({
        'chatSettings': settings,
      });
    } catch (e) {
      debugPrint('Error updating chat settings: $e');
      rethrow;
    }
  }
  
  // Mark chat as deleted for a user
  Future<void> markChatAsDeleted({
    required String chatId,
    required String uid,
  }) async {
    try {
      // Get current chat room
      final chatDoc = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .get();
      
      if (chatDoc.exists) {
        final chatData = chatDoc.data()!;
        final chatSettings = Map<String, dynamic>.from(chatData['chatSettings'] ?? {});
        
        // Add user to deletedBy list in settings
        final List<String> deletedBy = List<String>.from(chatSettings['deletedBy'] ?? []);
        if (!deletedBy.contains(uid)) {
          deletedBy.add(uid);
        }
        
        chatSettings['deletedBy'] = deletedBy;
        
        // Update chat settings
        await _firestore
            .collection(Constants.chats)
            .doc(chatId)
            .update({
          'chatSettings': chatSettings,
        });
      }
    } catch (e) {
      debugPrint('Error marking chat as deleted: $e');
      rethrow;
    }
  }
  
  // Clear chat history (delete all messages for a user)
  Future<void> clearChatHistory({
    required String chatId,
    required String uid,
  }) async {
    try {
      // Get all messages in the chat
      final messagesSnapshot = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .get();
      
      // Batch update to mark all messages as deleted for this user
      final batch = _firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {
          Constants.deletedBy: FieldValue.arrayUnion([uid]),
        });
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing chat history: $e');
      rethrow;
    }
  }

  // Get chat room by ID
  Stream<ChatRoom> getChatRoomById(String chatId) {
    return _firestore
        .collection(Constants.chats)
        .doc(chatId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return ChatRoom.fromMap(doc.data()!);
      } else {
        throw Exception('Chat room not found');
      }
    });
  }

  // Get chat messages
  Stream<List<ChatMessage>> getChatMessages(String chatId) {
    return _firestore
        .collection(Constants.chats)
        .doc(chatId)
        .collection(Constants.messages)
        .orderBy(Constants.timeSent, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatMessage.fromMap(doc.data());
      }).toList();
    });
  }

  // Get all chat rooms for a user
  Stream<List<ChatRoom>> getUserChatRooms(String uid) {
    return _firestore
        .collection(Constants.chats)
        .where('participantsUIDs', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatRoom.fromMap(doc.data()))
          // Filter out chats that were deleted by this user
          .where((chatRoom) {
            final deletedBy = List<String>.from(chatRoom.chatSettings['deletedBy'] ?? []);
            return !deletedBy.contains(uid);
          })
          .toList();
    });
  }
  
  // Get archived chat rooms for a user
  Stream<List<ChatRoom>> getArchivedChatRooms(String uid) {
    return _firestore
        .collection(Constants.chats)
        .where('participantsUIDs', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatRoom.fromMap(doc.data()))
          // Filter for archived chats only
          .where((chatRoom) {
            final deletedBy = List<String>.from(chatRoom.chatSettings['deletedBy'] ?? []);
            final isArchived = chatRoom.chatSettings['isArchived'] as bool? ?? false;
            return isArchived && !deletedBy.contains(uid);
          })
          .toList();
    });
  }
  
  // Search chat messages by text
  Future<List<ChatMessage>> searchChatMessages({
    required String chatId,
    required String query,
  }) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a simple implementation that uses contains() which is inefficient
      // For a full-featured search, you would typically use a service like Algolia
      
      final messagesSnapshot = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .where(Constants.messageType, isEqualTo: MessageEnum.text.name)
          .orderBy(Constants.timeSent, descending: true)
          .get();
      
      final messages = messagesSnapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data()))
          .where((message) => 
              message.message.toLowerCase().contains(query.toLowerCase()))
          .toList();
      
      return messages;
    } catch (e) {
      debugPrint('Error searching chat messages: $e');
      rethrow;
    }
  }
  
  // Get unread messages count
  Future<int> getUnreadMessagesCount(String uid) async {
    try {
      final chatRoomsSnapshot = await _firestore
          .collection(Constants.chats)
          .where('participantsUIDs', arrayContains: uid)
          .get();
      
      int totalUnread = 0;
      
      for (final doc in chatRoomsSnapshot.docs) {
        final chatData = doc.data();
        
        // Skip deleted chats
        final chatSettings = Map<String, dynamic>.from(chatData['chatSettings'] ?? {});
        final deletedBy = List<String>.from(chatSettings['deletedBy'] ?? []);
        if (deletedBy.contains(uid)) {
          continue;
        }
        
        final unreadCount = chatData['unreadCount'] as Map<String, dynamic>?;
        
        if (unreadCount != null && unreadCount.containsKey(uid)) {
          totalUnread += (unreadCount[uid] as int?) ?? 0;
        }
      }
      
      return totalUnread;
    } catch (e) {
      debugPrint('Error getting unread messages count: $e');
      return 0;
    }
  }
  
  // Update user typing status
  Future<void> updateTypingStatus({
    required String chatId,
    required String uid,
    required bool isTyping,
  }) async {
    try {
      await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .update({
        'typingUsers.$uid': isTyping,
      });
    } catch (e) {
      debugPrint('Error updating typing status: $e');
    }
  }
  
  // Get users typing in a chat
  Stream<Map<String, bool>> getTypingUsers(String chatId) {
    return _firestore
        .collection(Constants.chats)
        .doc(chatId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return {};
      
      final data = doc.data();
      final typingUsers = data?['typingUsers'] as Map<String, dynamic>?;
      
      if (typingUsers == null) return {};
      
      return typingUsers.map((key, value) => MapEntry(key, value as bool));
    });
  }
  
  // Forward a message to another chat
  Future<void> forwardMessage({
    required String sourceChatId,
    required String sourceMessageId,
    required String targetChatId,
    required UserModel sender,
    required String receiverUID,
  }) async {
    try {
      // Get the source message
      final messageDoc = await _firestore
          .collection(Constants.chats)
          .doc(sourceChatId)
          .collection(Constants.messages)
          .doc(sourceMessageId)
          .get();
      
      if (!messageDoc.exists) {
        throw Exception('Source message not found');
      }
      
      // Create a new message ID
      final String newMessageId = const Uuid().v4();
      final DateTime timeSent = DateTime.now();
      
      // Create a new message based on the source message
      final sourceMessage = ChatMessage.fromMap(messageDoc.data()!);
      
      final ChatMessage forwardedMessage = ChatMessage(
        messageId: newMessageId,
        senderUID: sender.uid,
        senderName: sender.name,
        senderImage: sender.image,
        message: sourceMessage.message,
        messageType: sourceMessage.messageType,
        timeSent: timeSent,
        isSeen: false,
        isSeenBy: [sender.uid],
        deletedBy: [],
        reactions: {},
        mediaMetadata: sourceMessage.mediaMetadata != null 
            ? {...sourceMessage.mediaMetadata!, 'forwarded': true}
            : {'forwarded': true},
      );
      
      // Save forwarded message to target chat
      await _firestore
          .collection(Constants.chats)
          .doc(targetChatId)
          .collection(Constants.messages)
          .doc(newMessageId)
          .set(forwardedMessage.toMap());
      
      // Update last message in target chat
      await _firestore
          .collection(Constants.chats)
          .doc(targetChatId)
          .update({
        'lastMessage': forwardedMessage.toMap(),
        'unreadCount.$receiverUID': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error forwarding message: $e');
      rethrow;
    }
  }
  
  // Update chat wallpaper
  Future<void> updateChatWallpaper({
    required String chatId,
    required String uid,
    required File wallpaperFile,
  }) async {
    try {
      // Upload wallpaper to storage
      final wallpaperUrl = await storeFileToStorage(
        file: wallpaperFile,
        reference: 'chat_wallpapers/$chatId/$uid',
      );
      
      // Get current chat settings
      final chatDoc = await _firestore
          .collection(Constants.chats)
          .doc(chatId)
          .get();
      
      if (chatDoc.exists) {
        final chatData = chatDoc.data()!;
        final chatSettings = Map<String, dynamic>.from(chatData['chatSettings'] ?? {});
        
        // Update wallpaper URL
        chatSettings['wallpaper'] = wallpaperUrl;
        
        // Update chat settings
        await _firestore
            .collection(Constants.chats)
            .doc(chatId)
            .update({
          'chatSettings': chatSettings,
        });
      }
    } catch (e) {
      debugPrint('Error updating chat wallpaper: $e');
      rethrow;
    }
  }
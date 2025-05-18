// lib/features/chat/models/chat_model.dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';

class ChatModel {
  final String id;
  final String contactUID;
  final String contactName;
  final String contactImage;
  final String lastMessage;
  final MessageEnum lastMessageType;
  final String lastMessageTime;
  final String lastMessageSender; // Added to track who sent the last message
  final int unreadCount;
  final bool isGroup;
  final String? groupId;
  final Map<String, int> unreadCountByUser; // Per-user unread counts

  ChatModel({
    required this.id,
    required this.contactUID,
    required this.contactName,
    required this.contactImage,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastMessageTime,
    required this.unreadCount,
    this.lastMessageSender = '',
    this.isGroup = false,
    this.groupId,
    Map<String, int>? unreadCountByUser,
  }) : this.unreadCountByUser = unreadCountByUser ?? {};

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    // Calculate unread count
    int unreadCount = 0;
    
    // Create unreadCountByUser map
    Map<String, int> unreadCountByUser = {};
    
    // First check if we have the new unreadCountByUser format
    if (map.containsKey('unreadCountByUser')) {
      try {
        final rawUnreadCounts = map['unreadCountByUser'];
        if (rawUnreadCounts is Map<String, dynamic>) {
          // Already a map, use directly
          unreadCountByUser = Map<String, int>.from(
            rawUnreadCounts.map((key, value) => MapEntry(key, value as int))
          );
        } else if (rawUnreadCounts is String) {
          // JSON string, need to decode
          final decoded = jsonDecode(rawUnreadCounts);
          if (decoded is Map) {
            unreadCountByUser = Map<String, int>.from(
              decoded.map((key, value) => MapEntry(key, value as int))
            );
          }
        }
        
        // Get unread count for current user if available
        if (currentUser != null && unreadCountByUser.containsKey(currentUser.uid)) {
          unreadCount = unreadCountByUser[currentUser.uid] ?? 0;
        }
      } catch (e) {
        // If parsing fails, fall back to default unreadCount
        print('Error parsing unreadCountByUser: $e');
      }
    }
    
    // Fall back to the old unreadCount field if needed
    if (unreadCount == 0 && map.containsKey('unreadCount')) {
      unreadCount = map['unreadCount'] as int? ?? 0;
    }
    
    // For a more reliable determination of whether the current user should show 
    // unread messages, check if the last message was sent by someone else
    final String lastMessageSender = map['lastMessageSender'] as String? ?? '';
    if (currentUser != null && lastMessageSender != currentUser.uid) {
      // If the user's own unread count wasn't correctly set, we can estimate it
      // based on the unreadCount field if lastMessageSender isn't the current user
      if (unreadCount == 0 && map.containsKey('unreadCount')) {
        unreadCount = map['unreadCount'] as int? ?? 0;
      }
    } else if (currentUser != null && lastMessageSender == currentUser.uid) {
      // If current user is the last message sender, they should have 0 unread messages
      unreadCount = 0;
    }
    
    return ChatModel(
      id: map['id'] ?? '',
      contactUID: map[Constants.contactUID] ?? '',
      contactName: map[Constants.contactName] ?? '',
      contactImage: map[Constants.contactImage] ?? '',
      lastMessage: map[Constants.lastMessage] ?? '',
      lastMessageType: (map[Constants.messageType] as String? ?? 'text').toMessageEnum(),
      lastMessageTime: map[Constants.timeSent] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      lastMessageSender: lastMessageSender,
      unreadCount: unreadCount,
      isGroup: map['isGroup'] ?? false,
      groupId: map[Constants.groupId],
      unreadCountByUser: unreadCountByUser,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      Constants.contactUID: contactUID,
      Constants.contactName: contactName,
      Constants.contactImage: contactImage,
      Constants.lastMessage: lastMessage,
      Constants.messageType: lastMessageType.name,
      Constants.timeSent: lastMessageTime,
      'lastMessageSender': lastMessageSender,
      'unreadCount': unreadCount,
      'isGroup': isGroup,
      Constants.groupId: groupId,
      'unreadCountByUser': unreadCountByUser,
    };
  }

  ChatModel copyWith({
    String? id,
    String? contactUID,
    String? contactName,
    String? contactImage,
    String? lastMessage,
    MessageEnum? lastMessageType,
    String? lastMessageTime,
    String? lastMessageSender,
    int? unreadCount,
    bool? isGroup,
    String? groupId,
    Map<String, int>? unreadCountByUser,
  }) {
    return ChatModel(
      id: id ?? this.id,
      contactUID: contactUID ?? this.contactUID,
      contactName: contactName ?? this.contactName,
      contactImage: contactImage ?? this.contactImage,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      unreadCount: unreadCount ?? this.unreadCount,
      isGroup: isGroup ?? this.isGroup,
      groupId: groupId ?? this.groupId,
      unreadCountByUser: unreadCountByUser ?? Map.from(this.unreadCountByUser),
    );
  }
  
  // Helper method to get unread count for a specific user
  int getUnreadCountForUser(String userId) {
    return unreadCountByUser[userId] ?? 0;
  }
  
  // Helper method to update unread count for a specific user
  ChatModel updateUnreadCountForUser(String userId, int count) {
    final newUnreadCountByUser = Map<String, int>.from(unreadCountByUser);
    newUnreadCountByUser[userId] = count;
    
    // If this is the current user, update the main unreadCount property too
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && userId == currentUser.uid) {
      return copyWith(
        unreadCountByUser: newUnreadCountByUser,
        unreadCount: count,
      );
    }
    
    return copyWith(
      unreadCountByUser: newUnreadCountByUser,
    );
  }
  
  // Helper method to increment unread count for a specific user
  ChatModel incrementUnreadCountForUser(String userId) {
    final currentCount = unreadCountByUser[userId] ?? 0;
    return updateUnreadCountForUser(userId, currentCount + 1);
  }
  
  // Helper method to reset unread count for a specific user
  ChatModel resetUnreadCountForUser(String userId) {
    return updateUnreadCountForUser(userId, 0);
  }
  
  // Helper method to check if the current user has unread messages
  bool hasUnreadMessages() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    
    // Check if we have an unread count for the current user
    if (unreadCountByUser.containsKey(currentUser.uid)) {
      return unreadCountByUser[currentUser.uid]! > 0;
    }
    
    // Fall back to the traditional unreadCount if the last message is from someone else
    if (lastMessageSender != currentUser.uid) {
      return unreadCount > 0;
    }
    
    return false;
  }
  
  // Helper method to get the correct unread count for display
  int getDisplayUnreadCount() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return 0;
    
    // If the last message was sent by the current user, they should have 0 unread messages
    if (lastMessageSender == currentUser.uid) {
      return 0;
    }
    
    // Try to get the unread count from unreadCountByUser first
    if (unreadCountByUser.containsKey(currentUser.uid)) {
      return unreadCountByUser[currentUser.uid] ?? 0;
    }
    
    // Fall back to the traditional unreadCount
    return unreadCount;
  }
}
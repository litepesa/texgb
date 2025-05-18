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
    
    return ChatModel(
      id: map['id'] ?? '',
      contactUID: map[Constants.contactUID] ?? '',
      contactName: map[Constants.contactName] ?? '',
      contactImage: map[Constants.contactImage] ?? '',
      lastMessage: map[Constants.lastMessage] ?? '',
      lastMessageType: (map[Constants.messageType] as String? ?? 'text').toMessageEnum(),
      lastMessageTime: map[Constants.timeSent] ?? DateTime.now().millisecondsSinceEpoch.toString(),
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
    return copyWith(
      unreadCountByUser: newUnreadCountByUser,
      unreadCount: userId == FirebaseAuth.instance.currentUser?.uid ? count : unreadCount,
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
}
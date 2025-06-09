// lib/features/chat/models/chat_model.dart - Modified implementation

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
  final bool? isPinned; // Added for pin functionality
  final DateTime? pinnedAt; // Added to track when it was pinned

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
    this.isPinned,
    this.pinnedAt,
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
      // If last message is from someone else, use the unreadCount field
      if (unreadCount == 0 && map.containsKey('unreadCount')) {
        unreadCount = map['unreadCount'] as int? ?? 0;
      }
    } else if (currentUser != null && lastMessageSender == currentUser.uid) {
      // If current user is the last message sender, they should have 0 unread messages
      unreadCount = 0;
    }
    
    // Parse pin data
    final bool? isPinned = map['isPinned'] as bool?;
    DateTime? pinnedAt;
    
    if (map['pinnedAt'] != null) {
      try {
        // Handle both string and int timestamps
        final pinnedAtValue = map['pinnedAt'];
        if (pinnedAtValue is String && pinnedAtValue.isNotEmpty) {
          pinnedAt = DateTime.fromMillisecondsSinceEpoch(int.parse(pinnedAtValue));
        } else if (pinnedAtValue is int) {
          pinnedAt = DateTime.fromMillisecondsSinceEpoch(pinnedAtValue);
        }
      } catch (e) {
        print('Error parsing pinnedAt: $e');
        // If parsing fails, set to null
        pinnedAt = null;
      }
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
      isPinned: isPinned,
      pinnedAt: pinnedAt,
    );
  }

  // Convert ChatModel to Map for Firestore
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
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
      'unreadCountByUser': unreadCountByUser,
    };
    
    // Add group-specific fields
    if (isGroup && groupId != null) {
      data[Constants.groupId] = groupId;
    }
    
    // Add pin-related fields
    if (isPinned != null) {
      data['isPinned'] = isPinned;
    }
    if (pinnedAt != null) {
      data['pinnedAt'] = pinnedAt!.millisecondsSinceEpoch.toString();
    }
    
    return data;
  }

  // IMPROVED: getDisplayUnreadCount only counts received messages, not sent ones
  int getDisplayUnreadCount() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return 0;
    
    // First priority: Check the lastMessageSender field
    // If the current user sent the last message, they have no unread messages
    if (lastMessageSender == currentUser.uid) {
      return 0;
    }
    
    // Second priority: Look in unreadCountByUser map if available
    if (unreadCountByUser.containsKey(currentUser.uid)) {
      return unreadCountByUser[currentUser.uid] ?? 0;
    }
    
    // Check if lastMessageSender is set and is not the current user
    if (lastMessageSender.isNotEmpty && lastMessageSender != currentUser.uid) {
      // If last message is from someone else, use the unreadCount field
      return unreadCount;
    }
    
    // Default case - no unread messages
    return 0;
  }
  
  // Helper method to check if the current user has unread messages
  bool hasUnreadMessages() {
    return getDisplayUnreadCount() > 0;
  }
  
  // Helper method to check if the chat is pinned
  bool get isPinnedChat => isPinned ?? false;
  
  // Create a copy of the chat model with updated fields
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
    bool? isPinned,
    DateTime? pinnedAt,
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
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: pinnedAt ?? this.pinnedAt,
    );
  }
  
  // Helper method to pin/unpin the chat
  ChatModel togglePin() {
    final newPinStatus = !isPinnedChat;
    return copyWith(
      isPinned: newPinStatus,
      pinnedAt: newPinStatus ? DateTime.now() : null,
    );
  }
  
  // Helper method to pin the chat
  ChatModel pin() {
    return copyWith(
      isPinned: true,
      pinnedAt: DateTime.now(),
    );
  }
  
  // Helper method to unpin the chat
  ChatModel unpin() {
    return copyWith(
      isPinned: false,
      pinnedAt: null,
    );
  }
  
  // Override toString for debugging
  @override
  String toString() {
    return 'ChatModel(id: $id, contactName: $contactName, isPinned: $isPinned, unreadCount: ${getDisplayUnreadCount()})';
  }
  
  // Override equality operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ChatModel &&
      other.id == id &&
      other.contactUID == contactUID &&
      other.contactName == contactName &&
      other.contactImage == contactImage &&
      other.lastMessage == lastMessage &&
      other.lastMessageType == lastMessageType &&
      other.lastMessageTime == lastMessageTime &&
      other.lastMessageSender == lastMessageSender &&
      other.unreadCount == unreadCount &&
      other.isGroup == isGroup &&
      other.groupId == groupId &&
      other.isPinned == isPinned;
  }
  
  // Override hashCode
  @override
  int get hashCode {
    return Object.hash(
      id,
      contactUID,
      contactName,
      contactImage,
      lastMessage,
      lastMessageType,
      lastMessageTime,
      lastMessageSender,
      unreadCount,
      isGroup,
      groupId,
      isPinned,
    );
  }
}
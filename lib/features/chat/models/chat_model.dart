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
  final String lastMessageSender;
  final int unreadCount;
  final bool isGroup;
  final String? groupId;
  final Map<String, int> unreadCountByUser;
  final bool isPinned;
  final DateTime? pinnedAt;

  const ChatModel({
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
    this.unreadCountByUser = const {},
    this.isPinned = false,
    this.pinnedAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      
      // Calculate unread count
      int unreadCount = 0;
      Map<String, int> unreadCountByUser = {};
      
      // Parse unreadCountByUser
      if (map.containsKey('unreadCountByUser')) {
        final rawUnreadCounts = map['unreadCountByUser'];
        if (rawUnreadCounts is Map<String, dynamic>) {
          unreadCountByUser = Map<String, int>.from(
            rawUnreadCounts.map((key, value) => MapEntry(key, _parseInt(value)))
          );
        } else if (rawUnreadCounts is String) {
          try {
            final decoded = jsonDecode(rawUnreadCounts);
            if (decoded is Map) {
              unreadCountByUser = Map<String, int>.from(
                decoded.map((key, value) => MapEntry(key, _parseInt(value)))
              );
            }
          } catch (e) {
            // If parsing fails, use empty map
            unreadCountByUser = {};
          }
        }
        
        // Get unread count for current user
        if (currentUser != null && unreadCountByUser.containsKey(currentUser.uid)) {
          unreadCount = unreadCountByUser[currentUser.uid] ?? 0;
        }
      }
      
      // Fall back to old unreadCount field
      if (unreadCount == 0 && map.containsKey('unreadCount')) {
        unreadCount = _parseInt(map['unreadCount']);
      }
      
      // Check if current user is the last message sender
      final lastMessageSender = map['lastMessageSender']?.toString() ?? '';
      if (currentUser != null && lastMessageSender == currentUser.uid) {
        unreadCount = 0; // User sent the last message, so no unread messages
      }
      
      // Parse pin data
      final isPinned = map['isPinned'] == true;
      DateTime? pinnedAt;
      
      if (map['pinnedAt'] != null) {
        try {
          final pinnedAtValue = map['pinnedAt'];
          if (pinnedAtValue is String && pinnedAtValue.isNotEmpty) {
            pinnedAt = DateTime.fromMillisecondsSinceEpoch(int.parse(pinnedAtValue));
          } else if (pinnedAtValue is int) {
            pinnedAt = DateTime.fromMillisecondsSinceEpoch(pinnedAtValue);
          }
        } catch (e) {
          // If parsing fails, set to null
          pinnedAt = null;
        }
      }
      
      return ChatModel(
        id: map['id']?.toString() ?? '',
        contactUID: map[Constants.contactUID]?.toString() ?? '',
        contactName: map[Constants.contactName]?.toString() ?? '',
        contactImage: map[Constants.contactImage]?.toString() ?? '',
        lastMessage: map[Constants.lastMessage]?.toString() ?? '',
        lastMessageType: _parseMessageType(map[Constants.messageType]?.toString()),
        lastMessageTime: map[Constants.timeSent]?.toString() ?? 
          DateTime.now().millisecondsSinceEpoch.toString(),
        lastMessageSender: lastMessageSender,
        unreadCount: unreadCount,
        isGroup: map['isGroup'] == true,
        groupId: map[Constants.groupId]?.toString(),
        unreadCountByUser: unreadCountByUser,
        isPinned: isPinned,
        pinnedAt: pinnedAt,
      );
    } catch (e, stackTrace) {
      throw FormatException('Error parsing ChatModel: $e\nStack trace: $stackTrace');
    }
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static MessageEnum _parseMessageType(String? type) {
    if (type == null) return MessageEnum.text;
    
    switch (type.toLowerCase()) {
      case 'image': return MessageEnum.image;
      case 'video': return MessageEnum.video;
      case 'audio': return MessageEnum.audio;
      case 'file': return MessageEnum.file;
      case 'location': return MessageEnum.location;
      case 'contact': return MessageEnum.contact;
      default: return MessageEnum.text;
    }
  }

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
      'isPinned': isPinned,
    };
    
    // Add group-specific fields
    if (isGroup && groupId != null) {
      data[Constants.groupId] = groupId;
    }
    
    // Add pin timestamp
    if (pinnedAt != null) {
      data['pinnedAt'] = pinnedAt!.millisecondsSinceEpoch.toString();
    }
    
    return data;
  }

  // Get display unread count - only counts received messages
  int getDisplayUnreadCount() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return 0;
    
    // If current user sent the last message, they have no unread messages
    if (lastMessageSender == currentUser.uid) {
      return 0;
    }
    
    // Check user-specific unread count
    if (unreadCountByUser.containsKey(currentUser.uid)) {
      return unreadCountByUser[currentUser.uid] ?? 0;
    }
    
    // Check if last message is from someone else
    if (lastMessageSender.isNotEmpty && lastMessageSender != currentUser.uid) {
      return unreadCount;
    }
    
    return 0;
  }
  
  // Helper method to check if the current user has unread messages
  bool hasUnreadMessages() {
    return getDisplayUnreadCount() > 0;
  }
  
  // Helper method to check if the chat is pinned
  bool get isPinnedChat => isPinned;
  
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
      unreadCountByUser: unreadCountByUser ?? Map<String, int>.from(this.unreadCountByUser),
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
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ChatModel &&
      other.id == id &&
      other.contactUID == contactUID &&
      other.lastMessage == lastMessage &&
      other.lastMessageTime == lastMessageTime;
  }
  
  @override
  int get hashCode {
    return Object.hash(id, contactUID, lastMessage, lastMessageTime);
  }

  @override
  String toString() {
    return 'ChatModel(id: $id, contact: $contactName, unread: ${getDisplayUnreadCount()}, pinned: $isPinned)';
  }
}
// lib/features/chat/models/chat_model.dart

enum ChatType {
  oneOnOne('one_on_one'),   // Direct message between 2 users
  group('group');            // Group chat with multiple users

  const ChatType(this.value);
  final String value;

  static ChatType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'group':
        return ChatType.group;
      case 'one_on_one':
      default:
        return ChatType.oneOnOne;
    }
  }
}

class ChatModel {
  final String id;
  final ChatType type;
  
  // Participants
  final List<String> participantIds;
  final List<String> participantNames;
  final List<String> participantImages;
  
  // Group specific fields
  final String? groupName;
  final String? groupImage;
  final String? groupDescription;
  final String? groupAdminId;
  final List<String> groupAdminIds; // Multiple admins support
  
  // Last message info
  final String? lastMessageId;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final String? lastMessageSenderName;
  final String lastMessageType;
  final String lastMessageTime;
  
  // Unread count per user
  final Map<String, int> unreadCounts; // userId -> count
  
  // Chat settings
  final bool isMuted;
  final bool isPinned;
  final bool isArchived;
  final bool isBlocked;
  
  // Timestamps
  final String createdAt;
  final String updatedAt;

  const ChatModel({
    required this.id,
    required this.type,
    required this.participantIds,
    required this.participantNames,
    required this.participantImages,
    this.groupName,
    this.groupImage,
    this.groupDescription,
    this.groupAdminId,
    this.groupAdminIds = const [],
    this.lastMessageId,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageSenderName,
    this.lastMessageType = 'text',
    required this.lastMessageTime,
    this.unreadCounts = const {},
    this.isMuted = false,
    this.isPinned = false,
    this.isArchived = false,
    this.isBlocked = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      id: id,
      type: ChatType.fromString(map['type'] ?? map['chat_type']),
      participantIds: _parseStringList(map['participantIds'] ?? map['participant_ids']),
      participantNames: _parseStringList(map['participantNames'] ?? map['participant_names']),
      participantImages: _parseStringList(map['participantImages'] ?? map['participant_images']),
      groupName: map['groupName'] ?? map['group_name'],
      groupImage: map['groupImage'] ?? map['group_image'],
      groupDescription: map['groupDescription'] ?? map['group_description'],
      groupAdminId: map['groupAdminId'] ?? map['group_admin_id'],
      groupAdminIds: _parseStringList(map['groupAdminIds'] ?? map['group_admin_ids']),
      lastMessageId: map['lastMessageId'] ?? map['last_message_id'],
      lastMessage: map['lastMessage'] ?? map['last_message'],
      lastMessageSenderId: map['lastMessageSenderId'] ?? map['last_message_sender_id'],
      lastMessageSenderName: map['lastMessageSenderName'] ?? map['last_message_sender_name'],
      lastMessageType: map['lastMessageType'] ?? map['last_message_type'] ?? 'text',
      lastMessageTime: map['lastMessageTime'] ?? map['last_message_time'] ?? '',
      unreadCounts: _parseUnreadCounts(map['unreadCounts'] ?? map['unread_counts']),
      isMuted: map['isMuted'] ?? map['is_muted'] ?? false,
      isPinned: map['isPinned'] ?? map['is_pinned'] ?? false,
      isArchived: map['isArchived'] ?? map['is_archived'] ?? false,
      isBlocked: map['isBlocked'] ?? map['is_blocked'] ?? false,
      createdAt: map['createdAt'] ?? map['created_at'] ?? '',
      updatedAt: map['updatedAt'] ?? map['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.value,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantImages': participantImages,
      'groupName': groupName,
      'groupImage': groupImage,
      'groupDescription': groupDescription,
      'groupAdminId': groupAdminId,
      'groupAdminIds': groupAdminIds,
      'lastMessageId': lastMessageId,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageSenderName': lastMessageSenderName,
      'lastMessageType': lastMessageType,
      'lastMessageTime': lastMessageTime,
      'unreadCounts': unreadCounts,
      'isMuted': isMuted,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'isBlocked': isBlocked,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  ChatModel copyWith({
    String? id,
    ChatType? type,
    List<String>? participantIds,
    List<String>? participantNames,
    List<String>? participantImages,
    String? groupName,
    String? groupImage,
    String? groupDescription,
    String? groupAdminId,
    List<String>? groupAdminIds,
    String? lastMessageId,
    String? lastMessage,
    String? lastMessageSenderId,
    String? lastMessageSenderName,
    String? lastMessageType,
    String? lastMessageTime,
    Map<String, int>? unreadCounts,
    bool? isMuted,
    bool? isPinned,
    bool? isArchived,
    bool? isBlocked,
    String? createdAt,
    String? updatedAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
      participantNames: participantNames ?? this.participantNames,
      participantImages: participantImages ?? this.participantImages,
      groupName: groupName ?? this.groupName,
      groupImage: groupImage ?? this.groupImage,
      groupDescription: groupDescription ?? this.groupDescription,
      groupAdminId: groupAdminId ?? this.groupAdminId,
      groupAdminIds: groupAdminIds ?? this.groupAdminIds,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageSenderName: lastMessageSenderName ?? this.lastMessageSenderName,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods for parsing
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }
    
    if (value is String) {
      if (value.isEmpty || value == '{}' || value == '[]') return [];
      String cleaned = value.replaceAll(RegExp(r'[{}"\[\]]'), '');
      if (cleaned.isEmpty) return [];
      return cleaned.split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    
    return [];
  }

  static Map<String, int> _parseUnreadCounts(dynamic value) {
    if (value == null) return {};
    if (value is Map) {
      return value.map((key, val) {
        final intVal = val is int ? val : int.tryParse(val.toString()) ?? 0;
        return MapEntry(key.toString(), intVal);
      });
    }
    return {};
  }

  // Timestamp helpers
  DateTime get createdAtDateTime => DateTime.parse(createdAt);
  DateTime get updatedAtDateTime => DateTime.parse(updatedAt);
  DateTime? get lastMessageDateTime {
    if (lastMessageTime.isEmpty) return null;
    try {
      return DateTime.parse(lastMessageTime);
    } catch (e) {
      return null;
    }
  }

  // Type helpers
  bool get isOneOnOne => type == ChatType.oneOnOne;
  bool get isGroup => type == ChatType.group;

  // Participant helpers
  int get participantCount => participantIds.length;
  bool get hasMessages => lastMessage != null && lastMessage!.isNotEmpty;

  // Get other participant in one-on-one chat
  String? getOtherParticipantId(String currentUserId) {
    if (!isOneOnOne) return null;
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  String? getOtherParticipantName(String currentUserId) {
    if (!isOneOnOne) return null;
    final otherIndex = participantIds.indexWhere((id) => id != currentUserId);
    if (otherIndex == -1 || otherIndex >= participantNames.length) return null;
    return participantNames[otherIndex];
  }

  String? getOtherParticipantImage(String currentUserId) {
    if (!isOneOnOne) return null;
    final otherIndex = participantIds.indexWhere((id) => id != currentUserId);
    if (otherIndex == -1 || otherIndex >= participantImages.length) return null;
    return participantImages[otherIndex];
  }

  // Unread count helpers
  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  bool hasUnreadMessages(String userId) {
    return getUnreadCount(userId) > 0;
  }

  // Group admin helpers
  bool isAdmin(String userId) {
    if (groupAdminId == userId) return true;
    return groupAdminIds.contains(userId);
  }

  bool get hasMultipleAdmins => groupAdminIds.length > 1;

  // Display helpers
  String getChatTitle(String currentUserId) {
    if (isGroup) {
      return groupName ?? 'Group Chat';
    }
    return getOtherParticipantName(currentUserId) ?? 'Unknown';
  }

  String? getChatImage(String currentUserId) {
    if (isGroup) {
      return groupImage;
    }
    return getOtherParticipantImage(currentUserId);
  }

  String getLastMessagePreview() {
    if (lastMessage == null || lastMessage!.isEmpty) {
      return 'No messages yet';
    }

    // Handle different message types
    switch (lastMessageType) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'audio':
        return '🎤 Voice message';
      case 'document':
        return '📄 Document';
      case 'location':
        return '📍 Location';
      case 'contact':
        return '👤 Contact';
      case 'sticker':
        return '😊 Sticker';
      case 'gif':
        return '🎬 GIF';
      default:
        // Truncate long messages
        if (lastMessage!.length > 50) {
          return '${lastMessage!.substring(0, 50)}...';
        }
        return lastMessage!;
    }
  }

  // Time formatting
  String get formattedLastMessageTime {
    final messageTime = lastMessageDateTime;
    if (messageTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(messageTime);

    if (difference.inDays == 0) {
      // Today - show time
      final hour = messageTime.hour.toString().padLeft(2, '0');
      final minute = messageTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[messageTime.weekday - 1];
    } else {
      // Older - show date
      final day = messageTime.day.toString().padLeft(2, '0');
      final month = messageTime.month.toString().padLeft(2, '0');
      final year = messageTime.year.toString().substring(2);
      return '$day/$month/$year';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatModel(id: $id, type: ${type.value}, participants: $participantCount, lastMessage: ${lastMessage?.substring(0, lastMessage!.length > 30 ? 30 : lastMessage!.length) ?? 'none'})';
  }
}
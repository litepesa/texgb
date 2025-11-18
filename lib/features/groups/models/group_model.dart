// lib/features/groups/models/group_model.dart

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String? groupImageUrl;
  final String creatorId;
  final int memberCount;
  final int maxMembers;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final bool isActive;
  final DateTime? insertedAt;
  final DateTime? updatedAt;

  const GroupModel({
    required this.id,
    required this.name,
    required this.description,
    this.groupImageUrl,
    required this.creatorId,
    this.memberCount = 0,
    this.maxMembers = 256,
    this.lastMessageText,
    this.lastMessageAt,
    this.isActive = true,
    this.insertedAt,
    this.updatedAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      groupImageUrl: json['group_image_url'],
      creatorId: json['creator_id'] ?? '',
      memberCount: json['member_count'] ?? 0,
      maxMembers: json['max_members'] ?? 256,
      lastMessageText: json['last_message_text'],
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      isActive: json['is_active'] ?? true,
      insertedAt: json['inserted_at'] != null
          ? DateTime.parse(json['inserted_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'group_image_url': groupImageUrl,
      'creator_id': creatorId,
      'member_count': memberCount,
      'max_members': maxMembers,
      'last_message_text': lastMessageText,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'is_active': isActive,
      'inserted_at': insertedAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? groupImageUrl,
    String? creatorId,
    int? memberCount,
    int? maxMembers,
    String? lastMessageText,
    DateTime? lastMessageAt,
    bool? isActive,
    DateTime? insertedAt,
    DateTime? updatedAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      groupImageUrl: groupImageUrl ?? this.groupImageUrl,
      creatorId: creatorId ?? this.creatorId,
      memberCount: memberCount ?? this.memberCount,
      maxMembers: maxMembers ?? this.maxMembers,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isActive: isActive ?? this.isActive,
      insertedAt: insertedAt ?? this.insertedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get hasImage => groupImageUrl != null && groupImageUrl!.isNotEmpty;

  bool get hasLastMessage => lastMessageText != null && lastMessageText!.isNotEmpty;

  bool get isFull => memberCount >= maxMembers;

  String get displayName => name.isEmpty ? 'Unnamed Group' : name;

  String get displayDescription => description.isEmpty ? 'No description' : description;

  // Time ago for last message
  String get lastMessageTimeAgo {
    if (lastMessageAt == null) return 'No messages';

    final now = DateTime.now();
    final difference = now.difference(lastMessageAt!);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// lib/features/groups/models/group_member_model.dart

enum GroupMemberRole {
  admin,
  member;

  String get displayName {
    switch (this) {
      case GroupMemberRole.admin:
        return 'Admin';
      case GroupMemberRole.member:
        return 'Member';
    }
  }

  static GroupMemberRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return GroupMemberRole.admin;
      case 'member':
        return GroupMemberRole.member;
      default:
        return GroupMemberRole.member;
    }
  }

  String toJson() => name;
}

class GroupMemberModel {
  final String id;
  final String groupId;
  final String userId;
  final GroupMemberRole role;
  final DateTime joinedAt;
  final String? userName;
  final String? userImage;
  final String? userPhone;

  const GroupMemberModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.userName,
    this.userImage,
    this.userPhone,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      id: json['id'] ?? '',
      groupId: json['group_id'] ?? '',
      userId: json['user_id'] ?? '',
      role: json['role'] != null
          ? GroupMemberRole.fromString(json['role'])
          : GroupMemberRole.member,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'])
          : DateTime.now(),
      userName: json['user_name'],
      userImage: json['user_image'],
      userPhone: json['user_phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'role': role.toJson(),
      'joined_at': joinedAt.toIso8601String(),
      'user_name': userName,
      'user_image': userImage,
      'user_phone': userPhone,
    };
  }

  GroupMemberModel copyWith({
    String? id,
    String? groupId,
    String? userId,
    GroupMemberRole? role,
    DateTime? joinedAt,
    String? userName,
    String? userImage,
    String? userPhone,
  }) {
    return GroupMemberModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      userPhone: userPhone ?? this.userPhone,
    );
  }

  // Helper methods
  bool get isAdmin => role == GroupMemberRole.admin;

  bool get isMember => role == GroupMemberRole.member;

  String get displayName => userName ?? 'Unknown User';

  String get displayRole => role.displayName;

  // Time ago for joined date
  String get joinedTimeAgo {
    final now = DateTime.now();
    final difference = now.difference(joinedAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }
}

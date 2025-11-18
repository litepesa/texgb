// lib/features/groups/models/group_member_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_member_model.freezed.dart';
part 'group_member_model.g.dart';

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
}

@freezed
class GroupMemberModel with _$GroupMemberModel {
  const factory GroupMemberModel({
    required String id,
    @JsonKey(name: 'group_id') required String groupId,
    @JsonKey(name: 'user_id') required String userId,
    required GroupMemberRole role,
    @JsonKey(name: 'joined_at') required DateTime joinedAt,
    // Optional user details (populated from join query)
    @JsonKey(name: 'user_name') String? userName,
    @JsonKey(name: 'user_image') String? userImage,
    @JsonKey(name: 'user_phone') String? userPhone,
  }) = _GroupMemberModel;

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberModelFromJson(json);
}

// Extension methods for GroupMemberModel
extension GroupMemberModelExtension on GroupMemberModel {
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

// lib/features/groups/models/group_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_model.freezed.dart';
part 'group_model.g.dart';

@freezed
class GroupModel with _$GroupModel {
  const factory GroupModel({
    required String id,
    required String name,
    required String description,
    @JsonKey(name: 'group_image_url') String? groupImageUrl,
    @JsonKey(name: 'creator_id') required String creatorId,
    @JsonKey(name: 'member_count') @Default(0) int memberCount,
    @JsonKey(name: 'max_members') @Default(256) int maxMembers,
    @JsonKey(name: 'last_message_text') String? lastMessageText,
    @JsonKey(name: 'last_message_at') DateTime? lastMessageAt,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'inserted_at') DateTime? insertedAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _GroupModel;

  factory GroupModel.fromJson(Map<String, dynamic> json) =>
      _$GroupModelFromJson(json);
}

// Extension methods for GroupModel
extension GroupModelExtension on GroupModel {
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

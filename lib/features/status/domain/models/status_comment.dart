import 'package:freezed_annotation/freezed_annotation.dart';

part 'status_comment.freezed.dart';
part 'status_comment.g.dart';

@freezed
class StatusComment with _$StatusComment {
  const factory StatusComment({
    required String id,
    required String postId,
    required String userId,
    required String userName,
    required String userImage,
    required String content,
    required DateTime createdAt,
    @Default(false) bool isEdited,
    String? replyToCommentId,
    String? replyToUserId,
    String? replyToUserName,
  }) = _StatusComment;

  factory StatusComment.fromJson(Map<String, dynamic> json) => _$StatusCommentFromJson(json);
  
  // Helper methods
  const StatusComment._();
  
  bool get isReply => replyToCommentId != null;
  
  // Get formatted date for display
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    // More than a week ago, show the actual date
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
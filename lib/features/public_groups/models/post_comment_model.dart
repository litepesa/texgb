// lib/features/public_groups/models/post_comment_model.dart
class PostCommentModel {
  final String commentId;
  final String postId;
  final String groupId;
  final String authorUID;
  final String authorName;
  final String authorImage;
  final String content;
  final String createdAt;
  final Map<String, dynamic> reactions;
  final int reactionsCount;
  final String? repliedToCommentId;
  final String? repliedToAuthorName;

  PostCommentModel({
    required this.commentId,
    required this.postId,
    required this.groupId,
    required this.authorUID,
    required this.authorName,
    required this.authorImage,
    required this.content,
    required this.createdAt,
    required this.reactions,
    required this.reactionsCount,
    this.repliedToCommentId,
    this.repliedToAuthorName,
  });

  factory PostCommentModel.fromMap(Map<String, dynamic> map) {
    try {
      return PostCommentModel(
        commentId: map['commentId']?.toString() ?? '',
        postId: map['postId']?.toString() ?? '',
        groupId: map['groupId']?.toString() ?? '',
        authorUID: map['authorUID']?.toString() ?? '',
        authorName: map['authorName']?.toString() ?? '',
        authorImage: map['authorImage']?.toString() ?? '',
        content: map['content']?.toString() ?? '',
        createdAt: map['createdAt']?.toString() ?? '',
        reactions: Map<String, dynamic>.from(map['reactions'] ?? {}),
        reactionsCount: map['reactionsCount'] is int 
            ? map['reactionsCount'] 
            : int.tryParse(map['reactionsCount']?.toString() ?? '0') ?? 0,
        repliedToCommentId: map['repliedToCommentId']?.toString(),
        repliedToAuthorName: map['repliedToAuthorName']?.toString(),
      );
    } catch (e, stackTrace) {
      print('Error parsing PostCommentModel: $e');
      print('Map data: $map');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'postId': postId,
      'groupId': groupId,
      'authorUID': authorUID,
      'authorName': authorName,
      'authorImage': authorImage,
      'content': content,
      'createdAt': createdAt,
      'reactions': reactions,
      'reactionsCount': reactionsCount,
      'repliedToCommentId': repliedToCommentId,
      'repliedToAuthorName': repliedToAuthorName,
    };
  }

  PostCommentModel copyWith({
    String? commentId,
    String? postId,
    String? groupId,
    String? authorUID,
    String? authorName,
    String? authorImage,
    String? content,
    String? createdAt,
    Map<String, dynamic>? reactions,
    int? reactionsCount,
    String? repliedToCommentId,
    String? repliedToAuthorName,
  }) {
    return PostCommentModel(
      commentId: commentId ?? this.commentId,
      postId: postId ?? this.postId,
      groupId: groupId ?? this.groupId,
      authorUID: authorUID ?? this.authorUID,
      authorName: authorName ?? this.authorName,
      authorImage: authorImage ?? this.authorImage,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      reactions: reactions ?? Map.from(this.reactions),
      reactionsCount: reactionsCount ?? this.reactionsCount,
      repliedToCommentId: repliedToCommentId ?? this.repliedToCommentId,
      repliedToAuthorName: repliedToAuthorName ?? this.repliedToAuthorName,
    );
  }

  // Helper methods
  bool hasUserReacted(String uid) {
    return reactions.containsKey(uid);
  }

  String? getUserReaction(String uid) {
    final userReaction = reactions[uid];
    return userReaction is Map ? userReaction['emoji'] : null;
  }

  bool isReply() {
    return repliedToCommentId != null;
  }

  String getFormattedTime() {
    if (createdAt.isEmpty) return '';
    
    try {
      final timestamp = int.parse(createdAt);
      final commentTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(commentTime);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }
}
// lib/features/channels/models/channel_comment_model.dart

/// Multi-threaded comment model (Twitter/Reddit style)
class ChannelComment {
  final String id;
  final String postId;
  final String?
      parentCommentId; // null = top-level comment, otherwise reply to this comment
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;

  // Content
  final String text;
  final String? mediaUrl; // Optional image attachment

  // Thread metadata
  final int depth; // 0 = top-level, 1 = first reply, 2 = second level, etc.
  final int repliesCount; // Direct replies to this comment
  final int totalRepliesCount; // All nested replies (recursive)

  // Engagement
  final int likes;
  final bool isPinned; // Pinned by admin/moderator
  final bool isDeleted; // Soft delete (show "[deleted]" placeholder)

  // User interaction
  final bool? hasLiked;

  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // For UI: Nested replies loaded inline
  final List<ChannelComment> replies;

  const ChannelComment({
    required this.id,
    required this.postId,
    this.parentCommentId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.text,
    this.mediaUrl,
    this.depth = 0,
    this.repliesCount = 0,
    this.totalRepliesCount = 0,
    this.likes = 0,
    this.isPinned = false,
    this.isDeleted = false,
    this.hasLiked,
    this.createdAt,
    this.updatedAt,
    this.replies = const [],
  });

  factory ChannelComment.fromJson(Map<String, dynamic> json) {
    return ChannelComment(
      id: json['id'] as String,
      postId: json['postId'] as String? ?? json['post_id'] as String,
      parentCommentId: json['parentCommentId'] as String? ??
          json['parent_comment_id'] as String?,
      authorId: json['authorId'] as String? ?? json['author_id'] as String,
      authorName:
          json['authorName'] as String? ?? json['author_name'] as String,
      authorAvatarUrl: json['authorAvatarUrl'] as String? ??
          json['author_avatar_url'] as String?,
      text: json['text'] as String,
      mediaUrl: json['mediaUrl'] as String? ?? json['media_url'] as String?,
      depth: json['depth'] as int? ?? 0,
      repliesCount:
          json['repliesCount'] as int? ?? json['replies_count'] as int? ?? 0,
      totalRepliesCount: json['totalRepliesCount'] as int? ??
          json['total_replies_count'] as int? ??
          0,
      likes: json['likes'] as int? ?? 0,
      isPinned:
          json['isPinned'] as bool? ?? json['is_pinned'] as bool? ?? false,
      isDeleted:
          json['isDeleted'] as bool? ?? json['is_deleted'] as bool? ?? false,
      hasLiked: json['hasLiked'] as bool? ?? json['has_liked'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : (json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null),
      replies: (json['replies'] as List<dynamic>?)
              ?.map((e) => ChannelComment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'parentCommentId': parentCommentId,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'text': text,
      'mediaUrl': mediaUrl,
      'depth': depth,
      'repliesCount': repliesCount,
      'totalRepliesCount': totalRepliesCount,
      'likes': likes,
      'isPinned': isPinned,
      'isDeleted': isDeleted,
      'hasLiked': hasLiked,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'replies': replies.map((e) => e.toJson()).toList(),
    };
  }

  ChannelComment copyWith({
    String? id,
    String? postId,
    String? parentCommentId,
    String? authorId,
    String? authorName,
    String? authorAvatarUrl,
    String? text,
    String? mediaUrl,
    int? depth,
    int? repliesCount,
    int? totalRepliesCount,
    int? likes,
    bool? isPinned,
    bool? isDeleted,
    bool? hasLiked,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChannelComment>? replies,
  }) {
    return ChannelComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      depth: depth ?? this.depth,
      repliesCount: repliesCount ?? this.repliesCount,
      totalRepliesCount: totalRepliesCount ?? this.totalRepliesCount,
      likes: likes ?? this.likes,
      isPinned: isPinned ?? this.isPinned,
      isDeleted: isDeleted ?? this.isDeleted,
      hasLiked: hasLiked ?? this.hasLiked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      replies: replies ?? this.replies,
    );
  }
}

/// Extension for comment helpers
extension ChannelCommentExtension on ChannelComment {
  /// Alias for authorName (for compatibility)
  String get username => authorName;

  /// Alias for authorAvatarUrl (for compatibility)
  String? get userAvatarUrl => authorAvatarUrl;

  /// Check if this is a top-level comment
  bool get isTopLevel => parentCommentId == null || depth == 0;

  /// Check if comment has replies
  bool get hasReplies => repliesCount > 0;

  /// Check if this comment has media attachment
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;

  /// Get indentation level for UI (cap at certain depth to avoid too much nesting)
  int get indentLevel => depth > 5 ? 5 : depth;

  /// Check if comment was edited
  bool get wasEdited {
    if (createdAt == null || updatedAt == null) return false;
    return updatedAt!.isAfter(createdAt!.add(const Duration(seconds: 30)));
  }

  /// Get display text (show placeholder if deleted)
  String get displayText => isDeleted ? '[Comment deleted]' : text;

  /// Check if current user can delete (will be determined by comparing authorId with current user)
  bool canDelete(String currentUserId, bool isAdminOrMod) {
    if (isDeleted) return false;
    return authorId == currentUserId || isAdminOrMod;
  }

  /// Get time ago string
  String get timeAgo {
    if (createdAt == null) return '';

    final now = DateTime.now();
    final difference = now.difference(createdAt!);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y';
    }
  }
}

/// Comment sort options
enum CommentSortType {
  top, // Most liked
  new_, // Newest first
  old, // Oldest first
}

/// Comment tree node for rendering (helper for UI)
class CommentTreeNode {
  final ChannelComment comment;
  final List<CommentTreeNode> children;
  final int depth;
  bool isExpanded;

  CommentTreeNode({
    required this.comment,
    this.children = const [],
    required this.depth,
    this.isExpanded = true,
  });

  /// Get flattened list for rendering (with expand/collapse state)
  List<CommentTreeNode> get flattenedList {
    final list = <CommentTreeNode>[this];
    if (isExpanded) {
      for (final child in children) {
        list.addAll(child.flattenedList);
      }
    }
    return list;
  }

  /// Total replies including all nested
  int get totalRepliesCount {
    int count = children.length;
    for (final child in children) {
      count += child.totalRepliesCount;
    }
    return count;
  }
}

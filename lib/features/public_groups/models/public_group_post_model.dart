// lib/features/public_groups/models/public_group_post_model.dart
import 'package:textgb/enums/enums.dart';

class PublicGroupPostModel {
  final String postId;
  final String groupId;
  final String authorUID;
  final String authorName;
  final String authorImage;
  final String content;
  final List<String> mediaUrls;
  final MessageEnum postType;
  final String createdAt;
  final Map<String, dynamic> reactions;
  final int commentsCount;
  final int reactionsCount;
  final bool isPinned;
  final Map<String, dynamic> metadata;

  PublicGroupPostModel({
    required this.postId,
    required this.groupId,
    required this.authorUID,
    required this.authorName,
    required this.authorImage,
    required this.content,
    required this.mediaUrls,
    required this.postType,
    required this.createdAt,
    required this.reactions,
    required this.commentsCount,
    required this.reactionsCount,
    required this.isPinned,
    required this.metadata,
  });

  factory PublicGroupPostModel.fromMap(Map<String, dynamic> map) {
    try {
      return PublicGroupPostModel(
        postId: map['postId']?.toString() ?? '',
        groupId: map['groupId']?.toString() ?? '',
        authorUID: map['authorUID']?.toString() ?? '',
        authorName: map['authorName']?.toString() ?? '',
        authorImage: map['authorImage']?.toString() ?? '',
        content: map['content']?.toString() ?? '',
        mediaUrls: (map['mediaUrls'] as List?)
            ?.map((item) => item.toString())
            .toList()
            .cast<String>() ?? [],
        postType: MessageEnum.values.firstWhere(
          (e) => e.name == map['postType'],
          orElse: () => MessageEnum.text,
        ),
        createdAt: map['createdAt']?.toString() ?? '',
        reactions: Map<String, dynamic>.from(map['reactions'] ?? {}),
        commentsCount: map['commentsCount'] is int 
            ? map['commentsCount'] 
            : int.tryParse(map['commentsCount']?.toString() ?? '0') ?? 0,
        reactionsCount: map['reactionsCount'] is int 
            ? map['reactionsCount'] 
            : int.tryParse(map['reactionsCount']?.toString() ?? '0') ?? 0,
        isPinned: map['isPinned'] ?? false,
        metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      );
    } catch (e, stackTrace) {
      print('Error parsing PublicGroupPostModel: $e');
      print('Map data: $map');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'groupId': groupId,
      'authorUID': authorUID,
      'authorName': authorName,
      'authorImage': authorImage,
      'content': content,
      'mediaUrls': mediaUrls,
      'postType': postType.name,
      'createdAt': createdAt,
      'reactions': reactions,
      'commentsCount': commentsCount,
      'reactionsCount': reactionsCount,
      'isPinned': isPinned,
      'metadata': metadata,
    };
  }

  PublicGroupPostModel copyWith({
    String? postId,
    String? groupId,
    String? authorUID,
    String? authorName,
    String? authorImage,
    String? content,
    List<String>? mediaUrls,
    MessageEnum? postType,
    String? createdAt,
    Map<String, dynamic>? reactions,
    int? commentsCount,
    int? reactionsCount,
    bool? isPinned,
    Map<String, dynamic>? metadata,
  }) {
    return PublicGroupPostModel(
      postId: postId ?? this.postId,
      groupId: groupId ?? this.groupId,
      authorUID: authorUID ?? this.authorUID,
      authorName: authorName ?? this.authorName,
      authorImage: authorImage ?? this.authorImage,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? List.from(this.mediaUrls),
      postType: postType ?? this.postType,
      createdAt: createdAt ?? this.createdAt,
      reactions: reactions ?? Map.from(this.reactions),
      commentsCount: commentsCount ?? this.commentsCount,
      reactionsCount: reactionsCount ?? this.reactionsCount,
      isPinned: isPinned ?? this.isPinned,
      metadata: metadata ?? Map.from(this.metadata),
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

  String getFormattedTime() {
    if (createdAt.isEmpty) return '';
    
    try {
      final timestamp = int.parse(createdAt);
      final postTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(postTime);
      
      if (difference.inDays > 7) {
        return '${postTime.day}/${postTime.month}/${postTime.year}';
      } else if (difference.inDays > 0) {
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

  String getContentPreview({int maxLength = 100}) {
    if (content.isEmpty) {
      switch (postType) {
        case MessageEnum.image:
          return '📷 Photo';
        case MessageEnum.video:
          return '🎥 Video';
        case MessageEnum.audio:
          return '🎵 Audio';
        default:
          return 'Post';
      }
    }
    
    if (content.length <= maxLength) return content;
    return '${content.substring(0, maxLength)}...';
  }
}


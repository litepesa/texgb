import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'status_media.dart';
import 'status_privacy.dart';
import 'status_comment.dart';
import 'status_reaction.dart';

part 'status_post.freezed.dart';
part 'status_post.g.dart';

@freezed
class StatusPost with _$StatusPost {
  const factory StatusPost({
    required String id,
    required String authorId,
    required String authorName,
    required String authorImage,
    required DateTime createdAt,
    required DateTime expiresAt,
    required String content,
    required List<StatusMedia> media,
    required StatusPrivacy privacy,
    required List<StatusComment> comments,
    required List<StatusReaction> reactions,
    required List<String> viewerIds,
    required int viewCount,
    @Default(false) bool isEdited,
    String? location,
    String? linkUrl,
    String? linkPreviewImage,
    String? linkPreviewTitle,
    String? linkPreviewDescription,
    String? shareSource,
    String? shareSourcePostId,
  }) = _StatusPost;

  factory StatusPost.fromJson(Map<String, dynamic> json) => _$StatusPostFromJson(json);

  // Helper methods
  const StatusPost._();

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  bool isViewedBy(String userId) => viewerIds.contains(userId);
  
  bool canBeViewedBy(String viewerId, List<String> viewerContacts) {
    // Creator can always see their own posts
    if (viewerId == authorId) return true;
    
    switch (privacy.type) {
      case PrivacyType.allContacts:
        return viewerContacts.contains(authorId);
      case PrivacyType.except:
        return viewerContacts.contains(authorId) && !privacy.excludedUserIds.contains(viewerId);
      case PrivacyType.onlySpecific:
        return privacy.includedUserIds.contains(viewerId);
      default:
        return false;
    }
  }
  
  bool get hasValidMedia {
    if (media.isEmpty) return true;
    
    try {
      for (final item in media) {
        final uri = Uri.parse(item.url);
        if (!uri.isAbsolute) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // Get reaction count
  int get reactionCount => reactions.length;
  
  // Get reaction by user
  StatusReaction? getReactionByUser(String userId) {
    try {
      return reactions.firstWhere((reaction) => reaction.userId == userId);
    } catch (_) {
      return null;
    }
  }
  
  // Check if user has reacted
  bool hasReactionFromUser(String userId) {
    return reactions.any((reaction) => reaction.userId == userId);
  }
  
  // Get comment count
  int get commentCount => comments.length;
  
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
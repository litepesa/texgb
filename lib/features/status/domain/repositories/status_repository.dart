import 'dart:io';
import 'package:dartz/dartz.dart';
import '../models/status_post.dart';
import '../models/status_comment.dart';
import '../models/status_reaction.dart';
import '../models/status_privacy.dart';
import '../../core/failures.dart';

/// Repository interface for status posts
///
/// This abstraction allows for easy switching between data sources
abstract class StatusRepository {
  /// Fetch status feed for a user
  Future<Either<Failure, List<StatusPost>>> getStatusFeed({
    required String userId,
    required List<String> contactIds,
    required List<String> mutedUserIds,
    int? limit,
    String? lastPostId,
  });
  
  /// Fetch a specific status post by ID
  Future<Either<Failure, StatusPost>> getStatusPost(String postId);

  /// Create a new status post
  Future<Either<Failure, StatusPost>> createStatusPost({
    required String authorId,
    required String authorName,
    required String authorImage,
    required String content,
    required StatusPrivacy privacy,
    List<File>? mediaFiles, 
    String? location,
    String? linkUrl,
  });
  
  /// Update an existing status post
  Future<Either<Failure, StatusPost>> updateStatusPost({
    required String postId,
    required String authorId,
    String? content,
    StatusPrivacy? privacy,
  });

  /// Delete a status post
  Future<Either<Failure, Unit>> deleteStatusPost({
    required String postId,
    required String authorId,
  });
  
  /// View a status post (increment view count)
  Future<Either<Failure, Unit>> viewStatusPost({
    required String postId,
    required String viewerId,
  });
  
  /// Add a comment to a status post
  Future<Either<Failure, StatusComment>> addComment({
    required String postId, 
    required String userId,
    required String userName,
    required String userImage,
    required String content,
    String? replyToCommentId,
    String? replyToUserId,
    String? replyToUserName,
  });
  
  /// Delete a comment
  Future<Either<Failure, Unit>> deleteComment({
    required String commentId,
    required String postId,
    required String userId,
  });
  
  /// Add a reaction to a status post
  Future<Either<Failure, StatusReaction>> addReaction({
    required String postId,
    required String userId,
    required String userName,
    required String userImage, 
    required ReactionType reactionType,
  });
  
  /// Remove a reaction from a status post
  Future<Either<Failure, Unit>> removeReaction({
    required String reactionId,
    required String postId,
    required String userId,
  });
  
  /// Update user's muted users list
  Future<Either<Failure, Unit>> updateMutedUsers({
    required String userId,
    required List<String> mutedUserIds,
  });
  
  /// Get user's muted users list
  Future<Either<Failure, List<String>>> getMutedUsers(String userId);
  
  /// Check if user has posted in the last 24 hours
  Future<Either<Failure, bool>> hasUserPostedRecently(String userId);
}
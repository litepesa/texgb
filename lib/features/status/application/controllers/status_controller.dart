import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/status_repository.dart';
import '../../domain/models/status_post.dart';
import '../../domain/models/status_privacy.dart';
import '../../domain/models/status_comment.dart';
import '../../domain/models/status_reaction.dart';
import '../../core/failures.dart';
import '../state/status_state.dart';

/// Controller for all status-related operations
class StatusController {
  final StatusRepository _repository;
  
  StatusController({required StatusRepository repository}) : _repository = repository;
  
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
  }) async {
    return _repository.createStatusPost(
      authorId: authorId,
      authorName: authorName,
      authorImage: authorImage,
      content: content,
      privacy: privacy,
      mediaFiles: mediaFiles,
      location: location,
      linkUrl: linkUrl,
    );
  }
  
  /// Delete a status post
  Future<Either<Failure, Unit>> deleteStatusPost({
    required String postId,
    required String authorId,
  }) async {
    return _repository.deleteStatusPost(
      postId: postId,
      authorId: authorId,
    );
  }
  
  /// Update an existing status post
  Future<Either<Failure, StatusPost>> updateStatusPost({
    required String postId,
    required String authorId,
    String? content,
    StatusPrivacy? privacy,
  }) async {
    return _repository.updateStatusPost(
      postId: postId,
      authorId: authorId,
      content: content,
      privacy: privacy,
    );
  }
  
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
  }) async {
    return _repository.addComment(
      postId: postId,
      userId: userId,
      userName: userName,
      userImage: userImage,
      content: content,
      replyToCommentId: replyToCommentId,
      replyToUserId: replyToUserId,
      replyToUserName: replyToUserName,
    );
  }
  
  /// Delete a comment
  Future<Either<Failure, Unit>> deleteComment({
    required String commentId,
    required String postId,
    required String userId,
  }) async {
    return _repository.deleteComment(
      commentId: commentId,
      postId: postId,
      userId: userId,
    );
  }
  
  /// Add a reaction to a status post
  Future<Either<Failure, StatusReaction>> addReaction({
    required String postId,
    required String userId,
    required String userName,
    required String userImage,
    required ReactionType reactionType,
  }) async {
    return _repository.addReaction(
      postId: postId,
      userId: userId,
      userName: userName,
      userImage: userImage,
      reactionType: reactionType,
    );
  }
  
  /// Remove a reaction from a status post
  Future<Either<Failure, Unit>> removeReaction({
    required String reactionId,
    required String postId,
    required String userId,
  }) async {
    return _repository.removeReaction(
      reactionId: reactionId,
      postId: postId,
      userId: userId,
    );
  }
  
  /// Update muted users list
  Future<Either<Failure, Unit>> updateMutedUsers({
    required String userId,
    required List<String> mutedUserIds,
  }) async {
    return _repository.updateMutedUsers(
      userId: userId,
      mutedUserIds: mutedUserIds,
    );
  }
  
  /// Check if user has posted recently
  Future<Either<Failure, bool>> hasUserPostedRecently(String userId) async {
    return _repository.hasUserPostedRecently(userId);
  }
}
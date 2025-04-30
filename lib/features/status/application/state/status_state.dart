import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/models/status_post.dart';
import '../../domain/models/status_comment.dart';
import '../../core/failures.dart';

part 'status_state.freezed.dart';

/// State for the status feed screen
@freezed
abstract class StatusFeedState with _$StatusFeedState {
  const factory StatusFeedState({
    @Default([]) List<StatusPost> posts,
    @Default(false) bool isLoading,
    @Default(false) bool hasMore,
    String? lastPostId,
    Failure? failure,
  }) = _StatusFeedState;
  
  factory StatusFeedState.initial() => const StatusFeedState();
  
  factory StatusFeedState.loading() => const StatusFeedState(isLoading: true);
  
  factory StatusFeedState.loaded({
    required List<StatusPost> posts,
    required bool hasMore,
    String? lastPostId,
  }) => StatusFeedState(
    posts: posts,
    hasMore: hasMore,
    lastPostId: lastPostId,
    isLoading: false,
  );
  
  factory StatusFeedState.error(Failure failure) => StatusFeedState(
    failure: failure,
    isLoading: false,
  );
}

/// State for current user's posts
@freezed
abstract class StatusPostsState with _$StatusPostsState {
  const factory StatusPostsState({
    @Default([]) List<StatusPost> posts,
    @Default(false) bool isLoading,
    Failure? failure,
  }) = _StatusPostsState;
  
  factory StatusPostsState.initial() => const StatusPostsState();
  
  factory StatusPostsState.loading() => const StatusPostsState(isLoading: true);
  
  factory StatusPostsState.loaded(List<StatusPost> posts) => StatusPostsState(
    posts: posts,
    isLoading: false,
  );
  
  factory StatusPostsState.error(Failure failure) => StatusPostsState(
    failure: failure,
    isLoading: false,
  );
}

/// State for a single status post with comments
@freezed
abstract class StatusDetailState with _$StatusDetailState {
  const factory StatusDetailState({
    StatusPost? post,
    @Default([]) List<StatusComment> comments,
    @Default(false) bool isLoading,
    Failure? failure,
  }) = _StatusDetailState;
  
  factory StatusDetailState.initial() => const StatusDetailState();
  
  factory StatusDetailState.loading() => const StatusDetailState(isLoading: true);
  
  factory StatusDetailState.loaded({
    required StatusPost post,
    required List<StatusComment> comments,
  }) => StatusDetailState(
    post: post,
    comments: comments,
    isLoading: false,
  );
  
  factory StatusDetailState.error(Failure failure) => StatusDetailState(
    failure: failure,
    isLoading: false,
  );
}
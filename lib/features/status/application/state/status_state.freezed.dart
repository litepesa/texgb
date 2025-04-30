// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'status_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StatusFeedState {
  List<StatusPost> get posts;
  bool get isLoading;
  bool get hasMore;
  String? get lastPostId;
  Failure? get failure;

  /// Create a copy of StatusFeedState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $StatusFeedStateCopyWith<StatusFeedState> get copyWith =>
      _$StatusFeedStateCopyWithImpl<StatusFeedState>(
          this as StatusFeedState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is StatusFeedState &&
            const DeepCollectionEquality().equals(other.posts, posts) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.lastPostId, lastPostId) ||
                other.lastPostId == lastPostId) &&
            (identical(other.failure, failure) || other.failure == failure));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(posts),
      isLoading,
      hasMore,
      lastPostId,
      failure);

  @override
  String toString() {
    return 'StatusFeedState(posts: $posts, isLoading: $isLoading, hasMore: $hasMore, lastPostId: $lastPostId, failure: $failure)';
  }
}

/// @nodoc
abstract mixin class $StatusFeedStateCopyWith<$Res> {
  factory $StatusFeedStateCopyWith(
          StatusFeedState value, $Res Function(StatusFeedState) _then) =
      _$StatusFeedStateCopyWithImpl;
  @useResult
  $Res call(
      {List<StatusPost> posts,
      bool isLoading,
      bool hasMore,
      String? lastPostId,
      Failure? failure});

  $FailureCopyWith<$Res>? get failure;
}

/// @nodoc
class _$StatusFeedStateCopyWithImpl<$Res>
    implements $StatusFeedStateCopyWith<$Res> {
  _$StatusFeedStateCopyWithImpl(this._self, this._then);

  final StatusFeedState _self;
  final $Res Function(StatusFeedState) _then;

  /// Create a copy of StatusFeedState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? posts = null,
    Object? isLoading = null,
    Object? hasMore = null,
    Object? lastPostId = freezed,
    Object? failure = freezed,
  }) {
    return _then(_self.copyWith(
      posts: null == posts
          ? _self.posts
          : posts // ignore: cast_nullable_to_non_nullable
              as List<StatusPost>,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      hasMore: null == hasMore
          ? _self.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      lastPostId: freezed == lastPostId
          ? _self.lastPostId
          : lastPostId // ignore: cast_nullable_to_non_nullable
              as String?,
      failure: freezed == failure
          ? _self.failure
          : failure // ignore: cast_nullable_to_non_nullable
              as Failure?,
    ));
  }

  /// Create a copy of StatusFeedState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
      return null;
    }

    return $FailureCopyWith<$Res>(_self.failure!, (value) {
      return _then(_self.copyWith(failure: value));
    });
  }
}

/// @nodoc

class _StatusFeedState implements StatusFeedState {
  const _StatusFeedState(
      {final List<StatusPost> posts = const [],
      this.isLoading = false,
      this.hasMore = false,
      this.lastPostId,
      this.failure})
      : _posts = posts;

  final List<StatusPost> _posts;
  @override
  @JsonKey()
  List<StatusPost> get posts {
    if (_posts is EqualUnmodifiableListView) return _posts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_posts);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool hasMore;
  @override
  final String? lastPostId;
  @override
  final Failure? failure;

  /// Create a copy of StatusFeedState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$StatusFeedStateCopyWith<_StatusFeedState> get copyWith =>
      __$StatusFeedStateCopyWithImpl<_StatusFeedState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _StatusFeedState &&
            const DeepCollectionEquality().equals(other._posts, _posts) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.lastPostId, lastPostId) ||
                other.lastPostId == lastPostId) &&
            (identical(other.failure, failure) || other.failure == failure));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_posts),
      isLoading,
      hasMore,
      lastPostId,
      failure);

  @override
  String toString() {
    return 'StatusFeedState(posts: $posts, isLoading: $isLoading, hasMore: $hasMore, lastPostId: $lastPostId, failure: $failure)';
  }
}

/// @nodoc
abstract mixin class _$StatusFeedStateCopyWith<$Res>
    implements $StatusFeedStateCopyWith<$Res> {
  factory _$StatusFeedStateCopyWith(
          _StatusFeedState value, $Res Function(_StatusFeedState) _then) =
      __$StatusFeedStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {List<StatusPost> posts,
      bool isLoading,
      bool hasMore,
      String? lastPostId,
      Failure? failure});

  @override
  $FailureCopyWith<$Res>? get failure;
}

/// @nodoc
class __$StatusFeedStateCopyWithImpl<$Res>
    implements _$StatusFeedStateCopyWith<$Res> {
  __$StatusFeedStateCopyWithImpl(this._self, this._then);

  final _StatusFeedState _self;
  final $Res Function(_StatusFeedState) _then;

  /// Create a copy of StatusFeedState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? posts = null,
    Object? isLoading = null,
    Object? hasMore = null,
    Object? lastPostId = freezed,
    Object? failure = freezed,
  }) {
    return _then(_StatusFeedState(
      posts: null == posts
          ? _self._posts
          : posts // ignore: cast_nullable_to_non_nullable
              as List<StatusPost>,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      hasMore: null == hasMore
          ? _self.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      lastPostId: freezed == lastPostId
          ? _self.lastPostId
          : lastPostId // ignore: cast_nullable_to_non_nullable
              as String?,
      failure: freezed == failure
          ? _self.failure
          : failure // ignore: cast_nullable_to_non_nullable
              as Failure?,
    ));
  }

  /// Create a copy of StatusFeedState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
      return null;
    }

    return $FailureCopyWith<$Res>(_self.failure!, (value) {
      return _then(_self.copyWith(failure: value));
    });
  }
}

/// @nodoc
mixin _$StatusPostsState {
  List<StatusPost> get posts;
  bool get isLoading;
  Failure? get failure;

  /// Create a copy of StatusPostsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $StatusPostsStateCopyWith<StatusPostsState> get copyWith =>
      _$StatusPostsStateCopyWithImpl<StatusPostsState>(
          this as StatusPostsState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is StatusPostsState &&
            const DeepCollectionEquality().equals(other.posts, posts) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.failure, failure) || other.failure == failure));
  }

  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(posts), isLoading, failure);

  @override
  String toString() {
    return 'StatusPostsState(posts: $posts, isLoading: $isLoading, failure: $failure)';
  }
}

/// @nodoc
abstract mixin class $StatusPostsStateCopyWith<$Res> {
  factory $StatusPostsStateCopyWith(
          StatusPostsState value, $Res Function(StatusPostsState) _then) =
      _$StatusPostsStateCopyWithImpl;
  @useResult
  $Res call({List<StatusPost> posts, bool isLoading, Failure? failure});

  $FailureCopyWith<$Res>? get failure;
}

/// @nodoc
class _$StatusPostsStateCopyWithImpl<$Res>
    implements $StatusPostsStateCopyWith<$Res> {
  _$StatusPostsStateCopyWithImpl(this._self, this._then);

  final StatusPostsState _self;
  final $Res Function(StatusPostsState) _then;

  /// Create a copy of StatusPostsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? posts = null,
    Object? isLoading = null,
    Object? failure = freezed,
  }) {
    return _then(_self.copyWith(
      posts: null == posts
          ? _self.posts
          : posts // ignore: cast_nullable_to_non_nullable
              as List<StatusPost>,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      failure: freezed == failure
          ? _self.failure
          : failure // ignore: cast_nullable_to_non_nullable
              as Failure?,
    ));
  }

  /// Create a copy of StatusPostsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
      return null;
    }

    return $FailureCopyWith<$Res>(_self.failure!, (value) {
      return _then(_self.copyWith(failure: value));
    });
  }
}

/// @nodoc

class _StatusPostsState implements StatusPostsState {
  const _StatusPostsState(
      {final List<StatusPost> posts = const [],
      this.isLoading = false,
      this.failure})
      : _posts = posts;

  final List<StatusPost> _posts;
  @override
  @JsonKey()
  List<StatusPost> get posts {
    if (_posts is EqualUnmodifiableListView) return _posts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_posts);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  final Failure? failure;

  /// Create a copy of StatusPostsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$StatusPostsStateCopyWith<_StatusPostsState> get copyWith =>
      __$StatusPostsStateCopyWithImpl<_StatusPostsState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _StatusPostsState &&
            const DeepCollectionEquality().equals(other._posts, _posts) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.failure, failure) || other.failure == failure));
  }

  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_posts), isLoading, failure);

  @override
  String toString() {
    return 'StatusPostsState(posts: $posts, isLoading: $isLoading, failure: $failure)';
  }
}

/// @nodoc
abstract mixin class _$StatusPostsStateCopyWith<$Res>
    implements $StatusPostsStateCopyWith<$Res> {
  factory _$StatusPostsStateCopyWith(
          _StatusPostsState value, $Res Function(_StatusPostsState) _then) =
      __$StatusPostsStateCopyWithImpl;
  @override
  @useResult
  $Res call({List<StatusPost> posts, bool isLoading, Failure? failure});

  @override
  $FailureCopyWith<$Res>? get failure;
}

/// @nodoc
class __$StatusPostsStateCopyWithImpl<$Res>
    implements _$StatusPostsStateCopyWith<$Res> {
  __$StatusPostsStateCopyWithImpl(this._self, this._then);

  final _StatusPostsState _self;
  final $Res Function(_StatusPostsState) _then;

  /// Create a copy of StatusPostsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? posts = null,
    Object? isLoading = null,
    Object? failure = freezed,
  }) {
    return _then(_StatusPostsState(
      posts: null == posts
          ? _self._posts
          : posts // ignore: cast_nullable_to_non_nullable
              as List<StatusPost>,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      failure: freezed == failure
          ? _self.failure
          : failure // ignore: cast_nullable_to_non_nullable
              as Failure?,
    ));
  }

  /// Create a copy of StatusPostsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
      return null;
    }

    return $FailureCopyWith<$Res>(_self.failure!, (value) {
      return _then(_self.copyWith(failure: value));
    });
  }
}

/// @nodoc
mixin _$StatusDetailState {
  StatusPost? get post;
  List<StatusComment> get comments;
  bool get isLoading;
  Failure? get failure;

  /// Create a copy of StatusDetailState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $StatusDetailStateCopyWith<StatusDetailState> get copyWith =>
      _$StatusDetailStateCopyWithImpl<StatusDetailState>(
          this as StatusDetailState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is StatusDetailState &&
            (identical(other.post, post) || other.post == post) &&
            const DeepCollectionEquality().equals(other.comments, comments) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.failure, failure) || other.failure == failure));
  }

  @override
  int get hashCode => Object.hash(runtimeType, post,
      const DeepCollectionEquality().hash(comments), isLoading, failure);

  @override
  String toString() {
    return 'StatusDetailState(post: $post, comments: $comments, isLoading: $isLoading, failure: $failure)';
  }
}

/// @nodoc
abstract mixin class $StatusDetailStateCopyWith<$Res> {
  factory $StatusDetailStateCopyWith(
          StatusDetailState value, $Res Function(StatusDetailState) _then) =
      _$StatusDetailStateCopyWithImpl;
  @useResult
  $Res call(
      {StatusPost? post,
      List<StatusComment> comments,
      bool isLoading,
      Failure? failure});

  $StatusPostCopyWith<$Res>? get post;
  $FailureCopyWith<$Res>? get failure;
}

/// @nodoc
class _$StatusDetailStateCopyWithImpl<$Res>
    implements $StatusDetailStateCopyWith<$Res> {
  _$StatusDetailStateCopyWithImpl(this._self, this._then);

  final StatusDetailState _self;
  final $Res Function(StatusDetailState) _then;

  /// Create a copy of StatusDetailState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? post = freezed,
    Object? comments = null,
    Object? isLoading = null,
    Object? failure = freezed,
  }) {
    return _then(_self.copyWith(
      post: freezed == post
          ? _self.post
          : post // ignore: cast_nullable_to_non_nullable
              as StatusPost?,
      comments: null == comments
          ? _self.comments
          : comments // ignore: cast_nullable_to_non_nullable
              as List<StatusComment>,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      failure: freezed == failure
          ? _self.failure
          : failure // ignore: cast_nullable_to_non_nullable
              as Failure?,
    ));
  }

  /// Create a copy of StatusDetailState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StatusPostCopyWith<$Res>? get post {
    if (_self.post == null) {
      return null;
    }

    return $StatusPostCopyWith<$Res>(_self.post!, (value) {
      return _then(_self.copyWith(post: value));
    });
  }

  /// Create a copy of StatusDetailState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
      return null;
    }

    return $FailureCopyWith<$Res>(_self.failure!, (value) {
      return _then(_self.copyWith(failure: value));
    });
  }
}

/// @nodoc

class _StatusDetailState implements StatusDetailState {
  const _StatusDetailState(
      {this.post,
      final List<StatusComment> comments = const [],
      this.isLoading = false,
      this.failure})
      : _comments = comments;

  @override
  final StatusPost? post;
  final List<StatusComment> _comments;
  @override
  @JsonKey()
  List<StatusComment> get comments {
    if (_comments is EqualUnmodifiableListView) return _comments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_comments);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  final Failure? failure;

  /// Create a copy of StatusDetailState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$StatusDetailStateCopyWith<_StatusDetailState> get copyWith =>
      __$StatusDetailStateCopyWithImpl<_StatusDetailState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _StatusDetailState &&
            (identical(other.post, post) || other.post == post) &&
            const DeepCollectionEquality().equals(other._comments, _comments) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.failure, failure) || other.failure == failure));
  }

  @override
  int get hashCode => Object.hash(runtimeType, post,
      const DeepCollectionEquality().hash(_comments), isLoading, failure);

  @override
  String toString() {
    return 'StatusDetailState(post: $post, comments: $comments, isLoading: $isLoading, failure: $failure)';
  }
}

/// @nodoc
abstract mixin class _$StatusDetailStateCopyWith<$Res>
    implements $StatusDetailStateCopyWith<$Res> {
  factory _$StatusDetailStateCopyWith(
          _StatusDetailState value, $Res Function(_StatusDetailState) _then) =
      __$StatusDetailStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {StatusPost? post,
      List<StatusComment> comments,
      bool isLoading,
      Failure? failure});

  @override
  $StatusPostCopyWith<$Res>? get post;
  @override
  $FailureCopyWith<$Res>? get failure;
}

/// @nodoc
class __$StatusDetailStateCopyWithImpl<$Res>
    implements _$StatusDetailStateCopyWith<$Res> {
  __$StatusDetailStateCopyWithImpl(this._self, this._then);

  final _StatusDetailState _self;
  final $Res Function(_StatusDetailState) _then;

  /// Create a copy of StatusDetailState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? post = freezed,
    Object? comments = null,
    Object? isLoading = null,
    Object? failure = freezed,
  }) {
    return _then(_StatusDetailState(
      post: freezed == post
          ? _self.post
          : post // ignore: cast_nullable_to_non_nullable
              as StatusPost?,
      comments: null == comments
          ? _self._comments
          : comments // ignore: cast_nullable_to_non_nullable
              as List<StatusComment>,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      failure: freezed == failure
          ? _self.failure
          : failure // ignore: cast_nullable_to_non_nullable
              as Failure?,
    ));
  }

  /// Create a copy of StatusDetailState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StatusPostCopyWith<$Res>? get post {
    if (_self.post == null) {
      return null;
    }

    return $StatusPostCopyWith<$Res>(_self.post!, (value) {
      return _then(_self.copyWith(post: value));
    });
  }

  /// Create a copy of StatusDetailState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
      return null;
    }

    return $FailureCopyWith<$Res>(_self.failure!, (value) {
      return _then(_self.copyWith(failure: value));
    });
  }
}

// dart format on

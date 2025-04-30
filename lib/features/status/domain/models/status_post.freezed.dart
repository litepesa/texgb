// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'status_post.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StatusPost {
  String get id;
  String get authorId;
  String get authorName;
  String get authorImage;
  DateTime get createdAt;
  DateTime get expiresAt;
  String get content;
  List<StatusMedia> get media;
  StatusPrivacy get privacy;
  List<StatusComment> get comments;
  List<StatusReaction> get reactions;
  List<String> get viewerIds;
  int get viewCount;
  bool get isEdited;
  String? get location;
  String? get linkUrl;
  String? get linkPreviewImage;
  String? get linkPreviewTitle;
  String? get linkPreviewDescription;
  String? get shareSource;
  String? get shareSourcePostId;

  /// Create a copy of StatusPost
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $StatusPostCopyWith<StatusPost> get copyWith =>
      _$StatusPostCopyWithImpl<StatusPost>(this as StatusPost, _$identity);

  /// Serializes this StatusPost to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is StatusPost &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            (identical(other.authorName, authorName) ||
                other.authorName == authorName) &&
            (identical(other.authorImage, authorImage) ||
                other.authorImage == authorImage) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.content, content) || other.content == content) &&
            const DeepCollectionEquality().equals(other.media, media) &&
            (identical(other.privacy, privacy) || other.privacy == privacy) &&
            const DeepCollectionEquality().equals(other.comments, comments) &&
            const DeepCollectionEquality().equals(other.reactions, reactions) &&
            const DeepCollectionEquality().equals(other.viewerIds, viewerIds) &&
            (identical(other.viewCount, viewCount) ||
                other.viewCount == viewCount) &&
            (identical(other.isEdited, isEdited) ||
                other.isEdited == isEdited) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.linkUrl, linkUrl) || other.linkUrl == linkUrl) &&
            (identical(other.linkPreviewImage, linkPreviewImage) ||
                other.linkPreviewImage == linkPreviewImage) &&
            (identical(other.linkPreviewTitle, linkPreviewTitle) ||
                other.linkPreviewTitle == linkPreviewTitle) &&
            (identical(other.linkPreviewDescription, linkPreviewDescription) ||
                other.linkPreviewDescription == linkPreviewDescription) &&
            (identical(other.shareSource, shareSource) ||
                other.shareSource == shareSource) &&
            (identical(other.shareSourcePostId, shareSourcePostId) ||
                other.shareSourcePostId == shareSourcePostId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        authorId,
        authorName,
        authorImage,
        createdAt,
        expiresAt,
        content,
        const DeepCollectionEquality().hash(media),
        privacy,
        const DeepCollectionEquality().hash(comments),
        const DeepCollectionEquality().hash(reactions),
        const DeepCollectionEquality().hash(viewerIds),
        viewCount,
        isEdited,
        location,
        linkUrl,
        linkPreviewImage,
        linkPreviewTitle,
        linkPreviewDescription,
        shareSource,
        shareSourcePostId
      ]);

  @override
  String toString() {
    return 'StatusPost(id: $id, authorId: $authorId, authorName: $authorName, authorImage: $authorImage, createdAt: $createdAt, expiresAt: $expiresAt, content: $content, media: $media, privacy: $privacy, comments: $comments, reactions: $reactions, viewerIds: $viewerIds, viewCount: $viewCount, isEdited: $isEdited, location: $location, linkUrl: $linkUrl, linkPreviewImage: $linkPreviewImage, linkPreviewTitle: $linkPreviewTitle, linkPreviewDescription: $linkPreviewDescription, shareSource: $shareSource, shareSourcePostId: $shareSourcePostId)';
  }
}

/// @nodoc
abstract mixin class $StatusPostCopyWith<$Res> {
  factory $StatusPostCopyWith(
          StatusPost value, $Res Function(StatusPost) _then) =
      _$StatusPostCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String authorId,
      String authorName,
      String authorImage,
      DateTime createdAt,
      DateTime expiresAt,
      String content,
      List<StatusMedia> media,
      StatusPrivacy privacy,
      List<StatusComment> comments,
      List<StatusReaction> reactions,
      List<String> viewerIds,
      int viewCount,
      bool isEdited,
      String? location,
      String? linkUrl,
      String? linkPreviewImage,
      String? linkPreviewTitle,
      String? linkPreviewDescription,
      String? shareSource,
      String? shareSourcePostId});

  $StatusPrivacyCopyWith<$Res> get privacy;
}

/// @nodoc
class _$StatusPostCopyWithImpl<$Res> implements $StatusPostCopyWith<$Res> {
  _$StatusPostCopyWithImpl(this._self, this._then);

  final StatusPost _self;
  final $Res Function(StatusPost) _then;

  /// Create a copy of StatusPost
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? authorId = null,
    Object? authorName = null,
    Object? authorImage = null,
    Object? createdAt = null,
    Object? expiresAt = null,
    Object? content = null,
    Object? media = null,
    Object? privacy = null,
    Object? comments = null,
    Object? reactions = null,
    Object? viewerIds = null,
    Object? viewCount = null,
    Object? isEdited = null,
    Object? location = freezed,
    Object? linkUrl = freezed,
    Object? linkPreviewImage = freezed,
    Object? linkPreviewTitle = freezed,
    Object? linkPreviewDescription = freezed,
    Object? shareSource = freezed,
    Object? shareSourcePostId = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      authorId: null == authorId
          ? _self.authorId
          : authorId // ignore: cast_nullable_to_non_nullable
              as String,
      authorName: null == authorName
          ? _self.authorName
          : authorName // ignore: cast_nullable_to_non_nullable
              as String,
      authorImage: null == authorImage
          ? _self.authorImage
          : authorImage // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expiresAt: null == expiresAt
          ? _self.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      content: null == content
          ? _self.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      media: null == media
          ? _self.media
          : media // ignore: cast_nullable_to_non_nullable
              as List<StatusMedia>,
      privacy: null == privacy
          ? _self.privacy
          : privacy // ignore: cast_nullable_to_non_nullable
              as StatusPrivacy,
      comments: null == comments
          ? _self.comments
          : comments // ignore: cast_nullable_to_non_nullable
              as List<StatusComment>,
      reactions: null == reactions
          ? _self.reactions
          : reactions // ignore: cast_nullable_to_non_nullable
              as List<StatusReaction>,
      viewerIds: null == viewerIds
          ? _self.viewerIds
          : viewerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      viewCount: null == viewCount
          ? _self.viewCount
          : viewCount // ignore: cast_nullable_to_non_nullable
              as int,
      isEdited: null == isEdited
          ? _self.isEdited
          : isEdited // ignore: cast_nullable_to_non_nullable
              as bool,
      location: freezed == location
          ? _self.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
      linkUrl: freezed == linkUrl
          ? _self.linkUrl
          : linkUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      linkPreviewImage: freezed == linkPreviewImage
          ? _self.linkPreviewImage
          : linkPreviewImage // ignore: cast_nullable_to_non_nullable
              as String?,
      linkPreviewTitle: freezed == linkPreviewTitle
          ? _self.linkPreviewTitle
          : linkPreviewTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      linkPreviewDescription: freezed == linkPreviewDescription
          ? _self.linkPreviewDescription
          : linkPreviewDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      shareSource: freezed == shareSource
          ? _self.shareSource
          : shareSource // ignore: cast_nullable_to_non_nullable
              as String?,
      shareSourcePostId: freezed == shareSourcePostId
          ? _self.shareSourcePostId
          : shareSourcePostId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of StatusPost
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StatusPrivacyCopyWith<$Res> get privacy {
    return $StatusPrivacyCopyWith<$Res>(_self.privacy, (value) {
      return _then(_self.copyWith(privacy: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _StatusPost extends StatusPost {
  const _StatusPost(
      {required this.id,
      required this.authorId,
      required this.authorName,
      required this.authorImage,
      required this.createdAt,
      required this.expiresAt,
      required this.content,
      required final List<StatusMedia> media,
      required this.privacy,
      required final List<StatusComment> comments,
      required final List<StatusReaction> reactions,
      required final List<String> viewerIds,
      required this.viewCount,
      this.isEdited = false,
      this.location,
      this.linkUrl,
      this.linkPreviewImage,
      this.linkPreviewTitle,
      this.linkPreviewDescription,
      this.shareSource,
      this.shareSourcePostId})
      : _media = media,
        _comments = comments,
        _reactions = reactions,
        _viewerIds = viewerIds,
        super._();
  factory _StatusPost.fromJson(Map<String, dynamic> json) =>
      _$StatusPostFromJson(json);

  @override
  final String id;
  @override
  final String authorId;
  @override
  final String authorName;
  @override
  final String authorImage;
  @override
  final DateTime createdAt;
  @override
  final DateTime expiresAt;
  @override
  final String content;
  final List<StatusMedia> _media;
  @override
  List<StatusMedia> get media {
    if (_media is EqualUnmodifiableListView) return _media;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_media);
  }

  @override
  final StatusPrivacy privacy;
  final List<StatusComment> _comments;
  @override
  List<StatusComment> get comments {
    if (_comments is EqualUnmodifiableListView) return _comments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_comments);
  }

  final List<StatusReaction> _reactions;
  @override
  List<StatusReaction> get reactions {
    if (_reactions is EqualUnmodifiableListView) return _reactions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_reactions);
  }

  final List<String> _viewerIds;
  @override
  List<String> get viewerIds {
    if (_viewerIds is EqualUnmodifiableListView) return _viewerIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_viewerIds);
  }

  @override
  final int viewCount;
  @override
  @JsonKey()
  final bool isEdited;
  @override
  final String? location;
  @override
  final String? linkUrl;
  @override
  final String? linkPreviewImage;
  @override
  final String? linkPreviewTitle;
  @override
  final String? linkPreviewDescription;
  @override
  final String? shareSource;
  @override
  final String? shareSourcePostId;

  /// Create a copy of StatusPost
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$StatusPostCopyWith<_StatusPost> get copyWith =>
      __$StatusPostCopyWithImpl<_StatusPost>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$StatusPostToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _StatusPost &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            (identical(other.authorName, authorName) ||
                other.authorName == authorName) &&
            (identical(other.authorImage, authorImage) ||
                other.authorImage == authorImage) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.content, content) || other.content == content) &&
            const DeepCollectionEquality().equals(other._media, _media) &&
            (identical(other.privacy, privacy) || other.privacy == privacy) &&
            const DeepCollectionEquality().equals(other._comments, _comments) &&
            const DeepCollectionEquality()
                .equals(other._reactions, _reactions) &&
            const DeepCollectionEquality()
                .equals(other._viewerIds, _viewerIds) &&
            (identical(other.viewCount, viewCount) ||
                other.viewCount == viewCount) &&
            (identical(other.isEdited, isEdited) ||
                other.isEdited == isEdited) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.linkUrl, linkUrl) || other.linkUrl == linkUrl) &&
            (identical(other.linkPreviewImage, linkPreviewImage) ||
                other.linkPreviewImage == linkPreviewImage) &&
            (identical(other.linkPreviewTitle, linkPreviewTitle) ||
                other.linkPreviewTitle == linkPreviewTitle) &&
            (identical(other.linkPreviewDescription, linkPreviewDescription) ||
                other.linkPreviewDescription == linkPreviewDescription) &&
            (identical(other.shareSource, shareSource) ||
                other.shareSource == shareSource) &&
            (identical(other.shareSourcePostId, shareSourcePostId) ||
                other.shareSourcePostId == shareSourcePostId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        authorId,
        authorName,
        authorImage,
        createdAt,
        expiresAt,
        content,
        const DeepCollectionEquality().hash(_media),
        privacy,
        const DeepCollectionEquality().hash(_comments),
        const DeepCollectionEquality().hash(_reactions),
        const DeepCollectionEquality().hash(_viewerIds),
        viewCount,
        isEdited,
        location,
        linkUrl,
        linkPreviewImage,
        linkPreviewTitle,
        linkPreviewDescription,
        shareSource,
        shareSourcePostId
      ]);

  @override
  String toString() {
    return 'StatusPost(id: $id, authorId: $authorId, authorName: $authorName, authorImage: $authorImage, createdAt: $createdAt, expiresAt: $expiresAt, content: $content, media: $media, privacy: $privacy, comments: $comments, reactions: $reactions, viewerIds: $viewerIds, viewCount: $viewCount, isEdited: $isEdited, location: $location, linkUrl: $linkUrl, linkPreviewImage: $linkPreviewImage, linkPreviewTitle: $linkPreviewTitle, linkPreviewDescription: $linkPreviewDescription, shareSource: $shareSource, shareSourcePostId: $shareSourcePostId)';
  }
}

/// @nodoc
abstract mixin class _$StatusPostCopyWith<$Res>
    implements $StatusPostCopyWith<$Res> {
  factory _$StatusPostCopyWith(
          _StatusPost value, $Res Function(_StatusPost) _then) =
      __$StatusPostCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String authorId,
      String authorName,
      String authorImage,
      DateTime createdAt,
      DateTime expiresAt,
      String content,
      List<StatusMedia> media,
      StatusPrivacy privacy,
      List<StatusComment> comments,
      List<StatusReaction> reactions,
      List<String> viewerIds,
      int viewCount,
      bool isEdited,
      String? location,
      String? linkUrl,
      String? linkPreviewImage,
      String? linkPreviewTitle,
      String? linkPreviewDescription,
      String? shareSource,
      String? shareSourcePostId});

  @override
  $StatusPrivacyCopyWith<$Res> get privacy;
}

/// @nodoc
class __$StatusPostCopyWithImpl<$Res> implements _$StatusPostCopyWith<$Res> {
  __$StatusPostCopyWithImpl(this._self, this._then);

  final _StatusPost _self;
  final $Res Function(_StatusPost) _then;

  /// Create a copy of StatusPost
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? authorId = null,
    Object? authorName = null,
    Object? authorImage = null,
    Object? createdAt = null,
    Object? expiresAt = null,
    Object? content = null,
    Object? media = null,
    Object? privacy = null,
    Object? comments = null,
    Object? reactions = null,
    Object? viewerIds = null,
    Object? viewCount = null,
    Object? isEdited = null,
    Object? location = freezed,
    Object? linkUrl = freezed,
    Object? linkPreviewImage = freezed,
    Object? linkPreviewTitle = freezed,
    Object? linkPreviewDescription = freezed,
    Object? shareSource = freezed,
    Object? shareSourcePostId = freezed,
  }) {
    return _then(_StatusPost(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      authorId: null == authorId
          ? _self.authorId
          : authorId // ignore: cast_nullable_to_non_nullable
              as String,
      authorName: null == authorName
          ? _self.authorName
          : authorName // ignore: cast_nullable_to_non_nullable
              as String,
      authorImage: null == authorImage
          ? _self.authorImage
          : authorImage // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expiresAt: null == expiresAt
          ? _self.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      content: null == content
          ? _self.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      media: null == media
          ? _self._media
          : media // ignore: cast_nullable_to_non_nullable
              as List<StatusMedia>,
      privacy: null == privacy
          ? _self.privacy
          : privacy // ignore: cast_nullable_to_non_nullable
              as StatusPrivacy,
      comments: null == comments
          ? _self._comments
          : comments // ignore: cast_nullable_to_non_nullable
              as List<StatusComment>,
      reactions: null == reactions
          ? _self._reactions
          : reactions // ignore: cast_nullable_to_non_nullable
              as List<StatusReaction>,
      viewerIds: null == viewerIds
          ? _self._viewerIds
          : viewerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      viewCount: null == viewCount
          ? _self.viewCount
          : viewCount // ignore: cast_nullable_to_non_nullable
              as int,
      isEdited: null == isEdited
          ? _self.isEdited
          : isEdited // ignore: cast_nullable_to_non_nullable
              as bool,
      location: freezed == location
          ? _self.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
      linkUrl: freezed == linkUrl
          ? _self.linkUrl
          : linkUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      linkPreviewImage: freezed == linkPreviewImage
          ? _self.linkPreviewImage
          : linkPreviewImage // ignore: cast_nullable_to_non_nullable
              as String?,
      linkPreviewTitle: freezed == linkPreviewTitle
          ? _self.linkPreviewTitle
          : linkPreviewTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      linkPreviewDescription: freezed == linkPreviewDescription
          ? _self.linkPreviewDescription
          : linkPreviewDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      shareSource: freezed == shareSource
          ? _self.shareSource
          : shareSource // ignore: cast_nullable_to_non_nullable
              as String?,
      shareSourcePostId: freezed == shareSourcePostId
          ? _self.shareSourcePostId
          : shareSourcePostId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of StatusPost
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StatusPrivacyCopyWith<$Res> get privacy {
    return $StatusPrivacyCopyWith<$Res>(_self.privacy, (value) {
      return _then(_self.copyWith(privacy: value));
    });
  }
}

// dart format on

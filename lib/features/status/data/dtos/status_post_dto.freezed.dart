// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'status_post_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StatusPostDTO {
  String get id;
  String get authorId;
  String get authorName;
  String get authorImage;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  DateTime get createdAt;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  DateTime get expiresAt;
  String get content;
  List<StatusMediaDTO> get media;
  StatusPrivacyDTO get privacy;
  List<StatusCommentDTO> get comments;
  List<StatusReactionDTO> get reactions;
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

  /// Create a copy of StatusPostDTO
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $StatusPostDTOCopyWith<StatusPostDTO> get copyWith =>
      _$StatusPostDTOCopyWithImpl<StatusPostDTO>(
          this as StatusPostDTO, _$identity);

  /// Serializes this StatusPostDTO to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is StatusPostDTO &&
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
    return 'StatusPostDTO(id: $id, authorId: $authorId, authorName: $authorName, authorImage: $authorImage, createdAt: $createdAt, expiresAt: $expiresAt, content: $content, media: $media, privacy: $privacy, comments: $comments, reactions: $reactions, viewerIds: $viewerIds, viewCount: $viewCount, isEdited: $isEdited, location: $location, linkUrl: $linkUrl, linkPreviewImage: $linkPreviewImage, linkPreviewTitle: $linkPreviewTitle, linkPreviewDescription: $linkPreviewDescription, shareSource: $shareSource, shareSourcePostId: $shareSourcePostId)';
  }
}

/// @nodoc
abstract mixin class $StatusPostDTOCopyWith<$Res> {
  factory $StatusPostDTOCopyWith(
          StatusPostDTO value, $Res Function(StatusPostDTO) _then) =
      _$StatusPostDTOCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String authorId,
      String authorName,
      String authorImage,
      @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
      DateTime createdAt,
      @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
      DateTime expiresAt,
      String content,
      List<StatusMediaDTO> media,
      StatusPrivacyDTO privacy,
      List<StatusCommentDTO> comments,
      List<StatusReactionDTO> reactions,
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

  $StatusPrivacyDTOCopyWith<$Res> get privacy;
}

/// @nodoc
class _$StatusPostDTOCopyWithImpl<$Res>
    implements $StatusPostDTOCopyWith<$Res> {
  _$StatusPostDTOCopyWithImpl(this._self, this._then);

  final StatusPostDTO _self;
  final $Res Function(StatusPostDTO) _then;

  /// Create a copy of StatusPostDTO
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
              as List<StatusMediaDTO>,
      privacy: null == privacy
          ? _self.privacy
          : privacy // ignore: cast_nullable_to_non_nullable
              as StatusPrivacyDTO,
      comments: null == comments
          ? _self.comments
          : comments // ignore: cast_nullable_to_non_nullable
              as List<StatusCommentDTO>,
      reactions: null == reactions
          ? _self.reactions
          : reactions // ignore: cast_nullable_to_non_nullable
              as List<StatusReactionDTO>,
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

  /// Create a copy of StatusPostDTO
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StatusPrivacyDTOCopyWith<$Res> get privacy {
    return $StatusPrivacyDTOCopyWith<$Res>(_self.privacy, (value) {
      return _then(_self.copyWith(privacy: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _StatusPostDTO implements StatusPostDTO {
  const _StatusPostDTO(
      {required this.id,
      required this.authorId,
      required this.authorName,
      required this.authorImage,
      @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
      required this.createdAt,
      @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
      required this.expiresAt,
      required this.content,
      required final List<StatusMediaDTO> media,
      required this.privacy,
      final List<StatusCommentDTO> comments = const [],
      final List<StatusReactionDTO> reactions = const [],
      final List<String> viewerIds = const [],
      this.viewCount = 0,
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
        _viewerIds = viewerIds;
  factory _StatusPostDTO.fromJson(Map<String, dynamic> json) =>
      _$StatusPostDTOFromJson(json);

  @override
  final String id;
  @override
  final String authorId;
  @override
  final String authorName;
  @override
  final String authorImage;
  @override
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;
  @override
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime expiresAt;
  @override
  final String content;
  final List<StatusMediaDTO> _media;
  @override
  List<StatusMediaDTO> get media {
    if (_media is EqualUnmodifiableListView) return _media;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_media);
  }

  @override
  final StatusPrivacyDTO privacy;
  final List<StatusCommentDTO> _comments;
  @override
  @JsonKey()
  List<StatusCommentDTO> get comments {
    if (_comments is EqualUnmodifiableListView) return _comments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_comments);
  }

  final List<StatusReactionDTO> _reactions;
  @override
  @JsonKey()
  List<StatusReactionDTO> get reactions {
    if (_reactions is EqualUnmodifiableListView) return _reactions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_reactions);
  }

  final List<String> _viewerIds;
  @override
  @JsonKey()
  List<String> get viewerIds {
    if (_viewerIds is EqualUnmodifiableListView) return _viewerIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_viewerIds);
  }

  @override
  @JsonKey()
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

  /// Create a copy of StatusPostDTO
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$StatusPostDTOCopyWith<_StatusPostDTO> get copyWith =>
      __$StatusPostDTOCopyWithImpl<_StatusPostDTO>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$StatusPostDTOToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _StatusPostDTO &&
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
    return 'StatusPostDTO(id: $id, authorId: $authorId, authorName: $authorName, authorImage: $authorImage, createdAt: $createdAt, expiresAt: $expiresAt, content: $content, media: $media, privacy: $privacy, comments: $comments, reactions: $reactions, viewerIds: $viewerIds, viewCount: $viewCount, isEdited: $isEdited, location: $location, linkUrl: $linkUrl, linkPreviewImage: $linkPreviewImage, linkPreviewTitle: $linkPreviewTitle, linkPreviewDescription: $linkPreviewDescription, shareSource: $shareSource, shareSourcePostId: $shareSourcePostId)';
  }
}

/// @nodoc
abstract mixin class _$StatusPostDTOCopyWith<$Res>
    implements $StatusPostDTOCopyWith<$Res> {
  factory _$StatusPostDTOCopyWith(
          _StatusPostDTO value, $Res Function(_StatusPostDTO) _then) =
      __$StatusPostDTOCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String authorId,
      String authorName,
      String authorImage,
      @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
      DateTime createdAt,
      @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
      DateTime expiresAt,
      String content,
      List<StatusMediaDTO> media,
      StatusPrivacyDTO privacy,
      List<StatusCommentDTO> comments,
      List<StatusReactionDTO> reactions,
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
  $StatusPrivacyDTOCopyWith<$Res> get privacy;
}

/// @nodoc
class __$StatusPostDTOCopyWithImpl<$Res>
    implements _$StatusPostDTOCopyWith<$Res> {
  __$StatusPostDTOCopyWithImpl(this._self, this._then);

  final _StatusPostDTO _self;
  final $Res Function(_StatusPostDTO) _then;

  /// Create a copy of StatusPostDTO
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
    return _then(_StatusPostDTO(
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
              as List<StatusMediaDTO>,
      privacy: null == privacy
          ? _self.privacy
          : privacy // ignore: cast_nullable_to_non_nullable
              as StatusPrivacyDTO,
      comments: null == comments
          ? _self._comments
          : comments // ignore: cast_nullable_to_non_nullable
              as List<StatusCommentDTO>,
      reactions: null == reactions
          ? _self._reactions
          : reactions // ignore: cast_nullable_to_non_nullable
              as List<StatusReactionDTO>,
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

  /// Create a copy of StatusPostDTO
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StatusPrivacyDTOCopyWith<$Res> get privacy {
    return $StatusPrivacyDTOCopyWith<$Res>(_self.privacy, (value) {
      return _then(_self.copyWith(privacy: value));
    });
  }
}

// dart format on

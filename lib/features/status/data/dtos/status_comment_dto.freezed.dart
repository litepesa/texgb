// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'status_comment_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StatusCommentDTO {
  String get id;
  String get postId;
  String get userId;
  String get userName;
  String get userImage;
  String get content;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  DateTime get createdAt;
  bool get isEdited;
  String? get replyToCommentId;
  String? get replyToUserId;
  String? get replyToUserName;

  /// Create a copy of StatusCommentDTO
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $StatusCommentDTOCopyWith<StatusCommentDTO> get copyWith =>
      _$StatusCommentDTOCopyWithImpl<StatusCommentDTO>(
          this as StatusCommentDTO, _$identity);

  /// Serializes this StatusCommentDTO to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is StatusCommentDTO &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.postId, postId) || other.postId == postId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.userImage, userImage) ||
                other.userImage == userImage) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.isEdited, isEdited) ||
                other.isEdited == isEdited) &&
            (identical(other.replyToCommentId, replyToCommentId) ||
                other.replyToCommentId == replyToCommentId) &&
            (identical(other.replyToUserId, replyToUserId) ||
                other.replyToUserId == replyToUserId) &&
            (identical(other.replyToUserName, replyToUserName) ||
                other.replyToUserName == replyToUserName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      postId,
      userId,
      userName,
      userImage,
      content,
      createdAt,
      isEdited,
      replyToCommentId,
      replyToUserId,
      replyToUserName);

  @override
  String toString() {
    return 'StatusCommentDTO(id: $id, postId: $postId, userId: $userId, userName: $userName, userImage: $userImage, content: $content, createdAt: $createdAt, isEdited: $isEdited, replyToCommentId: $replyToCommentId, replyToUserId: $replyToUserId, replyToUserName: $replyToUserName)';
  }
}

/// @nodoc
abstract mixin class $StatusCommentDTOCopyWith<$Res> {
  factory $StatusCommentDTOCopyWith(
          StatusCommentDTO value, $Res Function(StatusCommentDTO) _then) =
      _$StatusCommentDTOCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String postId,
      String userId,
      String userName,
      String userImage,
      String content,
      @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
      DateTime createdAt,
      bool isEdited,
      String? replyToCommentId,
      String? replyToUserId,
      String? replyToUserName});
}

/// @nodoc
class _$StatusCommentDTOCopyWithImpl<$Res>
    implements $StatusCommentDTOCopyWith<$Res> {
  _$StatusCommentDTOCopyWithImpl(this._self, this._then);

  final StatusCommentDTO _self;
  final $Res Function(StatusCommentDTO) _then;

  /// Create a copy of StatusCommentDTO
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? postId = null,
    Object? userId = null,
    Object? userName = null,
    Object? userImage = null,
    Object? content = null,
    Object? createdAt = null,
    Object? isEdited = null,
    Object? replyToCommentId = freezed,
    Object? replyToUserId = freezed,
    Object? replyToUserName = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      postId: null == postId
          ? _self.postId
          : postId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      userName: null == userName
          ? _self.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String,
      userImage: null == userImage
          ? _self.userImage
          : userImage // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _self.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isEdited: null == isEdited
          ? _self.isEdited
          : isEdited // ignore: cast_nullable_to_non_nullable
              as bool,
      replyToCommentId: freezed == replyToCommentId
          ? _self.replyToCommentId
          : replyToCommentId // ignore: cast_nullable_to_non_nullable
              as String?,
      replyToUserId: freezed == replyToUserId
          ? _self.replyToUserId
          : replyToUserId // ignore: cast_nullable_to_non_nullable
              as String?,
      replyToUserName: freezed == replyToUserName
          ? _self.replyToUserName
          : replyToUserName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _StatusCommentDTO implements StatusCommentDTO {
  const _StatusCommentDTO(
      {required this.id,
      required this.postId,
      required this.userId,
      required this.userName,
      required this.userImage,
      required this.content,
      @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
      required this.createdAt,
      this.isEdited = false,
      this.replyToCommentId,
      this.replyToUserId,
      this.replyToUserName});
  factory _StatusCommentDTO.fromJson(Map<String, dynamic> json) =>
      _$StatusCommentDTOFromJson(json);

  @override
  final String id;
  @override
  final String postId;
  @override
  final String userId;
  @override
  final String userName;
  @override
  final String userImage;
  @override
  final String content;
  @override
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;
  @override
  @JsonKey()
  final bool isEdited;
  @override
  final String? replyToCommentId;
  @override
  final String? replyToUserId;
  @override
  final String? replyToUserName;

  /// Create a copy of StatusCommentDTO
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$StatusCommentDTOCopyWith<_StatusCommentDTO> get copyWith =>
      __$StatusCommentDTOCopyWithImpl<_StatusCommentDTO>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$StatusCommentDTOToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _StatusCommentDTO &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.postId, postId) || other.postId == postId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.userImage, userImage) ||
                other.userImage == userImage) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.isEdited, isEdited) ||
                other.isEdited == isEdited) &&
            (identical(other.replyToCommentId, replyToCommentId) ||
                other.replyToCommentId == replyToCommentId) &&
            (identical(other.replyToUserId, replyToUserId) ||
                other.replyToUserId == replyToUserId) &&
            (identical(other.replyToUserName, replyToUserName) ||
                other.replyToUserName == replyToUserName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      postId,
      userId,
      userName,
      userImage,
      content,
      createdAt,
      isEdited,
      replyToCommentId,
      replyToUserId,
      replyToUserName);

  @override
  String toString() {
    return 'StatusCommentDTO(id: $id, postId: $postId, userId: $userId, userName: $userName, userImage: $userImage, content: $content, createdAt: $createdAt, isEdited: $isEdited, replyToCommentId: $replyToCommentId, replyToUserId: $replyToUserId, replyToUserName: $replyToUserName)';
  }
}

/// @nodoc
abstract mixin class _$StatusCommentDTOCopyWith<$Res>
    implements $StatusCommentDTOCopyWith<$Res> {
  factory _$StatusCommentDTOCopyWith(
          _StatusCommentDTO value, $Res Function(_StatusCommentDTO) _then) =
      __$StatusCommentDTOCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String postId,
      String userId,
      String userName,
      String userImage,
      String content,
      @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
      DateTime createdAt,
      bool isEdited,
      String? replyToCommentId,
      String? replyToUserId,
      String? replyToUserName});
}

/// @nodoc
class __$StatusCommentDTOCopyWithImpl<$Res>
    implements _$StatusCommentDTOCopyWith<$Res> {
  __$StatusCommentDTOCopyWithImpl(this._self, this._then);

  final _StatusCommentDTO _self;
  final $Res Function(_StatusCommentDTO) _then;

  /// Create a copy of StatusCommentDTO
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? postId = null,
    Object? userId = null,
    Object? userName = null,
    Object? userImage = null,
    Object? content = null,
    Object? createdAt = null,
    Object? isEdited = null,
    Object? replyToCommentId = freezed,
    Object? replyToUserId = freezed,
    Object? replyToUserName = freezed,
  }) {
    return _then(_StatusCommentDTO(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      postId: null == postId
          ? _self.postId
          : postId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      userName: null == userName
          ? _self.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String,
      userImage: null == userImage
          ? _self.userImage
          : userImage // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _self.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isEdited: null == isEdited
          ? _self.isEdited
          : isEdited // ignore: cast_nullable_to_non_nullable
              as bool,
      replyToCommentId: freezed == replyToCommentId
          ? _self.replyToCommentId
          : replyToCommentId // ignore: cast_nullable_to_non_nullable
              as String?,
      replyToUserId: freezed == replyToUserId
          ? _self.replyToUserId
          : replyToUserId // ignore: cast_nullable_to_non_nullable
              as String?,
      replyToUserName: freezed == replyToUserName
          ? _self.replyToUserName
          : replyToUserName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on

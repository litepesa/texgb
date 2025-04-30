// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'status_reaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StatusReaction {
  String get id;
  String get postId;
  String get userId;
  String get userName;
  String get userImage;
  ReactionType get type;
  DateTime get createdAt;

  /// Create a copy of StatusReaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $StatusReactionCopyWith<StatusReaction> get copyWith =>
      _$StatusReactionCopyWithImpl<StatusReaction>(
          this as StatusReaction, _$identity);

  /// Serializes this StatusReaction to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is StatusReaction &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.postId, postId) || other.postId == postId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.userImage, userImage) ||
                other.userImage == userImage) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, postId, userId, userName, userImage, type, createdAt);

  @override
  String toString() {
    return 'StatusReaction(id: $id, postId: $postId, userId: $userId, userName: $userName, userImage: $userImage, type: $type, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class $StatusReactionCopyWith<$Res> {
  factory $StatusReactionCopyWith(
          StatusReaction value, $Res Function(StatusReaction) _then) =
      _$StatusReactionCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String postId,
      String userId,
      String userName,
      String userImage,
      ReactionType type,
      DateTime createdAt});
}

/// @nodoc
class _$StatusReactionCopyWithImpl<$Res>
    implements $StatusReactionCopyWith<$Res> {
  _$StatusReactionCopyWithImpl(this._self, this._then);

  final StatusReaction _self;
  final $Res Function(StatusReaction) _then;

  /// Create a copy of StatusReaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? postId = null,
    Object? userId = null,
    Object? userName = null,
    Object? userImage = null,
    Object? type = null,
    Object? createdAt = null,
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
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as ReactionType,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _StatusReaction extends StatusReaction {
  const _StatusReaction(
      {required this.id,
      required this.postId,
      required this.userId,
      required this.userName,
      required this.userImage,
      required this.type,
      required this.createdAt})
      : super._();
  factory _StatusReaction.fromJson(Map<String, dynamic> json) =>
      _$StatusReactionFromJson(json);

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
  final ReactionType type;
  @override
  final DateTime createdAt;

  /// Create a copy of StatusReaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$StatusReactionCopyWith<_StatusReaction> get copyWith =>
      __$StatusReactionCopyWithImpl<_StatusReaction>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$StatusReactionToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _StatusReaction &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.postId, postId) || other.postId == postId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.userImage, userImage) ||
                other.userImage == userImage) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, postId, userId, userName, userImage, type, createdAt);

  @override
  String toString() {
    return 'StatusReaction(id: $id, postId: $postId, userId: $userId, userName: $userName, userImage: $userImage, type: $type, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$StatusReactionCopyWith<$Res>
    implements $StatusReactionCopyWith<$Res> {
  factory _$StatusReactionCopyWith(
          _StatusReaction value, $Res Function(_StatusReaction) _then) =
      __$StatusReactionCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String postId,
      String userId,
      String userName,
      String userImage,
      ReactionType type,
      DateTime createdAt});
}

/// @nodoc
class __$StatusReactionCopyWithImpl<$Res>
    implements _$StatusReactionCopyWith<$Res> {
  __$StatusReactionCopyWithImpl(this._self, this._then);

  final _StatusReaction _self;
  final $Res Function(_StatusReaction) _then;

  /// Create a copy of StatusReaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? postId = null,
    Object? userId = null,
    Object? userName = null,
    Object? userImage = null,
    Object? type = null,
    Object? createdAt = null,
  }) {
    return _then(_StatusReaction(
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
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as ReactionType,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on

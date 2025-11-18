// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_member_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GroupMemberModel {
  String get id;
  @JsonKey(name: 'group_id')
  String get groupId;
  @JsonKey(name: 'user_id')
  String get userId;
  GroupMemberRole get role;
  @JsonKey(name: 'joined_at')
  DateTime get joinedAt; // Optional user details (populated from join query)
  @JsonKey(name: 'user_name')
  String? get userName;
  @JsonKey(name: 'user_image')
  String? get userImage;
  @JsonKey(name: 'user_phone')
  String? get userPhone;

  /// Create a copy of GroupMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GroupMemberModelCopyWith<GroupMemberModel> get copyWith =>
      _$GroupMemberModelCopyWithImpl<GroupMemberModel>(
          this as GroupMemberModel, _$identity);

  /// Serializes this GroupMemberModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GroupMemberModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.userImage, userImage) ||
                other.userImage == userImage) &&
            (identical(other.userPhone, userPhone) ||
                other.userPhone == userPhone));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, groupId, userId, role,
      joinedAt, userName, userImage, userPhone);

  @override
  String toString() {
    return 'GroupMemberModel(id: $id, groupId: $groupId, userId: $userId, role: $role, joinedAt: $joinedAt, userName: $userName, userImage: $userImage, userPhone: $userPhone)';
  }
}

/// @nodoc
abstract mixin class $GroupMemberModelCopyWith<$Res> {
  factory $GroupMemberModelCopyWith(
          GroupMemberModel value, $Res Function(GroupMemberModel) _then) =
      _$GroupMemberModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'group_id') String groupId,
      @JsonKey(name: 'user_id') String userId,
      GroupMemberRole role,
      @JsonKey(name: 'joined_at') DateTime joinedAt,
      @JsonKey(name: 'user_name') String? userName,
      @JsonKey(name: 'user_image') String? userImage,
      @JsonKey(name: 'user_phone') String? userPhone});
}

/// @nodoc
class _$GroupMemberModelCopyWithImpl<$Res>
    implements $GroupMemberModelCopyWith<$Res> {
  _$GroupMemberModelCopyWithImpl(this._self, this._then);

  final GroupMemberModel _self;
  final $Res Function(GroupMemberModel) _then;

  /// Create a copy of GroupMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupId = null,
    Object? userId = null,
    Object? role = null,
    Object? joinedAt = null,
    Object? userName = freezed,
    Object? userImage = freezed,
    Object? userPhone = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _self.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _self.role
          : role // ignore: cast_nullable_to_non_nullable
              as GroupMemberRole,
      joinedAt: null == joinedAt
          ? _self.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      userName: freezed == userName
          ? _self.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String?,
      userImage: freezed == userImage
          ? _self.userImage
          : userImage // ignore: cast_nullable_to_non_nullable
              as String?,
      userPhone: freezed == userPhone
          ? _self.userPhone
          : userPhone // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _GroupMemberModel implements GroupMemberModel {
  const _GroupMemberModel(
      {required this.id,
      @JsonKey(name: 'group_id') required this.groupId,
      @JsonKey(name: 'user_id') required this.userId,
      required this.role,
      @JsonKey(name: 'joined_at') required this.joinedAt,
      @JsonKey(name: 'user_name') this.userName,
      @JsonKey(name: 'user_image') this.userImage,
      @JsonKey(name: 'user_phone') this.userPhone});
  factory _GroupMemberModel.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberModelFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'group_id')
  final String groupId;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  final GroupMemberRole role;
  @override
  @JsonKey(name: 'joined_at')
  final DateTime joinedAt;
// Optional user details (populated from join query)
  @override
  @JsonKey(name: 'user_name')
  final String? userName;
  @override
  @JsonKey(name: 'user_image')
  final String? userImage;
  @override
  @JsonKey(name: 'user_phone')
  final String? userPhone;

  /// Create a copy of GroupMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GroupMemberModelCopyWith<_GroupMemberModel> get copyWith =>
      __$GroupMemberModelCopyWithImpl<_GroupMemberModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GroupMemberModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GroupMemberModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.userImage, userImage) ||
                other.userImage == userImage) &&
            (identical(other.userPhone, userPhone) ||
                other.userPhone == userPhone));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, groupId, userId, role,
      joinedAt, userName, userImage, userPhone);

  @override
  String toString() {
    return 'GroupMemberModel(id: $id, groupId: $groupId, userId: $userId, role: $role, joinedAt: $joinedAt, userName: $userName, userImage: $userImage, userPhone: $userPhone)';
  }
}

/// @nodoc
abstract mixin class _$GroupMemberModelCopyWith<$Res>
    implements $GroupMemberModelCopyWith<$Res> {
  factory _$GroupMemberModelCopyWith(
          _GroupMemberModel value, $Res Function(_GroupMemberModel) _then) =
      __$GroupMemberModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'group_id') String groupId,
      @JsonKey(name: 'user_id') String userId,
      GroupMemberRole role,
      @JsonKey(name: 'joined_at') DateTime joinedAt,
      @JsonKey(name: 'user_name') String? userName,
      @JsonKey(name: 'user_image') String? userImage,
      @JsonKey(name: 'user_phone') String? userPhone});
}

/// @nodoc
class __$GroupMemberModelCopyWithImpl<$Res>
    implements _$GroupMemberModelCopyWith<$Res> {
  __$GroupMemberModelCopyWithImpl(this._self, this._then);

  final _GroupMemberModel _self;
  final $Res Function(_GroupMemberModel) _then;

  /// Create a copy of GroupMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? groupId = null,
    Object? userId = null,
    Object? role = null,
    Object? joinedAt = null,
    Object? userName = freezed,
    Object? userImage = freezed,
    Object? userPhone = freezed,
  }) {
    return _then(_GroupMemberModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _self.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _self.role
          : role // ignore: cast_nullable_to_non_nullable
              as GroupMemberRole,
      joinedAt: null == joinedAt
          ? _self.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      userName: freezed == userName
          ? _self.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String?,
      userImage: freezed == userImage
          ? _self.userImage
          : userImage // ignore: cast_nullable_to_non_nullable
              as String?,
      userPhone: freezed == userPhone
          ? _self.userPhone
          : userPhone // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on

// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GroupModel {
  String get id;
  String get name;
  String get description;
  @JsonKey(name: 'group_image_url')
  String? get groupImageUrl;
  @JsonKey(name: 'creator_id')
  String get creatorId;
  @JsonKey(name: 'member_count')
  int get memberCount;
  @JsonKey(name: 'max_members')
  int get maxMembers;
  @JsonKey(name: 'last_message_text')
  String? get lastMessageText;
  @JsonKey(name: 'last_message_at')
  DateTime? get lastMessageAt;
  @JsonKey(name: 'is_active')
  bool get isActive;
  @JsonKey(name: 'inserted_at')
  DateTime? get insertedAt;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of GroupModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GroupModelCopyWith<GroupModel> get copyWith =>
      _$GroupModelCopyWithImpl<GroupModel>(this as GroupModel, _$identity);

  /// Serializes this GroupModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GroupModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.groupImageUrl, groupImageUrl) ||
                other.groupImageUrl == groupImageUrl) &&
            (identical(other.creatorId, creatorId) ||
                other.creatorId == creatorId) &&
            (identical(other.memberCount, memberCount) ||
                other.memberCount == memberCount) &&
            (identical(other.maxMembers, maxMembers) ||
                other.maxMembers == maxMembers) &&
            (identical(other.lastMessageText, lastMessageText) ||
                other.lastMessageText == lastMessageText) &&
            (identical(other.lastMessageAt, lastMessageAt) ||
                other.lastMessageAt == lastMessageAt) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.insertedAt, insertedAt) ||
                other.insertedAt == insertedAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      description,
      groupImageUrl,
      creatorId,
      memberCount,
      maxMembers,
      lastMessageText,
      lastMessageAt,
      isActive,
      insertedAt,
      updatedAt);

  @override
  String toString() {
    return 'GroupModel(id: $id, name: $name, description: $description, groupImageUrl: $groupImageUrl, creatorId: $creatorId, memberCount: $memberCount, maxMembers: $maxMembers, lastMessageText: $lastMessageText, lastMessageAt: $lastMessageAt, isActive: $isActive, insertedAt: $insertedAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $GroupModelCopyWith<$Res> {
  factory $GroupModelCopyWith(
          GroupModel value, $Res Function(GroupModel) _then) =
      _$GroupModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      @JsonKey(name: 'group_image_url') String? groupImageUrl,
      @JsonKey(name: 'creator_id') String creatorId,
      @JsonKey(name: 'member_count') int memberCount,
      @JsonKey(name: 'max_members') int maxMembers,
      @JsonKey(name: 'last_message_text') String? lastMessageText,
      @JsonKey(name: 'last_message_at') DateTime? lastMessageAt,
      @JsonKey(name: 'is_active') bool isActive,
      @JsonKey(name: 'inserted_at') DateTime? insertedAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$GroupModelCopyWithImpl<$Res> implements $GroupModelCopyWith<$Res> {
  _$GroupModelCopyWithImpl(this._self, this._then);

  final GroupModel _self;
  final $Res Function(GroupModel) _then;

  /// Create a copy of GroupModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? groupImageUrl = freezed,
    Object? creatorId = null,
    Object? memberCount = null,
    Object? maxMembers = null,
    Object? lastMessageText = freezed,
    Object? lastMessageAt = freezed,
    Object? isActive = null,
    Object? insertedAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      groupImageUrl: freezed == groupImageUrl
          ? _self.groupImageUrl
          : groupImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      creatorId: null == creatorId
          ? _self.creatorId
          : creatorId // ignore: cast_nullable_to_non_nullable
              as String,
      memberCount: null == memberCount
          ? _self.memberCount
          : memberCount // ignore: cast_nullable_to_non_nullable
              as int,
      maxMembers: null == maxMembers
          ? _self.maxMembers
          : maxMembers // ignore: cast_nullable_to_non_nullable
              as int,
      lastMessageText: freezed == lastMessageText
          ? _self.lastMessageText
          : lastMessageText // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessageAt: freezed == lastMessageAt
          ? _self.lastMessageAt
          : lastMessageAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isActive: null == isActive
          ? _self.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      insertedAt: freezed == insertedAt
          ? _self.insertedAt
          : insertedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _GroupModel implements GroupModel {
  const _GroupModel(
      {required this.id,
      required this.name,
      required this.description,
      @JsonKey(name: 'group_image_url') this.groupImageUrl,
      @JsonKey(name: 'creator_id') required this.creatorId,
      @JsonKey(name: 'member_count') this.memberCount = 0,
      @JsonKey(name: 'max_members') this.maxMembers = 256,
      @JsonKey(name: 'last_message_text') this.lastMessageText,
      @JsonKey(name: 'last_message_at') this.lastMessageAt,
      @JsonKey(name: 'is_active') this.isActive = true,
      @JsonKey(name: 'inserted_at') this.insertedAt,
      @JsonKey(name: 'updated_at') this.updatedAt});
  factory _GroupModel.fromJson(Map<String, dynamic> json) =>
      _$GroupModelFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  @JsonKey(name: 'group_image_url')
  final String? groupImageUrl;
  @override
  @JsonKey(name: 'creator_id')
  final String creatorId;
  @override
  @JsonKey(name: 'member_count')
  final int memberCount;
  @override
  @JsonKey(name: 'max_members')
  final int maxMembers;
  @override
  @JsonKey(name: 'last_message_text')
  final String? lastMessageText;
  @override
  @JsonKey(name: 'last_message_at')
  final DateTime? lastMessageAt;
  @override
  @JsonKey(name: 'is_active')
  final bool isActive;
  @override
  @JsonKey(name: 'inserted_at')
  final DateTime? insertedAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  /// Create a copy of GroupModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GroupModelCopyWith<_GroupModel> get copyWith =>
      __$GroupModelCopyWithImpl<_GroupModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GroupModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GroupModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.groupImageUrl, groupImageUrl) ||
                other.groupImageUrl == groupImageUrl) &&
            (identical(other.creatorId, creatorId) ||
                other.creatorId == creatorId) &&
            (identical(other.memberCount, memberCount) ||
                other.memberCount == memberCount) &&
            (identical(other.maxMembers, maxMembers) ||
                other.maxMembers == maxMembers) &&
            (identical(other.lastMessageText, lastMessageText) ||
                other.lastMessageText == lastMessageText) &&
            (identical(other.lastMessageAt, lastMessageAt) ||
                other.lastMessageAt == lastMessageAt) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.insertedAt, insertedAt) ||
                other.insertedAt == insertedAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      description,
      groupImageUrl,
      creatorId,
      memberCount,
      maxMembers,
      lastMessageText,
      lastMessageAt,
      isActive,
      insertedAt,
      updatedAt);

  @override
  String toString() {
    return 'GroupModel(id: $id, name: $name, description: $description, groupImageUrl: $groupImageUrl, creatorId: $creatorId, memberCount: $memberCount, maxMembers: $maxMembers, lastMessageText: $lastMessageText, lastMessageAt: $lastMessageAt, isActive: $isActive, insertedAt: $insertedAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$GroupModelCopyWith<$Res>
    implements $GroupModelCopyWith<$Res> {
  factory _$GroupModelCopyWith(
          _GroupModel value, $Res Function(_GroupModel) _then) =
      __$GroupModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      @JsonKey(name: 'group_image_url') String? groupImageUrl,
      @JsonKey(name: 'creator_id') String creatorId,
      @JsonKey(name: 'member_count') int memberCount,
      @JsonKey(name: 'max_members') int maxMembers,
      @JsonKey(name: 'last_message_text') String? lastMessageText,
      @JsonKey(name: 'last_message_at') DateTime? lastMessageAt,
      @JsonKey(name: 'is_active') bool isActive,
      @JsonKey(name: 'inserted_at') DateTime? insertedAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class __$GroupModelCopyWithImpl<$Res> implements _$GroupModelCopyWith<$Res> {
  __$GroupModelCopyWithImpl(this._self, this._then);

  final _GroupModel _self;
  final $Res Function(_GroupModel) _then;

  /// Create a copy of GroupModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? groupImageUrl = freezed,
    Object? creatorId = null,
    Object? memberCount = null,
    Object? maxMembers = null,
    Object? lastMessageText = freezed,
    Object? lastMessageAt = freezed,
    Object? isActive = null,
    Object? insertedAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_GroupModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      groupImageUrl: freezed == groupImageUrl
          ? _self.groupImageUrl
          : groupImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      creatorId: null == creatorId
          ? _self.creatorId
          : creatorId // ignore: cast_nullable_to_non_nullable
              as String,
      memberCount: null == memberCount
          ? _self.memberCount
          : memberCount // ignore: cast_nullable_to_non_nullable
              as int,
      maxMembers: null == maxMembers
          ? _self.maxMembers
          : maxMembers // ignore: cast_nullable_to_non_nullable
              as int,
      lastMessageText: freezed == lastMessageText
          ? _self.lastMessageText
          : lastMessageText // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessageAt: freezed == lastMessageAt
          ? _self.lastMessageAt
          : lastMessageAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isActive: null == isActive
          ? _self.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      insertedAt: freezed == insertedAt
          ? _self.insertedAt
          : insertedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on

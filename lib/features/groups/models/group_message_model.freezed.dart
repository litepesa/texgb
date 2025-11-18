// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_message_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GroupMessageModel {
  String get id;
  @JsonKey(name: 'group_id')
  String get groupId;
  @JsonKey(name: 'sender_id')
  String get senderId;
  @JsonKey(name: 'message_text')
  String get messageText;
  @JsonKey(name: 'media_url')
  String? get mediaUrl;
  @JsonKey(name: 'media_type')
  MessageMediaType get mediaType;
  @JsonKey(name: 'read_by')
  List<String> get readBy;
  @JsonKey(name: 'inserted_at')
  DateTime get insertedAt;
  @JsonKey(name: 'updated_at')
  DateTime?
      get updatedAt; // Optional sender details (populated from join query)
  @JsonKey(name: 'sender_name')
  String? get senderName;
  @JsonKey(name: 'sender_image')
  String? get senderImage;

  /// Create a copy of GroupMessageModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GroupMessageModelCopyWith<GroupMessageModel> get copyWith =>
      _$GroupMessageModelCopyWithImpl<GroupMessageModel>(
          this as GroupMessageModel, _$identity);

  /// Serializes this GroupMessageModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GroupMessageModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.messageText, messageText) ||
                other.messageText == messageText) &&
            (identical(other.mediaUrl, mediaUrl) ||
                other.mediaUrl == mediaUrl) &&
            (identical(other.mediaType, mediaType) ||
                other.mediaType == mediaType) &&
            const DeepCollectionEquality().equals(other.readBy, readBy) &&
            (identical(other.insertedAt, insertedAt) ||
                other.insertedAt == insertedAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.senderName, senderName) ||
                other.senderName == senderName) &&
            (identical(other.senderImage, senderImage) ||
                other.senderImage == senderImage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      groupId,
      senderId,
      messageText,
      mediaUrl,
      mediaType,
      const DeepCollectionEquality().hash(readBy),
      insertedAt,
      updatedAt,
      senderName,
      senderImage);

  @override
  String toString() {
    return 'GroupMessageModel(id: $id, groupId: $groupId, senderId: $senderId, messageText: $messageText, mediaUrl: $mediaUrl, mediaType: $mediaType, readBy: $readBy, insertedAt: $insertedAt, updatedAt: $updatedAt, senderName: $senderName, senderImage: $senderImage)';
  }
}

/// @nodoc
abstract mixin class $GroupMessageModelCopyWith<$Res> {
  factory $GroupMessageModelCopyWith(
          GroupMessageModel value, $Res Function(GroupMessageModel) _then) =
      _$GroupMessageModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'group_id') String groupId,
      @JsonKey(name: 'sender_id') String senderId,
      @JsonKey(name: 'message_text') String messageText,
      @JsonKey(name: 'media_url') String? mediaUrl,
      @JsonKey(name: 'media_type') MessageMediaType mediaType,
      @JsonKey(name: 'read_by') List<String> readBy,
      @JsonKey(name: 'inserted_at') DateTime insertedAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      @JsonKey(name: 'sender_name') String? senderName,
      @JsonKey(name: 'sender_image') String? senderImage});
}

/// @nodoc
class _$GroupMessageModelCopyWithImpl<$Res>
    implements $GroupMessageModelCopyWith<$Res> {
  _$GroupMessageModelCopyWithImpl(this._self, this._then);

  final GroupMessageModel _self;
  final $Res Function(GroupMessageModel) _then;

  /// Create a copy of GroupMessageModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupId = null,
    Object? senderId = null,
    Object? messageText = null,
    Object? mediaUrl = freezed,
    Object? mediaType = null,
    Object? readBy = null,
    Object? insertedAt = null,
    Object? updatedAt = freezed,
    Object? senderName = freezed,
    Object? senderImage = freezed,
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
      senderId: null == senderId
          ? _self.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      messageText: null == messageText
          ? _self.messageText
          : messageText // ignore: cast_nullable_to_non_nullable
              as String,
      mediaUrl: freezed == mediaUrl
          ? _self.mediaUrl
          : mediaUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      mediaType: null == mediaType
          ? _self.mediaType
          : mediaType // ignore: cast_nullable_to_non_nullable
              as MessageMediaType,
      readBy: null == readBy
          ? _self.readBy
          : readBy // ignore: cast_nullable_to_non_nullable
              as List<String>,
      insertedAt: null == insertedAt
          ? _self.insertedAt
          : insertedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      senderName: freezed == senderName
          ? _self.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      senderImage: freezed == senderImage
          ? _self.senderImage
          : senderImage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _GroupMessageModel implements GroupMessageModel {
  const _GroupMessageModel(
      {required this.id,
      @JsonKey(name: 'group_id') required this.groupId,
      @JsonKey(name: 'sender_id') required this.senderId,
      @JsonKey(name: 'message_text') required this.messageText,
      @JsonKey(name: 'media_url') this.mediaUrl,
      @JsonKey(name: 'media_type') this.mediaType = MessageMediaType.text,
      @JsonKey(name: 'read_by') final List<String> readBy = const [],
      @JsonKey(name: 'inserted_at') required this.insertedAt,
      @JsonKey(name: 'updated_at') this.updatedAt,
      @JsonKey(name: 'sender_name') this.senderName,
      @JsonKey(name: 'sender_image') this.senderImage})
      : _readBy = readBy;
  factory _GroupMessageModel.fromJson(Map<String, dynamic> json) =>
      _$GroupMessageModelFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'group_id')
  final String groupId;
  @override
  @JsonKey(name: 'sender_id')
  final String senderId;
  @override
  @JsonKey(name: 'message_text')
  final String messageText;
  @override
  @JsonKey(name: 'media_url')
  final String? mediaUrl;
  @override
  @JsonKey(name: 'media_type')
  final MessageMediaType mediaType;
  final List<String> _readBy;
  @override
  @JsonKey(name: 'read_by')
  List<String> get readBy {
    if (_readBy is EqualUnmodifiableListView) return _readBy;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_readBy);
  }

  @override
  @JsonKey(name: 'inserted_at')
  final DateTime insertedAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
// Optional sender details (populated from join query)
  @override
  @JsonKey(name: 'sender_name')
  final String? senderName;
  @override
  @JsonKey(name: 'sender_image')
  final String? senderImage;

  /// Create a copy of GroupMessageModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GroupMessageModelCopyWith<_GroupMessageModel> get copyWith =>
      __$GroupMessageModelCopyWithImpl<_GroupMessageModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GroupMessageModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GroupMessageModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.messageText, messageText) ||
                other.messageText == messageText) &&
            (identical(other.mediaUrl, mediaUrl) ||
                other.mediaUrl == mediaUrl) &&
            (identical(other.mediaType, mediaType) ||
                other.mediaType == mediaType) &&
            const DeepCollectionEquality().equals(other._readBy, _readBy) &&
            (identical(other.insertedAt, insertedAt) ||
                other.insertedAt == insertedAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.senderName, senderName) ||
                other.senderName == senderName) &&
            (identical(other.senderImage, senderImage) ||
                other.senderImage == senderImage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      groupId,
      senderId,
      messageText,
      mediaUrl,
      mediaType,
      const DeepCollectionEquality().hash(_readBy),
      insertedAt,
      updatedAt,
      senderName,
      senderImage);

  @override
  String toString() {
    return 'GroupMessageModel(id: $id, groupId: $groupId, senderId: $senderId, messageText: $messageText, mediaUrl: $mediaUrl, mediaType: $mediaType, readBy: $readBy, insertedAt: $insertedAt, updatedAt: $updatedAt, senderName: $senderName, senderImage: $senderImage)';
  }
}

/// @nodoc
abstract mixin class _$GroupMessageModelCopyWith<$Res>
    implements $GroupMessageModelCopyWith<$Res> {
  factory _$GroupMessageModelCopyWith(
          _GroupMessageModel value, $Res Function(_GroupMessageModel) _then) =
      __$GroupMessageModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'group_id') String groupId,
      @JsonKey(name: 'sender_id') String senderId,
      @JsonKey(name: 'message_text') String messageText,
      @JsonKey(name: 'media_url') String? mediaUrl,
      @JsonKey(name: 'media_type') MessageMediaType mediaType,
      @JsonKey(name: 'read_by') List<String> readBy,
      @JsonKey(name: 'inserted_at') DateTime insertedAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      @JsonKey(name: 'sender_name') String? senderName,
      @JsonKey(name: 'sender_image') String? senderImage});
}

/// @nodoc
class __$GroupMessageModelCopyWithImpl<$Res>
    implements _$GroupMessageModelCopyWith<$Res> {
  __$GroupMessageModelCopyWithImpl(this._self, this._then);

  final _GroupMessageModel _self;
  final $Res Function(_GroupMessageModel) _then;

  /// Create a copy of GroupMessageModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? groupId = null,
    Object? senderId = null,
    Object? messageText = null,
    Object? mediaUrl = freezed,
    Object? mediaType = null,
    Object? readBy = null,
    Object? insertedAt = null,
    Object? updatedAt = freezed,
    Object? senderName = freezed,
    Object? senderImage = freezed,
  }) {
    return _then(_GroupMessageModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _self.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _self.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      messageText: null == messageText
          ? _self.messageText
          : messageText // ignore: cast_nullable_to_non_nullable
              as String,
      mediaUrl: freezed == mediaUrl
          ? _self.mediaUrl
          : mediaUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      mediaType: null == mediaType
          ? _self.mediaType
          : mediaType // ignore: cast_nullable_to_non_nullable
              as MessageMediaType,
      readBy: null == readBy
          ? _self._readBy
          : readBy // ignore: cast_nullable_to_non_nullable
              as List<String>,
      insertedAt: null == insertedAt
          ? _self.insertedAt
          : insertedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      senderName: freezed == senderName
          ? _self.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      senderImage: freezed == senderImage
          ? _self.senderImage
          : senderImage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on

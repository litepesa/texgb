// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'status_media.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StatusMedia {
  String get id;
  String get url;
  MediaType get type;
  String? get thumbnailUrl;
  int? get width;
  int? get height;
  int? get duration; // for videos: duration in seconds
  int? get size;

  /// Create a copy of StatusMedia
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $StatusMediaCopyWith<StatusMedia> get copyWith =>
      _$StatusMediaCopyWithImpl<StatusMedia>(this as StatusMedia, _$identity);

  /// Serializes this StatusMedia to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is StatusMedia &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.size, size) || other.size == size));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, url, type, thumbnailUrl, width, height, duration, size);

  @override
  String toString() {
    return 'StatusMedia(id: $id, url: $url, type: $type, thumbnailUrl: $thumbnailUrl, width: $width, height: $height, duration: $duration, size: $size)';
  }
}

/// @nodoc
abstract mixin class $StatusMediaCopyWith<$Res> {
  factory $StatusMediaCopyWith(
          StatusMedia value, $Res Function(StatusMedia) _then) =
      _$StatusMediaCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String url,
      MediaType type,
      String? thumbnailUrl,
      int? width,
      int? height,
      int? duration,
      int? size});
}

/// @nodoc
class _$StatusMediaCopyWithImpl<$Res> implements $StatusMediaCopyWith<$Res> {
  _$StatusMediaCopyWithImpl(this._self, this._then);

  final StatusMedia _self;
  final $Res Function(StatusMedia) _then;

  /// Create a copy of StatusMedia
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? url = null,
    Object? type = null,
    Object? thumbnailUrl = freezed,
    Object? width = freezed,
    Object? height = freezed,
    Object? duration = freezed,
    Object? size = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as MediaType,
      thumbnailUrl: freezed == thumbnailUrl
          ? _self.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      width: freezed == width
          ? _self.width
          : width // ignore: cast_nullable_to_non_nullable
              as int?,
      height: freezed == height
          ? _self.height
          : height // ignore: cast_nullable_to_non_nullable
              as int?,
      duration: freezed == duration
          ? _self.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int?,
      size: freezed == size
          ? _self.size
          : size // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _StatusMedia extends StatusMedia {
  const _StatusMedia(
      {required this.id,
      required this.url,
      required this.type,
      this.thumbnailUrl,
      this.width,
      this.height,
      this.duration,
      this.size})
      : super._();
  factory _StatusMedia.fromJson(Map<String, dynamic> json) =>
      _$StatusMediaFromJson(json);

  @override
  final String id;
  @override
  final String url;
  @override
  final MediaType type;
  @override
  final String? thumbnailUrl;
  @override
  final int? width;
  @override
  final int? height;
  @override
  final int? duration;
// for videos: duration in seconds
  @override
  final int? size;

  /// Create a copy of StatusMedia
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$StatusMediaCopyWith<_StatusMedia> get copyWith =>
      __$StatusMediaCopyWithImpl<_StatusMedia>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$StatusMediaToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _StatusMedia &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.size, size) || other.size == size));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, url, type, thumbnailUrl, width, height, duration, size);

  @override
  String toString() {
    return 'StatusMedia(id: $id, url: $url, type: $type, thumbnailUrl: $thumbnailUrl, width: $width, height: $height, duration: $duration, size: $size)';
  }
}

/// @nodoc
abstract mixin class _$StatusMediaCopyWith<$Res>
    implements $StatusMediaCopyWith<$Res> {
  factory _$StatusMediaCopyWith(
          _StatusMedia value, $Res Function(_StatusMedia) _then) =
      __$StatusMediaCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String url,
      MediaType type,
      String? thumbnailUrl,
      int? width,
      int? height,
      int? duration,
      int? size});
}

/// @nodoc
class __$StatusMediaCopyWithImpl<$Res> implements _$StatusMediaCopyWith<$Res> {
  __$StatusMediaCopyWithImpl(this._self, this._then);

  final _StatusMedia _self;
  final $Res Function(_StatusMedia) _then;

  /// Create a copy of StatusMedia
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? url = null,
    Object? type = null,
    Object? thumbnailUrl = freezed,
    Object? width = freezed,
    Object? height = freezed,
    Object? duration = freezed,
    Object? size = freezed,
  }) {
    return _then(_StatusMedia(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as MediaType,
      thumbnailUrl: freezed == thumbnailUrl
          ? _self.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      width: freezed == width
          ? _self.width
          : width // ignore: cast_nullable_to_non_nullable
              as int?,
      height: freezed == height
          ? _self.height
          : height // ignore: cast_nullable_to_non_nullable
              as int?,
      duration: freezed == duration
          ? _self.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int?,
      size: freezed == size
          ? _self.size
          : size // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on

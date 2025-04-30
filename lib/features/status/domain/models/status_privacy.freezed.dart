// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'status_privacy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StatusPrivacy {
  PrivacyType get type;
  List<String> get includedUserIds;
  List<String> get excludedUserIds;
  bool get hideViewCount;

  /// Create a copy of StatusPrivacy
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $StatusPrivacyCopyWith<StatusPrivacy> get copyWith =>
      _$StatusPrivacyCopyWithImpl<StatusPrivacy>(
          this as StatusPrivacy, _$identity);

  /// Serializes this StatusPrivacy to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is StatusPrivacy &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality()
                .equals(other.includedUserIds, includedUserIds) &&
            const DeepCollectionEquality()
                .equals(other.excludedUserIds, excludedUserIds) &&
            (identical(other.hideViewCount, hideViewCount) ||
                other.hideViewCount == hideViewCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      type,
      const DeepCollectionEquality().hash(includedUserIds),
      const DeepCollectionEquality().hash(excludedUserIds),
      hideViewCount);

  @override
  String toString() {
    return 'StatusPrivacy(type: $type, includedUserIds: $includedUserIds, excludedUserIds: $excludedUserIds, hideViewCount: $hideViewCount)';
  }
}

/// @nodoc
abstract mixin class $StatusPrivacyCopyWith<$Res> {
  factory $StatusPrivacyCopyWith(
          StatusPrivacy value, $Res Function(StatusPrivacy) _then) =
      _$StatusPrivacyCopyWithImpl;
  @useResult
  $Res call(
      {PrivacyType type,
      List<String> includedUserIds,
      List<String> excludedUserIds,
      bool hideViewCount});
}

/// @nodoc
class _$StatusPrivacyCopyWithImpl<$Res>
    implements $StatusPrivacyCopyWith<$Res> {
  _$StatusPrivacyCopyWithImpl(this._self, this._then);

  final StatusPrivacy _self;
  final $Res Function(StatusPrivacy) _then;

  /// Create a copy of StatusPrivacy
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? includedUserIds = null,
    Object? excludedUserIds = null,
    Object? hideViewCount = null,
  }) {
    return _then(_self.copyWith(
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as PrivacyType,
      includedUserIds: null == includedUserIds
          ? _self.includedUserIds
          : includedUserIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      excludedUserIds: null == excludedUserIds
          ? _self.excludedUserIds
          : excludedUserIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      hideViewCount: null == hideViewCount
          ? _self.hideViewCount
          : hideViewCount // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _StatusPrivacy extends StatusPrivacy {
  const _StatusPrivacy(
      {required this.type,
      final List<String> includedUserIds = const [],
      final List<String> excludedUserIds = const [],
      this.hideViewCount = false})
      : _includedUserIds = includedUserIds,
        _excludedUserIds = excludedUserIds,
        super._();
  factory _StatusPrivacy.fromJson(Map<String, dynamic> json) =>
      _$StatusPrivacyFromJson(json);

  @override
  final PrivacyType type;
  final List<String> _includedUserIds;
  @override
  @JsonKey()
  List<String> get includedUserIds {
    if (_includedUserIds is EqualUnmodifiableListView) return _includedUserIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_includedUserIds);
  }

  final List<String> _excludedUserIds;
  @override
  @JsonKey()
  List<String> get excludedUserIds {
    if (_excludedUserIds is EqualUnmodifiableListView) return _excludedUserIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_excludedUserIds);
  }

  @override
  @JsonKey()
  final bool hideViewCount;

  /// Create a copy of StatusPrivacy
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$StatusPrivacyCopyWith<_StatusPrivacy> get copyWith =>
      __$StatusPrivacyCopyWithImpl<_StatusPrivacy>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$StatusPrivacyToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _StatusPrivacy &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality()
                .equals(other._includedUserIds, _includedUserIds) &&
            const DeepCollectionEquality()
                .equals(other._excludedUserIds, _excludedUserIds) &&
            (identical(other.hideViewCount, hideViewCount) ||
                other.hideViewCount == hideViewCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      type,
      const DeepCollectionEquality().hash(_includedUserIds),
      const DeepCollectionEquality().hash(_excludedUserIds),
      hideViewCount);

  @override
  String toString() {
    return 'StatusPrivacy(type: $type, includedUserIds: $includedUserIds, excludedUserIds: $excludedUserIds, hideViewCount: $hideViewCount)';
  }
}

/// @nodoc
abstract mixin class _$StatusPrivacyCopyWith<$Res>
    implements $StatusPrivacyCopyWith<$Res> {
  factory _$StatusPrivacyCopyWith(
          _StatusPrivacy value, $Res Function(_StatusPrivacy) _then) =
      __$StatusPrivacyCopyWithImpl;
  @override
  @useResult
  $Res call(
      {PrivacyType type,
      List<String> includedUserIds,
      List<String> excludedUserIds,
      bool hideViewCount});
}

/// @nodoc
class __$StatusPrivacyCopyWithImpl<$Res>
    implements _$StatusPrivacyCopyWith<$Res> {
  __$StatusPrivacyCopyWithImpl(this._self, this._then);

  final _StatusPrivacy _self;
  final $Res Function(_StatusPrivacy) _then;

  /// Create a copy of StatusPrivacy
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? type = null,
    Object? includedUserIds = null,
    Object? excludedUserIds = null,
    Object? hideViewCount = null,
  }) {
    return _then(_StatusPrivacy(
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as PrivacyType,
      includedUserIds: null == includedUserIds
          ? _self._includedUserIds
          : includedUserIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      excludedUserIds: null == excludedUserIds
          ? _self._excludedUserIds
          : excludedUserIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      hideViewCount: null == hideViewCount
          ? _self.hideViewCount
          : hideViewCount // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on

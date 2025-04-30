// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'failures.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Failure {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is Failure);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'Failure()';
  }
}

/// @nodoc
class $FailureCopyWith<$Res> {
  $FailureCopyWith(Failure _, $Res Function(Failure) __);
}

/// @nodoc

class ServerFailure implements Failure {
  const ServerFailure([this.message]);

  final String? message;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ServerFailureCopyWith<ServerFailure> get copyWith =>
      _$ServerFailureCopyWithImpl<ServerFailure>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ServerFailure &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() {
    return 'Failure.serverError(message: $message)';
  }
}

/// @nodoc
abstract mixin class $ServerFailureCopyWith<$Res>
    implements $FailureCopyWith<$Res> {
  factory $ServerFailureCopyWith(
          ServerFailure value, $Res Function(ServerFailure) _then) =
      _$ServerFailureCopyWithImpl;
  @useResult
  $Res call({String? message});
}

/// @nodoc
class _$ServerFailureCopyWithImpl<$Res>
    implements $ServerFailureCopyWith<$Res> {
  _$ServerFailureCopyWithImpl(this._self, this._then);

  final ServerFailure _self;
  final $Res Function(ServerFailure) _then;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = freezed,
  }) {
    return _then(ServerFailure(
      freezed == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class NetworkFailure implements Failure {
  const NetworkFailure();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is NetworkFailure);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'Failure.networkError()';
  }
}

/// @nodoc

class NotFoundFailure implements Failure {
  const NotFoundFailure();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is NotFoundFailure);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'Failure.notFoundError()';
  }
}

/// @nodoc

class PermissionDeniedFailure implements Failure {
  const PermissionDeniedFailure();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is PermissionDeniedFailure);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'Failure.permissionDenied()';
  }
}

/// @nodoc

class UnexpectedFailure implements Failure {
  const UnexpectedFailure([this.message]);

  final String? message;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UnexpectedFailureCopyWith<UnexpectedFailure> get copyWith =>
      _$UnexpectedFailureCopyWithImpl<UnexpectedFailure>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UnexpectedFailure &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() {
    return 'Failure.unexpectedError(message: $message)';
  }
}

/// @nodoc
abstract mixin class $UnexpectedFailureCopyWith<$Res>
    implements $FailureCopyWith<$Res> {
  factory $UnexpectedFailureCopyWith(
          UnexpectedFailure value, $Res Function(UnexpectedFailure) _then) =
      _$UnexpectedFailureCopyWithImpl;
  @useResult
  $Res call({String? message});
}

/// @nodoc
class _$UnexpectedFailureCopyWithImpl<$Res>
    implements $UnexpectedFailureCopyWith<$Res> {
  _$UnexpectedFailureCopyWithImpl(this._self, this._then);

  final UnexpectedFailure _self;
  final $Res Function(UnexpectedFailure) _then;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = freezed,
  }) {
    return _then(UnexpectedFailure(
      freezed == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class MediaUploadFailure implements Failure {
  const MediaUploadFailure([this.message]);

  final String? message;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MediaUploadFailureCopyWith<MediaUploadFailure> get copyWith =>
      _$MediaUploadFailureCopyWithImpl<MediaUploadFailure>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MediaUploadFailure &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() {
    return 'Failure.mediaUploadFailed(message: $message)';
  }
}

/// @nodoc
abstract mixin class $MediaUploadFailureCopyWith<$Res>
    implements $FailureCopyWith<$Res> {
  factory $MediaUploadFailureCopyWith(
          MediaUploadFailure value, $Res Function(MediaUploadFailure) _then) =
      _$MediaUploadFailureCopyWithImpl;
  @useResult
  $Res call({String? message});
}

/// @nodoc
class _$MediaUploadFailureCopyWithImpl<$Res>
    implements $MediaUploadFailureCopyWith<$Res> {
  _$MediaUploadFailureCopyWithImpl(this._self, this._then);

  final MediaUploadFailure _self;
  final $Res Function(MediaUploadFailure) _then;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = freezed,
  }) {
    return _then(MediaUploadFailure(
      freezed == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class InvalidInputFailure implements Failure {
  const InvalidInputFailure([this.message]);

  final String? message;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $InvalidInputFailureCopyWith<InvalidInputFailure> get copyWith =>
      _$InvalidInputFailureCopyWithImpl<InvalidInputFailure>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is InvalidInputFailure &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() {
    return 'Failure.invalidInput(message: $message)';
  }
}

/// @nodoc
abstract mixin class $InvalidInputFailureCopyWith<$Res>
    implements $FailureCopyWith<$Res> {
  factory $InvalidInputFailureCopyWith(
          InvalidInputFailure value, $Res Function(InvalidInputFailure) _then) =
      _$InvalidInputFailureCopyWithImpl;
  @useResult
  $Res call({String? message});
}

/// @nodoc
class _$InvalidInputFailureCopyWithImpl<$Res>
    implements $InvalidInputFailureCopyWith<$Res> {
  _$InvalidInputFailureCopyWithImpl(this._self, this._then);

  final InvalidInputFailure _self;
  final $Res Function(InvalidInputFailure) _then;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = freezed,
  }) {
    return _then(InvalidInputFailure(
      freezed == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class UserNotAuthenticatedFailure implements Failure {
  const UserNotAuthenticatedFailure();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UserNotAuthenticatedFailure);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'Failure.userNotAuthenticated()';
  }
}

/// @nodoc

class LimitExceededFailure implements Failure {
  const LimitExceededFailure([this.message]);

  final String? message;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LimitExceededFailureCopyWith<LimitExceededFailure> get copyWith =>
      _$LimitExceededFailureCopyWithImpl<LimitExceededFailure>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LimitExceededFailure &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() {
    return 'Failure.limitExceeded(message: $message)';
  }
}

/// @nodoc
abstract mixin class $LimitExceededFailureCopyWith<$Res>
    implements $FailureCopyWith<$Res> {
  factory $LimitExceededFailureCopyWith(LimitExceededFailure value,
          $Res Function(LimitExceededFailure) _then) =
      _$LimitExceededFailureCopyWithImpl;
  @useResult
  $Res call({String? message});
}

/// @nodoc
class _$LimitExceededFailureCopyWithImpl<$Res>
    implements $LimitExceededFailureCopyWith<$Res> {
  _$LimitExceededFailureCopyWithImpl(this._self, this._then);

  final LimitExceededFailure _self;
  final $Res Function(LimitExceededFailure) _then;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = freezed,
  }) {
    return _then(LimitExceededFailure(
      freezed == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on

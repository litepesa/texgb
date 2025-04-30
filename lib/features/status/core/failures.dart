import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

@freezed
abstract class Failure with _$Failure {
  const factory Failure.serverError([String? message]) = ServerFailure;
  const factory Failure.networkError() = NetworkFailure;
  const factory Failure.notFoundError() = NotFoundFailure;
  const factory Failure.permissionDenied() = PermissionDeniedFailure;
  const factory Failure.unexpectedError([String? message]) = UnexpectedFailure;
  const factory Failure.mediaUploadFailed([String? message]) = MediaUploadFailure;
  const factory Failure.invalidInput([String? message]) = InvalidInputFailure;
  const factory Failure.userNotAuthenticated() = UserNotAuthenticatedFailure;
  const factory Failure.limitExceeded([String? message]) = LimitExceededFailure;
}
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/models/user_model.dart';

part 'auth_providers.g.dart';

// Convenience provider to get current user model
@riverpod
UserModel? currentUser(CurrentUserRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.value?.userModel;
}

// Convenience provider to check if user is logged in
@riverpod
bool isLoggedIn(IsLoggedInRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.value?.userModel != null;
}

// Convenience provider to check loading state
@riverpod
bool isAuthLoading(IsAuthLoadingRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.value?.isLoading ?? false;
}
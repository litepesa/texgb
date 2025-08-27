// lib/features/authentication/providers/auth_repository_provider.dart (Updated)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';

// Provider for the auth repository - now using Firebase Auth + Go Backend
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthWithGoBackendRepository();
});


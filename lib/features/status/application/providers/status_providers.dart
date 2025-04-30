import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../domain/repositories/status_repository.dart';
import '../../data/repositories/firebase_status_repository.dart';
import '../../data/data_sources/media_upload_service.dart';
import '../../domain/models/status_post.dart';
import '../../domain/models/status_privacy.dart';
import '../../domain/models/status_comment.dart';
import '../../domain/models/status_reaction.dart';
import '../state/status_state.dart';
import '../controllers/status_controller.dart';

/// Dependency injection for Firebase services
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final uuidProvider = Provider<Uuid>((ref) {
  return const Uuid();
});

/// Provider for media upload service
final mediaUploadServiceProvider = Provider<MediaUploadService>((ref) {
  return MediaUploadService(
    storage: ref.watch(firebaseStorageProvider),
    uuid: ref.watch(uuidProvider),
  );
});

/// Repository provider
final statusRepositoryProvider = Provider<StatusRepository>((ref) {
  return FirebaseStatusRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
    uuid: ref.watch(uuidProvider),
    mediaUploadService: ref.watch(mediaUploadServiceProvider),
  );
});

/// Provider for status controller
final statusControllerProvider = Provider<StatusController>((ref) {
  return StatusController(
    repository: ref.watch(statusRepositoryProvider),
  );
});

/// Provider for user's muted status users
final mutedUsersProvider = StateNotifierProvider<MutedUsersNotifier, List<String>>((ref) {
  return MutedUsersNotifier(ref.watch(statusRepositoryProvider));
});

/// Provider for status feed
final statusFeedProvider = StateNotifierProvider<StatusFeedNotifier, StatusFeedState>((ref) {
  return StatusFeedNotifier(
    repository: ref.watch(statusRepositoryProvider),
  );
});

/// Provider for current user's posts
final myStatusPostsProvider = StateNotifierProvider<MyStatusPostsNotifier, StatusPostsState>((ref) {
  return MyStatusPostsNotifier(
    repository: ref.watch(statusRepositoryProvider),
  );
});

/// Provider for status detail (single post with comments)
final statusDetailProvider = StateNotifierProvider.family<StatusDetailNotifier, StatusDetailState, String>((ref, postId) {
  return StatusDetailNotifier(
    repository: ref.watch(statusRepositoryProvider),
    postId: postId,
  );
});

/// Provider for status privacy settings
final statusPrivacyProvider = StateProvider<StatusPrivacy>((ref) {
  return StatusPrivacy.allContacts();
});

/// Provider for media selection
final selectedMediaProvider = StateNotifierProvider<SelectedMediaNotifier, List<File>>((ref) {
  return SelectedMediaNotifier();
});



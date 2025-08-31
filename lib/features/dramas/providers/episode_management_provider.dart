// lib/features/dramas/providers/episode_management_provider.dart
import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/dramas/providers/drama_providers.dart';
import 'package:textgb/features/dramas/repositories/drama_repository.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';

part 'episode_management_provider.g.dart';

// Episode management state
class EpisodeManagementState {
  final bool isUploading;
  final bool isAdding;
  final double uploadProgress;
  final String? uploadedVideoUrl;
  final String? error;
  final String? successMessage;

  const EpisodeManagementState({
    this.isUploading = false,
    this.isAdding = false,
    this.uploadProgress = 0.0,
    this.uploadedVideoUrl,
    this.error,
    this.successMessage,
  });

  EpisodeManagementState copyWith({
    bool? isUploading,
    bool? isAdding,
    double? uploadProgress,
    String? uploadedVideoUrl,
    String? error,
    String? successMessage,
  }) {
    return EpisodeManagementState(
      isUploading: isUploading ?? this.isUploading,
      isAdding: isAdding ?? this.isAdding,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      uploadedVideoUrl: uploadedVideoUrl,
      error: error,
      successMessage: successMessage,
    );
  }

  bool get hasUploadedVideo => uploadedVideoUrl != null && uploadedVideoUrl!.isNotEmpty;
  bool get isProcessing => isUploading || isAdding;
}

@riverpod
class EpisodeManagement extends _$EpisodeManagement {
  @override
  EpisodeManagementState build() {
    return const EpisodeManagementState();
  }

  // Upload video file to server
  Future<bool> uploadVideo(File videoFile, String dramaId) async {
    final user = ref.read(currentUserProvider);
    if (user == null || !user.isAdmin) {
      state = state.copyWith(error: 'Admin access required');
      return false;
    }

    state = state.copyWith(
      isUploading: true, 
      error: null, 
      uploadProgress: 0.0,
      successMessage: null,
    );

    try {
      // Validate file size (50MB limit)
      final fileSizeInBytes = await videoFile.length();
      final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
      
      if (fileSizeInMB > 50) {
        state = state.copyWith(
          isUploading: false,
          error: 'Video too large! Maximum size is 50MB (current: ${fileSizeInMB.toStringAsFixed(1)}MB)',
        );
        return false;
      }

      final repository = ref.read(dramaRepositoryProvider);
      final episodeId = 'episode_${dramaId}_${DateTime.now().millisecondsSinceEpoch}';
      
      final videoUrl = await repository.uploadVideo(
        videoFile,
        episodeId,
        onProgress: (progress) {
          state = state.copyWith(uploadProgress: progress / 100.0);
        },
      );

      state = state.copyWith(
        isUploading: false,
        uploadProgress: 1.0,
        uploadedVideoUrl: videoUrl,
        successMessage: 'Video uploaded successfully!',
      );

      return true;
      
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        error: 'Failed to upload video: $e',
      );
      return false;
    }
  }

  // Add uploaded episode to drama
  Future<bool> addEpisodeToDrama(String dramaId) async {
    final user = ref.read(currentUserProvider);
    if (user == null || !user.isAdmin) {
      state = state.copyWith(error: 'Admin access required');
      return false;
    }

    if (!state.hasUploadedVideo) {
      state = state.copyWith(error: 'No video uploaded yet');
      return false;
    }

    state = state.copyWith(
      isAdding: true, 
      error: null,
      successMessage: null,
    );

    try {
      final repository = ref.read(dramaRepositoryProvider);
      final response = await repository.addEpisodeToDrama(dramaId, state.uploadedVideoUrl!);
      
      final episodeNumber = response['episodeNumber'] ?? 1;
      final totalEpisodes = response['totalEpisodes'] ?? 1;
      
      state = state.copyWith(
        isAdding: false,
        successMessage: 'Successfully added Episode $episodeNumber! Total episodes: $totalEpisodes',
      );

      // Refresh drama data
      ref.invalidate(dramaProvider(dramaId));
      ref.invalidate(adminDramasProvider);

      return true;
      
    } catch (e) {
      state = state.copyWith(
        isAdding: false,
        error: 'Failed to add episode to drama: $e',
      );
      return false;
    }
  }

  // Combined upload and add operation
  Future<bool> uploadVideoAndAddToDrama(File videoFile, String dramaId) async {
    // Step 1: Upload video
    final uploadSuccess = await uploadVideo(videoFile, dramaId);
    if (!uploadSuccess) return false;

    // Wait a moment for state to stabilize
    await Future.delayed(const Duration(milliseconds: 500));

    // Step 2: Add to drama
    return await addEpisodeToDrama(dramaId);
  }

  // Clear state
  void clearState() {
    state = const EpisodeManagementState();
  }

  // Clear only messages
  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }

  // Clear uploaded video
  void clearUploadedVideo() {
    state = state.copyWith(
      uploadedVideoUrl: null,
      uploadProgress: 0.0,
      successMessage: null,
      error: null,
    );
  }
}

// Convenience providers
@riverpod
bool hasUploadedVideo(HasUploadedVideoRef ref) {
  final state = ref.watch(episodeManagementProvider);
  return state.hasUploadedVideo;
}

@riverpod
bool isProcessingEpisode(IsProcessingEpisodeRef ref) {
  final state = ref.watch(episodeManagementProvider);
  return state.isProcessing;
}

@riverpod
double episodeUploadProgress(EpisodeUploadProgressRef ref) {
  final state = ref.watch(episodeManagementProvider);
  return state.uploadProgress;
}

@riverpod
String? episodeManagementError(EpisodeManagementErrorRef ref) {
  final state = ref.watch(episodeManagementProvider);
  return state.error;
}

@riverpod
String? episodeManagementSuccess(EpisodeManagementSuccessRef ref) {
  final state = ref.watch(episodeManagementProvider);
  return state.successMessage;
}
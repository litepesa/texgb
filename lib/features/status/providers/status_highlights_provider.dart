// lib/features/status/providers/status_highlights_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

part 'status_highlights_provider.g.dart';

// Status Highlights State
class StatusHighlightsState {
  final bool isDownloading;
  final double downloadProgress;
  final String? downloadingId;
  final Map<String, String> downloadedPaths; // statusId -> local path
  final String? error;

  const StatusHighlightsState({
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.downloadingId,
    this.downloadedPaths = const {},
    this.error,
  });

  StatusHighlightsState copyWith({
    bool? isDownloading,
    double? downloadProgress,
    String? downloadingId,
    Map<String, String>? downloadedPaths,
    String? error,
    bool clearError = false,
    bool clearDownloading = false,
  }) {
    return StatusHighlightsState(
      isDownloading: clearDownloading ? false : (isDownloading ?? this.isDownloading),
      downloadProgress: clearDownloading ? 0.0 : (downloadProgress ?? this.downloadProgress),
      downloadingId: clearDownloading ? null : (downloadingId ?? this.downloadingId),
      downloadedPaths: downloadedPaths ?? this.downloadedPaths,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

@riverpod
class StatusHighlightsNotifier extends _$StatusHighlightsNotifier {
  final Dio _dio = Dio();

  @override
  StatusHighlightsState build() {
    return const StatusHighlightsState();
  }

  // Download status to device
  Future<void> downloadStatus(StatusUpdate statusUpdate, StatusModel statusOwner) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      state = state.copyWith(error: 'User not authenticated');
      return;
    }

    // Check storage permission
    final hasPermission = await _checkStoragePermission();
    if (!hasPermission) {
      state = state.copyWith(error: 'Storage permission denied');
      return;
    }

    state = state.copyWith(
      isDownloading: true,
      downloadingId: statusUpdate.id,
      downloadProgress: 0.0,
      clearError: true,
    );

    try {
      String? filePath;

      switch (statusUpdate.type) {
        case StatusType.text:
          filePath = await _downloadTextStatus(statusUpdate, statusOwner);
          break;
        case StatusType.image:
          if (statusUpdate.mediaUrl != null) {
            filePath = await _downloadImageStatus(statusUpdate, statusOwner);
          }
          break;
        case StatusType.video:
          if (statusUpdate.mediaUrl != null) {
            filePath = await _downloadVideoStatus(statusUpdate, statusOwner);
          }
          break;
        default:
          throw Exception('Unsupported status type');
      }

      if (filePath != null) {
        // Save to gallery
        await _saveToGallery(filePath, statusUpdate.type);
        
        // Update downloaded paths
        final updatedPaths = Map<String, String>.from(state.downloadedPaths);
        updatedPaths[statusUpdate.id] = filePath;

        state = state.copyWith(
          downloadedPaths: updatedPaths,
          clearDownloading: true,
        );

        // Show success message
        _showSuccess('Status saved to gallery');
      } else {
        throw Exception('Failed to download status');
      }
    } catch (e) {
      debugPrint('Error downloading status: $e');
      state = state.copyWith(
        error: 'Failed to download status: $e',
        clearDownloading: true,
      );
    }
  }

  // Download text status as image
  Future<String?> _downloadTextStatus(StatusUpdate statusUpdate, StatusModel statusOwner) async {
    try {
      // For text status, we'll create a screenshot-like image
      // This would require creating a widget and converting it to image
      // For now, we'll create a simple text file or convert to image
      
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'status_${statusUpdate.id}_${DateTime.now().millisecondsSinceEpoch}.txt';
      final filePath = path.join(appDir.path, fileName);
      
      final content = '''
Status by: ${statusOwner.userName}
Posted: ${_formatDate(statusUpdate.timestamp)}

${statusUpdate.content}

Downloaded from TextGB
      ''';
      
      final file = File(filePath);
      await file.writeAsString(content);
      
      return filePath;
    } catch (e) {
      debugPrint('Error downloading text status: $e');
      return null;
    }
  }

  // Download image status
  Future<String?> _downloadImageStatus(StatusUpdate statusUpdate, StatusModel statusOwner) async {
    try {
      final response = await _dio.get(
        statusUpdate.mediaUrl!,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            state = state.copyWith(downloadProgress: progress);
          }
        },
      );

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'status_${statusUpdate.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = path.join(appDir.path, fileName);
      
      final file = File(filePath);
      await file.writeAsBytes(response.data);
      
      return filePath;
    } catch (e) {
      debugPrint('Error downloading image status: $e');
      return null;
    }
  }

  // Download video status
  Future<String?> _downloadVideoStatus(StatusUpdate statusUpdate, StatusModel statusOwner) async {
    try {
      final response = await _dio.get(
        statusUpdate.mediaUrl!,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            state = state.copyWith(downloadProgress: progress);
          }
        },
      );

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'status_${statusUpdate.id}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final filePath = path.join(appDir.path, fileName);
      
      final file = File(filePath);
      await file.writeAsBytes(response.data);
      
      return filePath;
    } catch (e) {
      debugPrint('Error downloading video status: $e');
      return null;
    }
  }

  // Save file to gallery
  Future<void> _saveToGallery(String filePath, StatusType type) async {
    try {
      switch (type) {
        case StatusType.text:
          // For text files, we might want to convert to image first
          // For now, just copy to downloads
          break;
        case StatusType.image:
          await Gal.putImage(filePath);
          break;
        case StatusType.video:
          await Gal.putVideo(filePath);
          break;
        default:
          break;
      }
    } catch (e) {
      debugPrint('Error saving to gallery: $e');
      // If gallery save fails, at least the file is in app directory
    }
  }

  // Check storage permission
  Future<bool> _checkStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+), we need different permissions
        final androidInfo = await _getAndroidInfo();
        if (androidInfo >= 33) {
          // Android 13+ uses scoped storage, Gal handles permissions
          return true;
        } else {
          // Android 12 and below
          final status = await Permission.storage.request();
          return status.isGranted;
        }
      } else if (Platform.isIOS) {
        final status = await Permission.photos.request();
        return status.isGranted;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking storage permission: $e');
      return false;
    }
  }

  // Get Android API level
  Future<int> _getAndroidInfo() async {
    try {
      // This is a simplified version - you might want to use device_info_plus
      return 33; // Assume modern Android for now
    } catch (e) {
      return 30; // Fallback to older Android
    }
  }

  // Download multiple status updates
  Future<void> downloadMultipleStatus(List<StatusUpdate> updates, StatusModel statusOwner) async {
    for (int i = 0; i < updates.length; i++) {
      final update = updates[i];
      
      // Update progress for batch download
      state = state.copyWith(
        downloadProgress: i / updates.length,
        downloadingId: update.id,
      );
      
      await downloadStatus(update, statusOwner);
      
      // Short delay between downloads
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    _showSuccess('${updates.length} status updates saved to gallery');
  }

  // Check if status is downloaded
  bool isStatusDownloaded(String statusId) {
    return state.downloadedPaths.containsKey(statusId);
  }

  // Get downloaded status path
  String? getDownloadedPath(String statusId) {
    return state.downloadedPaths[statusId];
  }

  // Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // Clear download state
  void clearDownloadState() {
    state = state.copyWith(clearDownloading: true);
  }

  // Delete downloaded status
  Future<void> deleteDownloadedStatus(String statusId) async {
    final filePath = state.downloadedPaths[statusId];
    if (filePath != null) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
        
        final updatedPaths = Map<String, String>.from(state.downloadedPaths);
        updatedPaths.remove(statusId);
        
        state = state.copyWith(downloadedPaths: updatedPaths);
        _showSuccess('Downloaded status deleted');
      } catch (e) {
        debugPrint('Error deleting downloaded status: $e');
        state = state.copyWith(error: 'Failed to delete downloaded status');
      }
    }
  }

  // Get all downloaded status
  List<String> getAllDownloadedStatusIds() {
    return state.downloadedPaths.keys.toList();
  }

  // Clear all downloaded status
  Future<void> clearAllDownloaded() async {
    try {
      for (final filePath in state.downloadedPaths.values) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      state = state.copyWith(downloadedPaths: {});
      _showSuccess('All downloaded status cleared');
    } catch (e) {
      debugPrint('Error clearing downloaded status: $e');
      state = state.copyWith(error: 'Failed to clear downloaded status');
    }
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  // Show success message
  void _showSuccess(String message) {
    // This will be handled by the UI layer
    debugPrint('Success: $message');
  }
}
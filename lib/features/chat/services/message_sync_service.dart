// lib/features/chat/services/message_sync_service.dart
// Background sync service for retrying failed messages
// Automatically retries sending messages that failed due to network issues

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:textgb/features/chat/services/chat_database_service.dart';
import 'package:textgb/features/chat/repositories/chat_repository.dart';
import 'package:textgb/enums/enums.dart';

class MessageSyncService {
  final ChatDatabaseService _db;
  final ChatRepository _repository;
  Timer? _syncTimer;
  bool _isSyncing = false;

  // Sync interval in seconds
  static const int _syncIntervalSeconds = 30;
  // Maximum retry attempts before giving up
  static const int _maxRetryAttempts = 5;

  MessageSyncService(this._db, this._repository);

  /// Start background sync timer
  void startBackgroundSync() {
    if (_syncTimer != null && _syncTimer!.isActive) {
      debugPrint('MessageSyncService: Sync already running');
      return;
    }

    debugPrint('MessageSyncService: Starting background sync (every $_syncIntervalSeconds seconds)');

    // Run immediately on start
    _syncUnsyncedMessages();

    // Then run periodically
    _syncTimer = Timer.periodic(
      Duration(seconds: _syncIntervalSeconds),
      (_) => _syncUnsyncedMessages(),
    );
  }

  /// Stop background sync timer
  void stopBackgroundSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('MessageSyncService: Background sync stopped');
  }

  /// Check if sync is currently running
  bool get isSyncing => _isSyncing;

  /// Check if background sync is active
  bool get isBackgroundSyncActive => _syncTimer != null && _syncTimer!.isActive;

  /// Manually trigger sync
  Future<void> triggerSync() async {
    await _syncUnsyncedMessages();
  }

  /// Sync all unsynced messages
  Future<void> _syncUnsyncedMessages() async {
    if (_isSyncing) {
      debugPrint('MessageSyncService: Sync already in progress, skipping');
      return;
    }

    _isSyncing = true;

    try {
      // Get all unsynced messages (status: sending or failed)
      final unsyncedMessages = await _db.getUnsyncedMessages();

      if (unsyncedMessages.isEmpty) {
        debugPrint('MessageSyncService: No unsynced messages');
        _isSyncing = false;
        return;
      }

      debugPrint('MessageSyncService: Found ${unsyncedMessages.length} unsynced messages');

      int successCount = 0;
      int failCount = 0;

      for (final message in unsyncedMessages) {
        try {
          // Skip messages that are still being uploaded (have isUploading: true in metadata)
          if (message.mediaMetadata != null &&
              message.mediaMetadata!['isUploading'] == true) {
            debugPrint('MessageSyncService: Skipping message ${message.messageId} (still uploading)');
            continue;
          }

          // Get retry count from metadata (or 0 if not set)
          final retryCount = (message.mediaMetadata?['_retryCount'] ?? 0) as int;

          if (retryCount >= _maxRetryAttempts) {
            debugPrint('MessageSyncService: Message ${message.messageId} exceeded max retries');
            // Update status to failed permanently
            await _db.updateMessageStatus(message.messageId, MessageStatus.failed.name);
            continue;
          }

          // Try to send the message
          debugPrint('MessageSyncService: Attempting to sync message ${message.messageId} (attempt ${retryCount + 1})');

          // Update retry count in metadata
          final updatedMetadata = {
            ...?message.mediaMetadata,
            '_retryCount': retryCount + 1,
            '_lastRetryAt': DateTime.now().toIso8601String(),
          };

          final messageToSend = message.copyWith(
            status: MessageStatus.sending,
            mediaMetadata: updatedMetadata,
          );

          // Update local status to sending
          await _db.upsertMessage(messageToSend);

          // Send to server
          await _repository.sendMessage(messageToSend);

          // Update status to sent
          await _db.updateMessageStatus(message.messageId, MessageStatus.sent.name);
          await _repository.updateMessageStatus(
            message.chatId,
            message.messageId,
            MessageStatus.sent,
          );

          successCount++;
          debugPrint('MessageSyncService: Successfully synced message ${message.messageId}');

        } catch (e) {
          failCount++;
          debugPrint('MessageSyncService: Failed to sync message ${message.messageId}: $e');

          // Update status back to failed
          await _db.updateMessageStatus(message.messageId, MessageStatus.failed.name);
        }
      }

      debugPrint('MessageSyncService: Sync complete - $successCount success, $failCount failed');

    } catch (e) {
      debugPrint('MessageSyncService: Error during sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Get count of unsynced messages
  Future<int> getUnsyncedCount() async {
    try {
      final unsyncedMessages = await _db.getUnsyncedMessages();
      return unsyncedMessages.length;
    } catch (e) {
      debugPrint('MessageSyncService: Error getting unsynced count: $e');
      return 0;
    }
  }

  /// Clear all failed messages (user initiated)
  Future<void> clearFailedMessages() async {
    try {
      final unsyncedMessages = await _db.getUnsyncedMessages();
      for (final message in unsyncedMessages) {
        if (message.status == MessageStatus.failed) {
          await _db.deleteMessage(message.messageId);
        }
      }
      debugPrint('MessageSyncService: Cleared all failed messages');
    } catch (e) {
      debugPrint('MessageSyncService: Error clearing failed messages: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    stopBackgroundSync();
  }
}

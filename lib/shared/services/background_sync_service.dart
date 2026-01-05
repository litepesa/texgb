// lib/shared/services/background_sync_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/services/connection_service.dart';
import 'package:textgb/features/chat/services/chat_database_service.dart';
import 'package:textgb/features/chat/repositories/chat_repository.dart';
import 'package:textgb/enums/enums.dart';

/// Background sync service that monitors connection status
/// and automatically syncs pending/failed messages when online
class BackgroundSyncService {
  final Ref ref;
  final ChatDatabaseService _databaseService;
  final ChatRepository _repository;

  bool _isSyncing = false;
  bool _wasOffline = false;

  BackgroundSyncService({
    required this.ref,
    required ChatDatabaseService databaseService,
    required ChatRepository repository,
  })  : _databaseService = databaseService,
        _repository = repository {
    _initializeConnectionMonitoring();
  }

  /// Initialize connection monitoring to trigger sync when online
  void _initializeConnectionMonitoring() {
    debugPrint('🔄 BackgroundSync: Initializing connection monitoring');

    // Listen to connection status changes
    ref.listen(connectionServiceProvider, (previous, next) {
      final wasOffline = previous?.isOffline ?? false;
      final isNowOnline = next.isOnline;

      debugPrint(
          '🔄 BackgroundSync: Connection changed - Was offline: $wasOffline, Now online: $isNowOnline');

      // If we just came back online, trigger sync
      if (wasOffline && isNowOnline) {
        debugPrint('🔄 BackgroundSync: Device came back online - triggering sync');
        _triggerSync();
      }

      _wasOffline = next.isOffline;
    });
  }

  /// Trigger background sync of failed/pending messages
  Future<void> _triggerSync() async {
    if (_isSyncing) {
      debugPrint(
          '🔄 BackgroundSync: Sync already in progress, skipping');
      return;
    }

    try {
      _isSyncing = true;
      debugPrint('🔄 BackgroundSync: Starting sync...');

      await _syncFailedMessages();

      debugPrint('🔄 BackgroundSync: Sync completed successfully');
    } catch (e) {
      debugPrint('❌ BackgroundSync: Error during sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync failed/unsent messages from local database
  Future<void> _syncFailedMessages() async {
    try {
      // Get unsynced messages from SQLite
      final unsyncedMessages = await _databaseService.getUnsyncedMessages();

      if (unsyncedMessages.isEmpty) {
        debugPrint('🔄 BackgroundSync: No unsynced messages found');
        return;
      }

      debugPrint(
          '🔄 BackgroundSync: Found ${unsyncedMessages.length} unsynced messages');

      int successCount = 0;
      int failureCount = 0;

      // Retry each failed message
      for (final message in unsyncedMessages) {
        try {
          debugPrint(
              '🔄 BackgroundSync: Retrying message ${message.messageId}');

          // Send message to server
          await _repository.sendMessage(message);

          // Update message status to sent
          await _databaseService.updateMessageStatus(
            message.messageId,
            MessageStatus.sent.name,
          );

          successCount++;
          debugPrint(
              '✅ BackgroundSync: Successfully synced message ${message.messageId}');
        } catch (e) {
          failureCount++;
          debugPrint(
              '❌ BackgroundSync: Failed to sync message ${message.messageId}: $e');

          // Update message status to failed
          await _databaseService.updateMessageStatus(
            message.messageId,
            MessageStatus.failed.name,
          );
        }
      }

      debugPrint(
          '🔄 BackgroundSync: Sync summary - Success: $successCount, Failed: $failureCount');
    } catch (e) {
      debugPrint('❌ BackgroundSync: Error syncing failed messages: $e');
    }
  }

  /// Manually trigger sync (can be called from UI)
  Future<void> manualSync() async {
    debugPrint('🔄 BackgroundSync: Manual sync triggered');
    await _triggerSync();
  }

  /// Check if sync is currently in progress
  bool get isSyncing => _isSyncing;

  /// Get sync statistics
  Future<Map<String, int>> getSyncStats() async {
    try {
      final dbStats = await _databaseService.getDatabaseStats();
      return {
        'totalMessages': dbStats['messages'] ?? 0,
        'totalChats': dbStats['chats'] ?? 0,
        'unsyncedMessages': dbStats['unsynced'] ?? 0,
      };
    } catch (e) {
      debugPrint('❌ BackgroundSync: Error getting sync stats: $e');
      return {
        'totalMessages': 0,
        'totalChats': 0,
        'unsyncedMessages': 0,
      };
    }
  }

  /// Dispose resources
  void dispose() {
    debugPrint('🔄 BackgroundSync: Disposing background sync service');
  }
}

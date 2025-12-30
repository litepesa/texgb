// lib/features/chat/providers/message_sync_provider.dart
// Riverpod provider for message sync service

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/chat/services/message_sync_service.dart';
import 'package:textgb/features/chat/repositories/chat_repository.dart';
import 'package:textgb/features/chat/providers/chat_database_provider.dart';

part 'message_sync_provider.g.dart';

/// Provider for the message sync service
/// This service automatically retries failed messages in the background
@riverpod
MessageSyncService messageSyncService(MessageSyncServiceRef ref) {
  final dbService = ref.watch(chatDatabaseProvider);
  final repository = ref.watch(chatRepositoryProvider);

  final syncService = MessageSyncService(dbService, repository);

  // Start background sync automatically
  syncService.startBackgroundSync();

  // Cleanup on dispose
  ref.onDispose(() {
    syncService.dispose();
  });

  return syncService;
}

/// Provider to get unsynced message count
@riverpod
Future<int> unsyncedMessageCount(UnsyncedMessageCountRef ref) async {
  final syncService = ref.watch(messageSyncServiceProvider);
  return await syncService.getUnsyncedCount();
}

/// Provider to check if sync is active
@riverpod
bool isSyncActive(IsSyncActiveRef ref) {
  final syncService = ref.watch(messageSyncServiceProvider);
  return syncService.isBackgroundSyncActive;
}

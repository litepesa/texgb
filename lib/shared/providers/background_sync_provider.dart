// lib/shared/providers/background_sync_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/shared/services/background_sync_service.dart';
import 'package:textgb/features/chat/providers/chat_database_provider.dart';
import 'package:textgb/features/chat/repositories/chat_repository.dart';

part 'background_sync_provider.g.dart';

/// Provider for background sync service
/// This service automatically syncs failed messages when connection is restored
@Riverpod(keepAlive: true)
BackgroundSyncService backgroundSync(BackgroundSyncRef ref) {
  final databaseService = ref.watch(chatDatabaseProvider);
  final repository = ref.watch(chatRepositoryProvider);

  final service = BackgroundSyncService(
    ref: ref,
    databaseService: databaseService,
    repository: repository,
  );

  // Cleanup on dispose
  ref.onDispose(() {
    service.dispose();
  });

  return service;
}

/// Provider to check if sync is currently in progress
@riverpod
bool isSyncing(IsSyncingRef ref) {
  final syncService = ref.watch(backgroundSyncProvider);
  return syncService.isSyncing;
}

/// Provider to get sync statistics
@riverpod
Future<Map<String, int>> syncStats(SyncStatsRef ref) async {
  final syncService = ref.watch(backgroundSyncProvider);
  return syncService.getSyncStats();
}

// lib/features/chat/providers/chat_database_provider.dart
// Riverpod provider for chat database service

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/chat/services/chat_database_service.dart';

part 'chat_database_provider.g.dart';

/// Singleton provider for the chat database service
@riverpod
ChatDatabaseService chatDatabase(ChatDatabaseRef ref) {
  final dbService = ChatDatabaseService();

  // Cleanup on dispose
  ref.onDispose(() {
    dbService.close();
  });

  return dbService;
}

/// Provider to get database statistics
@riverpod
Future<Map<String, int>> databaseStats(DatabaseStatsRef ref) async {
  final dbService = ref.watch(chatDatabaseProvider);
  return await dbService.getDatabaseStats();
}

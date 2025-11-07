// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatDatabaseHash() => r'61bcae3a3abe71eed27147c2bb4c0c5894c58fa2';

/// Singleton provider for the chat database service
///
/// Copied from [chatDatabase].
@ProviderFor(chatDatabase)
final chatDatabaseProvider = AutoDisposeProvider<ChatDatabaseService>.internal(
  chatDatabase,
  name: r'chatDatabaseProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$chatDatabaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChatDatabaseRef = AutoDisposeProviderRef<ChatDatabaseService>;
String _$databaseStatsHash() => r'66b8ca05abe16c8697ce55a4866ec616e672a7e1';

/// Provider to get database statistics
///
/// Copied from [databaseStats].
@ProviderFor(databaseStats)
final databaseStatsProvider =
    AutoDisposeFutureProvider<Map<String, int>>.internal(
  databaseStats,
  name: r'databaseStatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$databaseStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DatabaseStatsRef = AutoDisposeFutureProviderRef<Map<String, int>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

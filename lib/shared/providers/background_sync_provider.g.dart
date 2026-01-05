// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$backgroundSyncHash() => r'9c025febc188a9e276bb0a2ac6cca850e4f99f94';

/// Provider for background sync service
/// This service automatically syncs failed messages when connection is restored
///
/// Copied from [backgroundSync].
@ProviderFor(backgroundSync)
final backgroundSyncProvider = Provider<BackgroundSyncService>.internal(
  backgroundSync,
  name: r'backgroundSyncProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$backgroundSyncHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BackgroundSyncRef = ProviderRef<BackgroundSyncService>;
String _$isSyncingHash() => r'9bc3d7ddf0d6faa3b7758f6490b76020310a3f41';

/// Provider to check if sync is currently in progress
///
/// Copied from [isSyncing].
@ProviderFor(isSyncing)
final isSyncingProvider = AutoDisposeProvider<bool>.internal(
  isSyncing,
  name: r'isSyncingProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isSyncingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsSyncingRef = AutoDisposeProviderRef<bool>;
String _$syncStatsHash() => r'788288c922d1f24354b66f2813a888bda46a31ca';

/// Provider to get sync statistics
///
/// Copied from [syncStats].
@ProviderFor(syncStats)
final syncStatsProvider = AutoDisposeFutureProvider<Map<String, int>>.internal(
  syncStats,
  name: r'syncStatsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$syncStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SyncStatsRef = AutoDisposeFutureProviderRef<Map<String, int>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

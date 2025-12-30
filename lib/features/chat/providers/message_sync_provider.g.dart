// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$messageSyncServiceHash() =>
    r'dd4bf5ba90e4dc6647fd6adf06c13856fec7ec26';

/// Provider for the message sync service
/// This service automatically retries failed messages in the background
///
/// Copied from [messageSyncService].
@ProviderFor(messageSyncService)
final messageSyncServiceProvider =
    AutoDisposeProvider<MessageSyncService>.internal(
  messageSyncService,
  name: r'messageSyncServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$messageSyncServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MessageSyncServiceRef = AutoDisposeProviderRef<MessageSyncService>;
String _$unsyncedMessageCountHash() =>
    r'ecf028ed62cd728b1e973b83f9b63e72001412f7';

/// Provider to get unsynced message count
///
/// Copied from [unsyncedMessageCount].
@ProviderFor(unsyncedMessageCount)
final unsyncedMessageCountProvider = AutoDisposeFutureProvider<int>.internal(
  unsyncedMessageCount,
  name: r'unsyncedMessageCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unsyncedMessageCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnsyncedMessageCountRef = AutoDisposeFutureProviderRef<int>;
String _$isSyncActiveHash() => r'ee3f3df86c23d3af09bd08a609ad310b7a88ad08';

/// Provider to check if sync is active
///
/// Copied from [isSyncActive].
@ProviderFor(isSyncActive)
final isSyncActiveProvider = AutoDisposeProvider<bool>.internal(
  isSyncActive,
  name: r'isSyncActiveProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isSyncActiveHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsSyncActiveRef = AutoDisposeProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$statusesStreamHash() => r'e25724cd9c7b9b3689c64a8b6e2d9887d3f7bbc1';

/// See also [statusesStream].
@ProviderFor(statusesStream)
final statusesStreamProvider = AutoDisposeStreamProvider<List<StatusModel>>.internal(
  statusesStream,
  name: r'statusesStreamProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$statusesStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StatusesStreamRef = AutoDisposeStreamProviderRef<List<StatusModel>>;
String _$myStatusesStreamHash() => r'2fa38b952add40d8b1bcf4c68cdf3d4f5e4c9a8d';

/// See also [myStatusesStream].
@ProviderFor(myStatusesStream)
final myStatusesStreamProvider = AutoDisposeStreamProvider<List<StatusModel>>.internal(
  myStatusesStream,
  name: r'myStatusesStreamProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$myStatusesStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MyStatusesStreamRef = AutoDisposeStreamProviderRef<List<StatusModel>>;
String _$statusNotifierHash() => r'6a9dcda41e856f3a24952fe8f0a4b5c0fef8c7ee';

/// See also [StatusNotifier].
@ProviderFor(StatusNotifier)
final statusNotifierProvider =
    AutoDisposeAsyncNotifierProvider<StatusNotifier, StatusState>.internal(
  StatusNotifier.new,
  name: r'statusNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$statusNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$StatusNotifier = AutoDisposeAsyncNotifier<StatusState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
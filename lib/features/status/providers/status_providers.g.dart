// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$statusApiServiceHash() => r'e8f9a3b2c1d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8';

/// See also [statusApiService].
@ProviderFor(statusApiService)
final statusApiServiceProvider = AutoDisposeProvider<StatusApiService>.internal(
  statusApiService,
  name: r'statusApiServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$statusApiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StatusApiServiceRef = AutoDisposeProviderRef<StatusApiService>;
String _$statusUploadServiceHash() =>
    r'f1e2d3c4b5a6f7e8d9c0b1a2f3e4d5c6b7a8f9e0';

/// See also [statusUploadService].
@ProviderFor(statusUploadService)
final statusUploadServiceProvider =
    AutoDisposeProvider<StatusUploadService>.internal(
  statusUploadService,
  name: r'statusUploadServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$statusUploadServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StatusUploadServiceRef = AutoDisposeProviderRef<StatusUploadService>;
String _$statusFeedHash() => r'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0';

/// See also [StatusFeed].
@ProviderFor(StatusFeed)
final statusFeedProvider =
    AutoDisposeAsyncNotifierProvider<StatusFeed, StatusFeedState>.internal(
  StatusFeed.new,
  name: r'statusFeedProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$statusFeedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$StatusFeed = AutoDisposeAsyncNotifier<StatusFeedState>;
String _$statusCreationHash() => r'b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1';

/// See also [StatusCreation].
@ProviderFor(StatusCreation)
final statusCreationProvider =
    AutoDisposeAsyncNotifierProvider<StatusCreation, void>.internal(
  StatusCreation.new,
  name: r'statusCreationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$statusCreationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$StatusCreation = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member

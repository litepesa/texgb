// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$statusApiServiceHash() => r'91a299030faefaa1b61d227d1b8386f156117f95';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StatusApiServiceRef = AutoDisposeProviderRef<StatusApiService>;
String _$statusUploadServiceHash() =>
    r'c405af4b1a33a3a361ae402e330f7f0d76509bd0';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StatusUploadServiceRef = AutoDisposeProviderRef<StatusUploadService>;
String _$statusFeedHash() => r'ce458d6006d1827e8e44e25a8ad89c36ac723460';

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
String _$statusCreationHash() => r'fe4c86059575c784b724e835e1e98f0491e4764e';

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
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

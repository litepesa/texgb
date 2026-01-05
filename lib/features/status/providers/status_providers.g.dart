// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$statusRepositoryHash() => r'f315678fb4d196bf6cd942c3710a378e06d0b0e8';

/// See also [statusRepository].
@ProviderFor(statusRepository)
final statusRepositoryProvider = AutoDisposeProvider<StatusRepository>.internal(
  statusRepository,
  name: r'statusRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$statusRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StatusRepositoryRef = AutoDisposeProviderRef<StatusRepository>;
String _$imagePickerHash() => r'7877699a862be48e962306635347623c45e91971';

/// See also [imagePicker].
@ProviderFor(imagePicker)
final imagePickerProvider = AutoDisposeProvider<ImagePicker>.internal(
  imagePicker,
  name: r'imagePickerProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$imagePickerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ImagePickerRef = AutoDisposeProviderRef<ImagePicker>;
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
String _$statusFeedHash() => r'a453c4510544a07e4117612518e92625e75ecbfa';

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
String _$statusCreationHash() => r'1af89d74af32058576ef45d2a1810c19630e1804';

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

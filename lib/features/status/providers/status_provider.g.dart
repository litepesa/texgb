// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$myStatusesStreamHash() => r'158b4c9e30c85a805e06d2bb1ef5d6bedd4b5ce5';

/// See also [myStatusesStream].
@ProviderFor(myStatusesStream)
final myStatusesStreamProvider =
    AutoDisposeStreamProvider<List<StatusModel>>.internal(
  myStatusesStream,
  name: r'myStatusesStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$myStatusesStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyStatusesStreamRef = AutoDisposeStreamProviderRef<List<StatusModel>>;
String _$contactsStatusesStreamHash() =>
    r'6c0de8a5c670ebda10d6535da2fe487460871d4e';

/// See also [contactsStatusesStream].
@ProviderFor(contactsStatusesStream)
final contactsStatusesStreamProvider =
    AutoDisposeStreamProvider<List<UserStatusSummary>>.internal(
  contactsStatusesStream,
  name: r'contactsStatusesStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$contactsStatusesStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ContactsStatusesStreamRef
    = AutoDisposeStreamProviderRef<List<UserStatusSummary>>;
String _$hasActiveStatusHash() => r'4f4987745bb0ed7abbbbde2f0479a9e86441e378';

/// See also [hasActiveStatus].
@ProviderFor(hasActiveStatus)
final hasActiveStatusProvider = AutoDisposeProvider<bool>.internal(
  hasActiveStatus,
  name: r'hasActiveStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasActiveStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HasActiveStatusRef = AutoDisposeProviderRef<bool>;
String _$statusNotifierHash() => r'2be5993c66b51e6f22913c4eb0d6b545c95de8ad';

/// See also [StatusNotifier].
@ProviderFor(StatusNotifier)
final statusNotifierProvider =
    AutoDisposeAsyncNotifierProvider<StatusNotifier, StatusState>.internal(
  StatusNotifier.new,
  name: r'statusNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$statusNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$StatusNotifier = AutoDisposeAsyncNotifier<StatusState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

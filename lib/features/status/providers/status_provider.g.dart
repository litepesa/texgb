// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$myStatusesStreamHash() => r'8e36a8e0e83dbf1b5f9e2a6f4982c2dba1a912d5';

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

typedef MyStatusesStreamRef = AutoDisposeStreamProviderRef<List<StatusModel>>;
String _$contactsStatusesStreamHash() =>
    r'6c01ec1dff43ae5dba25d01551e0b4de81be5ff7';

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

typedef ContactsStatusesStreamRef
    = AutoDisposeStreamProviderRef<List<UserStatusSummary>>;
String _$hasActiveStatusHash() => r'f83e3b6e9aa75d5c0ec0a5f9dd51a94ab4def9a0';

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

typedef HasActiveStatusRef = AutoDisposeProviderRef<bool>;
String _$statusNotifierHash() => r'7e982a81bda0be51e38bb2e5e7c2b0bc7aa85f02';

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
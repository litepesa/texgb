// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userGroupsStreamHash() => r'577c535732aafd7d38d5295a463af1846ed7862c';

/// See also [userGroupsStream].
@ProviderFor(userGroupsStream)
final userGroupsStreamProvider =
    AutoDisposeStreamProvider<List<GroupModel>>.internal(
  userGroupsStream,
  name: r'userGroupsStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userGroupsStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserGroupsStreamRef = AutoDisposeStreamProviderRef<List<GroupModel>>;
String _$publicGroupsStreamHash() =>
    r'f9d7a300a1f31f2e6bed99655c840b88f8f1546a';

/// See also [publicGroupsStream].
@ProviderFor(publicGroupsStream)
final publicGroupsStreamProvider =
    AutoDisposeStreamProvider<List<GroupModel>>.internal(
  publicGroupsStream,
  name: r'publicGroupsStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$publicGroupsStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PublicGroupsStreamRef = AutoDisposeStreamProviderRef<List<GroupModel>>;
String _$groupNotifierHash() => r'd7aad1850057ddc635eac6f78a9bd8fb907ae071';

/// See also [GroupNotifier].
@ProviderFor(GroupNotifier)
final groupNotifierProvider =
    AutoDisposeAsyncNotifierProvider<GroupNotifier, GroupState>.internal(
  GroupNotifier.new,
  name: r'groupNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$groupNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GroupNotifier = AutoDisposeAsyncNotifier<GroupState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

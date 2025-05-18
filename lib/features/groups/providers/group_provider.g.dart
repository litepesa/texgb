// lib/features/groups/providers/group_provider.g.dart

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userGroupsStreamHash() => r'e3e6f09c57a8b3f9d7a4e2c81d6548f9a7b52c10';

/// See also [userGroupsStream].
@ProviderFor(userGroupsStream)
final userGroupsStreamProvider = AutoDisposeStreamProvider<List<GroupModel>>.internal(
  userGroupsStream,
  name: r'userGroupsStreamProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userGroupsStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserGroupsStreamRef = AutoDisposeStreamProviderRef<List<GroupModel>>;
String _$publicGroupsStreamHash() => r'9f47a5c81e32075d8a3f9cc3a1e67b2e5d7c8f2a';

/// See also [publicGroupsStream].
@ProviderFor(publicGroupsStream)
final publicGroupsStreamProvider = AutoDisposeStreamProvider<List<GroupModel>>.internal(
  publicGroupsStream,
  name: r'publicGroupsStreamProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$publicGroupsStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PublicGroupsStreamRef = AutoDisposeStreamProviderRef<List<GroupModel>>;
String _$groupNotifierHash() => r'2a7cdaf5e8b491c3d94a723f156e8f4b9a6c8e10';

/// See also [GroupNotifier].
@ProviderFor(GroupNotifier)
final groupNotifierProvider =
    AutoDisposeAsyncNotifierProvider<GroupNotifier, GroupState>.internal(
  GroupNotifier.new,
  name: r'groupNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$groupNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GroupNotifier = AutoDisposeAsyncNotifier<GroupState>;
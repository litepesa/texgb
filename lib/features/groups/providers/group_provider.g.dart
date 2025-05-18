// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userGroupsStreamHash() => r'd0132aa420aaba9adfec1362957f102ef2cf5f18';

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
    r'fedaab3e2b68904227e1b68f5ba9dc5153bc749d';

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
String _$groupNotifierHash() => r'14789da9d30e4a0930125da0d8c2e19c8268516c';

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

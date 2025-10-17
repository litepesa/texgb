// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_convenience_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allGroupsHash() => r'abce28ea3b5b43d1f638d8de9d05ab99779dfd3a';

/// Get all groups
///
/// Copied from [allGroups].
@ProviderFor(allGroups)
final allGroupsProvider = AutoDisposeProvider<List<GroupModel>>.internal(
  allGroups,
  name: r'allGroupsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allGroupsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllGroupsRef = AutoDisposeProviderRef<List<GroupModel>>;
String _$myGroupsHash() => r'1a9fb95e0dd5d72ec0cc7898db6fc713daa25931';

/// Get my groups (where user is a member)
///
/// Copied from [myGroups].
@ProviderFor(myGroups)
final myGroupsProvider = AutoDisposeProvider<List<GroupModel>>.internal(
  myGroups,
  name: r'myGroupsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$myGroupsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyGroupsRef = AutoDisposeProviderRef<List<GroupModel>>;
String _$featuredGroupsHash() => r'f3c41a15c62013224bec21920daafebc91aca4d7';

/// Get featured groups
///
/// Copied from [featuredGroups].
@ProviderFor(featuredGroups)
final featuredGroupsProvider = AutoDisposeProvider<List<GroupModel>>.internal(
  featuredGroups,
  name: r'featuredGroupsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$featuredGroupsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FeaturedGroupsRef = AutoDisposeProviderRef<List<GroupModel>>;
String _$publicGroupsHash() => r'9a3a0055410fcc9e6d900cbe568ced9849cba8a2';

/// Get public groups
///
/// Copied from [publicGroups].
@ProviderFor(publicGroups)
final publicGroupsProvider = AutoDisposeProvider<List<GroupModel>>.internal(
  publicGroups,
  name: r'publicGroupsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$publicGroupsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PublicGroupsRef = AutoDisposeProviderRef<List<GroupModel>>;
String _$privateGroupsHash() => r'0d6a4d95502929598db347789d3849ee0b32628f';

/// Get private groups
///
/// Copied from [privateGroups].
@ProviderFor(privateGroups)
final privateGroupsProvider = AutoDisposeProvider<List<GroupModel>>.internal(
  privateGroups,
  name: r'privateGroupsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$privateGroupsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PrivateGroupsRef = AutoDisposeProviderRef<List<GroupModel>>;
String _$verifiedGroupsHash() => r'43b18d8c5d00220468de349a6d78c535e347d899';

/// Get verified groups
///
/// Copied from [verifiedGroups].
@ProviderFor(verifiedGroups)
final verifiedGroupsProvider = AutoDisposeProvider<List<GroupModel>>.internal(
  verifiedGroups,
  name: r'verifiedGroupsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$verifiedGroupsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef VerifiedGroupsRef = AutoDisposeProviderRef<List<GroupModel>>;
String _$activeGroupsHash() => r'254251aba6890980204db72b828d84d9c4aec5be';

/// Get active groups
///
/// Copied from [activeGroups].
@ProviderFor(activeGroups)
final activeGroupsProvider = AutoDisposeProvider<List<GroupModel>>.internal(
  activeGroups,
  name: r'activeGroupsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$activeGroupsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveGroupsRef = AutoDisposeProviderRef<List<GroupModel>>;
String _$filteredGroupsHash() => r'cbde6ab77d2f39a17d747ea59f4967db22e01dcc';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Get filtered groups (search)
///
/// Copied from [filteredGroups].
@ProviderFor(filteredGroups)
const filteredGroupsProvider = FilteredGroupsFamily();

/// Get filtered groups (search)
///
/// Copied from [filteredGroups].
class FilteredGroupsFamily extends Family<List<GroupModel>> {
  /// Get filtered groups (search)
  ///
  /// Copied from [filteredGroups].
  const FilteredGroupsFamily();

  /// Get filtered groups (search)
  ///
  /// Copied from [filteredGroups].
  FilteredGroupsProvider call(
    String query,
  ) {
    return FilteredGroupsProvider(
      query,
    );
  }

  @override
  FilteredGroupsProvider getProviderOverride(
    covariant FilteredGroupsProvider provider,
  ) {
    return call(
      provider.query,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'filteredGroupsProvider';
}

/// Get filtered groups (search)
///
/// Copied from [filteredGroups].
class FilteredGroupsProvider extends AutoDisposeProvider<List<GroupModel>> {
  /// Get filtered groups (search)
  ///
  /// Copied from [filteredGroups].
  FilteredGroupsProvider(
    String query,
  ) : this._internal(
          (ref) => filteredGroups(
            ref as FilteredGroupsRef,
            query,
          ),
          from: filteredGroupsProvider,
          name: r'filteredGroupsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$filteredGroupsHash,
          dependencies: FilteredGroupsFamily._dependencies,
          allTransitiveDependencies:
              FilteredGroupsFamily._allTransitiveDependencies,
          query: query,
        );

  FilteredGroupsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    List<GroupModel> Function(FilteredGroupsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FilteredGroupsProvider._internal(
        (ref) => create(ref as FilteredGroupsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<List<GroupModel>> createElement() {
    return _FilteredGroupsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredGroupsProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FilteredGroupsRef on AutoDisposeProviderRef<List<GroupModel>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _FilteredGroupsProviderElement
    extends AutoDisposeProviderElement<List<GroupModel>>
    with FilteredGroupsRef {
  _FilteredGroupsProviderElement(super.provider);

  @override
  String get query => (origin as FilteredGroupsProvider).query;
}

String _$groupByIdHash() => r'0cd4d31be2c1be3272b9e279a3d0d1bf54b7a2d0';

/// Get specific group by ID
///
/// Copied from [groupById].
@ProviderFor(groupById)
const groupByIdProvider = GroupByIdFamily();

/// Get specific group by ID
///
/// Copied from [groupById].
class GroupByIdFamily extends Family<AsyncValue<GroupModel?>> {
  /// Get specific group by ID
  ///
  /// Copied from [groupById].
  const GroupByIdFamily();

  /// Get specific group by ID
  ///
  /// Copied from [groupById].
  GroupByIdProvider call(
    String groupId,
  ) {
    return GroupByIdProvider(
      groupId,
    );
  }

  @override
  GroupByIdProvider getProviderOverride(
    covariant GroupByIdProvider provider,
  ) {
    return call(
      provider.groupId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'groupByIdProvider';
}

/// Get specific group by ID
///
/// Copied from [groupById].
class GroupByIdProvider extends AutoDisposeFutureProvider<GroupModel?> {
  /// Get specific group by ID
  ///
  /// Copied from [groupById].
  GroupByIdProvider(
    String groupId,
  ) : this._internal(
          (ref) => groupById(
            ref as GroupByIdRef,
            groupId,
          ),
          from: groupByIdProvider,
          name: r'groupByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupByIdHash,
          dependencies: GroupByIdFamily._dependencies,
          allTransitiveDependencies: GroupByIdFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  GroupByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    FutureOr<GroupModel?> Function(GroupByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GroupByIdProvider._internal(
        (ref) => create(ref as GroupByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<GroupModel?> createElement() {
    return _GroupByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupByIdProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GroupByIdRef on AutoDisposeFutureProviderRef<GroupModel?> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _GroupByIdProviderElement
    extends AutoDisposeFutureProviderElement<GroupModel?> with GroupByIdRef {
  _GroupByIdProviderElement(super.provider);

  @override
  String get groupId => (origin as GroupByIdProvider).groupId;
}

String _$groupNameHash() => r'607ec41a8eb8aed3a1ef09695945ca510eb9e557';

/// Get group name
///
/// Copied from [groupName].
@ProviderFor(groupName)
const groupNameProvider = GroupNameFamily();

/// Get group name
///
/// Copied from [groupName].
class GroupNameFamily extends Family<String> {
  /// Get group name
  ///
  /// Copied from [groupName].
  const GroupNameFamily();

  /// Get group name
  ///
  /// Copied from [groupName].
  GroupNameProvider call(
    String groupId,
  ) {
    return GroupNameProvider(
      groupId,
    );
  }

  @override
  GroupNameProvider getProviderOverride(
    covariant GroupNameProvider provider,
  ) {
    return call(
      provider.groupId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'groupNameProvider';
}

/// Get group name
///
/// Copied from [groupName].
class GroupNameProvider extends AutoDisposeProvider<String> {
  /// Get group name
  ///
  /// Copied from [groupName].
  GroupNameProvider(
    String groupId,
  ) : this._internal(
          (ref) => groupName(
            ref as GroupNameRef,
            groupId,
          ),
          from: groupNameProvider,
          name: r'groupNameProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupNameHash,
          dependencies: GroupNameFamily._dependencies,
          allTransitiveDependencies: GroupNameFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  GroupNameProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    String Function(GroupNameRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GroupNameProvider._internal(
        (ref) => create(ref as GroupNameRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<String> createElement() {
    return _GroupNameProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupNameProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GroupNameRef on AutoDisposeProviderRef<String> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _GroupNameProviderElement extends AutoDisposeProviderElement<String>
    with GroupNameRef {
  _GroupNameProviderElement(super.provider);

  @override
  String get groupId => (origin as GroupNameProvider).groupId;
}

String _$groupDescriptionHash() => r'e5e3899288b374d33dce31dbb1a30d952413ddef';

/// Get group description
///
/// Copied from [groupDescription].
@ProviderFor(groupDescription)
const groupDescriptionProvider = GroupDescriptionFamily();

/// Get group description
///
/// Copied from [groupDescription].
class GroupDescriptionFamily extends Family<String> {
  /// Get group description
  ///
  /// Copied from [groupDescription].
  const GroupDescriptionFamily();

  /// Get group description
  ///
  /// Copied from [groupDescription].
  GroupDescriptionProvider call(
    String groupId,
  ) {
    return GroupDescriptionProvider(
      groupId,
    );
  }

  @override
  GroupDescriptionProvider getProviderOverride(
    covariant GroupDescriptionProvider provider,
  ) {
    return call(
      provider.groupId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'groupDescriptionProvider';
}

/// Get group description
///
/// Copied from [groupDescription].
class GroupDescriptionProvider extends AutoDisposeProvider<String> {
  /// Get group description
  ///
  /// Copied from [groupDescription].
  GroupDescriptionProvider(
    String groupId,
  ) : this._internal(
          (ref) => groupDescription(
            ref as GroupDescriptionRef,
            groupId,
          ),
          from: groupDescriptionProvider,
          name: r'groupDescriptionProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupDescriptionHash,
          dependencies: GroupDescriptionFamily._dependencies,
          allTransitiveDependencies:
              GroupDescriptionFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  GroupDescriptionProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    String Function(GroupDescriptionRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GroupDescriptionProvider._internal(
        (ref) => create(ref as GroupDescriptionRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<String> createElement() {
    return _GroupDescriptionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupDescriptionProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GroupDescriptionRef on AutoDisposeProviderRef<String> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _GroupDescriptionProviderElement
    extends AutoDisposeProviderElement<String> with GroupDescriptionRef {
  _GroupDescriptionProviderElement(super.provider);

  @override
  String get groupId => (origin as GroupDescriptionProvider).groupId;
}

String _$isGroupMemberHash() => r'24059710f4a0d90ec15e078878f2fe6a5507b30b';

/// Check if current user is a member of a group
///
/// Copied from [isGroupMember].
@ProviderFor(isGroupMember)
const isGroupMemberProvider = IsGroupMemberFamily();

/// Check if current user is a member of a group
///
/// Copied from [isGroupMember].
class IsGroupMemberFamily extends Family<bool> {
  /// Check if current user is a member of a group
  ///
  /// Copied from [isGroupMember].
  const IsGroupMemberFamily();

  /// Check if current user is a member of a group
  ///
  /// Copied from [isGroupMember].
  IsGroupMemberProvider call(
    String groupId,
  ) {
    return IsGroupMemberProvider(
      groupId,
    );
  }

  @override
  IsGroupMemberProvider getProviderOverride(
    covariant IsGroupMemberProvider provider,
  ) {
    return call(
      provider.groupId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'isGroupMemberProvider';
}

/// Check if current user is a member of a group
///
/// Copied from [isGroupMember].
class IsGroupMemberProvider extends AutoDisposeProvider<bool> {
  /// Check if current user is a member of a group
  ///
  /// Copied from [isGroupMember].
  IsGroupMemberProvider(
    String groupId,
  ) : this._internal(
          (ref) => isGroupMember(
            ref as IsGroupMemberRef,
            groupId,
          ),
          from: isGroupMemberProvider,
          name: r'isGroupMemberProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isGroupMemberHash,
          dependencies: IsGroupMemberFamily._dependencies,
          allTransitiveDependencies:
              IsGroupMemberFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  IsGroupMemberProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    bool Function(IsGroupMemberRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsGroupMemberProvider._internal(
        (ref) => create(ref as IsGroupMemberRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _IsGroupMemberProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsGroupMemberProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsGroupMemberRef on AutoDisposeProviderRef<bool> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _IsGroupMemberProviderElement extends AutoDisposeProviderElement<bool>
    with IsGroupMemberRef {
  _IsGroupMemberProviderElement(super.provider);

  @override
  String get groupId => (origin as IsGroupMemberProvider).groupId;
}

String _$isGroupAdminHash() => r'6fdb9834fc5e443993e4ee6c49bc24ed38f54c0b';

/// Check if current user is admin of a group
///
/// Copied from [isGroupAdmin].
@ProviderFor(isGroupAdmin)
const isGroupAdminProvider = IsGroupAdminFamily();

/// Check if current user is admin of a group
///
/// Copied from [isGroupAdmin].
class IsGroupAdminFamily extends Family<bool> {
  /// Check if current user is admin of a group
  ///
  /// Copied from [isGroupAdmin].
  const IsGroupAdminFamily();

  /// Check if current user is admin of a group
  ///
  /// Copied from [isGroupAdmin].
  IsGroupAdminProvider call(
    String groupId,
  ) {
    return IsGroupAdminProvider(
      groupId,
    );
  }

  @override
  IsGroupAdminProvider getProviderOverride(
    covariant IsGroupAdminProvider provider,
  ) {
    return call(
      provider.groupId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'isGroupAdminProvider';
}

/// Check if current user is admin of a group
///
/// Copied from [isGroupAdmin].
class IsGroupAdminProvider extends AutoDisposeProvider<bool> {
  /// Check if current user is admin of a group
  ///
  /// Copied from [isGroupAdmin].
  IsGroupAdminProvider(
    String groupId,
  ) : this._internal(
          (ref) => isGroupAdmin(
            ref as IsGroupAdminRef,
            groupId,
          ),
          from: isGroupAdminProvider,
          name: r'isGroupAdminProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isGroupAdminHash,
          dependencies: IsGroupAdminFamily._dependencies,
          allTransitiveDependencies:
              IsGroupAdminFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  IsGroupAdminProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    bool Function(IsGroupAdminRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsGroupAdminProvider._internal(
        (ref) => create(ref as IsGroupAdminRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _IsGroupAdminProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsGroupAdminProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsGroupAdminRef on AutoDisposeProviderRef<bool> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _IsGroupAdminProviderElement extends AutoDisposeProviderElement<bool>
    with IsGroupAdminRef {
  _IsGroupAdminProviderElement(super.provider);

  @override
  String get groupId => (origin as IsGroupAdminProvider).groupId;
}

String _$isGroupModeratorHash() => r'33c386b1724878c5321ef92271ccdd1f47a01a1f';

/// Check if current user is moderator of a group
///
/// Copied from [isGroupModerator].
@ProviderFor(isGroupModerator)
const isGroupModeratorProvider = IsGroupModeratorFamily();

/// Check if current user is moderator of a group
///
/// Copied from [isGroupModerator].
class IsGroupModeratorFamily extends Family<bool> {
  /// Check if current user is moderator of a group
  ///
  /// Copied from [isGroupModerator].
  const IsGroupModeratorFamily();

  /// Check if current user is moderator of a group
  ///
  /// Copied from [isGroupModerator].
  IsGroupModeratorProvider call(
    String groupId,
  ) {
    return IsGroupModeratorProvider(
      groupId,
    );
  }

  @override
  IsGroupModeratorProvider getProviderOverride(
    covariant IsGroupModeratorProvider provider,
  ) {
    return call(
      provider.groupId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'isGroupModeratorProvider';
}

/// Check if current user is moderator of a group
///
/// Copied from [isGroupModerator].
class IsGroupModeratorProvider extends AutoDisposeProvider<bool> {
  /// Check if current user is moderator of a group
  ///
  /// Copied from [isGroupModerator].
  IsGroupModeratorProvider(
    String groupId,
  ) : this._internal(
          (ref) => isGroupModerator(
            ref as IsGroupModeratorRef,
            groupId,
          ),
          from: isGroupModeratorProvider,
          name: r'isGroupModeratorProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isGroupModeratorHash,
          dependencies: IsGroupModeratorFamily._dependencies,
          allTransitiveDependencies:
              IsGroupModeratorFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  IsGroupModeratorProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    bool Function(IsGroupModeratorRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsGroupModeratorProvider._internal(
        (ref) => create(ref as IsGroupModeratorRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _IsGroupModeratorProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsGroupModeratorProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsGroupModeratorRef on AutoDisposeProviderRef<bool> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _IsGroupModeratorProviderElement extends AutoDisposeProviderElement<bool>
    with IsGroupModeratorRef {
  _IsGroupModeratorProviderElement(super.provider);

  @override
  String get groupId => (origin as IsGroupModeratorProvider).groupId;
}

String _$canManageGroupHash() => r'5106785c7cc6e6c71a7a876ae4dd47e57753df87';

/// Check if current user can manage a group
///
/// Copied from [canManageGroup].
@ProviderFor(canManageGroup)
const canManageGroupProvider = CanManageGroupFamily();

/// Check if current user can manage a group
///
/// Copied from [canManageGroup].
class CanManageGroupFamily extends Family<bool> {
  /// Check if current user can manage a group
  ///
  /// Copied from [canManageGroup].
  const CanManageGroupFamily();

  /// Check if current user can manage a group
  ///
  /// Copied from [canManageGroup].
  CanManageGroupProvider call(
    String groupId,
  ) {
    return CanManageGroupProvider(
      groupId,
    );
  }

  @override
  CanManageGroupProvider getProviderOverride(
    covariant CanManageGroupProvider provider,
  ) {
    return call(
      provider.groupId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'canManageGroupProvider';
}

/// Check if current user can manage a group
///
/// Copied from [canManageGroup].
class CanManageGroupProvider extends AutoDisposeProvider<bool> {
  /// Check if current user can manage a group
  ///
  /// Copied from [canManageGroup].
  CanManageGroupProvider(
    String groupId,
  ) : this._internal(
          (ref) => canManageGroup(
            ref as CanManageGroupRef,
            groupId,
          ),
          from: canManageGroupProvider,
          name: r'canManageGroupProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$canManageGroupHash,
          dependencies: CanManageGroupFamily._dependencies,
          allTransitiveDependencies:
              CanManageGroupFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  CanManageGroupProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    bool Function(CanManageGroupRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CanManageGroupProvider._internal(
        (ref) => create(ref as CanManageGroupRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _CanManageGroupProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CanManageGroupProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CanManageGroupRef on AutoDisposeProviderRef<bool> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _CanManageGroupProviderElement extends AutoDisposeProviderElement<bool>
    with CanManageGroupRef {
  _CanManageGroupProviderElement(super.provider);

  @override
  String get groupId => (origin as CanManageGroupProvider).groupId;
}

String _$canModerateGroupHash() => r'f1f4645451bd958323856092aca9cceea8309ed8';

/// Check if current user can moderate a group
///
/// Copied from [canModerateGroup].
@ProviderFor(canModerateGroup)
const canModerateGroupProvider = CanModerateGroupFamily();

/// Check if current user can moderate a group
///
/// Copied from [canModerateGroup].
class CanModerateGroupFamily extends Family<bool> {
  /// Check if current user can moderate a group
  ///
  /// Copied from [canModerateGroup].
  const CanModerateGroupFamily();

  /// Check if current user can moderate a group
  ///
  /// Copied from [canModerateGroup].
  CanModerateGroupProvider call(
    String groupId,
  ) {
    return CanModerateGroupProvider(
      groupId,
    );
  }

  @override
  CanModerateGroupProvider getProviderOverride(
    covariant CanModerateGroupProvider provider,
  ) {
    return call(
      provider.groupId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'canModerateGroupProvider';
}

/// Check if current user can moderate a group
///
/// Copied from [canModerateGroup].
class CanModerateGroupProvider extends AutoDisposeProvider<bool> {
  /// Check if current user can moderate a group
  ///
  /// Copied from [canModerateGroup].
  CanModerateGroupProvider(
    String groupId,
  ) : this._internal(
          (ref) => canModerateGroup(
            ref as CanModerateGroupRef,
            groupId,
          ),
          from: canModerateGroupProvider,
          name: r'canModerateGroupProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$canModerateGroupHash,
          dependencies: CanModerateGroupFamily._dependencies,
          allTransitiveDependencies:
              CanModerateGroupFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  CanModerateGroupProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    bool Function(CanModerateGroupRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CanModerateGroupProvider._internal(
        (ref) => create(ref as CanModerateGroupRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _CanModerateGroupProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CanModerateGroupProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CanModerateGroupRef on AutoDisposeProviderRef<bool> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _CanModerateGroupProviderElement extends AutoDisposeProviderElement<bool>
    with CanModerateGroupRef {
  _CanModerateGroupProviderElement(super.provider);

  @override
  String get groupId => (origin as CanModerateGroupProvider).groupId;
}

String _$canPostInGroupHash() => r'b621f0520c6f40f52d47f4421bcc262e6a273609';

/// Check if current user can post in a group
///
/// Copied from [canPostInGroup].
@ProviderFor(canPostInGroup)
const canPostInGroupProvider = CanPostInGroupFamily();

/// Check if current user can post in a group
///
/// Copied from [canPostInGroup].
class CanPostInGroupFamily extends Family<bool> {
  /// Check if current user can post in a group
  ///
  /// Copied from [canPostInGroup].
  const CanPostInGroupFamily();

  /// Check if current user can post in a group
  ///
  /// Copied from [canPostInGroup].
  CanPostInGroupProvider call(
    String groupId,
  ) {
    return CanPostInGroupProvider(
      groupId,
    );
  }

  @override
  CanPostInGroupProvider getProviderOverride(
    covariant CanPostInGroupProvider provider,
  ) {
    return call(
      provider.groupId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'canPostInGroupProvider';
}

/// Check if current user can post in a group
///
/// Copied from [canPostInGroup].
class CanPostInGroupProvider extends AutoDisposeProvider<bool> {
  /// Check if current user can post in a group
  ///
  /// Copied from [canPostInGroup].
  CanPostInGroupProvider(
    String groupId,
  ) : this._internal(
          (ref) => canPostInGroup(
            ref as CanPostInGroupRef,
            groupId,
          ),
          from: canPostInGroupProvider,
          name: r'canPostInGroupProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$canPostInGroupHash,
          dependencies: CanPostInGroupFamily._dependencies,
          allTransitiveDependencies:
              CanPostInGroupFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  CanPostInGroupProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    bool Function(CanPostInGroupRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CanPostInGroupProvider._internal(
        (ref) => create(ref as CanPostInGroupRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _CanPostInGroupProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CanPostInGroupProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CanPostInGroupRef on AutoDisposeProviderRef<bool> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _CanPostInGroupProviderElement extends AutoDisposeProviderElement<bool>
    with CanPostInGroupRef {
  _CanPostInGroupProviderElement(super.provider);

  @override
  String get groupId => (origin as CanPostInGroupProvider).groupId;
}

String _$groupMemberRoleHash() => r'341c33bbd4c655ce9af397b87119dac02597b2a8';

/// Get member role in a group
///
/// Copied from [groupMemberRole].
@ProviderFor(groupMemberRole)
const groupMemberRoleProvider = GroupMemberRoleFamily();

/// Get member role in a group
///
/// Copied from [groupMemberRole].
class GroupMemberRoleFamily extends Family<MemberRole> {
  /// Get member role in a group
  ///
  /// Copied from [groupMemberRole].
  const GroupMemberRoleFamily();

  /// Get member role in a group
  ///
  /// Copied from [groupMemberRole].
  GroupMemberRoleProvider call(
    String groupId,
  ) {
    return GroupMemberRoleProvider(
      groupId,
    );
  }

  @override
  GroupMemberRoleProvider getProviderOverride(
    covariant GroupMemberRoleProvider provider,
  ) {
    return call(
      provider.groupId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'groupMemberRoleProvider';
}

/// Get member role in a group
///
/// Copied from [groupMemberRole].
class GroupMemberRoleProvider extends AutoDisposeProvider<MemberRole> {
  /// Get member role in a group
  ///
  /// Copied from [groupMemberRole].
  GroupMemberRoleProvider(
    String groupId,
  ) : this._internal(
          (ref) => groupMemberRole(
            ref as GroupMemberRoleRef,
            groupId,
          ),
          from: groupMemberRoleProvider,
          name: r'groupMemberRoleProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupMemberRoleHash,
          dependencies: GroupMemberRoleFamily._dependencies,
          allTransitiveDependencies:
              GroupMemberRoleFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  GroupMemberRoleProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    MemberRole Function(GroupMemberRoleRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GroupMemberRoleProvider._internal(
        (ref) => create(ref as GroupMemberRoleRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<MemberRole> createElement() {
    return _GroupMemberRoleProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupMemberRoleProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GroupMemberRoleRef on AutoDisposeProviderRef<MemberRole> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _GroupMemberRoleProviderElement
    extends AutoDisposeProviderElement<MemberRole> with GroupMemberRoleRef {
  _GroupMemberRoleProviderElement(super.provider);

  @override
  String get groupId => (origin as GroupMemberRoleProvider).groupId;
}

String _$groupMembersCountHash() => r'be8151eab5433bd882ca8d2c0c80c662d508b9d8';

/// Get group members count
///
/// Copied from [groupMembersCount].
@ProviderFor(groupMembersCount)
const groupMembersCountProvider = GroupMembersCountFamily();

/// Get group members count
///
/// Copied from [groupMembersCount].
class GroupMembersCountFamily extends Family<int> {
  /// Get group members count
  ///
  /// Copied from [groupMembersCount].
  const GroupMembersCountFamily();

  /// Get group members count
  ///
  /// Copied from [groupMembersCount].
  GroupMembersCountProvider call(
    String groupId,
  ) {
    return GroupMembersCountProvider(
      groupId,
    );
  }

  @override
  GroupMembersCountProvider getProviderOverride(
    covariant GroupMembersCountProvider provider,
  ) {
    return call(
      provider.groupId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'groupMembersCountProvider';
}

/// Get group members count
///
/// Copied from [groupMembersCount].
class GroupMembersCountProvider extends AutoDisposeProvider<int> {
  /// Get group members count
  ///
  /// Copied from [groupMembersCount].
  GroupMembersCountProvider(
    String groupId,
  ) : this._internal(
          (ref) => groupMembersCount(
            ref as GroupMembersCountRef,
            groupId,
          ),
          from: groupMembersCountProvider,
          name: r'groupMembersCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupMembersCountHash,
          dependencies: GroupMembersCountFamily._dependencies,
          allTransitiveDependencies:
              GroupMembersCountFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  GroupMembersCountProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    int Function(GroupMembersCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GroupMembersCountProvider._internal(
        (ref) => create(ref as GroupMembersCountRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<int> createElement() {
    return _GroupMembersCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupMembersCountProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GroupMembersCountRef on AutoDisposeProviderRef<int> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _GroupMembersCountProviderElement extends AutoDisposeProviderElement<int>
    with GroupMembersCountRef {
  _GroupMembersCountProviderElement(super.provider);

  @override
  String get groupId => (origin as GroupMembersCountProvider).groupId;
}

String _$groupPostsCountHash() => r'4a94e77269f0591bfc53a00f7004deeed35914c5';

/// Get group posts count
///
/// Copied from [groupPostsCount].
@ProviderFor(groupPostsCount)
const groupPostsCountProvider = GroupPostsCountFamily();

/// Get group posts count
///
/// Copied from [groupPostsCount].
class GroupPostsCountFamily extends Family<int> {
  /// Get group posts count
  ///
  /// Copied from [groupPostsCount].
  const GroupPostsCountFamily();

  /// Get group posts count
  ///
  /// Copied from [groupPostsCount].
  GroupPostsCountProvider call(
    String groupId,
  ) {
    return GroupPostsCountProvider(
      groupId,
    );
  }

  @override
  GroupPostsCountProvider getProviderOverride(
    covariant GroupPostsCountProvider provider,
  ) {
    return call(
      provider.groupId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'groupPostsCountProvider';
}

/// Get group posts count
///
/// Copied from [groupPostsCount].
class GroupPostsCountProvider extends AutoDisposeProvider<int> {
  /// Get group posts count
  ///
  /// Copied from [groupPostsCount].
  GroupPostsCountProvider(
    String groupId,
  ) : this._internal(
          (ref) => groupPostsCount(
            ref as GroupPostsCountRef,
            groupId,
          ),
          from: groupPostsCountProvider,
          name: r'groupPostsCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupPostsCountHash,
          dependencies: GroupPostsCountFamily._dependencies,
          allTransitiveDependencies:
              GroupPostsCountFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  GroupPostsCountProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    int Function(GroupPostsCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GroupPostsCountProvider._internal(
        (ref) => create(ref as GroupPostsCountRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<int> createElement() {
    return _GroupPostsCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupPostsCountProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GroupPostsCountRef on AutoDisposeProviderRef<int> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _GroupPostsCountProviderElement extends AutoDisposeProviderElement<int>
    with GroupPostsCountRef {
  _GroupPostsCountProviderElement(super.provider);

  @override
  String get groupId => (origin as GroupPostsCountProvider).groupId;
}

String _$isGroupAtMaxCapacityHash() =>
    r'fd0e217fd0efeb2d6513cfd859211322ba7157e4';

/// Check if group is at max capacity
///
/// Copied from [isGroupAtMaxCapacity].
@ProviderFor(isGroupAtMaxCapacity)
const isGroupAtMaxCapacityProvider = IsGroupAtMaxCapacityFamily();

/// Check if group is at max capacity
///
/// Copied from [isGroupAtMaxCapacity].
class IsGroupAtMaxCapacityFamily extends Family<bool> {
  /// Check if group is at max capacity
  ///
  /// Copied from [isGroupAtMaxCapacity].
  const IsGroupAtMaxCapacityFamily();

  /// Check if group is at max capacity
  ///
  /// Copied from [isGroupAtMaxCapacity].
  IsGroupAtMaxCapacityProvider call(
    String groupId,
  ) {
    return IsGroupAtMaxCapacityProvider(
      groupId,
    );
  }

  @override
  IsGroupAtMaxCapacityProvider getProviderOverride(
    covariant IsGroupAtMaxCapacityProvider provider,
  ) {
    return call(
      provider.groupId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'isGroupAtMaxCapacityProvider';
}

/// Check if group is at max capacity
///
/// Copied from [isGroupAtMaxCapacity].
class IsGroupAtMaxCapacityProvider extends AutoDisposeProvider<bool> {
  /// Check if group is at max capacity
  ///
  /// Copied from [isGroupAtMaxCapacity].
  IsGroupAtMaxCapacityProvider(
    String groupId,
  ) : this._internal(
          (ref) => isGroupAtMaxCapacity(
            ref as IsGroupAtMaxCapacityRef,
            groupId,
          ),
          from: isGroupAtMaxCapacityProvider,
          name: r'isGroupAtMaxCapacityProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isGroupAtMaxCapacityHash,
          dependencies: IsGroupAtMaxCapacityFamily._dependencies,
          allTransitiveDependencies:
              IsGroupAtMaxCapacityFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  IsGroupAtMaxCapacityProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    bool Function(IsGroupAtMaxCapacityRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsGroupAtMaxCapacityProvider._internal(
        (ref) => create(ref as IsGroupAtMaxCapacityRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _IsGroupAtMaxCapacityProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsGroupAtMaxCapacityProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsGroupAtMaxCapacityRef on AutoDisposeProviderRef<bool> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _IsGroupAtMaxCapacityProviderElement
    extends AutoDisposeProviderElement<bool> with IsGroupAtMaxCapacityRef {
  _IsGroupAtMaxCapacityProviderElement(super.provider);

  @override
  String get groupId => (origin as IsGroupAtMaxCapacityProvider).groupId;
}

String _$groupMembersCountTextHash() =>
    r'1086575099d993f41b541132352efe35bda271c1';

/// Get formatted members count text
///
/// Copied from [groupMembersCountText].
@ProviderFor(groupMembersCountText)
const groupMembersCountTextProvider = GroupMembersCountTextFamily();

/// Get formatted members count text
///
/// Copied from [groupMembersCountText].
class GroupMembersCountTextFamily extends Family<String> {
  /// Get formatted members count text
  ///
  /// Copied from [groupMembersCountText].
  const GroupMembersCountTextFamily();

  /// Get formatted members count text
  ///
  /// Copied from [groupMembersCountText].
  GroupMembersCountTextProvider call(
    String groupId,
  ) {
    return GroupMembersCountTextProvider(
      groupId,
    );
  }

  @override
  GroupMembersCountTextProvider getProviderOverride(
    covariant GroupMembersCountTextProvider provider,
  ) {
    return call(
      provider.groupId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'groupMembersCountTextProvider';
}

/// Get formatted members count text
///
/// Copied from [groupMembersCountText].
class GroupMembersCountTextProvider extends AutoDisposeProvider<String> {
  /// Get formatted members count text
  ///
  /// Copied from [groupMembersCountText].
  GroupMembersCountTextProvider(
    String groupId,
  ) : this._internal(
          (ref) => groupMembersCountText(
            ref as GroupMembersCountTextRef,
            groupId,
          ),
          from: groupMembersCountTextProvider,
          name: r'groupMembersCountTextProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupMembersCountTextHash,
          dependencies: GroupMembersCountTextFamily._dependencies,
          allTransitiveDependencies:
              GroupMembersCountTextFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  GroupMembersCountTextProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    String Function(GroupMembersCountTextRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GroupMembersCountTextProvider._internal(
        (ref) => create(ref as GroupMembersCountTextRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<String> createElement() {
    return _GroupMembersCountTextProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupMembersCountTextProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GroupMembersCountTextRef on AutoDisposeProviderRef<String> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _GroupMembersCountTextProviderElement
    extends AutoDisposeProviderElement<String> with GroupMembersCountTextRef {
  _GroupMembersCountTextProviderElement(super.provider);

  @override
  String get groupId => (origin as GroupMembersCountTextProvider).groupId;
}

String _$groupPostsCountTextHash() =>
    r'f0f0bd532398426baa3654bc2bce9af99dd75cdd';

/// Get formatted posts count text
///
/// Copied from [groupPostsCountText].
@ProviderFor(groupPostsCountText)
const groupPostsCountTextProvider = GroupPostsCountTextFamily();

/// Get formatted posts count text
///
/// Copied from [groupPostsCountText].
class GroupPostsCountTextFamily extends Family<String> {
  /// Get formatted posts count text
  ///
  /// Copied from [groupPostsCountText].
  const GroupPostsCountTextFamily();

  /// Get formatted posts count text
  ///
  /// Copied from [groupPostsCountText].
  GroupPostsCountTextProvider call(
    String groupId,
  ) {
    return GroupPostsCountTextProvider(
      groupId,
    );
  }

  @override
  GroupPostsCountTextProvider getProviderOverride(
    covariant GroupPostsCountTextProvider provider,
  ) {
    return call(
      provider.groupId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'groupPostsCountTextProvider';
}

/// Get formatted posts count text
///
/// Copied from [groupPostsCountText].
class GroupPostsCountTextProvider extends AutoDisposeProvider<String> {
  /// Get formatted posts count text
  ///
  /// Copied from [groupPostsCountText].
  GroupPostsCountTextProvider(
    String groupId,
  ) : this._internal(
          (ref) => groupPostsCountText(
            ref as GroupPostsCountTextRef,
            groupId,
          ),
          from: groupPostsCountTextProvider,
          name: r'groupPostsCountTextProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupPostsCountTextHash,
          dependencies: GroupPostsCountTextFamily._dependencies,
          allTransitiveDependencies:
              GroupPostsCountTextFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  GroupPostsCountTextProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    String Function(GroupPostsCountTextRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GroupPostsCountTextProvider._internal(
        (ref) => create(ref as GroupPostsCountTextRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<String> createElement() {
    return _GroupPostsCountTextProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupPostsCountTextProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GroupPostsCountTextRef on AutoDisposeProviderRef<String> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _GroupPostsCountTextProviderElement
    extends AutoDisposeProviderElement<String> with GroupPostsCountTextRef {
  _GroupPostsCountTextProviderElement(super.provider);

  @override
  String get groupId => (origin as GroupPostsCountTextProvider).groupId;
}

String _$groupPostsHash() => r'a42c9cb2262b99c59d98d55487140f2bcfb22b49';

/// Get posts for a specific group
///
/// Copied from [groupPosts].
@ProviderFor(groupPosts)
const groupPostsProvider = GroupPostsFamily();

/// Get posts for a specific group
///
/// Copied from [groupPosts].
class GroupPostsFamily extends Family<List<VideoModel>> {
  /// Get posts for a specific group
  ///
  /// Copied from [groupPosts].
  const GroupPostsFamily();

  /// Get posts for a specific group
  ///
  /// Copied from [groupPosts].
  GroupPostsProvider call(
    String groupId,
  ) {
    return GroupPostsProvider(
      groupId,
    );
  }

  @override
  GroupPostsProvider getProviderOverride(
    covariant GroupPostsProvider provider,
  ) {
    return call(
      provider.groupId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'groupPostsProvider';
}

/// Get posts for a specific group
///
/// Copied from [groupPosts].
class GroupPostsProvider extends AutoDisposeProvider<List<VideoModel>> {
  /// Get posts for a specific group
  ///
  /// Copied from [groupPosts].
  GroupPostsProvider(
    String groupId,
  ) : this._internal(
          (ref) => groupPosts(
            ref as GroupPostsRef,
            groupId,
          ),
          from: groupPostsProvider,
          name: r'groupPostsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupPostsHash,
          dependencies: GroupPostsFamily._dependencies,
          allTransitiveDependencies:
              GroupPostsFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  GroupPostsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    List<VideoModel> Function(GroupPostsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GroupPostsProvider._internal(
        (ref) => create(ref as GroupPostsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<List<VideoModel>> createElement() {
    return _GroupPostsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupPostsProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GroupPostsRef on AutoDisposeProviderRef<List<VideoModel>> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _GroupPostsProviderElement
    extends AutoDisposeProviderElement<List<VideoModel>> with GroupPostsRef {
  _GroupPostsProviderElement(super.provider);

  @override
  String get groupId => (origin as GroupPostsProvider).groupId;
}

String _$groupPostCountHash() => r'd6c4bbf00a4de2f643690ebfbdc50ab483ff5aa6';

/// Get post count for a group
///
/// Copied from [groupPostCount].
@ProviderFor(groupPostCount)
const groupPostCountProvider = GroupPostCountFamily();

/// Get post count for a group
///
/// Copied from [groupPostCount].
class GroupPostCountFamily extends Family<int> {
  /// Get post count for a group
  ///
  /// Copied from [groupPostCount].
  const GroupPostCountFamily();

  /// Get post count for a group
  ///
  /// Copied from [groupPostCount].
  GroupPostCountProvider call(
    String groupId,
  ) {
    return GroupPostCountProvider(
      groupId,
    );
  }

  @override
  GroupPostCountProvider getProviderOverride(
    covariant GroupPostCountProvider provider,
  ) {
    return call(
      provider.groupId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'groupPostCountProvider';
}

/// Get post count for a group
///
/// Copied from [groupPostCount].
class GroupPostCountProvider extends AutoDisposeProvider<int> {
  /// Get post count for a group
  ///
  /// Copied from [groupPostCount].
  GroupPostCountProvider(
    String groupId,
  ) : this._internal(
          (ref) => groupPostCount(
            ref as GroupPostCountRef,
            groupId,
          ),
          from: groupPostCountProvider,
          name: r'groupPostCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupPostCountHash,
          dependencies: GroupPostCountFamily._dependencies,
          allTransitiveDependencies:
              GroupPostCountFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  GroupPostCountProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    int Function(GroupPostCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GroupPostCountProvider._internal(
        (ref) => create(ref as GroupPostCountRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<int> createElement() {
    return _GroupPostCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupPostCountProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GroupPostCountRef on AutoDisposeProviderRef<int> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _GroupPostCountProviderElement extends AutoDisposeProviderElement<int>
    with GroupPostCountRef {
  _GroupPostCountProviderElement(super.provider);

  @override
  String get groupId => (origin as GroupPostCountProvider).groupId;
}

String _$isGroupsConnectedHash() => r'd1d8badcf4ba44776e7641c18a8984e026959a5f';

/// Check if groups are connected
///
/// Copied from [isGroupsConnected].
@ProviderFor(isGroupsConnected)
final isGroupsConnectedProvider = AutoDisposeProvider<bool>.internal(
  isGroupsConnected,
  name: r'isGroupsConnectedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isGroupsConnectedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsGroupsConnectedRef = AutoDisposeProviderRef<bool>;
String _$isGroupsLoadingHash() => r'9b2ab4a0fc3b12bd4a4ac81c4cf5071b7217af81';

/// Check if groups are loading
///
/// Copied from [isGroupsLoading].
@ProviderFor(isGroupsLoading)
final isGroupsLoadingProvider = AutoDisposeProvider<bool>.internal(
  isGroupsLoading,
  name: r'isGroupsLoadingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isGroupsLoadingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsGroupsLoadingRef = AutoDisposeProviderRef<bool>;
String _$groupsErrorHash() => r'c7c2460ab803a2fa9cfbf7029f8df5fb795b45fd';

/// Get groups error if any
///
/// Copied from [groupsError].
@ProviderFor(groupsError)
final groupsErrorProvider = AutoDisposeProvider<String?>.internal(
  groupsError,
  name: r'groupsErrorProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$groupsErrorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GroupsErrorRef = AutoDisposeProviderRef<String?>;
String _$lastGroupsSyncHash() => r'e0423c8d6b622c7d15cf4d92e3affec17e96592e';

/// Get last sync time
///
/// Copied from [lastGroupsSync].
@ProviderFor(lastGroupsSync)
final lastGroupsSyncProvider = AutoDisposeProvider<DateTime?>.internal(
  lastGroupsSync,
  name: r'lastGroupsSyncProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$lastGroupsSyncHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LastGroupsSyncRef = AutoDisposeProviderRef<DateTime?>;
String _$adminGroupsHash() => r'652df281a8253be2cb9e679af83d0e80e0a7bd98';

/// Get groups where user is admin
///
/// Copied from [adminGroups].
@ProviderFor(adminGroups)
final adminGroupsProvider = AutoDisposeProvider<List<GroupModel>>.internal(
  adminGroups,
  name: r'adminGroupsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$adminGroupsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdminGroupsRef = AutoDisposeProviderRef<List<GroupModel>>;
String _$moderatorGroupsHash() => r'475a3f1ff270e2c41a2022e36beede9d50f35d8f';

/// Get groups where user is moderator
///
/// Copied from [moderatorGroups].
@ProviderFor(moderatorGroups)
final moderatorGroupsProvider = AutoDisposeProvider<List<GroupModel>>.internal(
  moderatorGroups,
  name: r'moderatorGroupsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$moderatorGroupsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ModeratorGroupsRef = AutoDisposeProviderRef<List<GroupModel>>;
String _$totalGroupCountHash() => r'38a3d043b8c92a26ac5c98473e417e3686e35957';

/// Get total group count
///
/// Copied from [totalGroupCount].
@ProviderFor(totalGroupCount)
final totalGroupCountProvider = AutoDisposeProvider<int>.internal(
  totalGroupCount,
  name: r'totalGroupCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalGroupCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TotalGroupCountRef = AutoDisposeProviderRef<int>;
String _$myGroupCountHash() => r'd257f6e9ee6cc3ad6b538b75aa8b7f400c5b2291';

/// Get my group count
///
/// Copied from [myGroupCount].
@ProviderFor(myGroupCount)
final myGroupCountProvider = AutoDisposeProvider<int>.internal(
  myGroupCount,
  name: r'myGroupCountProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$myGroupCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyGroupCountRef = AutoDisposeProviderRef<int>;
String _$featuredGroupCountHash() =>
    r'92267ac819e0351c07e8773ead43fae5c7c43da0';

/// Get featured group count
///
/// Copied from [featuredGroupCount].
@ProviderFor(featuredGroupCount)
final featuredGroupCountProvider = AutoDisposeProvider<int>.internal(
  featuredGroupCount,
  name: r'featuredGroupCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$featuredGroupCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FeaturedGroupCountRef = AutoDisposeProviderRef<int>;
String _$publicGroupCountHash() => r'cc307386afdd30bd9a90ed43edc012468ba95e3e';

/// Get public group count
///
/// Copied from [publicGroupCount].
@ProviderFor(publicGroupCount)
final publicGroupCountProvider = AutoDisposeProvider<int>.internal(
  publicGroupCount,
  name: r'publicGroupCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$publicGroupCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PublicGroupCountRef = AutoDisposeProviderRef<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

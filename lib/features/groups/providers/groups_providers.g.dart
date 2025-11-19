// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'groups_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$groupApiServiceHash() => r'9eec9531f736e4cf9276d8a9f041a1006d17d5b9';

/// See also [groupApiService].
@ProviderFor(groupApiService)
final groupApiServiceProvider = AutoDisposeProvider<GroupApiService>.internal(
  groupApiService,
  name: r'groupApiServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$groupApiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GroupApiServiceRef = AutoDisposeProviderRef<GroupApiService>;
String _$groupWebSocketServiceHash() =>
    r'c09c31ccff48081c1f66c3bd656586ea20c9fe7f';

/// See also [groupWebSocketService].
@ProviderFor(groupWebSocketService)
final groupWebSocketServiceProvider =
    AutoDisposeProvider<GroupWebSocketService>.internal(
  groupWebSocketService,
  name: r'groupWebSocketServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$groupWebSocketServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GroupWebSocketServiceRef
    = AutoDisposeProviderRef<GroupWebSocketService>;
String _$isGroupAdminHash() => r'f966774b2e4a7403b6153b39cc20d462ffed5cbf';

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

/// See also [isGroupAdmin].
@ProviderFor(isGroupAdmin)
const isGroupAdminProvider = IsGroupAdminFamily();

/// See also [isGroupAdmin].
class IsGroupAdminFamily extends Family<AsyncValue<bool>> {
  /// See also [isGroupAdmin].
  const IsGroupAdminFamily();

  /// See also [isGroupAdmin].
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

/// See also [isGroupAdmin].
class IsGroupAdminProvider extends AutoDisposeFutureProvider<bool> {
  /// See also [isGroupAdmin].
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
    FutureOr<bool> Function(IsGroupAdminRef provider) create,
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
  AutoDisposeFutureProviderElement<bool> createElement() {
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
mixin IsGroupAdminRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _IsGroupAdminProviderElement
    extends AutoDisposeFutureProviderElement<bool> with IsGroupAdminRef {
  _IsGroupAdminProviderElement(super.provider);

  @override
  String get groupId => (origin as IsGroupAdminProvider).groupId;
}

String _$currentUserMembershipHash() =>
    r'9738bc86d8f7ba1a5ed7afa7e2e0fdc491a567b0';

/// See also [currentUserMembership].
@ProviderFor(currentUserMembership)
const currentUserMembershipProvider = CurrentUserMembershipFamily();

/// See also [currentUserMembership].
class CurrentUserMembershipFamily
    extends Family<AsyncValue<GroupMemberModel?>> {
  /// See also [currentUserMembership].
  const CurrentUserMembershipFamily();

  /// See also [currentUserMembership].
  CurrentUserMembershipProvider call(
    String groupId,
  ) {
    return CurrentUserMembershipProvider(
      groupId,
    );
  }

  @override
  CurrentUserMembershipProvider getProviderOverride(
    covariant CurrentUserMembershipProvider provider,
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
  String? get name => r'currentUserMembershipProvider';
}

/// See also [currentUserMembership].
class CurrentUserMembershipProvider
    extends AutoDisposeFutureProvider<GroupMemberModel?> {
  /// See also [currentUserMembership].
  CurrentUserMembershipProvider(
    String groupId,
  ) : this._internal(
          (ref) => currentUserMembership(
            ref as CurrentUserMembershipRef,
            groupId,
          ),
          from: currentUserMembershipProvider,
          name: r'currentUserMembershipProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$currentUserMembershipHash,
          dependencies: CurrentUserMembershipFamily._dependencies,
          allTransitiveDependencies:
              CurrentUserMembershipFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  CurrentUserMembershipProvider._internal(
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
    FutureOr<GroupMemberModel?> Function(CurrentUserMembershipRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CurrentUserMembershipProvider._internal(
        (ref) => create(ref as CurrentUserMembershipRef),
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
  AutoDisposeFutureProviderElement<GroupMemberModel?> createElement() {
    return _CurrentUserMembershipProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentUserMembershipProvider && other.groupId == groupId;
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
mixin CurrentUserMembershipRef
    on AutoDisposeFutureProviderRef<GroupMemberModel?> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _CurrentUserMembershipProviderElement
    extends AutoDisposeFutureProviderElement<GroupMemberModel?>
    with CurrentUserMembershipRef {
  _CurrentUserMembershipProviderElement(super.provider);

  @override
  String get groupId => (origin as CurrentUserMembershipProvider).groupId;
}

String _$groupsListHash() => r'1f0e2d733bde6bddee9d4b8fd38e597641911484';

/// See also [GroupsList].
@ProviderFor(GroupsList)
final groupsListProvider =
    AutoDisposeAsyncNotifierProvider<GroupsList, List<GroupModel>>.internal(
  GroupsList.new,
  name: r'groupsListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$groupsListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GroupsList = AutoDisposeAsyncNotifier<List<GroupModel>>;
String _$groupDetailHash() => r'49d92aed27ea0ce924b04b61c481a8944b1d2ace';

abstract class _$GroupDetail
    extends BuildlessAutoDisposeAsyncNotifier<GroupModel> {
  late final String groupId;

  FutureOr<GroupModel> build(
    String groupId,
  );
}

/// See also [GroupDetail].
@ProviderFor(GroupDetail)
const groupDetailProvider = GroupDetailFamily();

/// See also [GroupDetail].
class GroupDetailFamily extends Family<AsyncValue<GroupModel>> {
  /// See also [GroupDetail].
  const GroupDetailFamily();

  /// See also [GroupDetail].
  GroupDetailProvider call(
    String groupId,
  ) {
    return GroupDetailProvider(
      groupId,
    );
  }

  @override
  GroupDetailProvider getProviderOverride(
    covariant GroupDetailProvider provider,
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
  String? get name => r'groupDetailProvider';
}

/// See also [GroupDetail].
class GroupDetailProvider
    extends AutoDisposeAsyncNotifierProviderImpl<GroupDetail, GroupModel> {
  /// See also [GroupDetail].
  GroupDetailProvider(
    String groupId,
  ) : this._internal(
          () => GroupDetail()..groupId = groupId,
          from: groupDetailProvider,
          name: r'groupDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupDetailHash,
          dependencies: GroupDetailFamily._dependencies,
          allTransitiveDependencies:
              GroupDetailFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  GroupDetailProvider._internal(
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
  FutureOr<GroupModel> runNotifierBuild(
    covariant GroupDetail notifier,
  ) {
    return notifier.build(
      groupId,
    );
  }

  @override
  Override overrideWith(GroupDetail Function() create) {
    return ProviderOverride(
      origin: this,
      override: GroupDetailProvider._internal(
        () => create()..groupId = groupId,
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
  AutoDisposeAsyncNotifierProviderElement<GroupDetail, GroupModel>
      createElement() {
    return _GroupDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupDetailProvider && other.groupId == groupId;
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
mixin GroupDetailRef on AutoDisposeAsyncNotifierProviderRef<GroupModel> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _GroupDetailProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<GroupDetail, GroupModel>
    with GroupDetailRef {
  _GroupDetailProviderElement(super.provider);

  @override
  String get groupId => (origin as GroupDetailProvider).groupId;
}

String _$groupMembersHash() => r'a9c85f3e826bdd26128faa69448bb84ed45d9f4d';

abstract class _$GroupMembers
    extends BuildlessAutoDisposeAsyncNotifier<List<GroupMemberModel>> {
  late final String groupId;

  FutureOr<List<GroupMemberModel>> build(
    String groupId,
  );
}

/// See also [GroupMembers].
@ProviderFor(GroupMembers)
const groupMembersProvider = GroupMembersFamily();

/// See also [GroupMembers].
class GroupMembersFamily extends Family<AsyncValue<List<GroupMemberModel>>> {
  /// See also [GroupMembers].
  const GroupMembersFamily();

  /// See also [GroupMembers].
  GroupMembersProvider call(
    String groupId,
  ) {
    return GroupMembersProvider(
      groupId,
    );
  }

  @override
  GroupMembersProvider getProviderOverride(
    covariant GroupMembersProvider provider,
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
  String? get name => r'groupMembersProvider';
}

/// See also [GroupMembers].
class GroupMembersProvider extends AutoDisposeAsyncNotifierProviderImpl<
    GroupMembers, List<GroupMemberModel>> {
  /// See also [GroupMembers].
  GroupMembersProvider(
    String groupId,
  ) : this._internal(
          () => GroupMembers()..groupId = groupId,
          from: groupMembersProvider,
          name: r'groupMembersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupMembersHash,
          dependencies: GroupMembersFamily._dependencies,
          allTransitiveDependencies:
              GroupMembersFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  GroupMembersProvider._internal(
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
  FutureOr<List<GroupMemberModel>> runNotifierBuild(
    covariant GroupMembers notifier,
  ) {
    return notifier.build(
      groupId,
    );
  }

  @override
  Override overrideWith(GroupMembers Function() create) {
    return ProviderOverride(
      origin: this,
      override: GroupMembersProvider._internal(
        () => create()..groupId = groupId,
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
  AutoDisposeAsyncNotifierProviderElement<GroupMembers, List<GroupMemberModel>>
      createElement() {
    return _GroupMembersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupMembersProvider && other.groupId == groupId;
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
mixin GroupMembersRef
    on AutoDisposeAsyncNotifierProviderRef<List<GroupMemberModel>> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _GroupMembersProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<GroupMembers,
        List<GroupMemberModel>> with GroupMembersRef {
  _GroupMembersProviderElement(super.provider);

  @override
  String get groupId => (origin as GroupMembersProvider).groupId;
}

String _$groupMessagesHash() => r'24972a6360d04a20f81ad9a41492065de3c70f07';

abstract class _$GroupMessages
    extends BuildlessAutoDisposeAsyncNotifier<List<GroupMessageModel>> {
  late final String groupId;

  FutureOr<List<GroupMessageModel>> build(
    String groupId,
  );
}

/// See also [GroupMessages].
@ProviderFor(GroupMessages)
const groupMessagesProvider = GroupMessagesFamily();

/// See also [GroupMessages].
class GroupMessagesFamily extends Family<AsyncValue<List<GroupMessageModel>>> {
  /// See also [GroupMessages].
  const GroupMessagesFamily();

  /// See also [GroupMessages].
  GroupMessagesProvider call(
    String groupId,
  ) {
    return GroupMessagesProvider(
      groupId,
    );
  }

  @override
  GroupMessagesProvider getProviderOverride(
    covariant GroupMessagesProvider provider,
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
  String? get name => r'groupMessagesProvider';
}

/// See also [GroupMessages].
class GroupMessagesProvider extends AutoDisposeAsyncNotifierProviderImpl<
    GroupMessages, List<GroupMessageModel>> {
  /// See also [GroupMessages].
  GroupMessagesProvider(
    String groupId,
  ) : this._internal(
          () => GroupMessages()..groupId = groupId,
          from: groupMessagesProvider,
          name: r'groupMessagesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupMessagesHash,
          dependencies: GroupMessagesFamily._dependencies,
          allTransitiveDependencies:
              GroupMessagesFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  GroupMessagesProvider._internal(
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
  FutureOr<List<GroupMessageModel>> runNotifierBuild(
    covariant GroupMessages notifier,
  ) {
    return notifier.build(
      groupId,
    );
  }

  @override
  Override overrideWith(GroupMessages Function() create) {
    return ProviderOverride(
      origin: this,
      override: GroupMessagesProvider._internal(
        () => create()..groupId = groupId,
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
  AutoDisposeAsyncNotifierProviderElement<GroupMessages,
      List<GroupMessageModel>> createElement() {
    return _GroupMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupMessagesProvider && other.groupId == groupId;
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
mixin GroupMessagesRef
    on AutoDisposeAsyncNotifierProviderRef<List<GroupMessageModel>> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _GroupMessagesProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<GroupMessages,
        List<GroupMessageModel>> with GroupMessagesRef {
  _GroupMessagesProviderElement(super.provider);

  @override
  String get groupId => (origin as GroupMessagesProvider).groupId;
}

String _$typingIndicatorHash() => r'3a2e120317f797c20fa0aa2a1f97690a9767660f';

abstract class _$TypingIndicator
    extends BuildlessAutoDisposeNotifier<Map<String, String>> {
  late final String groupId;

  Map<String, String> build(
    String groupId,
  );
}

/// See also [TypingIndicator].
@ProviderFor(TypingIndicator)
const typingIndicatorProvider = TypingIndicatorFamily();

/// See also [TypingIndicator].
class TypingIndicatorFamily extends Family<Map<String, String>> {
  /// See also [TypingIndicator].
  const TypingIndicatorFamily();

  /// See also [TypingIndicator].
  TypingIndicatorProvider call(
    String groupId,
  ) {
    return TypingIndicatorProvider(
      groupId,
    );
  }

  @override
  TypingIndicatorProvider getProviderOverride(
    covariant TypingIndicatorProvider provider,
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
  String? get name => r'typingIndicatorProvider';
}

/// See also [TypingIndicator].
class TypingIndicatorProvider extends AutoDisposeNotifierProviderImpl<
    TypingIndicator, Map<String, String>> {
  /// See also [TypingIndicator].
  TypingIndicatorProvider(
    String groupId,
  ) : this._internal(
          () => TypingIndicator()..groupId = groupId,
          from: typingIndicatorProvider,
          name: r'typingIndicatorProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$typingIndicatorHash,
          dependencies: TypingIndicatorFamily._dependencies,
          allTransitiveDependencies:
              TypingIndicatorFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  TypingIndicatorProvider._internal(
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
  Map<String, String> runNotifierBuild(
    covariant TypingIndicator notifier,
  ) {
    return notifier.build(
      groupId,
    );
  }

  @override
  Override overrideWith(TypingIndicator Function() create) {
    return ProviderOverride(
      origin: this,
      override: TypingIndicatorProvider._internal(
        () => create()..groupId = groupId,
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
  AutoDisposeNotifierProviderElement<TypingIndicator, Map<String, String>>
      createElement() {
    return _TypingIndicatorProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TypingIndicatorProvider && other.groupId == groupId;
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
mixin TypingIndicatorRef
    on AutoDisposeNotifierProviderRef<Map<String, String>> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _TypingIndicatorProviderElement
    extends AutoDisposeNotifierProviderElement<TypingIndicator,
        Map<String, String>> with TypingIndicatorRef {
  _TypingIndicatorProviderElement(super.provider);

  @override
  String get groupId => (origin as TypingIndicatorProvider).groupId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

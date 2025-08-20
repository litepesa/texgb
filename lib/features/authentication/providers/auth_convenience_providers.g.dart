// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_convenience_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentUserHash() => r'9fe48b5c7c981b041c10ec03620a3569e1ea328e';

/// See also [currentUser].
@ProviderFor(currentUser)
final currentUserProvider = AutoDisposeProvider<UserModel?>.internal(
  currentUser,
  name: r'currentUserProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserRef = AutoDisposeProviderRef<UserModel?>;
String _$isAuthenticatedHash() => r'26e01c267d69e672ac8ec3fe4bd65ae68c385de6';

/// See also [isAuthenticated].
@ProviderFor(isAuthenticated)
final isAuthenticatedProvider = AutoDisposeProvider<bool>.internal(
  isAuthenticated,
  name: r'isAuthenticatedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isAuthenticatedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsAuthenticatedRef = AutoDisposeProviderRef<bool>;
String _$isGuestHash() => r'cb5db5b177f8e99d64a2953ce565c70efa9b2537';

/// See also [isGuest].
@ProviderFor(isGuest)
final isGuestProvider = AutoDisposeProvider<bool>.internal(
  isGuest,
  name: r'isGuestProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isGuestHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsGuestRef = AutoDisposeProviderRef<bool>;
String _$isAuthLoadingHash() => r'0e20e2a02e43e83135cc09ba0863bbc54ba2fa90';

/// See also [isAuthLoading].
@ProviderFor(isAuthLoading)
final isAuthLoadingProvider = AutoDisposeProvider<bool>.internal(
  isAuthLoading,
  name: r'isAuthLoadingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isAuthLoadingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsAuthLoadingRef = AutoDisposeProviderRef<bool>;
String _$currentUserIdHash() => r'8cead6f40c44d22fc793fc76bb78b49e87131f58';

/// See also [currentUserId].
@ProviderFor(currentUserId)
final currentUserIdProvider = AutoDisposeProvider<String?>.internal(
  currentUserId,
  name: r'currentUserIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserIdRef = AutoDisposeProviderRef<String?>;
String _$currentPhoneNumberHash() =>
    r'1d4f471252cb85ef44a5348d7ac58514dcd7f4fb';

/// See also [currentPhoneNumber].
@ProviderFor(currentPhoneNumber)
final currentPhoneNumberProvider = AutoDisposeProvider<String?>.internal(
  currentPhoneNumber,
  name: r'currentPhoneNumberProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentPhoneNumberHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentPhoneNumberRef = AutoDisposeProviderRef<String?>;
String _$videosHash() => r'68c65e599ae60304ff3efecf659cbfc2d068f070';

/// See also [videos].
@ProviderFor(videos)
final videosProvider = AutoDisposeProvider<List<VideoModel>>.internal(
  videos,
  name: r'videosProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$videosHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef VideosRef = AutoDisposeProviderRef<List<VideoModel>>;
String _$usersHash() => r'347cb457fff55a09b087d3edba9f4d0faa8ca2ce';

/// See also [users].
@ProviderFor(users)
final usersProvider = AutoDisposeProvider<List<UserModel>>.internal(
  users,
  name: r'usersProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$usersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UsersRef = AutoDisposeProviderRef<List<UserModel>>;
String _$likedVideosHash() => r'a78615342b14154b15eb455de00bbde8a01725be';

/// See also [likedVideos].
@ProviderFor(likedVideos)
final likedVideosProvider = AutoDisposeProvider<List<String>>.internal(
  likedVideos,
  name: r'likedVideosProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$likedVideosHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LikedVideosRef = AutoDisposeProviderRef<List<String>>;
String _$followedUsersHash() => r'd8a37fefd528ac31729d96dd096c11a6ea5f1bb1';

/// See also [followedUsers].
@ProviderFor(followedUsers)
final followedUsersProvider = AutoDisposeProvider<List<String>>.internal(
  followedUsers,
  name: r'followedUsersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$followedUsersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FollowedUsersRef = AutoDisposeProviderRef<List<String>>;
String _$isVideoLikedHash() => r'fd16aac965a1e32746a2f20f2a7a810e68015bca';

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

/// See also [isVideoLiked].
@ProviderFor(isVideoLiked)
const isVideoLikedProvider = IsVideoLikedFamily();

/// See also [isVideoLiked].
class IsVideoLikedFamily extends Family<bool> {
  /// See also [isVideoLiked].
  const IsVideoLikedFamily();

  /// See also [isVideoLiked].
  IsVideoLikedProvider call(
    String videoId,
  ) {
    return IsVideoLikedProvider(
      videoId,
    );
  }

  @override
  IsVideoLikedProvider getProviderOverride(
    covariant IsVideoLikedProvider provider,
  ) {
    return call(
      provider.videoId,
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
  String? get name => r'isVideoLikedProvider';
}

/// See also [isVideoLiked].
class IsVideoLikedProvider extends AutoDisposeProvider<bool> {
  /// See also [isVideoLiked].
  IsVideoLikedProvider(
    String videoId,
  ) : this._internal(
          (ref) => isVideoLiked(
            ref as IsVideoLikedRef,
            videoId,
          ),
          from: isVideoLikedProvider,
          name: r'isVideoLikedProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isVideoLikedHash,
          dependencies: IsVideoLikedFamily._dependencies,
          allTransitiveDependencies:
              IsVideoLikedFamily._allTransitiveDependencies,
          videoId: videoId,
        );

  IsVideoLikedProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.videoId,
  }) : super.internal();

  final String videoId;

  @override
  Override overrideWith(
    bool Function(IsVideoLikedRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsVideoLikedProvider._internal(
        (ref) => create(ref as IsVideoLikedRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        videoId: videoId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _IsVideoLikedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsVideoLikedProvider && other.videoId == videoId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, videoId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsVideoLikedRef on AutoDisposeProviderRef<bool> {
  /// The parameter `videoId` of this provider.
  String get videoId;
}

class _IsVideoLikedProviderElement extends AutoDisposeProviderElement<bool>
    with IsVideoLikedRef {
  _IsVideoLikedProviderElement(super.provider);

  @override
  String get videoId => (origin as IsVideoLikedProvider).videoId;
}

String _$isUserFollowedHash() => r'017bb86ee143e74d4f9192a94f3a616fb1dba6d8';

/// See also [isUserFollowed].
@ProviderFor(isUserFollowed)
const isUserFollowedProvider = IsUserFollowedFamily();

/// See also [isUserFollowed].
class IsUserFollowedFamily extends Family<bool> {
  /// See also [isUserFollowed].
  const IsUserFollowedFamily();

  /// See also [isUserFollowed].
  IsUserFollowedProvider call(
    String userId,
  ) {
    return IsUserFollowedProvider(
      userId,
    );
  }

  @override
  IsUserFollowedProvider getProviderOverride(
    covariant IsUserFollowedProvider provider,
  ) {
    return call(
      provider.userId,
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
  String? get name => r'isUserFollowedProvider';
}

/// See also [isUserFollowed].
class IsUserFollowedProvider extends AutoDisposeProvider<bool> {
  /// See also [isUserFollowed].
  IsUserFollowedProvider(
    String userId,
  ) : this._internal(
          (ref) => isUserFollowed(
            ref as IsUserFollowedRef,
            userId,
          ),
          from: isUserFollowedProvider,
          name: r'isUserFollowedProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isUserFollowedHash,
          dependencies: IsUserFollowedFamily._dependencies,
          allTransitiveDependencies:
              IsUserFollowedFamily._allTransitiveDependencies,
          userId: userId,
        );

  IsUserFollowedProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    bool Function(IsUserFollowedRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsUserFollowedProvider._internal(
        (ref) => create(ref as IsUserFollowedRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _IsUserFollowedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsUserFollowedProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsUserFollowedRef on AutoDisposeProviderRef<bool> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _IsUserFollowedProviderElement extends AutoDisposeProviderElement<bool>
    with IsUserFollowedRef {
  _IsUserFollowedProviderElement(super.provider);

  @override
  String get userId => (origin as IsUserFollowedProvider).userId;
}

String _$authStateHash() => r'7c8e6c2b335da7a0778bcabe8d53bf1de4bfafd6';

/// See also [authState].
@ProviderFor(authState)
final authStateProvider = AutoDisposeProvider<AuthState>.internal(
  authState,
  name: r'authStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthStateRef = AutoDisposeProviderRef<AuthState>;
String _$authErrorHash() => r'0362323894cac7b52ed1d01c3be442f428e87d1f';

/// See also [authError].
@ProviderFor(authError)
final authErrorProvider = AutoDisposeProvider<String?>.internal(
  authError,
  name: r'authErrorProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authErrorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthErrorRef = AutoDisposeProviderRef<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

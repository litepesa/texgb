// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marketplace_convenience_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$marketplaceVideosHash() => r'c9de6a5bf7a1bd16f7dfa476245387f33101c722';

/// See also [marketplaceVideos].
@ProviderFor(marketplaceVideos)
final marketplaceVideosProvider =
    AutoDisposeProvider<List<MarketplaceVideoModel>>.internal(
  marketplaceVideos,
  name: r'marketplaceVideosProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$marketplaceVideosHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MarketplaceVideosRef
    = AutoDisposeProviderRef<List<MarketplaceVideoModel>>;
String _$likedMarketplaceVideosHash() =>
    r'3c65e6a76137d3fad99f4b92630129e66eabb8ea';

/// See also [likedMarketplaceVideos].
@ProviderFor(likedMarketplaceVideos)
final likedMarketplaceVideosProvider =
    AutoDisposeProvider<List<String>>.internal(
  likedMarketplaceVideos,
  name: r'likedMarketplaceVideosProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$likedMarketplaceVideosHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LikedMarketplaceVideosRef = AutoDisposeProviderRef<List<String>>;
String _$isMarketplaceUploadingHash() =>
    r'4a109c00c1939bc3383e436e99a5287881c53c69';

/// See also [isMarketplaceUploading].
@ProviderFor(isMarketplaceUploading)
final isMarketplaceUploadingProvider = AutoDisposeProvider<bool>.internal(
  isMarketplaceUploading,
  name: r'isMarketplaceUploadingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isMarketplaceUploadingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsMarketplaceUploadingRef = AutoDisposeProviderRef<bool>;
String _$marketplaceUploadProgressHash() =>
    r'6deaf2c3430a078a1dccd8a541220ab03e9f7461';

/// See also [marketplaceUploadProgress].
@ProviderFor(marketplaceUploadProgress)
final marketplaceUploadProgressProvider = AutoDisposeProvider<double>.internal(
  marketplaceUploadProgress,
  name: r'marketplaceUploadProgressProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$marketplaceUploadProgressHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MarketplaceUploadProgressRef = AutoDisposeProviderRef<double>;
String _$isMarketplaceVideoLikedHash() =>
    r'77285d52dc05385b201ae18f573fef905d9becc3';

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

/// See also [isMarketplaceVideoLiked].
@ProviderFor(isMarketplaceVideoLiked)
const isMarketplaceVideoLikedProvider = IsMarketplaceVideoLikedFamily();

/// See also [isMarketplaceVideoLiked].
class IsMarketplaceVideoLikedFamily extends Family<bool> {
  /// See also [isMarketplaceVideoLiked].
  const IsMarketplaceVideoLikedFamily();

  /// See also [isMarketplaceVideoLiked].
  IsMarketplaceVideoLikedProvider call(
    String videoId,
  ) {
    return IsMarketplaceVideoLikedProvider(
      videoId,
    );
  }

  @override
  IsMarketplaceVideoLikedProvider getProviderOverride(
    covariant IsMarketplaceVideoLikedProvider provider,
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
  String? get name => r'isMarketplaceVideoLikedProvider';
}

/// See also [isMarketplaceVideoLiked].
class IsMarketplaceVideoLikedProvider extends AutoDisposeProvider<bool> {
  /// See also [isMarketplaceVideoLiked].
  IsMarketplaceVideoLikedProvider(
    String videoId,
  ) : this._internal(
          (ref) => isMarketplaceVideoLiked(
            ref as IsMarketplaceVideoLikedRef,
            videoId,
          ),
          from: isMarketplaceVideoLikedProvider,
          name: r'isMarketplaceVideoLikedProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isMarketplaceVideoLikedHash,
          dependencies: IsMarketplaceVideoLikedFamily._dependencies,
          allTransitiveDependencies:
              IsMarketplaceVideoLikedFamily._allTransitiveDependencies,
          videoId: videoId,
        );

  IsMarketplaceVideoLikedProvider._internal(
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
    bool Function(IsMarketplaceVideoLikedRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsMarketplaceVideoLikedProvider._internal(
        (ref) => create(ref as IsMarketplaceVideoLikedRef),
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
    return _IsMarketplaceVideoLikedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsMarketplaceVideoLikedProvider && other.videoId == videoId;
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
mixin IsMarketplaceVideoLikedRef on AutoDisposeProviderRef<bool> {
  /// The parameter `videoId` of this provider.
  String get videoId;
}

class _IsMarketplaceVideoLikedProviderElement
    extends AutoDisposeProviderElement<bool> with IsMarketplaceVideoLikedRef {
  _IsMarketplaceVideoLikedProviderElement(super.provider);

  @override
  String get videoId => (origin as IsMarketplaceVideoLikedProvider).videoId;
}

String _$marketplaceErrorHash() => r'76453370bea54fb4498872fe43e640e2b11f00f5';

/// See also [marketplaceError].
@ProviderFor(marketplaceError)
final marketplaceErrorProvider = AutoDisposeProvider<String?>.internal(
  marketplaceError,
  name: r'marketplaceErrorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$marketplaceErrorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MarketplaceErrorRef = AutoDisposeProviderRef<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

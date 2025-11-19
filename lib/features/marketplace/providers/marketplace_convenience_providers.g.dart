// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marketplace_convenience_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$marketplaceItemsHash() => r'b8c8e8e73f74253ac8a04dcf035492c94127e8ab';

/// Convenience provider to get marketplace items
///
/// Copied from [marketplaceItems].
@ProviderFor(marketplaceItems)
final marketplaceItemsProvider =
    AutoDisposeProvider<List<MarketplaceItemModel>>.internal(
  marketplaceItems,
  name: r'marketplaceItemsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$marketplaceItemsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MarketplaceItemsRef = AutoDisposeProviderRef<List<MarketplaceItemModel>>;
String _$likedMarketplaceItemsHash() =>
    r'a3d9f9f84f74253ac8a04dcf035492c94127e8ab';

/// Convenience provider to get liked marketplace items
///
/// Copied from [likedMarketplaceItems].
@ProviderFor(likedMarketplaceItems)
final likedMarketplaceItemsProvider = AutoDisposeProvider<List<String>>.internal(
  likedMarketplaceItems,
  name: r'likedMarketplaceItemsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$likedMarketplaceItemsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LikedMarketplaceItemsRef = AutoDisposeProviderRef<List<String>>;
String _$isMarketplaceUploadingHash() =>
    r'c5e0f0f95f74253ac8a04dcf035492c94127e8ab';

/// Convenience provider to check if marketplace is uploading
///
/// Copied from [isMarketplaceUploading].
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

typedef IsMarketplaceUploadingRef = AutoDisposeProviderRef<bool>;
String _$marketplaceUploadProgressHash() =>
    r'd6f1f1f06f74253ac8a04dcf035492c94127e8ab';

/// Convenience provider to get marketplace upload progress
///
/// Copied from [marketplaceUploadProgress].
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

typedef MarketplaceUploadProgressRef = AutoDisposeProviderRef<double>;
String _$isMarketplaceItemLikedHash() =>
    r'e7g2g2g17f74253ac8a04dcf035492c94127e8ab';

/// Helper method as provider to check if item is liked
///
/// Copied from [isMarketplaceItemLiked].
@ProviderFor(isMarketplaceItemLiked)
const isMarketplaceItemLikedProvider = IsMarketplaceItemLikedFamily();

/// Helper method as provider to check if item is liked
///
/// Copied from [isMarketplaceItemLiked].
class IsMarketplaceItemLikedFamily extends Family<bool> {
  /// Helper method as provider to check if item is liked
  ///
  /// Copied from [isMarketplaceItemLiked].
  const IsMarketplaceItemLikedFamily();

  /// Helper method as provider to check if item is liked
  ///
  /// Copied from [isMarketplaceItemLiked].
  IsMarketplaceItemLikedProvider call(
    String itemId,
  ) {
    return IsMarketplaceItemLikedProvider(
      itemId,
    );
  }

  @override
  IsMarketplaceItemLikedProvider getProviderOverride(
    covariant IsMarketplaceItemLikedProvider provider,
  ) {
    return call(
      provider.itemId,
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
  String? get name => r'isMarketplaceItemLikedProvider';
}

/// Helper method as provider to check if item is liked
///
/// Copied from [isMarketplaceItemLiked].
class IsMarketplaceItemLikedProvider extends AutoDisposeProvider<bool> {
  /// Helper method as provider to check if item is liked
  ///
  /// Copied from [isMarketplaceItemLiked].
  IsMarketplaceItemLikedProvider(
    String itemId,
  ) : this._internal(
          (ref) => isMarketplaceItemLiked(
            ref as IsMarketplaceItemLikedRef,
            itemId,
          ),
          from: isMarketplaceItemLikedProvider,
          name: r'isMarketplaceItemLikedProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isMarketplaceItemLikedHash,
          dependencies: IsMarketplaceItemLikedFamily._dependencies,
          allTransitiveDependencies:
              IsMarketplaceItemLikedFamily._allTransitiveDependencies,
          itemId: itemId,
        );

  IsMarketplaceItemLikedProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.itemId,
  }) : super.internal();

  final String itemId;

  @override
  Override overrideWith(
    bool Function(IsMarketplaceItemLikedRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsMarketplaceItemLikedProvider._internal(
        (ref) => create(ref as IsMarketplaceItemLikedRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        itemId: itemId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _IsMarketplaceItemLikedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsMarketplaceItemLikedProvider && other.itemId == itemId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, itemId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin IsMarketplaceItemLikedRef on AutoDisposeProviderRef<bool> {
  /// The parameter `itemId` of this provider.
  String get itemId;
}

class _IsMarketplaceItemLikedProviderElement
    extends AutoDisposeProviderElement<bool> with IsMarketplaceItemLikedRef {
  _IsMarketplaceItemLikedProviderElement(super.provider);

  @override
  String get itemId => (origin as IsMarketplaceItemLikedProvider).itemId;
}

String _$marketplaceErrorHash() => r'f8h3h3h28f74253ac8a04dcf035492c94127e8ab';

/// Error provider
///
/// Copied from [marketplaceError].
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

typedef MarketplaceErrorRef = AutoDisposeProviderRef<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

final _System Hash = $Hash();

class $Hash {
  static int combine(int hash, int value) {
    // Jenkins hash function
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

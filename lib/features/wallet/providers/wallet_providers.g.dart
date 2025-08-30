// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$walletRepositoryHash() => r'5c5ae0611279fce205eeee4ab2d602a9950dccec';

/// See also [walletRepository].
@ProviderFor(walletRepository)
final walletRepositoryProvider = AutoDisposeProvider<WalletRepository>.internal(
  walletRepository,
  name: r'walletRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$walletRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WalletRepositoryRef = AutoDisposeProviderRef<WalletRepository>;
String _$walletStreamHash() => r'75eff376b47aadaeab5d21a7ab89d6299ce7b8e2';

/// See also [walletStream].
@ProviderFor(walletStream)
final walletStreamProvider = AutoDisposeStreamProvider<WalletModel?>.internal(
  walletStream,
  name: r'walletStreamProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$walletStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WalletStreamRef = AutoDisposeStreamProviderRef<WalletModel?>;
String _$transactionsStreamHash() =>
    r'cb21d3c310a57b8c8caff92908190de4ece98a40';

/// See also [transactionsStream].
@ProviderFor(transactionsStream)
final transactionsStreamProvider =
    AutoDisposeStreamProvider<List<WalletTransaction>>.internal(
  transactionsStream,
  name: r'transactionsStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$transactionsStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TransactionsStreamRef
    = AutoDisposeStreamProviderRef<List<WalletTransaction>>;
String _$coinsBalanceHash() => r'5e8f7bc690c5a583ba8eb3540bbcfcae714b85fc';

/// See also [coinsBalance].
@ProviderFor(coinsBalance)
final coinsBalanceProvider = AutoDisposeProvider<int?>.internal(
  coinsBalance,
  name: r'coinsBalanceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$coinsBalanceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CoinsBalanceRef = AutoDisposeProviderRef<int?>;
String _$hasCoinsHash() => r'd2c88f8f7d1e354c933b84fe6848d13ef0e34777';

/// See also [hasCoins].
@ProviderFor(hasCoins)
final hasCoinsProvider = AutoDisposeProvider<bool>.internal(
  hasCoins,
  name: r'hasCoinsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$hasCoinsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HasCoinsRef = AutoDisposeProviderRef<bool>;
String _$canAffordCoinsHash() => r'b2e2a36e3a33083da5b6a8cbd82272b7710bcd53';

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

/// See also [canAffordCoins].
@ProviderFor(canAffordCoins)
const canAffordCoinsProvider = CanAffordCoinsFamily();

/// See also [canAffordCoins].
class CanAffordCoinsFamily extends Family<bool> {
  /// See also [canAffordCoins].
  const CanAffordCoinsFamily();

  /// See also [canAffordCoins].
  CanAffordCoinsProvider call(
    int coinAmount,
  ) {
    return CanAffordCoinsProvider(
      coinAmount,
    );
  }

  @override
  CanAffordCoinsProvider getProviderOverride(
    covariant CanAffordCoinsProvider provider,
  ) {
    return call(
      provider.coinAmount,
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
  String? get name => r'canAffordCoinsProvider';
}

/// See also [canAffordCoins].
class CanAffordCoinsProvider extends AutoDisposeProvider<bool> {
  /// See also [canAffordCoins].
  CanAffordCoinsProvider(
    int coinAmount,
  ) : this._internal(
          (ref) => canAffordCoins(
            ref as CanAffordCoinsRef,
            coinAmount,
          ),
          from: canAffordCoinsProvider,
          name: r'canAffordCoinsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$canAffordCoinsHash,
          dependencies: CanAffordCoinsFamily._dependencies,
          allTransitiveDependencies:
              CanAffordCoinsFamily._allTransitiveDependencies,
          coinAmount: coinAmount,
        );

  CanAffordCoinsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.coinAmount,
  }) : super.internal();

  final int coinAmount;

  @override
  Override overrideWith(
    bool Function(CanAffordCoinsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CanAffordCoinsProvider._internal(
        (ref) => create(ref as CanAffordCoinsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        coinAmount: coinAmount,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _CanAffordCoinsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CanAffordCoinsProvider && other.coinAmount == coinAmount;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, coinAmount.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CanAffordCoinsRef on AutoDisposeProviderRef<bool> {
  /// The parameter `coinAmount` of this provider.
  int get coinAmount;
}

class _CanAffordCoinsProviderElement extends AutoDisposeProviderElement<bool>
    with CanAffordCoinsRef {
  _CanAffordCoinsProviderElement(super.provider);

  @override
  int get coinAmount => (origin as CanAffordCoinsProvider).coinAmount;
}

String _$availableCoinPackagesHash() =>
    r'a974b09c1db4f590beaa77185f76a4046c00c9ea';

/// See also [availableCoinPackages].
@ProviderFor(availableCoinPackages)
final availableCoinPackagesProvider =
    AutoDisposeProvider<List<CoinPackage>>.internal(
  availableCoinPackages,
  name: r'availableCoinPackagesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$availableCoinPackagesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AvailableCoinPackagesRef = AutoDisposeProviderRef<List<CoinPackage>>;
String _$walletHash() => r'53c8c5b71eaf0de7ef3fbb78a512d1d20bdb9ae0';

/// See also [Wallet].
@ProviderFor(Wallet)
final walletProvider =
    AutoDisposeAsyncNotifierProvider<Wallet, WalletState>.internal(
  Wallet.new,
  name: r'walletProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$walletHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Wallet = AutoDisposeAsyncNotifier<WalletState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$walletRepositoryHash() => r'eeedf944cc5db96a7ede5a0a79f3a4e0eaaabf16';

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
String _$walletBalanceHash() => r'ff418fbaabb93acf308e7a78daecb99c17751098';

/// See also [walletBalance].
@ProviderFor(walletBalance)
final walletBalanceProvider = AutoDisposeProvider<double?>.internal(
  walletBalance,
  name: r'walletBalanceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$walletBalanceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WalletBalanceRef = AutoDisposeProviderRef<double?>;
String _$hasWalletBalanceHash() => r'5a2a23548bf17026475467cb670f754cb06d0d85';

/// See also [hasWalletBalance].
@ProviderFor(hasWalletBalance)
final hasWalletBalanceProvider = AutoDisposeProvider<bool>.internal(
  hasWalletBalance,
  name: r'hasWalletBalanceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasWalletBalanceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HasWalletBalanceRef = AutoDisposeProviderRef<bool>;
String _$canAffordHash() => r'a9ba7f06ef735c71199eed4a154cb4cf60ddb418';

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

/// See also [canAfford].
@ProviderFor(canAfford)
const canAffordProvider = CanAffordFamily();

/// See also [canAfford].
class CanAffordFamily extends Family<bool> {
  /// See also [canAfford].
  const CanAffordFamily();

  /// See also [canAfford].
  CanAffordProvider call(
    double amount,
  ) {
    return CanAffordProvider(
      amount,
    );
  }

  @override
  CanAffordProvider getProviderOverride(
    covariant CanAffordProvider provider,
  ) {
    return call(
      provider.amount,
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
  String? get name => r'canAffordProvider';
}

/// See also [canAfford].
class CanAffordProvider extends AutoDisposeProvider<bool> {
  /// See also [canAfford].
  CanAffordProvider(
    double amount,
  ) : this._internal(
          (ref) => canAfford(
            ref as CanAffordRef,
            amount,
          ),
          from: canAffordProvider,
          name: r'canAffordProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$canAffordHash,
          dependencies: CanAffordFamily._dependencies,
          allTransitiveDependencies: CanAffordFamily._allTransitiveDependencies,
          amount: amount,
        );

  CanAffordProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.amount,
  }) : super.internal();

  final double amount;

  @override
  Override overrideWith(
    bool Function(CanAffordRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CanAffordProvider._internal(
        (ref) => create(ref as CanAffordRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        amount: amount,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _CanAffordProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CanAffordProvider && other.amount == amount;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, amount.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CanAffordRef on AutoDisposeProviderRef<bool> {
  /// The parameter `amount` of this provider.
  double get amount;
}

class _CanAffordProviderElement extends AutoDisposeProviderElement<bool>
    with CanAffordRef {
  _CanAffordProviderElement(super.provider);

  @override
  double get amount => (origin as CanAffordProvider).amount;
}

String _$walletHash() => r'0fdcc7d4d4334044e8f925218099872a3aa4dc96';

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

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$paymentServiceHash() => r'dbd1256e28841433d6170f8324e5c6bcba65c5b0';

/// Provider for PaymentService instance
///
/// Copied from [paymentService].
@ProviderFor(paymentService)
final paymentServiceProvider = AutoDisposeProvider<PaymentService>.internal(
  paymentService,
  name: r'paymentServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$paymentServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PaymentServiceRef = AutoDisposeProviderRef<PaymentService>;
String _$paymentHash() => r'aa2a677c9b39a4b7f11a4f166b4431f88433c50b';

/// Payment provider for managing M-Pesa payment operations
///
/// Copied from [Payment].
@ProviderFor(Payment)
final paymentProvider =
    AutoDisposeNotifierProvider<Payment, PaymentState>.internal(
  Payment.new,
  name: r'paymentProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$paymentHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Payment = AutoDisposeNotifier<PaymentState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

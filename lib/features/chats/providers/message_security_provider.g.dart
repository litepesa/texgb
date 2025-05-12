// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_security_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$messageSecurityNotifierHash() =>
    r'6822ce79fd37c3e3ab7257a388c77f3c11a59078';

/// Provider for managing message encryption and security features.
/// Handles end-to-end encryption, message integrity verification, etc.
///
/// Copied from [MessageSecurityNotifier].
@ProviderFor(MessageSecurityNotifier)
final messageSecurityNotifierProvider =
    AutoDisposeAsyncNotifierProvider<MessageSecurityNotifier, void>.internal(
  MessageSecurityNotifier.new,
  name: r'messageSecurityNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$messageSecurityNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MessageSecurityNotifier = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

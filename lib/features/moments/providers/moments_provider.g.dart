// lib/features/moments/providers/moments_provider.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moments_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$momentsNotifierHash() => r'0a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6';

/// See also [MomentsNotifier].
@ProviderFor(MomentsNotifier)
final momentsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<MomentsNotifier, List<MomentModel>>.internal(
  MomentsNotifier.new,
  name: r'momentsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$momentsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MomentsNotifier = AutoDisposeAsyncNotifier<List<MomentModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_streams_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatStreamHash() => r'f644908c7d6079b62b06621e5c3e66e61a7554bc';

/// Provider that exposes a stream of chats
///
/// Copied from [chatStream].
@ProviderFor(chatStream)
final chatStreamProvider = AutoDisposeStreamProvider<List<ChatModel>>.internal(
  chatStream,
  name: r'chatStreamProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$chatStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChatStreamRef = AutoDisposeStreamProviderRef<List<ChatModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

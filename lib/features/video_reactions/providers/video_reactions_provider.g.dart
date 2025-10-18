// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_reactions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$videoReactionChatsListHash() =>
    r'9f95793d60213cb6c607dbc7d34a83f263196eb8';

/// See also [VideoReactionChatsList].
@ProviderFor(VideoReactionChatsList)
final videoReactionChatsListProvider = AutoDisposeAsyncNotifierProvider<
    VideoReactionChatsList, VideoReactionChatsState>.internal(
  VideoReactionChatsList.new,
  name: r'videoReactionChatsListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$videoReactionChatsListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$VideoReactionChatsList
    = AutoDisposeAsyncNotifier<VideoReactionChatsState>;
String _$videoReactionMessagesHash() =>
    r'ab8ce08f8aa8f3176053fc84dbd3dc85621c7e30';

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

abstract class _$VideoReactionMessages
    extends BuildlessAutoDisposeAsyncNotifier<VideoReactionMessagesState> {
  late final String chatId;

  FutureOr<VideoReactionMessagesState> build(
    String chatId,
  );
}

/// See also [VideoReactionMessages].
@ProviderFor(VideoReactionMessages)
const videoReactionMessagesProvider = VideoReactionMessagesFamily();

/// See also [VideoReactionMessages].
class VideoReactionMessagesFamily
    extends Family<AsyncValue<VideoReactionMessagesState>> {
  /// See also [VideoReactionMessages].
  const VideoReactionMessagesFamily();

  /// See also [VideoReactionMessages].
  VideoReactionMessagesProvider call(
    String chatId,
  ) {
    return VideoReactionMessagesProvider(
      chatId,
    );
  }

  @override
  VideoReactionMessagesProvider getProviderOverride(
    covariant VideoReactionMessagesProvider provider,
  ) {
    return call(
      provider.chatId,
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
  String? get name => r'videoReactionMessagesProvider';
}

/// See also [VideoReactionMessages].
class VideoReactionMessagesProvider
    extends AutoDisposeAsyncNotifierProviderImpl<VideoReactionMessages,
        VideoReactionMessagesState> {
  /// See also [VideoReactionMessages].
  VideoReactionMessagesProvider(
    String chatId,
  ) : this._internal(
          () => VideoReactionMessages()..chatId = chatId,
          from: videoReactionMessagesProvider,
          name: r'videoReactionMessagesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$videoReactionMessagesHash,
          dependencies: VideoReactionMessagesFamily._dependencies,
          allTransitiveDependencies:
              VideoReactionMessagesFamily._allTransitiveDependencies,
          chatId: chatId,
        );

  VideoReactionMessagesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.chatId,
  }) : super.internal();

  final String chatId;

  @override
  FutureOr<VideoReactionMessagesState> runNotifierBuild(
    covariant VideoReactionMessages notifier,
  ) {
    return notifier.build(
      chatId,
    );
  }

  @override
  Override overrideWith(VideoReactionMessages Function() create) {
    return ProviderOverride(
      origin: this,
      override: VideoReactionMessagesProvider._internal(
        () => create()..chatId = chatId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        chatId: chatId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<VideoReactionMessages,
      VideoReactionMessagesState> createElement() {
    return _VideoReactionMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VideoReactionMessagesProvider && other.chatId == chatId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, chatId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin VideoReactionMessagesRef
    on AutoDisposeAsyncNotifierProviderRef<VideoReactionMessagesState> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _VideoReactionMessagesProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<VideoReactionMessages,
        VideoReactionMessagesState> with VideoReactionMessagesRef {
  _VideoReactionMessagesProviderElement(super.provider);

  @override
  String get chatId => (origin as VideoReactionMessagesProvider).chatId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

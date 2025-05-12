// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatSearchNotifierHash() =>
    r'637c6ece8ddc5543d09529e1df9b7ec5a1129a26';

/// Provider for searching within chats.
/// Handles searching for messages by content, type, date, etc.
///
/// Copied from [ChatSearchNotifier].
@ProviderFor(ChatSearchNotifier)
final chatSearchNotifierProvider = AutoDisposeAsyncNotifierProvider<
    ChatSearchNotifier, ChatSearchState>.internal(
  ChatSearchNotifier.new,
  name: r'chatSearchNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chatSearchNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ChatSearchNotifier = AutoDisposeAsyncNotifier<ChatSearchState>;
String _$mediaGalleryNotifierHash() =>
    r'18aeba4f0e5b324dc9bda2888f15921c7f9e1f06';

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

abstract class _$MediaGalleryNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<ChatMessageModel>> {
  late final String contactUID;

  FutureOr<List<ChatMessageModel>> build(
    String contactUID,
  );
}

/// Provider for media gallery access in a specific chat
///
/// Copied from [MediaGalleryNotifier].
@ProviderFor(MediaGalleryNotifier)
const mediaGalleryNotifierProvider = MediaGalleryNotifierFamily();

/// Provider for media gallery access in a specific chat
///
/// Copied from [MediaGalleryNotifier].
class MediaGalleryNotifierFamily
    extends Family<AsyncValue<List<ChatMessageModel>>> {
  /// Provider for media gallery access in a specific chat
  ///
  /// Copied from [MediaGalleryNotifier].
  const MediaGalleryNotifierFamily();

  /// Provider for media gallery access in a specific chat
  ///
  /// Copied from [MediaGalleryNotifier].
  MediaGalleryNotifierProvider call(
    String contactUID,
  ) {
    return MediaGalleryNotifierProvider(
      contactUID,
    );
  }

  @override
  MediaGalleryNotifierProvider getProviderOverride(
    covariant MediaGalleryNotifierProvider provider,
  ) {
    return call(
      provider.contactUID,
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
  String? get name => r'mediaGalleryNotifierProvider';
}

/// Provider for media gallery access in a specific chat
///
/// Copied from [MediaGalleryNotifier].
class MediaGalleryNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    MediaGalleryNotifier, List<ChatMessageModel>> {
  /// Provider for media gallery access in a specific chat
  ///
  /// Copied from [MediaGalleryNotifier].
  MediaGalleryNotifierProvider(
    String contactUID,
  ) : this._internal(
          () => MediaGalleryNotifier()..contactUID = contactUID,
          from: mediaGalleryNotifierProvider,
          name: r'mediaGalleryNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$mediaGalleryNotifierHash,
          dependencies: MediaGalleryNotifierFamily._dependencies,
          allTransitiveDependencies:
              MediaGalleryNotifierFamily._allTransitiveDependencies,
          contactUID: contactUID,
        );

  MediaGalleryNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.contactUID,
  }) : super.internal();

  final String contactUID;

  @override
  FutureOr<List<ChatMessageModel>> runNotifierBuild(
    covariant MediaGalleryNotifier notifier,
  ) {
    return notifier.build(
      contactUID,
    );
  }

  @override
  Override overrideWith(MediaGalleryNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: MediaGalleryNotifierProvider._internal(
        () => create()..contactUID = contactUID,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        contactUID: contactUID,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<MediaGalleryNotifier,
      List<ChatMessageModel>> createElement() {
    return _MediaGalleryNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MediaGalleryNotifierProvider &&
        other.contactUID == contactUID;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, contactUID.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MediaGalleryNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<ChatMessageModel>> {
  /// The parameter `contactUID` of this provider.
  String get contactUID;
}

class _MediaGalleryNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<MediaGalleryNotifier,
        List<ChatMessageModel>> with MediaGalleryNotifierRef {
  _MediaGalleryNotifierProviderElement(super.provider);

  @override
  String get contactUID => (origin as MediaGalleryNotifierProvider).contactUID;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

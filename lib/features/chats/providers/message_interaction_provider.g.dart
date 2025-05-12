// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_interaction_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$starredMessagesHash() => r'1150ee98ccf3755cf58145163d99d71d312cf7f2';

/// Provider for accessing all starred messages for current user
///
/// Copied from [starredMessages].
@ProviderFor(starredMessages)
final starredMessagesProvider =
    AutoDisposeStreamProvider<List<ChatMessageModel>>.internal(
  starredMessages,
  name: r'starredMessagesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$starredMessagesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StarredMessagesRef
    = AutoDisposeStreamProviderRef<List<ChatMessageModel>>;
String _$pinnedMessagesHash() => r'b1b9d2007d144f05c6fe23b04d06666626548b44';

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

/// Provider for accessing pinned messages in a specific chat
///
/// Copied from [pinnedMessages].
@ProviderFor(pinnedMessages)
const pinnedMessagesProvider = PinnedMessagesFamily();

/// Provider for accessing pinned messages in a specific chat
///
/// Copied from [pinnedMessages].
class PinnedMessagesFamily extends Family<AsyncValue<List<ChatMessageModel>>> {
  /// Provider for accessing pinned messages in a specific chat
  ///
  /// Copied from [pinnedMessages].
  const PinnedMessagesFamily();

  /// Provider for accessing pinned messages in a specific chat
  ///
  /// Copied from [pinnedMessages].
  PinnedMessagesProvider call(
    String chatId,
  ) {
    return PinnedMessagesProvider(
      chatId,
    );
  }

  @override
  PinnedMessagesProvider getProviderOverride(
    covariant PinnedMessagesProvider provider,
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
  String? get name => r'pinnedMessagesProvider';
}

/// Provider for accessing pinned messages in a specific chat
///
/// Copied from [pinnedMessages].
class PinnedMessagesProvider
    extends AutoDisposeStreamProvider<List<ChatMessageModel>> {
  /// Provider for accessing pinned messages in a specific chat
  ///
  /// Copied from [pinnedMessages].
  PinnedMessagesProvider(
    String chatId,
  ) : this._internal(
          (ref) => pinnedMessages(
            ref as PinnedMessagesRef,
            chatId,
          ),
          from: pinnedMessagesProvider,
          name: r'pinnedMessagesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$pinnedMessagesHash,
          dependencies: PinnedMessagesFamily._dependencies,
          allTransitiveDependencies:
              PinnedMessagesFamily._allTransitiveDependencies,
          chatId: chatId,
        );

  PinnedMessagesProvider._internal(
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
  Override overrideWith(
    Stream<List<ChatMessageModel>> Function(PinnedMessagesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PinnedMessagesProvider._internal(
        (ref) => create(ref as PinnedMessagesRef),
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
  AutoDisposeStreamProviderElement<List<ChatMessageModel>> createElement() {
    return _PinnedMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PinnedMessagesProvider && other.chatId == chatId;
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
mixin PinnedMessagesRef
    on AutoDisposeStreamProviderRef<List<ChatMessageModel>> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _PinnedMessagesProviderElement
    extends AutoDisposeStreamProviderElement<List<ChatMessageModel>>
    with PinnedMessagesRef {
  _PinnedMessagesProviderElement(super.provider);

  @override
  String get chatId => (origin as PinnedMessagesProvider).chatId;
}

String _$messageInteractionNotifierHash() =>
    r'91a1f47af55aac725b6a410d5a84cd1e5b90db08';

/// Provider for handling user interactions with messages.
/// Responsible for reactions, deleting, editing, and other message operations.
///
/// Copied from [MessageInteractionNotifier].
@ProviderFor(MessageInteractionNotifier)
final messageInteractionNotifierProvider =
    AutoDisposeAsyncNotifierProvider<MessageInteractionNotifier, void>.internal(
  MessageInteractionNotifier.new,
  name: r'messageInteractionNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$messageInteractionNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MessageInteractionNotifier = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

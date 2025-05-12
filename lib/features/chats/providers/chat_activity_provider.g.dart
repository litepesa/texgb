// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_activity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatActivityNotifierHash() =>
    r'ec11677c99dbb023d904dc2060fa8c8a247311ec';

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

abstract class _$ChatActivityNotifier
    extends BuildlessAutoDisposeAsyncNotifier<ChatActivityState> {
  late final String contactUID;

  FutureOr<ChatActivityState> build(
    String contactUID,
  );
}

/// Provider for managing chat activity indicators.
/// Handles online status, typing indicators, and read receipts.
///
/// Copied from [ChatActivityNotifier].
@ProviderFor(ChatActivityNotifier)
const chatActivityNotifierProvider = ChatActivityNotifierFamily();

/// Provider for managing chat activity indicators.
/// Handles online status, typing indicators, and read receipts.
///
/// Copied from [ChatActivityNotifier].
class ChatActivityNotifierFamily extends Family<AsyncValue<ChatActivityState>> {
  /// Provider for managing chat activity indicators.
  /// Handles online status, typing indicators, and read receipts.
  ///
  /// Copied from [ChatActivityNotifier].
  const ChatActivityNotifierFamily();

  /// Provider for managing chat activity indicators.
  /// Handles online status, typing indicators, and read receipts.
  ///
  /// Copied from [ChatActivityNotifier].
  ChatActivityNotifierProvider call(
    String contactUID,
  ) {
    return ChatActivityNotifierProvider(
      contactUID,
    );
  }

  @override
  ChatActivityNotifierProvider getProviderOverride(
    covariant ChatActivityNotifierProvider provider,
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
  String? get name => r'chatActivityNotifierProvider';
}

/// Provider for managing chat activity indicators.
/// Handles online status, typing indicators, and read receipts.
///
/// Copied from [ChatActivityNotifier].
class ChatActivityNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    ChatActivityNotifier, ChatActivityState> {
  /// Provider for managing chat activity indicators.
  /// Handles online status, typing indicators, and read receipts.
  ///
  /// Copied from [ChatActivityNotifier].
  ChatActivityNotifierProvider(
    String contactUID,
  ) : this._internal(
          () => ChatActivityNotifier()..contactUID = contactUID,
          from: chatActivityNotifierProvider,
          name: r'chatActivityNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$chatActivityNotifierHash,
          dependencies: ChatActivityNotifierFamily._dependencies,
          allTransitiveDependencies:
              ChatActivityNotifierFamily._allTransitiveDependencies,
          contactUID: contactUID,
        );

  ChatActivityNotifierProvider._internal(
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
  FutureOr<ChatActivityState> runNotifierBuild(
    covariant ChatActivityNotifier notifier,
  ) {
    return notifier.build(
      contactUID,
    );
  }

  @override
  Override overrideWith(ChatActivityNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ChatActivityNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<ChatActivityNotifier,
      ChatActivityState> createElement() {
    return _ChatActivityNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatActivityNotifierProvider &&
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
mixin ChatActivityNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<ChatActivityState> {
  /// The parameter `contactUID` of this provider.
  String get contactUID;
}

class _ChatActivityNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<ChatActivityNotifier,
        ChatActivityState> with ChatActivityNotifierRef {
  _ChatActivityNotifierProviderElement(super.provider);

  @override
  String get contactUID => (origin as ChatActivityNotifierProvider).contactUID;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$messageNotifierHash() => r'14e4ffbd1e869967c593dc5ea3c7d966c7d6624b';

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

abstract class _$MessageNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<ChatMessageModel>> {
  late final String contactUID;

  FutureOr<List<ChatMessageModel>> build(
    String contactUID,
  );
}

/// Provider for message operations within a chat.
/// Handles sending and managing messages with a specific contact.
///
/// Copied from [MessageNotifier].
@ProviderFor(MessageNotifier)
const messageNotifierProvider = MessageNotifierFamily();

/// Provider for message operations within a chat.
/// Handles sending and managing messages with a specific contact.
///
/// Copied from [MessageNotifier].
class MessageNotifierFamily extends Family<AsyncValue<List<ChatMessageModel>>> {
  /// Provider for message operations within a chat.
  /// Handles sending and managing messages with a specific contact.
  ///
  /// Copied from [MessageNotifier].
  const MessageNotifierFamily();

  /// Provider for message operations within a chat.
  /// Handles sending and managing messages with a specific contact.
  ///
  /// Copied from [MessageNotifier].
  MessageNotifierProvider call(
    String contactUID,
  ) {
    return MessageNotifierProvider(
      contactUID,
    );
  }

  @override
  MessageNotifierProvider getProviderOverride(
    covariant MessageNotifierProvider provider,
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
  String? get name => r'messageNotifierProvider';
}

/// Provider for message operations within a chat.
/// Handles sending and managing messages with a specific contact.
///
/// Copied from [MessageNotifier].
class MessageNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    MessageNotifier, List<ChatMessageModel>> {
  /// Provider for message operations within a chat.
  /// Handles sending and managing messages with a specific contact.
  ///
  /// Copied from [MessageNotifier].
  MessageNotifierProvider(
    String contactUID,
  ) : this._internal(
          () => MessageNotifier()..contactUID = contactUID,
          from: messageNotifierProvider,
          name: r'messageNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$messageNotifierHash,
          dependencies: MessageNotifierFamily._dependencies,
          allTransitiveDependencies:
              MessageNotifierFamily._allTransitiveDependencies,
          contactUID: contactUID,
        );

  MessageNotifierProvider._internal(
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
    covariant MessageNotifier notifier,
  ) {
    return notifier.build(
      contactUID,
    );
  }

  @override
  Override overrideWith(MessageNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: MessageNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<MessageNotifier,
      List<ChatMessageModel>> createElement() {
    return _MessageNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MessageNotifierProvider && other.contactUID == contactUID;
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
mixin MessageNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<ChatMessageModel>> {
  /// The parameter `contactUID` of this provider.
  String get contactUID;
}

class _MessageNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<MessageNotifier,
        List<ChatMessageModel>> with MessageNotifierRef {
  _MessageNotifierProviderElement(super.provider);

  @override
  String get contactUID => (origin as MessageNotifierProvider).contactUID;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

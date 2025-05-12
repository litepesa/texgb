// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_streams_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$messageStreamHash() => r'dd54ebd0fd77fdc684b17651d6bab1c1ec882802';

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

/// Provider that exposes a stream of messages for a specific chat
///
/// Copied from [messageStream].
@ProviderFor(messageStream)
const messageStreamProvider = MessageStreamFamily();

/// Provider that exposes a stream of messages for a specific chat
///
/// Copied from [messageStream].
class MessageStreamFamily extends Family<AsyncValue<List<ChatMessageModel>>> {
  /// Provider that exposes a stream of messages for a specific chat
  ///
  /// Copied from [messageStream].
  const MessageStreamFamily();

  /// Provider that exposes a stream of messages for a specific chat
  ///
  /// Copied from [messageStream].
  MessageStreamProvider call(
    String contactUID,
  ) {
    return MessageStreamProvider(
      contactUID,
    );
  }

  @override
  MessageStreamProvider getProviderOverride(
    covariant MessageStreamProvider provider,
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
  String? get name => r'messageStreamProvider';
}

/// Provider that exposes a stream of messages for a specific chat
///
/// Copied from [messageStream].
class MessageStreamProvider
    extends AutoDisposeStreamProvider<List<ChatMessageModel>> {
  /// Provider that exposes a stream of messages for a specific chat
  ///
  /// Copied from [messageStream].
  MessageStreamProvider(
    String contactUID,
  ) : this._internal(
          (ref) => messageStream(
            ref as MessageStreamRef,
            contactUID,
          ),
          from: messageStreamProvider,
          name: r'messageStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$messageStreamHash,
          dependencies: MessageStreamFamily._dependencies,
          allTransitiveDependencies:
              MessageStreamFamily._allTransitiveDependencies,
          contactUID: contactUID,
        );

  MessageStreamProvider._internal(
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
  Override overrideWith(
    Stream<List<ChatMessageModel>> Function(MessageStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MessageStreamProvider._internal(
        (ref) => create(ref as MessageStreamRef),
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
  AutoDisposeStreamProviderElement<List<ChatMessageModel>> createElement() {
    return _MessageStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MessageStreamProvider && other.contactUID == contactUID;
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
mixin MessageStreamRef on AutoDisposeStreamProviderRef<List<ChatMessageModel>> {
  /// The parameter `contactUID` of this provider.
  String get contactUID;
}

class _MessageStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<ChatMessageModel>>
    with MessageStreamRef {
  _MessageStreamProviderElement(super.provider);

  @override
  String get contactUID => (origin as MessageStreamProvider).contactUID;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

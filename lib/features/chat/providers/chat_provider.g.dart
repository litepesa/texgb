// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatStreamHash() => r'f8052ac41be7955b7711f399f312c6bdef997683';

/// See also [chatStream].
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
String _$messageStreamHash() => r'847f85c7e03489f282037b21494cedcc68bfa642';

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

/// See also [messageStream].
@ProviderFor(messageStream)
const messageStreamProvider = MessageStreamFamily();

/// See also [messageStream].
class MessageStreamFamily extends Family<AsyncValue<List<MessageModel>>> {
  /// See also [messageStream].
  const MessageStreamFamily();

  /// See also [messageStream].
  MessageStreamProvider call(
    String chatId,
  ) {
    return MessageStreamProvider(
      chatId,
    );
  }

  @override
  MessageStreamProvider getProviderOverride(
    covariant MessageStreamProvider provider,
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
  String? get name => r'messageStreamProvider';
}

/// See also [messageStream].
class MessageStreamProvider
    extends AutoDisposeStreamProvider<List<MessageModel>> {
  /// See also [messageStream].
  MessageStreamProvider(
    String chatId,
  ) : this._internal(
          (ref) => messageStream(
            ref as MessageStreamRef,
            chatId,
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
          chatId: chatId,
        );

  MessageStreamProvider._internal(
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
    Stream<List<MessageModel>> Function(MessageStreamRef provider) create,
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
        chatId: chatId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<MessageModel>> createElement() {
    return _MessageStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MessageStreamProvider && other.chatId == chatId;
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
mixin MessageStreamRef on AutoDisposeStreamProviderRef<List<MessageModel>> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _MessageStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<MessageModel>>
    with MessageStreamRef {
  _MessageStreamProviderElement(super.provider);

  @override
  String get chatId => (origin as MessageStreamProvider).chatId;
}

String _$totalUnreadCountHash() => r'a8bcb8361c6005e046e9ebb35ee43ba8371f2dcc';

/// See also [totalUnreadCount].
@ProviderFor(totalUnreadCount)
final totalUnreadCountProvider = AutoDisposeStreamProvider<int>.internal(
  totalUnreadCount,
  name: r'totalUnreadCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalUnreadCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TotalUnreadCountRef = AutoDisposeStreamProviderRef<int>;
String _$chatNotifierHash() => r'7a0ebc8ca60705d12f0886b88950ed36fc6b1a6d';

/// See also [ChatNotifier].
@ProviderFor(ChatNotifier)
final chatNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ChatNotifier, ChatState>.internal(
  ChatNotifier.new,
  name: r'chatNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$chatNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ChatNotifier = AutoDisposeAsyncNotifier<ChatState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

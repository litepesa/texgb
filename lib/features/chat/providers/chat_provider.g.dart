// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allChatsHash() => r'48de8184c2362a4c11a3dcc6a26386577337ca52';

/// See also [allChats].
@ProviderFor(allChats)
final allChatsProvider = AutoDisposeProvider<List<ChatModel>>.internal(
  allChats,
  name: r'allChatsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allChatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllChatsRef = AutoDisposeProviderRef<List<ChatModel>>;
String _$chatByIdHash() => r'25782e3a083d6e8b4dd634008e581b1ec892e909';

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

/// See also [chatById].
@ProviderFor(chatById)
const chatByIdProvider = ChatByIdFamily();

/// See also [chatById].
class ChatByIdFamily extends Family<AsyncValue<ChatModel?>> {
  /// See also [chatById].
  const ChatByIdFamily();

  /// See also [chatById].
  ChatByIdProvider call(
    String chatId,
  ) {
    return ChatByIdProvider(
      chatId,
    );
  }

  @override
  ChatByIdProvider getProviderOverride(
    covariant ChatByIdProvider provider,
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
  String? get name => r'chatByIdProvider';
}

/// See also [chatById].
class ChatByIdProvider extends AutoDisposeFutureProvider<ChatModel?> {
  /// See also [chatById].
  ChatByIdProvider(
    String chatId,
  ) : this._internal(
          (ref) => chatById(
            ref as ChatByIdRef,
            chatId,
          ),
          from: chatByIdProvider,
          name: r'chatByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$chatByIdHash,
          dependencies: ChatByIdFamily._dependencies,
          allTransitiveDependencies: ChatByIdFamily._allTransitiveDependencies,
          chatId: chatId,
        );

  ChatByIdProvider._internal(
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
    FutureOr<ChatModel?> Function(ChatByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChatByIdProvider._internal(
        (ref) => create(ref as ChatByIdRef),
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
  AutoDisposeFutureProviderElement<ChatModel?> createElement() {
    return _ChatByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatByIdProvider && other.chatId == chatId;
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
mixin ChatByIdRef on AutoDisposeFutureProviderRef<ChatModel?> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _ChatByIdProviderElement
    extends AutoDisposeFutureProviderElement<ChatModel?> with ChatByIdRef {
  _ChatByIdProviderElement(super.provider);

  @override
  String get chatId => (origin as ChatByIdProvider).chatId;
}

String _$chatMessagesHash() => r'9e6e9b6bdf3ed474b000f0f3b7770eea56cbff27';

/// See also [chatMessages].
@ProviderFor(chatMessages)
const chatMessagesProvider = ChatMessagesFamily();

/// See also [chatMessages].
class ChatMessagesFamily extends Family<List<MessageModel>> {
  /// See also [chatMessages].
  const ChatMessagesFamily();

  /// See also [chatMessages].
  ChatMessagesProvider call(
    String chatId,
  ) {
    return ChatMessagesProvider(
      chatId,
    );
  }

  @override
  ChatMessagesProvider getProviderOverride(
    covariant ChatMessagesProvider provider,
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
  String? get name => r'chatMessagesProvider';
}

/// See also [chatMessages].
class ChatMessagesProvider extends AutoDisposeProvider<List<MessageModel>> {
  /// See also [chatMessages].
  ChatMessagesProvider(
    String chatId,
  ) : this._internal(
          (ref) => chatMessages(
            ref as ChatMessagesRef,
            chatId,
          ),
          from: chatMessagesProvider,
          name: r'chatMessagesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$chatMessagesHash,
          dependencies: ChatMessagesFamily._dependencies,
          allTransitiveDependencies:
              ChatMessagesFamily._allTransitiveDependencies,
          chatId: chatId,
        );

  ChatMessagesProvider._internal(
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
    List<MessageModel> Function(ChatMessagesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChatMessagesProvider._internal(
        (ref) => create(ref as ChatMessagesRef),
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
  AutoDisposeProviderElement<List<MessageModel>> createElement() {
    return _ChatMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatMessagesProvider && other.chatId == chatId;
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
mixin ChatMessagesRef on AutoDisposeProviderRef<List<MessageModel>> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _ChatMessagesProviderElement
    extends AutoDisposeProviderElement<List<MessageModel>>
    with ChatMessagesRef {
  _ChatMessagesProviderElement(super.provider);

  @override
  String get chatId => (origin as ChatMessagesProvider).chatId;
}

String _$chatUnreadCountHash() => r'77023f05d25622b9f201549edb544ecb36c92f10';

/// See also [chatUnreadCount].
@ProviderFor(chatUnreadCount)
const chatUnreadCountProvider = ChatUnreadCountFamily();

/// See also [chatUnreadCount].
class ChatUnreadCountFamily extends Family<int> {
  /// See also [chatUnreadCount].
  const ChatUnreadCountFamily();

  /// See also [chatUnreadCount].
  ChatUnreadCountProvider call(
    String chatId,
  ) {
    return ChatUnreadCountProvider(
      chatId,
    );
  }

  @override
  ChatUnreadCountProvider getProviderOverride(
    covariant ChatUnreadCountProvider provider,
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
  String? get name => r'chatUnreadCountProvider';
}

/// See also [chatUnreadCount].
class ChatUnreadCountProvider extends AutoDisposeProvider<int> {
  /// See also [chatUnreadCount].
  ChatUnreadCountProvider(
    String chatId,
  ) : this._internal(
          (ref) => chatUnreadCount(
            ref as ChatUnreadCountRef,
            chatId,
          ),
          from: chatUnreadCountProvider,
          name: r'chatUnreadCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$chatUnreadCountHash,
          dependencies: ChatUnreadCountFamily._dependencies,
          allTransitiveDependencies:
              ChatUnreadCountFamily._allTransitiveDependencies,
          chatId: chatId,
        );

  ChatUnreadCountProvider._internal(
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
    int Function(ChatUnreadCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChatUnreadCountProvider._internal(
        (ref) => create(ref as ChatUnreadCountRef),
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
  AutoDisposeProviderElement<int> createElement() {
    return _ChatUnreadCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatUnreadCountProvider && other.chatId == chatId;
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
mixin ChatUnreadCountRef on AutoDisposeProviderRef<int> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _ChatUnreadCountProviderElement extends AutoDisposeProviderElement<int>
    with ChatUnreadCountRef {
  _ChatUnreadCountProviderElement(super.provider);

  @override
  String get chatId => (origin as ChatUnreadCountProvider).chatId;
}

String _$totalUnreadCountHash() => r'47b31be7fa2ed50a6d7c8ba2b453fa0aa05d69b5';

/// See also [totalUnreadCount].
@ProviderFor(totalUnreadCount)
final totalUnreadCountProvider = AutoDisposeProvider<int>.internal(
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
typedef TotalUnreadCountRef = AutoDisposeProviderRef<int>;
String _$isChatConnectedHash() => r'fe1f2832259abbb593fdfecb425ff71563dc9796';

/// See also [isChatConnected].
@ProviderFor(isChatConnected)
final isChatConnectedProvider = AutoDisposeProvider<bool>.internal(
  isChatConnected,
  name: r'isChatConnectedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isChatConnectedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsChatConnectedRef = AutoDisposeProviderRef<bool>;
String _$isChatLoadingHash() => r'52ede80c307c670237312861a54a5178e3fdeb39';

/// See also [isChatLoading].
@ProviderFor(isChatLoading)
final isChatLoadingProvider = AutoDisposeProvider<bool>.internal(
  isChatLoading,
  name: r'isChatLoadingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isChatLoadingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsChatLoadingRef = AutoDisposeProviderRef<bool>;
String _$filteredChatsHash() => r'0d45be1d1a50ac1ccfa772ebc61022d89b119db5';

/// See also [filteredChats].
@ProviderFor(filteredChats)
const filteredChatsProvider = FilteredChatsFamily();

/// See also [filteredChats].
class FilteredChatsFamily extends Family<List<ChatModel>> {
  /// See also [filteredChats].
  const FilteredChatsFamily();

  /// See also [filteredChats].
  FilteredChatsProvider call(
    String query,
  ) {
    return FilteredChatsProvider(
      query,
    );
  }

  @override
  FilteredChatsProvider getProviderOverride(
    covariant FilteredChatsProvider provider,
  ) {
    return call(
      provider.query,
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
  String? get name => r'filteredChatsProvider';
}

/// See also [filteredChats].
class FilteredChatsProvider extends AutoDisposeProvider<List<ChatModel>> {
  /// See also [filteredChats].
  FilteredChatsProvider(
    String query,
  ) : this._internal(
          (ref) => filteredChats(
            ref as FilteredChatsRef,
            query,
          ),
          from: filteredChatsProvider,
          name: r'filteredChatsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$filteredChatsHash,
          dependencies: FilteredChatsFamily._dependencies,
          allTransitiveDependencies:
              FilteredChatsFamily._allTransitiveDependencies,
          query: query,
        );

  FilteredChatsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    List<ChatModel> Function(FilteredChatsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FilteredChatsProvider._internal(
        (ref) => create(ref as FilteredChatsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<List<ChatModel>> createElement() {
    return _FilteredChatsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredChatsProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FilteredChatsRef on AutoDisposeProviderRef<List<ChatModel>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _FilteredChatsProviderElement
    extends AutoDisposeProviderElement<List<ChatModel>> with FilteredChatsRef {
  _FilteredChatsProviderElement(super.provider);

  @override
  String get query => (origin as FilteredChatsProvider).query;
}

String _$pinnedChatsHash() => r'161891132e15dabfe1b1e9f0e766989a210daa71';

/// See also [pinnedChats].
@ProviderFor(pinnedChats)
final pinnedChatsProvider = AutoDisposeProvider<List<ChatModel>>.internal(
  pinnedChats,
  name: r'pinnedChatsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$pinnedChatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PinnedChatsRef = AutoDisposeProviderRef<List<ChatModel>>;
String _$archivedChatsHash() => r'6ecb26d71c96d4b533524ab3acfc955431239b08';

/// See also [archivedChats].
@ProviderFor(archivedChats)
final archivedChatsProvider = AutoDisposeProvider<List<ChatModel>>.internal(
  archivedChats,
  name: r'archivedChatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$archivedChatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ArchivedChatsRef = AutoDisposeProviderRef<List<ChatModel>>;
String _$activeChatsHash() => r'957c67aba3da5755ed6283f60c33ffc7e304d55c';

/// See also [activeChats].
@ProviderFor(activeChats)
final activeChatsProvider = AutoDisposeProvider<List<ChatModel>>.internal(
  activeChats,
  name: r'activeChatsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$activeChatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveChatsRef = AutoDisposeProviderRef<List<ChatModel>>;
String _$chatHash() => r'fcc29a6aaa779ec84aaa87e2048260af1da5d52f';

/// See also [Chat].
@ProviderFor(Chat)
final chatProvider = AutoDisposeAsyncNotifierProvider<Chat, ChatState>.internal(
  Chat.new,
  name: r'chatProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$chatHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Chat = AutoDisposeAsyncNotifier<ChatState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

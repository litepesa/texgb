// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_convenience_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allChatsHash() => r'48de8184c2362a4c11a3dcc6a26386577337ca52';

/// Get all chats
///
/// Copied from [allChats].
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
String _$filteredChatsHash() => r'ebd6ea7de4758196879bc4cfdc075f86ed47c07f';

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

/// Get filtered chats (search)
///
/// Copied from [filteredChats].
@ProviderFor(filteredChats)
const filteredChatsProvider = FilteredChatsFamily();

/// Get filtered chats (search)
///
/// Copied from [filteredChats].
class FilteredChatsFamily extends Family<List<ChatModel>> {
  /// Get filtered chats (search)
  ///
  /// Copied from [filteredChats].
  const FilteredChatsFamily();

  /// Get filtered chats (search)
  ///
  /// Copied from [filteredChats].
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

/// Get filtered chats (search)
///
/// Copied from [filteredChats].
class FilteredChatsProvider extends AutoDisposeProvider<List<ChatModel>> {
  /// Get filtered chats (search)
  ///
  /// Copied from [filteredChats].
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

/// Get pinned chats
///
/// Copied from [pinnedChats].
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

/// Get archived chats
///
/// Copied from [archivedChats].
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

/// Get active (non-archived) chats
///
/// Copied from [activeChats].
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
String _$chatsWithUnreadHash() => r'bc23be6bbb820c0ca45629d33a4715bd328b9e67';

/// Get chats with unread messages
///
/// Copied from [chatsWithUnread].
@ProviderFor(chatsWithUnread)
final chatsWithUnreadProvider = AutoDisposeProvider<List<ChatModel>>.internal(
  chatsWithUnread,
  name: r'chatsWithUnreadProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chatsWithUnreadHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChatsWithUnreadRef = AutoDisposeProviderRef<List<ChatModel>>;
String _$oneOnOneChatsHash() => r'59448215a85af40420e1ab74d312be6cbc1b3dbd';

/// Get one-on-one chats
///
/// Copied from [oneOnOneChats].
@ProviderFor(oneOnOneChats)
final oneOnOneChatsProvider = AutoDisposeProvider<List<ChatModel>>.internal(
  oneOnOneChats,
  name: r'oneOnOneChatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$oneOnOneChatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OneOnOneChatsRef = AutoDisposeProviderRef<List<ChatModel>>;
String _$groupChatsHash() => r'60fb93438f8f567b631acc020a646c3a780cccc0';

/// Get group chats
///
/// Copied from [groupChats].
@ProviderFor(groupChats)
final groupChatsProvider = AutoDisposeProvider<List<ChatModel>>.internal(
  groupChats,
  name: r'groupChatsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$groupChatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GroupChatsRef = AutoDisposeProviderRef<List<ChatModel>>;
String _$chatByIdHash() => r'25782e3a083d6e8b4dd634008e581b1ec892e909';

/// Get specific chat by ID
///
/// Copied from [chatById].
@ProviderFor(chatById)
const chatByIdProvider = ChatByIdFamily();

/// Get specific chat by ID
///
/// Copied from [chatById].
class ChatByIdFamily extends Family<AsyncValue<ChatModel?>> {
  /// Get specific chat by ID
  ///
  /// Copied from [chatById].
  const ChatByIdFamily();

  /// Get specific chat by ID
  ///
  /// Copied from [chatById].
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

/// Get specific chat by ID
///
/// Copied from [chatById].
class ChatByIdProvider extends AutoDisposeFutureProvider<ChatModel?> {
  /// Get specific chat by ID
  ///
  /// Copied from [chatById].
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

String _$chatTitleHash() => r'609131a26c81256f5ead90e2c37b52109777a8ea';

/// Get chat title for current user
///
/// Copied from [chatTitle].
@ProviderFor(chatTitle)
const chatTitleProvider = ChatTitleFamily();

/// Get chat title for current user
///
/// Copied from [chatTitle].
class ChatTitleFamily extends Family<String> {
  /// Get chat title for current user
  ///
  /// Copied from [chatTitle].
  const ChatTitleFamily();

  /// Get chat title for current user
  ///
  /// Copied from [chatTitle].
  ChatTitleProvider call(
    String chatId,
  ) {
    return ChatTitleProvider(
      chatId,
    );
  }

  @override
  ChatTitleProvider getProviderOverride(
    covariant ChatTitleProvider provider,
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
  String? get name => r'chatTitleProvider';
}

/// Get chat title for current user
///
/// Copied from [chatTitle].
class ChatTitleProvider extends AutoDisposeProvider<String> {
  /// Get chat title for current user
  ///
  /// Copied from [chatTitle].
  ChatTitleProvider(
    String chatId,
  ) : this._internal(
          (ref) => chatTitle(
            ref as ChatTitleRef,
            chatId,
          ),
          from: chatTitleProvider,
          name: r'chatTitleProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$chatTitleHash,
          dependencies: ChatTitleFamily._dependencies,
          allTransitiveDependencies: ChatTitleFamily._allTransitiveDependencies,
          chatId: chatId,
        );

  ChatTitleProvider._internal(
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
    String Function(ChatTitleRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChatTitleProvider._internal(
        (ref) => create(ref as ChatTitleRef),
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
  AutoDisposeProviderElement<String> createElement() {
    return _ChatTitleProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatTitleProvider && other.chatId == chatId;
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
mixin ChatTitleRef on AutoDisposeProviderRef<String> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _ChatTitleProviderElement extends AutoDisposeProviderElement<String>
    with ChatTitleRef {
  _ChatTitleProviderElement(super.provider);

  @override
  String get chatId => (origin as ChatTitleProvider).chatId;
}

String _$chatImageHash() => r'8e5e208f4c022d4fdc5a42fda28aedde92b4cf57';

/// Get chat image for current user
///
/// Copied from [chatImage].
@ProviderFor(chatImage)
const chatImageProvider = ChatImageFamily();

/// Get chat image for current user
///
/// Copied from [chatImage].
class ChatImageFamily extends Family<String?> {
  /// Get chat image for current user
  ///
  /// Copied from [chatImage].
  const ChatImageFamily();

  /// Get chat image for current user
  ///
  /// Copied from [chatImage].
  ChatImageProvider call(
    String chatId,
  ) {
    return ChatImageProvider(
      chatId,
    );
  }

  @override
  ChatImageProvider getProviderOverride(
    covariant ChatImageProvider provider,
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
  String? get name => r'chatImageProvider';
}

/// Get chat image for current user
///
/// Copied from [chatImage].
class ChatImageProvider extends AutoDisposeProvider<String?> {
  /// Get chat image for current user
  ///
  /// Copied from [chatImage].
  ChatImageProvider(
    String chatId,
  ) : this._internal(
          (ref) => chatImage(
            ref as ChatImageRef,
            chatId,
          ),
          from: chatImageProvider,
          name: r'chatImageProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$chatImageHash,
          dependencies: ChatImageFamily._dependencies,
          allTransitiveDependencies: ChatImageFamily._allTransitiveDependencies,
          chatId: chatId,
        );

  ChatImageProvider._internal(
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
    String? Function(ChatImageRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChatImageProvider._internal(
        (ref) => create(ref as ChatImageRef),
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
  AutoDisposeProviderElement<String?> createElement() {
    return _ChatImageProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatImageProvider && other.chatId == chatId;
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
mixin ChatImageRef on AutoDisposeProviderRef<String?> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _ChatImageProviderElement extends AutoDisposeProviderElement<String?>
    with ChatImageRef {
  _ChatImageProviderElement(super.provider);

  @override
  String get chatId => (origin as ChatImageProvider).chatId;
}

String _$chatMessagesHash() => r'9e6e9b6bdf3ed474b000f0f3b7770eea56cbff27';

/// Get messages for a specific chat
///
/// Copied from [chatMessages].
@ProviderFor(chatMessages)
const chatMessagesProvider = ChatMessagesFamily();

/// Get messages for a specific chat
///
/// Copied from [chatMessages].
class ChatMessagesFamily extends Family<List<MessageModel>> {
  /// Get messages for a specific chat
  ///
  /// Copied from [chatMessages].
  const ChatMessagesFamily();

  /// Get messages for a specific chat
  ///
  /// Copied from [chatMessages].
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

/// Get messages for a specific chat
///
/// Copied from [chatMessages].
class ChatMessagesProvider extends AutoDisposeProvider<List<MessageModel>> {
  /// Get messages for a specific chat
  ///
  /// Copied from [chatMessages].
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

String _$latestMessageHash() => r'a2553e04b17d093bbecfd99b1f32b41a3b7da833';

/// Get latest message for a chat
///
/// Copied from [latestMessage].
@ProviderFor(latestMessage)
const latestMessageProvider = LatestMessageFamily();

/// Get latest message for a chat
///
/// Copied from [latestMessage].
class LatestMessageFamily extends Family<MessageModel?> {
  /// Get latest message for a chat
  ///
  /// Copied from [latestMessage].
  const LatestMessageFamily();

  /// Get latest message for a chat
  ///
  /// Copied from [latestMessage].
  LatestMessageProvider call(
    String chatId,
  ) {
    return LatestMessageProvider(
      chatId,
    );
  }

  @override
  LatestMessageProvider getProviderOverride(
    covariant LatestMessageProvider provider,
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
  String? get name => r'latestMessageProvider';
}

/// Get latest message for a chat
///
/// Copied from [latestMessage].
class LatestMessageProvider extends AutoDisposeProvider<MessageModel?> {
  /// Get latest message for a chat
  ///
  /// Copied from [latestMessage].
  LatestMessageProvider(
    String chatId,
  ) : this._internal(
          (ref) => latestMessage(
            ref as LatestMessageRef,
            chatId,
          ),
          from: latestMessageProvider,
          name: r'latestMessageProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$latestMessageHash,
          dependencies: LatestMessageFamily._dependencies,
          allTransitiveDependencies:
              LatestMessageFamily._allTransitiveDependencies,
          chatId: chatId,
        );

  LatestMessageProvider._internal(
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
    MessageModel? Function(LatestMessageRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LatestMessageProvider._internal(
        (ref) => create(ref as LatestMessageRef),
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
  AutoDisposeProviderElement<MessageModel?> createElement() {
    return _LatestMessageProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LatestMessageProvider && other.chatId == chatId;
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
mixin LatestMessageRef on AutoDisposeProviderRef<MessageModel?> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _LatestMessageProviderElement
    extends AutoDisposeProviderElement<MessageModel?> with LatestMessageRef {
  _LatestMessageProviderElement(super.provider);

  @override
  String get chatId => (origin as LatestMessageProvider).chatId;
}

String _$messageCountHash() => r'1335727b7bf9edf5009c6b44952d94190a84612d';

/// Get message count for a chat
///
/// Copied from [messageCount].
@ProviderFor(messageCount)
const messageCountProvider = MessageCountFamily();

/// Get message count for a chat
///
/// Copied from [messageCount].
class MessageCountFamily extends Family<int> {
  /// Get message count for a chat
  ///
  /// Copied from [messageCount].
  const MessageCountFamily();

  /// Get message count for a chat
  ///
  /// Copied from [messageCount].
  MessageCountProvider call(
    String chatId,
  ) {
    return MessageCountProvider(
      chatId,
    );
  }

  @override
  MessageCountProvider getProviderOverride(
    covariant MessageCountProvider provider,
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
  String? get name => r'messageCountProvider';
}

/// Get message count for a chat
///
/// Copied from [messageCount].
class MessageCountProvider extends AutoDisposeProvider<int> {
  /// Get message count for a chat
  ///
  /// Copied from [messageCount].
  MessageCountProvider(
    String chatId,
  ) : this._internal(
          (ref) => messageCount(
            ref as MessageCountRef,
            chatId,
          ),
          from: messageCountProvider,
          name: r'messageCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$messageCountHash,
          dependencies: MessageCountFamily._dependencies,
          allTransitiveDependencies:
              MessageCountFamily._allTransitiveDependencies,
          chatId: chatId,
        );

  MessageCountProvider._internal(
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
    int Function(MessageCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MessageCountProvider._internal(
        (ref) => create(ref as MessageCountRef),
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
    return _MessageCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MessageCountProvider && other.chatId == chatId;
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
mixin MessageCountRef on AutoDisposeProviderRef<int> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _MessageCountProviderElement extends AutoDisposeProviderElement<int>
    with MessageCountRef {
  _MessageCountProviderElement(super.provider);

  @override
  String get chatId => (origin as MessageCountProvider).chatId;
}

String _$starredMessagesHash() => r'b1299400c6496b1e134c3cc9147a52af72f1400c';

/// Get starred messages
///
/// Copied from [starredMessages].
@ProviderFor(starredMessages)
final starredMessagesProvider =
    AutoDisposeFutureProvider<List<MessageModel>>.internal(
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
typedef StarredMessagesRef = AutoDisposeFutureProviderRef<List<MessageModel>>;
String _$chatUnreadCountHash() => r'ce8ac35eeeb7523bad87f6b8cee3657a7a68ef13';

/// Get unread count for a specific chat
///
/// Copied from [chatUnreadCount].
@ProviderFor(chatUnreadCount)
const chatUnreadCountProvider = ChatUnreadCountFamily();

/// Get unread count for a specific chat
///
/// Copied from [chatUnreadCount].
class ChatUnreadCountFamily extends Family<int> {
  /// Get unread count for a specific chat
  ///
  /// Copied from [chatUnreadCount].
  const ChatUnreadCountFamily();

  /// Get unread count for a specific chat
  ///
  /// Copied from [chatUnreadCount].
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

/// Get unread count for a specific chat
///
/// Copied from [chatUnreadCount].
class ChatUnreadCountProvider extends AutoDisposeProvider<int> {
  /// Get unread count for a specific chat
  ///
  /// Copied from [chatUnreadCount].
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

/// Get total unread count across all chats
///
/// Copied from [totalUnreadCount].
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
String _$hasUnreadMessagesHash() => r'3115f4ebbe0fd71aae7a6d92dd10ac74c28d4bc7';

/// Check if chat has unread messages
///
/// Copied from [hasUnreadMessages].
@ProviderFor(hasUnreadMessages)
const hasUnreadMessagesProvider = HasUnreadMessagesFamily();

/// Check if chat has unread messages
///
/// Copied from [hasUnreadMessages].
class HasUnreadMessagesFamily extends Family<bool> {
  /// Check if chat has unread messages
  ///
  /// Copied from [hasUnreadMessages].
  const HasUnreadMessagesFamily();

  /// Check if chat has unread messages
  ///
  /// Copied from [hasUnreadMessages].
  HasUnreadMessagesProvider call(
    String chatId,
  ) {
    return HasUnreadMessagesProvider(
      chatId,
    );
  }

  @override
  HasUnreadMessagesProvider getProviderOverride(
    covariant HasUnreadMessagesProvider provider,
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
  String? get name => r'hasUnreadMessagesProvider';
}

/// Check if chat has unread messages
///
/// Copied from [hasUnreadMessages].
class HasUnreadMessagesProvider extends AutoDisposeProvider<bool> {
  /// Check if chat has unread messages
  ///
  /// Copied from [hasUnreadMessages].
  HasUnreadMessagesProvider(
    String chatId,
  ) : this._internal(
          (ref) => hasUnreadMessages(
            ref as HasUnreadMessagesRef,
            chatId,
          ),
          from: hasUnreadMessagesProvider,
          name: r'hasUnreadMessagesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$hasUnreadMessagesHash,
          dependencies: HasUnreadMessagesFamily._dependencies,
          allTransitiveDependencies:
              HasUnreadMessagesFamily._allTransitiveDependencies,
          chatId: chatId,
        );

  HasUnreadMessagesProvider._internal(
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
    bool Function(HasUnreadMessagesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HasUnreadMessagesProvider._internal(
        (ref) => create(ref as HasUnreadMessagesRef),
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
  AutoDisposeProviderElement<bool> createElement() {
    return _HasUnreadMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HasUnreadMessagesProvider && other.chatId == chatId;
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
mixin HasUnreadMessagesRef on AutoDisposeProviderRef<bool> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _HasUnreadMessagesProviderElement extends AutoDisposeProviderElement<bool>
    with HasUnreadMessagesRef {
  _HasUnreadMessagesProviderElement(super.provider);

  @override
  String get chatId => (origin as HasUnreadMessagesProvider).chatId;
}

String _$isChatConnectedHash() => r'fe1f2832259abbb593fdfecb425ff71563dc9796';

/// Check if WebSocket is connected
///
/// Copied from [isChatConnected].
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

/// Check if chats are loading
///
/// Copied from [isChatLoading].
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
String _$chatErrorHash() => r'cd02d8055a41c0b70de19765d50fd67253c80d00';

/// Get chat error if any
///
/// Copied from [chatError].
@ProviderFor(chatError)
final chatErrorProvider = AutoDisposeProvider<String?>.internal(
  chatError,
  name: r'chatErrorProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$chatErrorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChatErrorRef = AutoDisposeProviderRef<String?>;
String _$lastChatSyncHash() => r'08c3f595acc01f4ff2ca2cac5ec76204eb23a60a';

/// Get last sync time
///
/// Copied from [lastChatSync].
@ProviderFor(lastChatSync)
final lastChatSyncProvider = AutoDisposeProvider<DateTime?>.internal(
  lastChatSync,
  name: r'lastChatSyncProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$lastChatSyncHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LastChatSyncRef = AutoDisposeProviderRef<DateTime?>;
String _$isChatMutedHash() => r'e8af6534367fae0f1acc46a3eb1a1e2593f6ea70';

/// Check if chat is muted
///
/// Copied from [isChatMuted].
@ProviderFor(isChatMuted)
const isChatMutedProvider = IsChatMutedFamily();

/// Check if chat is muted
///
/// Copied from [isChatMuted].
class IsChatMutedFamily extends Family<bool> {
  /// Check if chat is muted
  ///
  /// Copied from [isChatMuted].
  const IsChatMutedFamily();

  /// Check if chat is muted
  ///
  /// Copied from [isChatMuted].
  IsChatMutedProvider call(
    String chatId,
  ) {
    return IsChatMutedProvider(
      chatId,
    );
  }

  @override
  IsChatMutedProvider getProviderOverride(
    covariant IsChatMutedProvider provider,
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
  String? get name => r'isChatMutedProvider';
}

/// Check if chat is muted
///
/// Copied from [isChatMuted].
class IsChatMutedProvider extends AutoDisposeProvider<bool> {
  /// Check if chat is muted
  ///
  /// Copied from [isChatMuted].
  IsChatMutedProvider(
    String chatId,
  ) : this._internal(
          (ref) => isChatMuted(
            ref as IsChatMutedRef,
            chatId,
          ),
          from: isChatMutedProvider,
          name: r'isChatMutedProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isChatMutedHash,
          dependencies: IsChatMutedFamily._dependencies,
          allTransitiveDependencies:
              IsChatMutedFamily._allTransitiveDependencies,
          chatId: chatId,
        );

  IsChatMutedProvider._internal(
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
    bool Function(IsChatMutedRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsChatMutedProvider._internal(
        (ref) => create(ref as IsChatMutedRef),
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
  AutoDisposeProviderElement<bool> createElement() {
    return _IsChatMutedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsChatMutedProvider && other.chatId == chatId;
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
mixin IsChatMutedRef on AutoDisposeProviderRef<bool> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _IsChatMutedProviderElement extends AutoDisposeProviderElement<bool>
    with IsChatMutedRef {
  _IsChatMutedProviderElement(super.provider);

  @override
  String get chatId => (origin as IsChatMutedProvider).chatId;
}

String _$isChatPinnedHash() => r'd7e761e1f4363698adecd25274bbee4198ba6c73';

/// Check if chat is pinned
///
/// Copied from [isChatPinned].
@ProviderFor(isChatPinned)
const isChatPinnedProvider = IsChatPinnedFamily();

/// Check if chat is pinned
///
/// Copied from [isChatPinned].
class IsChatPinnedFamily extends Family<bool> {
  /// Check if chat is pinned
  ///
  /// Copied from [isChatPinned].
  const IsChatPinnedFamily();

  /// Check if chat is pinned
  ///
  /// Copied from [isChatPinned].
  IsChatPinnedProvider call(
    String chatId,
  ) {
    return IsChatPinnedProvider(
      chatId,
    );
  }

  @override
  IsChatPinnedProvider getProviderOverride(
    covariant IsChatPinnedProvider provider,
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
  String? get name => r'isChatPinnedProvider';
}

/// Check if chat is pinned
///
/// Copied from [isChatPinned].
class IsChatPinnedProvider extends AutoDisposeProvider<bool> {
  /// Check if chat is pinned
  ///
  /// Copied from [isChatPinned].
  IsChatPinnedProvider(
    String chatId,
  ) : this._internal(
          (ref) => isChatPinned(
            ref as IsChatPinnedRef,
            chatId,
          ),
          from: isChatPinnedProvider,
          name: r'isChatPinnedProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isChatPinnedHash,
          dependencies: IsChatPinnedFamily._dependencies,
          allTransitiveDependencies:
              IsChatPinnedFamily._allTransitiveDependencies,
          chatId: chatId,
        );

  IsChatPinnedProvider._internal(
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
    bool Function(IsChatPinnedRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsChatPinnedProvider._internal(
        (ref) => create(ref as IsChatPinnedRef),
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
  AutoDisposeProviderElement<bool> createElement() {
    return _IsChatPinnedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsChatPinnedProvider && other.chatId == chatId;
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
mixin IsChatPinnedRef on AutoDisposeProviderRef<bool> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _IsChatPinnedProviderElement extends AutoDisposeProviderElement<bool>
    with IsChatPinnedRef {
  _IsChatPinnedProviderElement(super.provider);

  @override
  String get chatId => (origin as IsChatPinnedProvider).chatId;
}

String _$isChatArchivedHash() => r'83dafce1e824bf6842fe9a6f2e91611a4c47c071';

/// Check if chat is archived
///
/// Copied from [isChatArchived].
@ProviderFor(isChatArchived)
const isChatArchivedProvider = IsChatArchivedFamily();

/// Check if chat is archived
///
/// Copied from [isChatArchived].
class IsChatArchivedFamily extends Family<bool> {
  /// Check if chat is archived
  ///
  /// Copied from [isChatArchived].
  const IsChatArchivedFamily();

  /// Check if chat is archived
  ///
  /// Copied from [isChatArchived].
  IsChatArchivedProvider call(
    String chatId,
  ) {
    return IsChatArchivedProvider(
      chatId,
    );
  }

  @override
  IsChatArchivedProvider getProviderOverride(
    covariant IsChatArchivedProvider provider,
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
  String? get name => r'isChatArchivedProvider';
}

/// Check if chat is archived
///
/// Copied from [isChatArchived].
class IsChatArchivedProvider extends AutoDisposeProvider<bool> {
  /// Check if chat is archived
  ///
  /// Copied from [isChatArchived].
  IsChatArchivedProvider(
    String chatId,
  ) : this._internal(
          (ref) => isChatArchived(
            ref as IsChatArchivedRef,
            chatId,
          ),
          from: isChatArchivedProvider,
          name: r'isChatArchivedProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isChatArchivedHash,
          dependencies: IsChatArchivedFamily._dependencies,
          allTransitiveDependencies:
              IsChatArchivedFamily._allTransitiveDependencies,
          chatId: chatId,
        );

  IsChatArchivedProvider._internal(
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
    bool Function(IsChatArchivedRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsChatArchivedProvider._internal(
        (ref) => create(ref as IsChatArchivedRef),
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
  AutoDisposeProviderElement<bool> createElement() {
    return _IsChatArchivedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsChatArchivedProvider && other.chatId == chatId;
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
mixin IsChatArchivedRef on AutoDisposeProviderRef<bool> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _IsChatArchivedProviderElement extends AutoDisposeProviderElement<bool>
    with IsChatArchivedRef {
  _IsChatArchivedProviderElement(super.provider);

  @override
  String get chatId => (origin as IsChatArchivedProvider).chatId;
}

String _$isChatBlockedHash() => r'b64215dbcf2eeb5c0a1fd8f98ac3822fe1c90c43';

/// Check if chat is blocked
///
/// Copied from [isChatBlocked].
@ProviderFor(isChatBlocked)
const isChatBlockedProvider = IsChatBlockedFamily();

/// Check if chat is blocked
///
/// Copied from [isChatBlocked].
class IsChatBlockedFamily extends Family<bool> {
  /// Check if chat is blocked
  ///
  /// Copied from [isChatBlocked].
  const IsChatBlockedFamily();

  /// Check if chat is blocked
  ///
  /// Copied from [isChatBlocked].
  IsChatBlockedProvider call(
    String chatId,
  ) {
    return IsChatBlockedProvider(
      chatId,
    );
  }

  @override
  IsChatBlockedProvider getProviderOverride(
    covariant IsChatBlockedProvider provider,
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
  String? get name => r'isChatBlockedProvider';
}

/// Check if chat is blocked
///
/// Copied from [isChatBlocked].
class IsChatBlockedProvider extends AutoDisposeProvider<bool> {
  /// Check if chat is blocked
  ///
  /// Copied from [isChatBlocked].
  IsChatBlockedProvider(
    String chatId,
  ) : this._internal(
          (ref) => isChatBlocked(
            ref as IsChatBlockedRef,
            chatId,
          ),
          from: isChatBlockedProvider,
          name: r'isChatBlockedProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isChatBlockedHash,
          dependencies: IsChatBlockedFamily._dependencies,
          allTransitiveDependencies:
              IsChatBlockedFamily._allTransitiveDependencies,
          chatId: chatId,
        );

  IsChatBlockedProvider._internal(
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
    bool Function(IsChatBlockedRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsChatBlockedProvider._internal(
        (ref) => create(ref as IsChatBlockedRef),
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
  AutoDisposeProviderElement<bool> createElement() {
    return _IsChatBlockedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsChatBlockedProvider && other.chatId == chatId;
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
mixin IsChatBlockedRef on AutoDisposeProviderRef<bool> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _IsChatBlockedProviderElement extends AutoDisposeProviderElement<bool>
    with IsChatBlockedRef {
  _IsChatBlockedProviderElement(super.provider);

  @override
  String get chatId => (origin as IsChatBlockedProvider).chatId;
}

String _$participantCountHash() => r'957bd4700b2a682c042316e5e5bbfd68d72cb4bd';

/// Get participant count for a chat
///
/// Copied from [participantCount].
@ProviderFor(participantCount)
const participantCountProvider = ParticipantCountFamily();

/// Get participant count for a chat
///
/// Copied from [participantCount].
class ParticipantCountFamily extends Family<int> {
  /// Get participant count for a chat
  ///
  /// Copied from [participantCount].
  const ParticipantCountFamily();

  /// Get participant count for a chat
  ///
  /// Copied from [participantCount].
  ParticipantCountProvider call(
    String chatId,
  ) {
    return ParticipantCountProvider(
      chatId,
    );
  }

  @override
  ParticipantCountProvider getProviderOverride(
    covariant ParticipantCountProvider provider,
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
  String? get name => r'participantCountProvider';
}

/// Get participant count for a chat
///
/// Copied from [participantCount].
class ParticipantCountProvider extends AutoDisposeProvider<int> {
  /// Get participant count for a chat
  ///
  /// Copied from [participantCount].
  ParticipantCountProvider(
    String chatId,
  ) : this._internal(
          (ref) => participantCount(
            ref as ParticipantCountRef,
            chatId,
          ),
          from: participantCountProvider,
          name: r'participantCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$participantCountHash,
          dependencies: ParticipantCountFamily._dependencies,
          allTransitiveDependencies:
              ParticipantCountFamily._allTransitiveDependencies,
          chatId: chatId,
        );

  ParticipantCountProvider._internal(
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
    int Function(ParticipantCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ParticipantCountProvider._internal(
        (ref) => create(ref as ParticipantCountRef),
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
    return _ParticipantCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ParticipantCountProvider && other.chatId == chatId;
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
mixin ParticipantCountRef on AutoDisposeProviderRef<int> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _ParticipantCountProviderElement extends AutoDisposeProviderElement<int>
    with ParticipantCountRef {
  _ParticipantCountProviderElement(super.provider);

  @override
  String get chatId => (origin as ParticipantCountProvider).chatId;
}

String _$otherParticipantIdHash() =>
    r'91b83c03633c58730f6e9117ec3c49fe5c85a0c4';

/// Get other participant ID in one-on-one chat
///
/// Copied from [otherParticipantId].
@ProviderFor(otherParticipantId)
const otherParticipantIdProvider = OtherParticipantIdFamily();

/// Get other participant ID in one-on-one chat
///
/// Copied from [otherParticipantId].
class OtherParticipantIdFamily extends Family<String?> {
  /// Get other participant ID in one-on-one chat
  ///
  /// Copied from [otherParticipantId].
  const OtherParticipantIdFamily();

  /// Get other participant ID in one-on-one chat
  ///
  /// Copied from [otherParticipantId].
  OtherParticipantIdProvider call(
    String chatId,
  ) {
    return OtherParticipantIdProvider(
      chatId,
    );
  }

  @override
  OtherParticipantIdProvider getProviderOverride(
    covariant OtherParticipantIdProvider provider,
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
  String? get name => r'otherParticipantIdProvider';
}

/// Get other participant ID in one-on-one chat
///
/// Copied from [otherParticipantId].
class OtherParticipantIdProvider extends AutoDisposeProvider<String?> {
  /// Get other participant ID in one-on-one chat
  ///
  /// Copied from [otherParticipantId].
  OtherParticipantIdProvider(
    String chatId,
  ) : this._internal(
          (ref) => otherParticipantId(
            ref as OtherParticipantIdRef,
            chatId,
          ),
          from: otherParticipantIdProvider,
          name: r'otherParticipantIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$otherParticipantIdHash,
          dependencies: OtherParticipantIdFamily._dependencies,
          allTransitiveDependencies:
              OtherParticipantIdFamily._allTransitiveDependencies,
          chatId: chatId,
        );

  OtherParticipantIdProvider._internal(
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
    String? Function(OtherParticipantIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: OtherParticipantIdProvider._internal(
        (ref) => create(ref as OtherParticipantIdRef),
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
  AutoDisposeProviderElement<String?> createElement() {
    return _OtherParticipantIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OtherParticipantIdProvider && other.chatId == chatId;
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
mixin OtherParticipantIdRef on AutoDisposeProviderRef<String?> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _OtherParticipantIdProviderElement
    extends AutoDisposeProviderElement<String?> with OtherParticipantIdRef {
  _OtherParticipantIdProviderElement(super.provider);

  @override
  String get chatId => (origin as OtherParticipantIdProvider).chatId;
}

String _$otherParticipantNameHash() =>
    r'e76a884052e367d9457a5f96a92a600fa4892339';

/// Get other participant name in one-on-one chat
///
/// Copied from [otherParticipantName].
@ProviderFor(otherParticipantName)
const otherParticipantNameProvider = OtherParticipantNameFamily();

/// Get other participant name in one-on-one chat
///
/// Copied from [otherParticipantName].
class OtherParticipantNameFamily extends Family<String?> {
  /// Get other participant name in one-on-one chat
  ///
  /// Copied from [otherParticipantName].
  const OtherParticipantNameFamily();

  /// Get other participant name in one-on-one chat
  ///
  /// Copied from [otherParticipantName].
  OtherParticipantNameProvider call(
    String chatId,
  ) {
    return OtherParticipantNameProvider(
      chatId,
    );
  }

  @override
  OtherParticipantNameProvider getProviderOverride(
    covariant OtherParticipantNameProvider provider,
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
  String? get name => r'otherParticipantNameProvider';
}

/// Get other participant name in one-on-one chat
///
/// Copied from [otherParticipantName].
class OtherParticipantNameProvider extends AutoDisposeProvider<String?> {
  /// Get other participant name in one-on-one chat
  ///
  /// Copied from [otherParticipantName].
  OtherParticipantNameProvider(
    String chatId,
  ) : this._internal(
          (ref) => otherParticipantName(
            ref as OtherParticipantNameRef,
            chatId,
          ),
          from: otherParticipantNameProvider,
          name: r'otherParticipantNameProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$otherParticipantNameHash,
          dependencies: OtherParticipantNameFamily._dependencies,
          allTransitiveDependencies:
              OtherParticipantNameFamily._allTransitiveDependencies,
          chatId: chatId,
        );

  OtherParticipantNameProvider._internal(
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
    String? Function(OtherParticipantNameRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: OtherParticipantNameProvider._internal(
        (ref) => create(ref as OtherParticipantNameRef),
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
  AutoDisposeProviderElement<String?> createElement() {
    return _OtherParticipantNameProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OtherParticipantNameProvider && other.chatId == chatId;
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
mixin OtherParticipantNameRef on AutoDisposeProviderRef<String?> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _OtherParticipantNameProviderElement
    extends AutoDisposeProviderElement<String?> with OtherParticipantNameRef {
  _OtherParticipantNameProviderElement(super.provider);

  @override
  String get chatId => (origin as OtherParticipantNameProvider).chatId;
}

String _$totalChatCountHash() => r'0020ace4596a6d3c98104e88042466fdbfb99fca';

/// Get total chat count
///
/// Copied from [totalChatCount].
@ProviderFor(totalChatCount)
final totalChatCountProvider = AutoDisposeProvider<int>.internal(
  totalChatCount,
  name: r'totalChatCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalChatCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TotalChatCountRef = AutoDisposeProviderRef<int>;
String _$activeChatCountHash() => r'8fa4131163a1de8664a9466cc27a815bd230a803';

/// Get active chat count
///
/// Copied from [activeChatCount].
@ProviderFor(activeChatCount)
final activeChatCountProvider = AutoDisposeProvider<int>.internal(
  activeChatCount,
  name: r'activeChatCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeChatCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveChatCountRef = AutoDisposeProviderRef<int>;
String _$archivedChatCountHash() => r'cd009bdbb14cfacdde49afd5f19ee3f471c60e7a';

/// Get archived chat count
///
/// Copied from [archivedChatCount].
@ProviderFor(archivedChatCount)
final archivedChatCountProvider = AutoDisposeProvider<int>.internal(
  archivedChatCount,
  name: r'archivedChatCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$archivedChatCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ArchivedChatCountRef = AutoDisposeProviderRef<int>;
String _$unreadChatCountHash() => r'dcbf12a5b1b2ce8f1ecd27d00007549d2c0614a5';

/// Get unread chat count
///
/// Copied from [unreadChatCount].
@ProviderFor(unreadChatCount)
final unreadChatCountProvider = AutoDisposeProvider<int>.internal(
  unreadChatCount,
  name: r'unreadChatCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unreadChatCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnreadChatCountRef = AutoDisposeProviderRef<int>;
String _$groupChatCountHash() => r'e97397cd635eaaa165b8a66151a3fd1806c95b72';

/// Get group chat count
///
/// Copied from [groupChatCount].
@ProviderFor(groupChatCount)
final groupChatCountProvider = AutoDisposeProvider<int>.internal(
  groupChatCount,
  name: r'groupChatCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$groupChatCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GroupChatCountRef = AutoDisposeProviderRef<int>;
String _$formattedLastMessageTimeHash() =>
    r'4594352975f7236e2d2c6dc9050a7ec5d0e77634';

/// Format last message time
///
/// Copied from [formattedLastMessageTime].
@ProviderFor(formattedLastMessageTime)
const formattedLastMessageTimeProvider = FormattedLastMessageTimeFamily();

/// Format last message time
///
/// Copied from [formattedLastMessageTime].
class FormattedLastMessageTimeFamily extends Family<String> {
  /// Format last message time
  ///
  /// Copied from [formattedLastMessageTime].
  const FormattedLastMessageTimeFamily();

  /// Format last message time
  ///
  /// Copied from [formattedLastMessageTime].
  FormattedLastMessageTimeProvider call(
    String chatId,
  ) {
    return FormattedLastMessageTimeProvider(
      chatId,
    );
  }

  @override
  FormattedLastMessageTimeProvider getProviderOverride(
    covariant FormattedLastMessageTimeProvider provider,
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
  String? get name => r'formattedLastMessageTimeProvider';
}

/// Format last message time
///
/// Copied from [formattedLastMessageTime].
class FormattedLastMessageTimeProvider extends AutoDisposeProvider<String> {
  /// Format last message time
  ///
  /// Copied from [formattedLastMessageTime].
  FormattedLastMessageTimeProvider(
    String chatId,
  ) : this._internal(
          (ref) => formattedLastMessageTime(
            ref as FormattedLastMessageTimeRef,
            chatId,
          ),
          from: formattedLastMessageTimeProvider,
          name: r'formattedLastMessageTimeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$formattedLastMessageTimeHash,
          dependencies: FormattedLastMessageTimeFamily._dependencies,
          allTransitiveDependencies:
              FormattedLastMessageTimeFamily._allTransitiveDependencies,
          chatId: chatId,
        );

  FormattedLastMessageTimeProvider._internal(
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
    String Function(FormattedLastMessageTimeRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FormattedLastMessageTimeProvider._internal(
        (ref) => create(ref as FormattedLastMessageTimeRef),
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
  AutoDisposeProviderElement<String> createElement() {
    return _FormattedLastMessageTimeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FormattedLastMessageTimeProvider && other.chatId == chatId;
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
mixin FormattedLastMessageTimeRef on AutoDisposeProviderRef<String> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _FormattedLastMessageTimeProviderElement
    extends AutoDisposeProviderElement<String>
    with FormattedLastMessageTimeRef {
  _FormattedLastMessageTimeProviderElement(super.provider);

  @override
  String get chatId => (origin as FormattedLastMessageTimeProvider).chatId;
}

String _$lastMessagePreviewHash() =>
    r'92fd1c57fb7815e690f31d4364ea1d61f68b64e3';

/// Get last message preview
///
/// Copied from [lastMessagePreview].
@ProviderFor(lastMessagePreview)
const lastMessagePreviewProvider = LastMessagePreviewFamily();

/// Get last message preview
///
/// Copied from [lastMessagePreview].
class LastMessagePreviewFamily extends Family<String> {
  /// Get last message preview
  ///
  /// Copied from [lastMessagePreview].
  const LastMessagePreviewFamily();

  /// Get last message preview
  ///
  /// Copied from [lastMessagePreview].
  LastMessagePreviewProvider call(
    String chatId,
  ) {
    return LastMessagePreviewProvider(
      chatId,
    );
  }

  @override
  LastMessagePreviewProvider getProviderOverride(
    covariant LastMessagePreviewProvider provider,
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
  String? get name => r'lastMessagePreviewProvider';
}

/// Get last message preview
///
/// Copied from [lastMessagePreview].
class LastMessagePreviewProvider extends AutoDisposeProvider<String> {
  /// Get last message preview
  ///
  /// Copied from [lastMessagePreview].
  LastMessagePreviewProvider(
    String chatId,
  ) : this._internal(
          (ref) => lastMessagePreview(
            ref as LastMessagePreviewRef,
            chatId,
          ),
          from: lastMessagePreviewProvider,
          name: r'lastMessagePreviewProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$lastMessagePreviewHash,
          dependencies: LastMessagePreviewFamily._dependencies,
          allTransitiveDependencies:
              LastMessagePreviewFamily._allTransitiveDependencies,
          chatId: chatId,
        );

  LastMessagePreviewProvider._internal(
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
    String Function(LastMessagePreviewRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LastMessagePreviewProvider._internal(
        (ref) => create(ref as LastMessagePreviewRef),
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
  AutoDisposeProviderElement<String> createElement() {
    return _LastMessagePreviewProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LastMessagePreviewProvider && other.chatId == chatId;
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
mixin LastMessagePreviewRef on AutoDisposeProviderRef<String> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _LastMessagePreviewProviderElement
    extends AutoDisposeProviderElement<String> with LastMessagePreviewRef {
  _LastMessagePreviewProviderElement(super.provider);

  @override
  String get chatId => (origin as LastMessagePreviewProvider).chatId;
}

String _$isOneOnOneChatHash() => r'0c0c14cf25efa947ea8abe02ed7913e477a9399a';

/// Check if chat is one-on-one
///
/// Copied from [isOneOnOneChat].
@ProviderFor(isOneOnOneChat)
const isOneOnOneChatProvider = IsOneOnOneChatFamily();

/// Check if chat is one-on-one
///
/// Copied from [isOneOnOneChat].
class IsOneOnOneChatFamily extends Family<bool> {
  /// Check if chat is one-on-one
  ///
  /// Copied from [isOneOnOneChat].
  const IsOneOnOneChatFamily();

  /// Check if chat is one-on-one
  ///
  /// Copied from [isOneOnOneChat].
  IsOneOnOneChatProvider call(
    String chatId,
  ) {
    return IsOneOnOneChatProvider(
      chatId,
    );
  }

  @override
  IsOneOnOneChatProvider getProviderOverride(
    covariant IsOneOnOneChatProvider provider,
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
  String? get name => r'isOneOnOneChatProvider';
}

/// Check if chat is one-on-one
///
/// Copied from [isOneOnOneChat].
class IsOneOnOneChatProvider extends AutoDisposeProvider<bool> {
  /// Check if chat is one-on-one
  ///
  /// Copied from [isOneOnOneChat].
  IsOneOnOneChatProvider(
    String chatId,
  ) : this._internal(
          (ref) => isOneOnOneChat(
            ref as IsOneOnOneChatRef,
            chatId,
          ),
          from: isOneOnOneChatProvider,
          name: r'isOneOnOneChatProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isOneOnOneChatHash,
          dependencies: IsOneOnOneChatFamily._dependencies,
          allTransitiveDependencies:
              IsOneOnOneChatFamily._allTransitiveDependencies,
          chatId: chatId,
        );

  IsOneOnOneChatProvider._internal(
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
    bool Function(IsOneOnOneChatRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsOneOnOneChatProvider._internal(
        (ref) => create(ref as IsOneOnOneChatRef),
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
  AutoDisposeProviderElement<bool> createElement() {
    return _IsOneOnOneChatProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsOneOnOneChatProvider && other.chatId == chatId;
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
mixin IsOneOnOneChatRef on AutoDisposeProviderRef<bool> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _IsOneOnOneChatProviderElement extends AutoDisposeProviderElement<bool>
    with IsOneOnOneChatRef {
  _IsOneOnOneChatProviderElement(super.provider);

  @override
  String get chatId => (origin as IsOneOnOneChatProvider).chatId;
}

String _$isGroupChatHash() => r'c87bb2659bcee57d22544da976344a0a5eb156df';

/// Check if chat is group
///
/// Copied from [isGroupChat].
@ProviderFor(isGroupChat)
const isGroupChatProvider = IsGroupChatFamily();

/// Check if chat is group
///
/// Copied from [isGroupChat].
class IsGroupChatFamily extends Family<bool> {
  /// Check if chat is group
  ///
  /// Copied from [isGroupChat].
  const IsGroupChatFamily();

  /// Check if chat is group
  ///
  /// Copied from [isGroupChat].
  IsGroupChatProvider call(
    String chatId,
  ) {
    return IsGroupChatProvider(
      chatId,
    );
  }

  @override
  IsGroupChatProvider getProviderOverride(
    covariant IsGroupChatProvider provider,
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
  String? get name => r'isGroupChatProvider';
}

/// Check if chat is group
///
/// Copied from [isGroupChat].
class IsGroupChatProvider extends AutoDisposeProvider<bool> {
  /// Check if chat is group
  ///
  /// Copied from [isGroupChat].
  IsGroupChatProvider(
    String chatId,
  ) : this._internal(
          (ref) => isGroupChat(
            ref as IsGroupChatRef,
            chatId,
          ),
          from: isGroupChatProvider,
          name: r'isGroupChatProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isGroupChatHash,
          dependencies: IsGroupChatFamily._dependencies,
          allTransitiveDependencies:
              IsGroupChatFamily._allTransitiveDependencies,
          chatId: chatId,
        );

  IsGroupChatProvider._internal(
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
    bool Function(IsGroupChatRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsGroupChatProvider._internal(
        (ref) => create(ref as IsGroupChatRef),
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
  AutoDisposeProviderElement<bool> createElement() {
    return _IsGroupChatProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsGroupChatProvider && other.chatId == chatId;
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
mixin IsGroupChatRef on AutoDisposeProviderRef<bool> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _IsGroupChatProviderElement extends AutoDisposeProviderElement<bool>
    with IsGroupChatRef {
  _IsGroupChatProviderElement(super.provider);

  @override
  String get chatId => (origin as IsGroupChatProvider).chatId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

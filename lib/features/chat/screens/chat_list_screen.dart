// lib/features/chat/screens/chat_list_screen.dart
// Updated for WeChat-style contact-based messaging
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/chat/models/chat_list_item_model.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/chat/screens/chat_screen.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/features/users/models/user_model.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Cache manager for profile images
  static final DefaultCacheManager _imageCacheManager = DefaultCacheManager();

  // In-memory cache for current session
  List<ChatListItemModel>? _cachedChats;
  DateTime? _lastCacheUpdate;
  bool _isInitialLoad = true;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadCachedData();

    // Listen to search focus changes
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearching = _searchFocusNode.hasFocus;
      });
    });
  }

  // Load cached chat data from persistent storage
  Future<void> _loadCachedData() async {
    try {
      final cachedData = await _getCachedChatList();
      if (cachedData != null && mounted) {
        setState(() {
          _cachedChats = cachedData;
          _isInitialLoad = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading cached chat data: $e');
    }
  }

  // Get cached chat list from cache manager (simplified)
  Future<List<ChatListItemModel>?> _getCachedChatList() async {
    // For now, just return the in-memory cache
    return _cachedChats;
  }

  // Cache chat list data (simplified)
  Future<void> _cacheChatList(List<ChatListItemModel> chats) async {
    // Just update in-memory cache for now
    setState(() {
      _cachedChats = chats;
      _lastCacheUpdate = DateTime.now();
    });
  }

  // Preload contact images for better performance
  Future<void> _preloadContactImages(List<ChatListItemModel> chats) async {
    final imagesToPreload = chats
        .where((chat) => chat.contactImage.isNotEmpty)
        .map((chat) => chat.contactImage)
        .take(10) // Preload only first 10 to avoid excessive memory usage
        .toList();

    for (final imageUrl in imagesToPreload) {
      try {
        _imageCacheManager.getSingleFile(imageUrl);
      } catch (e) {
        debugPrint('Error preloading image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final modernTheme = context.modernTheme;

    // Watch the current user using new auth system
    final currentUser = ref.watch(currentUserProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    if (!isAuthenticated || currentUser == null) {
      return _buildNotAuthenticatedState(modernTheme);
    }

    // User is authenticated, show the chat list
    return _buildAuthenticatedChatList(currentUser, modernTheme);
  }

  Widget _buildAuthenticatedChatList(
      UserModel user, ModernThemeExtension modernTheme) {
    final chatListState = ref.watch(chatListProvider);

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
          _clearSearch();
        }
      },
      child: Scaffold(
        backgroundColor: modernTheme.surfaceColor,
        body: SafeArea(
          child: Column(
            children: [
              // Search bar
              _buildSearchBar(modernTheme),
              // Chat list
              Expanded(
                child: chatListState.when(
                  loading: () {
                    // Show cached data while loading if available
                    if (_cachedChats != null && _cachedChats!.isNotEmpty) {
                      return Column(
                        children: [
                          // Loading indicator at top
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      modernTheme.primaryColor ??
                                          const Color(0xFF07C160),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Updating...',
                                  style: TextStyle(
                                    color: modernTheme.textSecondaryColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Cached chat list
                          Expanded(
                            child: _buildChatListFromCache(
                                _cachedChats!, modernTheme, user.uid),
                          ),
                        ],
                      );
                    }
                    return _buildLoadingState(modernTheme);
                  },
                  error: (error, stack) {
                    debugPrint('Chat list error: $error');
                    // Show cached data with error indicator if available
                    if (_cachedChats != null && _cachedChats!.isNotEmpty) {
                      return Column(
                        children: [
                          // Error indicator at top
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            color: Colors.red.withOpacity(0.1),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 16,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Failed to update. Showing cached data.',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      ref.refresh(chatListProvider),
                                  child: const Text(
                                    'Retry',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Cached chat list
                          Expanded(
                            child: _buildChatListFromCache(
                                _cachedChats!, modernTheme, user.uid),
                          ),
                        ],
                      );
                    }
                    return _buildErrorState(modernTheme, error.toString());
                  },
                  data: (state) {
                    // Cache the new data
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _cacheChatList(state.chats);
                      _preloadContactImages(state.chats);
                    });

                    return _buildChatList(state, user.uid, modernTheme);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ModernThemeExtension modernTheme) {
    final chatListNotifier = ref.read(chatListProvider.notifier);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: modernTheme.backgroundColor?.withOpacity(0.6),
        border: Border(
          bottom: BorderSide(
            color: (modernTheme.dividerColor ?? Colors.grey).withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: TextStyle(color: modernTheme.textColor),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: modernTheme.textSecondaryColor),
                prefixIcon: Icon(
                  CupertinoIcons.search,
                  color: modernTheme.textSecondaryColor,
                  size: 20,
                ),
                filled: true,
                fillColor: modernTheme.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onChanged: (query) => chatListNotifier.setSearchQuery(query),
            ),
          ),
          if (_isSearching) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: _clearSearch,
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: modernTheme.primaryColor ?? const Color(0xFF07C160),
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    final chatListNotifier = ref.read(chatListProvider.notifier);
    chatListNotifier.setSearchQuery('');
  }

  Widget _buildNotAuthenticatedState(ModernThemeExtension modernTheme) {
    return Scaffold(
      backgroundColor: modernTheme.surfaceColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (modernTheme.primaryColor ?? const Color(0xFF07C160))
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.chat_bubble_2,
                size: 64,
                color: modernTheme.primaryColor ?? const Color(0xFF07C160),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sign In Required',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please sign in to view your chats',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                Constants.landingScreen,
                (route) => false,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    modernTheme.primaryColor ?? const Color(0xFF07C160),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ModernThemeExtension modernTheme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 8,
      itemBuilder: (context, index) => _buildShimmerChatItem(modernTheme),
    );
  }

  Widget _buildShimmerChatItem(ModernThemeExtension modernTheme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: (modernTheme.dividerColor ?? Colors.grey).withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      title: Container(
        height: 16,
        width: double.infinity,
        decoration: BoxDecoration(
          color: (modernTheme.dividerColor ?? Colors.grey).withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      subtitle: Container(
        height: 12,
        width: 200,
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: (modernTheme.dividerColor ?? Colors.grey).withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      trailing: Container(
        height: 12,
        width: 50,
        decoration: BoxDecoration(
          color: (modernTheme.dividerColor ?? Colors.grey).withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildErrorState(ModernThemeExtension modernTheme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 64,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Failed to load chats',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Please check your internet connection',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => ref.refresh(chatListProvider),
            icon: const Icon(CupertinoIcons.refresh, size: 18),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  modernTheme.primaryColor ?? const Color(0xFF07C160),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatListFromCache(List<ChatListItemModel> chats,
      ModernThemeExtension modernTheme, String currentUserId) {
    if (chats.isEmpty) {
      return _buildEmptyState(modernTheme);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chatItem = chats[index];

        return _buildChatItem(
          chatItem,
          currentUserId,
          modernTheme,
        );
      },
    );
  }

  Widget _buildChatList(ChatListState state, String currentUserId,
      ModernThemeExtension modernTheme) {
    if (state.chats.isEmpty && state.searchQuery.isEmpty) {
      return _buildEmptyState(modernTheme);
    }

    final filteredChats = state.filteredChats;

    if (filteredChats.isEmpty && state.searchQuery.isNotEmpty) {
      return _buildNoSearchResultsState(modernTheme, state.searchQuery);
    }

    // Get pinned and regular chats
    final chatListNotifier = ref.read(chatListProvider.notifier);
    final pinnedChats = chatListNotifier.getPinnedChats();
    final regularChats = chatListNotifier.getRegularChats();

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(chatListProvider);
      },
      color: modernTheme.primaryColor ?? const Color(0xFF07C160),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 0, bottom: 100),
        itemCount: pinnedChats.length + regularChats.length,
        itemBuilder: (context, index) {
          // Pinned chats
          if (index < pinnedChats.length) {
            return _buildChatItem(
              pinnedChats[index],
              currentUserId,
              modernTheme,
              isPinned: true,
            );
          }

          // Regular chats
          final chatIndex = index - pinnedChats.length;

          if (chatIndex < regularChats.length) {
            return _buildChatItem(
              regularChats[chatIndex],
              currentUserId,
              modernTheme,
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState(ModernThemeExtension modernTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: (modernTheme.primaryColor ?? const Color(0xFF07C160))
                  .withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.chat_bubble_2,
              size: 64,
              color: modernTheme.primaryColor ?? const Color(0xFF07C160),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Chats',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with your contacts',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _navigateToContacts(),
            icon: const Icon(
              CupertinoIcons.person_2_square_stack_fill,
              color: Colors.white,
              size: 18,
            ),
            label: const Text('View Contacts'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  modernTheme.primaryColor ?? const Color(0xFF07C160),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResultsState(
      ModernThemeExtension modernTheme, String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.search,
            size: 64,
            color: modernTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No Results',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No chats match "$query"',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(ChatListItemModel chatItem, String currentUserId,
      ModernThemeExtension modernTheme,
      {bool isPinned = false}) {
    final unreadCount = chatItem.chat.getUnreadCount(currentUserId);
    final hasUnread = unreadCount > 0;
    final isMuted = chatItem.chat.isMutedForUser(currentUserId);

    return InkWell(
      onTap: () => _openChat(chatItem),
      onLongPress: () => _showChatOptions(chatItem),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: modernTheme.backgroundColor,
          border: Border(
            bottom: BorderSide(
              color: modernTheme.dividerColor ?? Colors.grey[300]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            _buildCachedAvatar(chatItem, modernTheme),
            const SizedBox(width: 12),

            // Chat info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chatItem.contactName,
                          style: TextStyle(
                            color: modernTheme.textColor,
                            fontWeight:
                                hasUnread ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        chatItem.getDisplayTime(),
                        style: TextStyle(
                          color: modernTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isMuted)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            CupertinoIcons.bell_slash_fill,
                            size: 14,
                            color: modernTheme.textSecondaryColor,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          chatItem.getLastMessagePreview(
                              currentUserId: currentUserId),
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isMuted
                                ? modernTheme.textSecondaryColor
                                : Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCachedAvatar(
      ChatListItemModel chatItem, ModernThemeExtension modernTheme) {
    if (chatItem.contactImage.isEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: (modernTheme.primaryColor ?? const Color(0xFF07C160))
              .withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            _getAvatarInitials(chatItem.contactName),
            style: TextStyle(
              color: modernTheme.primaryColor ?? const Color(0xFF07C160),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: chatItem.contactImage,
      imageBuilder: (context, imageProvider) => Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
      placeholder: (context, url) => Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: (modernTheme.primaryColor ?? const Color(0xFF07C160))
              .withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CupertinoActivityIndicator(),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: (modernTheme.primaryColor ?? const Color(0xFF07C160))
              .withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            _getAvatarInitials(chatItem.contactName),
            style: TextStyle(
              color: modernTheme.primaryColor ?? const Color(0xFF07C160),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
      cacheManager: _imageCacheManager,
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
    );
  }

  String _getAvatarInitials(String name) {
    if (name.isEmpty) return 'U'; // U for Unknown User, better than '?'

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return 'U';

    final words = trimmedName.split(' ');
    if (words.length >= 2 && words[0].isNotEmpty && words[1].isNotEmpty) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }

    // Single word or name - use first character
    return trimmedName[0].toUpperCase();
  }

  void _openChat(ChatListItemModel chatItem) async {
    try {
      debugPrint('🔵 Opening chat: ${chatItem.chat.chatId}');

      // Mark chat as read when opening
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        debugPrint('❌ No current user, cannot open chat');
        return;
      }

      debugPrint('🔵 Current user: ${currentUser.uid}');

      final chatListNotifier = ref.read(chatListProvider.notifier);
      await chatListNotifier.markChatAsRead(chatItem.chat.chatId);

      // Get the other participant's user ID
      final otherUserId = chatItem.chat.getOtherParticipant(currentUser.uid);
      debugPrint('🔵 Other user ID: $otherUserId');

      // Get full user data from authentication provider
      final authNotifier = ref.read(authenticationProvider.notifier);
      UserModel? contactUser;

      try {
        contactUser = await authNotifier.getUserById(otherUserId);
        debugPrint('✅ Got contact user: ${contactUser?.name}');
      } catch (e) {
        debugPrint('⚠️ Error fetching contact user data: $e');
      }

      // Create UserModel with available data
      final contact = contactUser ??
          UserModel(
            uid: otherUserId,
            phoneNumber: chatItem.contactPhone,
            name: chatItem.contactName.isNotEmpty
                ? chatItem.contactName
                : 'Unknown User',
            bio: '',
            profileImage: chatItem.contactImage,
            coverImage: '',
            followers: 0,
            following: 0,
            videosCount: 0,
            likesCount: 0,
            isVerified: false,
            tags: [],
            followerUIDs: [],
            followingUIDs: [],
            likedVideos: [],
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
            lastSeen: DateTime.now().toIso8601String(),
            isActive: true,
            isFeatured: false,
          );

      debugPrint('🔵 Final contact name: ${contact.name}');
      debugPrint('🔵 Navigating to ChatScreen...');

      // Navigate to chat screen
      if (mounted) {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatItem.chat.chatId,
              contact: contact,
            ),
          ),
        );

        debugPrint('✅ Returned from ChatScreen with result: $result');

        // Refresh chat list if message was sent
        if (result == true) {
          ref.refresh(chatListProvider);
        }
      } else {
        debugPrint('❌ Widget not mounted, cannot navigate');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in _openChat: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void _showChatOptions(ChatListItemModel chatItem) {
    final modernTheme = context.modernTheme;
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final isPinned = chatItem.chat.isPinnedForUser(currentUser.uid);
    final isMuted = chatItem.chat.isMutedForUser(currentUser.uid);

    showModalBottomSheet(
      context: context,
      backgroundColor: modernTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: modernTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Contact info header
            ListTile(
              leading: _buildCachedAvatar(chatItem, modernTheme),
              title: Text(
                chatItem.contactName,
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                chatItem.contactPhone,
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontSize: 14,
                ),
              ),
            ),

            const Divider(height: 1),

            ListTile(
              leading: Icon(
                isPinned ? CupertinoIcons.pin_slash : CupertinoIcons.pin,
                color: modernTheme.textColor,
              ),
              title: Text(
                isPinned ? 'Unpin' : 'Pin',
                style: TextStyle(color: modernTheme.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _togglePinChat(chatItem.chat.chatId);
              },
            ),

            ListTile(
              leading: Icon(
                isMuted ? CupertinoIcons.speaker_2 : CupertinoIcons.bell_slash,
                color: modernTheme.textColor,
              ),
              title: Text(
                isMuted ? 'Unmute' : 'Mute',
                style: TextStyle(color: modernTheme.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleMuteChat(chatItem.chat.chatId);
              },
            ),

            ListTile(
              leading: const Icon(
                CupertinoIcons.delete,
                color: Colors.red,
              ),
              title: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteChat(chatItem.chat.chatId, chatItem.contactName);
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePinChat(String chatId) async {
    try {
      final chatListNotifier = ref.read(chatListProvider.notifier);
      await chatListNotifier.togglePinChat(chatId);

      if (mounted) {
        showSnackBar(context, 'Chat updated');
      }
    } catch (e) {
      debugPrint('Error toggling pin chat: $e');
      if (mounted) {
        showSnackBar(context, 'Failed to update chat');
      }
    }
  }

  Future<void> _toggleMuteChat(String chatId) async {
    try {
      final chatListNotifier = ref.read(chatListProvider.notifier);
      await chatListNotifier.toggleMuteChat(chatId);

      if (mounted) {
        showSnackBar(context, 'Chat updated');
      }
    } catch (e) {
      debugPrint('Error toggling mute chat: $e');
      if (mounted) {
        showSnackBar(context, 'Failed to update chat');
      }
    }
  }

  void _confirmDeleteChat(String chatId, String contactName) {
    final modernTheme = context.modernTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: modernTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Delete Chat',
          style: TextStyle(color: modernTheme.textColor),
        ),
        content: Text(
          'Delete chat with $contactName?',
          style: TextStyle(color: modernTheme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: modernTheme.textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteChat(chatId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChat(String chatId) async {
    try {
      final chatListNotifier = ref.read(chatListProvider.notifier);
      await chatListNotifier.deleteChat(chatId, deleteForEveryone: false);

      if (mounted) {
        showSnackBar(context, 'Chat deleted');
      }
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      if (mounted) {
        showSnackBar(context, 'Failed to delete chat');
      }
    }
  }

  void _navigateToContacts() {
    // Navigate to contacts tab (index 1 in HomeScreen)
    // Since we're already in HomeScreen, we need to notify the parent to switch tabs
    // For now, just pop and let user navigate via bottom nav
    if (mounted) {
      // This will be handled by the HomeScreen's bottom navigation
      // User can tap the Contacts tab (index 1)
      showSnackBar(context, 'Tap the Contacts tab to view your contacts');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

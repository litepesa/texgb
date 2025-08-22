// lib/features/chat/screens/chat_list_screen.dart - Updated with Caching
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/chat/models/chat_list_item_model.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart' hide messageNotifierProvider;
import 'package:textgb/features/chat/screens/chat_screen.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/models/user_model.dart';

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
  
  // Cache key for storing chat list data
  static const String _chatListCacheKey = 'cached_chat_list_data';
  static const String _lastUpdateCacheKey = 'chat_list_last_update';
  
  // In-memory cache for current session
  List<ChatListItemModel>? _cachedChats;
  DateTime? _lastCacheUpdate;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
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
    // You can implement persistent caching later when the models support it
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

  // Clear chat list cache (simplified)
  Future<void> _clearChatListCache() async {
    try {
      await _imageCacheManager.emptyCache();
      
      setState(() {
        _cachedChats = null;
        _lastCacheUpdate = null;
      });
      
      if (mounted) {
        showSnackBar(context, 'Chat list cache cleared');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to clear cache');
      }
    }
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
        // Continue preloading other images even if one fails
        debugPrint('Error preloading image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final modernTheme = context.modernTheme;
    
    // Watch the authentication state
    final authState = ref.watch(authenticationProvider);
    
    return authState.when(
      loading: () => _buildLoadingAuthState(modernTheme),
      error: (error, stack) => _buildNotAuthenticatedState(modernTheme),
      data: (authenticationState) {
        if (authenticationState.userModel == null) {
          return _buildNotAuthenticatedState(modernTheme);
        }
        
        // User is authenticated, show the chat list
        return _buildAuthenticatedChatList(authenticationState.userModel!, modernTheme);
      },
    );
  }

  Widget _buildLoadingAuthState(ModernThemeExtension modernTheme) {
    // Show cached data while authenticating if available
    if (_cachedChats != null && _cachedChats!.isNotEmpty) {
      return _buildCachedChatList(_cachedChats!, modernTheme);
    }
    
    return Scaffold(
      backgroundColor: modernTheme.surfaceColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(modernTheme.primaryColor!),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCachedChatList(List<ChatListItemModel> cachedChats, ModernThemeExtension modernTheme) {
    return Scaffold(
      backgroundColor: modernTheme.surfaceColor,
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(modernTheme),
          
          // Cached data indicator
          if (_lastCacheUpdate != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: modernTheme.primaryColor?.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.cached,
                    size: 16,
                    color: modernTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Showing cached data from ${_formatCacheTime(_lastCacheUpdate!)}',
                    style: TextStyle(
                      color: modernTheme.primaryColor,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ref.refresh(chatListProvider);
                    },
                    child: Text(
                      'Refresh',
                      style: TextStyle(
                        color: modernTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Chat list
          Expanded(
            child: _buildChatListFromCache(cachedChats, modernTheme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToContacts(),
        backgroundColor: modernTheme.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.chat),
      ),
    );
  }

  Widget _buildAuthenticatedChatList(UserModel user, ModernThemeExtension modernTheme) {
    final chatListState = ref.watch(chatListProvider);
    
    return Scaffold(
      backgroundColor: modernTheme.surfaceColor,
      body: Column(
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
                                valueColor: AlwaysStoppedAnimation<Color>(modernTheme.primaryColor!),
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
                        child: _buildChatListFromCache(_cachedChats!, modernTheme),
                      ),
                    ],
                  );
                }
                return _buildLoadingState(modernTheme);
              },
              error: (error, stack) {
                // Show cached data with error indicator if available
                if (_cachedChats != null && _cachedChats!.isNotEmpty) {
                  return Column(
                    children: [
                      // Error indicator at top
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: Colors.red.withOpacity(0.1),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 16,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Failed to update. Showing cached data.',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => ref.refresh(chatListProvider),
                              child: Text(
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
                        child: _buildChatListFromCache(_cachedChats!, modernTheme),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToContacts(),
        backgroundColor: modernTheme.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.chat),
      ),
    );
  }

  String _formatCacheTime(DateTime cacheTime) {
    final now = DateTime.now();
    final difference = now.difference(cacheTime);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM dd').format(cacheTime);
    }
  }

  Widget _buildSearchBar(ModernThemeExtension modernTheme) {
    final chatListNotifier = ref.read(chatListProvider.notifier);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: modernTheme.dividerColor!.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: TextStyle(color: modernTheme.textColor),
              decoration: InputDecoration(
                hintText: 'Search chats...',
                hintStyle: TextStyle(color: modernTheme.textSecondaryColor),
                prefixIcon: Icon(
                  Icons.search,
                  color: modernTheme.textSecondaryColor,
                  size: 20,
                ),
                filled: true,
                fillColor: modernTheme.backgroundColor?.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (query) => chatListNotifier.setSearchQuery(query),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: modernTheme.textColor,
            ),
            color: modernTheme.surfaceColor,
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: modernTheme.textColor, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Refresh',
                      style: TextStyle(color: modernTheme.textColor),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_cache',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: modernTheme.textColor, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Clear Cache',
                      style: TextStyle(color: modernTheme.textColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        ref.refresh(chatListProvider);
        break;
      case 'clear_cache':
        _clearChatListCache();
        break;
    }
  }

  Widget _buildNotAuthenticatedState(ModernThemeExtension modernTheme) {
    return Scaffold(
      backgroundColor: modernTheme.surfaceColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: modernTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Please log in to view chats',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
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
          color: modernTheme.dividerColor?.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
      ),
      title: Container(
        height: 16,
        width: double.infinity,
        decoration: BoxDecoration(
          color: modernTheme.dividerColor?.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      subtitle: Container(
        height: 12,
        width: 200,
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: modernTheme.dividerColor?.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      trailing: Container(
        height: 12,
        width: 50,
        decoration: BoxDecoration(
          color: modernTheme.dividerColor?.withOpacity(0.2),
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
          Icon(
            Icons.error_outline,
            size: 64,
            color: modernTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load chats',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.refresh(chatListProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: modernTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatListFromCache(List<ChatListItemModel> chats, ModernThemeExtension modernTheme) {
    if (chats.isEmpty) {
      return _buildEmptyState(modernTheme);
    }

    // Simple list without filtering for cached data
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chatItem = chats[index];
        final currentUser = ref.read(currentUserProvider);
        
        return _buildChatItem(
          chatItem, 
          currentUser?.uid ?? '', 
          modernTheme,
        );
      },
    );
  }

  Widget _buildChatList(ChatListState state, String currentUserId, ModernThemeExtension modernTheme) {
    if (state.chats.isEmpty && state.searchQuery.isEmpty) {
      return _buildEmptyState(modernTheme);
    }

    final filteredChats = state.filteredChats;
    
    if (filteredChats.isEmpty && state.searchQuery.isNotEmpty) {
      return _buildNoSearchResultsState(modernTheme, state.searchQuery);
    }

    final pinnedChats = state.pinnedChats;
    final regularChats = state.regularChats;

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(chatListProvider);
      },
      color: modernTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: pinnedChats.length + regularChats.length + (pinnedChats.isNotEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          // Pinned section header
          if (pinnedChats.isNotEmpty && index == 0) {
            return _buildSectionHeader('Pinned', modernTheme);
          }
          
          // Pinned chats
          if (pinnedChats.isNotEmpty && index <= pinnedChats.length) {
            final chatIndex = index - 1;
            return _buildChatItem(
              pinnedChats[chatIndex], 
              currentUserId, 
              modernTheme,
              isPinned: true,
            );
          }
          
          // Regular chats
          final chatIndex = pinnedChats.isNotEmpty 
              ? index - pinnedChats.length - 1 
              : index;
          
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

  Widget _buildSectionHeader(String title, ModernThemeExtension modernTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: modernTheme.primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
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
              color: modernTheme.primaryColor?.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.bubble_left_bubble_right,
              size: 64,
              color: modernTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No chats yet',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with your contacts',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _navigateToContacts(),
            icon: const Icon(
              CupertinoIcons.person_add,
              color: Colors.white,
              size: 20,
            ),
            label: const Text(
              'Start Chatting',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: modernTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResultsState(ModernThemeExtension modernTheme, String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: modernTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No chats found',
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

  Widget _buildChatItem(
    ChatListItemModel chatItem, 
    String currentUserId, 
    ModernThemeExtension modernTheme,
    {bool isPinned = false}
  ) {
    final unreadCount = chatItem.chat.getUnreadCount(currentUserId);
    final hasUnread = unreadCount > 0;
    final isMuted = chatItem.chat.isMutedForUser(currentUserId);
    
    return Dismissible(
      key: ValueKey(chatItem.chat.chatId),
      background: _buildDismissBackground(modernTheme, isLeftSwipe: false),
      secondaryBackground: _buildDismissBackground(modernTheme, isLeftSwipe: true),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Archive chat
          await _archiveChat(chatItem.chat.chatId, currentUserId);
          return false;
        } else {
          // Pin/unpin chat
          await _togglePinChat(chatItem.chat.chatId, currentUserId);
          return false;
        }
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Stack(
          children: [
            _buildCachedAvatar(chatItem, modernTheme),
            if (chatItem.isOnline)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: modernTheme.surfaceColor!,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                chatItem.contactName,
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isPinned) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.push_pin,
                size: 14,
                color: modernTheme.primaryColor,
              ),
            ],
            if (isMuted) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.volume_off,
                size: 14,
                color: modernTheme.textSecondaryColor,
              ),
            ],
          ],
        ),
        subtitle: Row(
          children: [
            if (chatItem.chat.lastMessageSender == currentUserId) ...[
              Icon(
                Icons.done_all,
                size: 14,
                color: modernTheme.textSecondaryColor,
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                chatItem.getLastMessagePreview(currentUserId: currentUserId),
                style: TextStyle(
                  color: hasUnread 
                    ? modernTheme.textColor 
                    : modernTheme.textSecondaryColor,
                  fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              chatItem.getDisplayTime(),
              style: TextStyle(
                color: hasUnread 
                  ? modernTheme.primaryColor 
                  : modernTheme.textSecondaryColor,
                fontSize: 12,
                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            if (hasUnread) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isMuted 
                    ? modernTheme.textSecondaryColor 
                    : modernTheme.primaryColor,
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
          ],
        ),
        onTap: () => _openChat(chatItem),
        onLongPress: () => _showChatOptions(chatItem, currentUserId),
      ),
    );
  }

  Widget _buildCachedAvatar(ChatListItemModel chatItem, ModernThemeExtension modernTheme) {
    if (chatItem.contactImage.isEmpty) {
      return CircleAvatar(
        radius: 25,
        backgroundColor: modernTheme.primaryColor?.withOpacity(0.2),
        child: Text(
          _getAvatarInitials(chatItem.contactName),
          style: TextStyle(
            color: modernTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: chatItem.contactImage,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: 25,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: 25,
        backgroundColor: modernTheme.primaryColor?.withOpacity(0.2),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(modernTheme.primaryColor!),
          ),
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: 25,
        backgroundColor: modernTheme.primaryColor?.withOpacity(0.2),
        child: Text(
          _getAvatarInitials(chatItem.contactName),
          style: TextStyle(
            color: modernTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      cacheManager: _imageCacheManager,
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
    );
  }

  Widget _buildDismissBackground(ModernThemeExtension modernTheme, {required bool isLeftSwipe}) {
    return Container(
      alignment: isLeftSwipe ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: isLeftSwipe ? Colors.red.withOpacity(0.8) : modernTheme.primaryColor,
      child: Icon(
        isLeftSwipe ? Icons.archive : Icons.push_pin,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  String _getAvatarInitials(String name) {
    if (name.isEmpty) return '?';
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  void _openChat(ChatListItemModel chatItem) async {
    // Mark chat as read when opening
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      final chatListNotifier = ref.read(chatListProvider.notifier);
      await chatListNotifier.markChatAsRead(chatItem.chat.chatId, currentUser.uid);
    }

    // Navigate to chat screen
    if (mounted && currentUser != null) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatItem.chat.chatId,
            contact: UserModel(
              uid: chatItem.chat.getOtherParticipant(currentUser.uid),
              name: chatItem.contactName,
              phoneNumber: chatItem.contactPhone,
              image: chatItem.contactImage,
              token: '',
              aboutMe: '',
              lastSeen: '',
              createdAt: '',
              contactsUIDs: [],
              blockedUIDs: [],
            ),
          ),
        ),
      );

      // Refresh chat list if message was sent
      if (result == true) {
        ref.refresh(chatListProvider);
      }
    }
  }

  void _showChatOptions(ChatListItemModel chatItem, String currentUserId) {
    final modernTheme = context.modernTheme;
    final isPinned = chatItem.chat.isPinnedForUser(currentUserId);
    final isMuted = chatItem.chat.isMutedForUser(currentUserId);
    
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
            
            ListTile(
              leading: Icon(
                isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                color: modernTheme.textColor,
              ),
              title: Text(
                isPinned ? 'Unpin chat' : 'Pin chat',
                style: TextStyle(color: modernTheme.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _togglePinChat(chatItem.chat.chatId, currentUserId);
              },
            ),
            
            ListTile(
              leading: Icon(
                isMuted ? Icons.volume_up : Icons.volume_off,
                color: modernTheme.textColor,
              ),
              title: Text(
                isMuted ? 'Unmute chat' : 'Mute chat',
                style: TextStyle(color: modernTheme.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleMuteChat(chatItem.chat.chatId, currentUserId);
              },
            ),
            
            ListTile(
              leading: const Icon(
                Icons.archive,
                color: Colors.orange,
              ),
              title: const Text(
                'Archive chat',
                style: TextStyle(color: Colors.orange),
              ),
              onTap: () {
                Navigator.pop(context);
                _archiveChat(chatItem.chat.chatId, currentUserId);
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.clear_all,
                color: Colors.blue,
              ),
              title: const Text(
                'Clear chat history',
                style: TextStyle(color: Colors.blue),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmClearChatHistory(chatItem.chat.chatId, currentUserId, chatItem.contactName);
              },
            ),
            
            ListTile(
              leading: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              title: const Text(
                'Delete chat',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteChat(chatItem.chat.chatId, currentUserId, chatItem.contactName);
              },
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePinChat(String chatId, String userId) async {
    try {
      final chatListNotifier = ref.read(chatListProvider.notifier);
      await chatListNotifier.togglePinChat(chatId, userId);
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to pin/unpin chat');
      }
    }
  }

  Future<void> _toggleMuteChat(String chatId, String userId) async {
    try {
      final chatListNotifier = ref.read(chatListProvider.notifier);
      await chatListNotifier.toggleMuteChat(chatId, userId);
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to mute/unmute chat');
      }
    }
  }

  Future<void> _archiveChat(String chatId, String userId) async {
    try {
      final chatListNotifier = ref.read(chatListProvider.notifier);
      await chatListNotifier.toggleArchiveChat(chatId, userId);
      
      if (mounted) {
        showSnackBar(context, 'Chat archived');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to archive chat');
      }
    }
  }

  void _confirmDeleteChat(String chatId, String userId, String contactName) {
    final modernTheme = context.modernTheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: modernTheme.surfaceColor,
        title: Text(
          'Delete Chat?',
          style: TextStyle(color: modernTheme.textColor),
        ),
        content: Text(
          'Are you sure you want to delete this chat with $contactName? This action cannot be undone.',
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
              _deleteChat(chatId, userId, false);
            },
            child: const Text(
              'Delete for me',
              style: TextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteForEveryone(chatId, userId, contactName);
            },
            child: const Text(
              'Delete for everyone',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteForEveryone(String chatId, String userId, String contactName) {
    final modernTheme = context.modernTheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: modernTheme.surfaceColor,
        title: Text(
          'Delete for Everyone?',
          style: TextStyle(color: modernTheme.textColor),
        ),
        content: Text(
          'This will delete the entire chat with $contactName for both participants. This action cannot be undone.',
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
              _deleteChat(chatId, userId, true);
            },
            child: const Text(
              'Delete for Everyone',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearChatHistory(String chatId, String userId, String contactName) {
    final modernTheme = context.modernTheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: modernTheme.surfaceColor,
        title: Text(
          'Clear Chat History?',
          style: TextStyle(color: modernTheme.textColor),
        ),
        content: Text(
          'Are you sure you want to clear all messages in this chat with $contactName? This action cannot be undone.',
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
              _clearChatHistory(chatId, userId);
            },
            child: Text(
              'Clear',
              style: TextStyle(color: modernTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChat(String chatId, String userId, bool deleteForEveryone) async {
    try {
      final chatListNotifier = ref.read(chatListProvider.notifier);
      await chatListNotifier.deleteChat(chatId, userId, deleteForEveryone: deleteForEveryone);
      
      if (mounted) {
        showSnackBar(
          context, 
          deleteForEveryone ? 'Chat deleted for everyone' : 'Chat deleted'
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to delete chat');
      }
    }
  }

  Future<void> _clearChatHistory(String chatId, String userId) async {
    try {
      final chatListNotifier = ref.read(chatListProvider.notifier);
      await chatListNotifier.clearChatHistory(chatId, userId);
      
      if (mounted) {
        showSnackBar(context, 'Chat history cleared');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to clear chat history');
      }
    }
  }

  void _navigateToContacts() {
    Navigator.pushNamed(context, Constants.contactsScreen);
  }

  @override
  void dispose() {
    // Clean up any temporary cache if needed
    super.dispose();
  }
}
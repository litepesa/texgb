// lib/features/video_reactions/screens/video_reactions_list_screen.dart
// COPIED: Same UI as chat list but for video reactions
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/video_reactions/models/video_reaction_chat_model.dart';
import 'package:textgb/features/video_reactions/providers/video_reactions_provider.dart';
import 'package:textgb/features/video_reactions/screens/video_reaction_chat_screen.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/features/users/models/user_model.dart';

class VideoReactionsListScreen extends ConsumerStatefulWidget {
  const VideoReactionsListScreen({super.key});

  @override
  ConsumerState<VideoReactionsListScreen> createState() => _VideoReactionsListScreenState();
}

class _VideoReactionsListScreenState extends ConsumerState<VideoReactionsListScreen> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  // Cache manager for profile images
  static final DefaultCacheManager _imageCacheManager = DefaultCacheManager();
  
  // In-memory cache for current session
  List<VideoReactionChatModel>? _cachedChats;
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
      debugPrint('Error loading cached video reaction chat data: $e');
    }
  }

  // Get cached chat list from cache manager (simplified)
  Future<List<VideoReactionChatModel>?> _getCachedChatList() async {
    return _cachedChats;
  }

  // Cache chat list data (simplified)
  Future<void> _cacheChatList(List<VideoReactionChatModel> chats) async {
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
        showSnackBar(context, 'Video reaction chat cache cleared');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to clear cache');
      }
    }
  }

  // Preload contact images for better performance
  Future<void> _preloadContactImages(List<VideoReactionChatModel> chats) async {
    final imagesToPreload = chats
        .where((chat) => chat.originalReaction.userImage.isNotEmpty)
        .map((chat) => chat.originalReaction.userImage)
        .take(10)
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
    
    // User is authenticated, show the video reaction chat list
    return _buildAuthenticatedChatList(currentUser, modernTheme);
  }

  Widget _buildAuthenticatedChatList(UserModel user, ModernThemeExtension modernTheme) {
    final chatListState = ref.watch(videoReactionChatsListProvider);
    
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  modernTheme.primaryColor ?? Theme.of(context).primaryColor,
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
                        child: _buildChatListFromCache(_cachedChats!, modernTheme, user.uid),
                      ),
                    ],
                  );
                }
                return _buildLoadingState(modernTheme);
              },
              error: (error, stack) {
                debugPrint('Video reaction chat list error: $error');
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
                              onPressed: () => ref.refresh(videoReactionChatsListProvider),
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
                        child: _buildChatListFromCache(_cachedChats!, modernTheme, user.uid),
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
    );
  }

  Widget _buildSearchBar(ModernThemeExtension modernTheme) {
    final chatListNotifier = ref.read(videoReactionChatsListProvider.notifier);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: (modernTheme.dividerColor ?? Colors.grey).withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: TextField(
        style: TextStyle(color: modernTheme.textColor),
        decoration: InputDecoration(
          hintText: 'Search video reactions...',
          hintStyle: TextStyle(color: modernTheme.textSecondaryColor),
          prefixIcon: Icon(
            Icons.search,
            color: modernTheme.textSecondaryColor,
            size: 20,
          ),
          filled: true,
          fillColor: (modernTheme.backgroundColor ?? Colors.grey.shade100).withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (query) => chatListNotifier.setSearchQuery(query),
      ),
    );
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
                color: (modernTheme.primaryColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 64,
                color: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Please log in to view video reactions',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to start reacting to videos and messaging users',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                Constants.landingScreen,
                (route) => false,
              ),
              icon: const Icon(
                Icons.login,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                'Sign In',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
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
          shape: BoxShape.circle,
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
            child: Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Failed to load video reactions',
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
              'Unable to connect to video reaction service. Please check your internet connection.',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => ref.refresh(videoReactionChatsListProvider),
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            label: const Text(
              'Try Again',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatListFromCache(List<VideoReactionChatModel> chats, ModernThemeExtension modernTheme, String currentUserId) {
    if (chats.isEmpty) {
      return _buildEmptyState(modernTheme);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chatItem = chats[index];
        return _buildChatItem(chatItem, currentUserId, modernTheme);
      },
    );
  }

  Widget _buildChatList(VideoReactionChatsState state, String currentUserId, ModernThemeExtension modernTheme) {
    if (state.chats.isEmpty && state.searchQuery.isEmpty) {
      return _buildEmptyState(modernTheme);
    }

    final filteredChats = state.filteredChats;
    
    if (filteredChats.isEmpty && state.searchQuery.isNotEmpty) {
      return _buildNoSearchResultsState(modernTheme, state.searchQuery);
    }

    // Get pinned and regular chats
    final chatListNotifier = ref.read(videoReactionChatsListProvider.notifier);
    final pinnedChats = chatListNotifier.getPinnedChats();
    final regularChats = chatListNotifier.getRegularChats();

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(videoReactionChatsListProvider);
      },
      color: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
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
          color: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
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
              color: (modernTheme.primaryColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.play_rectangle,
              size: 64,
              color: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No video reactions yet',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start reacting to videos to begin\nconversations with other users',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 16,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _navigateToVideos(),
            icon: const Icon(
              CupertinoIcons.play_circle,
              color: Colors.white,
              size: 20,
            ),
            label: const Text(
              'Explore Videos',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
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
            'No video reactions found',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No video reactions match "$query"',
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
    VideoReactionChatModel chatItem, 
    String currentUserId, 
    ModernThemeExtension modernTheme,
    {bool isPinned = false}
  ) {
    final unreadCount = chatItem.getUnreadCount(currentUserId);
    final hasUnread = unreadCount > 0;
    final isMuted = chatItem.isMutedForUser(currentUserId);
    
    // Get the other participant's name from the original reaction
    final contactName = chatItem.originalReaction.userName;
    final contactImage = chatItem.originalReaction.userImage;
    
    return Dismissible(
      key: ValueKey(chatItem.chatId),
      background: _buildDismissBackground(modernTheme, isLeftSwipe: false),
      secondaryBackground: _buildDismissBackground(modernTheme, isLeftSwipe: true),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Archive chat
          await _archiveChat(chatItem.chatId);
          return false;
        } else {
          // Pin/unpin chat
          await _togglePinChat(chatItem.chatId);
          return false;
        }
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Stack(
          children: [
            _buildCachedAvatar(contactName, contactImage, modernTheme),
            // Note: Video reactions don't need online status since they're based on videos
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                contactName,
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Show video reaction indicator
            Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (modernTheme.primaryColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.videocam_rounded,
                    size: 10,
                    color: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Video',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isPinned) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.push_pin,
                size: 14,
                color: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
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
            if (chatItem.lastMessageSender == currentUserId) ...[
              Icon(
                Icons.done_all,
                size: 14,
                color: modernTheme.textSecondaryColor,
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                _getLastMessagePreview(chatItem, currentUserId),
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
              _getDisplayTime(chatItem.lastMessageTime),
              style: TextStyle(
                color: hasUnread 
                  ? (modernTheme.primaryColor ?? Theme.of(context).primaryColor)
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
                    : (modernTheme.primaryColor ?? Theme.of(context).primaryColor),
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
        onLongPress: () => _showChatOptions(chatItem),
      ),
    );
  }

  Widget _buildCachedAvatar(String contactName, String contactImage, ModernThemeExtension modernTheme) {
    if (contactImage.isEmpty) {
      return CircleAvatar(
        radius: 25,
        backgroundColor: (modernTheme.primaryColor ?? Theme.of(context).primaryColor).withOpacity(0.2),
        child: Text(
          _getAvatarInitials(contactName),
          style: TextStyle(
            color: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: contactImage,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: 25,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: 25,
        backgroundColor: (modernTheme.primaryColor ?? Theme.of(context).primaryColor).withOpacity(0.2),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              modernTheme.primaryColor ?? Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: 25,
        backgroundColor: (modernTheme.primaryColor ?? Theme.of(context).primaryColor).withOpacity(0.2),
        child: Text(
          _getAvatarInitials(contactName),
          style: TextStyle(
            color: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
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
      color: isLeftSwipe 
          ? Colors.red.withOpacity(0.8) 
          : (modernTheme.primaryColor ?? Theme.of(context).primaryColor),
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

  String _getLastMessagePreview(VideoReactionChatModel chatItem, String currentUserId) {
    // For video reaction chats, show either the reaction or last message
    if (chatItem.lastMessage.isEmpty && chatItem.originalReaction.hasReaction) {
      return 'Reacted: ${chatItem.originalReaction.reaction!}';
    }
    return chatItem.lastMessage.isNotEmpty ? chatItem.lastMessage : 'Video reaction';
  }

  String _getDisplayTime(DateTime messageTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(messageTime.year, messageTime.month, messageTime.day);
    
    if (messageDate == today) {
      return DateFormat('HH:mm').format(messageTime);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(messageTime).inDays < 7) {
      return DateFormat('EEE').format(messageTime);
    } else {
      return DateFormat('MM/dd').format(messageTime);
    }
  }

  void _openChat(VideoReactionChatModel chatItem) async {
    // Mark chat as read when opening
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final chatListNotifier = ref.read(videoReactionChatsListProvider.notifier);
    await chatListNotifier.markChatAsRead(chatItem.chatId);

    // Get the other participant's user ID
    final otherUserId = chatItem.getOtherParticipant(currentUser.uid);

    // Get full user data from authentication provider
    final authNotifier = ref.read(authenticationProvider.notifier);
    UserModel? contactUser;
    
    try {
      contactUser = await authNotifier.getUserById(otherUserId);
    } catch (e) {
      debugPrint('Error fetching contact user data: $e');
    }

    // Create UserModel with available data (fallback to chat item data if user not found)
    final contact = contactUser ?? UserModel(
      uid: otherUserId,
      phoneNumber: '', // Video reactions don't need phone numbers
      name: chatItem.originalReaction.userName,
      bio: '',
      profileImage: chatItem.originalReaction.userImage,
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

    // Navigate to video reaction chat screen
    if (mounted) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoReactionChatScreen(
            chatId: chatItem.chatId,
            contact: contact,
          ),
        ),
      );

      // Refresh chat list if message was sent
      if (result == true) {
        ref.refresh(videoReactionChatsListProvider);
      }
    }
  }

  void _showChatOptions(VideoReactionChatModel chatItem) {
    final modernTheme = context.modernTheme;
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final isPinned = chatItem.isPinnedForUser(currentUser.uid);
    final isMuted = chatItem.isMutedForUser(currentUser.uid);
    
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
              leading: _buildCachedAvatar(
                chatItem.originalReaction.userName, 
                chatItem.originalReaction.userImage, 
                modernTheme,
              ),
              title: Text(
                chatItem.originalReaction.userName,
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                'Video reaction chat',
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontSize: 14,
                ),
              ),
            ),
            
            const Divider(height: 1),
            
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
                _togglePinChat(chatItem.chatId);
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
                _toggleMuteChat(chatItem.chatId);
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
                _archiveChat(chatItem.chatId);
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
                _confirmClearChatHistory(chatItem.chatId, chatItem.originalReaction.userName);
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
                _confirmDeleteChat(chatItem.chatId, chatItem.originalReaction.userName);
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
      final chatListNotifier = ref.read(videoReactionChatsListProvider.notifier);
      await chatListNotifier.togglePinChat(chatId);
      
      if (mounted) {
        showSnackBar(context, 'Video reaction chat pin status updated');
      }
    } catch (e) {
      debugPrint('Error toggling pin chat: $e');
      if (mounted) {
        showSnackBar(context, 'Failed to pin/unpin chat');
      }
    }
  }

  Future<void> _toggleMuteChat(String chatId) async {
    try {
      final chatListNotifier = ref.read(videoReactionChatsListProvider.notifier);
      await chatListNotifier.toggleMuteChat(chatId);
      
      if (mounted) {
        showSnackBar(context, 'Video reaction chat mute status updated');
      }
    } catch (e) {
      debugPrint('Error toggling mute chat: $e');
      if (mounted) {
        showSnackBar(context, 'Failed to mute/unmute chat');
      }
    }
  }

  Future<void> _archiveChat(String chatId) async {
    try {
      final chatListNotifier = ref.read(videoReactionChatsListProvider.notifier);
      await chatListNotifier.toggleArchiveChat(chatId);
      
      if (mounted) {
        showSnackBar(context, 'Video reaction chat archived');
      }
    } catch (e) {
      debugPrint('Error archiving chat: $e');
      if (mounted) {
        showSnackBar(context, 'Failed to archive chat');
      }
    }
  }

  void _confirmDeleteChat(String chatId, String contactName) {
    final modernTheme = context.modernTheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: modernTheme.surfaceColor,
        title: Text(
          'Delete Video Reaction Chat?',
          style: TextStyle(color: modernTheme.textColor),
        ),
        content: Text(
          'Are you sure you want to delete this video reaction chat with $contactName? This action cannot be undone.',
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
              _deleteChat(chatId, false);
            },
            child: const Text(
              'Delete for me',
              style: TextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteForEveryone(chatId, contactName);
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

  void _confirmDeleteForEveryone(String chatId, String contactName) {
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
          'This will delete the entire video reaction chat with $contactName for both participants. This action cannot be undone.',
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
              _deleteChat(chatId, true);
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

  void _confirmClearChatHistory(String chatId, String contactName) {
    final modernTheme = context.modernTheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: modernTheme.surfaceColor,
        title: Text(
          'Clear Video Reaction Chat History?',
          style: TextStyle(color: modernTheme.textColor),
        ),
        content: Text(
          'Are you sure you want to clear all messages in this video reaction chat with $contactName? This action cannot be undone.',
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
              _clearChatHistory(chatId);
            },
            child: Text(
              'Clear',
              style: TextStyle(color: modernTheme.primaryColor ?? Theme.of(context).primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChat(String chatId, bool deleteForEveryone) async {
    try {
      final chatListNotifier = ref.read(videoReactionChatsListProvider.notifier);
      await chatListNotifier.deleteChat(chatId, deleteForEveryone: deleteForEveryone);
      
      if (mounted) {
        showSnackBar(
          context, 
          deleteForEveryone ? 'Video reaction chat deleted for everyone' : 'Video reaction chat deleted'
        );
      }
    } catch (e) {
      debugPrint('Error deleting video reaction chat: $e');
      if (mounted) {
        showSnackBar(context, 'Failed to delete video reaction chat');
      }
    }
  }

  Future<void> _clearChatHistory(String chatId) async {
    try {
      final chatListNotifier = ref.read(videoReactionChatsListProvider.notifier);
      await chatListNotifier.clearChatHistory(chatId);
      
      if (mounted) {
        showSnackBar(context, 'Video reaction chat history cleared');
      }
    } catch (e) {
      debugPrint('Error clearing video reaction chat history: $e');
      if (mounted) {
        showSnackBar(context, 'Failed to clear video reaction chat history');
      }
    }
  }

  void _navigateToVideos() {
    // Navigate to videos tab/screen to explore content
    Navigator.pushNamedAndRemoveUntil(
      context,
      Constants.homeScreen,
      (route) => false,
    );
  }

  @override
  void dispose() {
    // Clean up any temporary cache if needed
    super.dispose();
  }
}
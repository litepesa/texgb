// lib/features/chat/screens/chat_list_screen.dart
// FIXED: Proper type handling for cached user data and null safety
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/chat/database/chat_database_helper.dart';
import 'package:textgb/features/chat/models/chat_list_item_model.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/chat/screens/chat_screen.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/utilities/datetime_helper.dart';
import 'package:textgb/features/users/models/user_model.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> 
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh chat list when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(chatListProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final modernTheme = context.modernTheme;
    
    final currentUser = ref.watch(currentUserProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    
    if (!isAuthenticated || currentUser == null) {
      return _buildNotAuthenticatedState(modernTheme);
    }
    
    return _buildAuthenticatedChatList(currentUser, modernTheme);
  }

  Widget _buildAuthenticatedChatList(UserModel user, ModernThemeExtension modernTheme) {
    final chatListState = ref.watch(chatListProvider);
    
    return Scaffold(
      backgroundColor: modernTheme.surfaceColor,
      body: Column(
        children: [
          _buildSearchBar(modernTheme),
          
          // Show sync status if syncing
          chatListState.maybeWhen(
            data: (state) => state.isSyncing 
                ? _buildSyncingIndicator(modernTheme)
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
          
          Expanded(
            child: chatListState.when(
              loading: () => _buildLoadingState(modernTheme),
              error: (error, stack) {
                debugPrint('❌ Chat list error: $error');
                return _buildErrorState(modernTheme, error.toString());
              },
              data: (state) => _buildChatList(state, user.uid, modernTheme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ModernThemeExtension modernTheme) {
    final chatListNotifier = ref.read(chatListProvider.notifier);
    
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
          hintText: 'Search chats...',
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

  Widget _buildSyncingIndicator(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      color: (modernTheme.primaryColor ?? Colors.blue).withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                modernTheme.primaryColor ?? Colors.blue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Syncing...',
            style: TextStyle(
              color: modernTheme.primaryColor ?? Colors.blue,
              fontSize: 12,
            ),
          ),
        ],
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
              'Please log in to view chats',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to start messaging with other users',
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
              icon: const Icon(Icons.login, color: Colors.white, size: 20),
              label: const Text(
                'Sign In',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
            child: const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
              'Unable to load chat list. Please try again.',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(chatListProvider),
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            label: const Text(
              'Try Again',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 2,
            ),
          ),
        ],
      ),
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

    final pinnedChats = state.getPinnedChats(currentUserId);
    final regularChats = state.getRegularChats(currentUserId);

    return RefreshIndicator(
      onRefresh: () async {
        final chatListNotifier = ref.read(chatListProvider.notifier);
        await chatListNotifier.syncChats();
      },
      color: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: pinnedChats.length + regularChats.length + (pinnedChats.isNotEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          if (pinnedChats.isNotEmpty && index == 0) {
            return _buildSectionHeader('Pinned', modernTheme);
          }
          
          if (pinnedChats.isNotEmpty && index <= pinnedChats.length) {
            final chatIndex = index - 1;
            return _buildChatItem(
              pinnedChats[chatIndex], 
              currentUserId, 
              modernTheme,
              isPinned: true,
            );
          }
          
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
              CupertinoIcons.bubble_left_bubble_right,
              size: 64,
              color: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
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
            'Start a conversation by sharing videos\nor reacting to other users\' content',
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
            icon: const Icon(CupertinoIcons.play_circle, color: Colors.white, size: 20),
            label: const Text(
              'Explore Videos',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
          await _archiveChat(chatItem.chat.chatId);
          return false;
        } else {
          await _togglePinChat(chatItem.chat.chatId);
          return false;
        }
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Stack(
          children: [
            _buildAvatar(chatItem, modernTheme),
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
                      color: modernTheme.surfaceColor ?? Colors.white,
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
            if (chatItem.chat.lastMessageSender == currentUserId) ...[
              Icon(Icons.done_all, size: 14, color: modernTheme.textSecondaryColor),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                chatItem.getLastMessagePreview(currentUserId: currentUserId),
                style: TextStyle(
                  color: hasUnread ? modernTheme.textColor : modernTheme.textSecondaryColor,
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
              DateTimeHelper.formatChatListTime(chatItem.chat.lastMessageTime),
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

  Widget _buildAvatar(ChatListItemModel chatItem, ModernThemeExtension modernTheme) {
    if (chatItem.contactImage.isEmpty) {
      return CircleAvatar(
        radius: 25,
        backgroundColor: (modernTheme.primaryColor ?? Theme.of(context).primaryColor).withOpacity(0.2),
        child: Text(
          _getAvatarInitials(chatItem.contactName),
          style: TextStyle(
            color: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
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
          _getAvatarInitials(chatItem.contactName),
          style: TextStyle(
            color: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
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

  Future<List<ChatListItemModel>> _buildChatListItems(
      List<ChatModel> chats, String currentUserId) async {
    final authNotifier = ref.read(authenticationProvider.notifier);
    final chatItems = <ChatListItemModel>[];

    for (final chat in chats) {
      try {
        final otherUserId = chat.getOtherParticipant(currentUserId);
        
        // Try to get contact info from cache
        var contactData = await _getCachedUserDetails(otherUserId, chat.chatId);
        
        String contactName = 'Unknown User';
        String contactImage = '';
        String contactPhone = '';
        bool isOnline = false;
        DateTime? lastSeen;
        
        if (contactData != null) {
          // contactData is a Map<String, dynamic>
          contactName = contactData['name']?.toString() ?? 'Unknown User';
          contactImage = contactData['profileImage']?.toString() ?? '';
          contactPhone = contactData['phoneNumber']?.toString() ?? '';
          
          final lastSeenStr = contactData['lastSeen']?.toString();
          if (lastSeenStr != null) {
            isOnline = _isUserOnline(lastSeenStr);
            lastSeen = _parseLastSeen(lastSeenStr);
          }
        } else {
          // If not cached, fetch from server
          try {
            final userModel = await authNotifier.getUserById(otherUserId);
            
            if (userModel != null) {
              contactName = userModel.name;
              contactImage = userModel.profileImage;
              contactPhone = userModel.phoneNumber;
              isOnline = _isUserOnline(userModel.lastSeen);
              lastSeen = _parseLastSeen(userModel.lastSeen);
              
              // Cache for future use
              await _cacheUserDetails(chat.chatId, userModel);
            }
          } catch (e) {
            debugPrint('Error fetching user $otherUserId: $e');
          }
          
          // If still no data, try participant cache
          if (contactName == 'Unknown User') {
            final participants = await _dbHelper.getChatParticipants(chat.chatId);
            final participant = participants.firstWhere(
              (p) => p['userId'] == otherUserId,
              orElse: () => <String, dynamic>{},
            );
            
            if (participant.isNotEmpty) {
              contactName = participant['userName']?.toString() ?? 'Unknown User';
              contactImage = participant['userImage']?.toString() ?? '';
              contactPhone = participant['phoneNumber']?.toString() ?? '';
              isOnline = (participant['isOnline'] == 1);
              
              if (participant['lastSeen'] != null) {
                try {
                  lastSeen = DateTime.fromMillisecondsSinceEpoch(
                    participant['lastSeen'] as int
                  );
                } catch (e) {
                  debugPrint('Error parsing lastSeen: $e');
                }
              }
            }
          }
        }
        
        // Always add a chat item, even with default values
        chatItems.add(ChatListItemModel(
          chat: chat,
          contactName: contactName,
          contactImage: contactImage,
          contactPhone: contactPhone,
          isOnline: isOnline,
          lastSeen: lastSeen,
        ));
      } catch (e) {
        debugPrint('❌ Error building chat item: $e');
        
        // Add a fallback chat item to prevent UI from breaking
        chatItems.add(ChatListItemModel(
          chat: chat,
          contactName: 'Unknown User',
          contactImage: '',
          contactPhone: '',
          isOnline: false,
          lastSeen: null,
        ));
      }
    }

    // Sort by last message time (most recent first)
    chatItems.sort((a, b) => b.chat.lastMessageTime.compareTo(a.chat.lastMessageTime));

    return chatItems;
  }

  Future<dynamic> _getCachedUserDetails(String userId, String chatId) async {
    try {
      final participants = await _dbHelper.getChatParticipants(chatId);
      final participant = participants.firstWhere(
        (p) => p['userId'] == userId,
        orElse: () => <String, dynamic>{},
      );
      
      if (participant.isNotEmpty) {
        // Return a simple map that looks like user data
        return {
          'uid': userId,
          'name': participant['userName'],
          'profileImage': participant['userImage'] ?? '',
          'phoneNumber': participant['phoneNumber'] ?? '',
          'lastSeen': participant['lastSeen'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(participant['lastSeen']).toIso8601String()
              : DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      debugPrint('Error getting cached user details: $e');
    }
    return null;
  }

  Future<void> _cacheUserDetails(String chatId, dynamic user) async {
    try {
      await _dbHelper.insertOrUpdateParticipant(
        chatId: chatId,
        userId: user.uid,
        userName: user.name,
        userImage: user.profileImage,
        phoneNumber: user.phoneNumber,
        isOnline: _isUserOnline(user.lastSeen),
        lastSeen: user.lastSeen,
      );
    } catch (e) {
      debugPrint('Error caching user details: $e');
    }
  }

  bool _isUserOnline(String lastSeenString) {
    try {
      final lastSeen = DateTime.parse(lastSeenString);
      final now = DateTime.now();
      final difference = now.difference(lastSeen);
      return difference.inMinutes <= 5;
    } catch (e) {
      return false;
    }
  }

  DateTime? _parseLastSeen(String lastSeenString) {
    try {
      return DateTime.parse(lastSeenString);
    } catch (e) {
      return null;
    }
  }

  void _openChat(ChatListItemModel chatItem) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    // Mark as read IMMEDIATELY when opening
    final chatListNotifier = ref.read(chatListProvider.notifier);
    await chatListNotifier.markChatAsRead(chatItem.chat.chatId);

    final otherUserId = chatItem.chat.getOtherParticipant(currentUser.uid);
    final authNotifier = ref.read(authenticationProvider.notifier);
    UserModel? contactUser;
    
    try {
      contactUser = await authNotifier.getUserById(otherUserId);
    } catch (e) {
      debugPrint('❌ Error fetching contact user: $e');
    }

    final contact = contactUser ?? UserModel(
      uid: otherUserId,
      phoneNumber: chatItem.contactPhone,
      name: chatItem.contactName,
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

    if (mounted) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatItem.chat.chatId,
            contact: contact,
          ),
        ),
      );

      // Refresh provider when coming back
      if (result == true && mounted) {
        ref.invalidate(chatListProvider);
      }
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
            
            ListTile(
              leading: _buildAvatar(chatItem, modernTheme),
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
                isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                color: modernTheme.textColor,
              ),
              title: Text(
                isPinned ? 'Unpin chat' : 'Pin chat',
                style: TextStyle(color: modernTheme.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _togglePinChat(chatItem.chat.chatId);
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
                _toggleMuteChat(chatItem.chat.chatId);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.archive, color: Colors.orange),
              title: const Text('Archive chat', style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.pop(context);
                _archiveChat(chatItem.chat.chatId);
              },
            ),

            ListTile(
              leading: const Icon(Icons.clear_all, color: Colors.blue),
              title: const Text('Clear chat history', style: TextStyle(color: Colors.blue)),
              onTap: () {
                Navigator.pop(context);
                _confirmClearChatHistory(chatItem.chat.chatId, chatItem.contactName);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete chat', style: TextStyle(color: Colors.red)),
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
      await ref.read(chatListProvider.notifier).togglePinChat(chatId);
      if (mounted) showSnackBar(context, 'Chat pin status updated');
    } catch (e) {
      debugPrint('❌ Error toggling pin: $e');
      if (mounted) showSnackBar(context, 'Failed to pin/unpin chat');
    }
  }

  Future<void> _toggleMuteChat(String chatId) async {
    try {
      await ref.read(chatListProvider.notifier).toggleMuteChat(chatId);
      if (mounted) showSnackBar(context, 'Chat mute status updated');
    } catch (e) {
      debugPrint('❌ Error toggling mute: $e');
      if (mounted) showSnackBar(context, 'Failed to mute/unmute chat');
    }
  }

  Future<void> _archiveChat(String chatId) async {
    try {
      await ref.read(chatListProvider.notifier).toggleArchiveChat(chatId);
      if (mounted) showSnackBar(context, 'Chat archived');
    } catch (e) {
      debugPrint('❌ Error archiving chat: $e');
      if (mounted) showSnackBar(context, 'Failed to archive chat');
    }
  }

  void _confirmDeleteChat(String chatId, String contactName) {
    final modernTheme = context.modernTheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: modernTheme.surfaceColor,
        title: Text('Delete Chat?', style: TextStyle(color: modernTheme.textColor)),
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
      await ref.read(chatListProvider.notifier).deleteChat(chatId, deleteForEveryone: deleteForEveryone);
      if (mounted) {
        showSnackBar(
          context, 
          deleteForEveryone ? 'Chat deleted for everyone' : 'Chat deleted'
        );
      }
    } catch (e) {
      debugPrint('❌ Error deleting chat: $e');
      if (mounted) showSnackBar(context, 'Failed to delete chat');
    }
  }

  Future<void> _clearChatHistory(String chatId) async {
    try {
      await ref.read(chatListProvider.notifier).clearChatHistory(chatId);
      if (mounted) showSnackBar(context, 'Chat history cleared');
    } catch (e) {
      debugPrint('❌ Error clearing history: $e');
      if (mounted) showSnackBar(context, 'Failed to clear chat history');
    }
  }

  void _navigateToVideos() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      Constants.homeScreen,
      (route) => false,
    );
  }
  
  // Add missing _dbHelper reference
  final _dbHelper = ChatDatabaseHelper();
}
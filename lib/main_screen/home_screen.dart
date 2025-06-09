// lib/main_screen/home_screen.dart
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/screens/chats_tab.dart';
import 'package:textgb/features/groups/screens/groups_tab.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/groups/providers/group_provider.dart';
import 'package:textgb/features/channels/screens/channels_feed_screen.dart';
import 'package:textgb/features/channels/screens/create_post_screen.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/profile/screens/my_profile_screen.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/widgets/custom_icon_button.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _previousIndex = 0;
  final PageController _pageController = PageController();
  final GlobalKey _channelsFeedKey = GlobalKey();
  
  // Simple controller for channels feed
  bool _isChannelsFeedActive = false;
  
  // Helper method to pause channels feed
  void _pauseChannelsFeed() {
    if (_isChannelsFeedActive) {
      _isChannelsFeedActive = false;
      try {
        final dynamic state = _channelsFeedKey.currentState;
        state?.onScreenBecameInactive?.call();
      } catch (e) {
        debugPrint('Error pausing channels feed: $e');
      }
    }
  }
  
  // Helper method to resume channels feed
  void _resumeChannelsFeed() {
    if (!_isChannelsFeedActive) {
      _isChannelsFeedActive = true;
      try {
        final dynamic state = _channelsFeedKey.currentState;
        state?.onScreenBecameActive?.call();
      } catch (e) {
        debugPrint('Error resuming channels feed: $e');
      }
    }
  }
  
  final List<String> _tabNames = [
    'Chats',
    'Groups',
    'Discover',
    'Me'
  ];
  
  final List<IconData> _tabIcons = [
    CupertinoIcons.chat_bubble_text,
    CupertinoIcons.person_3,
    CupertinoIcons.compass,
    CupertinoIcons.person
  ];

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(channelsProvider.notifier).loadUserChannel();
      _updateSystemUI();
    });
  }

  @override
  void dispose() {
    // Ensure channels feed is properly cleaned up
    _pauseChannelsFeed();
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    // Store previous index for video lifecycle management
    _previousIndex = _currentIndex;
    
    setState(() {
      _currentIndex = index;
      _updateSystemUI(); // Force immediate update
    });

    // Handle channels feed video lifecycle based on tab changes
    _handleChannelsFeedLifecycle(index);

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  void _handleChannelsFeedLifecycle(int newIndex) {
    const channelsFeedIndex = 2; // Channels tab at index 2
    
    // Debug logging
    debugPrint('Tab changed from $_previousIndex to $newIndex');
    
    if (_previousIndex == channelsFeedIndex && newIndex != channelsFeedIndex) {
      // User left channels feed tab - pause all videos
      debugPrint('Pausing channels feed videos');
      _pauseChannelsFeed();
    } else if (_previousIndex != channelsFeedIndex && newIndex == channelsFeedIndex) {
      // User entered channels feed tab - resume videos
      debugPrint('Resuming channels feed videos');
      _resumeChannelsFeed();
    }
  }
  
  void _updateSystemUI() {
    final isChannelsTab = _currentIndex == 2; // Channels tab at index 2
    final isProfileTab = _currentIndex == 3; // Profile tab at index 3
    
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: isChannelsTab ? Colors.black : Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ));
  }
  
  void _onPageChanged(int index) {
    // Store previous index before updating
    _previousIndex = _currentIndex;
    
    setState(() {
      _currentIndex = index;
      _updateSystemUI();
    });
    
    // Handle video lifecycle for page changes too
    _handleChannelsFeedLifecycle(index);
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final chatsAsyncValue = ref.watch(chatStreamProvider);
    final groupsAsyncValue = ref.watch(userGroupsStreamProvider);
    final isChannelsTab = _currentIndex == 2; // Channels tab at index 2
    final isProfileTab = _currentIndex == 3; // Profile tab at index 3
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // Debug logging for groups
    groupsAsyncValue.whenData((groups) {
      final currentUser = ref.watch(currentUserProvider);
      if (currentUser != null) {
        final totalUnread = groups.fold<int>(0, (sum, group) => sum + group.getUnreadCountForUser(currentUser.uid));
        debugPrint('Groups unread count: $totalUnread');
        for (final group in groups) {
          debugPrint('Group ${group.groupName}: ${group.getUnreadCountForUser(currentUser.uid)} unread');
        }
      }
    });

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: isChannelsTab || isProfileTab,
      backgroundColor: isChannelsTab ? Colors.black : modernTheme.backgroundColor,
      
      // Hide AppBar for channels and profile tabs
      appBar: (isChannelsTab || isProfileTab) ? null : _buildAppBar(modernTheme, isDarkMode),
      
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: _onPageChanged,
        children: [
          // Chats tab (index 0)
          Container(
            color: modernTheme.backgroundColor,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: const ChatsTab(),
          ),
          // Groups tab (index 1)
          Container(
            color: modernTheme.surfaceColor,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: const GroupsTab(),
          ),
          // Channels feed (index 2)
          ChannelsFeedScreen(key: _channelsFeedKey),
          // Profile tab (index 3)
          Container(
            color: modernTheme.surfaceColor,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: const MyProfileScreen(),
          ),
        ],
      ),
      
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isChannelsTab ? Colors.black : modernTheme.surfaceColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 1,
              width: double.infinity,
              color: isChannelsTab ? Colors.grey[900] : modernTheme.dividerColor,
            ),
            SafeArea(
              top: false,
              bottom: false,
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: _onTabTapped,
                backgroundColor: Colors.transparent,
                selectedItemColor: modernTheme.primaryColor,
                unselectedItemColor: modernTheme.textSecondaryColor,
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                items: List.generate(
                  _tabNames.length,
                  (index) => _buildBottomNavItem(index, modernTheme, chatsAsyncValue, groupsAsyncValue),
                ),
              ),
            ),
          ],
        ),
      ),
      
      floatingActionButton: _shouldShowFab() ? _buildFab(modernTheme) : null,
    );
  }
  
  BottomNavigationBarItem _buildBottomNavItem(
    int index, 
    ModernThemeExtension modernTheme,
    AsyncValue<List<ChatModel>> chatsAsyncValue,
    AsyncValue<List<GroupModel>> groupsAsyncValue,
  ) {
    final isSelected = _currentIndex == index;
    
    // Chats tab is at index 0 - show unread count for direct chats only
    if (index == 0) {
      return chatsAsyncValue.when(
        data: (chats) {
          // Calculate unread count from direct chats only
          final directChats = chats.where((chat) => !chat.isGroup).toList();
          final chatUnreadCount = directChats.fold<int>(
            0, 
            (sum, chat) => sum + chat.getDisplayUnreadCount()
          );
          
          return _buildNavItemWithBadge(
            index, 
            isSelected, 
            modernTheme, 
            chatUnreadCount
          );
        },
        loading: () => _buildDefaultBottomNavItem(index, isSelected, modernTheme),
        error: (_, __) => _buildDefaultBottomNavItem(index, isSelected, modernTheme),
      );
    }
    
    // Groups tab is at index 1 - show unread count for groups
    if (index == 1) {
      return groupsAsyncValue.when(
        data: (groups) {
          final currentUser = ref.watch(currentUserProvider);
          
          final groupUnreadCount = currentUser != null 
              ? groups.fold<int>(
                  0, 
                  (sum, group) => sum + group.getUnreadCountForUser(currentUser.uid)
                )
              : 0;
          
          return _buildNavItemWithBadge(
            index, 
            isSelected, 
            modernTheme, 
            groupUnreadCount
          );
        },
        loading: () => _buildDefaultBottomNavItem(index, isSelected, modernTheme),
        error: (_, __) => _buildDefaultBottomNavItem(index, isSelected, modernTheme),
      );
    }
    
    return _buildDefaultBottomNavItem(index, isSelected, modernTheme);
  }
  
  BottomNavigationBarItem _buildNavItemWithBadge(
    int index,
    bool isSelected,
    ModernThemeExtension modernTheme,
    int unreadCount,
  ) {
    return BottomNavigationBarItem(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected 
                ? modernTheme.primaryColor!.withOpacity(0.2) 
                : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(_tabIcons[index]),
          ),
          if (unreadCount > 0)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: modernTheme.primaryColor,
                  shape: unreadCount > 99 
                      ? BoxShape.rectangle 
                      : BoxShape.circle,
                  borderRadius: unreadCount > 99 
                      ? BorderRadius.circular(10) 
                      : null,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      label: _tabNames[index],
    );
  }
  
  BottomNavigationBarItem _buildDefaultBottomNavItem(
    int index, 
    bool isSelected, 
    ModernThemeExtension modernTheme
  ) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected 
            ? modernTheme.primaryColor!.withOpacity(0.2) 
            : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(_tabIcons[index]),
      ),
      label: _tabNames[index],
    );
  }
  
  // Show FAB on Chats and Groups tabs
  bool _shouldShowFab() {
    return _currentIndex == 0 || _currentIndex == 1;
  }
  
  PreferredSizeWidget? _buildAppBar(ModernThemeExtension modernTheme, bool isDarkMode) {
    return AppBar(
      backgroundColor: modernTheme.backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: _buildAppBarTitle(modernTheme),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(
          height: 0.5,
          width: double.infinity,
          color: modernTheme.dividerColor,
        ),
      ),
    );
  }

  Widget _buildAppBarTitle(ModernThemeExtension modernTheme) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "Wei",
            style: TextStyle(
              color: modernTheme.textColor,          
              fontWeight: FontWeight.w500,
              fontSize: 22,
              letterSpacing: -0.3,
            ),
          ),
          TextSpan(
            text: "Bao",
            style: TextStyle(
              color: modernTheme.primaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 24,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFab(ModernThemeExtension modernTheme) {
    if (_currentIndex == 0) {
      // Chats tab - New chat FAB
      return FloatingActionButton(
        backgroundColor: modernTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => Navigator.pushNamed(context, Constants.contactsScreen),
        child: const Icon(CupertinoIcons.chat_bubble_text),
      );
    } else if (_currentIndex == 1) {
      // Groups tab - Create group FAB
      return FloatingActionButton(
        backgroundColor: modernTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => Navigator.pushNamed(context, Constants.createGroupScreen),
        child: const Icon(CupertinoIcons.person_3),
      );
    }
    
    return const SizedBox.shrink();
  }
}
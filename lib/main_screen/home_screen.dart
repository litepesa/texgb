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
import 'package:textgb/features/channels/screens/channels_feed_screen.dart';
import 'package:textgb/features/channels/screens/create_post_screen.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
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
  bool _isPageAnimating = false;
  final GlobalKey _channelsFeedKey = GlobalKey();
  
  // Professional channels feed lifecycle management
  bool _isChannelsFeedActive = false;
  
  // Professional method to pause channels feed using the original extension
  void _pauseChannelsFeed() {
    if (_isChannelsFeedActive) {
      _isChannelsFeedActive = false;
      final state = _channelsFeedKey.currentState;
      if (state != null) {
        // Call the lifecycle method directly since we know it exists
        (state as dynamic).onScreenBecameInactive();
      }
    }
  }
  
  // Professional method to resume channels feed using the original extension
  void _resumeChannelsFeed() {
    if (!_isChannelsFeedActive) {
      _isChannelsFeedActive = true;
      final state = _channelsFeedKey.currentState;
      if (state != null) {
        // Call the lifecycle method directly since we know it exists
        (state as dynamic).onScreenBecameActive();
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
    Icons.group_outlined,
    CupertinoIcons.compass,
    CupertinoIcons.person
  ];

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(channelsProvider.notifier).loadUserChannel();
      _updateSystemUI();
      // Initialize channels feed as inactive since we start on Chats tab
      _isChannelsFeedActive = false;
    });
  }

  @override
  void dispose() {
    // Professional cleanup - ensure channels feed is properly paused before disposal
    if (_isChannelsFeedActive) {
      _pauseChannelsFeed();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    // Store previous index for video lifecycle management
    _previousIndex = _currentIndex;
    
    // Handle channels feed video lifecycle based on tab changes
    _handleChannelsFeedLifecycle(index);
    
    setState(() {
      _currentIndex = index;
      _updateSystemUI(); // Force immediate update
    });

    // Use jumpToPage to avoid showing intermediate pages
    _isPageAnimating = true;
    _pageController.jumpToPage(index);
    // Reset animation flag after a brief delay
    Future.delayed(const Duration(milliseconds: 50), () {
      _isPageAnimating = false;
    });
  }
  
  void _handleChannelsFeedLifecycle(int newIndex) {
    const channelsFeedIndex = 2; // Channels tab at index 2
    
    if (_previousIndex == channelsFeedIndex && newIndex != channelsFeedIndex) {
      // User left channels feed tab - pause all videos immediately
      _pauseChannelsFeed();
    } else if (_previousIndex != channelsFeedIndex && newIndex == channelsFeedIndex) {
      // User entered channels feed tab - resume videos immediately
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
    // Only process page changes that aren't from programmatic jumps
    if (_isPageAnimating) return;
    
    // Store previous index before updating
    _previousIndex = _currentIndex;
    
    setState(() {
      _currentIndex = index;
      _updateSystemUI();
    });
    
    // Handle video lifecycle for page changes too
    _handleChannelsFeedLifecycle(index);
  }

  // Helper method to get progress bar from channels feed screen
  Widget _buildProgressBarFromFeedScreen(BuildContext context) {
    final state = _channelsFeedKey.currentState;
    if (state == null) return const SizedBox.shrink();
    
    return (state as dynamic).buildEnhancedProgressBar(context.modernTheme);
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final chatsAsyncValue = ref.watch(chatStreamProvider);
    final isChannelsTab = _currentIndex == 2; // Channels tab at index 2
    final isProfileTab = _currentIndex == 3; // Profile tab at index 3
    final isGroupsTab = _currentIndex == 1; // Groups tab at index 1
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: isChannelsTab || isProfileTab,
      backgroundColor: isChannelsTab ? Colors.black : modernTheme.backgroundColor,
      
      // Hide AppBar for channels and profile tabs only
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
          // Groups tab (index 1) - Replaced Wallet tab
          Container(
            color: modernTheme.backgroundColor,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: const GroupsTab(),
          ),
          // Channels feed (index 2) - Always present but lifecycle managed
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
            // Add the progress bar here - only show for channels tab
            if (_currentIndex == 2) // Only show for channels tab
              Consumer(
                builder: (context, ref, _) {
                  final videosState = ref.watch(channelVideosProvider);
                  return videosState.videos.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildProgressBarFromFeedScreen(context),
                        )
                      : const SizedBox.shrink();
                },
              ),
            
            Container(
              height: 1,
              width: double.infinity,
              color: isChannelsTab ? Colors.grey[900] : modernTheme.dividerColor,
            ),
            SafeArea(
              top: false,
              bottom: false,
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: Colors.transparent,
                ),
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
                    (index) => _buildBottomNavItem(index, modernTheme, chatsAsyncValue),
                  ),
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
    
    // Groups tab is at index 1 - show unread count for group chats only
    if (index == 1) {
      return chatsAsyncValue.when(
        data: (chats) {
          // Calculate unread count from group chats only
          final groupChats = chats.where((chat) => chat.isGroup).toList();
          final groupUnreadCount = groupChats.fold<int>(
            0, 
            (sum, chat) => sum + chat.getDisplayUnreadCount()
          );
          
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
    
    // For other tabs (Discover, Me), no badge needed
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
      // Groups tab - Create group FAB (using the existing FAB from GroupsTab)
      return FloatingActionButton(
        backgroundColor: modernTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => Navigator.pushNamed(context, Constants.createGroupScreen),
        child: const Icon(Icons.group_add),
      );
    }
    
    return const SizedBox.shrink();
  }
}
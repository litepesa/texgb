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
import 'package:textgb/features/channels/screens/create_channel_post_screen.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/profile/screens/my_profile_screen.dart';
import 'package:textgb/features/status/screens/status_overview_screen.dart';
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
  
  // Tab switcher for Chats tab (between Chats and Status)
  int _chatsTabIndex = 0; // 0 = Chats, 1 = Status
  late AnimationController _tabSwitchController;
  late Animation<double> _tabSwitchAnimation;
  
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
    '',  // Empty for center button
    'Channels',
    'Profile'
  ];
  
  final List<IconData> _tabIcons = [
    CupertinoIcons.bubble_left,
    CupertinoIcons.bubble_left_bubble_right,
    Icons.add,
    CupertinoIcons.tv,
    CupertinoIcons.person
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize tab switch animation
    _tabSwitchController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _tabSwitchAnimation = CurvedAnimation(
      parent: _tabSwitchController,
      curve: Curves.easeInOut,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(channelsProvider.notifier).loadUserChannel();
      _updateSystemUI();
    });
  }

  @override
  void dispose() {
    // Ensure channels feed is properly cleaned up
    _pauseChannelsFeed();
    _tabSwitchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      final userChannel = ref.read(channelsProvider).userChannel;
      
      if (userChannel == null) {
        Navigator.of(context).pushNamed(Constants.createChannelScreen);
      } else {
        Navigator.of(context).pushNamed(Constants.createChannelPostScreen);
      }
      return;
    }
    
    // Store previous index for video lifecycle management
    _previousIndex = _currentIndex;
    
    setState(() {
      _currentIndex = index;
      _updateSystemUI(); // Force immediate update
    });

    // Handle channels feed video lifecycle based on tab changes
    _handleChannelsFeedLifecycle(index);

    int pageIndex = index > 2 ? index - 1 : index;
    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  void _handleChannelsFeedLifecycle(int newIndex) {
    const channelsFeedIndex = 3; // Channels tab moved to index 3
    
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
    final isChannelsTab = _currentIndex == 3; // Channels tab now at index 3
    final isProfileTab = _currentIndex == 4; // Profile tab at index 4
    
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: isChannelsTab ? Colors.black : Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ));
  }
  
  void _onPageChanged(int index) {
    int tabIndex = index >= 2 ? index + 1 : index;
    
    // Store previous index before updating
    _previousIndex = _currentIndex;
    
    setState(() {
      _currentIndex = tabIndex;
      _updateSystemUI();
    });
    
    // Handle video lifecycle for page changes too
    _handleChannelsFeedLifecycle(tabIndex);
  }

  void _onChatTabSwitched(int index) {
    setState(() {
      _chatsTabIndex = index;
    });
    
    if (index == 1) {
      // Animate to status tab
      _tabSwitchController.forward();
    } else {
      // Animate to chats tab
      _tabSwitchController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final chatsAsyncValue = ref.watch(chatStreamProvider);
    final isChannelsTab = _currentIndex == 3; // Channels tab at index 3
    final isProfileTab = _currentIndex == 4; // Profile tab at index 4
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
          // Chats tab with status switcher (index 0)
          Container(
            color: modernTheme.surfaceColor,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: _buildChatsTabContent(),
          ),
          // Groups tab (index 1)
          Container(
            color: modernTheme.surfaceColor,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: const GroupsTab(),
          ),
          // Channels feed (index 2 -> page index 2)
          ChannelsFeedScreen(key: _channelsFeedKey),
          // Profile tab (index 3 -> page index 3)
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
            Divider(
              height: 1,
              thickness: 0.5,
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
                  (index) => _buildBottomNavItem(index, modernTheme, chatsAsyncValue),
                ),
              ),
            ),
          ],
        ),
      ),
      
      floatingActionButton: _shouldShowFab() ? _buildFab(modernTheme) : null,
    );
  }

  Widget _buildChatsTabContent() {
    return AnimatedBuilder(
      animation: _tabSwitchAnimation,
      builder: (context, child) {
        return IndexedStack(
          index: _chatsTabIndex,
          children: const [
            ChatsTab(),
            StatusOverviewScreen(),
          ],
        );
      },
    );
  }
  
  BottomNavigationBarItem _buildBottomNavItem(
    int index, 
    ModernThemeExtension modernTheme,
    AsyncValue<List<ChatModel>> chatsAsyncValue,
  ) {
    final isSelected = _currentIndex == index;
    
    if (index == 2) {
      return BottomNavigationBarItem(
        icon: SizedBox(
          height: 48,
          child: Center(child: CustomIconButton()),
        ),
        label: '',
      );
    }
    
    // Chats tab is at index 0
    if (index == 0) {
      return chatsAsyncValue.when(
        data: (chats) {
          final directChats = chats.where((chat) => !chat.isGroup).toList();
          final totalUnreadCount = directChats.fold<int>(
            0, 
            (sum, chat) => sum + chat.getDisplayUnreadCount()
          );
          
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
                if (totalUnreadCount > 0)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: modernTheme.primaryColor,
                        shape: totalUnreadCount > 99 
                            ? BoxShape.rectangle 
                            : BoxShape.circle,
                        borderRadius: totalUnreadCount > 99 
                            ? BorderRadius.circular(10) 
                            : null,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          totalUnreadCount > 99 ? '99+' : totalUnreadCount.toString(),
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
        },
        loading: () => _buildDefaultBottomNavItem(index, isSelected, modernTheme),
        error: (_, __) => _buildDefaultBottomNavItem(index, isSelected, modernTheme),
      );
    }
    
    return _buildDefaultBottomNavItem(index, isSelected, modernTheme);
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
  
  // Updated to show different FABs based on current tab and status tab selection
  bool _shouldShowFab() {
    // Show FAB on Chats tab (including status sub-tab) and Groups tab
    return _currentIndex == 0 || _currentIndex == 1;
  }
  
  PreferredSizeWidget? _buildAppBar(ModernThemeExtension modernTheme, bool isDarkMode) {
    final isChatsTab = _currentIndex == 0;
    final isGroupsTab = _currentIndex == 1;
    
    return AppBar(
      elevation: 0,
      backgroundColor: modernTheme.backgroundColor,
      centerTitle: !isChatsTab, // Only Chats tab has custom layout
      title: isChatsTab 
          ? _buildChatsAppBarTitle(modernTheme)
          : _buildDefaultAppBarTitle(modernTheme),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Divider(
          height: 1,
          thickness: 0.5,
          color: modernTheme.dividerColor,
        ),
      ),
    );
  }

  Widget _buildDefaultAppBarTitle(ModernThemeExtension modernTheme) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "Wei",
            style: TextStyle(
              color: modernTheme.textColor,          
              fontWeight: FontWeight.w500,
              fontSize: 22,
            ),
          ),
          TextSpan(
            text: "Bao",
            style: TextStyle(
              color: modernTheme.primaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatsAppBarTitle(ModernThemeExtension modernTheme) {
    return Container(
      height: 50,
      child: Row(
        children: [
          // App title with enhanced styling
          Expanded(
            child: Container(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Wei",
                      style: TextStyle(
                        color: modernTheme.textColor,          
                        fontWeight: FontWeight.w500,
                        fontSize: 22,
                        letterSpacing: 0.5,
                      ),
                    ),
                    TextSpan(
                      text: "Bao",
                      style: TextStyle(
                        color: modernTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Enhanced tab switcher with glassmorphism effect
          Container(
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  modernTheme.surfaceColor!.withOpacity(0.9),
                  modernTheme.surfaceColor!.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: modernTheme.primaryColor!.withOpacity(0.2),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: modernTheme.primaryColor!.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTabSwitchButton(
                        'Chats',
                        CupertinoIcons.bubble_left_fill,
                        0,
                        modernTheme,
                      ),
                      _buildTabSwitchButton(
                        'Status',
                        CupertinoIcons.camera_fill,
                        1,
                        modernTheme,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitchButton(
    String label,
    IconData icon,
    int index,
    ModernThemeExtension modernTheme,
  ) {
    final isSelected = _chatsTabIndex == index;
    
    return GestureDetector(
      onTap: () => _onChatTabSwitched(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? LinearGradient(
                  colors: [
                    modernTheme.primaryColor!,
                    modernTheme.primaryColor!.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: modernTheme.primaryColor!.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: modernTheme.primaryColor!.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                size: 16,
                color: isSelected 
                    ? Colors.white 
                    : modernTheme.textSecondaryColor!.withOpacity(0.8),
              ),
            ),
            const SizedBox(width: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected 
                    ? Colors.white 
                    : modernTheme.textSecondaryColor!.withOpacity(0.8),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.8,
                shadows: isSelected
                    ? [
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFab(ModernThemeExtension modernTheme) {
    // Different FAB based on current context
    if (_currentIndex == 0) {
      // Chats tab - different FAB for Chats vs Status
      if (_chatsTabIndex == 0) {
        // Chats sub-tab - New chat FAB
        return FloatingActionButton(
          backgroundColor: modernTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          onPressed: () => Navigator.pushNamed(context, Constants.contactsScreen),
          child: const Icon(CupertinoIcons.bubble_left),
        );
      } else {
        // Status sub-tab - Create status FAB
        return FloatingActionButton(
          backgroundColor: modernTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          onPressed: () => Navigator.pushNamed(context, Constants.createStatusScreen),
          child: const Icon(CupertinoIcons.camera),
        );
      }
    } else if (_currentIndex == 1) {
      // Groups tab - Create group FAB
      return FloatingActionButton(
        backgroundColor: modernTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => Navigator.pushNamed(context, Constants.createGroupScreen),
        child: const Icon(CupertinoIcons.bubble_left_bubble_right),
      );
    }
    
    return const SizedBox.shrink();
  }
}
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
import 'package:textgb/features/status/screens/status_overview_screen.dart';
import 'package:textgb/features/channels/screens/channels_feed_screen.dart';
import 'package:textgb/features/channels/screens/create_post_screen.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/profile/screens/my_profile_screen.dart';
import 'package:textgb/features/wallet/screens/wallet_screen.dart';
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
  
  // Chat tab controllers
  int _chatTabIndex = 0; // 0: Chats, 1: Groups, 2: Status
  late TabController _chatTabController;
  final PageController _chatPageController = PageController();
  
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
    'Wallet',
    '',  // Empty for center button
    'Channels',
    'Profile'
  ];
  
  final List<IconData> _tabIcons = [
    CupertinoIcons.bubble_left,
    CupertinoIcons.creditcard,
    Icons.add,
    CupertinoIcons.tv,
    CupertinoIcons.person
  ];

  final List<String> _chatTabNames = ['Chats', 'Groups', 'Status'];
  final List<IconData> _chatTabIcons = [
    CupertinoIcons.bubble_left,
    CupertinoIcons.group,
    CupertinoIcons.photo_on_rectangle
  ];

  @override
  void initState() {
    super.initState();
    _chatTabController = TabController(length: 3, vsync: this);
    
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
    _chatTabController.dispose();
    _chatPageController.dispose();
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

  void _onChatTabChanged(int index) {
    setState(() {
      _chatTabIndex = index;
    });
    
    _chatPageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    _chatTabController.animateTo(index);
  }

  void _onChatPageChanged(int index) {
    setState(() {
      _chatTabIndex = index;
    });
    _chatTabController.animateTo(index);
  }
  
  void _handleChannelsFeedLifecycle(int newIndex) {
    const channelsFeedIndex = 3; // Channels tab at index 3
    
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
    final isChannelsTab = _currentIndex == 3; // Channels tab at index 3
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

  Widget _buildFloatingTabBar(ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: modernTheme.borderColor!.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: List.generate(_chatTabNames.length, (index) {
            final isSelected = _chatTabIndex == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => _onChatTabChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Center(
                    child: isSelected 
                        ? _buildSelectedTab(index, modernTheme)
                        : _buildUnselectedTab(index, modernTheme),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSelectedTab(int index, ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: modernTheme.primaryColor!.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _chatTabIcons[index],
            size: 16,
            color: modernTheme.primaryColor,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _chatTabNames[index],
              style: TextStyle(
                color: modernTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnselectedTab(int index, ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        _chatTabIcons[index],
        size: 18,
        color: modernTheme.textSecondaryColor,
      ),
    );
  }

  Widget _buildChatSection(ModernThemeExtension modernTheme) {
    return Column(
      children: [
        _buildFloatingTabBar(modernTheme),
        Expanded(
          child: PageView(
            controller: _chatPageController,
            onPageChanged: _onChatPageChanged,
            children: const [
              ChatsTab(),
              GroupsTab(),
              StatusOverviewScreen(),
            ],
          ),
        ),
      ],
    );
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
          // Chats section with floating tabbar (index 0)
          Container(
            color: modernTheme.backgroundColor,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: _buildChatSection(modernTheme),
          ),
          // Wallet tab (index 1)
          Container(
            color: modernTheme.surfaceColor,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: const WalletScreen(),
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
    
    // Chats tab is at index 0 - show unread count
    if (index == 0) {
      return chatsAsyncValue.when(
        data: (chats) {
          final directChats = chats.where((chat) => !chat.isGroup).toList();
          final totalUnreadCount = directChats.fold<int>(
            0, 
            (sum, chat) => sum + chat.getDisplayUnreadCount()
          );
          
          return _buildNavItemWithBadge(
            index, 
            isSelected, 
            modernTheme, 
            totalUnreadCount
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
  
  // Updated to show different FABs based on current tab and sub-tab
  bool _shouldShowFab() {
    // Show FAB on main tabs and chat sub-tabs
    return _currentIndex == 0 || _currentIndex == 1;
  }
  
  PreferredSizeWidget? _buildAppBar(ModernThemeExtension modernTheme, bool isDarkMode) {
    return AppBar(
      elevation: 0,
      backgroundColor: modernTheme.backgroundColor,
      centerTitle: true, // Center the app title
      title: _buildAppBarTitle(modernTheme),
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
  
  Widget _buildFab(ModernThemeExtension modernTheme) {
    if (_currentIndex == 0) {
      // Chat section - different FAB based on sub-tab
      switch (_chatTabIndex) {
        case 0: // Chats tab
          return FloatingActionButton(
            backgroundColor: modernTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 4,
            onPressed: () => Navigator.pushNamed(context, Constants.contactsScreen),
            child: const Icon(CupertinoIcons.bubble_left),
          );
        case 1: // Groups tab
          return FloatingActionButton(
            backgroundColor: modernTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 4,
            onPressed: () => Navigator.pushNamed(context, Constants.createGroupScreen),
            child: const Icon(CupertinoIcons.group_solid),
          );
        case 2: // Status tab
          return FloatingActionButton(
            backgroundColor: modernTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 4,
            onPressed: () => Navigator.pushNamed(context, Constants.createStatusScreen),
            child: const Icon(CupertinoIcons.camera),
          );
        default:
          return FloatingActionButton(
            backgroundColor: modernTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 4,
            onPressed: () => Navigator.pushNamed(context, Constants.contactsScreen),
            child: const Icon(CupertinoIcons.bubble_left),
          );
      }
    } else if (_currentIndex == 1) {
      // Wallet tab - Quick send money FAB
      return FloatingActionButton(
        backgroundColor: modernTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () {
          // Handle quick send money action
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quick Send Money feature coming soon!')),
          );
        },
        child: const Icon(CupertinoIcons.paperplane),
      );
    }
    
    return const SizedBox.shrink();
  }
}
// lib/main_screen/home_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/screens/chats_tab.dart';
import 'package:textgb/features/channels/screens/channels_feed_screen.dart';
import 'package:textgb/features/channels/screens/create_channel_post_screen.dart';
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

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  
  final List<String> _tabNames = [
    'Home',
    'Chats',
    '',  // Empty for center button
    'Wallet',
    'Profile'
  ];
  
  final List<IconData> _tabIcons = [
    CupertinoIcons.home,
    CupertinoIcons.chat_bubble_text,
    Icons.add,
    CupertinoIcons.creditcard,
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
    
    setState(() {
      _currentIndex = index;
      _updateSystemUI(); // Force immediate update
    });

    int pageIndex = index > 2 ? index - 1 : index;
    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  void _updateSystemUI() {
    final isHomeTab = _currentIndex == 0;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: isHomeTab ? Colors.black : Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ));
  }
  
  void _onPageChanged(int index) {
    int tabIndex = index >= 2 ? index + 1 : index;
    setState(() {
      _currentIndex = tabIndex;
      _updateSystemUI();
    });
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final chatsAsyncValue = ref.watch(chatStreamProvider);
    final isHomeTab = _currentIndex == 0;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: isHomeTab,
      backgroundColor: isHomeTab ? Colors.black : modernTheme.backgroundColor,
      
      appBar: isHomeTab ? null : _buildAppBar(modernTheme, isDarkMode),
      
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: _onPageChanged,
        children: [
          const ChannelsFeedScreen(),
          Container(
            color: modernTheme.surfaceColor,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: const ChatsTab(),
          ),
          Container(
            color: modernTheme.surfaceColor,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: _buildWalletTab(),
          ),
          Container(
            color: modernTheme.surfaceColor,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: const MyProfileScreen(),
          ),
        ],
      ),
      
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isHomeTab ? Colors.black : modernTheme.surfaceColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(
              height: 1,
              thickness: 0.5,
              color: isHomeTab ? Colors.grey[900] : modernTheme.dividerColor,
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
    
    if (index == 1) {
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
  
  bool _shouldShowFab() => _currentIndex == 1;
  
  PreferredSizeWidget? _buildAppBar(ModernThemeExtension modernTheme, bool isDarkMode) {
    return AppBar(
      elevation: 0,
      backgroundColor: modernTheme.backgroundColor,
      centerTitle: true,
      title: RichText(
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
      ),
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
  
  Widget _buildFab(ModernThemeExtension modernTheme) {
    return FloatingActionButton(
      backgroundColor: modernTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      onPressed: () => Navigator.pushNamed(context, Constants.contactsScreen),
      child: const Icon(CupertinoIcons.chat_bubble_text),
    );
  }
  
  Widget _buildWalletTab() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.creditcard,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Wallet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
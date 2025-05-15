import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/chat/screens/chats_tab.dart';
import 'package:textgb/features/marketplace/screens/marketplace_video_feed_screen.dart';
import 'package:textgb/features/profile/screens/my_profile_screen.dart';
import 'package:textgb/features/status/screens/status_overview_screen.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  
  // List of tab names
  final List<String> _tabNames = [
    'Chats',
    'Status',
    'Marketplace',
    'Profile'
  ];
  
  // List of tab icons
  final List<IconData> _tabIcons = [
    Icons.chat_bubble_rounded,
    Icons.photo_library_rounded,
    Icons.shopping_bag_rounded,
    Icons.person_rounded
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Animate to the selected page
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    // Ensure system UI is updated when page changes via tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSystemUI();
    });
  }

  @override
  void initState() {
    super.initState();
    // Ensure system navigation bar stays transparent
    _updateSystemUI();
  }
  
  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update system UI when widget updates
    _updateSystemUI();
  }
  
  // Method to ensure system navigation bar stays transparent
  void _updateSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ));
  }
  
  // Handle page changes
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Ensure system UI is updated when page changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSystemUI();
    });
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate bottom padding to account for system navigation
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // Update system UI when widget rebuilds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSystemUI();
    });
    
    return Scaffold(
      extendBody: true, // Important for the transparent navigation bar
      extendBodyBehindAppBar: _currentIndex == 2 || _currentIndex == 3, // Only extend content behind AppBar for tabs without AppBar
      backgroundColor: _currentIndex == 2 ? Colors.black : modernTheme.backgroundColor,
      
      // Custom AppBar
      appBar: _buildAppBar(modernTheme, isDarkMode),
      
      // PageView for tab content
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swiping between tabs
        onPageChanged: _onPageChanged, // Use the dedicated method
        children: [
          const ChatsTab(), // Use the real ChatsTab component
          const StatusOverviewScreen(), // Use our new StatusOverviewScreen 
          const MarketplaceVideoFeedScreen(), // Use the new marketplace implementation
          const MyProfileScreen(), // Use the existing profile screen
        ],
      ),
      
      // Regular Bottom Navigation Bar with divider
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Divider above bottom nav
          Divider(
            height: 1,
            thickness: 0.5,
            color: _currentIndex == 2 ? Colors.grey[900] : modernTheme.dividerColor,
          ),
          // Standard BottomNavigationBar with custom styling
          Container(
            decoration: BoxDecoration(
              color: _currentIndex == 2 ? Colors.black : modernTheme.surfaceColor,
            ),
            child: SafeArea(
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: _onTabTapped,
                backgroundColor: Colors.transparent, // Transparent to use the Container's color
                selectedItemColor: modernTheme.primaryColor,
                unselectedItemColor: modernTheme.textSecondaryColor,
                type: BottomNavigationBarType.fixed,
                elevation: 0, // No elevation on the BottomNavigationBar itself
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                items: List.generate(
                  _tabNames.length,
                  (index) {
                    bool isSelected = _currentIndex == index;
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
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      
      // FAB for new chat or content
      floatingActionButton: _currentIndex == 2 || _currentIndex == 3 ? null : _buildFab(modernTheme),
    );
  }
  
  PreferredSizeWidget? _buildAppBar(ModernThemeExtension modernTheme, bool isDarkMode) {
    // Hide AppBar for Marketplace and Profile tabs
    if (_currentIndex == 2 || _currentIndex == 3) {
      return null;
    }
    
    // Static AppBar for Chats and Status tabs
    return AppBar(
      elevation: 0,
      backgroundColor: modernTheme.backgroundColor,
      centerTitle: true,
      title: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "Tex",
              style: TextStyle(
                color: modernTheme.textColor,          
                fontWeight: FontWeight.w500,
                fontSize: 22,
              ),
            ),
            TextSpan(
              text: "GB",
              style: TextStyle(
                color: modernTheme.primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
          ],
        ),
      ),
      actions: _buildAppBarActions(modernTheme, _currentIndex),
      leading: _buildAppBarLeading(modernTheme, _currentIndex),
      // Adding system nav padding
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(8.0),
        child: Container(),
      ),
    );
  }
  
  // AppBar leading widget based on tab
  Widget? _buildAppBarLeading(ModernThemeExtension modernTheme, int tabIndex) {
    // Only show custom leading for tabs that need it
    if (tabIndex == 3) {
      return IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: modernTheme.textColor,
        ),
        onPressed: () {
          _onTabTapped(0); // Go back to chats tab
        },
      );
    }
    return null;
  }
  
  // AppBar actions based on current tab
  List<Widget> _buildAppBarActions(ModernThemeExtension modernTheme, int tabIndex) {
    // Default actions for chats tab
    if (tabIndex == 0) {
      return [
        IconButton(
          icon: Icon(
            Icons.search,
            color: modernTheme.textColor,
          ),
          onPressed: () {
            // TODO: Implement search
          },
        ),
        IconButton(
          icon: Icon(
            Icons.more_vert,
            color: modernTheme.textColor,
          ),
          onPressed: () {
            // TODO: Show more options
          },
        ),
      ];
    }
    
    // Actions for status tab
    else if (tabIndex == 1) {
      return [
        IconButton(
          icon: Icon(
            Icons.camera_alt,
            color: modernTheme.textColor,
          ),
          onPressed: () {
            Navigator.pushNamed(context, Constants.createStatusScreen);
          },
        ),
      ];
    }
    
    // Actions for marketplace tab
    else if (tabIndex == 2) {
      return [
        IconButton(
          icon: Icon(
            Icons.search,
            color: modernTheme.textColor,
          ),
          onPressed: () {
            // TODO: Search marketplace
          },
        ),
        IconButton(
          icon: Icon(
            Icons.shopping_cart,
            color: modernTheme.textColor,
          ),
          onPressed: () {
            // TODO: Open shopping cart
          },
        ),
      ];
    }
    
    // No custom actions for profile tab
    return [];
  }
  
  // FAB based on current tab
  Widget _buildFab(ModernThemeExtension modernTheme) {
    IconData fabIcon;
    VoidCallback onPressed;
    
    // Different FAB for different tabs
    switch (_currentIndex) {
      case 0: // Chats
        fabIcon = Icons.chat;
        onPressed = () {
          // Navigate to contacts screen
          Navigator.pushNamed(context, Constants.contactsScreen);
        };
        break;
      case 1: // Status
        fabIcon = Icons.add;
        onPressed = () {
          // Navigate to create status screen
          Navigator.pushNamed(context, Constants.createStatusScreen);
        };
        break;
      default:
        fabIcon = Icons.chat;
        onPressed = () {};
    }
    
    return FloatingActionButton(
      backgroundColor: modernTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      onPressed: onPressed,
      child: Icon(fabIcon),
    );
  }
}
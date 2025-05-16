import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/chat/screens/chats_tab.dart';
import 'package:textgb/features/marketplace/screens/create_marketplace_video_screen.dart';
import 'package:textgb/features/marketplace/screens/marketplace_video_feed_screen.dart';
import 'package:textgb/features/profile/screens/my_profile_screen.dart';
import 'package:textgb/features/status/screens/status_overview_screen.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/widgets/custom_icon_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  
  // Updated list of tab names (5 tabs now)
  final List<String> _tabNames = [
    'Chats',
    'Groups',
    '',  // Empty for center button
    'Status',
    'Marketplace'
  ];
  
  // Updated list of tab icons (5 tabs now)
  final List<IconData> _tabIcons = [
    Icons.chat_bubble_rounded,
    Icons.group_rounded,
    Icons.add,  // Placeholder, we'll use CustomIconButton instead
    Icons.photo_library_rounded,
    Icons.shopping_bag_rounded
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    // Special handling for center button (index 2)
    if (index == 2) {
      // Navigate to CreateMarketplaceVideoScreen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const CreateMarketplaceVideoScreen(),
        ),
      );
      return; // Don't update current index or animate page
    }
    
    // For other tabs, calculate the actual page index
    // Since we removed Profile (index 3) and have a non-page center button (index 2)
    int pageIndex = index;
    if (index > 2) pageIndex = index - 1; // Adjust for center button
    
    setState(() {
      _currentIndex = index;
    });
    
    // Animate to the selected page
    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    // Ensure system UI is updated when page changes via tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSystemUI();
    });
  }

  // Navigate to profile screen
  void _navigateToProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MyProfileScreen(),
      ),
    );
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
    // Convert page index to tab index
    int tabIndex = index;
    if (index >= 2) tabIndex = index + 1; // Adjust for center button
    
    setState(() {
      _currentIndex = tabIndex;
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
    
    // Check which page we're actually on (adjusting for the center button)
    final int actualPageIndex = _currentIndex > 2 ? _currentIndex - 1 : _currentIndex;
    
    return Scaffold(
      extendBody: true, // Important for the transparent navigation bar
      extendBodyBehindAppBar: actualPageIndex == 2, // Only extend content behind AppBar for marketplace tab
      backgroundColor: actualPageIndex == 2 ? Colors.black : modernTheme.backgroundColor,
      
      // Custom AppBar
      appBar: _buildAppBar(modernTheme, isDarkMode),
      
      // PageView for tab content - profile is no longer in PageView
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swiping between tabs
        onPageChanged: _onPageChanged,
        children: [
          const ChatsTab(),
          Center(child: Text('Groups (Coming Soon)', style: TextStyle(color: modernTheme.textColor))), // Groups placeholder
          const StatusOverviewScreen(),
          const MarketplaceVideoFeedScreen(),
        ],
      ),
      
      // Updated Bottom Navigation Bar with 5 items
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Divider above bottom nav
          Divider(
            height: 1,
            thickness: 0.5,
            color: actualPageIndex == 2 ? Colors.grey[900] : modernTheme.dividerColor,
          ),
          // Standard BottomNavigationBar with custom styling
          Container(
            decoration: BoxDecoration(
              color: actualPageIndex == 2 ? Colors.black : modernTheme.surfaceColor,
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
                    
                    // Special case for center button (index 2)
                    if (index == 2) {
                      return BottomNavigationBarItem(
                        icon: SizedBox(
                          height: 48,
                          child: Center(
                            child: CustomIconButton(), // Using CustomIconButton widget
                          ),
                        ),
                        label: '', // No label for center button
                      );
                    }
                    
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
      
      // FAB for new chat or content (only for specific tabs)
      floatingActionButton: _shouldShowFab() ? _buildFab(modernTheme) : null,
    );
  }
  
  // Determine if FAB should be shown
  bool _shouldShowFab() {
    // Only show FAB for Chats and Status tabs
    return _currentIndex == 0 || _currentIndex == 3;
  }
  
  PreferredSizeWidget? _buildAppBar(ModernThemeExtension modernTheme, bool isDarkMode) {
    // Check which page we're actually on (adjusting for the center button)
    final int actualPageIndex = _currentIndex > 2 ? _currentIndex - 1 : _currentIndex;
    
    // Hide AppBar for Marketplace tab
    if (actualPageIndex == 2) {
      return null;
    }
    
    // Get current user for profile image
    final user = ref.watch(currentUserProvider);
    
    // AppBar with app name on left and profile icon on right
    return AppBar(
      elevation: 0,
      backgroundColor: modernTheme.backgroundColor,
      centerTitle: false, // Move title to left
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
      actions: [
        // Search icon for chats and marketplace
        if (_currentIndex == 0 || actualPageIndex == 2)
          IconButton(
            icon: Icon(
              Icons.search,
              color: modernTheme.textColor,
            ),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          
        // More options for chats
        if (_currentIndex == 0)
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: modernTheme.textColor,
            ),
            onPressed: () {
              // TODO: Show more options
            },
          ),
          
        // Camera icon for status tab
        if (_currentIndex == 3)
          IconButton(
            icon: Icon(
              Icons.camera_alt,
              color: modernTheme.textColor,
            ),
            onPressed: () {
              Navigator.pushNamed(context, Constants.createStatusScreen);
            },
          ),
          
        // Shopping cart for marketplace tab
        if (actualPageIndex == 2)
          IconButton(
            icon: Icon(
              Icons.shopping_cart,
              color: modernTheme.textColor,
            ),
            onPressed: () {
              // TODO: Open shopping cart
            },
          ),
          
        // Profile icon - always shown
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: GestureDetector(
            onTap: _navigateToProfile,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: modernTheme.primaryColor!,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: user?.image != null && user!.image.isNotEmpty
                  ? Image.network(
                      user.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.person,
                        color: modernTheme.textColor,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: modernTheme.textColor,
                    ),
              ),
            ),
          ),
        ),
      ],
      // Adding system nav padding
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(8.0),
        child: Container(),
      ),
    );
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
      case 3: // Status (now at index 3)
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
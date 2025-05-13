import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/profile/screens/my_profile_screen.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/widgets/modern_bottomnav_bar.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBody: true, // Important for the floating bottom navigation bar
      extendBodyBehindAppBar: true, // Extend content behind the AppBar
      backgroundColor: modernTheme.backgroundColor,
      
      // Custom AppBar
      appBar: _buildAppBar(modernTheme, isDarkMode),
      
      // PageView for tab content
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swiping between tabs
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          _buildChatsTab(modernTheme),
          _buildStatusTab(modernTheme),
          _buildMarketplaceTab(modernTheme),
          const MyProfileScreen(), // Use the existing profile screen
        ],
      ),
      
      // Custom Bottom Navigation Bar
      bottomNavigationBar: ModernBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        backgroundColor: modernTheme.surfaceColor!,
        selectedItemColor: modernTheme.primaryColor!,
        unselectedItemColor: modernTheme.textSecondaryColor!,
        items: List.generate(
          _tabNames.length,
          (index) => BottomNavigationBarItem(
            icon: Icon(_tabIcons[index]),
            label: _tabNames[index],
          ),
        ),
        elevation: 8.0,
        showLabels: true,
      ),
      
      // FAB for new chat or content
      floatingActionButton: _currentIndex != 3 ? _buildFab(modernTheme) : null,
    );
  }
  
  PreferredSizeWidget _buildAppBar(ModernThemeExtension modernTheme, bool isDarkMode) {
    // Different titles based on the selected tab
    final title = _tabNames[_currentIndex];
    
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      title: Text(
        _currentIndex == 3 ? "My Profile" : "WeiChat",
        style: TextStyle(
          color: modernTheme.textColor,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      actions: _buildAppBarActions(modernTheme, _currentIndex),
      leading: _buildAppBarLeading(modernTheme, _currentIndex),
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
            // TODO: Open camera for status
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
          // TODO: Start new chat
          Navigator.pushNamed(context, Constants.contactsScreen);
        };
        break;
      case 1: // Status
        fabIcon = Icons.add;
        onPressed = () {
          // TODO: Add new status
        };
        break;
      case 2: // Marketplace
        fabIcon = Icons.add_shopping_cart;
        onPressed = () {
          // TODO: Add new item to sell
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
  
  // Tab content builders
  Widget _buildChatsTab(ModernThemeExtension modernTheme) {
    return Container(
      color: modernTheme.backgroundColor,
      child: ListView.builder(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 56, bottom: 100),
        itemCount: 15, // Sample count
        itemBuilder: (context, index) {
          return _buildChatItem(modernTheme, index);
        },
      ),
    );
  }
  
  Widget _buildChatItem(ModernThemeExtension modernTheme, int index) {
    // Sample data
    final name = "User ${index + 1}";
    final message = index % 3 == 0 
        ? "Hey, how are you doing today?" 
        : index % 3 == 1 
            ? "Can we meet tomorrow for lunch?"
            : "I sent you the documents you requested";
    final time = index % 4 == 0 
        ? "Just now" 
        : index % 4 == 1 
            ? "5 min ago" 
            : index % 4 == 2 
                ? "1 hour ago"
                : "Yesterday";
    final hasUnread = index % 3 == 0;
    final unreadCount = hasUnread ? (index % 5) + 1 : 0;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: modernTheme.primaryColor!.withOpacity(0.2),
        child: Text(
          name.substring(0, 1),
          style: TextStyle(
            color: modernTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        name,
        style: TextStyle(
          color: modernTheme.textColor,
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: hasUnread 
              ? modernTheme.textColor 
              : modernTheme.textSecondaryColor,
          fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: TextStyle(
              color: hasUnread 
                  ? modernTheme.primaryColor 
                  : modernTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          if (hasUnread)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: modernTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        // TODO: Open chat
      },
    );
  }
  
  Widget _buildCallsTab(ModernThemeExtension modernTheme) {
    return Container(
      color: modernTheme.backgroundColor,
      child: ListView.builder(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 56, bottom: 100),
        itemCount: 10, // Sample count
        itemBuilder: (context, index) {
          return _buildCallItem(modernTheme, index);
        },
      ),
    );
  }
  
  Widget _buildCallItem(ModernThemeExtension modernTheme, int index) {
    // Sample data
    final name = "User ${index + 1}";
    final isMissed = index % 3 == 0;
    final isOutgoing = index % 2 == 0;
    final time = index % 4 == 0 
        ? "Just now" 
        : index % 4 == 1 
            ? "5 min ago" 
            : index % 4 == 2 
                ? "1 hour ago"
                : "Yesterday";
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: modernTheme.primaryColor!.withOpacity(0.2),
        child: Text(
          name.substring(0, 1),
          style: TextStyle(
            color: modernTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        name,
        style: TextStyle(
          color: modernTheme.textColor,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(
            isOutgoing ? Icons.call_made : Icons.call_received,
            color: isMissed 
                ? Colors.red 
                : Colors.green,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            time,
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.call,
          color: modernTheme.primaryColor,
        ),
        onPressed: () {
          // TODO: Call this contact
        },
      ),
      onTap: () {
        // TODO: Show call details
      },
    );
  }
  
  Widget _buildStatusTab(ModernThemeExtension modernTheme) {
    return Container(
      color: modernTheme.backgroundColor,
      child: ListView(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 56, bottom: 100),
        children: [
          // My status
          ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: modernTheme.primaryColor!.withOpacity(0.2),
                  radius: 24,
                  child: const Text(
                    "Me",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: modernTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: modernTheme.backgroundColor!,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              "My Status",
              style: TextStyle(
                color: modernTheme.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              "Tap to add status update",
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
              ),
            ),
            onTap: () {
              // TODO: Add new status
            },
          ),
          
          // Recent updates
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Recent Updates",
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Status items
          ...List.generate(
            5,
            (index) => _buildStatusItem(modernTheme, index),
          ),
          
          // Viewed updates
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Viewed Updates",
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Viewed status items
          ...List.generate(
            3,
            (index) => _buildStatusItem(modernTheme, index + 5, isViewed: true),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusItem(ModernThemeExtension modernTheme, int index, {bool isViewed = false}) {
    final name = "User ${index + 1}";
    final time = index % 4 == 0 
        ? "Just now" 
        : index % 4 == 1 
            ? "5 min ago" 
            : index % 4 == 2 
                ? "1 hour ago"
                : "Yesterday";
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isViewed 
                ? modernTheme.textSecondaryColor!
                : modernTheme.primaryColor!,
            width: 2,
          ),
        ),
        child: CircleAvatar(
          backgroundColor: modernTheme.primaryColor!.withOpacity(0.2),
          child: Text(
            name.substring(0, 1),
            style: TextStyle(
              color: modernTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      title: Text(
        name,
        style: TextStyle(
          color: modernTheme.textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        time,
        style: TextStyle(
          color: modernTheme.textSecondaryColor,
        ),
      ),
      onTap: () {
        // TODO: View status
      },
    );
  }
  
  Widget _buildMarketplaceTab(ModernThemeExtension modernTheme) {
    return Container(
      color: modernTheme.backgroundColor,
      child: GridView.builder(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 56,
          left: 12,
          right: 12,
          bottom: 100,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 10,
        itemBuilder: (context, index) {
          return _buildMarketplaceItem(modernTheme, index);
        },
      ),
    );
  }
  
  Widget _buildMarketplaceItem(ModernThemeExtension modernTheme, int index) {
    // Sample product data
    final name = "Product ${index + 1}";
    final price = "\$${(index + 1) * 10 + 5}.99";
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: modernTheme.surfaceColor!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.primaries[index % Colors.primaries.length].withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              width: double.infinity,
              child: Center(
                child: Icon(
                  Icons.shopping_bag,
                  size: 48,
                  color: Colors.primaries[index % Colors.primaries.length],
                ),
              ),
            ),
          ),
          
          // Product details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: TextStyle(
                    color: modernTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Seller rating
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (3.5 + (index % 3) * 0.5).toStringAsFixed(1),
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    // Add to cart button
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: modernTheme.primaryColor!.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_shopping_cart,
                        color: modernTheme.primaryColor,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
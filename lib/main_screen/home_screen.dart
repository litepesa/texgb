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
import 'package:textgb/features/groups/screens/groups_tab.dart';
import 'package:textgb/features/profile/screens/my_profile_screen.dart';
import 'package:textgb/features/status/screens/status_overview_screen.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/widgets/custom_icon_button.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/groups/providers/group_provider.dart';

// Define a new provider for group chats from chat provider
final groupChatStreamProvider = Provider<AsyncValue<List<ChatModel>>>((ref) {
  final allChats = ref.watch(chatStreamProvider);
  
  return allChats.when(
    data: (chats) => AsyncValue.data(chats.where((chat) => chat.isGroup).toList()),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

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
    'Channels'  // Changed from Marketplace to Channels
  ];
  
  // Updated list of tab icons (5 tabs now)
  final List<IconData> _tabIcons = [
    CupertinoIcons.chat_bubble_text, // Changed from Icons.chat_bubble_rounded
    CupertinoIcons.person_2,
    Icons.add,  // Placeholder, we'll use CustomIconButton instead
    CupertinoIcons.rays, // Changed from Icons.photo_library_rounded
    CupertinoIcons.camera // Changed from Icons.shopping_bag_rounded
  ];

  @override
  void initState() {
    super.initState();
    // Load user's channel data on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(channelsProvider.notifier).loadUserChannel();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    // Special handling for center button (index 2)
    if (index == 2) {
      // Check if user has a channel for creating posts
      final userChannel = ref.read(channelsProvider).userChannel;
      
      if (userChannel == null) {
        // If no channel exists, always navigate to CreateChannelScreen first
        Navigator.of(context).pushNamed(Constants.createChannelScreen);
      } else {
        // If user has a channel, navigate to CreateChannelPostScreen
        Navigator.of(context).pushNamed(Constants.createChannelPostScreen);
      }
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
    
    // Get chats list to calculate total unread messages
    final chatsAsyncValue = ref.watch(chatStreamProvider);
    
    // Get groups list to calculate unread messages
    final groupsAsyncValue = ref.watch(userGroupsStreamProvider);
    
    // Get group chats for Groups tab
    final groupChatsAsyncValue = ref.watch(groupChatStreamProvider);
    
    // Calculate bottom padding to account for system navigation
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // Update system UI when widget rebuilds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSystemUI();
    });
    
    // Check which page we're actually on (adjusting for the center button)
    final int actualPageIndex = _currentIndex > 2 ? _currentIndex - 1 : _currentIndex;
    
    // Only hide AppBar and change background to black for channels tab (index 4)
    final bool isChannelsTab = _currentIndex == 4;
    
    return Scaffold(
      extendBody: true, // Important for the transparent navigation bar
      extendBodyBehindAppBar: isChannelsTab, // Only extend content behind AppBar for channels tab
      backgroundColor: isChannelsTab ? Colors.black : modernTheme.backgroundColor,
      
      // Custom AppBar
      appBar: _buildAppBar(modernTheme, isDarkMode),
      
      // PageView for tab content - profile is no longer in PageView
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swiping between tabs
        onPageChanged: _onPageChanged,
        children: [
          const ChatsTab(),
          const GroupsTab(), // Now using the actual GroupsTab
          const StatusOverviewScreen(),
          const ChannelsFeedScreen(),
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
            color: isChannelsTab ? Colors.grey[900] : modernTheme.dividerColor,
          ),
          // Standard BottomNavigationBar with custom styling
          Container(
            decoration: BoxDecoration(
              color: isChannelsTab ? Colors.black : modernTheme.surfaceColor,
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
                    
                    // Check if it's the Chats tab (index 0) and has unread messages
                    if (index == 0) {
                      return chatsAsyncValue.when(
                        data: (chats) {
                          // Calculate total unread count from direct chats only
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
                                // Show badge only if there are unread messages
                                if (totalUnreadCount > 0)
                                  Positioned(
                                    top: -5,
                                    right: -5,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
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
                                          totalUnreadCount > 99 
                                              ? '99+' 
                                              : totalUnreadCount.toString(),
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
                    
                    // Check if it's the Groups tab (index 1) and has unread messages
                    if (index == 1) {
                      return groupsAsyncValue.when(
                        data: (groups) {
                          // Calculate total unread count from regular groups
                          final currentUserUid = ref.read(groupProvider.notifier).getCurrentUserUid();
                          final groupUnreadCount = currentUserUid != null
                              ? groups.fold<int>(
                                  0, 
                                  (sum, group) => sum + group.getUnreadCountForUser(currentUserUid)
                                )
                              : 0;
                          
                          // Calculate unread count from group chats
                          int groupChatUnreadCount = 0;
                          if (groupChatsAsyncValue.hasValue) {
                            final groupChats = groupChatsAsyncValue.value!;
                            // Use a for loop instead of fold
                            for (final chat in groupChats) {
                              groupChatUnreadCount += chat.getDisplayUnreadCount();
                            }
                          }
                          
                          // Add pending requests for admins in the badge count
                          final pendingRequests = groups
                              .where((group) => ref.read(groupProvider.notifier).isCurrentUserAdmin(group.groupId))
                              .fold<int>(0, (sum, group) => sum + group.awaitingApprovalUIDs.length);
                          
                          // Total badge count combines all three sources
                          final badgeCount = groupUnreadCount + groupChatUnreadCount + pendingRequests;
                          
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
                                // Show badge only if there are unread messages or pending requests
                                if (badgeCount > 0)
                                  Positioned(
                                    top: -5,
                                    right: -5,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: badgeCount > 99 
                                            ? BoxShape.rectangle 
                                            : BoxShape.circle,
                                        borderRadius: badgeCount > 99 
                                            ? BorderRadius.circular(10) 
                                            : null,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 18,
                                      ),
                                      child: Center(
                                        child: Text(
                                          badgeCount > 99 
                                              ? '99+' 
                                              : badgeCount.toString(),
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
                    
                    // Default case for other tabs
                    return _buildDefaultBottomNavItem(index, isSelected, modernTheme);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      
      // FAB for new chat (only for Chats tab) or new group (for Groups tab)
      floatingActionButton: _shouldShowFab() ? _buildFab(modernTheme) : null,
    );
  }
  
  // Helper method to build default bottom nav item (without badge)
  BottomNavigationBarItem _buildDefaultBottomNavItem(int index, bool isSelected, ModernThemeExtension modernTheme) {
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
  
  // Determine if FAB should be shown
  bool _shouldShowFab() {
    // Show FAB for Chats, Groups, and Status tabs
    return _currentIndex == 0 || _currentIndex == 1 || _currentIndex == 3;
  }
  
  PreferredSizeWidget? _buildAppBar(ModernThemeExtension modernTheme, bool isDarkMode) {
    // Only hide AppBar for Channels tab (index 4)
    if (_currentIndex == 4) {
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
      actions: [
        // WiFi icon for all tabs
        IconButton(
          icon: Icon(
            Icons.wifi,
            color: modernTheme.textColor,
          ),
          onPressed: () {
            // TODO: WiFi action
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
        fabIcon = CupertinoIcons.chat_bubble_text;
        onPressed = () {
          // Navigate to contacts screen
          Navigator.pushNamed(context, Constants.contactsScreen);
        };
        break;
      case 1: // Groups
        fabIcon = Icons.group_add;
        onPressed = () {
          // Navigate to create group screen
          Navigator.pushNamed(context, Constants.createGroupScreen);
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
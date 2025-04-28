import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/channels/screens/channels_screen.dart';
import 'package:textgb/features/contacts/screens/my_profile_screen.dart';
import 'package:textgb/features/status/screens/status_overview_screen.dart';
import 'package:textgb/features/chat/screens/my_chats_screen.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  int pageIndex = 0;
  
  // Creating separate widget variables with 3 screens
  final Widget chatScreen = const MyChatsScreen();
  // Using the new StatusOverviewScreen instead of the old StatusScreen
  final Widget statusScreen = const StatusOverviewScreen();
  final Widget channelsScreen = const ChannelsScreen();
  
  // We'll define these in initState to ensure they match our bottom nav bar
  late final List<Widget> pages;
  
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    
    // Initialize pages list to match our bottom nav bar (now 3 tabs)
    pages = [
      chatScreen,        // Index 0 - Chats
      statusScreen,      // Index 1 - Status Feed
      channelsScreen,    // Index 2 - Channels
    ];
    
    // Set feed filter on initialization (for new status implementation)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StatusProvider>().setFeedFilter(FeedFilterType.latest);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // user comes back to the app
        // update user status to online
        context.read<AuthenticationProvider>().updateUserStatus(
              value: true,
            );
        // Refresh status feed when app is resumed
        if (pageIndex == 1) { // Status is index 1
          _refreshStatusFeed();
          // Set status tab visibility to true when app resumes on status tab
          context.read<StatusProvider>().setStatusTabVisible(true);
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // app is inactive, paused, detached or hidden
        // update user status to offline
        context.read<AuthenticationProvider>().updateUserStatus(
              value: false,
            );
        // Set status tab visibility to false when app is in background
        if (pageIndex == 1) { // Status is index 1
          context.read<StatusProvider>().setStatusTabVisible(false);
        }
        break;
      default:
        // handle other states
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

  // Function to refresh status feed with new implementation
  void _refreshStatusFeed() {
    final currentUser = context.read<AuthenticationProvider>().userModel;
    if (currentUser != null) {
      // Use the new fetchAllStatuses method from the updated StatusProvider
      context.read<StatusProvider>().fetchAllStatuses(
        currentUserId: currentUser.uid,
        contactIds: currentUser.contactsUIDs,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the new theme extensions
    final modernTheme = context.modernTheme;
    final animationTheme = context.animationTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Get accent color from ModernThemeExtension
    final accentColor = modernTheme.primaryColor!;
    
    // Get app bar and surface colors
    final appBarColor = modernTheme.appBarColor!;
    final surfaceColor = modernTheme.surfaceColor!;
    
    // Determine bottom nav color based on selected tab
    final bottomNavColor = pageIndex == 1 
        ? Colors.black  // Force black color when status tab is selected
        : surfaceColor; // Use theme surface color for other tabs
    
    // Get text colors
    final textColor = modernTheme.textColor!;
    final textSecondaryColor = modernTheme.textSecondaryColor!;
    
    // Consistent selected item color
    final selectedItemColor = accentColor;
    
    // Unselected items color
    final unselectedItemColor = textSecondaryColor;
    
    // Set elevation for better delineation
    final elevation = isDarkMode ? 1.0 : 2.0;

    // Get the current user data for the profile avatar
    final authProvider = context.watch<AuthenticationProvider>();
    final currentUser = authProvider.userModel;
    
    return Scaffold(
      appBar: pageIndex != 1 ? AppBar(
        elevation: elevation,
        toolbarHeight: 65.0,
        centerTitle: false,
        backgroundColor: appBarColor,
        title: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            children: [
              TextSpan(
                text: 'Tex',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: 'GB',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Profile avatar with red ring
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: GestureDetector(
              onTap: () {
                // Navigate to profile screen when avatar is tapped
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MyProfileScreen(),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.withOpacity(0.7),
                    width: 2,
                  ),
                ),
                child: Hero(
                  tag: 'profile-image',
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: currentUser?.image != null && currentUser!.image.isNotEmpty
                      ? CachedNetworkImageProvider(currentUser.image)
                      : AssetImage(AssetsManager.userImage) as ImageProvider,
                  ),
                ),
              ),
            ),
          ),
        ],
      ) : null,
      body: IndexedStack(
        index: pageIndex,
        children: pages,
      ),
      // Custom bottom nav bar that extends into system nav area
      bottomNavigationBar: Material(
        color: bottomNavColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top divider for the bottom nav
            Divider(
              height: 1,
              thickness: 0.5,
              color: modernTheme.dividerColor,
            ),
            // Bottom navigation bar (standard height)
            BottomNavigationBar(
              onTap: (index) {
                // If switching FROM status tab, ensure videos are paused by setting visibility flag
                if (pageIndex == 1 && index != 1) {
                  // We're switching away from status tab
                  context.read<StatusProvider>().setStatusTabVisible(false);
                } else if (index == 1 && pageIndex != 1) {
                  // We're switching TO status tab, set visibility to true
                  context.read<StatusProvider>().setStatusTabVisible(true);
                }
                
                setState(() {
                  pageIndex = index;
                });
                
                // If status tab is selected, refresh status data
                if (index == 1) {
                  _refreshStatusFeed();
                }
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent, // Make transparent to inherit from Material
              selectedItemColor: pageIndex == 1 ? Colors.white : selectedItemColor,
              unselectedItemColor: pageIndex == 1 ? Colors.white70 : unselectedItemColor,
              showUnselectedLabels: true,
              showSelectedLabels: true,
              currentIndex: pageIndex,
              elevation: 0, // No elevation
              selectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                height: 1.6,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                height: 1.6,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.chat_bubble_text, size: 30),
                  label: 'Chats',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.rays, size: 30),
                  label: 'Status',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.camera, size: 30),
                  label: 'Channels',
                ),
              ],
            ),
            // Extra padding that extends into system navigation area
            MediaQuery.of(context).padding.bottom > 0
              ? Container(
                  height: MediaQuery.of(context).padding.bottom,
                  color: bottomNavColor, // Same color as bottom nav
                )
              : const SizedBox.shrink(),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(accentColor),
    );
  }
  
  // Build context-specific floating action button
  Widget? _buildFloatingActionButton(Color accentColor) {
    // Chat button for Chats tab
    if (pageIndex == 0) {
      return FloatingActionButton(
        onPressed: () {
          // Navigate to Contacts screen
          Navigator.pushNamed(
            context,
            Constants.contactsScreen,
          );
        },
        backgroundColor: accentColor,
        elevation: 4.0, // Increased elevation for better visibility
        child: const Icon(CupertinoIcons.chat_bubble_text, size: 26),
      );
    }
    // Status create button for Status tab
    else if (pageIndex == 1) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, Constants.createStatusScreen)
              .then((_) => _refreshStatusFeed()); // Refresh after returning
        },
        backgroundColor: Colors.green, // Distinctive color for status creation
        elevation: 4.0,
        child: const Icon(CupertinoIcons.camera, size: 26),
      );
    }
    // FAB for Channels tab - Navigate to create channel
    else if (pageIndex == 2) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, Constants.createChannelScreen);
        },
        backgroundColor: accentColor,
        elevation: 4.0,
        child: const Icon(CupertinoIcons.add, size: 26),
      );
    }
    
    // No FAB for other tabs
    return null;
  }
}
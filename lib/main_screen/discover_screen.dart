// lib/main_screen/discover_screen.dart - Updated with Moments
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/videos/screens/create_post_screen.dart';
import 'package:textgb/features/videos/screens/videos_feed_screen.dart';
import 'package:textgb/features/wallet/screens/wallet_screen.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: modernTheme.surfaceColor,
      body: ListView(
        children: [
          // First section - Main features
          _buildListItem(
            icon: CupertinoIcons.camera_circle,
            title: 'Moments',
            subtitle: 'Share your moments with friends',
            iconColor: const Color(0xFF007AFF),
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const VideosFeedScreen(),
                ),
              );
            },
            modernTheme: modernTheme,
          ),
          
          /*_buildListItem(
            icon: CupertinoIcons.shopping_cart,
            title: 'Marketplace',
            subtitle: 'Buy and sell anything easily',
            iconColor: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VideosFeedScreen(),
                ),
              );
            },
            modernTheme: modernTheme,
          ),*/
          
          _buildListItem(
            icon: CupertinoIcons.play_rectangle,
            title: 'Channels',
            subtitle: 'Discover and share videos',
            iconColor: Colors.red,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VideosFeedScreen(),
                ),
              );
            },
            modernTheme: modernTheme,
          ),
          
          _buildListItem(
            icon: Icons.campaign_outlined,
            title: 'Public Groups',
            subtitle: 'Join and discover communities',
            iconColor: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VideosFeedScreen(),
                ),
              );
            },
            modernTheme: modernTheme,
          ),
          
          _buildListItem(
            icon: Icons.add_box_outlined,
            title: 'Create Post',
            subtitle: 'Share content on your channel',
            iconColor: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePostScreen(),
                ),
              );
            },
            modernTheme: modernTheme,
          ),
          
          _buildListItem(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Wallet',
            subtitle: 'Manage your finances',
            iconColor: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WalletScreen(),
                ),
              );
            },
            modernTheme: modernTheme,
          ),
          
          _buildComingSoonItem(
            icon: CupertinoIcons.square_grid_2x2,
            title: 'Mini Programs',
            subtitle: 'Quick access to useful tools',
            iconColor: Colors.purple,
            modernTheme: modernTheme,
          ),
          
          _buildComingSoonItem(
            icon: CupertinoIcons.game_controller,
            title: 'Games',
            subtitle: 'Play games with friends',
            iconColor: Colors.indigo,
            modernTheme: modernTheme,
          ),
          
          _buildComingSoonItem(
            icon: CupertinoIcons.location,
            title: 'Nearby',
            subtitle: 'Discover people and places nearby',
            iconColor: Colors.teal,
            modernTheme: modernTheme,
          ),
          
          // Add some bottom padding
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildListItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color iconColor,
    required VoidCallback onTap,
    required ModernThemeExtension modernTheme,
  }) {
    return Container(
      color: modernTheme.surfaceColor,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: modernTheme.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor?.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: modernTheme.textSecondaryColor?.withOpacity(0.6),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildComingSoonItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color iconColor,
    required ModernThemeExtension modernTheme,
  }) {
    return Container(
      color: modernTheme.surfaceColor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor.withOpacity(0.7),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: modernTheme.textSecondaryColor?.withOpacity(0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: modernTheme.primaryColor?.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Soon',
                          style: TextStyle(
                            color: modernTheme.primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor?.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDivider(ModernThemeExtension modernTheme) {
    return Container(
      height: 8,
      color: modernTheme.backgroundColor,
    );
  }
}
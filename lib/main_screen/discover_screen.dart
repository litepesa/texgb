// lib/features/discover/screens/discover_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/channels/screens/channels_feed_screen.dart';
import 'package:textgb/features/channels/screens/create_post_screen.dart';
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
            icon: CupertinoIcons.play_rectangle,
            title: 'Channels',
            iconColor: Colors.red,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChannelsFeedScreen(),
                ),
              );
            },
            modernTheme: modernTheme,
          ),
          
          _buildListItem(
            icon: Icons.add_box_outlined,
            title: 'Create Post',
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
            icon: CupertinoIcons.camera_circle,
            title: 'Moments',
            iconColor: Colors.orange,
            modernTheme: modernTheme,
          ),
          
          _buildComingSoonItem(
            icon: CupertinoIcons.square_grid_2x2,
            title: 'Mini Programs',
            iconColor: Colors.purple,
            modernTheme: modernTheme,
          ),
          
          _buildComingSoonItem(
            icon: CupertinoIcons.game_controller,
            title: 'Games',
            iconColor: Colors.indigo,
            modernTheme: modernTheme,
          ),
          
          _buildComingSoonItem(
            icon: CupertinoIcons.location,
            title: 'Nearby',
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: modernTheme.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
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
    required Color iconColor,
    required ModernThemeExtension modernTheme,
  }) {
    return Container(
      color: modernTheme.surfaceColor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: iconColor.withOpacity(0.7),
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor?.withOpacity(0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: modernTheme.primaryColor?.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Soon',
                      style: TextStyle(
                        color: modernTheme.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
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
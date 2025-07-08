// lib/features/channels/widgets/channel_profile_bottom_nav.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/models/channel_video_model.dart';

class ChannelProfileBottomNav extends StatelessWidget {
  final double progressBarHeight;
  final double bottomNavContentHeight;
  final ValueNotifier<double> progressNotifier;
  final ChannelVideoModel? currentVideo;
  final VoidCallback onBackPressed;
  final VoidCallback onSearchPressed;
  final VoidCallback onGiftPressed;
  final VoidCallback onDMPressed;
  final VoidCallback onLikePressed;
  final VoidCallback onCommentsPressed;

  const ChannelProfileBottomNav({
    Key? key,
    required this.progressBarHeight,
    required this.bottomNavContentHeight,
    required this.progressNotifier,
    required this.currentVideo,
    required this.onBackPressed,
    required this.onSearchPressed,
    required this.onGiftPressed,
    required this.onDMPressed,
    required this.onLikePressed,
    required this.onCommentsPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final totalHeight = bottomNavContentHeight + progressBarHeight + bottomPadding;
    
    return Container(
      height: totalHeight,
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: Column(
        children: [
          // Progress bar as divider
          _buildProgressBar(context, modernTheme),
          
          // Navigation content
          Container(
            height: bottomNavContentHeight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Custom Gift button
                _GiftButton(onPressed: onGiftPressed),
                
                // Custom Search button
                _SearchButton(onPressed: onSearchPressed),
                
                // Custom DM button
                _DMButton(onPressed: onDMPressed),
                
                // Custom Like button with badge
                _LikeButton(
                  onPressed: onLikePressed,
                  isLiked: currentVideo?.isLiked ?? false,
                  likeCount: currentVideo?.likes ?? 0,
                  modernTheme: modernTheme,
                ),
                
                // Custom Comments button with badge
                _CommentsButton(
                  onPressed: onCommentsPressed,
                  commentCount: currentVideo?.comments ?? 0,
                  modernTheme: modernTheme,
                ),
              ],
            ),
          ),
          
          // System navigation bar space
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  // Progress bar widget for the bottom nav divider
  Widget _buildProgressBar(BuildContext context, ModernThemeExtension modernTheme) {
    return ValueListenableBuilder<double>(
      valueListenable: progressNotifier,
      builder: (context, progress, child) {
        return Container(
          height: progressBarHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: MediaQuery.of(context).size.width * progress.clamp(0.0, 1.0),
                height: progressBarHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      modernTheme.primaryColor ?? Colors.blue,
                      (modernTheme.primaryColor ?? Colors.blue).withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatCount(int count) {
    if (count == 0) return '0';
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}

// Custom Gift Button Widget - TikTok Live Style with "Gift" text
class _GiftButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GiftButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 50,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.purple.shade400,
              Colors.pink.shade300,
              Colors.orange.shade300,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Sparkle effect background
            Positioned(
              left: 8,
              top: 4,
              child: Icon(
                Icons.star,
                color: Colors.white.withOpacity(0.8),
                size: 6,
              ),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: Icon(
                Icons.star,
                color: Colors.white.withOpacity(0.6),
                size: 5,
              ),
            ),
            Positioned(
              left: 10,
              bottom: 6,
              child: Icon(
                Icons.star,
                color: Colors.white.withOpacity(0.7),
                size: 5,
              ),
            ),
            // Gift text
            Center(
              child: Text(
                'Gift',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Search Button Widget
class _SearchButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SearchButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 50,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade600,
              Colors.grey.shade500,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.search,
            color: Colors.white,
            size: 20,
            shadows: const [
              Shadow(
                color: Colors.black54,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom DM Button Widget - Distinct from Comments
class _DMButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DMButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 45,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade500,
              Colors.cyan.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'DM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Like Button Widget with Badge
class _LikeButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLiked;
  final int likeCount;
  final ModernThemeExtension modernTheme;

  const _LikeButton({
    required this.onPressed,
    required this.isLiked,
    required this.likeCount,
    required this.modernTheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 50,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(
            colors: isLiked 
                ? [
                    const Color(0xFFFF3040),
                    Colors.red.shade400,
                  ]
                : [
                    Colors.grey.shade700,
                    Colors.grey.shade600,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: isLiked 
                  ? Colors.red.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_outline,
                color: Colors.white,
                size: 18,
                shadows: const [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
            if (likeCount > 0)
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: modernTheme.primaryColor ?? Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    _formatCount(likeCount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count == 0) return '0';
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}

// Custom Comments Button Widget with Badge - "..." text design
class _CommentsButton extends StatelessWidget {
  final VoidCallback onPressed;
  final int commentCount;
  final ModernThemeExtension modernTheme;

  const _CommentsButton({
    required this.onPressed,
    required this.commentCount,
    required this.modernTheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 50,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20), // More rounded than others
          gradient: LinearGradient(
            colors: [
              Colors.green.shade500,
              Colors.teal.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Text(
                '...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  height: 0.8, // Reduces vertical spacing
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
            if (commentCount > 0)
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: modernTheme.primaryColor ?? Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    _formatCount(commentCount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count == 0) return '0';
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}
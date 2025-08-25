// lib/features/dramas/widgets/drama_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/dramas/providers/drama_providers.dart';
import 'package:textgb/models/drama_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class DramaCard extends ConsumerWidget {
  final DramaModel drama;
  final VoidCallback onTap;
  final bool showProgress;

  const DramaCard({
    super.key,
    required this.drama,
    required this.onTap,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modernTheme = context.modernTheme;
    final isFavorited = ref.watch(isDramaFavoritedProvider(drama.dramaId));
    final userProgress = ref.watch(dramaUserProgressProvider(drama.dramaId));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: modernTheme.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner image with badges
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Banner image
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: drama.bannerImage.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: drama.bannerImage,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: modernTheme.surfaceVariantColor,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: const Color(0xFFFE2C55),
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: modernTheme.surfaceVariantColor,
                                child: Icon(
                                  Icons.tv,
                                  size: 40,
                                  color: modernTheme.textSecondaryColor,
                                ),
                              ),
                            )
                          : Container(
                              color: modernTheme.surfaceVariantColor,
                              child: Icon(
                                Icons.tv,
                                size: 40,
                                color: modernTheme.textSecondaryColor,
                              ),
                            ),
                    ),
                  ),

                  // Premium badge
                  if (drama.isPremium)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.workspace_premium,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Premium',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Featured badge
                  if (drama.isFeatured)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFE2C55),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  // Favorite indicator
                  if (isFavorited)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  // Progress indicator (if watching)
                  if (showProgress && userProgress > 0)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 4,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                          child: LinearProgressIndicator(
                            value: drama.totalEpisodes > 0 
                                ? userProgress / drama.totalEpisodes 
                                : 0,
                            backgroundColor: Colors.grey.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFFE2C55),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Drama info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Expanded(
                      child: Text(
                        drama.title,
                        style: TextStyle(
                          color: modernTheme.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Stats row
                    Row(
                      children: [
                        // Episode count
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.play_circle_outline,
                                size: 14,
                                color: modernTheme.textSecondaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${drama.totalEpisodes} eps',
                                style: TextStyle(
                                  color: modernTheme.textSecondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // View count
                        Row(
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 14,
                              color: modernTheme.textSecondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatCount(drama.viewCount),
                              style: TextStyle(
                                color: modernTheme.textSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Premium info
                    if (drama.isPremium)
                      Text(
                        drama.premiumInfo,
                        style: TextStyle(
                          color: const Color(0xFFFE2C55),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        'Free Drama',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
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

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}

// Horizontal drama card variant for home screen carousels
class HorizontalDramaCard extends ConsumerWidget {
  final DramaModel drama;
  final VoidCallback onTap;
  final double width;
  final bool showProgress;

  const HorizontalDramaCard({
    super.key,
    required this.drama,
    required this.onTap,
    this.width = 160,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modernTheme = context.modernTheme;
    final isFavorited = ref.watch(isDramaFavoritedProvider(drama.dramaId));
    final userProgress = ref.watch(dramaUserProgressProvider(drama.dramaId));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: modernTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner image
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: drama.bannerImage.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: drama.bannerImage,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: modernTheme.surfaceVariantColor,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFFE2C55),
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: modernTheme.surfaceVariantColor,
                                child: Icon(
                                  Icons.tv,
                                  size: 30,
                                  color: modernTheme.textSecondaryColor,
                                ),
                              ),
                            )
                          : Container(
                              color: modernTheme.surfaceVariantColor,
                              child: Icon(
                                Icons.tv,
                                size: 30,
                                color: modernTheme.textSecondaryColor,
                              ),
                            ),
                    ),
                  ),

                  // Badges
                  if (drama.isPremium)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Premium',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  if (isFavorited)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  // Progress bar
                  if (showProgress && userProgress > 0)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(12),
                          ),
                          child: LinearProgressIndicator(
                            value: drama.totalEpisodes > 0 
                                ? userProgress / drama.totalEpisodes 
                                : 0,
                            backgroundColor: Colors.grey.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFFE2C55),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Drama info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drama.title,
                    style: TextStyle(
                      color: modernTheme.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        size: 12,
                        color: modernTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${drama.totalEpisodes}',
                        style: TextStyle(
                          color: modernTheme.textSecondaryColor,
                          fontSize: 10,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatCount(drama.viewCount),
                        style: TextStyle(
                          color: modernTheme.textSecondaryColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}
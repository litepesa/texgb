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
  final int index;
  final PageController? pageController;

  const DramaCard({
    super.key,
    required this.drama,
    required this.onTap,
    this.showProgress = false,
    this.index = 0,
    this.pageController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modernTheme = context.modernTheme;
    final isFavorited = ref.watch(isDramaFavoritedProvider(drama.dramaId));
    final userProgress = ref.watch(dramaUserProgressProvider(drama.dramaId));

    // Calculate scale based on current page position
    double scale = 1.0;
    if (pageController != null && pageController!.hasClients && pageController!.page != null) {
      scale = 1.0 - ((pageController!.page! - index).abs() * 0.1).clamp(0.0, 0.3);
    }

    return Transform.scale(
      scale: scale,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: modernTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: modernTheme.dividerColor!.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: modernTheme.primaryColor!.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main thumbnail section
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Banner content
                        SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: _buildBannerContent(drama, modernTheme),
                        ),

                        // Premium/Featured badges
                        if (drama.isPremium || drama.isFeatured)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Row(
                              children: [
                                if (drama.isPremium) _buildPremiumBadge(modernTheme),
                                if (drama.isPremium && drama.isFeatured)
                                  const SizedBox(width: 8),
                                if (drama.isFeatured) _buildFeaturedBadge(modernTheme),
                              ],
                            ),
                          ),

                        // Favorite indicator
                        if (isFavorited)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: modernTheme.primaryColor,
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
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),

                        // Progress indicator
                        if (showProgress && userProgress > 0)
                          Positioned(
                            top: 12,
                            right: isFavorited ? 50 : 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: modernTheme.primaryColor,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '$userProgress/${drama.totalEpisodes}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                        // Gradient overlay with views only
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.8),
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_formatCount(drama.viewCount)} views',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Channel-like info section
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Row(
                  children: [
                    // Avatar
                    Stack(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: modernTheme.dividerColor!.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: modernTheme.primaryColor!.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: drama.bannerImage.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: drama.bannerImage,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) => Container(
                                      decoration: BoxDecoration(
                                        color: modernTheme.primaryColor!.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          drama.title.isNotEmpty
                                              ? drama.title[0].toUpperCase()
                                              : "D",
                                          style: TextStyle(
                                            color: modernTheme.primaryColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: modernTheme.primaryColor!.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        drama.title.isNotEmpty
                                            ? drama.title[0].toUpperCase()
                                            : "D",
                                        style: TextStyle(
                                          color: modernTheme.primaryColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 14),

                    // Drama info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            drama.title,
                            style: TextStyle(
                              color: modernTheme.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: modernTheme.surfaceVariantColor!.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: modernTheme.dividerColor!.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  drama.isPremium ? Icons.workspace_premium : Icons.tv,
                                  size: 14,
                                  color: modernTheme.textSecondaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  drama.isPremium ? 'Premium Drama' : 'Free Drama',
                                  style: TextStyle(
                                    color: modernTheme.textSecondaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerContent(DramaModel drama, ModernThemeExtension modernTheme) {
    if (drama.bannerImage.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: drama.bannerImage,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => _buildLoadingBanner(modernTheme),
        errorWidget: (context, url, error) => _buildErrorBanner(modernTheme),
      );
    } else {
      return _buildErrorBanner(modernTheme);
    }
  }

  Widget _buildLoadingBanner(ModernThemeExtension modernTheme) {
    return Container(
      color: modernTheme.surfaceVariantColor,
      child: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            color: modernTheme.primaryColor,
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(ModernThemeExtension modernTheme) {
    return Container(
      color: modernTheme.surfaceVariantColor,
      child: Center(
        child: Icon(
          Icons.tv,
          color: modernTheme.textSecondaryColor,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildPremiumBadge(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: modernTheme.primaryColor,
        borderRadius: BorderRadius.circular(8),
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
          Icon(
            Icons.workspace_premium,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          const Text(
            'Premium',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedBadge(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: modernTheme.primaryColor,
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
    );
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}

// HorizontalDramaCard remains unchanged as it was not specified for modification
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
                      child: SizedBox(
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
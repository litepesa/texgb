// ===============================
// lib/features/videos/widgets/search_result_card.dart
// Individual Search Result Card Widget
// Beautiful card design for video search results
// ===============================

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/videos/models/search_models.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';

class SearchResultCard extends ConsumerWidget {
  final VideoSearchResult searchResult;
  final VoidCallback onTap;
  final bool showRelevance;
  final bool showMatchType;

  const SearchResultCard({
    super.key,
    required this.searchResult,
    required this.onTap,
    this.showRelevance = false,
    this.showMatchType = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final video = searchResult.video;
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video thumbnail with overlay info
            Expanded(
              flex: 3,
              child: _buildThumbnail(video),
            ),
            
            // Video info section
            Expanded(
              flex: 2,
              child: _buildVideoInfo(video, isAuthenticated),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================
  // THUMBNAIL SECTION
  // ===============================

  Widget _buildThumbnail(VideoModel video) {
    return Stack(
      children: [
        // Main thumbnail
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[850],
            child: _buildThumbnailContent(video),
          ),
        ),
        
        // Gradient overlay for better text visibility
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
                stops: const [0.6, 1.0],
              ),
            ),
          ),
        ),
        
        // Top-left overlays
        Positioned(
          top: 8,
          left: 8,
          child: _buildTopLeftOverlays(video),
        ),
        
        // Top-right overlays
        Positioned(
          top: 8,
          right: 8,
          child: _buildTopRightOverlays(video),
        ),
        
        // Bottom overlays
        Positioned(
          bottom: 8,
          left: 8,
          right: 8,
          child: _buildBottomOverlays(video),
        ),
      ],
    );
  }

  Widget _buildThumbnailContent(VideoModel video) {
    if (video.isMultipleImages && video.imageUrls.isNotEmpty) {
      // Show first image for image posts
      return Image.network(
        video.imageUrls.first,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder();
        },
      );
    } else if (video.thumbnailUrl.isNotEmpty) {
      // Show thumbnail for videos
      return Image.network(
        video.thumbnailUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder();
        },
      );
    } else {
      // Fallback placeholder
      return _buildPlaceholder(video);
    }
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.grey[850],
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[850],
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.white54,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildPlaceholder(VideoModel video) {
    return Container(
      color: Colors.grey[850],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              video.isMultipleImages 
                  ? Icons.image 
                  : Icons.play_circle_outline,
              color: Colors.white54,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              video.isMultipleImages ? 'Images' : 'Video',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================
  // OVERLAY COMPONENTS
  // ===============================

  Widget _buildTopLeftOverlays(VideoModel video) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Content type indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                video.isMultipleImages 
                    ? CupertinoIcons.photo 
                    : CupertinoIcons.play_fill,
                color: Colors.white,
                size: 10,
              ),
              const SizedBox(width: 3),
              Text(
                video.isMultipleImages 
                    ? '${video.imageUrls.length}' 
                    : 'Video',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        // Match type indicator (if enabled)
        if (showMatchType) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getMatchTypeColor().withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getMatchTypeDisplay(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTopRightOverlays(VideoModel video) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Verification badge
        if (video.isVerified)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified,
              color: Colors.white,
              size: 12,
            ),
          ),
        
        // Price indicator
        if (video.price > 0) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatPrice(video.price),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        
        // Relevance score (if enabled)
        if (showRelevance) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getRelevanceColor().withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 8,
                ),
                const SizedBox(width: 2),
                Text(
                  '${(searchResult.relevance * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomOverlays(VideoModel video) {
    return Row(
      children: [
        // Views count
        _buildStatChip(
          icon: CupertinoIcons.eye,
          count: video.views,
        ),
        
        const SizedBox(width: 6),
        
        // Likes count
        _buildStatChip(
          icon: CupertinoIcons.heart,
          count: video.likes,
          color: video.isLiked ? Colors.red : null,
        ),
        
        const Spacer(),
        
        // Duration indicator for videos (if available)
        if (!video.isMultipleImages)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '0:15', // Placeholder - would need duration from video
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required int count,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color ?? Colors.white,
            size: 10,
          ),
          const SizedBox(width: 3),
          Text(
            _formatCount(count),
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // VIDEO INFO SECTION
  // ===============================

  Widget _buildVideoInfo(VideoModel video, bool isAuthenticated) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Creator info
          Row(
            children: [
              // Creator avatar
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: video.isVerified ? Colors.blue : Colors.grey[600]!,
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: video.userImage.isNotEmpty
                      ? Image.network(
                          video.userImage,
                          fit: BoxFit.cover,
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildAvatarFallback(video.userName);
                          },
                        )
                      : _buildAvatarFallback(video.userName),
                ),
              ),
              
              const SizedBox(width: 6),
              
              // Creator name with highlight
              Expanded(
                child: Text(
                  searchResult.displayUsername,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Time ago
              Text(
                video.timeAgo,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 9,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 6),
          
          // Video caption with highlight
          Expanded(
            child: Text(
              searchResult.displayCaption,
              style: TextStyle(
                color: Colors.grey[200],
                fontSize: 12,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Bottom stats row
          Row(
            children: [
              // Content tier badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getContentTierColor(video.contentTier),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  video.contentTier,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Engagement stats
              Row(
                children: [
                  Icon(
                    CupertinoIcons.chat_bubble,
                    color: Colors.grey[400],
                    size: 10,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    _formatCount(video.comments),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    CupertinoIcons.share,
                    color: Colors.grey[400],
                    size: 10,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    _formatCount(video.shares),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String userName) {
    return Container(
      color: Colors.grey[700],
      child: Center(
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ===============================
  // HELPER METHODS
  // ===============================

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }

  String _formatPrice(double price) {
    if (price < 1000) {
      return 'KES ${price.toInt()}';
    } else if (price < 1000000) {
      return 'KES ${(price / 1000).toStringAsFixed(1)}K';
    } else {
      return 'KES ${(price / 1000000).toStringAsFixed(1)}M';
    }
  }

  Color _getMatchTypeColor() {
    switch (searchResult.matchType.toLowerCase()) {
      case 'caption':
        return Colors.blue;
      case 'username':
        return Colors.green;
      case 'tag':
        return Colors.orange;
      case 'fulltext':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getMatchTypeDisplay() {
    switch (searchResult.matchType.toLowerCase()) {
      case 'caption':
        return 'Caption';
      case 'username':
        return 'Creator';
      case 'tag':
        return 'Tag';
      case 'fulltext':
        return 'Text';
      default:
        return 'Match';
    }
  }

  Color _getRelevanceColor() {
    if (searchResult.isHighRelevance) {
      return Colors.green;
    } else if (searchResult.isMediumRelevance) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Color _getContentTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'premium+':
        return Colors.purple;
      case 'premium':
        return Colors.blue;
      case 'featured':
        return Colors.orange;
      case 'popular':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

// ===============================
// SEARCH RESULT CARD VARIANTS
// ===============================

/// Compact version for smaller screens or dense layouts
class CompactSearchResultCard extends ConsumerWidget {
  final VideoSearchResult searchResult;
  final VoidCallback onTap;

  const CompactSearchResultCard({
    super.key,
    required this.searchResult,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final video = searchResult.video;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[800]!, width: 1),
        ),
        child: Row(
          children: [
            // Compact thumbnail
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: video.thumbnailUrl.isNotEmpty
                    ? Image.network(
                        video.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.play_circle_outline,
                            color: Colors.white54,
                            size: 24,
                          );
                        },
                      )
                    : const Icon(
                        Icons.play_circle_outline,
                        color: Colors.white54,
                        size: 24,
                      ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Content info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Creator and time
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          video.userName,
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        video.timeAgo,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Caption
                  Expanded(
                    child: Text(
                      video.caption,
                      style: TextStyle(
                        color: Colors.grey[200],
                        fontSize: 11,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Stats
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.eye,
                        color: Colors.grey[400],
                        size: 10,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _formatCount(video.views),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        CupertinoIcons.heart,
                        color: Colors.grey[400],
                        size: 10,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _formatCount(video.likes),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 9,
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
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}
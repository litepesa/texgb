// lib/features/moments/widgets/moment_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/screens/media_viewer_screen.dart';
import 'package:textgb/features/moments/screens/moment_detail_screen.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'dart:io';
import 'dart:typed_data';

class MomentCard extends StatefulWidget {
  final MomentModel moment;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onView;
  final VoidCallback? onDelete;

  const MomentCard({
    super.key,
    required this.moment,
    required this.onLike,
    required this.onComment,
    required this.onView,
    this.onDelete,
  });

  @override
  State<MomentCard> createState() => _MomentCardState();
}

class _MomentCardState extends State<MomentCard> with TickerProviderStateMixin {
  bool _hasViewed = false;
  Uint8List? _videoThumbnail;
  bool _isLoadingThumbnail = false;
  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;

  // Premium color palette - Sophisticated blues and greens
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF7F8FC);
  static const Color softGray = Color(0xFFEFF1F6);
  static const Color textPrimary = Color(0xFF1A1D29);
  static const Color textSecondary = Color(0xFF5A6175);
  static const Color textTertiary = Color(0xFF9BA3B4);
  static const Color premiumBlue = Color(0xFF2563EB);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color premiumGreen = Color(0xFF059669);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentRed = Color(0xFFDC2626);
  static const Color premiumRed = Color(0xFFEF4444);
  static const Color dividerColor = Color(0xFFE2E5EA);
  static const Color shadowColor = Color(0x08000000);

  @override
  void initState() {
    super.initState();
    
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _likeAnimationController, curve: Curves.easeInOut),
    );
    
    // Add view after a short delay to simulate viewing
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_hasViewed && mounted) {
        widget.onView();
        _hasViewed = true;
      }
    });

    // Generate video thumbnail if it's a video moment
    if (widget.moment.hasVideo && widget.moment.mediaUrls.isNotEmpty) {
      _generateVideoThumbnail();
    }
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  Future<void> _generateVideoThumbnail() async {
    if (_isLoadingThumbnail) return;
    
    setState(() => _isLoadingThumbnail = true);
    
    try {
      final thumbnailData = await VideoThumbnail.thumbnailData(
        video: widget.moment.mediaUrls.first,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 400,
        quality: 75,
      );
      
      if (mounted && thumbnailData != null) {
        setState(() {
          _videoThumbnail = thumbnailData;
          _isLoadingThumbnail = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingThumbnail = false);
      }
      debugPrint('Error generating video thumbnail: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: const BoxDecoration(
        color: primaryWhite,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (widget.moment.content.isNotEmpty) _buildContent(),
          if (widget.moment.hasMedia) _buildMedia(),
          _buildActions(),
          if (widget.moment.likesCount > 0) _buildLikesCount(),
          _buildTimeStamp(),
          _buildDivider(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateToMomentDetail(),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: userImageWidget(
                imageUrl: widget.moment.authorImage,
                radius: 22,
                onTap: () {},
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToMomentDetail(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.moment.authorName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _formatTime(widget.moment.createdAt),
                        style: const TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getPrivacyColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getPrivacyIcon(),
                              size: 11,
                              color: _getPrivacyColor(),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.moment.privacy.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                color: _getPrivacyColor(),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (widget.onDelete != null)
            GestureDetector(
              onTap: () => _showMoreOptions(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: softGray,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.more_horiz_rounded,
                  color: textSecondary,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return GestureDetector(
      onTap: () => _navigateToMomentDetail(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          widget.moment.content,
          style: const TextStyle(
            fontSize: 15,
            color: textPrimary,
            height: 1.5,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }

  Widget _buildMedia() {
    if (widget.moment.hasImages) {
      return _buildImageMedia();
    } else if (widget.moment.hasVideo) {
      return _buildVideoMedia();
    }
    return const SizedBox.shrink();
  }

  Widget _buildImageMedia() {
    final images = widget.moment.mediaUrls;
    final imageCount = images.length;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: _buildImageGrid(images, imageCount),
    );
  }

  Widget _buildImageGrid(List<String> images, int count) {
    if (count == 1) {
      return _buildSingleImage(images[0], 0);
    } else if (count == 2) {
      return _buildTwoImages(images);
    } else if (count <= 4) {
      return _buildFourImages(images);
    } else {
      return _buildNineImages(images);
    }
  }

  Widget _buildSingleImage(String imageUrl, int index) {
    return GestureDetector(
      onTap: () => _openMediaViewer(index),
      child: Container(
        height: 320,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Hero(
          tag: 'moment_${widget.moment.momentId}_image_$index',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: softGray,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: premiumBlue,
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: softGray,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: textTertiary,
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Failed to load',
                        style: TextStyle(
                          color: textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTwoImages(List<String> images) {
    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildImageItem(images[0], 0),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildImageItem(images[1], 1),
          ),
        ],
      ),
    );
  }

  Widget _buildFourImages(List<String> images) {
    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildImageItem(images[0], 0)),
                const SizedBox(width: 4),
                Expanded(child: _buildImageItem(images[1], 1)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: images.length > 2 
                      ? _buildImageItem(images[2], 2)
                      : const SizedBox.shrink(),
                ),
                if (images.length > 3) const SizedBox(width: 4),
                if (images.length > 3)
                  Expanded(child: _buildImageItem(images[3], 3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNineImages(List<String> images) {
    return Container(
      height: 300,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildImageItem(images[0], 0)),
                const SizedBox(width: 4),
                Expanded(child: _buildImageItem(images[1], 1)),
                const SizedBox(width: 4),
                Expanded(child: _buildImageItem(images[2], 2)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: images.length > 3 
                      ? _buildImageItem(images[3], 3)
                      : const SizedBox.shrink(),
                ),
                if (images.length > 4) const SizedBox(width: 4),
                if (images.length > 4)
                  Expanded(child: _buildImageItem(images[4], 4)),
                if (images.length > 5) const SizedBox(width: 4),
                if (images.length > 5)
                  Expanded(child: _buildImageItem(images[5], 5)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: images.length > 6 
                      ? _buildImageItem(images[6], 6)
                      : const SizedBox.shrink(),
                ),
                if (images.length > 7) const SizedBox(width: 4),
                if (images.length > 7)
                  Expanded(child: _buildImageItem(images[7], 7)),
                if (images.length > 8) const SizedBox(width: 4),
                if (images.length > 8)
                  Expanded(
                    child: Stack(
                      children: [
                        _buildImageItem(images[8], 8),
                        if (images.length > 9)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '+${images.length - 9}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
    );
  }

  Widget _buildImageItem(String imageUrl, int index) {
    return GestureDetector(
      onTap: () => _openMediaViewer(index),
      child: Hero(
        tag: 'moment_${widget.moment.momentId}_image_$index',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: softGray,
              child: const Center(
                child: CircularProgressIndicator(
                  color: accentBlue,
                  strokeWidth: 2,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: softGray,
              child: const Icon(
                Icons.error_outline_rounded,
                color: textTertiary,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoMedia() {
    return GestureDetector(
      onTap: () => _openMediaViewer(0),
      child: Container(
        height: 320,
        margin: const EdgeInsets.only(top: 16, left: 20, right: 20),
        child: Hero(
          tag: 'moment_${widget.moment.momentId}_video_0',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Video thumbnail or placeholder
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: _videoThumbnail != null
                      ? Image.memory(
                          _videoThumbnail!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: textPrimary,
                          child: _isLoadingThumbnail
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.videocam_rounded,
                                    size: 48,
                                    color: Colors.white54,
                                  ),
                                ),
                        ),
                ),
                
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
                
                // Play button overlay
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                // Video indicator
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Video',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildActions() {
    final isLiked = widget.moment.likedBy.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _likeAnimationController.forward().then((_) {
                _likeAnimationController.reverse();
              });
              widget.onLike();
            },
            child: AnimatedBuilder(
              animation: _likeScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _likeScaleAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isLiked ? premiumRed.withOpacity(0.1) : softGray,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                          color: isLiked ? premiumRed : textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Like',
                          style: TextStyle(
                            color: isLiked ? premiumRed : textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onComment();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: softGray,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: textSecondary,
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Comment',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _navigateToMomentDetail(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: softGray,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    color: textSecondary,
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'View',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (widget.moment.viewsCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: softGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.visibility_outlined,
                    color: textTertiary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.moment.viewsCount}',
                    style: const TextStyle(
                      color: textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLikesCount() {
    if (widget.moment.likesCount == 0) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        '${widget.moment.likesCount} ${widget.moment.likesCount == 1 ? 'like' : 'likes'}',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
    );
  }

  Widget _buildTimeStamp() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Text(
        _formatDetailedTime(widget.moment.createdAt),
        style: const TextStyle(
          fontSize: 12,
          color: textTertiary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 8,
      color: backgroundGray, // Subtle gray separator between moments
    );
  }

  void _openMediaViewer(int index) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => MediaViewerScreen(
          mediaUrls: widget.moment.mediaUrls,
          initialIndex: index,
          mediaType: widget.moment.mediaType,
          authorName: widget.moment.authorName,
          createdAt: widget.moment.createdAt,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
        opaque: false,
      ),
    );
  }

  void _navigateToMomentDetail() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MomentDetailScreen(moment: widget.moment),
      ),
    );
  }

  void _showMoreOptions() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: primaryWhite,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (widget.onDelete != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                ),
                title: const Text(
                  'Delete Moment',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDelete!();
                },
              ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: premiumBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.share_rounded, color: premiumBlue, size: 20),
              ),
              title: const Text(
                'Share Moment',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                // Implement share functionality
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.report_outlined, color: Colors.orange, size: 20),
              ),
              title: const Text(
                'Report',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                // Implement report functionality
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Color _getPrivacyColor() {
    switch (widget.moment.privacy) {
      case MomentPrivacy.allContacts:
        return accentGreen;
      case MomentPrivacy.onlyMe:
        return Colors.orange;
      case MomentPrivacy.customList:
        return premiumBlue;
    }
  }

  IconData _getPrivacyIcon() {
    switch (widget.moment.privacy) {
      case MomentPrivacy.allContacts:
        return Icons.people_rounded;
      case MomentPrivacy.onlyMe:
        return Icons.lock_rounded;
      case MomentPrivacy.customList:
        return Icons.group_rounded;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatDetailedTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        if (difference.inMinutes < 1) {
          return 'Just now';
        }
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
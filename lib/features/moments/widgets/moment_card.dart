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
  late AnimationController _cardAnimationController;
  late Animation<double> _likeScaleAnimation;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;

  // Facebook 2025 Color System - Modern & Fresh
  static const Color fbBlue = Color(0xFF1877F2);
  static const Color fbBlueLight = Color(0xFF42A5F5);
  static const Color fbGreen = Color(0xFF00A400);
  static const Color fbRed = Color(0xFFE41E3F);
  static const Color fbOrange = Color(0xFFFF7043);
  
  // Neutral System (Facebook's 2025 palette)
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF0F2F5); // Facebook's new bg
  static const Color surfaceVariant = Color(0xFFF7F8FA);
  static const Color outline = Color(0xFFDADDE1);
  static const Color outlineVariant = Color(0xFFE4E6EA);
  
  // Text System
  static const Color onSurface = Color(0xFF1C1E21);
  static const Color onSurfaceVariant = Color(0xFF65676B);
  static const Color onSurfaceSecondary = Color(0xFF8A8D91);
  static const Color onSurfaceTertiary = Color(0xFFBCC0C4);
  
  // Interactive colors
  static const Color likeRed = Color(0xFFE41E3F);
  static const Color commentBlue = Color(0xFF1877F2);
  static const Color shareGreen = Color(0xFF00A400);

  @override
  void initState() {
    super.initState();
    
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _likeAnimationController, curve: Curves.elasticOut),
    );
    
    _cardSlideAnimation = Tween<double>(begin: 15.0, end: 0.0).animate(
      CurvedAnimation(parent: _cardAnimationController, curve: Curves.easeOutQuart),
    );
    
    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardAnimationController, curve: Curves.easeOut),
    );
    
    _cardAnimationController.forward();
    
    // Add view after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_hasViewed && mounted) {
        widget.onView();
        _hasViewed = true;
      }
    });

    // Generate video thumbnail if needed
    if (widget.moment.hasVideo && widget.moment.mediaUrls.isNotEmpty) {
      _generateVideoThumbnail();
    }
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _cardAnimationController.dispose();
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
        quality: 85,
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
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _cardSlideAnimation.value),
          child: FadeTransition(
            opacity: _cardFadeAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: const BoxDecoration(
                color: surface,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  if (widget.moment.content.isNotEmpty) _buildContent(),
                  if (widget.moment.hasMedia) _buildFullWidthMedia(),
                  _buildActionBar(),
                  if (widget.moment.likesCount > 0) _buildEngagementStats(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateToMomentDetail(),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: fbBlue.withOpacity(0.15),
                  width: 2,
                ),
              ),
              child: userImageWidget(
                imageUrl: widget.moment.authorImage,
                radius: 20,
                onTap: () {},
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.moment.authorName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPrivacyColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPrivacyIcon(),
                            size: 10,
                            color: _getPrivacyColor(),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            widget.moment.privacy.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              color: _getPrivacyColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(widget.moment.createdAt),
                  style: const TextStyle(
                    fontSize: 13,
                    color: onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showMoreOptions(),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.more_horiz_rounded,
                color: onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        widget.moment.content,
        style: const TextStyle(
          fontSize: 16,
          color: onSurface,
          height: 1.4,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildFullWidthMedia() {
    if (widget.moment.hasImages) {
      return _buildFullWidthImages();
    } else if (widget.moment.hasVideo) {
      return _buildFullWidthVideo();
    }
    return const SizedBox.shrink();
  }

  Widget _buildFullWidthImages() {
    final images = widget.moment.mediaUrls;
    final count = images.length;

    if (count == 1) {
      return _buildSingleFullWidthImage(images[0], 0);
    } else {
      return _buildMultipleImagesGrid(images);
    }
  }

  Widget _buildSingleFullWidthImage(String imageUrl, int index) {
    return GestureDetector(
      onTap: () => _openMediaViewer(index),
      child: Hero(
        tag: 'moment_${widget.moment.momentId}_image_$index',
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: 200,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 300,
              color: surfaceVariant,
              child: Center(
                child: CircularProgressIndicator(
                  color: fbBlue,
                  strokeWidth: 2.5,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 300,
              color: surfaceVariant,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: onSurfaceSecondary,
                      size: 36,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Unable to load image',
                      style: TextStyle(
                        color: onSurfaceSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultipleImagesGrid(List<String> images) {
    final count = images.length;
    
    if (count == 2) {
      return _buildTwoImagesLayout(images);
    } else if (count == 3) {
      return _buildThreeImagesLayout(images);
    } else {
      return _buildFourPlusImagesLayout(images);
    }
  }

  Widget _buildTwoImagesLayout(List<String> images) {
    return Container(
      height: 250,
      child: Row(
        children: [
          Expanded(
            child: _buildGridImageItem(images[0], 0),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: _buildGridImageItem(images[1], 1),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeImagesLayout(List<String> images) {
    return Container(
      height: 250,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildGridImageItem(images[0], 0),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _buildGridImageItem(images[1], 1),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: _buildGridImageItem(images[2], 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFourPlusImagesLayout(List<String> images) {
    return Container(
      height: 300,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildGridImageItem(images[0], 0),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: _buildGridImageItem(images[1], 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildGridImageItem(images[2], 2),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Stack(
                    children: [
                      _buildGridImageItem(images[3], 3),
                      if (images.length > 4)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                          ),
                          child: Center(
                            child: Text(
                              '+${images.length - 4}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
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

  Widget _buildGridImageItem(String imageUrl, int index) {
    return GestureDetector(
      onTap: () => _openMediaViewer(index),
      child: Hero(
        tag: 'moment_${widget.moment.momentId}_image_$index',
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => Container(
            color: surfaceVariant,
            child: Center(
              child: CircularProgressIndicator(
                color: fbBlue,
                strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: surfaceVariant,
            child: const Icon(
              Icons.error_outline_rounded,
              color: onSurfaceSecondary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullWidthVideo() {
    return GestureDetector(
      onTap: () => _openMediaViewer(0),
      child: Hero(
        tag: 'moment_${widget.moment.momentId}_video_0',
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.6, // Full vertical space like Facebook
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                child: _videoThumbnail != null
                    ? Image.memory(
                        _videoThumbnail!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black87,
                              Colors.black54,
                            ],
                          ),
                        ),
                        child: _isLoadingThumbnail
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.videocam_rounded,
                                  size: 64,
                                  color: Colors.white60,
                                ),
                              ),
                      ),
              ),
              
              // Gradient overlay for better readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
              
              // Modern play button like Facebook Reels
              Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 36,
                    color: onSurface,
                  ),
                ),
              ),
              
              // Video indicator badge
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_circle_rounded,
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
    );
  }

  Widget _buildActionBar() {
    final isLiked = widget.moment.likedBy.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
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
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                          color: isLiked ? likeRed : onSurfaceVariant,
                          size: 22,
                        ),
                        if (widget.moment.likesCount > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${widget.moment.likesCount}',
                            style: TextStyle(
                              color: isLiked ? likeRed : onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(width: 8),
          
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onComment();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: onSurfaceVariant,
                size: 22,
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          GestureDetector(
            onTap: () => _shareMoment(),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.share_outlined,
                color: onSurfaceVariant,
                size: 22,
              ),
            ),
          ),
          
          const Spacer(),
          
          if (widget.moment.viewsCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.visibility_outlined,
                    color: onSurfaceSecondary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.moment.viewsCount}',
                    style: const TextStyle(
                      color: onSurfaceSecondary,
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

  Widget _buildEngagementStats() {
    if (widget.moment.likesCount == 0) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        _formatLikesText(widget.moment.likesCount),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: onSurfaceVariant,
        ),
      ),
    );
  }

  String _formatLikesText(int count) {
    if (count == 1) return '1 like';
    if (count < 1000) return '$count likes';
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K likes';
    return '${(count / 1000000).toStringAsFixed(1)}M likes';
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
          color: surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
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
                color: outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (widget.onDelete != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: fbRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.delete_outline_rounded, color: fbRed, size: 20),
                ),
                title: Text(
                  'Delete moment',
                  style: TextStyle(color: fbRed, fontWeight: FontWeight.w600),
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
                  color: fbBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.share_rounded, color: fbBlue, size: 20),
              ),
              title: const Text(
                'Share moment',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                _shareMoment();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: fbOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.report_outlined, color: fbOrange, size: 20),
              ),
              title: const Text(
                'Report',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                _reportMoment();
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  void _shareMoment() {
    showSnackBar(context, 'Share functionality coming soon');
  }

  void _reportMoment() {
    showSnackBar(context, 'Moment reported');
  }

  Color _getPrivacyColor() {
    switch (widget.moment.privacy) {
      case MomentPrivacy.allContacts:
        return fbGreen;
      case MomentPrivacy.onlyMe:
        return fbOrange;
      case MomentPrivacy.customList:
        return fbBlue;
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
}
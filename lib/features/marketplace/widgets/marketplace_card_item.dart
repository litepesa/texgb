// lib/features/marketplace/widgets/marketplace_card_item.dart
// Facebook-style card widget for marketplace items

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:textgb/features/marketplace/models/marketplace_video_model.dart';
import 'package:textgb/features/marketplace/providers/marketplace_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/authentication/widgets/login_required_widget.dart';
import 'package:textgb/features/marketplace/services/marketplace_cache_service.dart';
import 'package:textgb/features/marketplace/widgets/marketplace_comments_bottom_sheet.dart';
import 'package:textgb/features/marketplace/widgets/marketplace_reaction_input.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/chat/screens/chat_screen.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/core/router/route_paths.dart';

class MarketplaceCardItem extends ConsumerStatefulWidget {
  final MarketplaceVideoModel item;
  final VoidCallback? onCommentsPressed;
  final VoidCallback? onDirectMessagePressed;

  const MarketplaceCardItem({
    super.key,
    required this.item,
    this.onCommentsPressed,
    this.onDirectMessagePressed,
  });

  @override
  ConsumerState<MarketplaceCardItem> createState() => _MarketplaceCardItemState();
}

class _MarketplaceCardItemState extends ConsumerState<MarketplaceCardItem> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoVisible = false;
  int _currentImageIndex = 0;
  bool _showFullCaption = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.isVideoContent) {
      _initializeVideo();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    if (widget.item.videoUrl.isEmpty) return;

    try {
      final cachedUri = MarketplaceCacheService().getLocalUri(widget.item.videoUrl);
      _videoController = VideoPlayerController.networkUrl(
        cachedUri,
        videoPlayerOptions: VideoPlayerOptions(
          allowBackgroundPlayback: false,
          mixWithOthers: true,
        ),
      );

      await _videoController!.initialize();
      _videoController!.setLooping(true);

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });

        // Auto-play if visible
        if (_isVideoVisible) {
          _videoController!.play();
        }
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    final isVisible = info.visibleFraction > 0.5;

    if (isVisible != _isVideoVisible) {
      setState(() {
        _isVideoVisible = isVisible;
      });

      if (widget.item.isVideoContent && _isVideoInitialized) {
        if (isVisible) {
          _videoController?.play();
        } else {
          _videoController?.pause();
        }
      }
    }
  }

  Future<bool> _requireAuthentication(String actionName) async {
    final isAuthenticated = ref.read(isAuthenticatedProvider);

    if (!isAuthenticated) {
      final result = await requireLogin(
        context,
        ref,
        customTitle: 'Sign In Required',
        customSubtitle: 'Please sign in to $actionName.',
        customActionText: 'Sign In',
        customIcon: _getIconForAction(actionName),
      );
      return result;
    }

    return true;
  }

  IconData _getIconForAction(String actionName) {
    switch (actionName.toLowerCase()) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'send messages':
        return Icons.message;
      default:
        return Icons.shopping_bag;
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleLike() async {
    final canInteract = await _requireAuthentication('like');
    if (!canInteract) return;

    final marketplaceNotifier = ref.read(marketplaceProvider.notifier);
    marketplaceNotifier.likeMarketplaceVideo(widget.item.id);
  }

  Future<void> _handleComment() async {
    final canInteract = await _requireAuthentication('comment');
    if (!canInteract) return;

    if (widget.onCommentsPressed != null) {
      widget.onCommentsPressed!();
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => MarketplaceCommentsBottomSheet(
          marketplaceVideo: widget.item,
          onClose: () {},
        ),
      );
    }
  }

  Future<void> _handleDirectMessage() async {
    final canInteract = await _requireAuthentication('send messages');
    if (!canInteract) return;

    final currentUser = ref.read(currentUserProvider);

    // Check if trying to message own listing
    if (widget.item.userId == currentUser!.uid) {
      _showSnackBar('You cannot message your own listing');
      return;
    }

    if (widget.onDirectMessagePressed != null) {
      widget.onDirectMessagePressed!();
    } else {
      // Show marketplace reaction input
      final reaction = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => MarketplaceReactionInput(
          listing: widget.item,
          onSendReaction: (reaction) => Navigator.pop(context, reaction),
          onCancel: () => Navigator.pop(context),
        ),
      );

      if (reaction != null && reaction.trim().isNotEmpty && mounted) {
        try {
          final chatNotifier = ref.read(chatListProvider.notifier);

          final chatId = await chatNotifier.createChatWithVideoReaction(
            otherUserId: widget.item.userId,
            videoId: widget.item.id,
            videoUrl: widget.item.videoUrl,
            thumbnailUrl: widget.item.thumbnailUrl.isNotEmpty
                ? widget.item.thumbnailUrl
                : (widget.item.isMultipleImages && widget.item.imageUrls.isNotEmpty
                    ? widget.item.imageUrls.first
                    : ''),
            userName: widget.item.userName,
            userImage: widget.item.userImage,
            reaction: reaction,
          );

          if (chatId != null && mounted) {
            final authNotifier = ref.read(authenticationProvider.notifier);
            final listingOwner = await authNotifier.getUserById(widget.item.userId);

            final contact = listingOwner ?? UserModel.fromMap({
              'uid': widget.item.userId,
              'name': widget.item.userName,
              'profileImage': widget.item.userImage,
            });

            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatId: chatId,
                    contact: contact,
                  ),
                ),
              );
            }
          } else {
            _showSnackBar('Failed to send message. Please try again.');
          }
        } catch (e) {
          debugPrint('Error sending marketplace message: $e');
          _showSnackBar('Failed to send message. Please try again.');
        }
      }
    }
  }

  String _getRelativeTime() {
    try {
      final now = DateTime.now();
      final videoTime = DateTime.parse(widget.item.createdAt);
      final difference = now.difference(videoTime);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d';
      } else {
        return '${(difference.inDays / 7).floor()}w';
      }
    } catch (e) {
      return '';
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('marketplace-card-${widget.item.id}'),
      onVisibilityChanged: _handleVisibilityChanged,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        elevation: 0,
        color: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildContent(),
            _buildActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  context.push(RoutePaths.userProfile(widget.item.userId));
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: widget.item.userImage.isNotEmpty
                      ? NetworkImage(widget.item.userImage)
                      : null,
                  child: widget.item.userImage.isEmpty
                      ? Text(
                          widget.item.userName.isNotEmpty
                              ? widget.item.userName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username on own line
                    Text(
                      widget.item.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    // Timestamp
                    Text(
                      _getRelativeTime(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.black54),
                onPressed: () {
                  // TODO: Show options menu
                },
              ),
            ],
          ),
          // Caption on separate line
          if (widget.item.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showFullCaption = !_showFullCaption;
                  });
                },
                child: Text(
                  widget.item.caption,
                  maxLines: _showFullCaption ? null : 3,
                  overflow: _showFullCaption ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          // Tags if any
          if (widget.item.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.item.tags.map((tag) => '#$tag').join(' '),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue[700],
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (widget.item.isMultipleImages) {
      return _buildImageCarousel();
    } else {
      return _buildVideoPlayer();
    }
  }

  Widget _buildImageCarousel() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final safePadding = MediaQuery.of(context).padding;

    // Reserve space for: header ~100, actions ~50, card margin 16, safe areas, bottom nav ~80
    final otherElementsHeight = 166.0 + safePadding.top + safePadding.bottom + 80.0 + 38.0;
    final maxImageHeight = screenHeight - otherElementsHeight;

    // For images, use 4:3 aspect ratio (standard social media)
    final calculatedHeight = screenWidth * 0.75;
    final imageHeight = calculatedHeight > maxImageHeight ? maxImageHeight : calculatedHeight;

    return ClipRect(
      child: SizedBox(
        width: double.infinity,
        height: imageHeight,
        child: Stack(
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: imageHeight,
                viewportFraction: 1.0,
                enableInfiniteScroll: widget.item.imageUrls.length > 1,
                autoPlay: false,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
              ),
              items: widget.item.imageUrls.map((imageUrl) {
                return Container(
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
            if (widget.item.imageUrls.length > 1)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.item.imageUrls.length,
                    (index) => Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.item.price > 0) _buildPriceBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final safePadding = MediaQuery.of(context).padding;

    // Reserve space for: header ~100, actions ~50, card margin 16, safe areas, bottom nav ~80
    final otherElementsHeight = 166.0 + safePadding.top + safePadding.bottom + 80.0 + 38.0;
    final maxVideoHeight = screenHeight - otherElementsHeight;

    double videoHeight;

    if (_isVideoInitialized) {
      final aspectRatio = _videoController!.value.aspectRatio;

      if (aspectRatio < 0.8) {
        // Vertical video (TikTok-style 9:16 or similar)
        // Constrain to available space so full card is visible
        final calculatedHeight = screenWidth / aspectRatio;
        videoHeight = calculatedHeight > maxVideoHeight ? maxVideoHeight : calculatedHeight;
      } else if (aspectRatio > 1.5) {
        // Horizontal video (landscape)
        // Use 16:9 aspect ratio
        videoHeight = screenWidth * 0.5625; // 9/16
      } else {
        // Square-ish video (1:1 or close)
        final calculatedHeight = screenWidth;
        videoHeight = calculatedHeight > maxVideoHeight ? maxVideoHeight : calculatedHeight;
      }
    } else {
      // Default height while loading
      videoHeight = maxVideoHeight;
    }

    return ClipRect(
      child: SizedBox(
        width: double.infinity,
        height: videoHeight,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: videoHeight,
              color: Colors.black,
              child: _isVideoInitialized
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
            ),
            if (_isVideoInitialized && !(_videoController?.value.isPlaying ?? false))
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  if (_isVideoInitialized) {
                    setState(() {
                      if (_videoController!.value.isPlaying) {
                        _videoController!.pause();
                      } else {
                        _videoController!.play();
                      }
                    });
                  }
                },
              ),
            ),
            if (widget.item.price > 0) _buildPriceBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBadge() {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green[600],
          borderRadius: BorderRadius.circular(20),
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
              Icons.local_offer,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              widget.item.formattedPrice,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          // Left: Like button
          _buildFacebookActionButton(
            icon: widget.item.isLiked == true
                ? Icons.thumb_up
                : Icons.thumb_up_outlined,
            label: 'Like',
            isActive: widget.item.isLiked == true,
            onTap: _handleLike,
          ),

          const Spacer(),

          // Center: Comment button
          _buildFacebookActionButton(
            icon: Icons.chat_bubble_outline,
            label: 'Comment',
            isActive: false,
            onTap: _handleComment,
          ),

          const Spacer(),

          // Right: Inbox button
          _buildFacebookActionButton(
            icon: Icons.send_outlined,
            label: 'Inbox',
            isActive: false,
            onTap: _handleDirectMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildFacebookActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.blue[600] : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.blue[600] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

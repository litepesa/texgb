// lib/features/moments/widgets/moment_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

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

class _MomentCardState extends State<MomentCard> {
  bool _hasViewed = false;

  @override
  void initState() {
    super.initState();
    // Add view after a short delay to simulate viewing
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_hasViewed && mounted) {
        widget.onView();
        _hasViewed = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF0F0F0),
            width: 1,
          ),
        ),
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
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          userImageWidget(
            imageUrl: widget.moment.authorImage,
            radius: 20,
            onTap: () {}, // Could navigate to user profile
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.moment.authorName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1D),
                  ),
                ),
                Text(
                  _formatTime(widget.moment.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
          if (widget.onDelete != null)
            GestureDetector(
              onTap: () => _showMoreOptions(),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.more_horiz,
                  color: Color(0xFF9E9E9E),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        widget.moment.content,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF1D1D1D),
          height: 1.4,
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
      margin: const EdgeInsets.only(top: 12),
      child: _buildImageGrid(images, imageCount),
    );
  }

  Widget _buildImageGrid(List<String> images, int count) {
    if (count == 1) {
      return _buildSingleImage(images[0]);
    } else if (count == 2) {
      return _buildTwoImages(images);
    } else if (count <= 4) {
      return _buildFourImages(images);
    } else {
      return _buildNineImages(images);
    }
  }

  Widget _buildSingleImage(String imageUrl) {
    return Container(
      height: 300,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: const Color(0xFFF8F8F8),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1D1D1D),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: const Color(0xFFF8F8F8),
            child: const Icon(
              Icons.error_outline,
              color: Color(0xFF9E9E9E),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTwoImages(List<String> images) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildImageItem(images[0]),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: _buildImageItem(images[1]),
          ),
        ],
      ),
    );
  }

  Widget _buildFourImages(List<String> images) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildImageItem(images[0])),
                const SizedBox(width: 2),
                Expanded(child: _buildImageItem(images[1])),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: images.length > 2 
                      ? _buildImageItem(images[2])
                      : const SizedBox.shrink(),
                ),
                if (images.length > 3) const SizedBox(width: 2),
                if (images.length > 3)
                  Expanded(child: _buildImageItem(images[3])),
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildImageItem(images[0])),
                const SizedBox(width: 2),
                Expanded(child: _buildImageItem(images[1])),
                const SizedBox(width: 2),
                Expanded(child: _buildImageItem(images[2])),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: images.length > 3 
                      ? _buildImageItem(images[3])
                      : const SizedBox.shrink(),
                ),
                if (images.length > 4) const SizedBox(width: 2),
                if (images.length > 4)
                  Expanded(child: _buildImageItem(images[4])),
                if (images.length > 5) const SizedBox(width: 2),
                if (images.length > 5)
                  Expanded(child: _buildImageItem(images[5])),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: images.length > 6 
                      ? _buildImageItem(images[6])
                      : const SizedBox.shrink(),
                ),
                if (images.length > 7) const SizedBox(width: 2),
                if (images.length > 7)
                  Expanded(child: _buildImageItem(images[7])),
                if (images.length > 8) const SizedBox(width: 2),
                if (images.length > 8)
                  Expanded(
                    child: Stack(
                      children: [
                        _buildImageItem(images[8]),
                        if (images.length > 9)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '+${images.length - 9}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
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

  Widget _buildImageItem(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: const Color(0xFFF8F8F8),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF1D1D1D),
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: const Color(0xFFF8F8F8),
          child: const Icon(
            Icons.error_outline,
            color: Color(0xFF9E9E9E),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoMedia() {
    return Container(
      height: 300,
      margin: const EdgeInsets.only(top: 12, left: 16, right: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Container(
              color: const Color(0xFF1D1D1D),
              child: const Center(
                child: Icon(
                  Icons.play_circle_filled,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.videocam,
                      color: Colors.white,
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Video',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
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

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onLike,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.moment.likedBy.isNotEmpty
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: widget.moment.likedBy.isNotEmpty
                      ? Colors.red
                      : const Color(0xFF9E9E9E),
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  'Like',
                  style: TextStyle(
                    color: widget.moment.likedBy.isNotEmpty
                        ? Colors.red
                        : const Color(0xFF9E9E9E),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          GestureDetector(
            onTap: widget.onComment,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFF9E9E9E),
                  size: 20,
                ),
                SizedBox(width: 4),
                Text(
                  'Comment',
                  style: TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (widget.moment.viewsCount > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.visibility,
                  color: Color(0xFF9E9E9E),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.moment.viewsCount}',
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLikesCount() {
    if (widget.moment.likesCount == 0) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        '${widget.moment.likesCount} ${widget.moment.likesCount == 1 ? 'like' : 'likes'}',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1D1D1D),
        ),
      ),
    );
  }

  Widget _buildTimeStamp() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Text(
        _formatDetailedTime(widget.moment.createdAt),
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF9E9E9E),
        ),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (widget.onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Moment',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDelete!();
                },
              ),
          ],
        ),
      ),
    );
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
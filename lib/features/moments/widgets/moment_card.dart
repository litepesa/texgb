// lib/features/moments/widgets/moment_card.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/providers/moments_provider.dart';
import 'package:textgb/features/moments/widgets/moment_image_viewer.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';
import 'package:timeago/timeago.dart' as timeago;

class MomentCard extends ConsumerStatefulWidget {
  final MomentModel moment;
  final UserModel currentUser;

  const MomentCard({
    super.key,
    required this.moment,
    required this.currentUser,
  });

  @override
  ConsumerState<MomentCard> createState() => _MomentCardState();
}

class _MomentCardState extends ConsumerState<MomentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _likeAnimation;
  bool _showComments = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _likeAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _toggleLike() {
    ref.read(momentsNotifierProvider.notifier).toggleLike(
          widget.moment.momentId,
          widget.currentUser.uid,
        );
    
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  void _addComment() {
    if (_commentController.text.trim().isNotEmpty) {
      ref.read(momentsNotifierProvider.notifier).addComment(
            widget.moment.momentId,
            widget.currentUser,
            _commentController.text.trim(),
          );
      _commentController.clear();
    }
  }

  void _openImageViewer(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MomentImageViewer(
          images: widget.moment.mediaUrls,
          initialIndex: initialIndex,
          moment: widget.moment,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = widget.moment.isLikedBy(widget.currentUser.uid);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info
            _buildHeader(),
            
            // Content
            if (widget.moment.content.isNotEmpty) _buildTextContent(),
            
            // Media content
            if (widget.moment.hasMedia) _buildMediaContent(),
            
            // Actions (like, comment, share)
            _buildActionsRow(),
            
            // Comments section
            if (_showComments) _buildCommentsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // User avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[300],
            backgroundImage: widget.moment.userImage.isNotEmpty
                ? CachedNetworkImageProvider(widget.moment.userImage)
                : const AssetImage(AssetsManager.userImage) as ImageProvider,
          ),
          const SizedBox(width: 12),
          
          // User name and time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.moment.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF1C1E21),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeago.format(widget.moment.createdAt),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // More options
          IconButton(
            icon: Icon(
              Icons.more_horiz,
              color: Colors.grey[600],
            ),
            onPressed: () {
              _showMomentOptions();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        widget.moment.content,
        style: const TextStyle(
          fontSize: 15,
          height: 1.4,
          color: Color(0xFF1C1E21),
        ),
      ),
    );
  }

  Widget _buildMediaContent() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: _buildImageGrid(),
    );
  }

  Widget _buildImageGrid() {
    final images = widget.moment.mediaUrls;
    if (images.isEmpty) return const SizedBox.shrink();

    if (images.length == 1) {
      return _buildSingleImage(images[0], 0);
    } else if (images.length == 2) {
      return _buildTwoImages(images);
    } else if (images.length == 3) {
      return _buildThreeImages(images);
    } else {
      return _buildFourOrMoreImages(images);
    }
  }

  Widget _buildSingleImage(String imageUrl, int index) {
    return GestureDetector(
      onTap: () => _openImageViewer(index),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 400),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 200,
            color: Colors.grey[300],
            child: const Icon(Icons.error),
          ),
        ),
      ),
    );
  }

  Widget _buildTwoImages(List<String> images) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _openImageViewer(0),
              child: Container(
                margin: const EdgeInsets.only(right: 1),
                child: CachedNetworkImage(
                  imageUrl: images[0],
                  fit: BoxFit.cover,
                  height: double.infinity,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _openImageViewer(1),
              child: Container(
                margin: const EdgeInsets.only(left: 1),
                child: CachedNetworkImage(
                  imageUrl: images[1],
                  fit: BoxFit.cover,
                  height: double.infinity,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeImages(List<String> images) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _openImageViewer(0),
              child: Container(
                margin: const EdgeInsets.only(right: 1),
                child: CachedNetworkImage(
                  imageUrl: images[0],
                  fit: BoxFit.cover,
                  height: double.infinity,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImageViewer(1),
                    child: Container(
                      margin: const EdgeInsets.only(left: 1, bottom: 1),
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: images[1],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImageViewer(2),
                    child: Container(
                      margin: const EdgeInsets.only(left: 1, top: 1),
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: images[2],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFourOrMoreImages(List<String> images) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImageViewer(0),
                    child: Container(
                      margin: const EdgeInsets.only(right: 1, bottom: 1),
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: images[0],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImageViewer(1),
                    child: Container(
                      margin: const EdgeInsets.only(right: 1, top: 1),
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: images[1],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImageViewer(2),
                    child: Container(
                      margin: const EdgeInsets.only(left: 1, bottom: 1),
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: images[2],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImageViewer(3),
                    child: Container(
                      margin: const EdgeInsets.only(left: 1, top: 1),
                      width: double.infinity,
                      child: Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: images[3],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          if (images.length > 4)
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.black.withOpacity(0.6),
                              child: Center(
                                child: Text(
                                  '+${images.length - 4}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsRow() {
    final isLiked = widget.moment.isLikedBy(widget.currentUser.uid);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Like and comment counts
          if (widget.moment.likesCount > 0 || widget.moment.commentsCount > 0)
            Row(
              children: [
                if (widget.moment.likesCount > 0) ...[
                  Icon(
                    Icons.favorite,
                    size: 16,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.moment.likesCount}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
                const Spacer(),
                if (widget.moment.commentsCount > 0)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showComments = !_showComments;
                      });
                    },
                    child: Text(
                      '${widget.moment.commentsCount} comments',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          
          if (widget.moment.likesCount > 0 || widget.moment.commentsCount > 0)
            const SizedBox(height: 12),
          
          // Divider
          if (widget.moment.likesCount > 0 || widget.moment.commentsCount > 0)
            Divider(
              height: 1,
              color: Colors.grey[300],
            ),
          
          if (widget.moment.likesCount > 0 || widget.moment.commentsCount > 0)
            const SizedBox(height: 8),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _toggleLike,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _likeAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _likeAnimation.value,
                              child: Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                color: isLiked ? Colors.red : Colors.grey[600],
                                size: 20,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Like',
                          style: TextStyle(
                            color: isLiked ? Colors.red : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showComments = !_showComments;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Comment',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // TODO: Implement share functionality
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.share_outlined,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Share',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Comment input
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: widget.currentUser.image.isNotEmpty
                      ? CachedNetworkImageProvider(widget.currentUser.image)
                      : const AssetImage(AssetsManager.userImage) as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Write a comment...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onSubmitted: (_) => _addComment(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addComment,
                  icon: Icon(
                    Icons.send,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Comments list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.moment.comments.length,
            itemBuilder: (context, index) {
              final comment = widget.moment.comments[index];
              return _buildCommentItem(comment);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(MomentComment comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[300],
            backgroundImage: comment.userImage.isNotEmpty
                ? CachedNetworkImageProvider(comment.userImage)
                : const AssetImage(AssetsManager.userImage) as ImageProvider,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comment.content,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      timeago.format(comment.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        // TODO: Implement comment like
                      },
                      child: Text(
                        'Like',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        // TODO: Implement reply to comment
                      },
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMomentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.moment.userId == widget.currentUser.uid) ...[
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Moment'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement edit moment
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete Moment', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMoment();
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.report),
                  title: const Text('Report Moment'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement report moment
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.block),
                  title: Text('Hide from ${widget.moment.userName}'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement hide user
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _deleteMoment() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Moment'),
          content: const Text('Are you sure you want to delete this moment? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(momentsNotifierProvider.notifier).deleteMoment(widget.moment.momentId);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
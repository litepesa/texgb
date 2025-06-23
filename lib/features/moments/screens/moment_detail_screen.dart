// lib/features/moments/screens/moment_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/providers/moments_provider.dart';
import 'package:textgb/features/moments/screens/media_viewer_screen.dart';
import 'package:textgb/features/moments/widgets/moment_reactions_widget.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class MomentDetailScreen extends ConsumerStatefulWidget {
  final MomentModel moment;

  const MomentDetailScreen({super.key, required this.moment});

  @override
  ConsumerState<MomentDetailScreen> createState() => _MomentDetailScreenState();
}

class _MomentDetailScreenState extends ConsumerState<MomentDetailScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isCommentExpanded = false;
  String? _replyToCommentId;
  String? _replyToAuthorName;

  // Beautiful color palette matching WeChat design
  static const Color primaryColor = Color(0xFF1D1D1D);
  static const Color secondaryColor = Color(0xFF8E8E93);
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color cardColor = Colors.white;
  static const Color borderColor = Color(0xFFE5E5EA);
  static const Color wechatGreen = Color(0xFF09B83E);
  static const Color appleBlue = Color(0xFF007AFF);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _animationController.forward();
    
    // Mark moment as viewed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(momentsNotifierProvider.notifier).addViewToMoment(widget.moment.momentId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authenticationProvider);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildContent(),
                    ),
                  );
                },
              ),
            ),
            _buildCommentInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.5),
            offset: const Offset(0, 1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: appleBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.arrow_back_ios,
                color: appleBlue,
                size: 18,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Moment Details',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: primaryColor,
                letterSpacing: -0.4,
              ),
            ),
          ),
          _buildMoreButton(),
        ],
      ),
    );
  }

  Widget _buildMoreButton() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: secondaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.more_horiz,
          color: secondaryColor,
          size: 18,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 8,
      offset: const Offset(0, 40),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, size: 20, color: primaryColor),
              SizedBox(width: 12),
              Text('Share'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.report, size: 20, color: Colors.red),
              SizedBox(width: 12),
              Text('Report'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'share':
            _shareMoment();
            break;
          case 'report':
            _reportMoment();
            break;
        }
      },
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildMomentCard()),
        SliverToBoxAdapter(child: _buildReactionsSection()),
        SliverToBoxAdapter(child: _buildCommentsHeader()),
        _buildCommentsList(),
      ],
    );
  }

  Widget _buildMomentCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.3),
            offset: const Offset(0, 2),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMomentHeader(),
          if (widget.moment.content.isNotEmpty) _buildMomentContent(),
          if (widget.moment.hasMedia) _buildMomentMedia(),
          _buildMomentActions(),
          _buildMomentStats(),
        ],
      ),
    );
  }

  Widget _buildMomentHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: wechatGreen.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: userImageWidget(
              imageUrl: widget.moment.authorImage,
              radius: 24,
              onTap: () {}, // Navigate to user profile
            ),
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
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatTimeDetailed(widget.moment.createdAt),
                      style: const TextStyle(
                        fontSize: 13,
                        color: secondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPrivacyColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPrivacyIcon(),
                            size: 12,
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
        ],
      ),
    );
  }

  Widget _buildMomentContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        widget.moment.content,
        style: const TextStyle(
          fontSize: 16,
          color: primaryColor,
          height: 1.5,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Widget _buildMomentMedia() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: widget.moment.hasImages
          ? _buildImageMedia()
          : _buildVideoMedia(),
    );
  }

  Widget _buildImageMedia() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: _buildImageGrid(),
    );
  }

  Widget _buildImageGrid() {
    final images = widget.moment.mediaUrls;
    final count = images.length;

    if (count == 1) {
      return _buildSingleImage(images[0], 0);
    } else {
      return _buildMultipleImages(images);
    }
  }

  Widget _buildSingleImage(String imageUrl, int index) {
    return GestureDetector(
      onTap: () => _openMediaViewer(index),
      child: Hero(
        tag: imageUrl,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            height: 300,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildImagePlaceholder(300),
            errorWidget: (context, url, error) => _buildImageError(300),
          ),
        ),
      ),
    );
  }

  Widget _buildMultipleImages(List<String> images) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: images.length == 2 ? 2 : 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1.0,
      ),
      itemCount: images.length > 9 ? 9 : images.length,
      itemBuilder: (context, index) {
        if (index == 8 && images.length > 9) {
          return _buildMoreImagesIndicator(images.length - 8, index);
        }
        return _buildGridImageItem(images[index], index);
      },
    );
  }

  Widget _buildGridImageItem(String imageUrl, int index) {
    return GestureDetector(
      onTap: () => _openMediaViewer(index),
      child: Hero(
        tag: imageUrl,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildImagePlaceholder(120),
            errorWidget: (context, url, error) => _buildImageError(120),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreImagesIndicator(int count, int index) {
    return GestureDetector(
      onTap: () => _openMediaViewer(index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: widget.moment.mediaUrls[index],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '+$count',
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
    );
  }

  Widget _buildVideoMedia() {
    return GestureDetector(
      onTap: () => _openMediaViewer(0),
      child: Container(
        height: 250,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: primaryColor.withOpacity(0.8),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.videocam,
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
    );
  }

  Widget _buildImagePlaceholder(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: appleBlue,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildImageError(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: secondaryColor,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              'Failed to load',
              style: TextStyle(
                color: secondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMomentActions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildActionButton(
            icon: widget.moment.likedBy.isNotEmpty
                ? Icons.favorite
                : Icons.favorite_border,
            label: 'Like',
            color: widget.moment.likedBy.isNotEmpty ? Colors.red : secondaryColor,
            onTap: () => _toggleLike(),
          ),
          const SizedBox(width: 24),
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            label: 'Comment',
            color: secondaryColor,
            onTap: () => _focusCommentInput(),
          ),
          const SizedBox(width: 24),
          _buildActionButton(
            icon: Icons.share,
            label: 'Share',
            color: secondaryColor,
            onTap: () => _shareMoment(),
          ),
          const Spacer(),
          if (widget.moment.viewsCount > 0)
            Row(
              children: [
                const Icon(
                  Icons.visibility,
                  color: secondaryColor,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.moment.viewsCount}',
                  style: const TextStyle(
                    color: secondaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMomentStats() {
    if (widget.moment.likesCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Text(
        '${widget.moment.likesCount} ${widget.moment.likesCount == 1 ? 'like' : 'likes'}',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildReactionsSection() {
    return MomentReactionsWidget(moment: widget.moment);
  }

  Widget _buildCommentsHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.3),
            offset: const Offset(0, 2),
            blurRadius: 12,
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            color: primaryColor,
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            'Comments',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: StreamBuilder<List<MomentComment>>(
        stream: ref.read(momentsNotifierProvider.notifier)
            .getMomentComments(widget.moment.momentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: appleBlue),
                ),
              ),
            );
          }

          final comments = snapshot.data ?? [];

          if (comments.isEmpty) {
            return SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: const BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 48,
                      color: secondaryColor,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No comments yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: secondaryColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Be the first to comment!',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final comment = comments[index];
                final isLast = index == comments.length - 1;
                
                return Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: isLast
                        ? const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          )
                        : null,
                  ),
                  child: _buildCommentItem(comment, isLast),
                );
              },
              childCount: comments.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommentItem(MomentComment comment, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: !isLast
            ? const Border(bottom: BorderSide(color: borderColor, width: 0.5))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          userImageWidget(
            imageUrl: comment.authorImage,
            radius: 16,
            onTap: () {}, // Navigate to user profile
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatCommentTime(comment.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (comment.replyToName != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Replying to ${comment.replyToName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: secondaryColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                Text(
                  comment.content,
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _replyToComment(comment),
                  child: const Text(
                    'Reply',
                    style: TextStyle(
                      color: appleBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 
                 MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.5),
            offset: const Offset(0, -1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyToAuthorName != null) _buildReplyIndicator(),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _commentController,
                    maxLines: _isCommentExpanded ? 4 : 1,
                    style: const TextStyle(
                      fontSize: 15,
                      color: primaryColor,
                    ),
                    decoration: InputDecoration(
                      hintText: _replyToAuthorName != null
                          ? 'Reply to ${_replyToAuthorName}...'
                          : 'Add a comment...',
                      hintStyle: const TextStyle(
                        color: secondaryColor,
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _isCommentExpanded = true;
                      });
                    },
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _postComment,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _commentController.text.trim().isNotEmpty
                          ? [appleBlue, appleBlue.withOpacity(0.8)]
                          : [secondaryColor, secondaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: appleBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.reply,
            color: appleBlue,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Replying to $_replyToAuthorName',
              style: const TextStyle(
                color: appleBlue,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: _cancelReply,
            child: const Icon(
              Icons.close,
              color: appleBlue,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getPrivacyColor() {
    switch (widget.moment.privacy) {
      case MomentPrivacy.allContacts:
        return wechatGreen;
      case MomentPrivacy.onlyMe:
        return Colors.orange;
      case MomentPrivacy.customList:
        return appleBlue;
    }
  }

  IconData _getPrivacyIcon() {
    switch (widget.moment.privacy) {
      case MomentPrivacy.allContacts:
        return Icons.people;
      case MomentPrivacy.onlyMe:
        return Icons.lock;
      case MomentPrivacy.customList:
        return Icons.group;
    }
  }

  void _openMediaViewer(int index) {
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

  void _toggleLike() {
    ref.read(momentsNotifierProvider.notifier).toggleLikeMoment(widget.moment.momentId);
  }

  void _focusCommentInput() {
    FocusScope.of(context).requestFocus(FocusNode());
    setState(() {
      _isCommentExpanded = true;
    });
  }

  void _replyToComment(MomentComment comment) {
    setState(() {
      _replyToCommentId = comment.commentId;
      _replyToAuthorName = comment.authorName;
      _isCommentExpanded = true;
    });
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToAuthorName = null;
    });
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    try {
      await ref.read(momentsNotifierProvider.notifier).addComment(
        momentId: widget.moment.momentId,
        content: content,
        replyToUID: _replyToCommentId,
        replyToName: _replyToAuthorName,
      );

      _commentController.clear();
      _cancelReply();
      setState(() {
        _isCommentExpanded = false;
      });

      // Auto-scroll to bottom to show new comment
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      showSnackBar(context, 'Failed to post comment');
    }
  }

  void _shareMoment() {
    // Implement share functionality
    showSnackBar(context, 'Share functionality to be implemented');
  }

  void _reportMoment() {
    showMyAnimatedDialog(
      context: context,
      title: 'Report Moment',
      content: 'Are you sure you want to report this moment for inappropriate content?',
      textAction: 'Report',
      onActionTap: (confirm) {
        if (confirm) {
          // Implement report functionality
          showSnackBar(context, 'Moment reported successfully');
        }
      },
    );
  }

  String _formatTimeDetailed(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatCommentTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
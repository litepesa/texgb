// lib/features/moments/widgets/moment_card.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/widgets/moment_media_grid.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:timeago/timeago.dart' as timeago;

class MomentCard extends StatelessWidget {
  final MomentModel moment;
  final String currentUserUID;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const MomentCard({
    super.key,
    required this.moment,
    required this.currentUserUID,
    required this.onLike,
    required this.onComment,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMyMoment = moment.authorUID == currentUserUID;
    final isLiked = moment.likedBy.contains(currentUserUID);

    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with user info
              _buildHeader(context, isMyMoment),
              
              const SizedBox(height: 12),
              
              // Content
              if (moment.content.isNotEmpty) ...[
                _buildContent(),
                const SizedBox(height: 12),
              ],
              
              // Media
              if (moment.hasMedia) ...[
                MomentMediaGrid(
                  mediaUrls: moment.mediaUrls,
                  mediaType: moment.mediaType,
                ),
                const SizedBox(height: 12),
              ],
              
              // Location
              if (moment.location != null) ...[
                _buildLocation(),
                const SizedBox(height: 12),
              ],
              
              // Actions
              _buildActions(context, isLiked),
              
              // Likes and comments count
              if (moment.likesCount > 0 || moment.commentsCount > 0) ...[
                const SizedBox(height: 8),
                _buildStats(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMyMoment) {
    return Row(
      children: [
        // Profile picture
        userImageWidget(
          imageUrl: moment.authorImage,
          radius: 20,
          onTap: () {
            // TODO: Navigate to user profile
          },
        ),
        
        const SizedBox(width: 12),
        
        // User info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    moment.authorName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  if (moment.privacy != MomentPrivacy.allContacts) ...[
                    const SizedBox(width: 8),
                    _buildPrivacyIcon(),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                timeago.format(moment.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
        ),
        
        // More options
        if (isMyMoment)
          GestureDetector(
            onTap: () => _showMoreOptions(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                CupertinoIcons.ellipsis,
                color: Color(0xFF8E8E93),
                size: 20,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPrivacyIcon() {
    IconData icon;
    Color color = const Color(0xFF8E8E93);
    
    switch (moment.privacy) {
      case MomentPrivacy.only:
        icon = CupertinoIcons.person_2;
        break;
      case MomentPrivacy.except:
        icon = CupertinoIcons.minus_circle;
        break;
      case MomentPrivacy.public:
        icon = CupertinoIcons.globe;
        break;
      default:
        icon = CupertinoIcons.person_3;
    }
    
    return Icon(
      icon,
      size: 14,
      color: color,
    );
  }

  Widget _buildContent() {
    return Text(
      moment.content,
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF1A1A1A),
        height: 1.4,
      ),
    );
  }

  Widget _buildLocation() {
    return Row(
      children: [
        const Icon(
          CupertinoIcons.location,
          size: 14,
          color: Color(0xFF007AFF),
        ),
        const SizedBox(width: 4),
        Text(
          moment.location!,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF007AFF),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, bool isLiked) {
    return Row(
      children: [
        // Like button
        GestureDetector(
          onTap: onLike,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                  size: 20,
                  color: isLiked ? const Color(0xFFFF3B30) : const Color(0xFF8E8E93),
                ),
                if (moment.likesCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '${moment.likesCount}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isLiked ? const Color(0xFFFF3B30) : const Color(0xFF8E8E93),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        const SizedBox(width: 24),
        
        // Comment button
        GestureDetector(
          onTap: onComment,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.chat_bubble,
                  size: 20,
                  color: Color(0xFF8E8E93),
                ),
                if (moment.commentsCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '${moment.commentsCount}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        const Spacer(),
        
        // Share button
        GestureDetector(
          onTap: () => _shareMoment(context),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(
              CupertinoIcons.share,
              size: 20,
              color: Color(0xFF8E8E93),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    final hasLikes = moment.likesCount > 0;
    final hasComments = moment.commentsCount > 0;
    
    if (!hasLikes && !hasComments) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (hasLikes) ...[
            Icon(
              CupertinoIcons.heart_fill,
              size: 12,
              color: Color(0xFFFF3B30),
            ),
            const SizedBox(width: 4),
            Text(
              _getLikesText(),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
          
          if (hasLikes && hasComments) ...[
            const SizedBox(width: 16),
            Container(
              width: 2,
              height: 2,
              decoration: const BoxDecoration(
                color: Color(0xFF8E8E93),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
          ],
          
          if (hasComments) ...[
            Text(
              '${moment.commentsCount} ${moment.commentsCount == 1 ? 'comment' : 'comments'}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getLikesText() {
    if (moment.likesCount == 1) {
      return '1 like';
    } else {
      return '${moment.likesCount} likes';
    }
  }

  void _showMoreOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          if (onDelete != null)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                onDelete!();
              },
              isDestructiveAction: true,
              child: const Text('Delete Moment'),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement edit moment
              showSnackBar(context, 'Edit feature coming soon');
            },
            child: const Text('Edit Moment'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _shareMoment(BuildContext context) {
    // TODO: Implement share functionality
    showSnackBar(context, 'Share feature coming soon');
  }
}
// lib/features/public_groups/widgets/public_group_post_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/public_groups/models/public_group_model.dart';
import 'package:textgb/features/public_groups/models/public_group_post_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class PublicGroupPostItem extends ConsumerStatefulWidget {
  final PublicGroupPostModel post;
  final PublicGroupModel publicGroup;
  final Function(String emoji) onReaction;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final Function(String action) onMenuAction;

  const PublicGroupPostItem({
    super.key,
    required this.post,
    required this.publicGroup,
    required this.onReaction,
    required this.onComment,
    required this.onShare,
    required this.onMenuAction,
  });

  @override
  ConsumerState<PublicGroupPostItem> createState() => _PublicGroupPostItemState();
}

class _PublicGroupPostItemState extends ConsumerState<PublicGroupPostItem> {
  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    final currentUser = ref.watch(currentUserProvider);
    
    final canManagePost = currentUser != null && 
        (widget.post.authorUID == currentUser.uid || widget.publicGroup.canPost(currentUser.uid));

    return Container(
      color: theme.surfaceColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          _buildPostHeader(theme, canManagePost, currentUser),
          
          // Post content
          if (widget.post.content.isNotEmpty) _buildPostContent(theme),
          
          // Post media
          if (widget.post.mediaUrls.isNotEmpty) _buildPostMedia(theme),
          
          // Post stats
          _buildPostStats(theme),
          
          // Post actions
          _buildPostActions(theme, currentUser),
        ],
      ),
    );
  }

  Widget _buildPostHeader(ModernThemeExtension theme, bool canManagePost, currentUser) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Author avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.primaryColor!.withOpacity(0.2),
            backgroundImage: widget.post.authorImage.isNotEmpty
                ? NetworkImage(widget.post.authorImage)
                : null,
            child: widget.post.authorImage.isEmpty
                ? Text(
                    widget.post.authorName.isNotEmpty ? widget.post.authorName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          
          const SizedBox(width: 12),
          
          // Author info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.post.authorName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                    if (widget.publicGroup.isCreator(widget.post.authorUID))
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor!.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Owner',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (widget.post.isPinned)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.push_pin,
                          size: 16,
                          color: theme.primaryColor,
                        ),
                      ),
                  ],
                ),
                Text(
                  widget.post.getFormattedTime(),
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Post menu
          if (canManagePost)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: theme.textSecondaryColor,
              ),
              onSelected: widget.onMenuAction,
              itemBuilder: (context) => _buildMenuItems(currentUser),
            ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(currentUser) {
    return [
      if (widget.publicGroup.canPost(widget.post.authorUID))
        PopupMenuItem(
          value: 'pin',
          child: Row(
            children: [
              Icon(
                widget.post.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(widget.post.isPinned ? 'Unpin' : 'Pin'),
            ],
          ),
        ),
      PopupMenuItem(
        value: 'copy_link',
        child: Row(
          children: [
            Icon(Icons.link, size: 20),
            SizedBox(width: 12),
            Text('Copy Link'),
          ],
        ),
      ),
      if (widget.post.authorUID == (currentUser?.uid ?? ''))
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 12),
              Text('Edit'),
            ],
          ),
        ),
      if (widget.post.authorUID == (currentUser?.uid ?? '') ||
          widget.publicGroup.canPost(currentUser?.uid ?? ''))
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        )
      else
        PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.report, size: 20, color: Colors.red),
              SizedBox(width: 12),
              Text('Report', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
    ];
  }

  Widget _buildPostContent(ModernThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(
        widget.post.content,
        style: TextStyle(
          fontSize: 16,
          color: theme.textColor,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildPostMedia(ModernThemeExtension theme) {
    if (widget.post.mediaUrls.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: _buildMediaGrid(theme),
    );
  }

  Widget _buildMediaGrid(ModernThemeExtension theme) {
    final mediaCount = widget.post.mediaUrls.length;
    
    if (mediaCount == 1) {
      return _buildSingleMedia(widget.post.mediaUrls[0], theme);
    } else if (mediaCount == 2) {
      return _buildTwoMediaGrid(theme);
    } else if (mediaCount == 3) {
      return _buildThreeMediaGrid(theme);
    } else {
      return _buildFourPlusMediaGrid(theme);
    }
  }

  Widget _buildSingleMedia(String mediaUrl, ModernThemeExtension theme) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.surfaceVariantColor,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildMediaWidget(mediaUrl, BoxFit.cover),
      ),
    );
  }

  Widget _buildTwoMediaGrid(ModernThemeExtension theme) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.surfaceVariantColor,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildMediaWidget(widget.post.mediaUrls[0], BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.surfaceVariantColor,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildMediaWidget(widget.post.mediaUrls[1], BoxFit.cover),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThreeMediaGrid(ModernThemeExtension theme) {
    return Column(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: theme.surfaceVariantColor,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildMediaWidget(widget.post.mediaUrls[0], BoxFit.cover),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.surfaceVariantColor,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildMediaWidget(widget.post.mediaUrls[1], BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.surfaceVariantColor,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildMediaWidget(widget.post.mediaUrls[2], BoxFit.cover),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFourPlusMediaGrid(ModernThemeExtension theme) {
    final remainingCount = widget.post.mediaUrls.length - 3;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.surfaceVariantColor,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildMediaWidget(widget.post.mediaUrls[0], BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.surfaceVariantColor,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildMediaWidget(widget.post.mediaUrls[1], BoxFit.cover),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.surfaceVariantColor,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildMediaWidget(widget.post.mediaUrls[2], BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.surfaceVariantColor,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildMediaWidget(widget.post.mediaUrls[3], BoxFit.cover),
                      if (remainingCount > 0)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '+$remainingCount',
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
      ],
    );
  }

  Widget _buildMediaWidget(String mediaUrl, BoxFit fit) {
    if (widget.post.postType == MessageEnum.video) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            mediaUrl,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, size: 50),
              );
            },
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      );
    } else {
      return Image.network(
        mediaUrl,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 50),
          );
        },
      );
    }
  }

  Widget _buildPostStats(ModernThemeExtension theme) {
    if (widget.post.reactionsCount == 0 && widget.post.commentsCount == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          if (widget.post.reactionsCount > 0) ...[
            _buildReactionSummary(theme),
            const Spacer(),
          ],
          if (widget.post.commentsCount > 0)
            Text(
              widget.post.commentsCount == 1 
                  ? '1 comment' 
                  : '${widget.post.commentsCount} comments',
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondaryColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReactionSummary(ModernThemeExtension theme) {
    final reactionEmojis = widget.post.reactions.values
        .where((reaction) => reaction is Map && reaction['emoji'] != null)
        .map((reaction) => reaction['emoji'] as String)
        .take(3)
        .toList();

    return Row(
      children: [
        if (reactionEmojis.isNotEmpty) ...[
          ...reactionEmojis.map((emoji) => Container(
            margin: const EdgeInsets.only(right: 2),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              shape: BoxShape.circle,
              border: Border.all(color: theme.backgroundColor!, width: 1),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 12)),
          )),
          const SizedBox(width: 4),
        ],
        Text(
          widget.post.reactionsCount.toString(),
          style: TextStyle(
            fontSize: 14,
            color: theme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPostActions(ModernThemeExtension theme, currentUser) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Row(
        children: [
          _buildActionButton(
            icon: Icons.favorite_border,
            label: 'Like',
            onTap: () => _showReactionPicker(),
            theme: theme,
            isActive: currentUser != null && widget.post.hasUserReacted(currentUser.uid),
            activeIcon: Icons.favorite,
          ),
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            label: 'Comment',
            onTap: widget.onComment,
            theme: theme,
          ),
          _buildActionButton(
            icon: Icons.share_outlined,
            label: 'Share',
            onTap: widget.onShare,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ModernThemeExtension theme,
    bool isActive = false,
    IconData? activeIcon,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? (activeIcon ?? icon) : icon,
                  size: 20,
                  color: isActive ? theme.primaryColor : theme.textSecondaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: isActive ? theme.primaryColor : theme.textSecondaryColor,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReactionPicker() {
    final theme = context.modernTheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.textTertiaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'React to this post',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildReactionOption('❤️', 'Love'),
                    _buildReactionOption('👍', 'Like'),
                    _buildReactionOption('😂', 'Laugh'),
                    _buildReactionOption('😮', 'Wow'),
                    _buildReactionOption('😢', 'Sad'),
                    _buildReactionOption('😡', 'Angry'),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReactionOption(String emoji, String label) {
    final theme = context.modernTheme;
    
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        widget.onReaction(emoji);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
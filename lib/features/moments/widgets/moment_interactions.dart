// ===============================
// Moment Interactions Widget
// Like and comment buttons with counts
// ===============================

import 'package:flutter/material.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/theme/moments_theme.dart';

class MomentInteractions extends StatelessWidget {
  final MomentModel moment;
  final VoidCallback onLike;
  final VoidCallback onComment;

  const MomentInteractions({
    super.key,
    required this.moment,
    required this.onLike,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MomentsTheme.paddingLarge,
        vertical: MomentsTheme.paddingSmall,
      ),
      child: Row(
        children: [
          // Like button - Facebook style
          Expanded(
            child: _buildLikeButton(),
          ),

          const SizedBox(width: 8),

          // Comment button - Facebook style
          Expanded(
            child: _buildCommentButton(),
          ),

          const SizedBox(width: 8),

          // Share button (optional)
          Expanded(
            child: _buildShareButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildLikeButton() {
    return InkWell(
      onTap: onLike,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              moment.isLikedByMe ? Icons.favorite : Icons.favorite_border,
              size: 20,
              color: moment.isLikedByMe
                  ? MomentsTheme.likeRed
                  : MomentsTheme.lightTextSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Like',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: moment.isLikedByMe
                    ? MomentsTheme.likeRed
                    : MomentsTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentButton() {
    return InkWell(
      onTap: onComment,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mode_comment_outlined,
              size: 20,
              color: MomentsTheme.lightTextSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Comment',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: MomentsTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton() {
    return InkWell(
      onTap: () {
        // Share functionality can be added here
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.share_outlined,
              size: 20,
              color: MomentsTheme.lightTextSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Share',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: MomentsTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

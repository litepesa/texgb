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
          // Like button
          _buildLikeButton(),

          const SizedBox(width: 24),

          // Comment button
          _buildCommentButton(),

          const Spacer(),

          // Timestamp (optional, can be removed if redundant)
          // Text(
          //   MomentsTimeService.formatMomentTime(moment.createdAt),
          //   style: MomentsTheme.timestampStyle,
          // ),
        ],
      ),
    );
  }

  Widget _buildLikeButton() {
    return InkWell(
      onTap: onLike,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              moment.isLikedByMe ? Icons.favorite : Icons.favorite_border,
              size: MomentsTheme.iconSizeMedium,
              color: moment.isLikedByMe
                  ? MomentsTheme.likeRed
                  : MomentsTheme.lightTextSecondary,
            ),
            if (moment.likesCount > 0) ...[
              const SizedBox(width: 6),
              Text(
                '${moment.likesCount}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: moment.isLikedByMe
                      ? MomentsTheme.likeRed
                      : MomentsTheme.lightTextSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommentButton() {
    return InkWell(
      onTap: onComment,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.comment_outlined,
              size: MomentsTheme.iconSizeMedium,
              color: MomentsTheme.lightTextSecondary,
            ),
            if (moment.commentsCount > 0) ...[
              const SizedBox(width: 6),
              Text(
                '${moment.commentsCount}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: MomentsTheme.lightTextSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

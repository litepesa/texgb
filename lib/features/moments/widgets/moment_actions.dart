// lib/features/moments/widgets/moment_actions.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';

class MomentActions extends ConsumerWidget {
  final MomentModel moment;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onMore;

  const MomentActions({
    super.key,
    required this.moment,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isLiked = currentUser != null && moment.likedBy.contains(currentUser.uid);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Like button
        _ActionButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          color: isLiked ? Colors.red : Colors.white,
          count: moment.likesCount,
          onTap: onLike,
        ),
        const SizedBox(height: 20),

        // Comment button
        _ActionButton(
          icon: Icons.chat_bubble_outline,
          color: Colors.white,
          count: moment.commentsCount,
          onTap: onComment,
        ),
        const SizedBox(height: 20),

        // Share button
        _ActionButton(
          icon: Icons.share,
          color: Colors.white,
          count: null,
          onTap: onShare,
        ),
        const SizedBox(height: 20),

        // More options button
        _ActionButton(
          icon: Icons.more_vert,
          color: Colors.white,
          count: null,
          onTap: onMore,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int? count;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
        ),
        if (count != null && count! > 0) ...[
          const SizedBox(height: 4),
          Text(
            _formatCount(count!),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}

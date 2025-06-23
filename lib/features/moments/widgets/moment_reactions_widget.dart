// lib/features/moments/widgets/moment_reactions_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class MomentReactionsWidget extends ConsumerStatefulWidget {
  final MomentModel moment;

  const MomentReactionsWidget({super.key, required this.moment});

  @override
  ConsumerState<MomentReactionsWidget> createState() => _MomentReactionsWidgetState();
}

class _MomentReactionsWidgetState extends ConsumerState<MomentReactionsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _showAllLikes = false;

  // Beautiful color palette
  static const Color primaryColor = Color(0xFF1D1D1D);
  static const Color secondaryColor = Color(0xFF8E8E93);
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color cardColor = Colors.white;
  static const Color borderColor = Color(0xFFE5E5EA);
  static const Color appleBlue = Color(0xFF007AFF);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.moment.likesCount == 0) {
      return const SizedBox.shrink();
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReactionsHeader(),
            const SizedBox(height: 12),
            _buildLikesList(),
            if (widget.moment.likesCount > 3) _buildShowMoreButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionsHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.red, Colors.pink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.favorite,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${widget.moment.likesCount} ${widget.moment.likesCount == 1 ? 'like' : 'likes'}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
        const Spacer(),
        if (widget.moment.likesCount > 0)
          Text(
            _getTimeAgo(),
            style: const TextStyle(
              fontSize: 12,
              color: secondaryColor,
            ),
          ),
      ],
    );
  }

  Widget _buildLikesList() {
    // In a real implementation, you would fetch the actual user data
    // For now, we'll show placeholder avatars
    final displayCount = _showAllLikes 
        ? widget.moment.likesCount 
        : (widget.moment.likesCount > 3 ? 3 : widget.moment.likesCount);

    return Column(
      children: List.generate(displayCount, (index) {
        return _buildLikeItem(index);
      }),
    );
  }

  Widget _buildLikeItem(int index) {
    // Placeholder data - in real implementation, fetch user data
    final userName = 'User ${index + 1}';
    final userImage = ''; // Placeholder
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          userImageWidget(
            imageUrl: userImage,
            radius: 16,
            onTap: () {}, // Navigate to user profile
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              userName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ),
          Text(
            _getRelativeTime(index),
            style: const TextStyle(
              fontSize: 12,
              color: secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowMoreButton() {
    if (_showAllLikes) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        setState(() {
          _showAllLikes = true;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'View all ${widget.moment.likesCount} likes',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: appleBlue,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: appleBlue,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(widget.moment.createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _getRelativeTime(int index) {
    // Simulate different like times
    final baseTime = widget.moment.createdAt.add(Duration(minutes: index * 5));
    final now = DateTime.now();
    final difference = now.difference(baseTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}
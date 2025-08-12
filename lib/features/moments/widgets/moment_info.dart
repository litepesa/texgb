// lib/features/moments/widgets/moment_info.dart
import 'package:flutter/material.dart';
import 'package:textgb/features/moments/models/moment_model.dart';

class MomentInfo extends StatelessWidget {
  final MomentModel moment;

  const MomentInfo({
    super.key,
    required this.moment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Author info
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: moment.authorImage.isNotEmpty
                  ? NetworkImage(moment.authorImage)
                  : null,
              backgroundColor: Colors.grey[300],
              child: moment.authorImage.isEmpty
                  ? Text(
                      moment.authorName.isNotEmpty 
                          ? moment.authorName[0].toUpperCase()
                          : "U",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    moment.authorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _getTimeAgo(moment.createdAt),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        if (moment.content.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            moment.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.3,
            ),
          ),
        ],

        const SizedBox(height: 8),
        
        // Time remaining and privacy info
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer,
                    color: Colors.white.withOpacity(0.7),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    moment.timeRemainingText,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getPrivacyIcon(moment.privacy),
                    color: Colors.white.withOpacity(0.7),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    moment.privacy.displayName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getPrivacyIcon(MomentPrivacy privacy) {
    switch (privacy) {
      case MomentPrivacy.public:
        return Icons.public;
      case MomentPrivacy.contacts:
        return Icons.contacts;
      case MomentPrivacy.selectedContacts:
        return Icons.people;
      case MomentPrivacy.exceptSelected:
        return Icons.people_outline;
    }
  }
}
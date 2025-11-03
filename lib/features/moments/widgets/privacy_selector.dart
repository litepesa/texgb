// ===============================
// Privacy Selector Widget
// Select moment visibility settings
// ===============================

import 'package:flutter/material.dart';
import 'package:textgb/features/moments/models/moment_enums.dart';
import 'package:textgb/features/moments/theme/moments_theme.dart';

class PrivacySelector extends StatelessWidget {
  final MomentVisibility currentVisibility;

  const PrivacySelector({
    Key? key,
    required this.currentVisibility,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Who can see this?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Privacy options
            _buildPrivacyOption(
              context,
              MomentVisibility.all,
              Icons.public,
              'Public',
              'All your mutual contacts can see this',
            ),

            _buildPrivacyOption(
              context,
              MomentVisibility.private,
              Icons.lock,
              'Private',
              'Only you can see this',
            ),

            _buildPrivacyOption(
              context,
              MomentVisibility.custom,
              Icons.visibility,
              'Custom',
              'Custom visibility settings',
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyOption(
    BuildContext context,
    MomentVisibility visibility,
    IconData icon,
    String title,
    String description,
  ) {
    final isSelected = visibility == currentVisibility;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? MomentsTheme.primaryBlue.withValues(alpha: 0.1)
              : Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? MomentsTheme.primaryBlue : Colors.grey[600],
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? MomentsTheme.primaryBlue : Colors.black,
        ),
      ),
      subtitle: Text(
        description,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: MomentsTheme.primaryBlue,
            )
          : null,
      onTap: () {
        if (visibility == MomentVisibility.custom) {
          // TODO: Navigate to contact selector
          _showCustomPrivacyNote(context, visibility);
        } else {
          Navigator.pop(context, visibility);
        }
      },
    );
  }

  void _showCustomPrivacyNote(BuildContext context, MomentVisibility visibility) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Privacy'),
        content: const Text(
          'Custom privacy lists will be available in the next update. '
          'For now, please use Public or Private visibility.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

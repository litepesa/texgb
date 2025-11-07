// ===============================
// Privacy Selector Widget
// Select moment visibility settings
// Uses GoRouter for navigation
// ===============================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/features/moments/models/moment_enums.dart';
import 'package:textgb/features/moments/theme/moments_theme.dart';
import 'package:textgb/features/moments/widgets/contact_selector_screen.dart';

class PrivacySelector extends StatelessWidget {
  final MomentVisibility currentVisibility;

  const PrivacySelector({
    super.key,
    required this.currentVisibility,
  });

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
                    onPressed: () => context.pop(),
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
      onTap: () async {
        if (visibility == MomentVisibility.custom) {
          // Navigate to contact selector
          context.pop(); // Close privacy selector
          await _showCustomPrivacyOptions(context);
        } else {
          context.pop(visibility);
        }
      },
    );
  }

  Future<void> _showCustomPrivacyOptions(BuildContext context) async {
    final mode = await showDialog<ContactSelectorMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Privacy'),
        content: const Text('Choose how to customize visibility:'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(ContactSelectorMode.visibleTo),
            child: const Text('Select who can see'),
          ),
          TextButton(
            onPressed: () => context.pop(ContactSelectorMode.hiddenFrom),
            child: const Text('Hide from specific'),
          ),
        ],
      ),
    );

    if (mode != null && context.mounted) {
      // Navigate to contact selector
      final selectedIds = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder: (context) => ContactSelectorScreen(
            mode: mode,
            initialSelectedIds: const [],
          ),
        ),
      );

      if (selectedIds != null && selectedIds.isNotEmpty && context.mounted) {
        // Return custom visibility with selected user IDs
        // For now, just return the visibility type
        // The parent screen should handle the selected IDs
        context.pop(MomentVisibility.custom);
      }
    }
  }
}

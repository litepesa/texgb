// ===============================
// Privacy Selector Widget
// Select moment visibility settings
// Uses GoRouter for navigation
// ===============================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/features/moments/models/moment_enums.dart';
import 'package:textgb/features/moments/theme/moments_theme.dart';

class PrivacySelector extends StatelessWidget {
  final PrivacySelection currentSelection;

  const PrivacySelector({
    super.key,
    required this.currentSelection,
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

            const Divider(height: 1),

            // Hide from specific contacts option - WeChat style
            _buildHideFromOption(context),

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
    final isSelected = visibility == currentSelection.visibility &&
        !currentSelection.hasCustomPrivacy;

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
        context.pop(PrivacySelection(
          visibility: visibility,
          visibleTo: [],
          hiddenFrom: [],
        ));
      },
    );
  }

  Widget _buildHideFromOption(BuildContext context) {
    final hasHiddenContacts = currentSelection.hiddenFrom.isNotEmpty;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: hasHiddenContacts
              ? MomentsTheme.primaryBlue.withValues(alpha: 0.1)
              : Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.visibility_off,
          color: hasHiddenContacts ? MomentsTheme.primaryBlue : Colors.grey[600],
          size: 20,
        ),
      ),
      title: Text(
        'Hide from contacts',
        style: TextStyle(
          fontWeight: hasHiddenContacts ? FontWeight.w600 : FontWeight.w500,
          color: hasHiddenContacts ? MomentsTheme.primaryBlue : Colors.black,
        ),
      ),
      subtitle: Text(
        hasHiddenContacts
            ? '${currentSelection.hiddenFrom.length} contact${currentSelection.hiddenFrom.length > 1 ? 's' : ''} hidden'
            : 'Select contacts who cannot see this',
        style: TextStyle(
          fontSize: 12,
          color: hasHiddenContacts ? MomentsTheme.primaryBlue : Colors.grey[600],
        ),
      ),
      trailing: hasHiddenContacts
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Clear button
                TextButton(
                  onPressed: () {
                    context.pop(PrivacySelection(
                      visibility: MomentVisibility.all,
                      visibleTo: [],
                      hiddenFrom: [],
                    ));
                  },
                  child: const Text('Clear'),
                ),
                Icon(
                  Icons.check_circle,
                  color: MomentsTheme.primaryBlue,
                ),
              ],
            )
          : const Icon(Icons.chevron_right),
      onTap: () {
        // Return action marker to tell parent to open contact selector
        context.pop(const OpenContactSelectorAction());
      },
    );
  }
}

/// Action to open contact selector
/// Returns this from bottom sheet to signal parent to open contact selector
class OpenContactSelectorAction {
  const OpenContactSelectorAction();
}

// lib/features/moments/widgets/privacy_selector.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:textgb/features/moments/models/moment_model.dart';

class PrivacySelector extends StatelessWidget {
  final MomentPrivacy selectedPrivacy;
  final List<String> visibleTo;
  final List<String> hiddenFrom;
  final Function(MomentPrivacy, List<String>, List<String>) onPrivacyChanged;

  const PrivacySelector({
    super.key,
    required this.selectedPrivacy,
    required this.visibleTo,
    required this.hiddenFrom,
    required this.onPrivacyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildPrivacyOption(
            context,
            MomentPrivacy.allContacts,
            'All Contacts',
            'Visible to all your contacts',
            CupertinoIcons.person_3,
          ),
          _buildDivider(),
          _buildPrivacyOption(
            context,
            MomentPrivacy.except,
            'All Contacts Except...',
            'Hide from specific contacts',
            CupertinoIcons.person_badge_minus,
          ),
          _buildDivider(),
          _buildPrivacyOption(
            context,
            MomentPrivacy.only,
            'Only Share With...',
            'Visible to selected contacts only',
            CupertinoIcons.person_2,
          ),
          _buildDivider(),
          _buildPrivacyOption(
            context,
            MomentPrivacy.public,
            'Public',
            'Visible to everyone',
            CupertinoIcons.globe,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyOption(
    BuildContext context,
    MomentPrivacy privacy,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = selectedPrivacy == privacy;

    return GestureDetector(
      onTap: () => _selectPrivacy(context, privacy),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF8E8E93),
                size: 18,
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            
            if (isSelected)
              const Icon(
                CupertinoIcons.checkmark,
                color: Color(0xFF007AFF),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 60),
      color: const Color(0xFFE5E5EA),
    );
  }

  void _selectPrivacy(BuildContext context, MomentPrivacy privacy) {
    if (privacy == MomentPrivacy.except || privacy == MomentPrivacy.only) {
      // Show contact selection screen
      _showContactSelection(context, privacy);
    } else {
      // Direct selection
      onPrivacyChanged(privacy, [], []);
    }
  }

  void _showContactSelection(BuildContext context, MomentPrivacy privacy) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(privacy.displayName),
        message: privacy == MomentPrivacy.except
            ? const Text('Select contacts to hide this moment from')
            : const Text('Select contacts who can see this moment'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement contact selection screen
              // For now, just set the privacy without specific contacts
              onPrivacyChanged(privacy, [], []);
            },
            child: const Text('Select Contacts'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}
// lib/features/users/widgets/privacy_settings_widget.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class PrivacySettingsWidget extends StatefulWidget {
  const PrivacySettingsWidget({super.key});

  @override
  State<PrivacySettingsWidget> createState() => _PrivacySettingsWidgetState();
}

class _PrivacySettingsWidgetState extends State<PrivacySettingsWidget> {
  // Privacy settings state (will be connected to backend later)
  String _lastSeenPrivacy = 'Everyone';
  String _profilePhotoPrivacy = 'Everyone';
  String _aboutPrivacy = 'Everyone';
  String _statusPrivacy = 'My Contacts';
  String _messagePrivacy = 'Everyone';
  String _callPrivacy = 'Everyone';
  bool _readReceipts = true;
  bool _onlineStatus = true;
  bool _typingIndicator = true;

  final List<String> _privacyOptions = [
    'Everyone',
    'My Contacts',
    'Nobody',
  ];

  @override
  Widget build(BuildContext context) {
    final modernTheme = Theme.of(context).extension<ModernThemeExtension>()!;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.9,
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: modernTheme.textColor,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'Privacy Settings',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Who Can See My Information Section
                  _buildSectionHeader(
                    'Who Can See My Information',
                    modernTheme,
                  ),
                  const SizedBox(height: 12),

                  _buildPrivacyOption(
                    icon: CupertinoIcons.clock,
                    title: 'Last Seen',
                    subtitle: 'Who can see when you were last online',
                    currentValue: _lastSeenPrivacy,
                    onTap: () => _showPrivacyPicker(
                      'Last Seen',
                      _lastSeenPrivacy,
                      (value) {
                        setState(() => _lastSeenPrivacy = value);
                      },
                      modernTheme,
                    ),
                    modernTheme: modernTheme,
                  ),

                  _buildPrivacyOption(
                    icon: CupertinoIcons.person_crop_circle,
                    title: 'Profile Photo',
                    subtitle: 'Who can see your profile photo',
                    currentValue: _profilePhotoPrivacy,
                    onTap: () => _showPrivacyPicker(
                      'Profile Photo',
                      _profilePhotoPrivacy,
                      (value) {
                        setState(() => _profilePhotoPrivacy = value);
                      },
                      modernTheme,
                    ),
                    modernTheme: modernTheme,
                  ),

                  _buildPrivacyOption(
                    icon: CupertinoIcons.info_circle,
                    title: 'About',
                    subtitle: 'Who can see your about info',
                    currentValue: _aboutPrivacy,
                    onTap: () => _showPrivacyPicker(
                      'About',
                      _aboutPrivacy,
                      (value) {
                        setState(() => _aboutPrivacy = value);
                      },
                      modernTheme,
                    ),
                    modernTheme: modernTheme,
                  ),

                  _buildPrivacyOption(
                    icon: CupertinoIcons.circle_filled,
                    title: 'Status',
                    subtitle: 'Who can see your status updates',
                    currentValue: _statusPrivacy,
                    onTap: () => _showPrivacyPicker(
                      'Status',
                      _statusPrivacy,
                      (value) {
                        setState(() => _statusPrivacy = value);
                      },
                      modernTheme,
                    ),
                    modernTheme: modernTheme,
                  ),

                  const SizedBox(height: 24),

                  // Communication Privacy Section
                  _buildSectionHeader(
                    'Communication Privacy',
                    modernTheme,
                  ),
                  const SizedBox(height: 12),

                  _buildPrivacyOption(
                    icon: CupertinoIcons.chat_bubble_2,
                    title: 'Messages',
                    subtitle: 'Who can send you messages',
                    currentValue: _messagePrivacy,
                    onTap: () => _showPrivacyPicker(
                      'Messages',
                      _messagePrivacy,
                      (value) {
                        setState(() => _messagePrivacy = value);
                      },
                      modernTheme,
                    ),
                    modernTheme: modernTheme,
                  ),

                  _buildPrivacyOption(
                    icon: CupertinoIcons.phone,
                    title: 'Calls',
                    subtitle: 'Who can call you',
                    currentValue: _callPrivacy,
                    onTap: () => _showPrivacyPicker(
                      'Calls',
                      _callPrivacy,
                      (value) {
                        setState(() => _callPrivacy = value);
                      },
                      modernTheme,
                    ),
                    modernTheme: modernTheme,
                  ),

                  const SizedBox(height: 24),

                  // Activity Privacy Section
                  _buildSectionHeader(
                    'Activity Privacy',
                    modernTheme,
                  ),
                  const SizedBox(height: 12),

                  _buildToggleOption(
                    icon: CupertinoIcons.checkmark_seal,
                    title: 'Read Receipts',
                    subtitle:
                        'Let others know when you\'ve read their messages',
                    value: _readReceipts,
                    onChanged: (value) {
                      setState(() => _readReceipts = value);
                    },
                    modernTheme: modernTheme,
                  ),

                  _buildToggleOption(
                    icon: CupertinoIcons.circle_fill,
                    title: 'Online Status',
                    subtitle: 'Show when you\'re online',
                    value: _onlineStatus,
                    onChanged: (value) {
                      setState(() => _onlineStatus = value);
                    },
                    modernTheme: modernTheme,
                  ),

                  _buildToggleOption(
                    icon: CupertinoIcons.keyboard,
                    title: 'Typing Indicator',
                    subtitle: 'Show when you\'re typing',
                    value: _typingIndicator,
                    onChanged: (value) {
                      setState(() => _typingIndicator = value);
                    },
                    modernTheme: modernTheme,
                  ),

                  const SizedBox(height: 24),

                  // Blocked Contacts Section
                  _buildSectionHeader(
                    'Blocked Contacts',
                    modernTheme,
                  ),
                  const SizedBox(height: 12),

                  _buildActionOption(
                    icon: CupertinoIcons.person_crop_circle_badge_xmark,
                    title: 'Blocked Contacts',
                    subtitle: 'View and manage blocked contacts',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Blocked Contacts - Coming Soon'),
                          backgroundColor: modernTheme.primaryColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    modernTheme: modernTheme,
                  ),

                  const SizedBox(height: 24),

                  // Data & Storage Section
                  _buildSectionHeader(
                    'Data & Storage',
                    modernTheme,
                  ),
                  const SizedBox(height: 12),

                  _buildActionOption(
                    icon: CupertinoIcons.download_circle,
                    title: 'Download My Data',
                    subtitle: 'Request a copy of your data',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Download Data - Coming Soon'),
                          backgroundColor: modernTheme.primaryColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    modernTheme: modernTheme,
                  ),

                  _buildActionOption(
                    icon: CupertinoIcons.delete,
                    title: 'Delete My Account',
                    subtitle: 'Permanently delete your account',
                    onTap: () {
                      _showDeleteAccountWarning(modernTheme);
                    },
                    modernTheme: modernTheme,
                    isDestructive: true,
                  ),

                  const SizedBox(height: 32),

                  // Info box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: modernTheme.primaryColor!.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          CupertinoIcons.info_circle,
                          color: modernTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Privacy settings help you control who can interact with you and see your information. Changes take effect immediately.',
                            style: TextStyle(
                              color: modernTheme.textColor,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    ModernThemeExtension modernTheme,
  ) {
    return Text(
      title,
      style: TextStyle(
        color: modernTheme.textColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildPrivacyOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String currentValue,
    required VoidCallback onTap,
    required ModernThemeExtension modernTheme,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: modernTheme.dividerColor ?? Colors.grey[300]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: modernTheme.primaryColor!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: modernTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: modernTheme.textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentValue,
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: modernTheme.textSecondaryColor,
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ModernThemeExtension modernTheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: modernTheme.dividerColor ?? Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: modernTheme.primaryColor!.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: modernTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeColor: modernTheme.primaryColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ModernThemeExtension modernTheme,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: modernTheme.dividerColor ?? Colors.grey[300]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withOpacity(0.1)
                    : modernTheme.primaryColor!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : modernTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDestructive ? Colors.red : modernTheme.textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: modernTheme.textSecondaryColor,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPicker(
    String title,
    String currentValue,
    ValueChanged<String> onSelected,
    ModernThemeExtension modernTheme,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: modernTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Who can see your $title',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ..._privacyOptions.map((option) {
                final isSelected = option == currentValue;
                return InkWell(
                  onTap: () {
                    onSelected(option);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? modernTheme.primaryColor!.withOpacity(0.1)
                          : null,
                      border: Border(
                        bottom: BorderSide(
                          color: modernTheme.dividerColor ?? Colors.grey[300]!,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              color: isSelected
                                  ? modernTheme.primaryColor
                                  : modernTheme.textColor,
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check,
                            color: modernTheme.primaryColor,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountWarning(ModernThemeExtension modernTheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: modernTheme.surfaceColor,
        title: Text(
          'Delete Account?',
          style: TextStyle(
            color: modernTheme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This action cannot be undone. All your data, messages, and content will be permanently deleted.',
          style: TextStyle(
            color: modernTheme.textSecondaryColor,
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: modernTheme.textColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account Deletion - Coming Soon'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

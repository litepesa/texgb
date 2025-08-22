import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  bool _lastSeenVisible = true;
  bool _readReceiptsEnabled = true;
  bool _statusVisible = true;
  bool _profilePhotoVisible = true;

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;

    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        children: [
          // Privacy options section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Privacy Options',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          _buildSwitchTile(
            title: 'Last Seen',
            subtitle: 'Allow contacts to see when you were last online',
            value: _lastSeenVisible,
            onChanged: (value) {
              setState(() {
                _lastSeenVisible = value;
              });
            },
          ),
          
          _buildSwitchTile(
            title: 'Read Receipts',
            subtitle: 'Let contacts know when you\'ve read their messages',
            value: _readReceiptsEnabled,
            onChanged: (value) {
              setState(() {
                _readReceiptsEnabled = value;
              });
            },
          ),
          
          _buildSwitchTile(
            title: 'Status Visibility',
            subtitle: 'Allow contacts to see your status updates',
            value: _statusVisible,
            onChanged: (value) {
              setState(() {
                _statusVisible = value;
              });
            },
          ),
          
          _buildSwitchTile(
            title: 'Profile Photo Visibility',
            subtitle: 'Allow contacts to see your profile photo',
            value: _profilePhotoVisible,
            onChanged: (value) {
              setState(() {
                _profilePhotoVisible = value;
              });
            },
          ),
          
          // Note
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'These settings will be saved when the feature is fully implemented.',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final modernTheme = context.modernTheme;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            color: modernTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: modernTheme.textSecondaryColor,
            fontSize: 14,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: modernTheme.primaryColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
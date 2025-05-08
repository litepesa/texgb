import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  bool _isLastSeenEnabled = true;
  bool _isReadReceiptsEnabled = true;
  bool _isTypingIndicatorEnabled = true;
  bool _isProfilePhotoVisible = true;
  bool _isStatusVisible = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    // Get user from Riverpod
    final user = ref.read(currentUserProvider);
    
    if (user != null) {
      // Example of how you might load these from user preferences
      setState(() {
        _isLastSeenEnabled = true; // default values
        _isReadReceiptsEnabled = true;
        _isTypingIndicatorEnabled = true;
        _isProfilePhotoVisible = true;
        _isStatusVisible = true;
      });
    }
  }
  
  Future<void> _saveSettings() async {
    // Show a saving indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saving privacy settings...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    // Simulate a delay for saving
    await Future.delayed(const Duration(seconds: 1));
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Privacy settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
      ),
      body: ListView(
        children: [
          // Personal information section
          _buildSectionHeader(theme, 'Personal Information'),
          
          SwitchListTile(
            title: const Text('Last Seen'),
            subtitle: const Text('Allow contacts to see when you were last online'),
            value: _isLastSeenEnabled,
            onChanged: (value) {
              setState(() {
                _isLastSeenEnabled = value;
              });
            },
          ),
          
          const Divider(),
          
          SwitchListTile(
            title: const Text('Read Receipts'),
            subtitle: const Text('Let others know when you\'ve read their messages'),
            value: _isReadReceiptsEnabled,
            onChanged: (value) {
              setState(() {
                _isReadReceiptsEnabled = value;
              });
            },
          ),
          
          const Divider(),
          
          SwitchListTile(
            title: const Text('Typing Indicator'),
            subtitle: const Text('Show when you are typing a message'),
            value: _isTypingIndicatorEnabled,
            onChanged: (value) {
              setState(() {
                _isTypingIndicatorEnabled = value;
              });
            },
          ),
          
          // Profile visibility section
          _buildSectionHeader(theme, 'Profile Visibility'),
          
          SwitchListTile(
            title: const Text('Profile Photo'),
            subtitle: const Text('Who can see your profile photo'),
            value: _isProfilePhotoVisible,
            onChanged: (value) {
              setState(() {
                _isProfilePhotoVisible = value;
              });
            },
            secondary: const Icon(Icons.photo),
          ),
          
          const Divider(),
          
          // Status privacy section
          _buildSectionHeader(theme, 'Status Privacy'),
          
          SwitchListTile(
            title: const Text('Status Updates'),
            subtitle: const Text('Allow contacts to see your status updates'),
            value: _isStatusVisible,
            onChanged: (value) {
              setState(() {
                _isStatusVisible = value;
              });
            },
            secondary: const Icon(Icons.update),
          ),
          
          const Divider(),
          
          ListTile(
            title: const Text('Status Privacy Settings'),
            subtitle: const Text('Configure who can see your status updates'),
            leading: const Icon(Icons.privacy_tip),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, Constants.statusSettingsScreen);
            },
          ),
          
          const Divider(),
          
          // Blocked Contacts section
          _buildSectionHeader(theme, 'Blocked Contacts'),
          
          ListTile(
            title: const Text('Blocked Contacts'),
            subtitle: const Text('Manage your blocked contacts list'),
            leading: const Icon(Icons.block),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, Constants.blockedContactsScreen);
            },
          ),
          
          const SizedBox(height: 40),
          
          // Save button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Save Settings'),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
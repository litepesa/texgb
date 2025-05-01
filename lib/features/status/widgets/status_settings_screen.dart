// lib/features/status/presentation/widgets/status_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class StatusSettingsScreen extends StatefulWidget {
  const StatusSettingsScreen({Key? key}) : super(key: key);

  @override
  State<StatusSettingsScreen> createState() => _StatusSettingsScreenState();
}

class _StatusSettingsScreenState extends State<StatusSettingsScreen> {
  bool _statusNotifications = true;
  bool _autoplayVideos = true;
  bool _downloadMedia = true;
  
  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Status Settings'),
        backgroundColor: modernTheme.appBarColor,
        elevation: 0.5,
      ),
      body: ListView(
        children: [
          // Notifications section
          _buildSectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Status Updates'),
            subtitle: const Text('Get notified when contacts post new status updates'),
            value: _statusNotifications,
            onChanged: (value) {
              setState(() {
                _statusNotifications = value;
              });
            },
          ),
          
          const Divider(),
          
          // Media settings
          _buildSectionHeader('Media'),
          SwitchListTile(
            title: const Text('Autoplay Videos'),
            subtitle: const Text('Automatically play videos when viewing status'),
            value: _autoplayVideos,
            onChanged: (value) {
              setState(() {
                _autoplayVideos = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Auto-download Media'),
            subtitle: const Text('Automatically download status media on Wi-Fi'),
            value: _downloadMedia,
            onChanged: (value) {
              setState(() {
                _downloadMedia = value;
              });
            },
          ),
          
          const Divider(),
          
          // Privacy settings
          _buildSectionHeader('Privacy'),
          ListTile(
            title: const Text('Status Privacy'),
            subtitle: const Text('Control who can see your status updates'),
            trailing: const Icon(CupertinoIcons.chevron_right),
            onTap: () {
              // Navigate to status privacy screen
            },
          ),
          ListTile(
            title: const Text('Muted Contacts'),
            subtitle: const Text('Contacts whose status updates are hidden'),
            trailing: const Icon(CupertinoIcons.chevron_right),
            onTap: () {
              // Navigate to muted contacts screen
            },
          ),
          
          const Divider(),
          
          // Storage settings
          _buildSectionHeader('Storage'),
          ListTile(
            title: const Text('Manage Storage'),
            subtitle: const Text('View and delete status media'),
            trailing: const Icon(CupertinoIcons.chevron_right),
            onTap: () {
              // Navigate to storage management screen
            },
          ),
          
          // Delete options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: ElevatedButton(
              onPressed: () {
                _showDeleteConfirmation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete All My Status Posts'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    final modernTheme = context.modernTheme;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: modernTheme.primaryColor,
        ),
      ),
    );
  }
  
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete All Status Posts?'),
          content: const Text(
            'This action cannot be undone. All your status posts will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Implement delete all posts logic
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
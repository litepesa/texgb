// lib/features/settings/screens/privacy_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({Key? key}) : super(key: key);

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _isLoading = true;
  
  // Privacy settings
  bool _showOnlineStatus = false;
  bool _showReadReceipts = false;
  bool _showTypingIndicators = false;
  bool _enableDisappearingMessages = false;
  int _disappearingMessagesTime = 24; // hours
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _showOnlineStatus = prefs.getBool('show_online_status') ?? false;
        _showReadReceipts = prefs.getBool('show_read_receipts') ?? false;
        _showTypingIndicators = prefs.getBool('show_typing_indicators') ?? false;
        _enableDisappearingMessages = prefs.getBool('enable_disappearing_messages') ?? false;
        _disappearingMessagesTime = prefs.getInt('disappearing_messages_time') ?? 24;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading privacy settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('show_online_status', _showOnlineStatus);
      await prefs.setBool('show_read_receipts', _showReadReceipts);
      await prefs.setBool('show_typing_indicators', _showTypingIndicators);
      await prefs.setBool('enable_disappearing_messages', _enableDisappearingMessages);
      await prefs.setInt('disappearing_messages_time', _disappearingMessagesTime);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Privacy settings saved')),
      );
    } catch (e) {
      debugPrint('Error saving privacy settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving settings')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy Settings',
          style: GoogleFonts.openSans(),
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              'Save',
              style: TextStyle(
                color: modernTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Visibility'),
                    _buildSettingTile(
                      title: 'Show online status',
                      subtitle: 'Allow contacts to see when you\'re online',
                      value: _showOnlineStatus,
                      onChanged: (value) {
                        setState(() {
                          _showOnlineStatus = value;
                        });
                      },
                    ),
                    _buildSettingTile(
                      title: 'Show read receipts',
                      subtitle: 'Show others when you\'ve read their messages',
                      value: _showReadReceipts,
                      onChanged: (value) {
                        setState(() {
                          _showReadReceipts = value;
                        });
                      },
                    ),
                    _buildSettingTile(
                      title: 'Show typing indicators',
                      subtitle: 'Show when you\'re typing a message',
                      value: _showTypingIndicators,
                      onChanged: (value) {
                        setState(() {
                          _showTypingIndicators = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    _buildSectionTitle('Disappearing Messages'),
                    _buildSettingTile(
                      title: 'Enable disappearing messages',
                      subtitle: 'Messages will be deleted after a specified time',
                      value: _enableDisappearingMessages,
                      onChanged: (value) {
                        setState(() {
                          _enableDisappearingMessages = value;
                        });
                      },
                    ),
                    if (_enableDisappearingMessages)
                      _buildTimeSelector(),
                    
                    const SizedBox(height: 24),
                    _buildSectionTitle('Security'),
                    ListTile(
                      title: const Text('Screen security'),
                      subtitle: const Text('Block screenshots in the app'),
                      trailing: Switch(
                        value: false,
                        onChanged: (value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('This feature is coming soon')),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    _buildInfoCard(),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    final modernTheme = context.modernTheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: modernTheme.primaryColor,
        ),
      ),
    );
  }
  
  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
  
  Widget _buildTimeSelector() {
    final timeOptions = [
      {'label': '1 hour', 'value': 1},
      {'label': '6 hours', 'value': 6},
      {'label': '24 hours', 'value': 24},
      {'label': '3 days', 'value': 72},
      {'label': '7 days', 'value': 168},
    ];
    
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Messages disappear after:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: timeOptions.map((option) {
              return ChoiceChip(
                label: Text(option['label'] as String),
                selected: _disappearingMessagesTime == option['value'],
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _disappearingMessagesTime = option['value'] as int;
                    });
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard() {
    return Card(
      elevation: 0,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade800.withOpacity(0.5)
          : Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'About Privacy Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'These privacy settings give you control over what information is shared with your contacts. '
              'By default, we prioritize your privacy by hiding your online status, read receipts, and typing indicators. '
              'Any changes you make here will apply to all your conversations.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
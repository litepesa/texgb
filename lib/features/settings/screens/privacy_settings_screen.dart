// lib/features/settings/screens/privacy_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  late UserPrivacySettings _privacySettings;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(currentUserProvider);
    _privacySettings = currentUser?.privacySettings ?? const UserPrivacySettings();
  }

  Future<void> _savePrivacySettings() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedUser = currentUser.copyWith(privacySettings: _privacySettings);
      await ref.read(authenticationProvider.notifier).updateUserProfile(updatedUser);
      
      if (mounted) {
        showSnackBar(context, 'Privacy settings updated successfully');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error updating privacy settings: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Privacy'),
        backgroundColor: modernTheme.appBarColor,
        foregroundColor: modernTheme.textColor,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _savePrivacySettings,
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Who can send me messages'),
          _buildMessagePermissionSettings(),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Last seen and online'),
          _buildLastSeenSettings(),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Profile photo'),
          _buildProfilePhotoSettings(),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Read receipts'),
          _buildReadReceiptSettings(),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Groups and channels'),
          _buildGroupSettings(),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Advanced'),
          _buildAdvancedSettings(),
          
          const SizedBox(height: 32),
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final modernTheme = context.modernTheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: modernTheme.primaryColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMessagePermissionSettings() {
    return _buildSettingsCard([
      _buildRadioListTile(
        title: 'Everyone',
        subtitle: 'Anyone can send you messages',
        value: MessagePermissionLevel.everyone,
        groupValue: _privacySettings.messagePermission,
        onChanged: (value) => _updateMessagePermission(value!),
      ),
      _buildRadioListTile(
        title: 'My contacts',
        subtitle: 'Only people in your contacts can message you',
        value: MessagePermissionLevel.contactsOnly,
        groupValue: _privacySettings.messagePermission,
        onChanged: (value) => _updateMessagePermission(value!),
      ),
      _buildRadioListTile(
        title: 'Selected contacts',
        subtitle: 'Only specific contacts you choose',
        value: MessagePermissionLevel.selectedContacts,
        groupValue: _privacySettings.messagePermission,
        onChanged: (value) => _updateMessagePermission(value!),
      ),
      _buildRadioListTile(
        title: 'Nobody',
        subtitle: 'No one can send you messages',
        value: MessagePermissionLevel.nobody,
        groupValue: _privacySettings.messagePermission,
        onChanged: (value) => _updateMessagePermission(value!),
      ),
    ]);
  }

  Widget _buildLastSeenSettings() {
    return _buildSettingsCard([
      _buildRadioListTile(
        title: 'Everyone',
        subtitle: 'Anyone can see when you were last online',
        value: LastSeenVisibility.everyone,
        groupValue: _privacySettings.lastSeenVisibility,
        onChanged: (value) => _updateLastSeenVisibility(value!),
      ),
      _buildRadioListTile(
        title: 'My contacts',
        subtitle: 'Only your contacts can see your last seen',
        value: LastSeenVisibility.contactsOnly,
        groupValue: _privacySettings.lastSeenVisibility,
        onChanged: (value) => _updateLastSeenVisibility(value!),
      ),
      _buildRadioListTile(
        title: 'Nobody',
        subtitle: 'No one can see when you were last online',
        value: LastSeenVisibility.nobody,
        groupValue: _privacySettings.lastSeenVisibility,
        onChanged: (value) => _updateLastSeenVisibility(value!),
      ),
    ]);
  }

  Widget _buildProfilePhotoSettings() {
    return _buildSettingsCard([
      _buildRadioListTile(
        title: 'Everyone',
        subtitle: 'Anyone can see your profile photo',
        value: ProfilePhotoVisibility.everyone,
        groupValue: _privacySettings.profilePhotoVisibility,
        onChanged: (value) => _updateProfilePhotoVisibility(value!),
      ),
      _buildRadioListTile(
        title: 'My contacts',
        subtitle: 'Only your contacts can see your profile photo',
        value: ProfilePhotoVisibility.contactsOnly,
        groupValue: _privacySettings.profilePhotoVisibility,
        onChanged: (value) => _updateProfilePhotoVisibility(value!),
      ),
      _buildRadioListTile(
        title: 'Nobody',
        subtitle: 'No one can see your profile photo',
        value: ProfilePhotoVisibility.nobody,
        groupValue: _privacySettings.profilePhotoVisibility,
        onChanged: (value) => _updateProfilePhotoVisibility(value!),
      ),
    ]);
  }

  Widget _buildReadReceiptSettings() {
    return _buildSettingsCard([
      _buildRadioListTile(
        title: 'Everyone',
        subtitle: 'Anyone can see when you read their messages',
        value: ReadReceiptVisibility.everyone,
        groupValue: _privacySettings.readReceiptVisibility,
        onChanged: (value) => _updateReadReceiptVisibility(value!),
      ),
      _buildRadioListTile(
        title: 'My contacts',
        subtitle: 'Only your contacts can see read receipts',
        value: ReadReceiptVisibility.contactsOnly,
        groupValue: _privacySettings.readReceiptVisibility,
        onChanged: (value) => _updateReadReceiptVisibility(value!),
      ),
      _buildRadioListTile(
        title: 'Nobody',
        subtitle: 'No one can see when you read messages',
        value: ReadReceiptVisibility.nobody,
        groupValue: _privacySettings.readReceiptVisibility,
        onChanged: (value) => _updateReadReceiptVisibility(value!),
      ),
    ]);
  }

  Widget _buildGroupSettings() {
    return _buildSettingsCard([
      _buildSwitchListTile(
        title: 'Group invites',
        subtitle: 'Allow others to add you to groups',
        value: _privacySettings.allowGroupInvites,
        onChanged: (value) => _updateGroupInvites(value),
      ),
      _buildSwitchListTile(
        title: 'Channel invites',
        subtitle: 'Allow others to add you to channels',
        value: _privacySettings.allowChannelInvites,
        onChanged: (value) => _updateChannelInvites(value),
      ),
    ]);
  }

  Widget _buildAdvancedSettings() {
    return _buildSettingsCard([
      _buildSwitchListTile(
        title: 'Message forwarding',
        subtitle: 'Allow your messages to be forwarded',
        value: _privacySettings.allowForwarding,
        onChanged: (value) => _updateForwarding(value),
      ),
      _buildSwitchListTile(
        title: 'Calls from contacts',
        subtitle: 'Allow calls from people in your contacts',
        value: _privacySettings.allowCallsFromContacts,
        onChanged: (value) => _updateCallsFromContacts(value),
      ),
    ]);
  }

  Widget _buildSettingsCard(List<Widget> children) {
    final modernTheme = context.modernTheme;
    
    return Container(
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: modernTheme.dividerColor?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildRadioListTile<T>({
    required String title,
    required String subtitle,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
  }) {
    final modernTheme = context.modernTheme;
    
    return RadioListTile<T>(
      title: Text(
        title,
        style: TextStyle(
          color: modernTheme.textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: modernTheme.textSecondaryColor,
          fontSize: 13,
        ),
      ),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: modernTheme.primaryColor,
      dense: true,
    );
  }

  Widget _buildSwitchListTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final modernTheme = context.modernTheme;
    
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          color: modernTheme.textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: modernTheme.textSecondaryColor,
          fontSize: 13,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: modernTheme.primaryColor,
      dense: true,
    );
  }

  Widget _buildInfoCard() {
    final modernTheme = context.modernTheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceVariantColor?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: modernTheme.primaryColor?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: modernTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Privacy Information',
                style: TextStyle(
                  color: modernTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'These settings control who can interact with you and what information they can see. '
            'Changes will take effect immediately and apply to all future interactions.',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Update methods
  void _updateMessagePermission(MessagePermissionLevel permission) {
    setState(() {
      _privacySettings = _privacySettings.copyWith(messagePermission: permission);
    });
  }

  void _updateLastSeenVisibility(LastSeenVisibility visibility) {
    setState(() {
      _privacySettings = _privacySettings.copyWith(lastSeenVisibility: visibility);
    });
  }

  void _updateProfilePhotoVisibility(ProfilePhotoVisibility visibility) {
    setState(() {
      _privacySettings = _privacySettings.copyWith(profilePhotoVisibility: visibility);
    });
  }

  void _updateReadReceiptVisibility(ReadReceiptVisibility visibility) {
    setState(() {
      _privacySettings = _privacySettings.copyWith(readReceiptVisibility: visibility);
    });
  }

  void _updateGroupInvites(bool allow) {
    setState(() {
      _privacySettings = _privacySettings.copyWith(allowGroupInvites: allow);
    });
  }

  void _updateChannelInvites(bool allow) {
    setState(() {
      _privacySettings = _privacySettings.copyWith(allowChannelInvites: allow);
    });
  }

  void _updateForwarding(bool allow) {
    setState(() {
      _privacySettings = _privacySettings.copyWith(allowForwarding: allow);
    });
  }

  void _updateCallsFromContacts(bool allow) {
    setState(() {
      _privacySettings = _privacySettings.copyWith(allowCallsFromContacts: allow);
    });
  }
}
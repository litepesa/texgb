import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../application/providers/status_providers.dart';
import '../../application/providers/app_providers.dart';
import '../../domain/models/status_privacy.dart';

class StatusSettingsScreen extends ConsumerWidget {
  const StatusSettingsScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutedUsers = ref.watch(mutedUsersProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Settings'),
      ),
      body: ListView(
        children: [
          // Privacy settings
          ListTile(
            title: const Text('Default Privacy Settings'),
            subtitle: const Text('Manage who can see your status updates'),
            leading: const Icon(Icons.lock_outline),
            onTap: () => _showPrivacySettings(context, ref),
          ),
          const Divider(),
          
          // Muted contacts
          ListTile(
            title: const Text('Muted Contacts'),
            subtitle: Text(
              mutedUsers.isEmpty
                  ? 'You haven\'t muted anyone yet'
                  : '${mutedUsers.length} ${mutedUsers.length == 1 ? 'contact' : 'contacts'} muted',
            ),
            leading: const Icon(Icons.volume_off),
            onTap: () => _showMutedContacts(context, ref),
          ),
          const Divider(),
          
          // View counter settings
          ListTile(
            title: const Text('View Counter'),
            subtitle: const Text('Manage who can see your view count'),
            leading: const Icon(Icons.visibility),
            onTap: () => _showViewCounterSettings(context, ref),
          ),
          const Divider(),
          
          // Data usage settings
          ListTile(
            title: const Text('Data Usage'),
            subtitle: const Text('Manage data usage for media in status updates'),
            leading: const Icon(Icons.data_usage),
            onTap: () => _showDataUsageSettings(context),
          ),
          const Divider(),
          
          // Notification settings
          ListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Manage notifications for status updates'),
            leading: const Icon(Icons.notifications_outlined),
            onTap: () => _showNotificationSettings(context),
          ),
        ],
      ),
    );
  }
  
  void _showPrivacySettings(BuildContext context, WidgetRef ref) {
    final currentPrivacy = ref.read(statusPrivacyProvider);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Default Privacy Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Choose who can see your status updates by default:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  
                  RadioListTile<PrivacyType>(
                    title: const Text('All Contacts'),
                    value: PrivacyType.allContacts,
                    groupValue: currentPrivacy.type,
                    onChanged: (value) {
                      final newPrivacy = StatusPrivacy.allContacts();
                      ref.read(statusPrivacyProvider.notifier).state = newPrivacy;
                      Navigator.pop(context);
                    },
                  ),
                  
                  RadioListTile<PrivacyType>(
                    title: const Text('All Contacts Except...'),
                    value: PrivacyType.except,
                    groupValue: currentPrivacy.type,
                    onChanged: (value) {
                      // This would open contact selection for exceptions
                      Navigator.pop(context);
                      _showContactSelectionForExceptions(context, ref);
                    },
                  ),
                  
                  RadioListTile<PrivacyType>(
                    title: const Text('Only Share With...'),
                    value: PrivacyType.onlySpecific,
                    groupValue: currentPrivacy.type,
                    onChanged: (value) {
                      // This would open contact selection for inclusion
                      Navigator.pop(context);
                      _showContactSelectionForInclusion(context, ref);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  void _showContactSelectionForExceptions(BuildContext context, WidgetRef ref) {
    // This would be implemented to show a contact picker
    // For now, just show a placeholder message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact selection will be implemented here'),
      ),
    );
  }
  
  void _showContactSelectionForInclusion(BuildContext context, WidgetRef ref) {
    // This would be implemented to show a contact picker
    // For now, just show a placeholder message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact selection will be implemented here'),
      ),
    );
  }
  
  void _showMutedContacts(BuildContext context, WidgetRef ref) async {
    final mutedUsers = ref.read(mutedUsersProvider);
    
    if (mutedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You haven\'t muted any contacts yet'),
        ),
      );
      return;
    }
    
    // Get current user
    final currentUser = await ref.read(userProvider.future);
    if (currentUser == null) return;
    
    // This would fetch user details of muted contacts
    // For now, just display IDs
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Muted Contacts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'These contacts won\'t appear in your status feed',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: mutedUsers.length,
                  itemBuilder: (context, index) {
                    final userId = mutedUsers[index];
                    // This would show actual user details in production
                    return ListTile(
                      title: Text('User ID: $userId'),
                      trailing: TextButton(
                        onPressed: () {
                          ref.read(mutedUsersProvider.notifier).unmuteUser(
                            currentUser.uid,
                            userId,
                          );
                          Navigator.pop(context);
                        },
                        child: const Text('Unmute'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showViewCounterSettings(BuildContext context, WidgetRef ref) {
    // For now, just allow toggling the hide view count setting
    final currentPrivacy = ref.read(statusPrivacyProvider);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'View Counter Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Control who can see the view count on your status updates',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  
                  SwitchListTile(
                    title: const Text('Hide view count from others'),
                    subtitle: const Text(
                      'Only you will be able to see how many people viewed your status',
                    ),
                    value: currentPrivacy.hideViewCount,
                    onChanged: (value) {
                      // Update the privacy settings
                      final newPrivacy = currentPrivacy.copyWith(
                        hideViewCount: value,
                      );
                      ref.read(statusPrivacyProvider.notifier).state = newPrivacy;
                      setState(() {});
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const Text(
                    'Note: Even when view count is hidden, you\'ll still be able to see who viewed your status.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  void _showDataUsageSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool autoDownloadOnWifi = true;
            bool autoDownloadOnMobile = false;
            bool highQualityUpload = true;
            
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Data Usage Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('Auto-download media on Wi-Fi'),
                    value: autoDownloadOnWifi,
                    onChanged: (value) {
                      setState(() {
                        autoDownloadOnWifi = value;
                      });
                    },
                  ),
                  
                  SwitchListTile(
                    title: const Text('Auto-download media on mobile data'),
                    value: autoDownloadOnMobile,
                    onChanged: (value) {
                      setState(() {
                        autoDownloadOnMobile = value;
                      });
                    },
                  ),
                  
                  SwitchListTile(
                    title: const Text('Upload high-quality media'),
                    subtitle: const Text('Uses more data but maintains quality'),
                    value: highQualityUpload,
                    onChanged: (value) {
                      setState(() {
                        highQualityUpload = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // Would save these settings in a real app
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Settings saved'),
                          ),
                        );
                      },
                      child: const Text('Save Settings'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  void _showNotificationSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool notifyNewStatus = true;
            bool notifyComments = true;
            bool notifyReactions = true;
            
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notification Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('New status updates'),
                    subtitle: const Text('Get notified when contacts post new status'),
                    value: notifyNewStatus,
                    onChanged: (value) {
                      setState(() {
                        notifyNewStatus = value;
                      });
                    },
                  ),
                  
                  SwitchListTile(
                    title: const Text('Comments notifications'),
                    subtitle: const Text('Get notified when someone comments on your status'),
                    value: notifyComments,
                    onChanged: (value) {
                      setState(() {
                        notifyComments = value;
                      });
                    },
                  ),
                  
                  SwitchListTile(
                    title: const Text('Reaction notifications'),
                    subtitle: const Text('Get notified when someone reacts to your status'),
                    value: notifyReactions,
                    onChanged: (value) {
                      setState(() {
                        notifyReactions = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // Would save these settings in a real app
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notification settings saved'),
                          ),
                        );
                      },
                      child: const Text('Save Settings'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
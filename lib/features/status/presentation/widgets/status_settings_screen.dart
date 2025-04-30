import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../application/providers/status_providers.dart';

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
          const ListTile(
            title: Text('Privacy Settings'),
            subtitle: Text('Manage who can see your status updates'),
            leading: Icon(Icons.lock_outline),
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
          const ListTile(
            title: Text('Data Usage'),
            subtitle: Text('Manage data usage for media in status updates'),
            leading: Icon(Icons.data_usage),
          ),
          const Divider(),
          
          // Notification settings
          const ListTile(
            title: Text('Notifications'),
            subtitle: Text('Manage notifications for status updates'),
            leading: Icon(Icons.notifications_outlined),
          ),
        ],
      ),
    );
  }
}
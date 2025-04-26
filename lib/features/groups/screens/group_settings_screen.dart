import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/groups/group_provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class GroupSettingsScreen extends StatefulWidget {
  const GroupSettingsScreen({super.key});

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, child) {
        return Scaffold(
          appBar: AppBar(
            leading: AppBarBackButton(
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: const Text('Group Settings'),
            centerTitle: true,
          ),
          body: ListView(
            children: [
              const SizedBox(height: 16),
              
              // Group admin controls section
              _buildSectionHeader('Admin Controls'),
              
              // Only admins can edit group info
              SwitchListTile(
                title: const Text('Only admins can edit group info'),
                subtitle: const Text('Name, description, and group icon'),
                value: groupProvider.groupModel.onlyAdminsCanEditInfo,
                onChanged: (value) {
                  groupProvider.setOnlyAdminsCanEditInfo(value: value);
                },
              ),
              
              // Only admins can send messages
              SwitchListTile(
                title: const Text('Only admins can send messages'),
                subtitle: const Text('Other members can only read messages'),
                value: groupProvider.groupModel.onlyAdminsCanSendMessages,
                onChanged: (value) {
                  groupProvider.setOnlyAdminsCanSendMessages(value: value);
                },
              ),
              
              const Divider(),
              
              // Privacy and notifications section
              _buildSectionHeader('Privacy'),
              
              // Media visibility
              ListTile(
                title: const Text('Media visibility'),
                subtitle: const Text('Show newly downloaded media from this group in your device\'s gallery'),
                trailing: Switch(
                  value: true, // This would be connected to actual app settings
                  onChanged: (value) {
                    // Implement media visibility settings change
                  },
                ),
              ),
              
              // Disappearing messages
              ListTile(
                title: const Text('Disappearing messages'),
                subtitle: const Text('Off'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to disappearing messages settings
                },
              ),
              
              // Encryption info
              ListTile(
                title: const Text('Encryption'),
                subtitle: const Text('Messages and calls are end-to-end encrypted'),
                trailing: const Icon(Icons.lock, size: 16),
                onTap: () {
                  // Show encryption info dialog
                  _showEncryptionInfoDialog();
                },
              ),
              
              const Divider(),
              
              // Group info section
              _buildSectionHeader('Group Info'),
              
              // Created at info
              ListTile(
                title: const Text('Created at'),
                subtitle: Text(_formatDate(groupProvider.groupModel.createdAt)),
              ),
              
              // Creator info
              FutureBuilder<List<UserModel>>(
                future: _getCreator(groupProvider),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      title: Text('Created by'),
                      subtitle: Text('Loading...'),
                    );
                  }
                  
                  final creator = snapshot.data?.first;
                  return ListTile(
                    title: const Text('Created by'),
                    subtitle: Text(creator?.name ?? 'Unknown'),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  Future<List<UserModel>> _getCreator(GroupProvider provider) async {
    // Get the creator user model
    final creatorUID = provider.groupModel.creatorUID;
    final creatorDoc = await FirebaseFirestore.instance
        .collection(Constants.users)
        .doc(creatorUID)
        .get();
    
    if (creatorDoc.exists) {
      return [UserModel.fromMap(creatorDoc.data()!)];
    }
    
    return [];
  }
  
  void _showEncryptionInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End-to-end encrypted'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Messages and calls in this chat are secured with end-to-end encryption. '
              'This means your messages stay between you and the people you choose. '
              'Not even the app can read the content of your messages.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
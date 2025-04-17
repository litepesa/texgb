import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/status/screens/status_create_screen.dart';
import 'package:textgb/features/status/screens/status_view_screen.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/providers/status_provider.dart';
import 'package:textgb/widgets/status_circle.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch statuses when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStatuses();
    });
  }

  Future<void> _loadStatuses() async {
    final authProvider = context.read<AuthenticationProvider>();
    final statusProvider = context.read<StatusProvider>();
    
    // Get current user and their contacts
    final currentUser = authProvider.userModel!;
    
    // Use contactsUIDs for the new contact system
    final contactUids = currentUser.contactsUIDs;
    
    // Filter out blocked contacts
    final blockedUids = currentUser.blockedUIDs;
    final filteredContactUids = contactUids.where((uid) => !blockedUids.contains(uid)).toList();
    
    // Fetch statuses
    await statusProvider.fetchAllStatuses(
      currentUserUid: currentUser.uid,
      friendUids: filteredContactUids,
    );
  }

  void _navigateToStatusCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StatusCreateScreen(),
      ),
    ).then((_) => _loadStatuses()); // Refresh statuses when returning
  }

  void _navigateToStatusView(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusViewScreen(userId: userId),
      ),
    ).then((_) => _loadStatuses()); // Refresh statuses when returning
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final backgroundColor = themeExtension?.backgroundColor;
    final accentColor = themeExtension?.accentColor ?? const Color(0xFF07C160);
    final greyColor = themeExtension?.greyColor ?? Colors.grey;
    
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    final statusProvider = context.watch<StatusProvider>();
    
    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToStatusCreate,
        backgroundColor: accentColor,
        elevation: 2,
        child: const Icon(Icons.camera_alt),
      ),
      body: statusProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatuses,
              color: accentColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // My Status section
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Row(
                          children: [
                            StatusCircle(
                              imageUrl: currentUser.image,
                              name: currentUser.name,
                              radius: 30,
                              isMyStatus: true,
                              hasStatus: statusProvider.myStatuses.isNotEmpty,
                              onTap: statusProvider.myStatuses.isEmpty
                                  ? _navigateToStatusCreate
                                  : () => _navigateToStatusView(currentUser.uid),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'My Status',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  Text(
                                    statusProvider.myStatuses.isEmpty
                                        ? 'Tap to add status update'
                                        : 'Tap to view your status',
                                    style: TextStyle(
                                      color: greyColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Section divider
                      Divider(
                        color: themeExtension?.dividerColor ?? Colors.grey.withOpacity(0.2),
                        height: 1,
                      ),
                      const SizedBox(height: 16),

                      // Recent updates heading
                      if (statusProvider.contactStatuses.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Recent Updates',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),

                        // Contacts with status updates
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: statusProvider.contactStatuses.length,
                          itemBuilder: (context, index) {
                            final userId = statusProvider.contactStatuses.keys.elementAt(index);
                            final statusList = statusProvider.contactStatuses[userId]!;
                            
                            // Skip if no statuses
                            if (statusList.isEmpty) return const SizedBox();
                            
                            // Get user info from the first status
                            final userName = statusList.first.userName;
                            final userImage = statusList.first.userImage;
                            
                            // Check if all statuses are viewed
                            final bool allViewed = statusList.every(
                              (status) => status.viewedBy.contains(currentUser.uid),
                            );

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Row(
                                children: [
                                  StatusCircle(
                                    imageUrl: userImage,
                                    name: userName,
                                    radius: 30,
                                    hasStatus: true,
                                    isViewed: allViewed,
                                    onTap: () => _navigateToStatusView(userId),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                        Text(
                                          _getTimeAgo(statusList.first.createdAt),
                                          style: TextStyle(
                                            color: greyColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ] else ...[
                        // No status updates from contacts
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 60.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.circle_outlined,
                                  size: 70,
                                  color: greyColor.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No recent updates',
                                  style: TextStyle(
                                    color: greyColor,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'When friends add to their status, you\'ll see them here',
                                  style: TextStyle(
                                    color: greyColor,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
  
  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
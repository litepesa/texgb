import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    
    // Get current user and their friends
    final currentUser = authProvider.userModel!;
    final friendUids = currentUser.friendsUIDs;
    
    // Fetch statuses
    await statusProvider.fetchAllStatuses(
      currentUserUid: currentUser.uid,
      friendUids: friendUids,
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
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    final statusProvider = context.watch<StatusProvider>();
    
    return RefreshIndicator(
      onRefresh: _loadStatuses,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: _navigateToStatusCreate,
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.camera_alt),
        ),
        body: statusProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
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
                        padding: const EdgeInsets.only(bottom: 16.0),
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
                                  const Text(
                                    'My Status',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    statusProvider.myStatuses.isEmpty
                                        ? 'Tap to add status update'
                                        : 'Tap to view your status',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Recent updates divider
                      if (statusProvider.contactStatuses.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Recent updates',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),

                        // Friends with status updates
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
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          'Tap to view status',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
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
                        // No status updates from friends
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.circle_outlined,
                                  size: 80,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No recent updates',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
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
}
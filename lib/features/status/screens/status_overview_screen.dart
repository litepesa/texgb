// lib/features/status/screens/status_overview_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/status_enums.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/status/screens/status_viewer_screen.dart';
import 'package:textgb/features/status/screens/create_status_screen.dart';
import 'package:textgb/features/status/screens/my_statuses_screen.dart';
import 'package:textgb/features/status/screens/status_replies_screen.dart';
import 'package:textgb/features/status/status_post_model.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';

class StatusOverviewScreen extends StatefulWidget {
  const StatusOverviewScreen({Key? key}) : super(key: key);

  @override
  State<StatusOverviewScreen> createState() => _StatusOverviewScreenState();
}

class _StatusOverviewScreenState extends State<StatusOverviewScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch statuses when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    final currentUser = Provider.of<AuthenticationProvider>(context, listen: false).userModel;
    if (currentUser == null) return;

    await Provider.of<StatusProvider>(context, listen: false).fetchAllStatuses(
      currentUserId: currentUser.uid,
      contactIds: currentUser.contactsUIDs,
    );
    
    await Provider.of<StatusProvider>(context, listen: false).fetchStatusReplies(
      currentUser.uid,
    );
  }

  void _navigateToCreateStatus() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateStatusScreen(),
      ),
    ).then((_) => _fetchData());
  }

  void _navigateToMyStatuses() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MyStatusesScreen(),
      ),
    ).then((_) => _fetchData());
  }

  void _navigateToStatusReplies() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StatusRepliesScreen(),
      ),
    ).then((_) => _fetchData());
  }

  void _navigateToStatusViewer(String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StatusViewerScreen(userId: userId),
      ),
    ).then((_) => _fetchData());
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final statusProvider = Provider.of<StatusProvider>(context);
    final authProvider = Provider.of<AuthenticationProvider>(context);
    final currentUser = authProvider.userModel;
    
    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Text('Please sign in to view status updates'),
        ),
      );
    }

    final myStatuses = statusProvider.myStatuses;
    final usersWithStatus = statusProvider.userStatusMap;
    
    final hasReplies = statusProvider.unreadRepliesCount > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status'),
        actions: [
          // Replies button with badge for unread replies
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                tooltip: 'Status Replies',
                onPressed: _navigateToStatusReplies,
              ),
              if (hasReplies)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      statusProvider.unreadRepliesCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onPressed: () => _showFilterOptions(context),
          ),
        ],
      ),
      body: statusProvider.isLoading
          ? Center(child: CircularProgressIndicator(color: modernTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: ListView(
                children: [
                  // My Status Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'My Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _buildMyStatusTile(context, myStatuses, currentUser),

                  // Recent updates section
                  if (usersWithStatus.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Recent Updates',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    ...usersWithStatus.entries.map((entry) {
                      final userId = entry.key;
                      final userStatuses = entry.value;
                      
                      if (userStatuses.isEmpty) return Container();
                      
                      // Check if all statuses are viewed
                      final allViewed = userStatuses.every((status) => 
                        status.viewerUIDs.contains(currentUser.uid));
                      
                      // Get the most recent status for preview
                      final recentStatus = userStatuses.reduce((a, b) => 
                        a.createdAt.isAfter(b.createdAt) ? a : b);
                      
                      return ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: recentStatus.userImage.isNotEmpty
                                  ? CachedNetworkImageProvider(recentStatus.userImage)
                                  : AssetImage(AssetsManager.userImage) as ImageProvider,
                            ),
                            Positioned.fill(
                              child: CircularBorder(
                                color: allViewed ? Colors.grey : modernTheme.primaryColor!,
                                segments: userStatuses.length,
                                highlightedSegments: userStatuses.where((s) => 
                                  !s.viewerUIDs.contains(currentUser.uid)).length,
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          recentStatus.username,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          _getStatusTimestamp(recentStatus.createdAt),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        onTap: () => _navigateToStatusViewer(userId),
                      );
                    }).toList(),
                  ],
                  
                  if (usersWithStatus.isEmpty && myStatuses.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.photo_album_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No status updates',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Be the first to share a status with your contacts',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateStatus,
        child: const Icon(Icons.add),
        tooltip: 'Create status',
      ),
    );
  }

  Widget _buildMyStatusTile(BuildContext context, List<StatusPostModel> myStatuses, dynamic currentUser) {
    final modernTheme = context.modernTheme;
    
    if (myStatuses.isEmpty) {
      // No status - show option to create
      return ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.grey[300],
              backgroundImage: currentUser.image.isNotEmpty
                  ? CachedNetworkImageProvider(currentUser.image)
                  : const AssetImage(AssetsManager.userImage) as ImageProvider,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: modernTheme.primaryColor,
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        title: const Text('My Status'),
        subtitle: const Text('Tap to add status update'),
        onTap: _navigateToCreateStatus,
      );
    } else {
      // Has status - show option to view
      final recentStatus = myStatuses.reduce((a, b) => 
        a.createdAt.isAfter(b.createdAt) ? a : b);
        
      return ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.grey[300],
              backgroundImage: currentUser.image.isNotEmpty
                  ? CachedNetworkImageProvider(currentUser.image)
                  : const AssetImage(AssetsManager.userImage) as ImageProvider,
            ),
            Positioned.fill(
              child: CircularBorder(
                color: modernTheme.primaryColor!,
                segments: myStatuses.length,
              ),
            ),
          ],
        ),
        title: const Text('My Status'),
        subtitle: Text(
          'Tap to view your status • ${_getStatusTimestamp(recentStatus.createdAt)}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'create') {
              _navigateToCreateStatus();
            } else if (value == 'view') {
              _navigateToMyStatuses();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'create',
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline),
                  SizedBox(width: 8),
                  Text('Add status'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('View all'),
                ],
              ),
            ),
          ],
        ),
        onTap: _navigateToMyStatuses,
      );
    }
  }
  
  void _showFilterOptions(BuildContext context) {
    final statusProvider = Provider.of<StatusProvider>(context, listen: false);
    final currentFilter = statusProvider.currentFilter;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Latest updates'),
              trailing: currentFilter == FeedFilterType.latest
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                statusProvider.setFeedFilter(FeedFilterType.latest);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off),
              title: const Text('Unwatched status'),
              trailing: currentFilter == FeedFilterType.unviewed
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                statusProvider.setFeedFilter(FeedFilterType.unviewed);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Watched status'),
              trailing: currentFilter == FeedFilterType.viewed
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                statusProvider.setFeedFilter(FeedFilterType.viewed);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  String _getStatusTimestamp(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return 'Yesterday';
    }
  }
}

/// Custom widget to draw segmented circular border around status avatar
class CircularBorder extends StatelessWidget {
  final Color color;
  final int segments;
  final int highlightedSegments;
  
  const CircularBorder({
    Key? key,
    required this.color,
    required this.segments,
    this.highlightedSegments = 0,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CircularBorderPainter(
        color: color,
        segments: segments,
        highlightedSegments: highlightedSegments,
      ),
    );
  }
}

class CircularBorderPainter extends CustomPainter {
  final Color color;
  final int segments;
  final int highlightedSegments;
  
  CircularBorderPainter({
    required this.color,
    required this.segments,
    required this.highlightedSegments,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw segments
    final double segmentAngle = 2 * 3.14159 / segments;
    final double gapAngle = segmentAngle * 0.05; // 5% gap
    
    for (int i = 0; i < segments; i++) {
      final startAngle = -3.14159 / 2 + i * segmentAngle;
      final sweepAngle = segmentAngle - gapAngle;
      
      final paint = Paint()
        ..color = i < highlightedSegments ? color : color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
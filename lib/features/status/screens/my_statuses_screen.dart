// lib/features/status/screens/my_statuses_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/status/screens/status_viewer_screen.dart';
import 'package:textgb/features/status/status_post_model.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';

class MyStatusesScreen extends StatefulWidget {
  const MyStatusesScreen({Key? key}) : super(key: key);

  @override
  State<MyStatusesScreen> createState() => _MyStatusesScreenState();
}

class _MyStatusesScreenState extends State<MyStatusesScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Fetch statuses when screen loads
    _refreshStatuses();
  }
  
  Future<void> _refreshStatuses() async {
    final currentUser = Provider.of<AuthenticationProvider>(context, listen: false).userModel;
    if (currentUser == null) return;
    
    // Re-fetch to ensure we have the latest data
    await Provider.of<StatusProvider>(context, listen: false).fetchAllStatuses(
      currentUserId: currentUser.uid,
      contactIds: currentUser.contactsUIDs,
    );
  }

  Future<void> _deleteStatus(StatusPostModel status) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = Provider.of<AuthenticationProvider>(context, listen: false).userModel;
      if (currentUser == null) return;

      await Provider.of<StatusProvider>(context, listen: false).deleteStatus(
        statusId: status.statusId,
        creatorUid: currentUser.uid,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _confirmDeleteStatus(StatusPostModel status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Status'),
        content: Text('Are you sure you want to delete this status? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteStatus(status);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToStatusViewer() {
    final currentUser = Provider.of<AuthenticationProvider>(context, listen: false).userModel;
    if (currentUser == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StatusViewerScreen(userId: currentUser.uid),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final statusProvider = Provider.of<StatusProvider>(context);
    final myStatuses = statusProvider.myStatuses;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Status'),
        actions: [
          if (myStatuses.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_circle_outline),
              tooltip: 'Play all',
              onPressed: _navigateToStatusViewer,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshStatuses,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: modernTheme.primaryColor))
            : myStatuses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No status updates yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Create your first status update',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: myStatuses.length,
                    itemBuilder: (context, index) {
                      final status = myStatuses[index];
                      return _buildStatusCard(status);
                    },
                  ),
      ),
    );
  }

  Widget _buildStatusCard(StatusPostModel status) {
    final timeLeft = status.expiresAt.difference(DateTime.now());
    final isExpired = timeLeft.isNegative;
    
    String timeLeftText;
    if (isExpired) {
      timeLeftText = 'Expired';
    } else if (timeLeft.inHours > 0) {
      timeLeftText = '${timeLeft.inHours}h ${timeLeft.inMinutes % 60}m left';
    } else {
      timeLeftText = '${timeLeft.inMinutes}m ${timeLeft.inSeconds % 60}s left';
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status preview
          _buildStatusPreview(status),
          
          // Status info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type and timestamp
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getStatusTypeDisplay(status.type),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getTimeAgo(status.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 4),
                
                // Caption preview
                if (status.caption.isNotEmpty)
                  Text(
                    status.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                
                SizedBox(height: 8),
                
                // Stats row
                Row(
                  children: [
                    // Views
                    Row(
                      children: [
                        Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          '${status.viewCount} views',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(width: 16),
                    
                    // Time left
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 16,
                          color: isExpired ? Colors.red : Colors.grey[600],
                        ),
                        SizedBox(width: 4),
                        Text(
                          timeLeftText,
                          style: TextStyle(
                            color: isExpired ? Colors.red : Colors.grey[600],
                            fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    
                    Spacer(),
                    
                    // Privacy indicator
                    _buildPrivacyIndicator(status),
                  ],
                ),
                
                SizedBox(height: 8),
                
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _confirmDeleteStatus(status),
                      icon: Icon(Icons.delete_outline, size: 18),
                      label: Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to get display name for status type
  String _getStatusTypeDisplay(StatusType type) {
    switch (type) {
      case StatusType.video:
        return 'Video';
      case StatusType.text:
        return 'Text';
      case StatusType.link:
        return 'Link';
      case StatusType.image:
        return 'Photo';
      default:
        return 'Status';
    }
  }
  
  Widget _buildStatusPreview(StatusPostModel status) {
    switch (status.type) {
      case StatusType.video:
        return Container(
          height: 150,
          width: double.infinity,
          color: Colors.black,
          child: status.mediaUrls.isNotEmpty
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    // Video thumbnail
                    if (status.mediaUrls.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: status.mediaUrls.first,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Icon(
                            Icons.video_file,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    
                    // Play button overlay
                    Icon(
                      Icons.play_circle_outline,
                      color: Colors.white.withOpacity(0.8),
                      size: 64,
                    ),
                  ],
                )
              : Center(
                  child: Text(
                    'No video preview available',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
        );
      
      case StatusType.text:
        // Get background color from custom data
        Color backgroundColor = Colors.blue; // Default color
        
        return Container(
          height: 150,
          width: double.infinity,
          color: backgroundColor,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              status.caption,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      
      case StatusType.link:
        // Extract URL from caption or custom data
        String? linkUrl = _extractUrlFromText(status.caption);
        
        return Container(
          height: 150,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.grey[200],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.link, size: 48),
                SizedBox(height: 8),
                if (linkUrl != null)
                  Text(
                    linkUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.blue,
                    ),
                  ),
              ],
            ),
          ),
        );
      
      case StatusType.image:
      default:
        return Container(
          height: 150,
          width: double.infinity,
          color: Colors.grey[300],
          child: status.mediaUrls.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: status.mediaUrls.first,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Icon(Icons.image, size: 48),
                  ),
                )
              : Center(
                  child: Icon(Icons.image, size: 48),
                ),
        );
    }
  }
  
  // Helper to extract URL from text
  String? _extractUrlFromText(String text) {
    final urlRegExp = RegExp(
      r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
      caseSensitive: false,
    );
    final match = urlRegExp.firstMatch(text);
    return match?.group(0);
  }
  
  Widget _buildPrivacyIndicator(StatusPostModel status) {
    IconData icon;
    String text;
    
    // Check privacy settings from the status model
    if (status.isPrivate) {
      if (status.isContactsOnly) {
        // All contacts except specific ones
        icon = Icons.person_remove;
        text = 'Filtered contacts';
      } else {
        // Only specific contacts
        icon = Icons.people;
        text = 'Selected contacts';
      }
    } else {
      // All contacts
      icon = Icons.people;
      text = 'All contacts';
    }
    
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  String _getTimeAgo(DateTime createdAt) {
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
  
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
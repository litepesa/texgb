// lib/features/status/screens/my_statuses_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/status/screens/status_viewer_screen.dart';
import 'package:textgb/features/status/status_post_model.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:textgb/features/status/widgets/status_enums.dart';
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
      body: _isLoading
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
                      status.type.displayName,
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
                    // Video thumbnail (would normally use a package to generate this)
                    Center(
                      child: Icon(
                        Icons.video_file,
                        color: Colors.white,
                        size: 48,
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
        return Container(
          height: 150,
          width: double.infinity,
          color: status.backgroundColor ?? Colors.blue,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              status.caption,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: status.fontName,
              ),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      
      case StatusType.link:
        return Container(
          height: 150,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.grey[200],
          child: status.linkPreviewImage != null
              ? CachedNetworkImage(
                  imageUrl: status.linkPreviewImage!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Icon(Icons.link, size: 48),
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.link, size: 48),
                      SizedBox(height: 8),
                      Text(
                        status.linkUrl ?? 'Link',
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
  
  Widget _buildPrivacyIndicator(StatusPostModel status) {
    IconData icon;
    String text;
    
    switch (status.privacyType) {
      case StatusPrivacyType.except:
        icon = Icons.person_remove;
        text = '${status.excludedContactUIDs.length} excluded';
        break;
      case StatusPrivacyType.only:
        icon = Icons.people;
        text = '${status.includedContactUIDs.length} selected';
        break;
      case StatusPrivacyType.all_contacts:
      default:
        icon = Icons.people;
        text = 'All contacts';
        break;
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
}
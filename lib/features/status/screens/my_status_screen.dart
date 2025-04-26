import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/status_post_model.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';
import 'package:textgb/features/status/widgets/status_video_player.dart';

class MyStatusScreen extends StatefulWidget {
  const MyStatusScreen({Key? key}) : super(key: key);

  @override
  State<MyStatusScreen> createState() => _MyStatusScreenState();
}

class _MyStatusScreenState extends State<MyStatusScreen> {
  bool _isLoading = false;
  List<StatusPostModel> _userStatusPosts = [];

  @override
  void initState() {
    super.initState();
    _fetchUserStatusPosts();
  }

  Future<void> _fetchUserStatusPosts() async {
    setState(() {
      _isLoading = true;
    });

    final currentUser = Provider.of<AuthenticationProvider>(context, listen: false).userModel;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final posts = await Provider.of<StatusProvider>(context, listen: false)
          .fetchUserStatusPosts(currentUser.uid);
      
      setState(() {
        _userStatusPosts = posts;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching your status posts: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteStatusPost(StatusPostModel post) async {
    final currentUser = Provider.of<AuthenticationProvider>(context, listen: false).userModel;
    if (currentUser == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await Provider.of<StatusProvider>(context, listen: false).deleteStatusPost(
        statusId: post.statusId,
        creatorUid: currentUser.uid,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status post deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the list
      await _fetchUserStatusPosts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting status post: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _confirmDeletePost(StatusPostModel post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Status Post'),
        content: Text('Are you sure you want to delete this status post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteStatusPost(post);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showStatusAnalytics(StatusPostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatusAnalyticsSheet(post: post),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No status posts found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Create your first post to share with others',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, Constants.createStatusScreen),
            icon: Icon(Icons.add_circle),
            label: Text('Create New Post'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Status Posts'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            tooltip: 'Create New Post',
            onPressed: () => Navigator.pushNamed(context, Constants.createStatusScreen)
                .then((_) => _fetchUserStatusPosts()),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: modernTheme.primaryColor))
          : _userStatusPosts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchUserStatusPosts,
                  color: modernTheme.primaryColor,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    itemCount: _userStatusPosts.length,
                    itemBuilder: (context, index) {
                      final post = _userStatusPosts[index];
                      return StatusPostCard(
                        post: post,
                        onDelete: () => _confirmDeletePost(post),
                        onViewAnalytics: () => _showStatusAnalytics(post),
                      );
                    },
                  ),
                ),
    );
  }
}

class StatusPostCard extends StatelessWidget {
  final StatusPostModel post;
  final VoidCallback onDelete;
  final VoidCallback onViewAnalytics;

  const StatusPostCard({
    Key? key,
    required this.post,
    required this.onDelete,
    required this.onViewAnalytics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Determine if post is active or expired
    final bool isExpired = post.isExpired;
    final DateTime now = DateTime.now();
    final Duration timeLeft = post.expiresAt.difference(now);
    final String timeLeftText = isExpired 
        ? 'Expired'
        : '${timeLeft.inHours}h ${timeLeft.inMinutes % 60}m left';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isExpired 
            ? BorderSide(color: Colors.grey.withOpacity(0.5), width: 1)
            : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media preview
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 200,
              width: double.infinity,
              child: _buildMediaPreview(context),
            ),
          ),

          // Status info and controls
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Caption
                if (post.caption.isNotEmpty)
                  Text(
                    post.caption,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                SizedBox(height: 12),

                // Analytics summary
                Row(
                  children: [
                    _buildAnalyticItem(context, Icons.visibility, '${post.viewCount}', 'Views'),
                    SizedBox(width: 16),
                    _buildAnalyticItem(context, Icons.favorite, '${post.likeCount}', 'Likes'),
                    Spacer(),
                    Text(
                      timeLeftText,
                      style: TextStyle(
                        fontSize: 12,
                        color: isExpired ? Colors.red : Colors.grey[600],
                        fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Privacy indicator + created date
                Row(
                  children: [
                    Icon(
                      post.isPrivate ? Icons.lock_outline : Icons.public,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 4),
                    Text(
                      post.isPrivate 
                          ? (post.isContactsOnly ? 'Contacts Only' : 'Private') 
                          : 'Public',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Spacer(),
                    Text(
                      'Posted on ${_formatDate(post.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Actions row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onViewAnalytics,
                      icon: Icon(Icons.analytics_outlined, size: 18),
                      label: Text('Analytics'),
                      style: TextButton.styleFrom(
                        foregroundColor: modernTheme.primaryColor,
                      ),
                    ),
                    SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onDelete,
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

  Widget _buildMediaPreview(BuildContext context) {
    if (post.mediaUrls.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: Center(
          child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
        ),
      );
    }

    if (post.type == StatusType.video) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),
          StatusVideoPlayer(
            videoUrl: post.mediaUrls.first,
            autoPlay: false,
          ),
          // Play button overlay
          Center(
            child: Icon(
              Icons.play_circle_outline,
              color: Colors.white.withOpacity(0.8),
              size: 64,
            ),
          ),
        ],
      );
    } else {
      return Stack(
        children: [
          // Image
          CachedNetworkImage(
            imageUrl: post.mediaUrls.first,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: Center(
                child: Icon(Icons.error, color: Colors.red),
              ),
            ),
          ),
          
          // Multiple images indicator
          if (post.mediaUrls.length > 1)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${post.mediaUrls.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }
  }

  Widget _buildAnalyticItem(BuildContext context, IconData icon, String count, String label) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey[600],
        ),
        SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 2) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class StatusAnalyticsSheet extends StatelessWidget {
  final StatusPostModel post;

  const StatusAnalyticsSheet({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.grey[50];
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sheet handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(top: 12, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Status Analytics',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Performance metrics
                  _buildSectionHeader(context, 'Performance Metrics'),
                  SizedBox(height: 16),
                  
                  // Key metrics cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          context, 
                          'Views', 
                          '${post.viewCount}',
                          Icons.visibility,
                          modernTheme.primaryColor!,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          context, 
                          'Likes', 
                          '${post.likeCount}',
                          Icons.favorite,
                          Colors.red,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          context, 
                          'Engagement', 
                          '${_calculateEngagement(post)}%',
                          Icons.trending_up,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 32),
                  
                  // Reach metrics
                  _buildSectionHeader(context, 'Visibility & Reach'),
                  SizedBox(height: 16),
                  
                  _buildInfoRow(context, 'Post Type', _getPostTypeString(post.type)),
                  SizedBox(height: 8),
                  _buildInfoRow(
                    context, 
                    'Privacy', 
                    post.isPrivate 
                        ? (post.isContactsOnly ? 'Visible to all contacts' : 'Visible to selected contacts')
                        : 'Public - Visible to everyone',
                  ),
                  SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    'Status',
                    post.isExpired ? 'Expired' : 'Active',
                  ),
                  
                  SizedBox(height: 32),
                  
                  // Time metrics
                  _buildSectionHeader(context, 'Time Metrics'),
                  SizedBox(height: 16),
                  
                  _buildInfoRow(
                    context,
                    'Posted On',
                    _formatDateTime(post.createdAt),
                  ),
                  SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    'Expires On',
                    _formatDateTime(post.expiresAt),
                  ),
                  SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    'Time Left',
                    post.isExpired
                        ? 'Expired'
                        : _formatDuration(post.expiresAt.difference(DateTime.now())),
                  ),
                  
                  SizedBox(height: 32),
                  
                  // Viewer list
                  _buildSectionHeader(context, 'Viewers (${post.viewerUIDs.length})'),
                  SizedBox(height: 16),
                  
                  post.viewerUIDs.isEmpty
                      ? Text('No viewers yet', style: TextStyle(color: Colors.grey[600]))
                      : Text('Detailed viewer list is not available in this version', 
                          style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, 
    String label, 
    String value, 
    IconData icon,
    Color color,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[800] : Colors.white;
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) {
      return 'Expired';
    }
    
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    
    if (days > 0) {
      return '$days days, $hours hours';
    } else {
      return '$hours hours, $minutes minutes';
    }
  }

  String _getPostTypeString(StatusType type) {
    switch (type) {
      case StatusType.image:
        return post.mediaUrls.length > 1 ? 'Multiple Images' : 'Single Image';
      case StatusType.video:
        return 'Video';
      case StatusType.text:
        return 'Text';
      default:
        return 'Unknown';
    }
  }

  int _calculateEngagement(StatusPostModel post) {
    if (post.viewCount == 0) return 0;
    
    // Simple engagement calculation: likes as percentage of views
    return ((post.likeCount / post.viewCount) * 100).round();
  }
}
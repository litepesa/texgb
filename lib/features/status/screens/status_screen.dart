import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/features/status/screens/create_status_screen.dart';
import 'package:textgb/features/status/screens/status_detail_screen.dart';
import 'package:textgb/features/status/status_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class StatusScreen extends ConsumerStatefulWidget {
  const StatusScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends ConsumerState<StatusScreen> with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  bool _isRefreshing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Load statuses on first render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshStatuses();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshStatuses() async {
    setState(() {
      _isRefreshing = true;
    });
    
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      setState(() {
        _isRefreshing = false;
      });
      return;
    }
    
    await ref.read(statusNotifierProvider.notifier).fetchStatuses(
      currentUserId: currentUser.uid,
      contactIds: currentUser.contactsUIDs,
    );
    
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // Use the modern theme extensions
    final modernTheme = context.modernTheme;
    final primaryColor = modernTheme.primaryColor!;
    final textColor = modernTheme.textColor!;
    final textSecondaryColor = modernTheme.textSecondaryColor!;
    final surfaceColor = modernTheme.surfaceColor!;
    
    // Get the current user
    final currentUser = ref.watch(currentUserProvider);
    
    // Watch the status state
    final statusState = ref.watch(statusNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status', style: TextStyle(fontSize: 22)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshStatuses,
          ),
        ],
      ),
      body: statusState.when(
        data: (state) {
          if (currentUser == null) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }
          
          if (state.isFetching || _isRefreshing) {
            return _buildLoadingView(primaryColor);
          }
          
          final myStatus = state.myStatus;
          final contactStatuses = state.contactStatuses;
          
          // Show empty state if no statuses (yours or contacts')
          if (myStatus == null && contactStatuses.isEmpty) {
            return _buildEmptyState(primaryColor);
          }
          
          return RefreshIndicator(
            onRefresh: _refreshStatuses,
            color: primaryColor,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // My Status Section
                SliverToBoxAdapter(
                  child: _buildMyStatusSection(
                    myStatus,
                    currentUser.name,
                    currentUser.image,
                  ),
                ),
                
                // Recent Updates Header - only show if there are contact statuses
                if (contactStatuses.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                        right: 16.0,
                        top: 16.0,
                        bottom: 8.0,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Recent Updates',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textSecondaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${contactStatuses.length}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Contacts' Statuses
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final status = contactStatuses[index];
                      return _buildContactStatusTile(
                        status, 
                        currentUser.uid, 
                        primaryColor
                      );
                    },
                    childCount: contactStatuses.length,
                  ),
                ),
                
                // Bottom Padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading statuses',
                style: TextStyle(fontSize: 18, color: textColor),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _refreshStatuses,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateStatus(context),
        backgroundColor: primaryColor,
        child: const Icon(Icons.camera_alt),
        tooltip: 'Create new status',
      ),
    );
  }

  Widget _buildLoadingView(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor),
          const SizedBox(height: 16),
          const Text(
            'Loading statuses...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_camera,
            size: 80,
            color: primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'No status updates',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Be the first to share a status update with your contacts',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateStatus(context),
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Create Status'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyStatusSection(
    StatusModel? myStatus,
    String userName, 
    String userImage,
  ) {
    final modernTheme = context.modernTheme;
    final primaryColor = modernTheme.primaryColor!;
    final textColor = modernTheme.textColor!;
    final textSecondaryColor = modernTheme.textSecondaryColor!;
    final surfaceColor = modernTheme.surfaceColor!;
    final hasStatus = myStatus != null;
    
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: modernTheme.dividerColor ?? Colors.grey.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.person, size: 20),
                const SizedBox(width: 8),
                Text(
                  'My Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                if (hasStatus)
                  Text(
                    'Expires in ${_getExpiryTime(myStatus!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondaryColor,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Status content/preview
            Row(
              children: [
                // Status avatar with indicator
                _buildStatusAvatar(
                  userImage,
                  hasStatus,
                  () {
                    if (hasStatus) {
                      _navigateToStatusDetail(context, myStatus!, true);
                    } else {
                      _navigateToCreateStatus(context);
                    }
                  },
                  isMyStatus: true,
                  primaryColor: primaryColor,
                ),
                
                const SizedBox(width: 16),
                
                // Status info and actions
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasStatus ? 'Your Status' : 'Create a Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasStatus 
                            ? 'Tap to view your status'
                            : 'Share photos, videos, or text updates',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action buttons
                if (hasStatus) ...[
                  IconButton(
                    icon: Icon(
                      Icons.visibility,
                      color: primaryColor,
                    ),
                    onPressed: () => _showViewersDialog(myStatus!),
                    tooltip: 'View count',
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _navigateToCreateStatus(context),
                    tooltip: 'Add status',
                  ),
                ],
              ],
            ),
            
            if (hasStatus) ...[
              const SizedBox(height: 16),
              // Status preview thumbnails
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: myStatus!.items.length,
                  itemBuilder: (context, index) {
                    final item = myStatus.items[index];
                    return GestureDetector(
                      onTap: () => _navigateToStatusDetail(context, myStatus, true, initialIndex: index),
                      child: Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: _buildStatusItemThumbnail(item),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusAvatar(
    String imageUrl, 
    bool hasStatus, 
    VoidCallback onTap, 
    {bool isMyStatus = false, 
    required Color primaryColor}
  ) {
    return Stack(
      children: [
        // Circular avatar with border
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: hasStatus
                ? Border.all(
                    color: primaryColor,
                    width: 2,
                  )
                : null,
          ),
          child: CircleAvatar(
            radius: 30,
            backgroundImage: CachedNetworkImageProvider(imageUrl),
          ),
        ),
        
        // Add button for "my status"
        if (isMyStatus)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 12,
                backgroundColor: hasStatus ? Colors.green : primaryColor,
                child: Icon(
                  hasStatus ? Icons.add : Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        
        // Clickable overlay
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildContactStatusTile(StatusModel status, String currentUserId, Color primaryColor) {
    final modernTheme = context.modernTheme;
    final textColor = modernTheme.textColor!;
    final textSecondaryColor = modernTheme.textSecondaryColor!;
    
    // Check if any status items have been viewed by current user
    final bool hasUnviewedStatus = !status.hasUserViewedAll(currentUserId);
    
    // Get the most recent status item timestamp
    final latestTimestamp = status.items
        .map((item) => item.timestamp)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    
    // Format time
    final timeAgo = _getTimeAgo(latestTimestamp);
    
    // Count how many statuses the contact has
    final statusCount = status.items.length;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToStatusDetail(context, status, false),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Status avatar with indicator
              _buildStatusAvatar(
                status.userImage,
                true,
                () => _navigateToStatusDetail(context, status, false),
                isMyStatus: false,
                primaryColor: hasUnviewedStatus ? primaryColor : Colors.grey,
              ),
              
              const SizedBox(width: 16),
              
              // Status info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$statusCount ${statusCount == 1 ? 'update' : 'updates'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Preview indicator
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasUnviewedStatus ? primaryColor : Colors.grey.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: _buildStatusItemThumbnail(status.items.first),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusItemThumbnail(StatusItemModel item) {
    switch (item.type) {
      case StatusType.image:
        return CachedNetworkImage(
          imageUrl: item.mediaUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: const Icon(Icons.image, color: Colors.white),
          ),
        );
      case StatusType.video:
        return Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: item.mediaUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        );
      case StatusType.text:
        return Container(
          color: Colors.purple,
          child: const Center(
            child: Icon(Icons.text_fields, color: Colors.white),
          ),
        );
      default:
        return Container(
          color: Colors.grey[300],
        );
    }
  }
  
  void _navigateToCreateStatus(BuildContext context) {
    // Convert to use a ConsumerWidget when updating CreateStatusScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateStatusScreen(),
      ),
    ).then((_) => _refreshStatuses());
  }
  
  void _navigateToStatusDetail(
    BuildContext context, 
    StatusModel status, 
    bool isMyStatus, 
    {int initialIndex = 0}
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusDetailScreen(
          status: status,
          isMyStatus: isMyStatus,
          initialIndex: initialIndex,
        ),
      ),
    ).then((_) => _refreshStatuses());
  }
  
  void _showViewersDialog(StatusModel status) {
    final modernTheme = context.modernTheme;
    
    // Get total view count across all status items
    int totalViews = 0;
    for (var item in status.items) {
      // Don't count the creator's view
      totalViews += item.viewedBy.length > 0 ? item.viewedBy.length - 1 : 0;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.visibility, size: 24),
            const SizedBox(width: 8),
            Text('Status Views ($totalViews)'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: ListView.builder(
            itemCount: status.items.length,
            itemBuilder: (context, index) {
              final item = status.items[index];
              // Don't count the creator's view
              final viewers = item.viewedBy.length > 0 ? item.viewedBy.length - 1 : 0;
              
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: _buildStatusItemThumbnail(item),
                  ),
                ),
                title: Text(
                  item.type == StatusType.text
                      ? 'Text status'
                      : item.type == StatusType.image
                          ? 'Photo status'
                          : 'Video status',
                ),
                subtitle: Text(
                  item.caption?.isNotEmpty == true
                      ? item.caption!
                      : _getTimeAgo(item.timestamp),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.visibility, size: 16),
                    const SizedBox(width: 4),
                    Text('$viewers'),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return 'Yesterday';
    }
  }
  
  String _getExpiryTime(StatusModel status) {
    final now = DateTime.now();
    final difference = status.expiresAt.difference(now);
    
    if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes.remainder(60)}m';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Expiring soon';
    }
  }
}
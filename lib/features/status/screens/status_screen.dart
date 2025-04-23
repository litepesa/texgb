import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/status/screens/create_status_screen.dart';
import 'package:textgb/features/status/screens/status_detail_screen.dart';
import 'package:textgb/features/status/status_model.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:textgb/features/status/widgets/status_circle.dart';
import 'package:textgb/shared/theme/wechat_theme_extension.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({Key? key}) : super(key: key);

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> with AutomaticKeepAliveClientMixin {
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
    
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    final statusProvider = context.read<StatusProvider>();
    
    await statusProvider.fetchStatuses(
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
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? const Color(0xFF07C160);
    
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
      body: RefreshIndicator(
        onRefresh: _refreshStatuses,
        color: accentColor,
        child: Consumer2<AuthenticationProvider, StatusProvider>(
          builder: (context, authProvider, statusProvider, _) {
            final currentUser = authProvider.userModel;
            
            if (currentUser == null) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (statusProvider.isFetching) {
              return _buildLoadingView();
            }
            
            return CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // My Status Section
                SliverToBoxAdapter(
                  child: _buildMyStatusSection(
                    statusProvider,
                    currentUser.name,
                    currentUser.image,
                  ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildContactStatusTile(StatusModel status, String currentUserId) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    
    // Check if all status items have been viewed by current user
    final bool allViewed = status.hasUserViewedAll(currentUserId);
    
    // Get the most recent status item timestamp
    final latestTimestamp = status.items
        .map((item) => item.timestamp)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    
    // Format time (e.g., "2h ago")
    final timeAgo = _getTimeAgo(latestTimestamp);
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      leading: StatusCircle(
        imageUrl: status.userImage,
        name: status.userName,
        hasStatus: true,
        isViewed: allViewed,
        onTap: () => _navigateToStatusDetail(status, false),
      ),
      title: Text(
        status.userName,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: themeExtension?.textColor ?? Colors.black,
        ),
      ),
      subtitle: Text(
        timeAgo,
        style: TextStyle(
          color: themeExtension?.greyColor ?? Colors.grey,
        ),
      ),
      onTap: () => _navigateToStatusDetail(status, false),
    );
  }
  
  Widget _buildEmptyState(Color accentColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_camera,
            size: 80,
            color: accentColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No status updates',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to create your first status',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToCreateStatus,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Create Status'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
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
                ),
                
                // Recent Updates Header
                if (statusProvider.contactStatuses.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        'Recent Updates',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: themeExtension?.greyColor ?? Colors.grey,
                        ),
                      ),
                    ),
                  ),
                
                // Contacts' Statuses
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final status = statusProvider.contactStatuses[index];
                      return _buildContactStatusTile(status, currentUser.uid);
                    },
                    childCount: statusProvider.contactStatuses.length,
                  ),
                ),
                
                // Empty State
                if (statusProvider.contactStatuses.isEmpty &&
                    statusProvider.myStatus == null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(accentColor),
                  ),
                
                // Bottom Padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateStatus,
        backgroundColor: accentColor,
        child: const Icon(Icons.camera_alt),
        tooltip: 'Create new status',
      ),
    );
  }

  void _navigateToCreateStatus() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateStatusScreen(),
      ),
    );
  }

  void _navigateToStatusDetail(StatusModel status, bool isMyStatus) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusDetailScreen(
          status: status,
          isMyStatus: isMyStatus,
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading statuses...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyStatusSection(StatusProvider statusProvider, String userName, String userImage) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final hasStatus = statusProvider.myStatus != null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
          const SizedBox(height: 8),
          Row(
            children: [
              // My Status Circle
              StatusCircle(
                imageUrl: userImage,
                name: 'My Status',
                hasStatus: hasStatus,
                isMyStatus: true,
                onTap: hasStatus
                    ? () => _navigateToStatusDetail(statusProvider.myStatus!, true)
                    : _navigateToCreateStatus,
              ),
              const SizedBox(width: 16),
              
              // Status info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: themeExtension?.textColor ?? Colors.black,
                      ),
                    ),
                    Text(
                      hasStatus
                          ? 'Tap to view your status'
                          : 'Tap to add status update',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeExtension?.greyColor ?? Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
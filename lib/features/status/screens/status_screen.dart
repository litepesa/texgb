// lib/features/status/screens/status_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/features/status/screens/create_status_screen.dart';
import 'package:textgb/features/status/screens/status_viewer_screen.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';

class StatusScreen extends ConsumerStatefulWidget {
  const StatusScreen({super.key});

  @override
  ConsumerState<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends ConsumerState<StatusScreen>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final modernTheme = context.modernTheme;
    final statusState = ref.watch(statusNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      body: SafeArea(
        child: statusState.when(
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error.toString()),
          data: (state) => _buildStatusContent(state, currentUser?.uid),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final modernTheme = context.modernTheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: modernTheme.primaryColor),
          const SizedBox(height: 16),
          Text(
            'Loading status...',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final modernTheme = context.modernTheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 64,
              color: modernTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load status',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(statusNotifierProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusContent(StatusState state, String? currentUserId) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(statusNotifierProvider);
      },
      child: CustomScrollView(
        slivers: [
          // My Status Section
          SliverToBoxAdapter(
            child: _buildMyStatusSection(state.myStatus, currentUserId),
          ),
          
          // Recent Updates Header
          if (state.unviewedStatus.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildSectionHeader('Recent updates'),
            ),
          
          // Recent Updates List
          if (state.unviewedStatus.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildStatusItem(
                  state.unviewedStatus[index],
                  isUnviewed: true,
                ),
                childCount: state.unviewedStatus.length,
              ),
            ),
          
          // Viewed Updates Header
          if (state.viewedStatus.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildSectionHeader('Viewed updates'),
            ),
          
          // Viewed Updates List
          if (state.viewedStatus.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildStatusItem(
                  state.viewedStatus[index],
                  isUnviewed: false,
                ),
                childCount: state.viewedStatus.length,
              ),
            ),
          
          // Empty State
          if (state.contactsStatus.isEmpty && state.myStatus == null)
            SliverFillRemaining(
              child: _buildEmptyState(),
            ),
          
          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildMyStatusSection(StatusModel? myStatus, String? currentUserId) {
    final modernTheme = context.modernTheme;
    final hasStatus = myStatus != null && myStatus.activeUpdates.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: hasStatus 
            ? () => _viewMyStatus(myStatus)
            : () => _createNewStatus(),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: modernTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: modernTheme.dividerColor!,
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: hasStatus
                          ? Border.all(
                              color: modernTheme.primaryColor!,
                              width: 2,
                            )
                          : null,
                    ),
                    child: CircleAvatar(
                      radius: hasStatus ? 26 : 28,
                      backgroundColor: modernTheme.primaryColor?.withOpacity(0.1),
                      backgroundImage: myStatus?.userImage.isNotEmpty == true
                          ? CachedNetworkImageProvider(myStatus!.userImage)
                          : null,
                      child: myStatus?.userImage.isEmpty != false
                          ? Icon(
                              CupertinoIcons.person,
                              color: modernTheme.primaryColor,
                              size: 28,
                            )
                          : null,
                    ),
                  ),
                  if (!hasStatus)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: modernTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: modernTheme.surfaceColor!,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.add,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Status',
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasStatus 
                          ? _getMyStatusSubtitle(myStatus)
                          : 'Tap to add status update',
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasStatus) ...[
                Icon(
                  CupertinoIcons.ellipsis,
                  color: modernTheme.textSecondaryColor,
                  size: 20,
                ),
              ] else ...[
                Icon(
                  CupertinoIcons.camera_fill,
                  color: modernTheme.primaryColor,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final modernTheme = context.modernTheme;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: modernTheme.textSecondaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusItem(StatusModel status, {required bool isUnviewed}) {
    final modernTheme = context.modernTheme;
    final latestUpdate = status.latestUpdate;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: () => _viewStatus(status),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: modernTheme.surfaceColor,
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isUnviewed 
                  ? modernTheme.primaryColor!
                  : modernTheme.dividerColor!,
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 26,
            backgroundColor: modernTheme.primaryColor?.withOpacity(0.1),
            backgroundImage: status.userImage.isNotEmpty
                ? CachedNetworkImageProvider(status.userImage)
                : null,
            child: status.userImage.isEmpty
                ? Icon(
                    CupertinoIcons.person,
                    color: modernTheme.primaryColor,
                    size: 24,
                  )
                : null,
          ),
        ),
        title: Text(
          status.userName,
          style: TextStyle(
            color: modernTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          latestUpdate != null 
              ? _formatTimestamp(latestUpdate.timestamp)
              : 'No updates',
          style: TextStyle(
            color: modernTheme.textSecondaryColor,
            fontSize: 13,
          ),
        ),
        trailing: isUnviewed
            ? Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: modernTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildEmptyState() {
    final modernTheme = context.modernTheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.chat_bubble_2,
              size: 64,
              color: modernTheme.textSecondaryColor?.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No status updates',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status updates from your contacts will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createNewStatus,
              icon: const Icon(CupertinoIcons.add, color: Colors.white),
              label: const Text('Create Status', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMyStatusSubtitle(StatusModel status) {
    final activeCount = status.activeUpdates.length;
    if (activeCount == 0) return 'No active updates';
    
    final latestUpdate = status.latestUpdate;
    if (latestUpdate == null) return 'No updates';
    
    if (activeCount == 1) {
      return _formatTimestamp(latestUpdate.timestamp);
    } else {
      return '$activeCount updates • ${_formatTimestamp(latestUpdate.timestamp)}';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _createNewStatus() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StatusTypeSelectionScreen(),
      ),
    );
  }

  void _viewMyStatus(StatusModel myStatus) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusViewerScreen(
          status: myStatus,
          allStatuses: [myStatus],
        ),
      ),
    );
  }

  void _viewStatus(StatusModel status) {
    final statusState = ref.read(statusNotifierProvider).valueOrNull;
    if (statusState == null) return;
    
    // Get all unviewed statuses for navigation
    final allStatuses = [
      ...statusState.unviewedStatus,
      ...statusState.viewedStatus,
    ];
    
    final initialIndex = allStatuses.indexWhere((s) => s.id == status.id);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusViewerScreen(
          status: status,
          initialIndex: initialIndex >= 0 ? initialIndex : 0,
          allStatuses: allStatuses,
        ),
      ),
    );
  }
}
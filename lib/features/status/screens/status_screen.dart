// lib/features/status/screens/status_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/features/status/screens/create_status_screen.dart';
import 'package:textgb/features/status/screens/status_viewer_screen.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/enums/enums.dart';

class StatusScreen extends ConsumerStatefulWidget {
  const StatusScreen({super.key});

  @override
  ConsumerState<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends ConsumerState<StatusScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Clean up expired statuses when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(statusNotifierProvider.notifier).cleanupExpiredStatuses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    final currentUser = ref.watch(currentUserProvider);
    final statusStreamAsync = ref.watch(statusStreamProvider);
    
    return Scaffold(
      backgroundColor: theme.surfaceColor,
      body: SafeArea(
        child: statusStreamAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: theme.textSecondaryColor),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: TextStyle(color: theme.textColor, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(color: theme.textSecondaryColor, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          data: (statusGroups) {
            if (currentUser == null) {
              return Center(
                child: Text(
                  'Please sign in to view statuses',
                  style: TextStyle(color: theme.textSecondaryColor),
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    children: [
                      // My Status Section
                      _buildMyStatusSection(statusGroups, currentUser, theme),
                      
                      const SizedBox(height: 8),
                      
                      // Recent Updates Section
                      ...statusGroups
                          .where((group) => !group.isMyStatus && group.hasUnviewedStatuses(currentUser.uid))
                          .isNotEmpty
                          ? [
                              _buildSectionHeader('Recent updates', theme),
                              ...statusGroups
                                  .where((group) => !group.isMyStatus && group.hasUnviewedStatuses(currentUser.uid))
                                  .map((group) => _buildStatusItem(group, currentUser.uid, theme)),
                              const SizedBox(height: 8),
                            ]
                          : [],
                      
                      // Viewed Updates Section
                      ...statusGroups
                          .where((group) => !group.isMyStatus && !group.hasUnviewedStatuses(currentUser.uid))
                          .isNotEmpty
                          ? [
                              _buildSectionHeader('Viewed updates', theme),
                              ...statusGroups
                                  .where((group) => !group.isMyStatus && !group.hasUnviewedStatuses(currentUser.uid))
                                  .map((group) => _buildStatusItem(group, currentUser.uid, theme)),
                            ]
                          : [],
                      
                      // Empty state
                      if (statusGroups.isEmpty)
                        _buildEmptyState(theme),
                      
                      const SizedBox(height: 32), // Bottom padding - reduced since no FAB
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      

    );
  }

  Widget _buildMyStatusSection(List<UserStatusGroup> statusGroups, dynamic currentUser, ModernThemeExtension theme) {
    final myStatusGroup = statusGroups.where((group) => group.isMyStatus).firstOrNull;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('My Status', theme),
        
        InkWell(
          onTap: () {
            if (myStatusGroup != null) {
              // View my status
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StatusViewerScreen(
                    statusGroup: myStatusGroup,
                    currentUserId: currentUser.uid,
                  ),
                ),
              );
            } else {
              // Create new status
              _showCreateStatusOptions();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Profile picture with status ring or add button
                _buildMyStatusAvatar(myStatusGroup, currentUser, theme),
                
                const SizedBox(width: 12),
                
                // Status info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        myStatusGroup != null 
                            ? 'Tap to view • ${myStatusGroup.latestStatusTime}'
                            : 'Tap to add status update',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Options menu for my status - only show delete option now
                if (myStatusGroup != null)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: theme.textSecondaryColor),
                    onSelected: (value) {
                      if (value == 'delete_all') {
                        _deleteAllMyStatuses(myStatusGroup);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete_all',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: theme.textSecondaryColor),
                            const SizedBox(width: 12),
                            Text('Delete all statuses', style: TextStyle(color: theme.textColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyStatusAvatar(UserStatusGroup? myStatusGroup, dynamic currentUser, ModernThemeExtension theme) {
    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: myStatusGroup != null
                ? Border.all(color: theme.primaryColor!, width: 2.5)
                : Border.all(color: theme.dividerColor!, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: ClipOval(
              child: currentUser.image.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: currentUser.image,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: theme.primaryColor?.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          color: theme.primaryColor,
                          size: 24,
                        ),
                      ),
                    )
                  : Container(
                      color: theme.primaryColor?.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        color: theme.primaryColor,
                        size: 24,
                      ),
                    ),
            ),
          ),
        ),
        
        // Add button
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: theme.primaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: theme.surfaceColor!, width: 2),
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, ModernThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.textSecondaryColor,
        ),
      ),
    );
  }

  Widget _buildStatusItem(UserStatusGroup statusGroup, String currentUserId, ModernThemeExtension theme) {
    final hasUnviewed = statusGroup.hasUnviewedStatuses(currentUserId);
    
    return InkWell(
      onTap: () => _viewStatus(statusGroup, currentUserId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Profile picture with status ring
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasUnviewed ? theme.primaryColor! : theme.dividerColor!,
                  width: hasUnviewed ? 2.5 : 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: statusGroup.userImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: statusGroup.userImage,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.person,
                              color: Colors.grey[600],
                              size: 24,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.person,
                            color: Colors.grey[600],
                            size: 24,
                          ),
                        ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Status info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusGroup.userName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusGroup.latestStatusTime,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ModernThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.donut_large_rounded,
            size: 64,
            color: theme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No status updates yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share photos, videos, and text with your contacts that disappear after 24 hours.',
            style: TextStyle(
              fontSize: 14,
              color: theme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }



  void _createTextStatus() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateStatusScreen(
          initialType: StatusType.text,
        ),
      ),
    );
  }

  void _showCreateStatusOptions() {
    final theme = context.modernTheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              'Create Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 20),
            
            // Text status option
            _buildCreateOption(
              icon: Icons.text_fields,
              title: 'Text',
              subtitle: 'Share text with background',
              onTap: () {
                Navigator.pop(context);
                _createTextStatus();
              },
              theme: theme,
            ),
            
            // Photo status option
            _buildCreateOption(
              icon: Icons.image,
              title: 'Photo',
              subtitle: 'Share a photo',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateStatusScreen(
                      initialType: StatusType.image,
                    ),
                  ),
                );
              },
              theme: theme,
            ),
            
            // Video status option
            _buildCreateOption(
              icon: Icons.videocam,
              title: 'Video',
              subtitle: 'Share a video (max 1 minute)',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateStatusScreen(
                      initialType: StatusType.video,
                    ),
                  ),
                );
              },
              theme: theme,
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ModernThemeExtension theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.primaryColor?.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: theme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  void _viewStatus(UserStatusGroup statusGroup, String currentUserId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusViewerScreen(
          statusGroup: statusGroup,
          currentUserId: currentUserId,
        ),
      ),
    );
  }

  void _deleteAllMyStatuses(UserStatusGroup myStatusGroup) {
    final theme = context.modernTheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor,
        title: Text(
          'Delete All Statuses',
          style: TextStyle(color: theme.textColor),
        ),
        content: Text(
          'Are you sure you want to delete all your status updates? This action cannot be undone.',
          style: TextStyle(color: theme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Delete all statuses
              for (final status in myStatusGroup.statuses) {
                await ref.read(statusNotifierProvider.notifier).deleteStatus(status.statusId);
              }
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('All statuses deleted'),
                    backgroundColor: theme.primaryColor,
                  ),
                );
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
// lib/features/status/screens/status_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/features/status/screens/create_text_status_screen.dart';
import 'package:textgb/features/status/screens/status_camera_screen.dart';
import 'package:textgb/features/status/screens/status_viewer_screen.dart';
import 'package:textgb/features/status/screens/my_status_screen.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/time_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StatusScreen extends ConsumerStatefulWidget {
  const StatusScreen({super.key});

  @override
  ConsumerState<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends ConsumerState<StatusScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    final statusState = ref.watch(statusNotifierProvider);
    final contactsStatuses = ref.watch(contactsStatusesStreamProvider);
    final myStatuses = ref.watch(myStatusesStreamProvider);

    return Scaffold(
      backgroundColor: theme.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header section with privacy info
            _buildHeader(theme),
            
            // Status list
            Expanded(
              child: statusState.when(
                data: (state) => _buildStatusList(
                  theme, 
                  state, 
                  contactsStatuses, 
                  myStatuses
                ),
                loading: () => _buildLoadingState(theme),
                error: (error, stack) => _buildErrorState(theme, error.toString()),
              ),
            ),
          ],
        ),
      ),
      
      // Floating action buttons for adding status
      floatingActionButton: _buildFloatingActionButtons(theme),
    );
  }

  Widget _buildHeader(ModernThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            color: theme.textSecondaryColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Status updates are end-to-end encrypted',
              style: TextStyle(
                color: theme.textSecondaryColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusList(
    ModernThemeExtension theme,
    StatusState state,
    AsyncValue<List<UserStatusGroup>> contactsStatuses,
    AsyncValue<List<StatusModel>> myStatuses,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(statusNotifierProvider.notifier).refreshStatuses();
      },
      child: ListView(
        controller: _scrollController,
        children: [
          // My Status Section
          myStatuses.when(
            data: (statuses) => _buildMyStatusSection(theme, statuses),
            loading: () => _buildMyStatusSkeleton(theme),
            error: (error, stack) => const SizedBox.shrink(),
          ),
          
          const SizedBox(height: 8),
          
          // Recent Updates Section
          contactsStatuses.when(
            data: (statusGroups) {
              final recentUpdates = statusGroups
                  .where((group) => group.hasUnviewedStatus)
                  .toList();
              
              final viewedUpdates = statusGroups
                  .where((group) => !group.hasUnviewedStatus)
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recentUpdates.isNotEmpty) ...[
                    _buildSectionHeader('Recent updates', theme),
                    ...recentUpdates.map((group) => 
                        _buildStatusGroupItem(group, theme, hasUnviewed: true)),
                    const SizedBox(height: 8),
                  ],
                  
                  if (viewedUpdates.isNotEmpty) ...[
                    _buildSectionHeader('Viewed updates', theme),
                    ...viewedUpdates.map((group) => 
                        _buildStatusGroupItem(group, theme, hasUnviewed: false)),
                  ],
                ],
              );
            },
            loading: () => _buildContactsStatusSkeleton(theme),
            error: (error, stack) => _buildErrorMessage(theme, 'Failed to load statuses'),
          ),
          
          const SizedBox(height: 100), // Bottom padding for FAB
        ],
      ),
    );
  }

  Widget _buildMyStatusSection(ModernThemeExtension theme, List<StatusModel> myStatuses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('My Status', theme),
        _buildMyStatusItem(theme, myStatuses),
      ],
    );
  }

  Widget _buildMyStatusItem(ModernThemeExtension theme, List<StatusModel> myStatuses) {
    final hasStatuses = myStatuses.isNotEmpty;
    
    return InkWell(
      onTap: () {
        if (hasStatuses) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MyStatusScreen(statuses: myStatuses),
            ),
          );
        } else {
          _showCreateStatusOptions();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Profile picture with status ring or add button
            _buildMyProfilePicture(theme, hasStatuses),
            
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
                    hasStatuses 
                        ? '${myStatuses.length} update${myStatuses.length == 1 ? '' : 's'}'
                        : 'Tap to add status update',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Options menu for my status
            if (hasStatuses)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: theme.textSecondaryColor,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'privacy':
                      _showStatusPrivacyOptions();
                      break;
                    case 'delete_all':
                      _showDeleteAllStatusDialog();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'privacy',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, color: theme.textSecondaryColor),
                        const SizedBox(width: 12),
                        Text('Status privacy', style: TextStyle(color: theme.textColor)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: theme.textSecondaryColor),
                        const SizedBox(width: 12),
                        Text('Delete all', style: TextStyle(color: theme.textColor)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyProfilePicture(ModernThemeExtension theme, bool hasStatuses) {
    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: hasStatuses ? theme.primaryColor! : Colors.transparent,
              width: hasStatuses ? 2.5 : 0,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(hasStatuses ? 3 : 0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor!.withOpacity(0.1),
              ),
              child: Center(
                child: Text(
                  'You',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Add button
        if (!hasStatuses)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.surfaceColor!,
                  width: 2,
                ),
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

  Widget _buildStatusGroupItem(UserStatusGroup group, ModernThemeExtension theme, {required bool hasUnviewed}) {
    return InkWell(
      onTap: () => _viewStatusGroup(group),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Profile picture with status ring
            _buildStatusProfilePicture(group, theme, hasUnviewed),
            
            const SizedBox(width: 12),
            
            // Status info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.userName,
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
                    TimeUtils.getStatusTimeAgo(group.lastStatusTime),
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Unviewed count
            if (hasUnviewed && group.unviewedCount > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${group.unviewedCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusProfilePicture(UserStatusGroup group, ModernThemeExtension theme, bool hasUnviewed) {
    return Container(
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
          child: group.userImage.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: group.userImage,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: theme.primaryColor!.withOpacity(0.1),
                    child: Center(
                      child: Text(
                        group.userName.isNotEmpty ? group.userName[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: theme.primaryColor!.withOpacity(0.1),
                    child: Center(
                      child: Text(
                        group.userName.isNotEmpty ? group.userName[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.primaryColor!.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Text(
                      group.userName.isNotEmpty ? group.userName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ),
        ),
      ),
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

  Widget _buildFloatingActionButtons(ModernThemeExtension theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Text status button
        FloatingActionButton(
          heroTag: "text_status",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateTextStatusScreen(),
              ),
            );
          },
          backgroundColor: theme.surfaceVariantColor,
          child: Icon(
            Icons.edit,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 16),
        
        // Camera status button
        FloatingActionButton(
          heroTag: "camera_status",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StatusCameraScreen(),
              ),
            );
          },
          backgroundColor: theme.primaryColor,
          child: const Icon(
            Icons.camera_alt,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(ModernThemeExtension theme) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(ModernThemeExtension theme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: theme.textSecondaryColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              color: theme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: theme.textSecondaryColor,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(statusNotifierProvider.notifier).refreshStatuses();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMyStatusSkeleton(ModernThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.dividerColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 16,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 150,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsStatusSkeleton(ModernThemeExtension theme) {
    return Column(
      children: List.generate(3, (index) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.dividerColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildErrorMessage(ModernThemeExtension theme, String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.textSecondaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: theme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewStatusGroup(UserStatusGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusViewerScreen(
          statusGroup: group,
          initialIndex: 0,
        ),
      ),
    );
  }

  void _showCreateStatusOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCreateStatusBottomSheet(),
    );
  }

  Widget _buildCreateStatusBottomSheet() {
    final theme = context.modernTheme;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Add Status Update',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Options
            _buildStatusOption(
              icon: Icons.edit,
              title: 'Text',
              subtitle: 'Share a text status',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateTextStatusScreen(),
                  ),
                );
              },
            ),
            
            _buildStatusOption(
              icon: Icons.camera_alt,
              title: 'Camera',
              subtitle: 'Take a photo or video',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StatusCameraScreen(),
                  ),
                );
              },
            ),
            
            _buildStatusOption(
              icon: Icons.photo_library,
              title: 'Gallery',
              subtitle: 'Choose from gallery',
              onTap: () {
                Navigator.pop(context);
                // Navigate to gallery picker
              },
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = context.modernTheme;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.primaryColor!.withOpacity(0.1),
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
              Icons.arrow_forward_ios,
              color: theme.textSecondaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusPrivacyOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildStatusPrivacyBottomSheet(),
    );
  }

  Widget _buildStatusPrivacyBottomSheet() {
    final theme = context.modernTheme;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Status Privacy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Privacy options
            _buildPrivacyOption(
              title: 'My contacts',
              subtitle: 'Share with all your contacts',
              isSelected: true,
              onTap: () {},
            ),
            
            _buildPrivacyOption(
              title: 'My contacts except...',
              subtitle: 'Share with all contacts except selected',
              isSelected: false,
              onTap: () {},
            ),
            
            _buildPrivacyOption(
              title: 'Only share with...',
              subtitle: 'Share with selected contacts only',
              isSelected: false,
              onTap: () {},
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = context.modernTheme;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? theme.primaryColor! : theme.dividerColor!,
                  width: 2,
                ),
                color: isSelected ? theme.primaryColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
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
          ],
        ),
      ),
    );
  }

  void _showDeleteAllStatusDialog() {
    final theme = context.modernTheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor,
        title: Text(
          'Delete All Status Updates?',
          style: TextStyle(color: theme.textColor),
        ),
        content: Text(
          'This will delete all your status updates. This action cannot be undone.',
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
            onPressed: () {
              Navigator.pop(context);
              // Delete all statuses
              _deleteAllStatuses();
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

  void _deleteAllStatuses() async {
    final myStatuses = await ref.read(myStatusesStreamProvider.future);
    
    for (final status in myStatuses) {
      await ref.read(statusNotifierProvider.notifier).deleteStatus(status.statusId);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All status updates deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
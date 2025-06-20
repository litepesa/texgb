// lib/features/public_groups/widgets/public_group_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/public_groups/models/public_group_model.dart';
import 'package:textgb/features/public_groups/providers/public_group_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class PublicGroupAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final PublicGroupModel publicGroup;
  final VoidCallback onBack;
  final VoidCallback onInfo;

  const PublicGroupAppBar({
    super.key,
    required this.publicGroup,
    required this.onBack,
    required this.onInfo,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 0.5);

  @override
  ConsumerState<PublicGroupAppBar> createState() => _PublicGroupAppBarState();
}

class _PublicGroupAppBarState extends ConsumerState<PublicGroupAppBar> {
  bool _isSubscribing = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    final currentUser = ref.watch(currentUserProvider);
    final publicGroupState = ref.watch(publicGroupProvider);
    
    // Get the most up-to-date group data
    final currentGroup = publicGroupState.valueOrNull?.currentPublicGroup ?? widget.publicGroup;
    
    final isSubscribed = currentUser != null && currentGroup.isSubscriber(currentUser.uid);
    final canPost = currentUser != null && currentGroup.canPost(currentUser.uid);

    return AppBar(
      backgroundColor: theme.backgroundColor,
      elevation: 0,
      leading: AppBarBackButton(onPressed: widget.onBack),
      titleSpacing: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(
          height: 0.5,
          width: double.infinity,
          color: theme.dividerColor,
        ),
      ),
      title: InkWell(
        onTap: widget.onInfo,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            children: [
              // Group Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.primaryColor!.withOpacity(0.2),
                    backgroundImage: currentGroup.groupImage.isNotEmpty
                        ? NetworkImage(currentGroup.groupImage)
                        : null,
                    child: currentGroup.groupImage.isEmpty
                        ? Text(
                            currentGroup.groupName.isNotEmpty 
                                ? currentGroup.groupName[0].toUpperCase() 
                                : '?',
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  // Verification badge
                  if (currentGroup.isVerified)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: theme.backgroundColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.backgroundColor!,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.verified,
                          size: 12,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(width: 12),
              
              // Group Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            currentGroup.groupName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Admin badge
                        if (canPost)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor?.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              currentGroup.isCreator(currentUser?.uid ?? '') ? 'OWNER' : 'ADMIN',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 1),
                    
                    Text(
                      currentGroup.getSubscribersText(),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Subscribe/Unsubscribe Button
        if (!canPost) // Don't show subscribe button if user is admin/owner
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: _isSubscribing
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primaryColor,
                    ),
                  )
                : TextButton(
                    onPressed: _handleSubscriptionToggle,
                    style: TextButton.styleFrom(
                      backgroundColor: isSubscribed 
                          ? theme.surfaceVariantColor 
                          : theme.primaryColor,
                      foregroundColor: isSubscribed 
                          ? theme.textColor 
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: const Size(80, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isSubscribed 
                            ? BorderSide(color: theme.borderColor!.withOpacity(0.3))
                            : BorderSide.none,
                      ),
                    ),
                    child: Text(
                      isSubscribed ? 'Following' : 'Follow',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        
        // Menu Button
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: theme.textSecondaryColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) => _handleMenuAction(value),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'info',
              child: _buildMenuItem(
                icon: Icons.info_outline,
                title: 'Group Info',
                theme: theme,
              ),
            ),
            if (isSubscribed) ...[
              PopupMenuItem(
                value: 'notifications',
                child: _buildMenuItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  theme: theme,
                ),
              ),
              const PopupMenuDivider(),
            ],
            if (canPost) ...[
              PopupMenuItem(
                value: 'manage',
                child: _buildMenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Manage Group',
                  theme: theme,
                ),
              ),
              PopupMenuItem(
                value: 'analytics',
                child: _buildMenuItem(
                  icon: Icons.analytics_outlined,
                  title: 'Analytics',
                  theme: theme,
                ),
              ),
              const PopupMenuDivider(),
            ],
            PopupMenuItem(
              value: 'share',
              child: _buildMenuItem(
                icon: Icons.share_outlined,
                title: 'Share Group',
                theme: theme,
              ),
            ),
            if (isSubscribed && !canPost) ...[
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'report',
                child: _buildMenuItem(
                  icon: Icons.report_outlined,
                  title: 'Report',
                  theme: theme,
                  isDestructive: true,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required ModernThemeExtension theme,
    bool isDestructive = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDestructive 
              ? Colors.red 
              : theme.textSecondaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isDestructive 
                  ? Colors.red 
                  : theme.textColor,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubscriptionToggle() async {
    if (_isSubscribing) return;
    
    setState(() {
      _isSubscribing = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      final currentGroup = ref.read(publicGroupProvider).valueOrNull?.currentPublicGroup ?? widget.publicGroup;
      
      if (currentUser != null) {
        final isSubscribed = currentGroup.isSubscriber(currentUser.uid);
        
        if (isSubscribed) {
          await ref.read(publicGroupProvider.notifier)
              .unsubscribeFromPublicGroup(widget.publicGroup.groupId);
          if (mounted) {
            showSnackBar(context, 'Unfollowed ${currentGroup.groupName}');
          }
        } else {
          await ref.read(publicGroupProvider.notifier)
              .subscribeToPublicGroup(widget.publicGroup.groupId);
          if (mounted) {
            showSnackBar(context, 'Now following ${currentGroup.groupName}');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubscribing = false;
        });
      }
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'info':
        widget.onInfo();
        break;
        
      case 'notifications':
        _handleNotificationSettings();
        break;
        
      case 'manage':
        _handleManageGroup();
        break;
        
      case 'analytics':
        _handleAnalytics();
        break;
        
      case 'share':
        _handleShareGroup();
        break;
        
      case 'report':
        _handleReportGroup();
        break;
    }
  }

  void _handleNotificationSettings() {
    // TODO: Implement notification settings
    showSnackBar(context, 'Notification settings coming soon');
  }

  void _handleManageGroup() {
    // TODO: Navigate to manage group screen
    showSnackBar(context, 'Group management coming soon');
  }

  void _handleAnalytics() {
    // TODO: Navigate to analytics screen
    showSnackBar(context, 'Analytics coming soon');
  }

  void _handleShareGroup() {
    // TODO: Implement group sharing
    showSnackBar(context, 'Share functionality coming soon');
  }

  void _handleReportGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Group'),
        content: const Text('Are you sure you want to report this group for violating community guidelines?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement report functionality
              showSnackBar(context, 'Group reported. Thank you for helping keep our community safe.');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }
}
// lib/features/public_groups/screens/public_group_info_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/public_groups/models/public_group_model.dart';
import 'package:textgb/features/public_groups/providers/public_group_provider.dart';
import 'package:textgb/features/public_groups/repositories/public_group_repository.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class PublicGroupInfoScreen extends ConsumerStatefulWidget {
  final PublicGroupModel publicGroup;

  const PublicGroupInfoScreen({
    super.key,
    required this.publicGroup,
  });

  @override
  ConsumerState<PublicGroupInfoScreen> createState() => _PublicGroupInfoScreenState();
}

class _PublicGroupInfoScreenState extends ConsumerState<PublicGroupInfoScreen> {
  bool _isLoading = false;
  bool _isSubscribing = false;
  Map<String, dynamic>? _groupStats;

  @override
  void initState() {
    super.initState();
    _loadGroupStats();
  }

  Future<void> _loadGroupStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await ref.read(publicGroupRepositoryProvider)
          .getPublicGroupStats(widget.publicGroup.groupId);
      
      if (mounted) {
        setState(() {
          _groupStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showSnackBar(context, 'Error loading group stats: $e');
      }
    }
  }

  Future<void> _handleSubscriptionToggle() async {
    if (_isSubscribing) return;
    
    setState(() {
      _isSubscribing = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final isSubscribed = widget.publicGroup.isSubscriber(currentUser.uid);
      
      if (isSubscribed) {
        await ref.read(publicGroupProvider.notifier)
            .unsubscribeFromPublicGroup(widget.publicGroup.groupId);
        if (mounted) {
          showSnackBar(context, 'Unfollowed ${widget.publicGroup.groupName}');
        }
      } else {
        await ref.read(publicGroupProvider.notifier)
            .subscribeToPublicGroup(widget.publicGroup.groupId);
        if (mounted) {
          showSnackBar(context, 'Now following ${widget.publicGroup.groupName}');
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

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    final currentUser = ref.watch(currentUserProvider);
    
    final isSubscribed = currentUser != null && widget.publicGroup.isSubscriber(currentUser.uid);
    final canManage = currentUser != null && widget.publicGroup.canPost(currentUser.uid);
    final isCreator = currentUser != null && widget.publicGroup.isCreator(currentUser.uid);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        title: Text(
          'Group Info',
          style: TextStyle(color: theme.textColor),
        ),
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (canManage)
            IconButton(
              icon: Icon(
                Icons.edit,
                color: theme.primaryColor,
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  Constants.editPublicGroupScreen,
                  arguments: widget.publicGroup,
                );
              },
            ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: theme.textSecondaryColor,
            ),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 12),
                    Text('Share Group'),
                  ],
                ),
              ),
              if (isSubscribed && !canManage) ...[
                PopupMenuItem(
                  value: 'mute',
                  child: Row(
                    children: [
                      Icon(Icons.notifications_off, size: 20),
                      SizedBox(width: 12),
                      Text('Mute Notifications'),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.report, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Report Group', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Header
                  _buildGroupHeader(theme, isSubscribed, canManage, isCreator),
                  
                  // Action Buttons
                  _buildActionButtons(theme, isSubscribed, canManage),
                  
                  // Group Stats
                  if (_groupStats != null) _buildGroupStats(theme),
                  
                  // Description
                  if (widget.publicGroup.groupDescription.isNotEmpty)
                    _buildDescriptionSection(theme),
                  
                  // Admin Section
                  if (canManage) _buildAdminSection(theme),
                  
                  // About Section
                  _buildAboutSection(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildGroupHeader(ModernThemeExtension theme, bool isSubscribed, bool canManage, bool isCreator) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Group Avatar
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: theme.primaryColor!.withOpacity(0.1),
            ),
            child: widget.publicGroup.groupImage.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.network(
                      widget.publicGroup.groupImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildGroupAvatar(theme);
                      },
                    ),
                  )
                : _buildGroupAvatar(theme),
          ),
          
          const SizedBox(height: 16),
          
          // Group Name and Verification
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  widget.publicGroup.groupName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (widget.publicGroup.isVerified) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.verified,
                  size: 28,
                  color: theme.primaryColor,
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Subscribers count
          Text(
            widget.publicGroup.getSubscribersText(),
            style: TextStyle(
              fontSize: 16,
              color: theme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Role Badge
          if (isCreator)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.primaryColor!.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Owner',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (canManage)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.primaryColor!.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Admin',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (isSubscribed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.surfaceVariantColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Follower',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textSecondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupAvatar(ModernThemeExtension theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor!,
            theme.primaryColor!.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Text(
          widget.publicGroup.groupName.isNotEmpty 
              ? widget.publicGroup.groupName[0].toUpperCase() 
              : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ModernThemeExtension theme, bool isSubscribed, bool canManage) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (!canManage) ...[
            Expanded(
              flex: 2,
              child: _isSubscribing
                  ? Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.surfaceVariantColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _handleSubscriptionToggle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSubscribed 
                            ? theme.surfaceVariantColor 
                            : theme.primaryColor,
                        foregroundColor: isSubscribed 
                            ? theme.textColor 
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: isSubscribed 
                              ? BorderSide(color: theme.borderColor!.withOpacity(0.3))
                              : BorderSide.none,
                        ),
                      ),
                      child: Text(
                        isSubscribed ? 'Following' : 'Follow',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
          ],
          
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  Constants.publicGroupFeedScreen,
                  arguments: widget.publicGroup,
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.primaryColor,
                side: BorderSide(color: theme.primaryColor!),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                canManage ? 'Manage Posts' : 'View Posts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupStats(ModernThemeExtension theme) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.borderColor!.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  theme: theme,
                  icon: Icons.post_add,
                  label: 'Posts',
                  value: _groupStats!['postsCount']?.toString() ?? '0',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  theme: theme,
                  icon: Icons.favorite,
                  label: 'Reactions',
                  value: _groupStats!['totalReactions']?.toString() ?? '0',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  theme: theme,
                  icon: Icons.chat_bubble,
                  label: 'Comments',
                  value: _groupStats!['totalComments']?.toString() ?? '0',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required ModernThemeExtension theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: theme.primaryColor,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(ModernThemeExtension theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.borderColor!.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.publicGroup.groupDescription,
            style: TextStyle(
              fontSize: 16,
              color: theme.textSecondaryColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSection(ModernThemeExtension theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.borderColor!.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Tools',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildAdminOption(
            theme: theme,
            icon: Icons.post_add,
            title: 'Create Post',
            subtitle: 'Share content with followers',
            onTap: () {
              Navigator.pushNamed(
                context,
                Constants.createPublicGroupPostScreen,
                arguments: widget.publicGroup,
              );
            },
          ),
          
          _buildAdminOption(
            theme: theme,
            icon: Icons.analytics,
            title: 'Analytics',
            subtitle: 'View group insights',
            onTap: () {
              showSnackBar(context, 'Analytics coming soon');
            },
          ),
          
          _buildAdminOption(
            theme: theme,
            icon: Icons.people,
            title: 'Manage Followers',
            subtitle: 'View and manage subscribers',
            onTap: () {
              showSnackBar(context, 'Follower management coming soon');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminOption({
    required ModernThemeExtension theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
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
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.textTertiaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(ModernThemeExtension theme) {
    final createdDate = widget.publicGroup.createdAt.isNotEmpty
        ? DateTime.fromMillisecondsSinceEpoch(int.parse(widget.publicGroup.createdAt))
        : null;

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.borderColor!.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildDetailItem(
            theme: theme,
            icon: Icons.public,
            label: 'Visibility',
            value: 'Public Group',
          ),
          
          if (createdDate != null)
            _buildDetailItem(
              theme: theme,
              icon: Icons.calendar_today,
              label: 'Created',
              value: '${createdDate.day}/${createdDate.month}/${createdDate.year}',
            ),
          
          _buildDetailItem(
            theme: theme,
            icon: Icons.people,
            label: 'Followers',
            value: widget.publicGroup.getSubscribersText(),
          ),
          
          _buildDetailItem(
            theme: theme,
            icon: Icons.campaign,
            label: 'Type',
            value: 'Broadcast Channel',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required ModernThemeExtension theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.primaryColor,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: theme.textSecondaryColor,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'share':
        showSnackBar(context, 'Share functionality coming soon');
        break;
      case 'mute':
        showSnackBar(context, 'Mute functionality coming soon');
        break;
      case 'report':
        _showReportDialog();
        break;
    }
  }

  void _showReportDialog() {
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
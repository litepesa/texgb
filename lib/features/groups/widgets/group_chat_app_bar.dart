// lib/features/groups/widgets/group_chat_app_bar.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/groups/providers/group_provider.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

// Custom Cache Manager for Group Images
class GroupImageCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'groupImageCache';
  
  static final GroupImageCacheManager _instance = GroupImageCacheManager._();
  factory GroupImageCacheManager() => _instance;
  
  GroupImageCacheManager._() : super(
    Config(
      key,
      stalePeriod: const Duration(hours: 24), // Images stale after 24 hours
      maxNrOfCacheObjects: 200, // Cache up to 200 group images
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}

// Custom Cache Manager for Group Data
class GroupDataCacheManager extends CacheManager {
  static const key = 'groupDataCache';
  
  static final GroupDataCacheManager _instance = GroupDataCacheManager._();
  factory GroupDataCacheManager() => _instance;
  
  GroupDataCacheManager._() : super(
    Config(
      key,
      stalePeriod: const Duration(hours: 2), // Data stale after 2 hours
      maxNrOfCacheObjects: 500, // Cache up to 500 group data objects
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}

class GroupChatAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final GroupModel group;
  final VoidCallback onBack;

  const GroupChatAppBar({
    Key? key,
    required this.group,
    required this.onBack,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 0.5);

  @override
  ConsumerState<GroupChatAppBar> createState() => _GroupChatAppBarState();
}

class _GroupChatAppBarState extends ConsumerState<GroupChatAppBar> 
    with AutomaticKeepAliveClientMixin {
  
  bool _isLoadingGroupData = false;
  GroupModel? _cachedGroup;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCachedGroupData();
    _preloadGroupImage();
  }

  @override
  void didUpdateWidget(GroupChatAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.groupId != widget.group.groupId) {
      _loadCachedGroupData();
      _preloadGroupImage();
    }
  }

  /// Load group data from cache for instant display
  Future<void> _loadCachedGroupData() async {
    if (_isLoadingGroupData) return;
    
    setState(() {
      _isLoadingGroupData = true;
    });

    try {
      final cacheKey = 'group_data_${widget.group.groupId}';
      final cacheFile = await GroupDataCacheManager().getFileFromCache(cacheKey);
      
      if (cacheFile?.file != null) {
        final content = await cacheFile!.file.readAsString();
        final groupMap = jsonDecode(content) as Map<String, dynamic>;
        
        // Check if cache is still valid (less than 1 hour old)
        final cachedAt = groupMap['_cached_at'] as int?;
        if (cachedAt != null) {
          final cacheAge = DateTime.now().millisecondsSinceEpoch - cachedAt;
          if (cacheAge < const Duration(hours: 1).inMilliseconds) {
            // Remove cache metadata
            groupMap.remove('_cached_at');
            groupMap.remove('_cache_version');
            
            final cachedGroup = GroupModel.fromMap(groupMap);
            if (mounted) {
              setState(() {
                _cachedGroup = cachedGroup;
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load cached group data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGroupData = false;
        });
      }
    }
  }

  /// Cache current group data
  Future<void> _cacheGroupData(GroupModel group) async {
    try {
      final cacheKey = 'group_data_${group.groupId}';
      final groupMap = group.toMap();
      
      // Add cache metadata
      groupMap['_cached_at'] = DateTime.now().millisecondsSinceEpoch;
      groupMap['_cache_version'] = '1.0';
      
      final groupData = jsonEncode(groupMap);
      
      await GroupDataCacheManager().putFile(
        cacheKey,
        Uint8List.fromList(utf8.encode(groupData)),
        maxAge: const Duration(hours: 2),
        eTag: 'group_${group.groupId}_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      debugPrint('Failed to cache group data: $e');
    }
  }

  /// Preload group image for faster display
  Future<void> _preloadGroupImage() async {
    if (widget.group.groupImage.isNotEmpty) {
      try {
        await GroupImageCacheManager().downloadFile(
          widget.group.groupImage,
          key: 'group_avatar_${widget.group.groupId}',
        );
      } catch (e) {
        debugPrint('Failed to preload group image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final modernTheme = context.modernTheme;
    
    // Watch the group provider with error handling
    final groupState = ref.watch(groupProvider);
    
    // Use the most up-to-date group data available
    final currentGroup = groupState.valueOrNull?.currentGroup ?? _cachedGroup ?? widget.group;
    final groupMembers = groupState.valueOrNull?.currentGroupMembers ?? [];
    
    // Cache the fresh group data when available
    if (groupState.valueOrNull?.currentGroup != null && 
        groupState.valueOrNull!.currentGroup!.groupId == widget.group.groupId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cacheGroupData(groupState.valueOrNull!.currentGroup!);
      });
    }
    
    // Get current user for admin check
    final currentUser = ref.watch(currentUserProvider);
    
    return AppBar(
      elevation: 0,
      backgroundColor: modernTheme.backgroundColor,
      leading: AppBarBackButton(onPressed: widget.onBack),
      titleSpacing: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(
          height: 0.5,
          width: double.infinity,
          color: modernTheme.dividerColor,
        ),
      ),
      title: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            Constants.groupInformationScreen,
            arguments: currentGroup,
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            children: [
              // Cached Group Profile Image
              Hero(
                tag: 'group_image_${currentGroup.groupId}',
                child: Stack(
                  children: [
                    _buildCachedGroupImage(currentGroup, modernTheme),
                    // Group type indicator
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: modernTheme.backgroundColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: modernTheme.backgroundColor!,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          currentGroup.isPrivate ? Icons.lock : Icons.public,
                          size: 8,
                          color: currentGroup.isPrivate 
                              ? Colors.orange 
                              : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Group info with loading states
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Group name with admin badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            currentGroup.groupName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: modernTheme.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Admin badge with caching consideration
                        if (currentUser != null && currentGroup.isAdmin(currentUser.uid))
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: modernTheme.primaryColor?.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ADMIN',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: modernTheme.primaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    // Members count with smart loading
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMemberCountText(
                            groupMembers, 
                            currentGroup, 
                            groupState.isLoading,
                            modernTheme,
                          ),
                        ),
                        // Encryption indicator
                        if (_shouldShowEncryptionIndicator(groupMembers, currentGroup, groupState.isLoading))
                          Icon(
                            Icons.lock_outline,
                            size: 12,
                            color: modernTheme.textSecondaryColor?.withOpacity(0.6),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Loading indicator for group data
        if (groupState.isLoading && _cachedGroup == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: modernTheme.primaryColor,
              ),
            ),
          )
        else
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: modernTheme.textSecondaryColor,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) => _handleMenuAction(context, ref, value, currentGroup, currentUser),
            itemBuilder: (context) => _buildMenuItems(currentGroup, currentUser, modernTheme),
          ),
      ],
    );
  }

  /// Build cached group image with proper fallbacks
  Widget _buildCachedGroupImage(GroupModel group, ModernThemeExtension theme) {
    if (group.groupImage.isEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: theme.primaryColor?.withOpacity(0.2),
        child: Icon(
          Icons.group,
          color: theme.primaryColor,
          size: 20,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: group.groupImage,
      cacheManager: GroupImageCacheManager(),
      key: ValueKey('group_avatar_${group.groupId}'),
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: 20,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: 20,
        backgroundColor: theme.primaryColor?.withOpacity(0.2),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.primaryColor,
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        // Log error for debugging
        debugPrint('Failed to load group image for ${group.groupId}: $error');
        
        return CircleAvatar(
          radius: 20,
          backgroundColor: theme.primaryColor?.withOpacity(0.2),
          child: Icon(
            Icons.group,
            color: theme.primaryColor,
            size: 20,
          ),
        );
      },
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
      memCacheWidth: 80, // Optimize memory usage
      memCacheHeight: 80,
    );
  }

  /// Build member count text with smart loading states
  Widget _buildMemberCountText(
    List groupMembers, 
    GroupModel group, 
    bool isLoading, 
    ModernThemeExtension theme,
  ) {
    // Show cached data immediately, then update with fresh data
    final memberCount = groupMembers.isNotEmpty 
        ? groupMembers.length 
        : (group.membersUIDs.isNotEmpty ? group.membersUIDs.length : 0);
    
    String text = '';
    if (memberCount == 0 && isLoading) {
      text = 'Loading...';
    } else if (memberCount == 0) {
      text = 'No members';
    } else if (memberCount == 1) {
      text = '1 member';
    } else {
      text = '$memberCount members';
    }
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Text(
        text,
        key: ValueKey(text),
        style: TextStyle(
          fontSize: 12,
          color: theme.textSecondaryColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Determine when to show encryption indicator
  bool _shouldShowEncryptionIndicator(List groupMembers, GroupModel group, bool isLoading) {
    final memberCount = groupMembers.isNotEmpty ? groupMembers.length : group.membersUIDs.length;
    return memberCount > 0 && !isLoading;
  }

  /// Build context menu items
  List<PopupMenuEntry<String>> _buildMenuItems(
    GroupModel group, 
    currentUser, 
    ModernThemeExtension modernTheme,
  ) {
    final items = <PopupMenuEntry<String>>[
      PopupMenuItem(
        value: 'info',
        child: _buildMenuItem(
          icon: Icons.info_outline,
          title: 'Group Info',
          modernTheme: modernTheme,
        ),
      ),
      PopupMenuItem(
        value: 'search',
        child: _buildMenuItem(
          icon: Icons.search,
          title: 'Search Messages',
          modernTheme: modernTheme,
        ),
      ),
      PopupMenuItem(
        value: 'mute',
        child: _buildMenuItem(
          icon: Icons.notifications_off_outlined,
          title: 'Mute Notifications',
          modernTheme: modernTheme,
        ),
      ),
      PopupMenuItem(
        value: 'media',
        child: _buildMenuItem(
          icon: Icons.photo_library_outlined,
          title: 'Media & Files',
          modernTheme: modernTheme,
        ),
      ),
      const PopupMenuDivider(),
    ];

    // Add admin-specific options
    if (currentUser != null && group.isAdmin(currentUser.uid)) {
      items.addAll([
        PopupMenuItem(
          value: 'settings',
          child: _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'Group Settings',
            modernTheme: modernTheme,
          ),
        ),
        if (group.awaitingApprovalUIDs.isNotEmpty)
          PopupMenuItem(
            value: 'requests',
            child: _buildMenuItem(
              icon: Icons.person_add_outlined,
              title: 'Pending Requests (${group.awaitingApprovalUIDs.length})',
              modernTheme: modernTheme,
            ),
          ),
        PopupMenuItem(
          value: 'clear_cache',
          child: _buildMenuItem(
            icon: Icons.cleaning_services_outlined,
            title: 'Clear Cache',
            modernTheme: modernTheme,
          ),
        ),
        const PopupMenuDivider(),
      ]);
    }

    // Add leave group option
    items.add(
      PopupMenuItem(
        value: 'leave',
        child: _buildMenuItem(
          icon: Icons.exit_to_app,
          title: 'Leave Group',
          modernTheme: modernTheme,
          isDestructive: true,
        ),
      ),
    );

    return items;
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required ModernThemeExtension modernTheme,
    bool isDestructive = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDestructive 
              ? Colors.red 
              : modernTheme.textSecondaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isDestructive 
                  ? Colors.red 
                  : modernTheme.textColor,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    GroupModel group,
    currentUser,
  ) async {
    switch (action) {
      case 'info':
        Navigator.pushNamed(
          context,
          Constants.groupInformationScreen,
          arguments: group,
        );
        break;
        
      case 'search':
        showSnackBar(context, 'Message search coming soon');
        break;
        
      case 'mute':
        showSnackBar(context, 'Mute notifications coming soon');
        break;
        
      case 'media':
        showSnackBar(context, 'Media gallery coming soon');
        break;
        
      case 'settings':
        Navigator.pushNamed(
          context,
          Constants.groupSettingsScreen,
          arguments: group,
        );
        break;
        
      case 'requests':
        Navigator.pushNamed(
          context,
          Constants.pendingRequestsScreen,
          arguments: group,
        );
        break;
        
      case 'clear_cache':
        await _clearGroupCache(group);
        if (context.mounted) {
          showSnackBar(context, 'Cache cleared for ${group.groupName}');
        }
        break;
        
      case 'leave':
        _showLeaveGroupDialog(context, ref, group);
        break;
    }
  }

  /// Clear cache for current group
  Future<void> _clearGroupCache(GroupModel group) async {
    try {
      // Clear group data cache
      await GroupDataCacheManager().removeFile('group_data_${group.groupId}');
      
      // Clear group image cache
      await GroupImageCacheManager().removeFile('group_avatar_${group.groupId}');
      
      // Clear local cached data
      if (mounted) {
        setState(() {
          _cachedGroup = null;
        });
      }
      
      // Clear security service cache
      final groupNotifier = ref.read(groupProvider.notifier);
      if (groupNotifier.state.hasValue) {
        // Trigger a refresh of group data
        await groupNotifier.getGroupDetails(group.groupId);
      }
      
    } catch (e) {
      debugPrint('Failed to clear group cache: $e');
    }
  }

  void _showLeaveGroupDialog(
    BuildContext context,
    WidgetRef ref,
    GroupModel group,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.exit_to_app,
              color: Colors.red,
            ),
            const SizedBox(width: 8),
            const Text('Leave Group'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to leave "${group.groupName}"?'),
            const SizedBox(height: 8),
            Text(
              'You will no longer receive messages from this group. Your cached data will also be cleared.',
              style: TextStyle(
                fontSize: 12,
                color: context.modernTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Clear cache before leaving
                await _clearGroupCache(group);
                
                // Leave the group
                await ref.read(groupProvider.notifier).leaveGroup(group.groupId);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  showSnackBar(context, 'You left the group');
                }
              } catch (e) {
                if (context.mounted) {
                  showSnackBar(context, 'Error leaving group: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
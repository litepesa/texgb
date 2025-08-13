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
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _preloadGroupImage();
  }

  @override
  void didUpdateWidget(GroupChatAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.groupId != widget.group.groupId) {
      _preloadGroupImage();
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

  /// Build dropdown menu - matching home screen style
  Widget _buildGroupOptionsMenu() {
    final modernTheme = context.modernTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final menuBgColor = isDark 
      ? modernTheme.surfaceColor!.withOpacity(0.98)
      : modernTheme.surfaceColor!.withOpacity(0.96);

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: modernTheme.textColor,
      ),
      color: menuBgColor,
      elevation: 8,
      surfaceTintColor: modernTheme.primaryColor?.withOpacity(0.1),
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: modernTheme.dividerColor?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      onSelected: (String value) {
        if (value == 'group_info') {
          Navigator.pushNamed(
            context,
            Constants.groupInformationScreen,
            arguments: widget.group,
          );
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'group_info',
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: modernTheme.primaryColor?.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline,
                  color: modernTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Group Info',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final modernTheme = context.modernTheme;
    
    // Watch the group provider to get the latest group data
    final groupState = ref.watch(groupProvider);
    final currentGroup = groupState.valueOrNull?.currentGroup ?? widget.group;
    
    return AppBar(
      elevation: 0,
      backgroundColor: modernTheme.surfaceColor,
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
              // Group Avatar
              _buildGroupAvatar(currentGroup, modernTheme),
              const SizedBox(width: 12),
              
              // Group Name and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Group Name
                    Text(
                      currentGroup.groupName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: modernTheme.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Group Description
                    const SizedBox(height: 1),
                    Text(
                      currentGroup.groupDescription.isNotEmpty 
                          ? currentGroup.groupDescription 
                          : 'Tap for group info',
                      style: TextStyle(
                        fontSize: 12,
                        color: modernTheme.textSecondaryColor,
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
        _buildGroupOptionsMenu(),
        const SizedBox(width: 16),
      ],
    );
  }

  /// Build group avatar with proper fallbacks
  Widget _buildGroupAvatar(GroupModel group, ModernThemeExtension theme) {
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
      memCacheWidth: 80,
      memCacheHeight: 80,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
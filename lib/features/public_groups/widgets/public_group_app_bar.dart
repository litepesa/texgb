// lib/features/public_groups/widgets/public_group_app_bar.dart
import 'package:flutter/material.dart';
import 'package:textgb/features/public_groups/models/public_group_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class PublicGroupAppBar extends StatelessWidget {
  final PublicGroupModel publicGroup;
  final VoidCallback? onBack;
  final VoidCallback? onInfo;

  const PublicGroupAppBar({
    super.key,
    required this.publicGroup,
    this.onBack,
    this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: theme.surfaceColor,
      foregroundColor: theme.textColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.textColor),
        onPressed: onBack ?? () => Navigator.pop(context),
      ),
      actions: [
        if (onInfo != null)
          IconButton(
            icon: Icon(Icons.info_outline, color: theme.textColor),
            onPressed: onInfo,
          ),
        IconButton(
          icon: Icon(Icons.more_vert, color: theme.textColor),
          onPressed: () {
            _showMoreOptions(context);
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.primaryColor!.withOpacity(0.8),
                theme.surfaceColor!,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Group avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: publicGroup.groupImage.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(25),
                                child: Image.network(
                                  publicGroup.groupImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildGroupAvatar(publicGroup.groupName);
                                  },
                                ),
                              )
                            : _buildGroupAvatar(publicGroup.groupName),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Group info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    publicGroup.groupName,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: theme.textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (publicGroup.isVerified)
                                  Icon(
                                    Icons.verified,
                                    size: 24,
                                    color: theme.primaryColor,
                                  ),
                              ],
                            ),
                            
                            const SizedBox(height: 4),
                            
                            Text(
                              publicGroup.getSubscribersText(),
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.textSecondaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            
                            if (publicGroup.groupDescription.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                publicGroup.groupDescription,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.textSecondaryColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        title: Text(
          publicGroup.groupName,
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupAvatar(String groupName) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.white.withOpacity(0.9),
      ),
      child: Center(
        child: Text(
          groupName.isNotEmpty ? groupName[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.blue.shade700,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Group'),
              onTap: () {
                Navigator.pop(context);
                // Handle share
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report Group'),
              onTap: () {
                Navigator.pop(context);
                // Handle report
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block Group'),
              onTap: () {
                Navigator.pop(context);
                // Handle block
              },
            ),
          ],
        ),
      ),
    );
  }
}
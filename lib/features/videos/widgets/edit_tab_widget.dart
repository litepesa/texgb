// lib/features/videos/widgets/edit_tab_widget.dart
import 'package:flutter/material.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class EditTabWidget extends StatelessWidget {
  final VideoModel? video;
  final VoidCallback onAddBannerText;
  final VoidCallback onEditPost;

  const EditTabWidget({
    super.key,
    required this.video,
    required this.onAddBannerText,
    required this.onEditPost,
  });

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Options',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Edit Options
          _buildEditOption(
            'Add Banner Text',
            'Overlay text on your video or image',
            Icons.text_fields,
            onAddBannerText,
            modernTheme,
          ),
          _buildEditOption(
            'Edit Caption',
            'Update your post description',
            Icons.edit_note,
            onEditPost,
            modernTheme,
          ),
          _buildEditOption(
            'Manage Tags',
            'Add or remove hashtags',
            Icons.tag,
            onEditPost,
            modernTheme,
          ),
          _buildEditOption(
            'Privacy Settings',
            'Control who can see this post',
            Icons.privacy_tip,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Privacy settings coming soon!'),
                  backgroundColor: modernTheme.primaryColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            modernTheme,
          ),
          _buildEditOption(
            'Advanced Settings',
            'Comments, downloads, and more',
            Icons.settings,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Advanced settings coming soon!'),
                  backgroundColor: modernTheme.primaryColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            modernTheme,
          ),

          const SizedBox(height: 24),

          // Post Activity Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: modernTheme.primaryColor!.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.toggle_on,
                      color: modernTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Post Activity',
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: video?.isActive ?? true,
                      onChanged: (value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value ? 'Post activated' : 'Post paused',
                            ),
                            backgroundColor: modernTheme.primaryColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      activeColor: modernTheme.primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  video?.isActive ?? true
                      ? 'Your post is visible to viewers'
                      : 'Your post is hidden from viewers',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditOption(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    ModernThemeExtension modernTheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: modernTheme.surfaceColor,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: modernTheme.primaryColor!.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: modernTheme.primaryColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: modernTheme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: modernTheme.textSecondaryColor,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: modernTheme.textSecondaryColor,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}

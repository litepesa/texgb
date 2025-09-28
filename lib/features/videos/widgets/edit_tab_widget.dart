// lib/features/videos/widgets/edit_tab_widget.dart
import 'package:flutter/material.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class EditTabWidget extends StatelessWidget {
  final VideoModel? video;
  final VoidCallback onEditCaption;
  final VoidCallback onUpdatePrice;
  final VoidCallback onUpdateVideoUrl;
  final VoidCallback onUpdateThumbnailUrl;
  final VoidCallback onManageTags;
  final VoidCallback onDeleteVideo;

  const EditTabWidget({
    super.key,
    required this.video,
    required this.onEditCaption,
    required this.onUpdatePrice,
    required this.onUpdateVideoUrl,
    required this.onUpdateThumbnailUrl,
    required this.onManageTags,
    required this.onDeleteVideo,
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
            'Edit Content',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Host Edit Options
          _buildEditOption(
            'Edit Caption',
            'Update your post description and text',
            Icons.edit_note,
            onEditCaption,
            modernTheme,
          ),
          _buildEditOption(
            'Update Price',
            'Set or change content pricing',
            Icons.attach_money,
            onUpdatePrice,
            modernTheme,
          ),
          _buildEditOption(
            'Update Video URL',
            'Change the video source link',
            Icons.video_library,
            onUpdateVideoUrl,
            modernTheme,
          ),
          _buildEditOption(
            'Update Thumbnail',
            'Change video thumbnail image',
            Icons.image,
            onUpdateThumbnailUrl,
            modernTheme,
          ),
          _buildEditOption(
            'Manage Tags',
            'Add or remove hashtags',
            Icons.tag,
            onManageTags,
            modernTheme,
          ),
          
          const SizedBox(height: 24),
          
          // Content Information
          if (video != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: modernTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: modernTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Content Information',
                        style: TextStyle(
                          color: modernTheme.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Content Type', video!.isMultipleImages ? 'Image Gallery' : 'Video', modernTheme),
                  _buildInfoRow('Current Price', video!.formattedPrice, modernTheme),
                  _buildInfoRow('Total Views', video!.formattedViews, modernTheme),
                  _buildInfoRow('Engagement Rate', video!.formattedEngagementRate, modernTheme),
                  _buildInfoRow('Content Tier', video!.contentTier, modernTheme),
                  _buildInfoRow('Created', video!.timeAgo, modernTheme),
                  if (video!.isVerified)
                    _buildInfoRow('Status', '✓ Verified', modernTheme),
                  if (video!.isFeatured)
                    _buildInfoRow('Featured', '⭐ Yes', modernTheme),
                ],
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Danger Zone
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_outlined,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Danger Zone',
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Once you delete this post, there is no going back. Please be certain.',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onDeleteVideo,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade600),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.delete_forever, size: 20),
                    label: const Text('Delete Post Permanently'),
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

  Widget _buildInfoRow(String label, String value, ModernThemeExtension modernTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
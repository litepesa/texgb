import 'package:flutter/material.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class PostDetailsWidget extends StatelessWidget {
  final TextEditingController captionController;
  final TextEditingController tagsController;
  final bool isEnabled;

  const PostDetailsWidget({
    Key? key,
    required this.captionController,
    required this.tagsController,
    required this.isEnabled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Caption field
        Container(
          decoration: BoxDecoration(
            color: modernTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: modernTheme.borderColor ?? modernTheme.primaryColor!.withOpacity(0.1),
            ),
          ),
          child: TextFormField(
            controller: captionController,
            enabled: isEnabled,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Write a caption...',
              hintStyle: TextStyle(
                color: modernTheme.textSecondaryColor,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: TextStyle(
              color: modernTheme.textColor,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Tags field
        Container(
          decoration: BoxDecoration(
            color: modernTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: modernTheme.borderColor ?? modernTheme.primaryColor!.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: tagsController,
                enabled: isEnabled,
                decoration: InputDecoration(
                  hintText: 'Add tags (comma separated)',
                  hintStyle: TextStyle(
                    color: modernTheme.textSecondaryColor,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  prefixIcon: Icon(
                    Icons.tag,
                    color: modernTheme.primaryColor,
                  ),
                ),
                style: TextStyle(
                  color: modernTheme.textColor,
                ),
              ),
              
              // Suggested tags
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSuggestedTag(context, 'trending'),
                    _buildSuggestedTag(context, 'viral'),
                    _buildSuggestedTag(context, 'fyp'),
                    _buildSuggestedTag(context, 'music'),
                    _buildSuggestedTag(context, 'dance'),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Post settings
        Container(
          decoration: BoxDecoration(
            color: modernTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: modernTheme.borderColor ?? modernTheme.primaryColor!.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              _buildSettingRow(
                context,
                icon: Icons.public,
                title: 'Who can view this',
                subtitle: 'Everyone',
                onTap: isEnabled ? () {
                  // TODO: Implement privacy settings
                } : null,
              ),
              Divider(
                height: 1,
                color: modernTheme.dividerColor ?? modernTheme.textSecondaryColor!.withOpacity(0.1),
              ),
              _buildSettingRow(
                context,
                icon: Icons.comment,
                title: 'Allow comments',
                trailing: Switch(
                  value: true,
                  onChanged: isEnabled ? (value) {
                    // TODO: Implement comment toggle
                  } : null,
                  activeColor: modernTheme.primaryColor,
                ),
              ),
              Divider(
                height: 1,
                color: modernTheme.dividerColor ?? modernTheme.textSecondaryColor!.withOpacity(0.1),
              ),
              _buildSettingRow(
                context,
                icon: Icons.download,
                title: 'Allow downloads',
                trailing: Switch(
                  value: true,
                  onChanged: isEnabled ? (value) {
                    // TODO: Implement download toggle
                  } : null,
                  activeColor: modernTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestedTag(BuildContext context, String tag) {
    final modernTheme = context.modernTheme;
    
    return GestureDetector(
      onTap: () {
        final currentTags = tagsController.text.trim();
        if (currentTags.isEmpty) {
          tagsController.text = tag;
        } else {
          tagsController.text = '$currentTags, $tag';
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: modernTheme.primaryColor!.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: modernTheme.primaryColor!.withOpacity(0.3),
          ),
        ),
        child: Text(
          '#$tag',
          style: TextStyle(
            color: modernTheme.primaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final modernTheme = context.modernTheme;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                color: modernTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: modernTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) 
                trailing
              else if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: modernTheme.textSecondaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
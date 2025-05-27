// lib/features/channels/widgets/drafts_sheet_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/services/draft_service.dart';

class DraftsSheetWidget extends StatelessWidget {
  final DraftService draftService;
  final Function(PostDraft) onDraftSelected;
  final VoidCallback? onCreateNew;

  const DraftsSheetWidget({
    Key? key,
    required this.draftService,
    required this.onDraftSelected,
    this.onCreateNew,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Container(
      decoration: BoxDecoration(
        color: modernTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: modernTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Drafts',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (onCreateNew != null)
                  TextButton.icon(
                    onPressed: onCreateNew,
                    icon: Icon(Icons.add, color: modernTheme.primaryColor),
                    label: Text(
                      'New',
                      style: TextStyle(color: modernTheme.primaryColor),
                    ),
                  ),
              ],
            ),
          ),
          
          // Drafts list
          Flexible(
            child: draftService.hasDrafts
                ? ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: draftService.drafts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final draft = draftService.drafts[index];
                      return _buildDraftItem(draft, modernTheme, context);
                    },
                  )
                : _buildEmptyState(modernTheme),
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }

  Widget _buildDraftItem(PostDraft draft, ModernThemeExtension modernTheme, BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onDraftSelected(draft);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: modernTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: modernTheme.borderColor ?? Colors.grey.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              // Media preview
              _buildMediaPreview(draft, modernTheme),
              const SizedBox(width: 16),
              
              // Draft info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.previewText,
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          draft.isVideo ? Icons.videocam : Icons.photo,
                          color: modernTheme.textSecondaryColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${draft.mediaPaths.length} ${draft.isVideo ? 'video' : 'item${draft.mediaPaths.length > 1 ? 's' : ''}'}',
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                        if (draft.tags.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.tag,
                            color: modernTheme.textSecondaryColor,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${draft.tags.length}',
                            style: TextStyle(
                              color: modernTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      draft.timeAgo,
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Actions
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'delete') {
                    await _confirmDelete(context, draft, modernTheme);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red[400]),
                        const SizedBox(width: 8),
                        const Text('Delete'),
                      ],
                    ),
                  ),
                ],
                child: Icon(
                  Icons.more_vert,
                  color: modernTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview(PostDraft draft, ModernThemeExtension modernTheme) {
    if (draft.mediaPaths.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: modernTheme.primaryColor!.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          draft.isVideo ? Icons.videocam : Icons.photo,
          color: modernTheme.primaryColor,
          size: 24,
        ),
      );
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: modernTheme.surfaceColor,
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(draft.mediaPaths.first),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: modernTheme.primaryColor!.withOpacity(0.1),
                child: Icon(
                  draft.isVideo ? Icons.videocam : Icons.photo,
                  color: modernTheme.primaryColor,
                  size: 24,
                ),
              );
            },
          ),
          
          // Video indicator
          if (draft.isVideo)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          
          // Multiple items indicator
          if (draft.mediaPaths.length > 1)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${draft.mediaPaths.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ModernThemeExtension modernTheme) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.drafts_outlined,
            size: 64,
            color: modernTheme.textSecondaryColor!.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No drafts yet',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your drafts will be automatically saved as you create posts',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, PostDraft draft, ModernThemeExtension modernTheme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: modernTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Draft',
          style: TextStyle(color: modernTheme.textColor),
        ),
        content: Text(
          'Are you sure you want to delete this draft? This action cannot be undone.',
          style: TextStyle(color: modernTheme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: modernTheme.textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red[400]),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await draftService.deleteDraft(draft.id);
    }
  }
}
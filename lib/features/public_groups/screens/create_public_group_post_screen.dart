// lib/features/public_groups/screens/create_public_group_post_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/public_groups/models/public_group_model.dart';
import 'package:textgb/features/public_groups/providers/public_group_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class CreatePublicGroupPostScreen extends ConsumerStatefulWidget {
  final PublicGroupModel publicGroup;

  const CreatePublicGroupPostScreen({
    super.key,
    required this.publicGroup,
  });

  @override
  ConsumerState<CreatePublicGroupPostScreen> createState() => _CreatePublicGroupPostScreenState();
}

class _CreatePublicGroupPostScreenState extends ConsumerState<CreatePublicGroupPostScreen> {
  final _contentController = TextEditingController();
  final _focusNode = FocusNode();
  
  List<File> _selectedMedia = [];
  MessageEnum _postType = MessageEnum.text;
  bool _isLoading = false;
  bool _isPinned = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _pickMedia({required bool isVideo}) async {
    if (_selectedMedia.length >= 4) {
      showSnackBar(context, 'Maximum 4 media files allowed');
      return;
    }

    File? media;
    if (isVideo) {
      media = await pickVideo(
        onFail: (error) => showSnackBar(context, error),
      );
    } else {
      media = await pickImage(
        fromCamera: false,
        onFail: (error) => showSnackBar(context, error),
      );
    }

    if (media != null) {
      setState(() {
        _selectedMedia.add(media!);
        _postType = isVideo ? MessageEnum.video : MessageEnum.image;
      });
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
      if (_selectedMedia.isEmpty) {
        _postType = MessageEnum.text;
      }
    });
  }

  void _createPost() async {
    final content = _contentController.text.trim();
    
    if (content.isEmpty && _selectedMedia.isEmpty) {
      showSnackBar(context, 'Please add some content or media');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(publicGroupProvider.notifier).createPost(
        groupId: widget.publicGroup.groupId,
        content: content,
        postType: _postType,
        mediaFiles: _selectedMedia.isNotEmpty ? _selectedMedia : null,
        isPinned: _isPinned,
      );

      if (mounted) {
        showSnackBar(context, 'Post created successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      showSnackBar(context, 'Error creating post: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    final hasContent = _contentController.text.trim().isNotEmpty || _selectedMedia.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Post',
          style: TextStyle(
            color: theme.textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (hasContent && !_isLoading)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: ElevatedButton(
                onPressed: _createPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                child: const Text(
                  'Post',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_isLoading)
            Container(
              margin: const EdgeInsets.only(right: 16),
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.primaryColor,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Group header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor!.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.primaryColor!.withOpacity(0.2),
                  backgroundImage: widget.publicGroup.groupImage.isNotEmpty
                      ? NetworkImage(widget.publicGroup.groupImage)
                      : null,
                  child: widget.publicGroup.groupImage.isEmpty
                      ? Text(
                          widget.publicGroup.groupName[0].toUpperCase(),
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.publicGroup.groupName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                      Text(
                        widget.publicGroup.getSubscribersText(),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      focusNode: _focusNode,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: 'What\'s on your mind?',
                        hintStyle: TextStyle(
                          color: theme.textSecondaryColor,
                          fontSize: 18,
                        ),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 18,
                        height: 1.4,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),

                  // Media preview
                  if (_selectedMedia.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildMediaPreview(theme),
                  ],

                  // Pin option (for admins/owners)
                  if (widget.publicGroup.canPost(ref.watch(publicGroupProvider).value?.getCurrentUserUid() ?? '')) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.surfaceVariantColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.push_pin_outlined,
                            color: theme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Pin this post',
                              style: TextStyle(
                                color: theme.textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Switch(
                            value: _isPinned,
                            onChanged: (value) {
                              setState(() {
                                _isPinned = value;
                              });
                            },
                            activeColor: theme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom toolbar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor!.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                _buildMediaButton(
                  theme: theme,
                  icon: Icons.photo_outlined,
                  label: 'Photo',
                  onTap: () => _pickMedia(isVideo: false),
                ),
                const SizedBox(width: 16),
                _buildMediaButton(
                  theme: theme,
                  icon: Icons.videocam_outlined,
                  label: 'Video',
                  onTap: () => _pickMedia(isVideo: true),
                ),
                const Spacer(),
                Text(
                  '${_selectedMedia.length}/4 media',
                  style: TextStyle(
                    color: theme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaButton({
    required ModernThemeExtension theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.surfaceVariantColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: theme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview(ModernThemeExtension theme) {
    return Container(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedMedia.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final media = _selectedMedia[index];
          final isVideo = _postType == MessageEnum.video;

          return Stack(
            children: [
              Container(
                width: 150,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.surfaceVariantColor,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    media,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (isVideo)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _removeMedia(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
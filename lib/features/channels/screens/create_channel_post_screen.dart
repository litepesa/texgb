// lib/features/channels/screens/create_channel_post_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:textgb/features/channels/models/channel_post_model.dart';
import 'package:textgb/features/channels/providers/channel_posts_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

/// Modern create post screen for channels
class CreateChannelPostScreen extends ConsumerStatefulWidget {
  final String channelId;

  const CreateChannelPostScreen({
    super.key,
    required this.channelId,
  });

  @override
  ConsumerState<CreateChannelPostScreen> createState() => _CreateChannelPostScreenState();
}

class _CreateChannelPostScreenState extends ConsumerState<CreateChannelPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _imagePicker = ImagePicker();

  PostContentType _contentType = PostContentType.text;
  File? _selectedMediaFile;
  List<File> _selectedImages = [];
  bool _isPremium = false;
  int? _priceCoins;
  int? _previewDuration;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: _buildAppBar(theme),
      body: _buildBody(theme),
    );
  }

  PreferredSizeWidget _buildAppBar(ModernThemeExtension theme) {
    return AppBar(
      backgroundColor: theme.surfaceColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close, color: theme.textColor),
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
        if (_isUploading)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 28,
                height: 28,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _uploadProgress,
                      strokeWidth: 3,
                      color: theme.primaryColor,
                    ),
                    Text(
                      '${(_uploadProgress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: theme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: ElevatedButton(
              onPressed: _createPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Post',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
      bottom: _isUploading
          ? PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: theme.dividerColor,
                color: theme.primaryColor,
              ),
            )
          : null,
    );
  }

  Widget _buildBody(ModernThemeExtension theme) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          // Text Input Section
          _buildTextSection(theme),

          // Media Attachment Section
          if (_contentType != PostContentType.text) _buildMediaSection(theme),

          // Content Type Selector
          _buildContentTypeSelector(theme),

          // Premium Settings
          if (_isPremium) _buildPremiumSettings(theme),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTextSection(ModernThemeExtension theme) {
    return Container(
      color: theme.surfaceColor,
      padding: const EdgeInsets.all(16),
      child: TextFormField(
        controller: _textController,
        decoration: InputDecoration(
          hintText: 'Share your thoughts with your subscribers...',
          hintStyle: TextStyle(
            color: theme.textTertiaryColor,
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: TextStyle(
          color: theme.textColor,
          fontSize: 16,
          height: 1.5,
        ),
        maxLines: null,
        minLines: 4,
        maxLength: 5000,
        buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '$currentLength / $maxLength',
              style: TextStyle(
                fontSize: 12,
                color: theme.textTertiaryColor,
              ),
            ),
          );
        },
        validator: (value) {
          if (_contentType == PostContentType.text ||
              _contentType == PostContentType.textImage ||
              _contentType == PostContentType.textVideo) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter some text';
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildMediaSection(ModernThemeExtension theme) {
    return Container(
      color: theme.surfaceColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media Preview - Video or Single Image
          if (_selectedMediaFile != null)
            _buildMediaFilePreview(theme)
          // Media Preview - Multiple Images Grid
          else if (_selectedImages.isNotEmpty)
            _buildImageGridPreview(theme)
          // Add Media Button
          else
            _buildAddMediaButton(theme),

          // Add More Images Button (for image content types)
          if (_selectedImages.isNotEmpty &&
              (_contentType == PostContentType.image || _contentType == PostContentType.textImage) &&
              _selectedImages.length < 10)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton.icon(
                onPressed: _addMoreImages,
                icon: Icon(Icons.add_photo_alternate, size: 20, color: theme.primaryColor),
                label: Text(
                  'Add More (${_selectedImages.length}/10)',
                  style: TextStyle(color: theme.primaryColor),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.primaryColor!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaFilePreview(ModernThemeExtension theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Media Preview
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _contentType == PostContentType.video || _contentType == PostContentType.textVideo
                  ? Container(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_circle_outline, size: 64, color: Colors.white),
                            const SizedBox(height: 8),
                            Text(
                              'Video selected',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Image.file(
                      _selectedMediaFile!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
            ),

            // Remove button
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () {
                    setState(() {
                      _selectedMediaFile = null;
                    });
                  },
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGridPreview(ModernThemeExtension theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate grid layout based on number of images
            if (_selectedImages.length == 1) {
              return _buildSingleImagePreview(_selectedImages[0], 0, theme);
            } else if (_selectedImages.length == 2) {
              return _buildTwoImageGrid(theme);
            } else if (_selectedImages.length == 3) {
              return _buildThreeImageGrid(theme);
            } else if (_selectedImages.length == 4) {
              return _buildFourImageGrid(theme);
            } else {
              return _buildFiveOrMoreImageGrid(theme);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSingleImagePreview(File image, int index, ModernThemeExtension theme) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(image, fit: BoxFit.cover),
          Positioned(
            top: 8,
            right: 8,
            child: _buildRemoveImageButton(index),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoImageGrid(ModernThemeExtension theme) {
    return SizedBox(
      height: 300,
      child: Row(
        children: [
          Expanded(child: _buildGridImageTile(_selectedImages[0], 0)),
          const SizedBox(width: 2),
          Expanded(child: _buildGridImageTile(_selectedImages[1], 1)),
        ],
      ),
    );
  }

  Widget _buildThreeImageGrid(ModernThemeExtension theme) {
    return SizedBox(
      height: 300,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildGridImageTile(_selectedImages[0], 0),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildGridImageTile(_selectedImages[1], 1)),
                const SizedBox(height: 2),
                Expanded(child: _buildGridImageTile(_selectedImages[2], 2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFourImageGrid(ModernThemeExtension theme) {
    return SizedBox(
      height: 300,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildGridImageTile(_selectedImages[0], 0)),
                const SizedBox(width: 2),
                Expanded(child: _buildGridImageTile(_selectedImages[1], 1)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildGridImageTile(_selectedImages[2], 2)),
                const SizedBox(width: 2),
                Expanded(child: _buildGridImageTile(_selectedImages[3], 3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiveOrMoreImageGrid(ModernThemeExtension theme) {
    return SizedBox(
      height: 300,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildGridImageTile(_selectedImages[0], 0)),
                const SizedBox(width: 2),
                Expanded(child: _buildGridImageTile(_selectedImages[1], 1)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildGridImageTile(_selectedImages[2], 2)),
                const SizedBox(width: 2),
                Expanded(child: _buildGridImageTile(_selectedImages[3], 3)),
                const SizedBox(width: 2),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildGridImageTile(_selectedImages[4], 4),
                      if (_selectedImages.length > 5)
                        Container(
                          color: Colors.black.withOpacity(0.6),
                          child: Center(
                            child: Text(
                              '+${_selectedImages.length - 5}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridImageTile(File image, int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(image, fit: BoxFit.cover),
        Positioned(
          top: 4,
          right: 4,
          child: _buildRemoveImageButton(index),
        ),
      ],
    );
  }

  Widget _buildRemoveImageButton(int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.close, color: Colors.white, size: 16),
        onPressed: () {
          setState(() {
            _selectedImages.removeAt(index);
          });
        },
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildAddMediaButton(ModernThemeExtension theme) {
    return InkWell(
      onTap: _pickMedia,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: theme.surfaceVariantColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor!,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor?.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _contentType == PostContentType.video || _contentType == PostContentType.textVideo
                    ? Icons.videocam
                    : Icons.add_photo_alternate,
                size: 40,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _contentType == PostContentType.video || _contentType == PostContentType.textVideo
                  ? 'Add Video'
                  : 'Add Photos',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _contentType == PostContentType.video || _contentType == PostContentType.textVideo
                  ? 'Select from gallery'
                  : 'Select up to 10 photos',
              style: TextStyle(
                color: theme.textSecondaryColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTypeSelector(ModernThemeExtension theme) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: theme.surfaceColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category_outlined, size: 20, color: theme.textSecondaryColor),
              const SizedBox(width: 8),
              Text(
                'Add to your post',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildContentTypeOption(
                theme: theme,
                type: PostContentType.text,
                icon: Icons.text_fields,
                label: 'Text',
                color: Colors.grey,
              ),
              _buildContentTypeOption(
                theme: theme,
                type: PostContentType.image,
                icon: Icons.image,
                label: 'Photo',
                color: Colors.green,
              ),
              _buildContentTypeOption(
                theme: theme,
                type: PostContentType.video,
                icon: Icons.videocam,
                label: 'Video',
                color: Colors.red,
              ),
              _buildContentTypeOption(
                theme: theme,
                type: PostContentType.textImage,
                icon: Icons.article,
                label: 'Text + Photo',
                color: Colors.blue,
              ),
              _buildContentTypeOption(
                theme: theme,
                type: PostContentType.textVideo,
                icon: Icons.video_library,
                label: 'Text + Video',
                color: Colors.purple,
              ),
              _buildPremiumToggle(theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentTypeOption({
    required ModernThemeExtension theme,
    required PostContentType type,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = _contentType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _contentType = type;
          _selectedMediaFile = null;
          _selectedImages = [];
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : theme.surfaceVariantColor,
          border: Border.all(
            color: isSelected ? color : theme.dividerColor!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? color : theme.textSecondaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : theme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumToggle(ModernThemeExtension theme) {
    return InkWell(
      onTap: () {
        setState(() {
          _isPremium = !_isPremium;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _isPremium ? Colors.amber.withOpacity(0.1) : theme.surfaceVariantColor,
          border: Border.all(
            color: _isPremium ? Colors.amber : theme.dividerColor!,
            width: _isPremium ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPremium ? Icons.star : Icons.star_border,
              size: 20,
              color: _isPremium ? Colors.amber : theme.textSecondaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Premium',
              style: TextStyle(
                fontSize: 14,
                fontWeight: _isPremium ? FontWeight.w600 : FontWeight.w500,
                color: _isPremium ? Colors.amber[800] : theme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumSettings(ModernThemeExtension theme) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: theme.surfaceColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, size: 20, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'Premium Content Settings',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Price Input
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Price (Coins)',
              hintText: 'Enter price in coins',
              helperText: 'Minimum 5 coins • You earn 80%',
              prefixIcon: Icon(Icons.monetization_on, color: Colors.amber),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.surfaceVariantColor,
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (_isPremium) {
                if (value == null || value.isEmpty) {
                  return 'Please enter price';
                }
                final price = int.tryParse(value);
                if (price == null || price <= 0) {
                  return 'Please enter a valid price';
                }
                if (price < 5) {
                  return 'Minimum price is 5 coins';
                }
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                _priceCoins = int.tryParse(value);
              });
            },
          ),

          // Preview Duration (for videos)
          if (_contentType == PostContentType.video || _contentType == PostContentType.textVideo) ...[
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Free Preview (seconds)',
                hintText: 'e.g., 30',
                helperText: 'Let users watch a preview before paying',
                prefixIcon: Icon(Icons.play_circle, color: Colors.amber),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.surfaceVariantColor,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _previewDuration = int.tryParse(value);
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickMedia() async {
    if (_contentType == PostContentType.video || _contentType == PostContentType.textVideo) {
      // Pick video
      final video = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _selectedMediaFile = File(video.path);
        });
      }
    } else {
      // Pick multiple images
      final images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images.take(10).map((img) => File(img.path)).toList();
        });
      }
    }
  }

  Future<void> _addMoreImages() async {
    final images = await _imagePicker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        final remainingSlots = 10 - _selectedImages.length;
        _selectedImages.addAll(
          images.take(remainingSlots).map((img) => File(img.path)).toList(),
        );
      });
    }
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate media
    if (_contentType != PostContentType.text) {
      if (_selectedMediaFile == null && _selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select media'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _isUploading = true);

    try {
      final actionsNotifier = ref.read(channelPostActionsProvider.notifier);

      final post = await actionsNotifier.createPost(
        channelId: widget.channelId,
        contentType: _contentType,
        text: _textController.text.trim().isEmpty ? null : _textController.text.trim(),
        mediaFile: _selectedMediaFile,
        imageFiles: _selectedImages,
        isPremium: _isPremium,
        priceCoins: _isPremium ? _priceCoins : null,
        previewDuration: _isPremium ? _previewDuration : null,
        onUploadProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      if (mounted) {
        setState(() => _isUploading = false);

        if (post != null) {
          Navigator.pop(context, post);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post created successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create post'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

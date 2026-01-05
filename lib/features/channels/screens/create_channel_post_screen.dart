// lib/features/channels/screens/create_channel_post_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:textgb/features/channels/models/channel_post_model.dart';
import 'package:textgb/features/channels/providers/channel_posts_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class CreateChannelPostScreen extends ConsumerStatefulWidget {
  final String channelId;

  const CreateChannelPostScreen({
    super.key,
    required this.channelId,
  });

  @override
  ConsumerState<CreateChannelPostScreen> createState() =>
      _CreateChannelPostScreenState();
}

class _CreateChannelPostScreenState
    extends ConsumerState<CreateChannelPostScreen> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  List<File> _selectedImages = [];
  PostContentType _contentType = PostContentType.text;
  bool _isPremium = false;
  int? _priceCoins;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // Pick images from gallery
  Future<void> _pickImages() async {
    try {
      final images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          // Add new images up to max of 10
          final remainingSlots = 10 - _selectedImages.length;
          _selectedImages.addAll(
            images.take(remainingSlots).map((img) => File(img.path)).toList(),
          );
          _updateContentType();
        });
      }
    } catch (e) {
      _showError('Failed to pick images: $e');
    }
  }

  // Take photo with camera
  Future<void> _takePhoto() async {
    try {
      final photo = await _imagePicker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _selectedImages.add(File(photo.path));
          _updateContentType();
        });
      }
    } catch (e) {
      _showError('Failed to take photo: $e');
    }
  }

  // Update content type based on current state
  void _updateContentType() {
    final hasText = _textController.text.trim().isNotEmpty;
    final hasImages = _selectedImages.isNotEmpty;

    if (hasText && hasImages) {
      _contentType = PostContentType.textImage;
    } else if (hasImages) {
      _contentType = PostContentType.image;
    } else {
      _contentType = PostContentType.text;
    }
  }

  // Remove image at index
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _updateContentType();
    });
  }

  // Clear all images
  void _clearAllImages() {
    setState(() {
      _selectedImages.clear();
      _updateContentType();
    });
  }

  // Toggle premium status
  void _togglePremium() {
    if (_isPremium) {
      setState(() {
        _isPremium = false;
        _priceCoins = null;
      });
    } else {
      _showPricingDialog();
    }
  }

  // Show pricing dialog for premium posts
  Future<void> _showPricingDialog() async {
    final controller = TextEditingController(
      text: _priceCoins?.toString() ?? '',
    );

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Price'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Price (coins)',
                hintText: 'e.g., 100',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Users will pay this amount to unlock your post',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = int.tryParse(controller.text);
              if (price != null && price > 0) {
                context.pop(price);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid price')),
                );
              }
            },
            child: const Text('Set Price'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _priceCoins = result;
        _isPremium = true;
      });
    }
  }

  // Post creation
  Future<void> _createPost() async {
    // Validation
    if (_textController.text.trim().isEmpty && _selectedImages.isEmpty) {
      _showError('Please add some content or images');
      return;
    }

    if (_isPremium && (_priceCoins == null || _priceCoins! <= 0)) {
      _showError('Please set a price for premium content');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final actionsNotifier = ref.read(channelPostActionsProvider.notifier);

      final post = await actionsNotifier.createPost(
        channelId: widget.channelId,
        contentType: _contentType,
        text: _textController.text.trim().isEmpty
            ? null
            : _textController.text.trim(),
        imageFiles: _selectedImages.isEmpty ? null : _selectedImages,
        isPremium: _isPremium,
        priceCoins: _priceCoins,
        onUploadProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      if (post != null && mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        _showError('Failed to create post');
      }
    } catch (e) {
      _showError('Error creating post: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;

    return Scaffold(
      backgroundColor: theme.surfaceColor,
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: theme.surfaceColor,
        elevation: 0.5,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
          color: theme.textColor,
        ),
        actions: [
          // Post button - Modern style
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton(
              onPressed: _isUploading ? null : _createPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isUploading
                    ? theme.textSecondaryColor
                    : theme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Post'),
            ),
          ),
        ],
      ),
      body: _isUploading ? _buildUploadingState(theme) : _buildEditor(theme),
    );
  }

  Widget _buildEditor(ModernThemeExtension theme) {
    return Column(
      children: [
        // Main content area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text input
                Container(
                  decoration: BoxDecoration(
                    color: theme.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _textController,
                    maxLines: null,
                    minLines: 3,
                    maxLength: 1000,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "What's on your mind?",
                      hintStyle: TextStyle(
                        fontSize: 17,
                        color: theme.textSecondaryColor,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      counterText: '',
                      filled: true,
                      fillColor: theme.surfaceColor,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(
                      fontSize: 17,
                      color: theme.textColor,
                      height: 1.4,
                    ),
                    onChanged: (_) => setState(() => _updateContentType()),
                  ),
                ),

                const SizedBox(height: 16),

                // Image previews
                if (_selectedImages.isNotEmpty) _buildImagesPreview(theme),

                // Premium indicator
                if (_isPremium) ...[
                  const SizedBox(height: 12),
                  _buildPremiumTag(theme),
                ],
              ],
            ),
          ),
        ),

        // Bottom action bar
        _buildBottomActionBar(theme),
      ],
    );
  }

  Widget _buildImagesPreview(ModernThemeExtension theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Images (${_selectedImages.length}/10)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: _clearAllImages,
              child: const Text('Clear All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount:
              _selectedImages.length + (_selectedImages.length < 10 ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < _selectedImages.length) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImages[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
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
            } else {
              // Add more button
              return GestureDetector(
                onTap: _pickImages,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: const Icon(Icons.add, size: 32),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildPremiumTag(ModernThemeExtension theme) {
    return InkWell(
      onTap: _showPricingDialog,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.monetization_on,
              size: 16,
              color: Colors.amber,
            ),
            const SizedBox(width: 6),
            Text(
              _priceCoins != null
                  ? 'Premium: $_priceCoins coins'
                  : 'Premium (tap to set price)',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.amber,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() {
                _isPremium = false;
                _priceCoins = null;
              }),
              child: const Icon(
                Icons.close,
                size: 18,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(ModernThemeExtension theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor ?? Colors.grey[300]!,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border:
                  Border.all(color: theme.dividerColor ?? Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  'Add to your post',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                const Spacer(),
                // Image button
                _buildActionButton(
                  icon: Icons.photo_library,
                  color: const Color(0xFF45BD62),
                  onTap: _showPhotoOptions,
                ),
                const SizedBox(width: 8),
                // Premium button
                _buildActionButton(
                  icon: _isPremium ? Icons.monetization_on : Icons.attach_money,
                  color: _isPremium
                      ? Colors.amber
                      : theme.textSecondaryColor ?? Colors.grey,
                  onTap: _togglePremium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 24,
          color: color,
        ),
      ),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                context.pop();
                _pickImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () {
                context.pop();
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadingState(ModernThemeExtension theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: theme.primaryColor,
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'Creating your post',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_uploadProgress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 15,
                color: theme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: theme.backgroundColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.primaryColor!,
                  ),
                  minHeight: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

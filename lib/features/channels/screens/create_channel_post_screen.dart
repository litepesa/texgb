// lib/features/channels/screens/create_channel_post_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:textgb/features/channels/models/channel_post_model.dart';
import 'package:textgb/features/channels/providers/channel_posts_provider.dart';

/// Screen for creating a new post in a channel
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          if (_isUploading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: _uploadProgress,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _createPost,
              child: const Text(
                'Post',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Text Content
            TextFormField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'What would you like to share?',
                border: InputBorder.none,
              ),
              maxLines: 8,
              maxLength: 5000,
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
            const SizedBox(height: 16),

            // Media Content Type Selection
            const Text(
              'Content Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              children: [
                _buildContentTypeChip(
                  type: PostContentType.text,
                  icon: Icons.text_fields,
                  label: 'Text Only',
                ),
                _buildContentTypeChip(
                  type: PostContentType.image,
                  icon: Icons.image,
                  label: 'Image',
                ),
                _buildContentTypeChip(
                  type: PostContentType.video,
                  icon: Icons.videocam,
                  label: 'Video',
                ),
                _buildContentTypeChip(
                  type: PostContentType.textImage,
                  icon: Icons.article,
                  label: 'Text + Image',
                ),
                _buildContentTypeChip(
                  type: PostContentType.textVideo,
                  icon: Icons.video_library,
                  label: 'Text + Video',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Media Selection
            if (_contentType != PostContentType.text) ...[
              _buildMediaSection(),
              const SizedBox(height: 16),
            ],

            // Premium Content Toggle
            SwitchListTile(
              value: _isPremium,
              onChanged: (value) {
                setState(() {
                  _isPremium = value;
                });
              },
              title: const Text('Premium Content'),
              subtitle: const Text('Charge subscribers to view this post'),
              secondary: const Icon(Icons.star, color: Colors.amber),
            ),

            // Premium Settings
            if (_isPremium) ...[
              const SizedBox(height: 8),
              Card(
                color: Colors.amber.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.monetization_on, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(
                            'Premium Settings',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Price
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Price (Coins)',
                          hintText: 'e.g., 50',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
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
                      const SizedBox(height: 12),

                      // Preview Duration (for videos)
                      if (_contentType == PostContentType.video ||
                          _contentType == PostContentType.textVideo) ...[
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Free Preview Duration (seconds)',
                            hintText: 'e.g., 30',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            helperText:
                                'How long users can watch before payment is required',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _previewDuration = int.tryParse(value);
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                      ],

                      Text(
                        'Note: Platform takes 20% (You get 80%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Guidelines
            Card(
              color: Colors.blue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Content Guidelines',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildGuideline(
                      'Regular posts: ≤5 minutes or ≤100MB',
                    ),
                    _buildGuideline(
                      'Premium posts: up to 2GB supported',
                    ),
                    _buildGuideline(
                      'Content will be accepted if duration ≤ 5 mins OR size ≤ 100MB',
                    ),
                    _buildGuideline(
                      'Use clear, engaging content to attract subscribers',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTypeChip({
    required PostContentType type,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _contentType == type;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _contentType = type;
            // Clear media when changing type
            _selectedMediaFile = null;
            _selectedImages = [];
          });
        }
      },
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
      ),
    );
  }

  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Media',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Media Preview
        if (_selectedMediaFile != null) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _selectedMediaFile!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _selectedMediaFile = null;
                    });
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ] else if (_selectedImages.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[index],
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            padding: const EdgeInsets.all(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ] else ...[
          InkWell(
            onTap: _pickMedia,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _contentType == PostContentType.video ||
                            _contentType == PostContentType.textVideo
                        ? Icons.videocam
                        : Icons.image,
                    size: 48,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _contentType == PostContentType.video ||
                            _contentType == PostContentType.textVideo
                        ? 'Tap to select video'
                        : 'Tap to select image(s)',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGuideline(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMedia() async {
    if (_contentType == PostContentType.video ||
        _contentType == PostContentType.textVideo) {
      // Pick video
      final video = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _selectedMediaFile = File(video.path);
        });
      }
    } else {
      // Pick image(s)
      final images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images.map((img) => File(img.path)).toList();
        });
      }
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
          const SnackBar(content: Text('Please select media')),
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
        text: _textController.text.trim().isEmpty
            ? null
            : _textController.text.trim(),
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
        if (post != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create post. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isUploading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isUploading = false);
      }
    }
  }
}

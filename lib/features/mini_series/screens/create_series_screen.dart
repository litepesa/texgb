// lib/features/mini_series/screens/create_series_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import '../providers/mini_series_provider.dart';
import '../widgets/tag_input_widget.dart';


class CreateSeriesScreen extends ConsumerStatefulWidget {
  const CreateSeriesScreen({super.key});

  @override
  ConsumerState<CreateSeriesScreen> createState() => _CreateSeriesScreenState();
}

class _CreateSeriesScreenState extends ConsumerState<CreateSeriesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = 'Drama';
  List<String> _tags = [];
  File? _coverImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(seriesCategoriesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Series'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveDraft,
            child: const Text('Save Draft'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cover Image Section
            _buildCoverImageSection(),
            const SizedBox(height: 24),
            
            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Series Title*',
                hintText: 'Enter an engaging title for your series',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                if (value.trim().length < 3) {
                  return 'Title must be at least 3 characters';
                }
                if (value.trim().length > 100) {
                  return 'Title must be less than 100 characters';
                }
                return null;
              },
              maxLength: 100,
            ),
            const SizedBox(height: 16),
            
            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description*',
                hintText: 'Describe your series to attract viewers...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                if (value.trim().length < 10) {
                  return 'Description must be at least 10 characters';
                }
                if (value.trim().length > 500) {
                  return 'Description must be less than 500 characters';
                }
                return null;
              },
              maxLength: 500,
            ),
            const SizedBox(height: 16),
            
            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category*',
                border: OutlineInputBorder(),
              ),
              items: categories.map((category) => DropdownMenuItem(
                value: category,
                child: Text(category),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Tags Section
            _buildTagsSection(),
            const SizedBox(height: 24),
            
            // Info Card
            Card(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Series Guidelines',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('• Maximum 100 episodes per series'),
                    const Text('• Each episode can be up to 2 minutes long'),
                    const Text('• Use engaging titles and descriptions'),
                    const Text('• Add relevant tags to help viewers find your content'),
                    const Text('• Choose an eye-catching cover image'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _saveDraft,
                    child: const Text('Save as Draft'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createAndPublish,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create & Publish'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cover Image*',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickCoverImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: _coverImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _coverImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add cover image',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Recommended: 16:9 aspect ratio',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TagInputWidget(
          tags: _tags,
          onTagsChanged: (tags) {
            setState(() {
              _tags = tags;
            });
          },
          maxTags: 5,
          hintText: 'Add tags to help viewers discover your series...',
        ),
        const SizedBox(height: 8),
        Text(
          'Add up to 5 tags. Use keywords that describe your series content.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Future<void> _pickCoverImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _coverImage = File(image.path);
        });
      }
    } catch (e) {
      showSnackBar(context, 'Error picking image: $e');
    }
  }

  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_coverImage == null) {
      showSnackBar(context, 'Please select a cover image');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final seriesId = await ref.read(miniSeriesProvider.notifier).createSeries(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        tags: _tags,
        coverImage: _coverImage,
      );

      if (seriesId != null) {
        showSnackBar(context, 'Series saved as draft successfully!');
        Navigator.of(context).pop();
      } else {
        showSnackBar(context, 'Failed to save series. Please try again.');
      }
    } catch (e) {
      showSnackBar(context, 'Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createAndPublish() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_coverImage == null) {
      showSnackBar(context, 'Please select a cover image');
      return;
    }

    // Show confirmation dialog
    final shouldPublish = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Series'),
        content: const Text(
          'Are you sure you want to create and publish this series? '
          'Published series will be visible to all users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    if (shouldPublish != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final seriesId = await ref.read(miniSeriesProvider.notifier).createSeries(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        tags: _tags,
        coverImage: _coverImage,
      );

      if (seriesId != null) {
        // Update to published status
        final series = await ref.read(miniSeriesRepositoryProvider).getSeriesById(seriesId);
        if (series != null) {
          await ref.read(miniSeriesProvider.notifier).updateSeries(
            series.copyWith(isPublished: true),
          );
        }

        showSnackBar(context, 'Series created and published successfully!');
        Navigator.of(context).pop();
      } else {
        showSnackBar(context, 'Failed to create series. Please try again.');
      }
    } catch (e) {
      showSnackBar(context, 'Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// lib/features/mini_series/screens/create_episode_screen.dart
class CreateEpisodeScreen extends ConsumerStatefulWidget {
  final String seriesId;
  final String seriesTitle;
  final int episodeNumber;

  const CreateEpisodeScreen({
    super.key,
    required this.seriesId,
    required this.seriesTitle,
    required this.episodeNumber,
  });

  @override
  ConsumerState<CreateEpisodeScreen> createState() => _CreateEpisodeScreenState();
}

class _CreateEpisodeScreenState extends ConsumerState<CreateEpisodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  File? _videoFile;
  File? _thumbnailFile;
  Duration _videoDuration = Duration.zero;
  bool _isPublished = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Episode ${widget.episodeNumber}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Episode ${widget.episodeNumber}'),
        //subtitle: Text(widget.seriesTitle),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Video Section
            _buildVideoSection(),
            const SizedBox(height: 24),
            
            // Thumbnail Section
            _buildThumbnailSection(),
            const SizedBox(height: 24),
            
            // Episode Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Episode Title*',
                hintText: 'Enter episode title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an episode title';
                }
                if (value.trim().length > 100) {
                  return 'Title must be less than 100 characters';
                }
                return null;
              },
              maxLength: 100,
            ),
            const SizedBox(height: 16),
            
            // Episode Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Episode Description',
                hintText: 'Describe what happens in this episode...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 300,
            ),
            const SizedBox(height: 16),
            
            // Publish Toggle
            SwitchListTile(
              title: const Text('Publish immediately'),
              subtitle: const Text('Episode will be visible to viewers'),
              value: _isPublished,
              onChanged: (value) {
                setState(() {
                  _isPublished = value;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Video Requirements Card
            Card(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.video_settings,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Video Requirements',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('• Maximum duration: 2 minutes'),
                    const Text('• Maximum file size: 50MB'),
                    const Text('• Supported formats: MP4, MOV'),
                    const Text('• Recommended resolution: 1080p'),
                    if (_videoDuration > Duration.zero) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Current video duration: ${_formatDuration(_videoDuration)}',
                        style: TextStyle(
                          color: _videoDuration.inSeconds > 120 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Create Button
            ElevatedButton(
              onPressed: _isLoading ? null : _createEpisode,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isPublished ? 'Create & Publish Episode' : 'Save as Draft'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Episode Video*',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickVideo,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: _videoFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.black,
                          child: const Center(
                            child: Icon(
                              Icons.play_circle_outline,
                              color: Colors.white,
                              size: 64,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _formatDuration(_videoDuration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        size: 48,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to select video file',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Max 2 minutes, 50MB',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thumbnail (Optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _pickThumbnail,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: _thumbnailFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _thumbnailFile!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add Thumbnail',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Custom thumbnail helps your episode stand out'),
                  const SizedBox(height: 8),
                  if (_thumbnailFile == null)
                    const Text(
                      'If not provided, a frame from your video will be used automatically',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickVideo() async {
    try {
      final file = await pickVideo(
        onFail: (error) => showSnackBar(context, error),
        maxDuration: const Duration(minutes: 2),
      );
      
      if (file != null) {
        // Get video duration (simplified - in production you'd use video_player)
        final duration = await _getVideoDuration(file);
        
        if (duration.inSeconds > 120) {
          showSnackBar(context, 'Video must be 2 minutes or less');
          return;
        }
        
        setState(() {
          _videoFile = file;
          _videoDuration = duration;
        });
      }
    } catch (e) {
      showSnackBar(context, 'Error selecting video: $e');
    }
  }

  Future<void> _pickThumbnail() async {
    try {
      final file = await pickImage(
        fromCamera: false,
        onFail: (error) => showSnackBar(context, error),
      );
      
      if (file != null) {
        setState(() {
          _thumbnailFile = file;
        });
      }
    } catch (e) {
      showSnackBar(context, 'Error selecting thumbnail: $e');
    }
  }

  Future<Duration> _getVideoDuration(File videoFile) async {
    // Simplified duration detection - in production, use video_player or ffmpeg
    // For now, return a placeholder duration
    return const Duration(seconds: 60);
  }

  Future<void> _createEpisode() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_videoFile == null) {
      showSnackBar(context, 'Please select a video file');
      return;
    }

    if (_videoDuration.inSeconds > 120) {
      showSnackBar(context, 'Video duration must not exceed 2 minutes');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final episodeId = await ref.read(miniSeriesProvider.notifier).createEpisode(
        seriesId: widget.seriesId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        episodeNumber: widget.episodeNumber,
        videoFile: _videoFile!,
        thumbnailFile: _thumbnailFile,
        duration: _videoDuration,
        isPublished: _isPublished,
      );

      if (episodeId != null) {
        showSnackBar(
          context,
          _isPublished ? 'Episode created and published!' : 'Episode saved as draft!',
        );
        Navigator.of(context).pop();
      } else {
        showSnackBar(context, 'Failed to create episode. Please try again.');
      }
    } catch (e) {
      showSnackBar(context, 'Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}

// lib/features/mini_series/widgets/tag_input_widget.dart
class TagInputWidget extends StatefulWidget {
  final List<String> tags;
  final Function(List<String>) onTagsChanged;
  final int maxTags;
  final String hintText;

  const TagInputWidget({
    super.key,
    required this.tags,
    required this.onTagsChanged,
    this.maxTags = 10,
    this.hintText = 'Add tags...',
  });

  @override
  State<TagInputWidget> createState() => _TagInputWidgetState();
}

class _TagInputWidgetState extends State<TagInputWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Tags display
        if (widget.tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.tags.map((tag) => Chip(
              label: Text(tag),
              onDeleted: () => _removeTag(tag),
              deleteIcon: const Icon(Icons.close, size: 16),
            )).toList(),
          ),
          const SizedBox(height: 8),
        ],
        // Tag input field
        if (widget.tags.length < widget.maxTags)
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addTag,
              ),
            ),
            onSubmitted: (_) => _addTag(),
          ),
        if (widget.tags.length >= widget.maxTags)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Maximum ${widget.maxTags} tags allowed',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _addTag() {
    final tag = _controller.text.trim().toLowerCase();
    if (tag.isNotEmpty && 
        !widget.tags.contains(tag) && 
        widget.tags.length < widget.maxTags &&
        tag.length <= 20) {
      widget.onTagsChanged([...widget.tags, tag]);
      _controller.clear();
    }
  }

  void _removeTag(String tag) {
    final updatedTags = widget.tags.where((t) => t != tag).toList();
    widget.onTagsChanged(updatedTags);
  }
}
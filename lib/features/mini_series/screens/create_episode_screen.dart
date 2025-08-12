// lib/features/mini_series/screens/create_episode_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:textgb/features/mini_series/models/episode_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/mini_series_provider.dart';
import '../models/mini_series_model.dart';


class CreateEpisodeScreen extends ConsumerStatefulWidget {
  final String seriesId;
  final String seriesTitle;
  final int episodeNumber;
  final EpisodeModel? existingEpisode; // For editing

  const CreateEpisodeScreen({
    super.key,
    required this.seriesId,
    required this.seriesTitle,
    required this.episodeNumber,
    this.existingEpisode,
  });

  @override
  ConsumerState<CreateEpisodeScreen> createState() => _CreateEpisodeScreenState();
}

class _CreateEpisodeScreenState extends ConsumerState<CreateEpisodeScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  File? _videoFile;
  File? _thumbnailFile;
  VideoPlayerController? _videoController;
  Duration _videoDuration = Duration.zero;
  bool _isPublished = false;
  bool _isLoading = false;
  bool _isProcessingVideo = false;
  
  late AnimationController _uploadAnimationController;
  late Animation<double> _uploadAnimation;
  
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupAnimations();
    _populateExistingData();
  }

  void _initializeControllers() {
    if (widget.existingEpisode == null) {
      _titleController.text = 'Episode ${widget.episodeNumber}';
    }
  }

  void _setupAnimations() {
    _uploadAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _uploadAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _uploadAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _populateExistingData() {
    final episode = widget.existingEpisode;
    if (episode != null) {
      _titleController.text = episode.title;
      _descriptionController.text = episode.description;
      _isPublished = episode.isPublished;
      _videoDuration = episode.duration;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoController?.dispose();
    _uploadAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingEpisode != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Episode' : 'Create Episode ${widget.episodeNumber}'),
        //subtitle: Text(widget.seriesTitle),
        elevation: 0,
        actions: [
          if (!isEditing)
            TextButton(
              onPressed: _isLoading ? null : () => _saveAsDraft(),
              child: const Text('Save Draft'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Progress indicator during upload
            if (_isLoading) _buildUploadProgress(theme),
            
            // Video upload section
            _buildVideoSection(theme),
            const SizedBox(height: 24),
            
            // Thumbnail section
            _buildThumbnailSection(theme),
            const SizedBox(height: 24),
            
            // Episode details
            _buildEpisodeDetailsSection(theme),
            const SizedBox(height: 24),
            
            // Publishing options
            _buildPublishingSection(theme),
            const SizedBox(height: 24),
            
            // Video requirements and tips
            _buildRequirementsCard(theme),
            const SizedBox(height: 32),
            
            // Action buttons
            _buildActionButtons(theme, isEditing),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadProgress(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _uploadAnimation,
                  builder: (context, child) {
                    return CircularProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _uploadStatus,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: theme.colorScheme.surfaceVariant,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(_uploadProgress * 100).toInt()}% complete',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Episode Video*',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Upload your episode video (max 2 minutes, 50MB)',
              child: Icon(
                Icons.help_outline,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        GestureDetector(
          onTap: _isLoading ? null : _pickVideo,
          child: Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _videoFile != null ? Colors.black : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _videoFile != null 
                    ? theme.colorScheme.primary 
                    : Colors.grey[400]!,
                width: _videoFile != null ? 2 : 1,
              ),
            ),
            child: _videoFile != null
                ? _buildVideoPreview(theme)
                : _buildVideoPlaceholder(theme),
          ),
        ),
        
        if (_videoFile != null) ...[
          const SizedBox(height: 12),
          _buildVideoInfo(theme),
        ],
      ],
    );
  }

  Widget _buildVideoPreview(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // Video player or thumbnail
          if (_videoController != null && _videoController!.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            )
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          
          // Overlay controls
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          
          // Play/pause button
          Center(
            child: GestureDetector(
              onTap: _toggleVideoPlayback,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _videoController?.value.isPlaying == true 
                      ? Icons.pause 
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
          
          // Duration and replace button
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Row(
              children: [
                Container(
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickVideo,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Replace'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // Processing indicator
          if (_isProcessingVideo)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.8),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Processing video...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoPlaceholder(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.video_library_outlined,
          size: 48,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 16),
        Text(
          'Tap to select video file',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Maximum 2 minutes • 50MB limit',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _pickVideoFromSource(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _pickVideoFromSource(ImageSource.camera),
              icon: const Icon(Icons.videocam),
              label: const Text('Camera'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVideoInfo(ThemeData theme) {
    final file = _videoFile!;
    final fileSize = file.lengthSync();
    final fileSizeText = _formatFileSize(fileSize);
    final isValidDuration = _videoDuration.inSeconds <= 120;
    final isValidSize = fileSize <= (50 * 1024 * 1024); // 50MB

    return Card(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Video Information',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoItem(
                  'Duration',
                  _formatDuration(_videoDuration),
                  isValidDuration ? Colors.green : Colors.red,
                  isValidDuration ? Icons.check_circle : Icons.error,
                  theme,
                ),
                const SizedBox(width: 24),
                _buildInfoItem(
                  'File Size',
                  fileSizeText,
                  isValidSize ? Colors.green : Colors.red,
                  isValidSize ? Icons.check_circle : Icons.error,
                  theme,
                ),
              ],
            ),
            if (!isValidDuration || !isValidSize) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        !isValidDuration 
                            ? 'Video must be 2 minutes or less'
                            : 'File size must be 50MB or less',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color color, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThumbnailSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Episode Thumbnail',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(Optional)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            // Thumbnail preview
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _isLoading ? null : _pickThumbnail,
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
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add Custom Thumbnail',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Thumbnail options
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thumbnail helps viewers discover your episode',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  
                  if (_thumbnailFile == null && _videoFile != null)
                    ElevatedButton.icon(
                      onPressed: _generateThumbnail,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate from Video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        foregroundColor: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  
                  if (_thumbnailFile != null) ...[
                    ElevatedButton.icon(
                      onPressed: _pickThumbnail,
                      icon: const Icon(Icons.edit),
                      label: const Text('Change Thumbnail'),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => setState(() => _thumbnailFile = null),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Remove'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  Text(
                    _thumbnailFile == null 
                        ? 'If not provided, a frame from your video will be used automatically'
                        : 'Custom thumbnail selected',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
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

  Widget _buildEpisodeDetailsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Episode Details',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Episode title
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Episode Title*',
            hintText: 'Enter a compelling title for this episode',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.title),
            helperText: 'Make it engaging and descriptive',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an episode title';
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
          textCapitalization: TextCapitalization.words,
        ),
        
        const SizedBox(height: 16),
        
        // Episode description
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Episode Description',
            hintText: 'Describe what happens in this episode...',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.description),
            alignLabelWithHint: true,
            helperText: 'Help viewers understand the episode content',
          ),
          maxLines: 4,
          maxLength: 300,
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (value != null && value.length > 300) {
              return 'Description must be less than 300 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPublishingSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Publishing Options',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Publish immediately'),
              subtitle: Text(
                _isPublished 
                    ? 'Episode will be visible to all viewers'
                    : 'Save as draft for now',
              ),
              value: _isPublished,
              onChanged: (value) {
                setState(() {
                  _isPublished = value;
                });
              },
              secondary: Icon(
                _isPublished ? Icons.public : Icons.drafts,
                color: theme.colorScheme.primary,
              ),
            ),
            
            if (!_isPublished) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can publish this episode later from your creator dashboard',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementsCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.primaryContainer.withOpacity(0.1),
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
                  'Video Requirements & Tips',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Requirements
            _buildRequirementItem('Maximum duration: 2 minutes', true),
            _buildRequirementItem('Maximum file size: 50MB', true),
            _buildRequirementItem('Supported formats: MP4, MOV', true),
            _buildRequirementItem('Recommended resolution: 1080p or higher', false),
            
            const SizedBox(height: 16),
            
            // Tips
            Text(
              'Tips for better episodes:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            _buildTipItem('• Keep viewers engaged with quick pacing'),
            _buildTipItem('• Use good lighting and clear audio'),
            _buildTipItem('• Add subtitles for accessibility'),
            _buildTipItem('• End with a hook for the next episode'),
            
            if (_videoDuration > Duration.zero) ...[
              const SizedBox(height: 16),
              Text(
                'Current video: ${_formatDuration(_videoDuration)}',
                style: TextStyle(
                  color: _videoDuration.inSeconds <= 120 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isRequired ? Icons.check_circle : Icons.recommend,
            size: 16,
            color: isRequired ? Colors.green : Colors.blue,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildActionButtons(ThemeData theme, bool isEditing) {
    return Column(
      children: [
        if (!isEditing)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _saveAsDraft,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save as Draft'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createEpisode,
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_isPublished ? Icons.publish : Icons.save),
                  label: Text(_isPublished ? 'Create & Publish' : 'Create Episode'),
                ),
              ),
            ],
          )
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _updateEpisode,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.update),
              label: const Text('Update Episode'),
            ),
          ),
      ],
    );
  }

  // Action methods
  Future<void> _pickVideoFromSource(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 2),
      );
      
      if (video != null) {
        await _processSelectedVideo(File(video.path));
      }
    } catch (e) {
      showSnackBar(context, 'Error selecting video: $e');
    }
  }

  Future<void> _pickVideo() async {
    await _pickVideoFromSource(ImageSource.gallery);
  }

  Future<void> _processSelectedVideo(File videoFile) async {
    setState(() {
      _isProcessingVideo = true;
    });

    try {
      // Check file size
      final fileSize = await videoFile.length();
      if (fileSize > (50 * 1024 * 1024)) {
        showSnackBar(context, 'Video file is too large. Maximum size is 50MB.');
        return;
      }

      // Initialize video controller to get duration
      final controller = VideoPlayerController.file(videoFile);
      await controller.initialize();
      
      final duration = controller.value.duration;
      
      if (duration.inSeconds > 120) {
        showSnackBar(context, 'Video is too long. Maximum duration is 2 minutes.');
        controller.dispose();
        return;
      }

      // Dispose old controller if exists
      _videoController?.dispose();
      
      setState(() {
        _videoFile = videoFile;
        _videoController = controller;
        _videoDuration = duration;
        _isProcessingVideo = false;
      });

      // Auto-generate thumbnail if none exists
      if (_thumbnailFile == null) {
        await _generateThumbnail();
      }
      
    } catch (e) {
      setState(() {
        _isProcessingVideo = false;
      });
      showSnackBar(context, 'Error processing video: $e');
    }
  }

  void _toggleVideoPlayback() {
    if (_videoController?.value.isInitialized == true) {
      setState(() {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
        } else {
          _videoController!.play();
        }
      });
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

  Future<void> _generateThumbnail() async {
    if (_videoFile == null) return;

    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: _videoFile!.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 720,
        quality: 85,
        timeMs: (_videoDuration.inMilliseconds * 0.1).round(), // 10% into video
      );

      if (thumbnailPath != null) {
        setState(() {
          _thumbnailFile = File(thumbnailPath);
        });
        showSnackBar(context, 'Thumbnail generated successfully');
      }
    } catch (e) {
      showSnackBar(context, 'Could not generate thumbnail: $e');
    }
  }

  Future<void> _saveAsDraft() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_videoFile == null) {
      showSnackBar(context, 'Please select a video file');
      return;
    }

    await _createEpisodeWithOptions(isPublished: false);
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

    await _createEpisodeWithOptions(isPublished: _isPublished);
  }

  Future<void> _createEpisodeWithOptions({required bool isPublished}) async {
    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Preparing upload...';
    });

    _uploadAnimationController.repeat();

    try {
      // Simulate upload progress
      await _simulateUploadProgress();

      final episodeId = await ref.read(miniSeriesProvider.notifier).createEpisode(
        seriesId: widget.seriesId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        episodeNumber: widget.episodeNumber,
        videoFile: _videoFile!,
        thumbnailFile: _thumbnailFile,
        duration: _videoDuration,
        isPublished: isPublished,
      );

      if (episodeId != null) {
        _uploadAnimationController.stop();
        showSnackBar(
          context,
          isPublished 
              ? 'Episode created and published successfully!' 
              : 'Episode saved as draft!',
        );
        Navigator.of(context).pop(true); // Return success
      } else {
        throw Exception('Failed to create episode');
      }
    } catch (e) {
      _uploadAnimationController.stop();
      showSnackBar(context, 'Error creating episode: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _uploadProgress = 0.0;
        _uploadStatus = '';
      });
    }
  }

  Future<void> _updateEpisode() async {
    if (!_formKey.currentState!.validate()) return;
    
    final episode = widget.existingEpisode!;

    setState(() {
      _isLoading = true;
      _uploadStatus = 'Updating episode...';
    });

    try {
      await ref.read(miniSeriesProvider.notifier).updateEpisode(
        episode.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          isPublished: _isPublished,
        ),
        videoFile: _videoFile,
        thumbnailFile: _thumbnailFile,
      );

      showSnackBar(context, 'Episode updated successfully!');
      Navigator.of(context).pop(true);
    } catch (e) {
      showSnackBar(context, 'Error updating episode: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _uploadStatus = '';
      });
    }
  }

  Future<void> _simulateUploadProgress() async {
    // Simulate realistic upload progress
    const steps = [
      (0.1, 'Uploading video...'),
      (0.3, 'Processing video...'),
      (0.5, 'Uploading thumbnail...'),
      (0.7, 'Generating metadata...'),
      (0.9, 'Finalizing episode...'),
      (1.0, 'Almost done...'),
    ];

    for (final (progress, status) in steps) {
      setState(() {
        _uploadProgress = progress;
        _uploadStatus = status;
      });
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }
}

// Helper widget for video compression options
class VideoCompressionDialog extends StatefulWidget {
  final File videoFile;
  final Function(File) onCompressed;

  const VideoCompressionDialog({
    super.key,
    required this.videoFile,
    required this.onCompressed,
  });

  @override
  State<VideoCompressionDialog> createState() => _VideoCompressionDialogState();
}

class _VideoCompressionDialogState extends State<VideoCompressionDialog> {
  bool _isCompressing = false;
  double _compressionProgress = 0.0;
  String _selectedQuality = 'medium';

  final Map<String, String> _qualityOptions = {
    'low': 'Low (smallest file)',
    'medium': 'Medium (balanced)',
    'high': 'High (best quality)',
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Compress Video'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Your video is larger than recommended. Would you like to compress it?'),
          const SizedBox(height: 16),
          
          if (!_isCompressing) ...[
            DropdownButtonFormField<String>(
              value: _selectedQuality,
              decoration: const InputDecoration(
                labelText: 'Compression Quality',
                border: OutlineInputBorder(),
              ),
              items: _qualityOptions.entries.map((entry) => DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedQuality = value!;
                });
              },
            ),
          ] else ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Compressing... ${(_compressionProgress * 100).toInt()}%'),
            LinearProgressIndicator(value: _compressionProgress),
          ],
        ],
      ),
      actions: [
        if (!_isCompressing) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Use Original'),
          ),
          ElevatedButton(
            onPressed: _compressVideo,
            child: const Text('Compress'),
          ),
        ],
      ],
    );
  }

  Future<void> _compressVideo() async {
    setState(() {
      _isCompressing = true;
    });

    try {
      // Simulate compression progress
      for (int i = 0; i <= 100; i += 10) {
        setState(() {
          _compressionProgress = i / 100;
        });
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // In a real implementation, you would use video_compress package here
      // For now, we'll just return the original file
      widget.onCompressed(widget.videoFile);
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isCompressing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Compression failed: $e')),
      );
    }
  }
}

// Widget for episode preview before publishing
class EpisodePreviewDialog extends StatelessWidget {
  final String title;
  final String description;
  final File? videoFile;
  final File? thumbnailFile;
  final Duration duration;
  final bool isPublished;

  const EpisodePreviewDialog({
    super.key,
    required this.title,
    required this.description,
    required this.videoFile,
    required this.thumbnailFile,
    required this.duration,
    required this.isPublished,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Text(
                    'Episode Preview',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail
                    if (thumbnailFile != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          thumbnailFile!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Title
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Duration and status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatDuration(duration),
                            style: TextStyle(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPublished 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isPublished ? 'Will Publish' : 'Save as Draft',
                            style: TextStyle(
                              color: isPublished ? Colors.green : Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Description',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(description),
                    ],
                  ],
                ),
              ),
            ),
            
            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(isPublished ? 'Publish' : 'Save Draft'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}
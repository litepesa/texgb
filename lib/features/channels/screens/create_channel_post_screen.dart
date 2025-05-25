import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/channels/widgets/media_editor_screen.dart';
import 'package:textgb/features/channels/widgets/media_selector_widget.dart';
import 'package:textgb/features/channels/widgets/post_details_widget.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/models/edited_media_model.dart';
import 'package:video_player/video_player.dart';

class CreateChannelPostScreen extends ConsumerStatefulWidget {
  const CreateChannelPostScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateChannelPostScreen> createState() => _CreateChannelPostScreenState();
}

class _CreateChannelPostScreenState extends ConsumerState<CreateChannelPostScreen> {
  // Media selection
  EditedMediaModel? _editedMedia;
  bool _isVideoMode = true;
  
  // Post details
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  
  // Video player for preview
  VideoPlayerController? _videoPlayerController;
  
  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _captionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  // Handle media selection
  void _onMediaSelected(File file, bool isVideo) async {
    // Navigate to editor
    final result = await Navigator.push<EditedMediaModel>(
      context,
      MaterialPageRoute(
        builder: (context) => MediaEditorScreen(
          mediaFile: file,
          isVideo: isVideo,
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        _editedMedia = result;
        _isVideoMode = isVideo;
      });
      
      // Initialize video player if it's a video
      if (isVideo && result.processedFile != null) {
        _initializeVideoPlayer(result.processedFile!);
      }
    }
  }

  // Initialize video player
  Future<void> _initializeVideoPlayer(File videoFile) async {
    _videoPlayerController?.dispose();
    _videoPlayerController = VideoPlayerController.file(videoFile);
    await _videoPlayerController!.initialize();
    _videoPlayerController!.setLooping(true);
    setState(() {});
  }

  // Submit the form to create post
  void _submitForm() {
    if (_editedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select and edit media first')),
      );
      return;
    }
    
    if (_captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a caption')),
      );
      return;
    }
    
    final channelVideosNotifier = ref.read(channelVideosProvider.notifier);
    final userChannel = ref.read(channelsProvider).userChannel;
    
    if (userChannel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to create a channel first')),
      );
      return;
    }
    
    // Parse tags from comma-separated string
    List<String> tags = [];
    if (_tagsController.text.isNotEmpty) {
      tags = _tagsController.text.split(',').map((tag) => tag.trim()).toList();
    }
    
    if (_isVideoMode) {
      // Upload video
      channelVideosNotifier.uploadVideo(
        channel: userChannel,
        videoFile: _editedMedia!.processedFile!,
        caption: _captionController.text,
        tags: tags,
        onSuccess: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
          Navigator.of(context).pop(true);
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        },
      );
    } else {
      // Upload images
      channelVideosNotifier.uploadImages(
        channel: userChannel,
        imageFiles: [_editedMedia!.processedFile!],
        caption: _captionController.text,
        tags: tags,
        onSuccess: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
          Navigator.of(context).pop(true);
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final channelVideosState = ref.watch(channelVideosProvider);
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: modernTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Create Post',
          style: TextStyle(
            color: modernTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: modernTheme.textColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_editedMedia != null)
            TextButton(
              onPressed: channelVideosState.isUploading ? null : _submitForm,
              child: Text(
                'Post',
                style: TextStyle(
                  color: modernTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media selector or preview
            if (_editedMedia == null)
              MediaSelectorWidget(
                onMediaSelected: _onMediaSelected,
              )
            else
              _buildMediaPreview(),
            
            const SizedBox(height: 24),
            
            // Upload progress indicator
            if (channelVideosState.isUploading)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: channelVideosState.uploadProgress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(modernTheme.primaryColor!),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Uploading: ${(channelVideosState.uploadProgress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            
            // Post details form
            PostDetailsWidget(
              captionController: _captionController,
              tagsController: _tagsController,
              isEnabled: !channelVideosState.isUploading,
            ),
            
            const SizedBox(height: 24),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: channelVideosState.isUploading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: modernTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: modernTheme.primaryColor!.withOpacity(0.5),
                ),
                child: channelVideosState.isUploading
                    ? const Text('Uploading...')
                    : const Text('Post Content'),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Build media preview widget
  Widget _buildMediaPreview() {
    final modernTheme = context.modernTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _isVideoMode ? 'Video Preview' : 'Image Preview',
              style: TextStyle(
                color: modernTheme.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                // Re-edit the media
                final result = await Navigator.push<EditedMediaModel>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MediaEditorScreen(
                      mediaFile: _editedMedia!.originalFile,
                      isVideo: _isVideoMode,
                      existingEdits: _editedMedia,
                    ),
                  ),
                );
                
                if (result != null) {
                  setState(() {
                    _editedMedia = result;
                  });
                  
                  if (_isVideoMode && result.processedFile != null) {
                    _initializeVideoPlayer(result.processedFile!);
                  }
                }
              },
              icon: const Icon(Icons.edit),
              label: const Text('Re-edit'),
              style: TextButton.styleFrom(
                foregroundColor: modernTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Media preview
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _isVideoMode
              ? _buildVideoPreview()
              : _buildImagePreview(),
        ),
        
        // Applied effects summary
        if (_editedMedia!.hasEdits)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: modernTheme.primaryColor!.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Applied Effects:',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (_editedMedia!.textOverlays.isNotEmpty)
                      _buildEffectChip('${_editedMedia!.textOverlays.length} Text${_editedMedia!.textOverlays.length > 1 ? 's' : ''}'),
                    if (_editedMedia!.stickerOverlays.isNotEmpty)
                      _buildEffectChip('${_editedMedia!.stickerOverlays.length} Sticker${_editedMedia!.stickerOverlays.length > 1 ? 's' : ''}'),
                    if (_editedMedia!.audioTrack != null)
                      _buildEffectChip('Background Music'),
                    if (_editedMedia!.filterType != null)
                      _buildEffectChip(_editedMedia!.filterType!),
                    if (_editedMedia!.beautyLevel > 0)
                      _buildEffectChip('Beauty: ${(_editedMedia!.beautyLevel * 100).toInt()}%'),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEffectChip(String label) {
    final modernTheme = context.modernTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: modernTheme.primaryColor!.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: modernTheme.primaryColor,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (_videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_videoPlayerController!),
            // Play button overlay
            IconButton(
              onPressed: () {
                setState(() {
                  if (_videoPlayerController!.value.isPlaying) {
                    _videoPlayerController!.pause();
                  } else {
                    _videoPlayerController!.play();
                  }
                });
              },
              icon: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _videoPlayerController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return const AspectRatio(
        aspectRatio: 9 / 16,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }

  Widget _buildImagePreview() {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Image.file(
        _editedMedia!.processedFile!,
        fit: BoxFit.cover,
      ),
    );
  }
}
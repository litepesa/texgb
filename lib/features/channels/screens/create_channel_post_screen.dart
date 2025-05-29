import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

class CreateChannelPostScreen extends ConsumerStatefulWidget {
  const CreateChannelPostScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateChannelPostScreen> createState() => _CreateChannelPostScreenState();
}

class _CreateChannelPostScreenState extends ConsumerState<CreateChannelPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  
  // Media selection
  bool _isVideoMode = true;
  File? _videoFile;
  List<File> _imageFiles = [];
  VideoPlayerController? _videoPlayerController;
  bool _isVideoPlaying = false;
  
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _captionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoPlayer() async {
    if (_videoFile == null) return;
    
    _videoPlayerController = VideoPlayerController.file(_videoFile!);
    await _videoPlayerController!.initialize();
    _videoPlayerController!.setLooping(true);
    
    setState(() {});
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      final video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      
      if (video != null) {
        final videoFile = File(video.path);
        await _processAndSetVideo(videoFile);
      }
    } catch (e) {
      _showError('Failed to pick video: ${e.toString()}');
    }
  }

  Future<void> _captureVideoFromCamera() async {
    try {
      final video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
      
      if (video != null) {
        final videoFile = File(video.path);
        await _processAndSetVideo(videoFile);
      }
    } catch (e) {
      _showError('Failed to capture video: ${e.toString()}');
    }
  }

  Future<void> _processAndSetVideo(File videoFile) async {
    // Check video duration first
    final duration = await _getVideoDuration(videoFile);
    if (duration.inMinutes > 5) {
      _showError('Video exceeds 5 minute limit');
      return;
    }

    // Process video with FFmpeg using lossless HEVC
    final processedFile = await _processVideoWithFFmpeg(videoFile);
    
    setState(() {
      _videoFile = processedFile ?? videoFile;
      _isVideoMode = true;
      _imageFiles = [];
    });
    
    await _initializeVideoPlayer();
  }

  Future<Duration> _getVideoDuration(File file) async {
    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    final duration = controller.value.duration;
    await controller.dispose();
    return duration;
  }

  Future<File?> _processVideoWithFFmpeg(File inputFile) async {
    try {
      final tempDir = Directory.systemTemp;
      final outputPath = '${tempDir.path}/processed_hevc_${DateTime.now().millisecondsSinceEpoch}.mp4';
      
      // HEVC (H.265) Lossless encoding command with highest quality audio
      // First attempt: Copy original audio stream (preserves original quality)
      final command = '-y -i "${inputFile.path}" '
          '-c:v libx265 '                    // Use HEVC/H.265 codec
          '-preset ultrafast '               // Fastest encoding preset
          '-x265-params lossless=1 '         // Enable lossless compression
          '-crf 0 '                          // Constant Rate Factor 0 (lossless)
          '-c:a copy '                       // Copy audio stream without re-encoding (preserves original quality)
          '-movflags +faststart '            // Optimize for streaming
          '-tag:v hvc1 '                     // Set video tag for better compatibility
          '"$outputPath"';
      
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      
      if (ReturnCode.isSuccess(returnCode)) {
        return File(outputPath);
      } else {
        // Fallback 1: Try with lossless audio encoding if copy fails
        final fallbackCommand1 = '-y -i "${inputFile.path}" '
            '-c:v libx265 '
            '-preset fast '
            '-crf 0 '                        // Still lossless video
            '-c:a flac '                     // FLAC lossless audio codec
            '-compression_level 8 '          // Maximum FLAC compression
            '-movflags +faststart '
            '"$outputPath"';
            
        final fallbackSession1 = await FFmpegKit.execute(fallbackCommand1);
        final fallbackReturnCode1 = await fallbackSession1.getReturnCode();
        
        if (ReturnCode.isSuccess(fallbackReturnCode1)) {
          return File(outputPath);
        } else {
          // Fallback 2: High-quality AAC if FLAC is not supported
          final fallbackCommand2 = '-y -i "${inputFile.path}" '
              '-c:v libx265 '
              '-preset fast '
              '-crf 0 '                      // Still lossless video
              '-c:a aac '                    // AAC audio codec
              '-b:a 320k '                   // Maximum AAC bitrate (320kbps)
              '-ar 48000 '                   // 48kHz sample rate
              '-ac 2 '                       // Stereo channels
              '-movflags +faststart '
              '"$outputPath"';
              
          final fallbackSession2 = await FFmpegKit.execute(fallbackCommand2);
          final fallbackReturnCode2 = await fallbackSession2.getReturnCode();
          
          if (ReturnCode.isSuccess(fallbackReturnCode2)) {
            return File(outputPath);
          } else {
            _showError('HEVC video processing failed');
            return null;
          }
        }
      }
    } catch (e) {
      _showError('Video processing error: ${e.toString()}');
      return null;
    }
  }

  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage();
      
      if (images.isNotEmpty) {
        List<File> imageFiles = images.map((xFile) => File(xFile.path)).toList();
        
        if (imageFiles.length > 10) {
          imageFiles = imageFiles.sublist(0, 10);
          _showMessage('Maximum 10 images allowed. Only the first 10 images were selected.');
        }
        
        setState(() {
          _imageFiles = imageFiles;
          _isVideoMode = false;
          _clearVideo();
        });
      }
    } catch (e) {
      _showError('Failed to pick images: ${e.toString()}');
    }
  }

  void _clearVideo() {
    if (_videoPlayerController != null) {
      _videoPlayerController!.dispose();
      _videoPlayerController = null;
    }
    _videoFile = null;
  }

  void _togglePlayPause() {
    if (_videoPlayerController == null) return;
    
    setState(() {
      if (_isVideoPlaying) {
        _videoPlayerController!.pause();
      } else {
        _videoPlayerController!.play();
      }
      _isVideoPlaying = !_isVideoPlaying;
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final channelVideosNotifier = ref.read(channelVideosProvider.notifier);
      final userChannel = ref.read(channelsProvider).userChannel;
      
      if (userChannel == null) {
        _showError('You need to create a channel first');
        return;
      }
      
      if (_isVideoMode && _videoFile == null) {
        _showError('Please select a video');
        return;
      }
      
      if (!_isVideoMode && _imageFiles.isEmpty) {
        _showError('Please select at least one image');
        return;
      }
      
      List<String> tags = [];
      if (_tagsController.text.isNotEmpty) {
        tags = _tagsController.text.split(',').map((tag) => tag.trim()).toList();
      }
      
      if (_isVideoMode) {
        channelVideosNotifier.uploadVideo(
          channel: userChannel,
          videoFile: _videoFile!,
          caption: _captionController.text,
          tags: tags,
          onSuccess: (message) {
            _showSuccess(message);
            _navigateBack();
          },
          onError: (error) {
            _showError(error);
          },
        );
      } else {
        channelVideosNotifier.uploadImages(
          channel: userChannel,
          imageFiles: _imageFiles,
          caption: _captionController.text,
          tags: tags,
          onSuccess: (message) {
            _showSuccess(message);
            _navigateBack();
          },
          onError: (error) {
            _showError(error);
          },
        );
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _navigateBack() {
    Future.delayed(const Duration(milliseconds: 300), () {
      Navigator.of(context).pop(true);
    });
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
          if (_isVideoMode && _videoFile != null || !_isVideoMode && _imageFiles.isNotEmpty)
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Media type selection
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isVideoMode = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isVideoMode 
                              ? modernTheme.primaryColor 
                              : modernTheme.primaryColor!.withOpacity(0.2),
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Video',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isVideoMode 
                                ? Colors.white 
                                : modernTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isVideoMode = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isVideoMode 
                              ? modernTheme.primaryColor 
                              : modernTheme.primaryColor!.withOpacity(0.2),
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Images',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_isVideoMode 
                                ? Colors.white 
                                : modernTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Media preview or picker
              _isVideoMode
                  ? (_videoFile == null
                      ? _buildVideoPickerPlaceholder(modernTheme)
                      : _buildVideoPreview(modernTheme))
                  : _buildImagePickerArea(modernTheme),
                
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
              
              // Caption
              TextFormField(
                controller: _captionController,
                decoration: InputDecoration(
                  labelText: 'Caption *',
                  labelStyle: TextStyle(color: modernTheme.textSecondaryColor),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: modernTheme.textSecondaryColor!.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: modernTheme.primaryColor!),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a caption';
                  }
                  return null;
                },
                enabled: !channelVideosState.isUploading,
              ),
              
              const SizedBox(height: 16),
              
              // Tags (Optional)
              TextFormField(
                controller: _tagsController,
                decoration: InputDecoration(
                  labelText: 'Tags (Comma separated, Optional)',
                  labelStyle: TextStyle(color: modernTheme.textSecondaryColor),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: modernTheme.textSecondaryColor!.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: modernTheme.primaryColor!),
                  ),
                  hintText: 'e.g. sports, travel, music',
                ),
                enabled: !channelVideosState.isUploading,
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
      ),
    );
  }

  Widget _buildVideoPickerPlaceholder(ModernThemeExtension modernTheme) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam,
              color: modernTheme.primaryColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Add a video',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your content with your audience',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickVideoFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Select from Gallery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: modernTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _captureVideoFromCamera,
                  icon: const Icon(Icons.videocam),
                  label: const Text('Record Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: modernTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Max video length: 5 minutes | HEVC Lossless',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview(ModernThemeExtension modernTheme) {
    if (_videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      return Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            child: VideoPlayer(_videoPlayerController!),
          ),
          
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isVideoPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          
          Positioned(
            bottom: 16,
            right: 16,
            child: IconButton(
              onPressed: _pickVideoFromGallery,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return AspectRatio(
        aspectRatio: 9 / 16,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: CircularProgressIndicator(
              color: modernTheme.primaryColor,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildImagePickerArea(ModernThemeExtension modernTheme) {
    if (_imageFiles.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library,
              color: modernTheme.primaryColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Add images',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share multiple photos with your audience',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Select from Gallery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Up to 10 images',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_imageFiles.length} images selected',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Change'),
                style: TextButton.styleFrom(
                  foregroundColor: modernTheme.primaryColor,
                ),
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
            itemCount: _imageFiles.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _imageFiles[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _imageFiles.removeAt(index);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      );
    }
  }
}
import 'dart:io';
import 'dart:math' as math;
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

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
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
    
    try {
      print('DEBUG: Initializing video player for: ${_videoFile!.path}');
      
      _videoPlayerController?.dispose(); // Dispose previous controller
      _videoPlayerController = VideoPlayerController.file(_videoFile!);
      
      await _videoPlayerController!.initialize();
      _videoPlayerController!.setLooping(true);
      
      print('DEBUG: Video player initialized successfully');
      setState(() {});
    } catch (e) {
      print('DEBUG: Video player initialization failed: $e');
      _showError('Failed to initialize video player: $e');
    }
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      print('DEBUG: Starting video picker...');
      
      final video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      
      if (video != null) {
        print('DEBUG: Video selected: ${video.path}');
        final videoFile = File(video.path);
        
        // Check if file exists
        if (await videoFile.exists()) {
          print('DEBUG: Video file exists, processing...');
          await _processAndSetVideo(videoFile);
        } else {
          print('DEBUG: Video file does not exist');
          _showError('Selected video file not found');
        }
      } else {
        print('DEBUG: No video selected');
      }
    } catch (e) {
      print('DEBUG: Video picker error: $e');
      _showError('Failed to pick video: ${e.toString()}');
    }
  }

  Future<void> _captureVideoFromCamera() async {
    try {
      print('DEBUG: Starting camera capture...');
      
      final video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
      
      if (video != null) {
        print('DEBUG: Video captured: ${video.path}');
        final videoFile = File(video.path);
        
        // Check if file exists
        if (await videoFile.exists()) {
          print('DEBUG: Captured video file exists, processing...');
          await _processAndSetVideo(videoFile);
        } else {
          print('DEBUG: Captured video file does not exist');
          _showError('Captured video file not found');
        }
      } else {
        print('DEBUG: No video captured');
      }
    } catch (e) {
      print('DEBUG: Camera capture error: $e');
      _showError('Failed to capture video: ${e.toString()}');
    }
  }

  Future<void> _processAndSetVideo(File videoFile) async {
    print('DEBUG: Starting optimal quality-size processing');
    
    // Get video info for smart decisions
    final videoInfo = await _analyzeVideo(videoFile);
    print('DEBUG: Video analysis - ${videoInfo.toString()}');
    
    if (videoInfo.duration.inSeconds > 300) { // 5 minutes
      _showError('Video exceeds 5 minute limit');
      return;
    }
    
    // Always process for optimal quality-size ratio
    final optimizedVideo = await _optimizeVideoQualitySize(videoFile, videoInfo);
    
    setState(() {
      _videoFile = optimizedVideo ?? videoFile;
      _isVideoMode = true;
      _imageFiles = [];
    });
    
    await _initializeVideoPlayer();
    print('DEBUG: Optimal processing complete');
  }

  Future<Duration> _getVideoDuration(File file) async {
    try {
      print('DEBUG: Getting video duration for: ${file.path}');
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      final duration = controller.value.duration;
      await controller.dispose();
      print('DEBUG: Video duration obtained: ${duration.inSeconds} seconds');
      return duration;
    } catch (e) {
      print('DEBUG: Error getting video duration: $e');
      // Return a default duration if we can't get it
      return const Duration(seconds: 0);
    }
  }

  Future<VideoInfo> _analyzeVideo(File videoFile) async {
    try {
      // Get basic info from video player
      final controller = VideoPlayerController.file(videoFile);
      await controller.initialize();
      
      final duration = controller.value.duration;
      final size = controller.value.size;
      final fileSizeBytes = await videoFile.length();
      final fileSizeMB = fileSizeBytes / (1024 * 1024);
      
      // Calculate current bitrate
      int? currentBitrate;
      if (duration.inSeconds > 0) {
        currentBitrate = ((fileSizeBytes * 8) / duration.inSeconds / 1000).round();
      }
      
      await controller.dispose();
      
      return VideoInfo(
        duration: duration,
        resolution: size,
        fileSizeMB: fileSizeMB,
        currentBitrate: currentBitrate,
        frameRate: 30.0, // Default assumption
      );
    } catch (e) {
      print('DEBUG: Video analysis error: $e');
      // Return safe defaults
      final fileSizeBytes = await videoFile.length();
      return VideoInfo(
        duration: const Duration(seconds: 60),
        resolution: const Size(1920, 1080),
        fileSizeMB: fileSizeBytes / (1024 * 1024),
        frameRate: 30.0,
      );
    }
  }

  Future<File?> _optimizeVideoQualitySize(File inputFile, VideoInfo info) async {
    try {
      final tempDir = Directory.systemTemp;
      final outputPath = '${tempDir.path}/optimized_${DateTime.now().millisecondsSinceEpoch}.mp4';
      
      // Determine optimal settings based on content
      final settings = _calculateOptimalSettings(info);
      print('DEBUG: Using optimization settings: $settings');
      
      // Build FFmpeg command for optimal quality-size ratio
      String command = '-y -i "${inputFile.path}" ';
      
      // Video encoding - optimal quality/size balance
      command += '-c:v libx264 '                           // H.264 for best compatibility
          '-preset ${settings.preset} '             // Better compression than fast
          '-crf ${settings.crf} '                   // Constant Rate Factor for quality
          '-maxrate ${settings.maxBitrate}k '       // Peak bitrate limit
          '-bufsize ${settings.maxBitrate * 2}k ';  // Buffer size (2x maxrate)
      
      // Video filters for quality optimization
      if (settings.videoFilter.isNotEmpty) {
        command += '-vf "${settings.videoFilter}" ';
      }
      
      // Audio filters for professional loudness normalization
      if (settings.audioFilter.isNotEmpty) {
        command += '-af "${settings.audioFilter}" ';
      }
      
      // Audio encoding - premium quality for content creation
      command += '-c:a aac '                               // Best audio codec
          '-b:a ${settings.audioBitrate}k '         // High-quality audio bitrate
          '-ar 48000 '                             // Professional 48kHz sample rate
          '-ac 2 '                                 // Stereo channels
          '-profile:a aac_he_v2 '                  // HE-AAC v2 for efficiency at high bitrates
          
          // Optimization flags
          '-movflags +faststart '                  // Web streaming optimization
          '-profile:v high '                       // H.264 high profile
          '-level:v 4.1 '                         // Compatibility level
          '-pix_fmt yuv420p '                     // Color format compatibility
          
          // Output
          '-f mp4 "${outputPath}"';
      
      print('DEBUG: Executing optimal compression');
      print('DEBUG: Command: $command');
      
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      final logs = await session.getLogsAsString();
      
      if (ReturnCode.isSuccess(returnCode)) {
        final outputFile = File(outputPath);
        if (await outputFile.exists()) {
          final originalSizeMB = info.fileSizeMB;
          final newSizeMB = await outputFile.length() / (1024 * 1024);
          final compressionRatio = ((originalSizeMB - newSizeMB) / originalSizeMB * 100);
          
          print('DEBUG: Optimization successful!');
          print('DEBUG: Original: ${originalSizeMB.toStringAsFixed(1)}MB → New: ${newSizeMB.toStringAsFixed(1)}MB');
          print('DEBUG: Compression: ${compressionRatio.toStringAsFixed(1)}% smaller');
          
          // Only use compressed version if it's actually smaller and reasonable
          if (newSizeMB < originalSizeMB && compressionRatio > 10) {
            return outputFile;
          } else {
            print('DEBUG: Compression not beneficial, using original');
            return null;
          }
        }
      }
      
      print('DEBUG: Optimization failed - $logs');
      return null;
      
    } catch (e) {
      print('DEBUG: Optimization error: $e');
      return null;
    }
  }

  OptimizationSettings _calculateOptimalSettings(VideoInfo info) {
    int crf = 23; // Default excellent quality
    String preset = 'medium';
    int maxBitrate = 2500;
    int audioBitrate = 192; // Start with high-quality audio (192kbps)
    String videoFilter = '';
    String audioFilter = '';
    
    // Professional loudness normalization for content creation
    audioFilter = 'loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json';
    print('DEBUG: Applied professional loudness normalization');
    
    // Camera-specific optimizations
    bool isCameraVideo = _detectCameraVideo(info);
    if (isCameraVideo) {
      print('DEBUG: Camera video detected - applying camera optimizations');
      // Camera videos often need more aggressive compression
      crf = 24; // Slightly more compression for camera videos
      preset = 'slow'; // Better compression for raw camera footage
    }
    
    // Smart resolution decisions
    final targetResolution = _determineTargetResolution(info);
    print('DEBUG: Target resolution: ${targetResolution.width}x${targetResolution.height}');
    
    // Adjust based on target resolution (mobile-optimized)
    if (targetResolution != info.resolution) {
      // Need to downscale
      videoFilter = 'scale=${targetResolution.width}:${targetResolution.height}:force_original_aspect_ratio=decrease';
      
      if (isCameraVideo && targetResolution.height <= 720) {
        // Enhanced filters for mobile 720p from camera footage
        videoFilter += ',deshake,hqdn3d=2:1:2:1,unsharp=5:5:1.2:5:5:0.0'; // Stabilize + denoise + sharpen more for mobile
      }
      
      // Mobile-optimized bitrates with premium audio
      if (targetResolution.height >= 1080) {
        maxBitrate = 2500; // 1080p for mobile (rare case)
        crf = 23;
        audioBitrate = 256; // Premium audio for high-res video
      } else if (targetResolution.height >= 720) {
        maxBitrate = 1500; // 720p sweet spot for mobile
        crf = 21; // Higher quality since we're downscaling
        audioBitrate = 192; // High-quality audio (near lossless)
      } else {
        maxBitrate = 1000; // Lower resolutions
        crf = 20;
        audioBitrate = 160; // Still excellent audio for lower res
      }
    } else if (info.resolution.height <= 720) {
      // Already 720p or lower - perfect for mobile
      crf = 24; // Good compression for mobile
      maxBitrate = 1200;
      audioBitrate = 192; // Premium audio quality
    }
    
    // Adjust based on current bitrate (preserve audio quality)
    if (info.currentBitrate != null) {
      if (info.currentBitrate! > 5000) {
        // Very high bitrate - aggressive video compression but preserve audio
        crf = 25;
        maxBitrate = math.max(1000, maxBitrate - 500);
        // Keep high audio bitrate even with aggressive video compression
        audioBitrate = math.max(192, audioBitrate);
      } else if (info.currentBitrate! < 1000) {
        // Already low bitrate - gentle compression, enhance audio
        crf = math.max(18, crf - 2);
        maxBitrate = math.min(2000, maxBitrate + 300);
        audioBitrate = 256; // Boost audio for low-bitrate sources
      }
    }
    
    // Adjust based on duration (maintain audio quality for longer content)
    if (info.duration.inSeconds > 180) { // 3+ minutes
      // Longer videos need more video compression but preserve audio quality
      crf = math.min(28, crf + 2);
      maxBitrate = math.max(800, maxBitrate - 300);
      // Maintain high audio quality for longer content where audio matters more
      audioBitrate = math.max(192, audioBitrate);
    }
    
    // Adjust based on file size (balance compression while preserving audio)
    if (info.fileSizeMB > 100) {
      // Large files need aggressive video compression but keep premium audio
      crf = 26;
      preset = 'slow'; // Better compression for large files
      maxBitrate = 1200;
      audioBitrate = math.max(192, audioBitrate); // Maintain premium audio
    } else if (info.fileSizeMB < 20) {
      // Small files - prioritize quality including premium audio
      crf = math.max(18, crf - 2);
      maxBitrate = math.min(2000, maxBitrate + 500);
      audioBitrate = 256; // Premium audio for small, high-quality files
    }
    
    return OptimizationSettings(
      crf: crf,
      preset: preset,
      maxBitrate: maxBitrate,
      audioBitrate: audioBitrate,
      videoFilter: videoFilter,
      audioFilter: audioFilter,
    );
  }

  // Smart resolution targeting optimized for mobile-only app
  Size _determineTargetResolution(VideoInfo info) {
    final currentRes = info.resolution;
    
    // Mobile-optimized strategy: Default to 720p for best experience
    return _getMobileOptimizedResolution(info);
  }

  Size _getMobileOptimizedResolution(VideoInfo info) {
    final currentWidth = info.resolution.width.toInt();
    final currentHeight = info.resolution.height.toInt();
    
    print('DEBUG: Mobile-only app - optimizing for 720p target');
    
    // 4K+ videos: Always downscale to 720p (mobile doesn't need 4K)
    if (currentHeight >= 2160 || currentWidth >= 3840) {
      print('DEBUG: 4K+ video detected - downscaling to 720p for mobile');
      return const Size(720, 1280); // Portrait 720p
    }
    
    // 1080p videos: Default to 720p for mobile optimization
    if (currentHeight >= 1080 || currentWidth >= 1920) {
      
      // Only keep 1080p in very specific cases for mobile
      if (_shouldKeep1080pForMobile(info)) {
        print('DEBUG: Keeping 1080p for mobile (special case)');
        return Size(currentWidth.toDouble(), currentHeight.toDouble());
      }
      
      print('DEBUG: Downscaling 1080p to 720p for optimal mobile experience');
      return const Size(720, 1280); // Portrait 720p
    }
    
    // 720p and below: Perfect for mobile, keep original
    print('DEBUG: 720p or lower - optimal for mobile');
    return Size(currentWidth.toDouble(), currentHeight.toDouble());
  }

  // Very selective criteria for keeping 1080p on mobile
  bool _shouldKeep1080pForMobile(VideoInfo info) {
    // Only keep 1080p if:
    // 1. File is already very small (well optimized)
    // 2. Short duration (quick to upload)
    // 3. Low bitrate (already compressed)
    
    final isSmallFile = info.fileSizeMB < 15; // Very small file
    final isShortVideo = info.duration.inSeconds < 30; // Very short
    final isLowBitrate = (info.currentBitrate ?? 99999) < 3000; // Already compressed
    
    final shouldKeep = isSmallFile && isShortVideo && isLowBitrate;
    
    if (shouldKeep) {
      print('DEBUG: 1080p mobile exception - small (${info.fileSizeMB.toStringAsFixed(1)}MB), short (${info.duration.inSeconds}s), low bitrate');
    }
    
    return shouldKeep;
  }

  // Detect if video is likely from camera (vs downloaded/edited)
  bool _detectCameraVideo(VideoInfo info) {
    // Camera videos typically have:
    // 1. Very high bitrates
    // 2. Standard camera resolutions
    // 3. Standard frame rates
    
    final isHighBitrate = (info.currentBitrate ?? 0) > 10000; // > 10 Mbps
    final isCameraResolution = _isCameraResolution(info.resolution);
    final isRecentlyCreated = true; // Could check file creation time
    
    return isHighBitrate && isCameraResolution;
  }

  bool _isCameraResolution(Size resolution) {
    // Common camera resolutions
    final commonCameraResolutions = [
      Size(3840, 2160), // 4K
      Size(2720, 1530), // 2.7K
      Size(1920, 1080), // 1080p
      Size(1280, 720),  // 720p
      // Portrait versions
      Size(2160, 3840), // 4K portrait
      Size(1530, 2720), // 2.7K portrait
      Size(1080, 1920), // 1080p portrait
      Size(720, 1280),  // 720p portrait
    ];
    
    return commonCameraResolutions.any((cameraRes) =>
      (resolution.width == cameraRes.width && resolution.height == cameraRes.height));
  }

  Future<void> _pickImages() async {
    try {
      print('DEBUG: Starting image picker...');
      
      final images = await _picker.pickMultiImage();
      
      if (images.isNotEmpty) {
        print('DEBUG: ${images.length} images selected');
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
        
        print('DEBUG: Images processed successfully');
      } else {
        print('DEBUG: No images selected');
      }
    } catch (e) {
      print('DEBUG: Image picker error: $e');
      _showError('Failed to pick images: ${e.toString()}');
    }
  }

  void _clearVideo() {
    print('DEBUG: Clearing video');
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
    print('DEBUG: Form submission started');
    
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
      
      print('DEBUG: Submitting ${_isVideoMode ? 'video' : 'images'}');
      
      if (_isVideoMode) {
        channelVideosNotifier.uploadVideo(
          channel: userChannel,
          videoFile: _videoFile!,
          caption: _captionController.text,
          tags: tags,
          onSuccess: (message) {
            print('DEBUG: Video upload success: $message');
            _showSuccess(message);
            _navigateBack();
          },
          onError: (error) {
            print('DEBUG: Video upload error: $error');
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
            print('DEBUG: Images upload success: $message');
            _showSuccess(message);
            _navigateBack();
          },
          onError: (error) {
            print('DEBUG: Images upload error: $error');
            _showError(error);
          },
        );
      }
    } else {
      print('DEBUG: Form validation failed');
    }
  }

  void _showError(String message) {
    print('DEBUG: Showing error: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showMessage(String message) {
    print('DEBUG: Showing message: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSuccess(String message) {
    print('DEBUG: Showing success: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _navigateBack() {
    print('DEBUG: Navigating back');
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
            const SizedBox(height: 32),
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
            const SizedBox(height: 16),
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

// Data classes for video processing
class VideoInfo {
  final Duration duration;
  final Size resolution;
  final double fileSizeMB;
  final int? currentBitrate;
  final double frameRate;
  
  VideoInfo({
    required this.duration,
    required this.resolution,
    required this.fileSizeMB,
    this.currentBitrate,
    required this.frameRate,
  });
  
  @override
  String toString() {
    return 'Duration: ${duration.inSeconds}s, Resolution: ${resolution.width}x${resolution.height}, '
           'Size: ${fileSizeMB.toStringAsFixed(1)}MB, Bitrate: ${currentBitrate ?? 'unknown'}kbps, '
           'FPS: ${frameRate.toStringAsFixed(1)}';
  }
}

class OptimizationSettings {
  final int crf;
  final String preset;
  final int maxBitrate;
  final int audioBitrate;
  final String videoFilter;
  final String audioFilter;
  
  OptimizationSettings({
    required this.crf,
    required this.preset,
    required this.maxBitrate,
    required this.audioBitrate,
    required this.videoFilter,
    required this.audioFilter,
  });
  
  @override
  String toString() {
    return 'CRF: $crf, Preset: $preset, MaxBitrate: ${maxBitrate}k, Audio: ${audioBitrate}k, AudioFilter: ${audioFilter.isNotEmpty ? "loudnorm" : "none"}';
  }
}
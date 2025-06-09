import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/channels/widgets/video_trim_screen.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ffmpeg_kit_flutter_new_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_gpl/return_code.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as path;

// Data classes for video processing - shared with VideoTrimScreen
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

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  
  // Cache manager for efficient file handling
  static final CacheManager _cacheManager = CacheManager(
    Config(
      'video_cache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 20,
    ),
  );
  
  // Media selection
  bool _isVideoMode = true;
  File? _videoFile;
  VideoInfo? _videoInfo; // Store video info for later optimization
  List<File> _imageFiles = [];
  VideoPlayerController? _videoPlayerController;
  bool _isVideoPlaying = false;
  
  // Optimization state
  bool _isOptimizing = false;
  double _optimizationProgress = 0.0;
  String _optimizationStatus = '';
  
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _captionController.dispose();
    _tagsController.dispose();
    // Clean up cache when disposing (optional)
    _cacheManager.emptyCache();
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
    print('DEBUG: Processing video for immediate display');
    
    // Get video info for later optimization and trim decisions
    final videoInfo = await _analyzeVideo(videoFile);
    print('DEBUG: Video analysis - ${videoInfo.toString()}');
    
    if (videoInfo.duration.inSeconds > 300) { // 5 minutes
      print('DEBUG: Video exceeds 5 minutes, offering trim option');
      await _showVideoTrimDialog(videoFile, videoInfo, isRequired: true);
      return;
    } else {
      print('DEBUG: Video under 5 minutes, offering optional trim');
      await _showVideoTrimDialog(videoFile, videoInfo, isRequired: false);
      return;
    }
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

  // Fixed CRF 23 - excellent quality for all content
  int _getFixedCRF() {
    return 23; // High quality, works great for all resolutions
  }

  // Get optimal preset based on video characteristics
  String _getOptimalPreset(VideoInfo info) {
    final totalPixels = info.resolution.width * info.resolution.height;
    final duration = info.duration.inSeconds;
    
    // For high resolution or long videos, use slower preset for better compression
    if (totalPixels >= 1920 * 1080 || duration > 180) {
      return 'slow';      // Better compression, slower encoding
    } else if (totalPixels >= 1280 * 720) {
      return 'medium';    // Balanced
    } else {
      return 'fast';      // Quick encoding for lower resolution
    }
  }

  // Get optimal profile based on resolution
  String _getOptimalProfile(VideoInfo info) {
    final totalPixels = info.resolution.width * info.resolution.height;
    
    if (totalPixels >= 1920 * 1080) {
      return 'high';      // High profile for better compression at high res
    } else {
      return 'main';      // Main profile for compatibility
    }
  }

  // Build video filters for enhancement
  String _buildVideoFilters(VideoInfo info) {
    List<String> filters = [];
    
    // Only add enhancement filters if the source quality is decent
    if (info.currentBitrate != null && info.currentBitrate! > 1000) {
      // Subtle sharpening for better perceived quality
      filters.add('unsharp=luma_msize_x=5:luma_msize_y=5:luma_amount=0.25:chroma_msize_x=3:chroma_msize_y=3:chroma_amount=0.25');
      
      // Slight saturation boost for more vivid colors
      filters.add('eq=saturation=1.1');
      
      // Noise reduction for cleaner image (very light)
      filters.add('hqdn3d=luma_spatial=1:chroma_spatial=0.5:luma_tmp=2:chroma_tmp=1');
    }
    
    return filters.join(',');
  }

  // Enhanced Premium Loud Audio Processing with Adaptive Video Quality
  Future<File?> _optimizeVideoQualitySize(File inputFile, VideoInfo info) async {
    try {
      final tempDir = Directory.systemTemp;
      final outputPath = '${tempDir.path}/optimized_${DateTime.now().millisecondsSinceEpoch}.mp4';
      
      setState(() {
        _isOptimizing = true;
        _optimizationStatus = 'Optimizing video...';
        _optimizationProgress = 0.0;
      });

      setState(() {
        _optimizationStatus = 'Analyzing video quality...';
        _optimizationProgress = 0.3;
      });

      // Use fixed CRF 23 and determine other optimal settings
      int fixedCRF = _getFixedCRF(); // Always 23 - excellent for all content
      String preset = _getOptimalPreset(info);
      String profile = _getOptimalProfile(info);
      String videoFilters = _buildVideoFilters(info);
      
      print('DEBUG: Using fixed CRF: $fixedCRF, Preset: $preset, Profile: $profile');

      // Enhanced command with fixed CRF 23 and preserved audio processing
      final enhancedCommand = '-y -i "${inputFile.path}" '
          // Video encoding with fixed CRF 23 - excellent quality for all content
          '-c:v libx264 '
          '-crf $fixedCRF '                      // Fixed CRF 23 - high quality, works great
          '-preset slow '                     // Adaptive preset for quality/speed balance
          '-profile:v $profile '                 // Optimal profile for device compatibility
          '-level 4.1 '                         // Ensures broad device compatibility
          '-pix_fmt yuv420p '                    // Ensures compatibility with all players
          '-g 30 '                               // Keyframe interval (2x framerate assumed)
          '-keyint_min 15 '                      // Minimum keyframe interval
          '-sc_threshold 40 '                    // Scene change detection threshold
          '-refs 3 '                             // Reference frames for better compression
          '-bf 3 '                               // B-frames for better compression
          '-b_strategy 2 '                       // Optimal B-frame strategy
          '-coder 1 '                            // CABAC entropy encoding
          '-me_method hex '                      // Motion estimation method
          '-subq 7 '                             // Subpixel motion estimation quality
          '-cmp chroma '                         // Comparison function
          '-partitions parti8x8+parti4x4+partp8x8+partb8x8 ' // Partition types
          '-me_range 16 '                        // Motion estimation range
          '-trellis 1 '                          // Trellis quantization
          '-8x8dct 1 '                           // 8x8 DCT transform
          '-fast-pskip 1 '                       // Fast P-skip
          '-mixed-refs 1 '                       // Mixed references
          '-wpredp 2 '                           // Weighted prediction for P-frames
          '-aq-mode 1 '                          // Adaptive quantization mode
          '-aq-strength 0.8 '                    // Adaptive quantization strength
          // Video filters for enhancement (if any)
          '${videoFilters.isNotEmpty ? '-vf "$videoFilters" ' : ''}'
          // Premium loud audio - preserved exactly as original
          '-c:a aac '                    // AAC audio
          '-b:a 128k '                   // High quality audio
          '-ar 48000 '                   // 48kHz sample rate
          '-ac 2 '                       // Stereo
          '-af "volume=2.2,equalizer=f=60:width_type=h:width=2:g=3,equalizer=f=150:width_type=h:width=2:g=2,equalizer=f=8000:width_type=h:width=2:g=1,compand=attacks=0.2:decays=0.4:points=-80/-80|-50/-20|-30/-15|-20/-10|-5/-5|0/-2|20/-2,highpass=f=40,lowpass=f=15000,loudnorm=I=-10:TP=-1.5:LRA=7:linear=true" '
          '-movflags +faststart '        // Optimize for streaming
          '-f mp4 "$outputPath"';

      print('DEBUG: Enhanced FFmpeg command: ffmpeg $enhancedCommand');

      setState(() {
        _optimizationStatus = 'Encoding with enhanced quality...';
        _optimizationProgress = 0.6;
      });

      // Get video duration for real progress calculation
      final videoDurationMs = info.duration.inMilliseconds;
      print('DEBUG: Video duration: ${videoDurationMs}ms for progress calculation');
      
      // Create a completer to properly wait for async completion
      final Completer<void> processingCompleter = Completer<void>();
      
      // Execute with real progress tracking using async
      FFmpegKit.executeAsync(
        enhancedCommand,
        (session) async {
          // Completion callback - this is when processing actually finishes
          print('DEBUG: Enhanced FFmpeg execution completed');
          final returnCode = await session.getReturnCode();
          
          if (mounted) {
            setState(() {
              _isOptimizing = false;
              _optimizationProgress = 1.0;
              _optimizationStatus = ReturnCode.isSuccess(returnCode) 
                  ? 'Video optimized with enhanced quality!'
                  : 'Optimization failed';
            });
          }
          // Complete the future when processing is actually done
          if (!processingCompleter.isCompleted) {
            processingCompleter.complete();
          }
        },
        (log) {
          // Log callback (optional for debugging)
          // print('DEBUG: FFmpeg log: ${log.getMessage()}');
        },
        (statistics) {
          // Real progress statistics callback
          if (mounted && _isOptimizing && statistics.getTime() > 0 && videoDurationMs > 0) {
            final baseProgress = 0.6; // Start from 60%
            final encodingProgress = (statistics.getTime() / videoDurationMs).clamp(0.0, 1.0);
            final totalProgress = baseProgress + (encodingProgress * 0.4); // Remaining 40%
            
            setState(() {
              _optimizationProgress = totalProgress.clamp(0.0, 1.0);
            });
            print('DEBUG: Enhanced encoding progress: ${(totalProgress * 100).toStringAsFixed(1)}%');
          }
        },
      );
      
      // Wait for the actual processing to complete
      await processingCompleter.future;
      
      // Now check the results after processing is truly complete
      final outputFile = File(outputPath);
      if (await outputFile.exists()) {
        final originalSizeMB = info.fileSizeMB;
        final newSizeMB = await outputFile.length() / (1024 * 1024);
        final compressionRatio = ((originalSizeMB - newSizeMB) / originalSizeMB * 100);
        
        print('DEBUG: Enhanced video optimization successful!');
        print('DEBUG: Original: ${originalSizeMB.toStringAsFixed(1)}MB → New: ${newSizeMB.toStringAsFixed(1)}MB');
        print('DEBUG: Compression: ${compressionRatio.toStringAsFixed(1)}% smaller');
        //print('DEBUG: Used CRF: $optimalCRF for optimal quality');
        
        // Validate quality hasn't degraded too much
        if (compressionRatio > 95) {
          print('DEBUG: Warning: Compression ratio very high, quality may be affected');
        }
        
        // Hide processing status after a delay
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _optimizationStatus = '';
              _optimizationProgress = 0.0;
            });
          }
        });
        
        return outputFile;
      }
      
      print('DEBUG: Enhanced video optimization failed - output file not found');
      return null;
      
    } catch (e) {
      print('DEBUG: Enhanced video optimization error: $e');
      if (mounted) {
        setState(() {
          _isOptimizing = false;
          _optimizationProgress = 0.0;
          _optimizationStatus = 'Optimization failed';
        });
        
        // Hide error status after a delay
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _optimizationStatus = '';
            });
          }
        });
      }
      return null;
    }
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
    _videoInfo = null;
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

  Future<void> _showVideoTrimDialog(File videoFile, VideoInfo videoInfo, {required bool isRequired}) async {
    final durationMinutes = (videoInfo.duration.inSeconds / 60).round();
    final durationSeconds = videoInfo.duration.inSeconds;
    
    String title;
    String content;
    List<Widget> actions = [];
    
    if (isRequired) {
      // Video is over 5 minutes - trimming is required
      title = 'Video Too Long';
      content = 'Your video is ${durationMinutes} minutes long. Videos must be 5 minutes or less.\n\n'
          'Choose how you want to trim it:';
      
      actions = [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('First 5 Minutes'),
          onPressed: () async {
            Navigator.of(context).pop();
            await _trimVideoTo5Minutes(videoFile, videoInfo);
          },
        ),
        TextButton(
          child: const Text('Manual Trim'),
          onPressed: () {
            Navigator.of(context).pop();
            _showManualTrimScreen(videoFile, videoInfo);
          },
        ),
      ];
    } else {
      // Video is under 5 minutes - trimming is optional
      title = 'Trim Video?';
      content = 'Your video is ${durationSeconds} seconds long.\n\n'
          'Would you like to trim it to a shorter clip, or use the full video?';
      
      actions = [
        TextButton(
          child: const Text('Use Full Video'),
          onPressed: () async {
            Navigator.of(context).pop();
            await _setVideoDirectly(videoFile, videoInfo);
          },
        ),
        TextButton(
          child: const Text('Trim Video'),
          onPressed: () {
            Navigator.of(context).pop();
            _showManualTrimScreen(videoFile, videoInfo);
          },
        ),
      ];
    }
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: actions,
        );
      },
    );
  }

  // Set video directly without optimization for immediate display
  Future<void> _setVideoDirectly(File videoFile, VideoInfo videoInfo) async {
    print('DEBUG: Setting video directly for immediate display');
    
    setState(() {
      _videoFile = videoFile;
      _videoInfo = videoInfo; // Store for later optimization
      _isVideoMode = true;
      _imageFiles = [];
    });
    
    await _initializeVideoPlayer();
    print('DEBUG: Video set successfully - ready for user interaction');
  }

  void _showManualTrimScreen(File videoFile, VideoInfo videoInfo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoTrimScreen(
          videoFile: videoFile,
          videoInfo: videoInfo,
          onTrimComplete: (File trimmedFile) async {
            Navigator.of(context).pop(); // Close trim screen
            await _setTrimmedVideoDirectly(trimmedFile);
          },
        ),
      ),
    );
  }

  // Set trimmed video directly without re-processing
  Future<void> _setTrimmedVideoDirectly(File trimmedFile) async {
    try {
      print('DEBUG: Setting trimmed video directly');
      
      // Cache the trimmed file for efficient access
      final cachedFile = await _cacheVideoFile(trimmedFile);
      
      // Analyze the trimmed video for later optimization
      final trimmedVideoInfo = await _analyzeVideo(cachedFile);
      
      setState(() {
        _videoFile = cachedFile;
        _videoInfo = trimmedVideoInfo; // Store for later optimization
        _isVideoMode = true;
        _imageFiles = [];
      });
      
      await _initializeVideoPlayer();
      print('DEBUG: Trimmed video set successfully');
      
      // Show success message
      _showSuccess('Video trimmed successfully!');
    } catch (e) {
      print('DEBUG: Error setting trimmed video: $e');
      _showError('Failed to set trimmed video: ${e.toString()}');
    }
  }

  // Cache video file using Flutter Cache Manager
  Future<File> _cacheVideoFile(File videoFile) async {
    try {
      print('DEBUG: Caching video file');
      
      // Generate a unique key for the video
      final fileKey = 'video_${DateTime.now().millisecondsSinceEpoch}_${path.basename(videoFile.path)}';
      
      // Read the video file bytes
      final videoBytes = await videoFile.readAsBytes();
      
      // Store in cache
      final cachedFile = await _cacheManager.putFile(
        fileKey,
        videoBytes,
        fileExtension: path.extension(videoFile.path),
      );
      
      print('DEBUG: Video cached successfully: ${cachedFile.path}');
      return cachedFile;
    } catch (e) {
      print('DEBUG: Caching failed, using original file: $e');
      return videoFile; // Fallback to original file
    }
  }

  // Enhanced trim to 5 minutes with caching
  Future<void> _trimVideoTo5Minutes(File videoFile, VideoInfo videoInfo) async {
    try {
      print('DEBUG: Starting video trim to 5 minutes');
      
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trimming video to 5 minutes...'),
            duration: Duration(seconds: 30),
          ),
        );
      }
      
      // Create unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = path.extension(videoFile.path);
      final trimmedFileName = 'trimmed_5min_${timestamp}${fileExtension}';
      
      // Use cache directory for trimmed file
      final tempDir = Directory.systemTemp;
      final trimmedPath = path.join(tempDir.path, trimmedFileName);
      
      // FFmpeg command to trim video to first 5 minutes (300 seconds)
      final command = '-y -i "${videoFile.path}" '
          '-t 300 '                               // Trim to 300 seconds (5 minutes)
          '-c:v libx264 '                         // Re-encode video for consistency
          '-c:a aac '                             // Re-encode audio for consistency
          '-avoid_negative_ts make_zero '         // Ensure timestamps start at 0
          '-movflags +faststart '                 // Web streaming optimization
          '"${trimmedPath}"';
      
      print('DEBUG: Trimming command: $command');
      
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      final logs = await session.getLogsAsString();
      
      if (ReturnCode.isSuccess(returnCode)) {
        final trimmedFile = File(trimmedPath);
        if (await trimmedFile.exists()) {
          print('DEBUG: Video trimmed successfully');
          
          // Hide loading indicator
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }
          
          // Set trimmed video directly without re-processing
          await _setTrimmedVideoDirectly(trimmedFile);
        } else {
          print('DEBUG: Trimmed file not found');
          _showError('Failed to trim video - file not created');
        }
      } else {
        print('DEBUG: Video trim failed - $logs');
        _showError('Failed to trim video. Please try a different video.');
      }
    } catch (e) {
      print('DEBUG: Video trim error: $e');
      _showError('Failed to trim video: ${e.toString()}');
    }
  }

  // Modified submit form to handle optimization during post
  void _submitForm() async {
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
        // Optimize video before upload if we have video info
        File videoToUpload = _videoFile!;
        
        if (_videoInfo != null) {
          print('DEBUG: Optimizing video before upload...');
          final optimizedVideo = await _optimizeVideoQualitySize(_videoFile!, _videoInfo!);
          
          if (optimizedVideo != null) {
            videoToUpload = optimizedVideo;
            print('DEBUG: Using optimized video for upload');
          } else {
            print('DEBUG: Using original video for upload');
          }
        }
        
        channelVideosNotifier.uploadVideo(
          channel: userChannel,
          videoFile: videoToUpload,
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
              onPressed: (channelVideosState.isUploading || _isOptimizing) ? null : _submitForm,
              child: Text(
                _isOptimizing ? 'Optimizing...' : (channelVideosState.isUploading ? 'Uploading...' : 'Post'),
                style: TextStyle(
                  color: (channelVideosState.isUploading || _isOptimizing) 
                      ? modernTheme.textSecondaryColor 
                      : modernTheme.primaryColor,
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
              
              // Video length tip
              if (_isVideoMode)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: modernTheme.primaryColor!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: modernTheme.primaryColor!.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: modernTheme.primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Max 5 minutes • Videos under 1 minute perform better',
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Media preview or picker
              _isVideoMode
                  ? (_videoFile == null
                      ? _buildVideoPickerPlaceholder(modernTheme)
                      : _buildVideoPreview(modernTheme))
                  : _buildImagePickerArea(modernTheme),
                
              const SizedBox(height: 24),
              
              // Video optimization progress
              if (_isOptimizing)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: modernTheme.primaryColor!.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: modernTheme.primaryColor!.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.settings,
                                color: modernTheme.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _optimizationStatus.isEmpty 
                                      ? 'Optimizing video...'
                                      : _optimizationStatus,
                                  style: TextStyle(
                                    color: modernTheme.textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: _optimizationProgress,
                            backgroundColor: modernTheme.borderColor,
                            valueColor: AlwaysStoppedAnimation<Color>(modernTheme.primaryColor!),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(_optimizationProgress * 100).toStringAsFixed(0)}% complete',
                            style: TextStyle(
                              color: modernTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              
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
                enabled: !channelVideosState.isUploading && !_isOptimizing,
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
                enabled: !channelVideosState.isUploading && !_isOptimizing,
              ),
              
              const SizedBox(height: 24),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (channelVideosState.isUploading || _isOptimizing) ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: modernTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: modernTheme.primaryColor!.withOpacity(0.5),
                  ),
                  child: _isOptimizing
                      ? const Text('Optimizing...')
                      : (channelVideosState.isUploading
                          ? const Text('Uploading...')
                          : const Text('Post Content')),
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
              onPressed: (!_isOptimizing && !ref.watch(channelVideosProvider).isUploading) ? _pickVideoFromGallery : null,
              icon: const Icon(Icons.photo_library),
              label: const Text('Select from Gallery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                disabledBackgroundColor: modernTheme.primaryColor!.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: (!_isOptimizing && !ref.watch(channelVideosProvider).isUploading) ? _captureVideoFromCamera : null,
              icon: const Icon(Icons.videocam),
              label: const Text('Record Video'),
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                disabledBackgroundColor: modernTheme.primaryColor!.withOpacity(0.5),
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
              onPressed: (!_isOptimizing && !ref.watch(channelVideosProvider).isUploading) ? _pickVideoFromGallery : null,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit,
                  color: (_isOptimizing || ref.watch(channelVideosProvider).isUploading) ? Colors.grey : Colors.white,
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
              onPressed: (!_isOptimizing && !ref.watch(channelVideosProvider).isUploading) ? _pickImages : null,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Select from Gallery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                disabledBackgroundColor: modernTheme.primaryColor!.withOpacity(0.5),
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
                onPressed: (!_isOptimizing && !ref.watch(channelVideosProvider).isUploading) ? _pickImages : null,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Change'),
                style: TextButton.styleFrom(
                  foregroundColor: (_isOptimizing || ref.watch(channelVideosProvider).isUploading) 
                      ? modernTheme.textSecondaryColor 
                      : modernTheme.primaryColor,
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
                      onTap: (!_isOptimizing && !ref.watch(channelVideosProvider).isUploading) ? () {
                        setState(() {
                          _imageFiles.removeAt(index);
                        });
                      } : null,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: (_isOptimizing || ref.watch(channelVideosProvider).isUploading) ? Colors.grey : Colors.white,
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
// lib/features/videos/screens/create_post_screen.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:textgb/features/authentication/widgets/login_required_widget.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/videos/services/video_thumbnail_service.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as path;

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

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

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
  
  // Video selection
  File? _videoFile;
  VideoInfo? _videoInfo;
  VideoPlayerController? _videoPlayerController;
  bool _isVideoPlaying = false;
  
  // Processing state
  bool _isProcessing = false;
  double _processingProgress = 0.0;
  
  // Upload simulation state
  bool _isSimulatingUpload = false;
  double _simulatedUploadProgress = 0.0;
  Timer? _uploadSimulationTimer;
  
  // Wakelock state tracking
  bool _wakelockActive = false;
  
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _captionController.dispose();
    _tagsController.dispose();
    _priceController.dispose();
    _cacheManager.emptyCache();
    _uploadSimulationTimer?.cancel();
    _disableWakelock();
    super.dispose();
  }

  // Wakelock management methods
  Future<void> _enableWakelock() async {
    if (!_wakelockActive) {
      try {
        await WakelockPlus.enable();
        _wakelockActive = true;
      } catch (e) {
        // Silently handle wakelock errors
      }
    }
  }

  Future<void> _disableWakelock() async {
    if (_wakelockActive) {
      try {
        await WakelockPlus.disable();
        _wakelockActive = false;
      } catch (e) {
        // Silently handle wakelock errors
      }
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (_videoFile == null) return;
    
    try {
      _videoPlayerController?.dispose();
      _videoPlayerController = VideoPlayerController.file(_videoFile!);
      
      await _videoPlayerController!.initialize();
      _videoPlayerController!.setLooping(true);
      
      setState(() {});
    } catch (e) {
      _showError('Failed to initialize video player');
    }
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      await _enableWakelock();
      
      final video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      
      if (video != null) {
        final videoFile = File(video.path);
        
        if (await videoFile.exists()) {
          await _processAndSetVideo(videoFile);
        } else {
          _showError('Selected video file not found');
          await _disableWakelock();
        }
      } else {
        await _disableWakelock();
      }
    } catch (e) {
      _showError('Failed to pick video');
      await _disableWakelock();
    }
  }

  void _showGoLiveMessage() {
    _showMessage('Unavailable');
  }

  Future<void> _processAndSetVideo(File videoFile) async {
    await _enableWakelock();
    
    final videoInfo = await _analyzeVideo(videoFile);
    
    // Check if video is longer than 5 minutes
    if (videoInfo.duration.inSeconds > 300) {
      _showError('Video must be under 5 minutes');
      await _disableWakelock();
      return;
    }
    
    // Set video directly without trim dialog
    await _setVideoDirectly(videoFile, videoInfo);
  }

  Future<Duration> _getVideoDuration(File file) async {
    try {
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      final duration = controller.value.duration;
      await controller.dispose();
      return duration;
    } catch (e) {
      return const Duration(seconds: 0);
    }
  }

  Future<VideoInfo> _analyzeVideo(File videoFile) async {
    try {
      final controller = VideoPlayerController.file(videoFile);
      await controller.initialize();
      
      final duration = controller.value.duration;
      final size = controller.value.size;
      final fileSizeBytes = await videoFile.length();
      final fileSizeMB = fileSizeBytes / (1024 * 1024);
      
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
        frameRate: 30.0,
      );
    } catch (e) {
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
    return 23;
  }

  // Get optimal preset based on video characteristics
  String _getOptimalPreset(VideoInfo info) {
    final totalPixels = info.resolution.width * info.resolution.height;
    final duration = info.duration.inSeconds;
    
    if (totalPixels >= 1920 * 1080 || duration > 180) {
      return 'slow';
    } else if (totalPixels >= 1280 * 720) {
      return 'medium';
    } else {
      return 'fast';
    }
  }

  // Get optimal profile based on resolution
  String _getOptimalProfile(VideoInfo info) {
    final totalPixels = info.resolution.width * info.resolution.height;
    
    if (totalPixels >= 1920 * 1080) {
      return 'high';
    } else {
      return 'main';
    }
  }

  // Build video filters for enhancement
  String _buildVideoFilters(VideoInfo info) {
    List<String> filters = [];
    
    if (info.currentBitrate != null && info.currentBitrate! > 1000) {
      // Subtle sharpening for better perceived quality
      filters.add('unsharp=luma_msize_x=5:luma_msize_y=5:luma_amount=0.25:chroma_msize_x=3:chroma_msize_y=3:chroma_amount=0.25');
      
      // Slight saturation boost for more vivid colors
      filters.add('eq=saturation=1.1');
      
      // Noise reduction for cleaner image
      filters.add('hqdn3d=luma_spatial=1:chroma_spatial=0.5:luma_tmp=2:chroma_tmp=1');
    }
    
    return filters.join(',');
  }

  // Pure audio normalization/boosting without frequency manipulation
  String _buildEnhancedAudioFilters() {
    return 'loudnorm=I=-6:TP=-0.5:LRA=11:linear=true';
  }

  // Modified video processing - enhanced audio for all videos
  Future<File?> _optimizeVideoQualitySize(File inputFile, VideoInfo info) async {
    try {
      final tempDir = Directory.systemTemp;
      final outputPath = '${tempDir.path}/optimized_${DateTime.now().millisecondsSinceEpoch}.mp4';
      
      await _enableWakelock();
      
      setState(() {
        _isProcessing = true;
        _processingProgress = 0.0;
      });

      String command;
      
      // Check if video is under 20MB - only process audio
      if (info.fileSizeMB < 50.0) {
        // Audio-only processing for videos under 50MB with enhanced audio chain
        command = '-y -i "${inputFile.path}" ';
        command += '-c:v copy '; // Copy video stream without re-encoding
        command += '-af "${_buildEnhancedAudioFilters()}" ';
        command += '-movflags +faststart ';
        command += '-f mp4 "$outputPath"';
      } else {
        // Full video and audio processing for larger files
        final crf = _getFixedCRF();
        final preset = _getOptimalPreset(info);
        final profile = _getOptimalProfile(info);
        final videoFilters = _buildVideoFilters(info);

        command = '-y -i "${inputFile.path}" ';
        
        // Video encoding with enhancement
        command += '-c:v libx264 ';
        command += '-crf $crf ';
        command += '-preset $preset ';
        command += '-profile:v $profile ';
        command += '-level 4.1 ';
        command += '-pix_fmt yuv420p ';
        
        // Add video filters if available
        if (videoFilters.isNotEmpty) {
          command += '-vf "$videoFilters" ';
        }
        
        // Enhanced audio processing with fuller sound
        command += '-af "${_buildEnhancedAudioFilters()}" ';
        
        // Output optimization
        command += '-movflags +faststart ';
        command += '-f mp4 "$outputPath"';
      }

      final videoDurationMs = info.duration.inMilliseconds;
      final Completer<void> processingCompleter = Completer<void>();
      
      FFmpegKit.executeAsync(
        command,
        (session) async {
          final returnCode = await session.getReturnCode();
          
          if (mounted) {
            setState(() {
              _isProcessing = false;
              _processingProgress = ReturnCode.isSuccess(returnCode) ? 1.0 : 0.0;
            });
          }
          
          final authProvider = ref.read(authenticationProvider.notifier);
          if (!authProvider.isLoading) {
            await _disableWakelock();
          }
          
          if (!processingCompleter.isCompleted) {
            processingCompleter.complete();
          }
        },
        (log) {
          // Silent processing - no debug logs
        },
        (statistics) {
          if (mounted && _isProcessing && statistics.getTime() > 0 && videoDurationMs > 0) {
            final encodingProgress = (statistics.getTime() / videoDurationMs).clamp(0.0, 1.0);
            
            setState(() {
              _processingProgress = encodingProgress.clamp(0.0, 1.0);
            });
          }
        },
      );
      
      await processingCompleter.future;
      
      final outputFile = File(outputPath);
      if (await outputFile.exists()) {
        return outputFile;
      }
      
      await _disableWakelock();
      return null;
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingProgress = 0.0;
        });
      }
      await _disableWakelock();
      return null;
    }
  }

  // Simulate upload progress
  void _startUploadSimulation() {
    _uploadSimulationTimer?.cancel();
    
    setState(() {
      _isSimulatingUpload = true;
      _simulatedUploadProgress = 0.0;
    });
    
    // Simulate varying upload speeds
    const updateInterval = Duration(milliseconds: 100);
    const totalDuration = Duration(seconds: 180); // Total simulated upload time
    final totalSteps = totalDuration.inMilliseconds / updateInterval.inMilliseconds;
    
    int currentStep = 0;
    
    _uploadSimulationTimer = Timer.periodic(updateInterval, (timer) {
      currentStep++;
      
      if (currentStep >= totalSteps) {
        timer.cancel();
        setState(() {
          _simulatedUploadProgress = 1.0;
          _isSimulatingUpload = false;
        });
        return;
      }
      
      // Create realistic upload progress with some variation
      double baseProgress = currentStep / totalSteps;
      
      // Add some realistic upload behavior (slower start, faster middle, slower end)
      double adjustedProgress;
      if (baseProgress < 0.1) {
        adjustedProgress = baseProgress * 0.5; // Slower start
      } else if (baseProgress < 0.8) {
        adjustedProgress = 0.05 + (baseProgress - 0.1) * 1.2; // Faster middle
      } else {
        adjustedProgress = 0.05 + 0.7 * 1.2 + (baseProgress - 0.8) * 0.6; // Slower end
      }
      
      setState(() {
        _simulatedUploadProgress = adjustedProgress.clamp(0.0, 1.0);
      });
    });
  }

  void _clearVideo() {
    if (_videoPlayerController != null) {
      _videoPlayerController!.dispose();
      _videoPlayerController = null;
    }
    _videoFile = null;
    _videoInfo = null;
    
    final authProvider = ref.read(authenticationProvider.notifier);
    if (!_isProcessing && !authProvider.isLoading) {
      _disableWakelock();
    }
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

  Future<void> _setVideoDirectly(File videoFile, VideoInfo videoInfo) async {
    setState(() {
      _videoFile = videoFile;
      _videoInfo = videoInfo;
    });
    
    await _initializeVideoPlayer();
  }

  Future<bool> _checkUserAuthentication() async {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    
    if (isAuthenticated) {
      return true;
    }
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: const LoginRequiredWidget(
            title: 'Sign In Required',
            subtitle: 'You need to sign in before you can upload content.',
            actionText: 'Sign In',
            icon: Icons.video_call,
          ),
        ),
      ),
    );
    
    return result ?? false;
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final isAuthenticated = await _checkUserAuthentication();
      if (!isAuthenticated) {
        return;
      }
      
      final authProvider = ref.read(authenticationProvider.notifier);
      final currentUser = ref.read(currentUserProvider);
      
      if (currentUser == null) {
        _showError('User not found. Please try again.');
        return;
      }
      
      if (_videoFile == null) {
        _showError('Please select a video');
        return;
      }
      
      await _enableWakelock();
      
      // Parse tags
      List<String> tags = [];
      if (_tagsController.text.isNotEmpty) {
        tags = _tagsController.text.split(',').map((tag) => tag.trim()).toList();
      }
      
      // Parse price
      double price = 0.0;
      if (_priceController.text.isNotEmpty) {
        price = double.tryParse(_priceController.text) ?? 0.0;
      }
      
      // STEP 1: Generate thumbnail FIRST from the original, unprocessed video
      debugPrint('🎬 Step 1: Generating thumbnail from original video...');
      File? thumbnailFile;
      try {
        final thumbnailService = VideoThumbnailService();
        thumbnailFile = await thumbnailService.generateBestThumbnailFile(
          videoFile: _videoFile!,
          maxWidth: 400,
          maxHeight: 600,
          quality: 85,
        );
        
        if (thumbnailFile == null) {
          debugPrint('⚠️ Warning: Failed to generate thumbnail, continuing without it');
        } else {
          debugPrint('✅ Thumbnail generated successfully from original video: ${thumbnailFile.path}');
        }
      } catch (e) {
        debugPrint('❌ Error generating thumbnail: $e');
        // Continue without thumbnail
      }
      
      // STEP 2: Process video (audio enhancement, etc.) AFTER thumbnail generation
      debugPrint('🔧 Step 2: Processing video (audio enhancement)...');
      File videoToUpload = _videoFile!;
      
      if (_videoInfo != null) {
        final processedVideo = await _optimizeVideoQualitySize(_videoFile!, _videoInfo!);
        
        if (processedVideo != null) {
          videoToUpload = processedVideo;
          debugPrint('✅ Video processed successfully');
        } else {
          debugPrint('⚠️ Video processing failed, using original video');
        }
      }
      
      // Start upload simulation
      _startUploadSimulation();
      
      // STEP 3: Upload with pre-generated thumbnail
      debugPrint('☁️ Step 3: Uploading video and thumbnail...');
      authProvider.createVideo(
        videoFile: videoToUpload,
        thumbnailFile: thumbnailFile, // Pass pre-generated thumbnail
        caption: _captionController.text,
        tags: tags,
        price: price,
        onSuccess: (message) {
          _uploadSimulationTimer?.cancel();
          setState(() {
            _isSimulatingUpload = false;
            _simulatedUploadProgress = 1.0;
          });
          _showSuccess(message);
          _navigateBack();
        },
        onError: (error) {
          _uploadSimulationTimer?.cancel();
          setState(() {
            _isSimulatingUpload = false;
            _simulatedUploadProgress = 0.0;
          });
          _showError(error);
          _disableWakelock();
        },
      );
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
    _disableWakelock();
    Future.delayed(const Duration(milliseconds: 300), () {
      Navigator.of(context).pop(true);
    });
  }

  // Helper method to get upload state
  bool get _isUploading {
    final authState = ref.read(authenticationProvider).value ?? const AuthenticationState();
    return authState.isUploading || _isSimulatingUpload;
  }

  // Helper method to get upload progress
  double get _uploadProgress {
    if (_isSimulatingUpload) {
      return _simulatedUploadProgress;
    }
    final authState = ref.read(authenticationProvider).value ?? const AuthenticationState();
    return authState.uploadProgress;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = ref.watch(authenticationProvider);
    final isLoading = ref.watch(isAuthLoadingProvider);
    final authState = authProvider.value ?? const AuthenticationState();
    final isUploading = _isUploading;
    final uploadProgress = _uploadProgress;
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final modernTheme = context.modernTheme;
    
    if (!isAuthenticated) {
      return Scaffold(
        backgroundColor: modernTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: modernTheme.backgroundColor,
          elevation: 0,
          title: Text(
            'Create Video',
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
            onPressed: () {
              _disableWakelock();
              Navigator.of(context).pop();
            },
          ),
        ),
        body: const InlineLoginRequiredWidget(
          title: 'Sign In to Create',
          subtitle: 'You need to sign in before you can upload videos. Join WeiBao to share your content with the world!',
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: modernTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Create Video',
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
          onPressed: () {
            _disableWakelock();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          if (_videoFile != null)
            TextButton(
              onPressed: (isLoading || _isProcessing || isUploading) ? null : _submitForm,
              child: Text(
                _isProcessing ? 'Processing...' : (isUploading ? 'Uploading...' : 'Post'),
                style: TextStyle(
                  color: (isLoading || _isProcessing || isUploading) 
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
              // Video preview or picker
              _videoFile == null
                  ? _buildVideoPickerPlaceholder(modernTheme)
                  : _buildVideoPreview(modernTheme),
                
              const SizedBox(height: 24),
              
              // Processing progress
              if (_isProcessing)
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
                                Icons.video_settings,
                                color: modernTheme.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _videoInfo != null && _videoInfo!.fileSizeMB < 50.0 
                                      ? 'Processing...'
                                      : 'Processing...',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: _processingProgress,
                            backgroundColor: modernTheme.borderColor,
                            valueColor: AlwaysStoppedAnimation<Color>(modernTheme.primaryColor!),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(_processingProgress * 100).toStringAsFixed(0)}% complete',
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
              
              // Upload progress indicator with simulated percentage
              if (isUploading)
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
                                Icons.cloud_upload,
                                color: modernTheme.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Uploading...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '${(uploadProgress * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: modernTheme.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: uploadProgress,
                            backgroundColor: modernTheme.borderColor,
                            valueColor: AlwaysStoppedAnimation<Color>(modernTheme.primaryColor!),
                          ),
                        ],
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
                  filled: true,
                  fillColor: modernTheme.surfaceColor?.withOpacity(0.3),
                ),
                style: TextStyle(color: modernTheme.textColor),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a caption';
                  }
                  return null;
                },
                enabled: !isLoading && !_isProcessing && !isUploading,
              ),
              
              const SizedBox(height: 16),
              
              // Price field (Required temporarily)
              /*TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Price (KES) *',
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
                  filled: true,
                  fillColor: modernTheme.surfaceColor?.withOpacity(0.3),
                  hintText: 'e.g. 100, 500, 1000',
                  hintStyle: TextStyle(color: modernTheme.textSecondaryColor?.withOpacity(0.5)),
                  prefixIcon: Icon(
                    Icons.attach_money,
                    color: modernTheme.textSecondaryColor,
                  ),
                  helperText: 'Enter whole numbers only (minimum 1 KES)',
                  helperStyle: TextStyle(
                    color: modernTheme.textSecondaryColor?.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                style: TextStyle(color: modernTheme.textColor),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  final price = int.tryParse(value);
                  if (price == null) {
                    return 'Please enter a valid price';
                  }
                  if (price <= 0) {
                    return 'Price must be greater than 0';
                  }
                  return null;
                },
                enabled: !isLoading && !_isProcessing && !isUploading,
              ),
              
              const SizedBox(height: 16),*/
              
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
                  filled: true,
                  fillColor: modernTheme.surfaceColor?.withOpacity(0.3),
                  hintText: 'e.g. sports, travel, music',
                ),
                style: TextStyle(color: modernTheme.textColor),
                enabled: !isLoading && !_isProcessing && !isUploading,
              ),
              
              const SizedBox(height: 24),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (!isLoading && !_isProcessing && !isUploading) ? _submitForm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: modernTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: modernTheme.primaryColor!.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? Text(_videoInfo != null && _videoInfo!.fileSizeMB < 50.0 
                          ? 'Processing...' 
                          : 'Processing...')
                      : (isUploading
                          ? const Text('Uploading...')
                          : const Text('Post Video')),
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
              'Add Video',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Max 5 minutes • Videos under 30 seconds perform better',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: (!_isProcessing && !_isUploading) ? _pickVideoFromGallery : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                disabledBackgroundColor: modernTheme.primaryColor!.withOpacity(0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.video_library,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text('Select Video'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: (!_isProcessing && !_isUploading) ? _showGoLiveMessage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                disabledBackgroundColor: modernTheme.primaryColor!.withOpacity(0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.video_camera_back,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text('Go Live'),
                ],
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
              onPressed: (!_isProcessing && !_isUploading) ? _pickVideoFromGallery : null,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit,
                  color: (!_isProcessing && !_isUploading) ? Colors.white : Colors.grey,
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
}
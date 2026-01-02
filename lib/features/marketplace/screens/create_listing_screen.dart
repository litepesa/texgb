// lib/features/marketplace/screens/create_listing_screen.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:textgb/features/authentication/widgets/login_required_widget.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/marketplace/providers/marketplace_provider.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/marketplace/services/marketplace_thumbnail_service.dart';
import 'package:textgb/features/users/widgets/seller_required_banner_widget.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

// Data classes for marketplaceVideo processing
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

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
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
  VideoPlayerController? _videoController;
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
    _videoController?.dispose();
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
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(_videoFile!);

      await _videoController!.initialize();
      _videoController!.setLooping(true);

      setState(() {});
    } catch (e) {
      _showError('Failed to initialize video player');
    }
  }

  Future<void> _pickItemFromGallery() async {
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.live_tv_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Live Selling'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFD32F2F),
                    Color(0xFFE91E63),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Coming Soon!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Live selling is coming soon for verified sellers.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'What is Live Selling?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Showcase products live to thousands of viewers\n'
              '• Real-time interaction with buyers\n'
              '• Instant sales during livestreams\n'
              '• Exclusive access for verified sellers',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Get verified to be first in line when live selling launches!',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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

      // 1. Small delay for OS to flush file buffers to disk
      await Future.delayed(const Duration(milliseconds: 300));

      final outputFile = File(outputPath);

      // 2. Check if file exists
      if (!await outputFile.exists()) {
        debugPrint('❌ Processed file does not exist');
        await _disableWakelock();
        return null;
      }

      // 3. Check file size - ensure it's not empty
      final fileSize = await outputFile.length();
      if (fileSize == 0) {
        debugPrint('⚠️ File is empty (0 bytes), retrying after delay...');
        await Future.delayed(const Duration(milliseconds: 1000));
        final retrySize = await outputFile.length();
        if (retrySize == 0) {
          debugPrint('❌ File is genuinely empty after retry');
          await _disableWakelock();
          return null;
        }
      }

      // 4. Verify file is readable
      try {
        final bytes = await outputFile.openRead(0, 1024).first;
        if (bytes.isEmpty) {
          debugPrint('❌ File exists but cannot be read');
          await _disableWakelock();
          return null;
        }
      } catch (e) {
        debugPrint('❌ File read error: $e');
        await _disableWakelock();
        return null;
      }

      // 5. Compare to expected size (warning if too small)
      final expectedMinSize = info.fileSizeMB * 0.3 * 1024 * 1024; // At least 30% of original
      if (fileSize < expectedMinSize) {
        debugPrint('⚠️ Warning: Processed file (${fileSize / (1024 * 1024)}MB) is much smaller than expected');
      }

      debugPrint('✅ Verified processed file: ${fileSize / (1024 * 1024)}MB');
      return outputFile;
      
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
    if (_videoController != null) {
      _videoController!.dispose();
      _videoController = null;
    }
    _videoFile = null;
    _videoInfo = null;

    final authProvider = ref.read(authenticationProvider.notifier);
    if (!_isProcessing && !authProvider.isLoading) {
      _disableWakelock();
    }
  }

  void _togglePlayPause() {
    if (_videoController == null) return;

    setState(() {
      if (_isVideoPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
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
        final thumbnailService = MarketplaceThumbnailService();
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
      final marketplaceNotifier = ref.read(marketplaceProvider.notifier);
      marketplaceNotifier.createMarketplaceVideo(
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
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.fixed,
      ),
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

  void _handleRefresh() {
    HapticFeedback.lightImpact();
    ref.invalidate(authenticationProvider);
    _showMessage('Refreshing payment status...');
  }

  void _showPaymentInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.account_balance_wallet,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text('Marketplace Activation'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'One-Time Activation Fee:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.payment,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'KES 2,999',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'One-time payment to unlock marketplace posting',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Mpesa Payment Details:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Paybill: ',
                              style: TextStyle(color: Colors.white),
                            ),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: '4146499'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Paybill number copied to clipboard!'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '4146499',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.copy,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Account Number: Your registered phone number',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'After payment, our admin will verify and activate your account within 24 hours',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = ref.watch(authenticationProvider);
    final isLoading = ref.watch(isAuthLoadingProvider);
    final authState = authProvider.value ?? const AuthenticationState();
    final isUploading = _isUploading;
    final uploadProgress = _uploadProgress;
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final currentUser = ref.watch(currentUserProvider);
    // Use isSeller field to check if user can create marketplace listings
    final canPost = currentUser?.isSeller ?? false;
    final modernTheme = context.modernTheme;
    
    if (!isAuthenticated) {
      return Scaffold(
        backgroundColor: modernTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: modernTheme.backgroundColor,
          elevation: 0,
          title: Text(
            'Create Listing',
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
          subtitle: 'You need to sign in before you can upload videos. Join WemaChat to share your content with the world!',
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: modernTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Create Listing',
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
          if (_videoFile != null && canPost)
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Required Banner (if cannot post)
                  // FIXED: Positioned banner removed from here to match users list screen
                  
                  // Video preview or picker
                  _videoFile == null
                      ? _buildVideoPickerPlaceholder(modernTheme, canPost)
                      : _buildVideoPreview(modernTheme, canPost),
                    
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
                    enabled: !isLoading && !_isProcessing && !isUploading && canPost,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Price field (Required temporarily)
                  TextFormField(
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
                    enabled: !isLoading && !_isProcessing && !isUploading && canPost,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tags (Optional)
                  TextFormField(
                    controller: _tagsController,
                    decoration: InputDecoration(
                      labelText: 'Keyword (Optional)',
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
                    enabled: !isLoading && !_isProcessing && !isUploading && canPost,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (!isLoading && !_isProcessing && !isUploading && canPost) ? _submitForm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canPost ? modernTheme.primaryColor : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: modernTheme.primaryColor!.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: !canPost
                          ? const Text('Seller Account Required')
                          : (_isProcessing
                              ? Text(_videoInfo != null && _videoInfo!.fileSizeMB < 50.0
                                  ? 'Processing...'
                                  : 'Processing...')
                              : (isUploading
                                  ? const Text('Uploading...')
                                  : const Text('Post Listing'))),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          // Seller required banner (matches position in users list screen)
          SellerRequiredBannerWidget(
            verticalPosition: 0.35,
            horizontalMargin: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildMarketplaceBanner(ModernThemeExtension theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFF6366F1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showPaymentInstructions,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                // Refresh button
                Positioned(
                  top: 0,
                  right: 0,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleRefresh,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                // Banner content
                Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Row(
                    children: [
                      // Animated icon
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(seconds: 2),
                        builder: (context, value, child) {
                          return Transform.rotate(
                            angle: value * 0.1,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // FIXED: Used Wrap instead of Row for better responsiveness
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                const Text(
                                  '🔒 Payment Required',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'KES 2,999',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Pay one-time activation fee to post on marketplace',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View Payment Details',
                                    style: TextStyle(
                                      color: theme.primaryColor ?? const Color(0xFF6366F1),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: theme.primaryColor ?? const Color(0xFF6366F1),
                                    size: 14,
                                  ),
                                ],
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
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPickerPlaceholder(ModernThemeExtension modernTheme, bool canPost) {
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
              color: canPost ? modernTheme.primaryColor : Colors.grey,
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
            // FIXED: Changed the text widget structure to fix the textAlign issue
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Max 5 minutes • Videos under 30 seconds perform better',
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: (!_isProcessing && !_isUploading && canPost) ? _pickItemFromGallery : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canPost ? modernTheme.primaryColor : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                disabledBackgroundColor: Colors.grey.withOpacity(0.5),
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
                  Text(canPost ? 'Select Video' : 'Payment Required'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: (!_isProcessing && !_isUploading && canPost) ? _showGoLiveMessage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canPost ? modernTheme.primaryColor : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                disabledBackgroundColor: Colors.grey.withOpacity(0.5),
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

  Widget _buildVideoPreview(ModernThemeExtension modernTheme, bool canPost) {
    if (_videoController != null &&
        _videoController!.value.isInitialized) {
      return Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
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
              onPressed: (!_isProcessing && !_isUploading && canPost) ? _pickItemFromGallery : null,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit,
                  color: (!_isProcessing && !_isUploading && canPost) ? Colors.white : Colors.grey,
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

// Inline login required widget
class InlineLoginRequiredWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  
  const InlineLoginRequiredWidget({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: modernTheme.primaryColor!.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.video_call,
                color: modernTheme.primaryColor,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                subtitle,
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Navigate to login screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
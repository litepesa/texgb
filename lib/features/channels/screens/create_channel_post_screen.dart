// lib/features/channels/screens/create_channel_post_screen.dart
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:camera/camera.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/services/video_processing_service.dart';
import 'package:textgb/features/channels/widgets/modern_camera_screen.dart';
import 'package:textgb/features/channels/widgets/video_editor_screen.dart';
import 'package:textgb/features/channels/widgets/modern_media_gallery.dart';
import 'package:textgb/features/channels/widgets/floating_media_preview.dart';
import 'package:textgb/features/channels/widgets/animated_post_composer.dart';
import 'package:textgb/features/channels/widgets/video_processing_overlay.dart';

class CreateChannelPostScreen extends ConsumerStatefulWidget {
  const CreateChannelPostScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateChannelPostScreen> createState() => 
      _CreateChannelPostScreenState();
}

class _CreateChannelPostScreenState 
    extends ConsumerState<CreateChannelPostScreen>
    with TickerProviderStateMixin {
  
  // Animation Controllers
  late AnimationController _mainAnimController;
  late AnimationController _fabAnimController;
  late AnimationController _composerAnimController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Controllers
  final TextEditingController _captionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  VideoPlayerController? _videoController;
  final VideoProcessingService _videoProcessingService = VideoProcessingService();
  
  // State
  List<File> _selectedImages = [];
  File? _selectedVideo;
  File? _processedVideo;
  Uint8List? _videoThumbnail;
  Duration? _videoDuration;
  Duration _trimStart = Duration.zero;
  Duration _trimEnd = Duration.zero;
  bool _isComposerExpanded = false;
  bool _isUploading = false;
  bool _isProcessingVideo = false;
  
  // Media selection mode
  MediaType _selectedMediaType = MediaType.none;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _videoProcessingService.initialize();
  }
  
  void _initializeAnimations() {
    _mainAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fabAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _composerAnimController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _composerAnimController,
      curve: Curves.easeOutCubic,
    ));
    
    _mainAnimController.forward();
    _fabAnimController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _mainAnimController.dispose();
    _fabAnimController.dispose();
    _composerAnimController.dispose();
    _captionController.dispose();
    _scrollController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: const Duration(seconds: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  modernTheme.primaryColor!.withOpacity(0.05),
                  modernTheme.backgroundColor!,
                  modernTheme.primaryColor!.withOpacity(0.02),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Custom app bar
                _buildModernAppBar(modernTheme),
                
                // Content area
                Expanded(
                  child: Stack(
                    children: [
                      // Media selection grid
                      if (_selectedMediaType == MediaType.none)
                        _buildMediaSelectionGrid(modernTheme, size)
                      else
                        _buildSelectedMediaView(modernTheme),
                      
                      // Floating composer
                      if (_hasMedia())
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          bottom: _isComposerExpanded ? 0 : 20,
                          left: _isComposerExpanded ? 0 : 20,
                          right: _isComposerExpanded ? 0 : 20,
                          height: _isComposerExpanded ? size.height * 0.6 : 80,
                          child: AnimatedPostComposer(
                            captionController: _captionController,
                            isExpanded: _isComposerExpanded,
                            onExpandToggle: () {
                              setState(() {
                                _isComposerExpanded = !_isComposerExpanded;
                              });
                              if (_isComposerExpanded) {
                                _composerAnimController.forward();
                              } else {
                                _composerAnimController.reverse();
                              }
                            },
                            onPost: _handlePost,
                            mediaCount: _selectedImages.length + (_selectedVideo != null ? 1 : 0),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Upload overlay
          if (_isUploading)
            _buildUploadOverlay(modernTheme),
          
          // Video processing overlay
          if (_isProcessingVideo)
            VideoProcessingOverlay(
              service: _videoProcessingService,
              onCancel: () {
                _videoProcessingService.cancelProcessing();
                setState(() {
                  _isProcessingVideo = false;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: modernTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: modernTheme.textColor,
                size: 20,
              ),
            ),
          ),
          
          // Title
          Expanded(
            child: Text(
              'Create Post',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Reset button
          if (_hasMedia())
            IconButton(
              onPressed: _resetMedia,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.refresh,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMediaSelectionGrid(ModernThemeExtension modernTheme, Size size) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header text
            ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                children: [
                  Text(
                    'What do you want to share?',
                    style: TextStyle(
                      color: modernTheme.textColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose your media type',
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Media options grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.0,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildMediaOption(
                    icon: Icons.camera_alt,
                    title: 'Camera',
                    subtitle: 'Record video or take photo',
                    gradient: [
                      const Color(0xFF667eea),
                      const Color(0xFF764ba2),
                    ],
                    onTap: () => _openCamera(context),
                    delay: 0,
                  ),
                  _buildMediaOption(
                    icon: Icons.video_library,
                    title: 'Video',
                    subtitle: 'Select from gallery',
                    gradient: [
                      const Color(0xFFf093fb),
                      const Color(0xFFf5576c),
                    ],
                    onTap: _selectVideo,
                    delay: 100,
                  ),
                  _buildMediaOption(
                    icon: Icons.photo_library,
                    title: 'Photos',
                    subtitle: 'Up to 10 images',
                    gradient: [
                      const Color(0xFF4facfe),
                      const Color(0xFF00f2fe),
                    ],
                    onTap: _selectImages,
                    delay: 200,
                  ),
                  _buildMediaOption(
                    icon: Icons.collections,
                    title: 'Gallery',
                    subtitle: 'Browse all media',
                    gradient: [
                      const Color(0xFFfa709a),
                      const Color(0xFFfee140),
                    ],
                    onTap: () => _openGallery(context),
                    delay: 300,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Animated circles background
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedMediaView(ModernThemeExtension modernTheme) {
    return Stack(
      children: [
        if (_selectedVideo != null)
          FloatingMediaPreview(
            video: _selectedVideo,
            videoController: _videoController,
            trimStart: _trimStart,
            trimEnd: _trimEnd,
            onEdit: () => _editVideo(context),
            onRemove: _resetMedia,
          )
        else if (_selectedImages.isNotEmpty)
          FloatingMediaPreview(
            images: _selectedImages,
            onAddMore: _selectedImages.length < 10 ? _addMoreImages : null,
            onRemove: _resetMedia,
            onImageRemove: (index) {
              setState(() {
                _selectedImages.removeAt(index);
                if (_selectedImages.isEmpty) {
                  _resetMedia();
                }
              });
            },
          ),
      ],
    );
  }

  Widget _buildUploadOverlay(ModernThemeExtension modernTheme) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Container(
          color: Colors.black.withOpacity(0.8 * value),
          child: Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: modernTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: modernTheme.primaryColor!.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated icon
                    TweenAnimationBuilder<double>(
                      duration: const Duration(seconds: 1),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: value * 2 * math.pi,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  modernTheme.primaryColor!,
                                  modernTheme.primaryColor!.withOpacity(0.6),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.cloud_upload,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      'Creating your post...',
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'This won\'t take long',
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 16,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Progress indicator
                    LinearProgressIndicator(
                      backgroundColor: modernTheme.surfaceColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        modernTheme.primaryColor!,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper methods
  
  bool _hasMedia() {
    return _selectedVideo != null || _selectedImages.isNotEmpty;
  }
  
  void _resetMedia() {
    setState(() {
      _selectedImages.clear();
      _selectedVideo = null;
      _processedVideo = null;
      _videoThumbnail = null;
      _videoController?.dispose();
      _videoController = null;
      _selectedMediaType = MediaType.none;
      _isComposerExpanded = false;
      _trimStart = Duration.zero;
      _trimEnd = Duration.zero;
    });
  }
  
  Future<void> _editVideo(BuildContext context) async {
    if (_selectedVideo == null || _videoController == null) return;
    
    final result = await Navigator.of(context).push<VideoEditResult>(
      MaterialPageRoute(
        builder: (context) => VideoEditorScreen(
          videoFile: _selectedVideo!,
          videoController: _videoController!,
          initialStart: _trimStart,
          initialEnd: _trimEnd,
        ),
        fullscreenDialog: true,
      ),
    );
    
    if (result != null) {
      setState(() {
        _trimStart = result.startTime;
        _trimEnd = result.endTime;
      });
      
      // Process the video with FFmpeg
      await _processVideoWithFFmpeg();
    }
  }
  
  Future<void> _processVideoWithFFmpeg() async {
    setState(() {
      _isProcessingVideo = true;
    });
    
    try {
      // Process video with trimming and compression
      final result = await _videoProcessingService.processVideo(
        inputFile: _selectedVideo!,
        trimStart: _trimStart,
        trimEnd: _trimEnd,
        quality: VideoQuality.high,
        generateThumbnail: true,
      );
      
      // Dispose old controller
      await _videoController?.dispose();
      
      // Update with processed video
      _videoController = VideoPlayerController.file(result.videoFile);
      await _videoController!.initialize();
      
      setState(() {
        _processedVideo = result.videoFile;
        _videoThumbnail = result.thumbnail;
        _videoDuration = result.duration;
        _isProcessingVideo = false;
      });
      
      // Show success with stats
      _showProcessingSuccess(result.stats);
      
    } catch (e) {
      setState(() {
        _isProcessingVideo = false;
      });
      _showError('Video processing failed: $e');
    }
  }
  
  void _showProcessingSuccess(ProcessingStats stats) {
    showDialog(
      context: context,
      builder: (context) {
        final modernTheme = context.modernTheme;
        return AlertDialog(
          backgroundColor: modernTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Video Optimized!',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: modernTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildStatRow('Original Size', stats.formattedOriginalSize, modernTheme),
                    const SizedBox(height: 8),
                    _buildStatRow('Optimized Size', stats.formattedProcessedSize, modernTheme),
                    const SizedBox(height: 8),
                    _buildStatRow('Compression', '${stats.compressionRatio}% smaller', modernTheme),
                    const SizedBox(height: 8),
                    _buildStatRow('Resolution', stats.resolution, modernTheme),
                    const SizedBox(height: 8),
                    _buildStatRow('Bitrate', stats.bitrate, modernTheme),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: modernTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildStatRow(String label, String value, ModernThemeExtension modernTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: modernTheme.textSecondaryColor,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: modernTheme.textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }<void> _openCamera(BuildContext context) async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    
    final result = await Navigator.of(context).push<MediaResult>(
      MaterialPageRoute(
        builder: (context) => ModernCameraScreen(cameras: cameras),
        fullscreenDialog: true,
      ),
    );
    
    if (result != null) {
      if (result.isVideo) {
        await _processVideo(result.file);
      } else {
        setState(() {
          _selectedImages = [result.file];
          _selectedMediaType = MediaType.image;
        });
      }
    }
  }
  
  Future<void> _openGallery(BuildContext context) async {
    final result = await Navigator.of(context).push<MediaResult>(
      MaterialPageRoute(
        builder: (context) => const ModernMediaGallery(),
        fullscreenDialog: true,
      ),
    );
    
    if (result != null) {
      if (result.isVideo) {
        await _processVideo(result.file);
      } else if (result.images != null) {
        setState(() {
          _selectedImages = result.images!;
          _selectedMediaType = MediaType.image;
        });
      }
    }
  }
  
  Future<void> _selectVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    
    if (video != null) {
      await _processVideo(File(video.path));
    }
  }
  
  Future<void> _processVideo(File videoFile) async {
    // Initialize video controller
    _videoController = VideoPlayerController.file(videoFile);
    await _videoController!.initialize();
    
    final duration = _videoController!.value.duration;
    
    setState(() {
      _selectedVideo = videoFile;
      _videoDuration = duration;
      _trimEnd = duration > const Duration(minutes: 5) 
          ? const Duration(minutes: 5) 
          : duration;
      _selectedMediaType = MediaType.video;
    });
    
    // Open video editor if video is longer than 5 minutes
    if (duration > const Duration(minutes: 5)) {
      _editVideo(context);
    }
  }
  
  Future<void> _editVideo(BuildContext context) async {
    if (_selectedVideo == null || _videoController == null) return;
    
    final result = await Navigator.of(context).push<VideoEditResult>(
      MaterialPageRoute(
        builder: (context) => VideoEditorScreen(
          videoFile: _selectedVideo!,
          videoController: _videoController!,
          initialStart: _trimStart,
          initialEnd: _trimEnd,
        ),
        fullscreenDialog: true,
      ),
    );
    
    if (result != null) {
      setState(() {
        _trimStart = result.startTime;
        _trimEnd = result.endTime;
      });
      
      // Process the video with FFmpeg
      await _processVideoWithFFmpeg();
    }
  }
  
  Future<void> _processVideoWithFFmpeg() async {
    setState(() {
      _isProcessingVideo = true;
    });
    
    try {
      // Process video with trimming and compression
      final result = await _videoProcessingService.processVideo(
        inputFile: _selectedVideo!,
        trimStart: _trimStart,
        trimEnd: _trimEnd,
        quality: VideoQuality.high,
        generateThumbnail: true,
      );
      
      // Dispose old controller
      await _videoController?.dispose();
      
      // Update with processed video
      _videoController = VideoPlayerController.file(result.videoFile);
      await _videoController!.initialize();
      
      setState(() {
        _processedVideo = result.videoFile;
        _videoThumbnail = result.thumbnail;
        _videoDuration = result.duration;
        _isProcessingVideo = false;
      });
      
      // Show success with stats
      _showProcessingSuccess(result.stats);
      
    } catch (e) {
      setState(() {
        _isProcessingVideo = false;
      });
      _showError('Video processing failed: $e');
    }
  }
  
  void _showProcessingSuccess(ProcessingStats stats) {
    showDialog(
      context: context,
      builder: (context) {
        final modernTheme = context.modernTheme;
        return AlertDialog(
          backgroundColor: modernTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Video Optimized!',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: modernTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildStatRow('Original Size', stats.formattedOriginalSize, modernTheme),
                    const SizedBox(height: 8),
                    _buildStatRow('Optimized Size', stats.formattedProcessedSize, modernTheme),
                    const SizedBox(height: 8),
                    _buildStatRow('Compression', '${stats.compressionRatio}% smaller', modernTheme),
                    const SizedBox(height: 8),
                    _buildStatRow('Resolution', stats.resolution, modernTheme),
                    const SizedBox(height: 8),
                    _buildStatRow('Bitrate', stats.bitrate, modernTheme),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: modernTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildStatRow(String label, String value, ModernThemeExtension modernTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: modernTheme.textSecondaryColor,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: modernTheme.textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Future<void> _selectImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images.take(10).map((x) => File(x.path)).toList();
        _selectedMediaType = MediaType.image;
      });
    }
  }
  
  Future<void> _addMoreImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      setState(() {
        final newImages = images.map((x) => File(x.path)).toList();
        _selectedImages.addAll(newImages);
        if (_selectedImages.length > 10) {
          _selectedImages = _selectedImages.take(10).toList();
        }
      });
    }
  }
  
  Future<void> _handlePost() async {
    final channelVideosNotifier = ref.read(channelVideosProvider.notifier);
    final userChannel = ref.read(channelsProvider).userChannel;
    
    if (userChannel == null) {
      _showError('You need to create a channel first');
      return;
    }
    
    if (_captionController.text.trim().isEmpty) {
      _showError('Please add a caption');
      return;
    }
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      final caption = _captionController.text.trim();
      final tags = _extractTags(caption);
      
      if (_processedVideo != null || _selectedVideo != null) {
        // Use processed video if available, otherwise original
        final videoToUpload = _processedVideo ?? _selectedVideo!;
        
        await channelVideosNotifier.uploadVideo(
          channel: userChannel,
          videoFile: videoToUpload,
          caption: caption,
          tags: tags,
          thumbnail: _videoThumbnail,
          duration: _videoDuration,
          onSuccess: (message) {
            Navigator.of(context).pop(true);
            _showSuccess(message);
          },
          onError: (error) {
            setState(() => _isUploading = false);
            _showError(error);
          },
        );
      } else if (_selectedImages.isNotEmpty) {
        await channelVideosNotifier.uploadImages(
          channel: userChannel,
          imageFiles: _selectedImages,
          caption: caption,
          tags: tags,
          onSuccess: (message) {
            Navigator.of(context).pop(true);
            _showSuccess(message);
          },
          onError: (error) {
            setState(() => _isUploading = false);
            _showError(error);
          },
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      _showError('Upload failed: $e');
    }
  }
  
  List<String> _extractTags(String caption) {
    final tagPattern = RegExp(r'#(\w+)');
    final matches = tagPattern.allMatches(caption);
    return matches.map((match) => match.group(1)!).toList();
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// Enums and classes
enum MediaType { none, image, video }

class MediaResult {
  final File file;
  final bool isVideo;
  final List<File>? images;
  
  MediaResult({
    required this.file,
    required this.isVideo,
    this.images,
  });
}

class VideoEditResult {
  final Duration startTime;
  final Duration endTime;
  
  VideoEditResult({
    required this.startTime,
    required this.endTime,
  });
}
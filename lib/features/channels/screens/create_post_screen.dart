// lib/features/channels/screens/create_post_screen.dart
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:camera/camera.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/services/video_processing_service.dart';
import 'package:textgb/features/channels/widgets/modern_camera_screen.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen>
    with TickerProviderStateMixin {
  // Controllers
  final TextEditingController _captionController = TextEditingController();
  final VideoProcessingService _videoProcessingService = VideoProcessingService();
  VideoPlayerController? _videoController;
  
  // Animation Controllers
  late AnimationController _scaleAnimController;
  late AnimationController _slideAnimController;
  late AnimationController _processingAnimController;
  
  // Media State
  File? _selectedVideo;
  Uint8List? _videoThumbnail;
  Duration _videoDuration = Duration.zero;
  bool _isProcessing = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  
  // Gallery State
  List<AssetEntity> _recentVideos = [];
  AssetEntity? _selectedAsset;
  bool _isLoadingGallery = true;
  
  // UI State
  bool _showCaption = false;
  final List<String> _trendingTags = ['fyp', 'viral', 'trending', 'music', 'dance'];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadRecentVideos();
    _videoProcessingService.initialize();
  }
  
  void _initializeAnimations() {
    _scaleAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _processingAnimController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _scaleAnimController.forward();
  }
  
  Future<void> _loadRecentVideos() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      setState(() => _isLoadingGallery = false);
      return;
    }
    
    final albums = await PhotoManager.getAssetPathList(type: RequestType.video);
    if (albums.isNotEmpty) {
      final recentAlbum = albums.first;
      final videos = await recentAlbum.getAssetListRange(start: 0, end: 20);
      
      // Filter videos under 5 minutes
      final filteredVideos = videos.where((v) => v.duration <= 300).toList();
      
      setState(() {
        _recentVideos = filteredVideos;
        _isLoadingGallery = false;
      });
    }
  }
  
  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    _scaleAnimController.dispose();
    _slideAnimController.dispose();
    _processingAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Main content
          if (_selectedVideo == null)
            _buildMediaSelector(modernTheme, size)
          else
            _buildVideoEditor(modernTheme, size),
          
          // Processing overlay
          if (_isProcessing)
            _buildProcessingOverlay(modernTheme),
          
          // Upload overlay
          if (_isUploading)
            _buildUploadOverlay(modernTheme),
        ],
      ),
    );
  }

  Widget _buildMediaSelector(ModernThemeExtension modernTheme, Size size) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
                Text(
                  'New Post',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          
          // Camera/Gallery Options
          Expanded(
            child: Column(
              children: [
                // Camera option
                GestureDetector(
                  onTap: _openCamera,
                  child: Container(
                    height: size.height * 0.35,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          modernTheme.primaryColor!.withOpacity(0.8),
                          modernTheme.primaryColor!.withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: modernTheme.primaryColor!.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background pattern
                        Positioned.fill(
                          child: CustomPaint(
                            painter: GridPatternPainter(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                        // Content
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.videocam,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Record Video',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create up to 5 minute videos',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Recent videos section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Videos',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: _openFullGallery,
                              child: Text(
                                'See all',
                                style: TextStyle(
                                  color: modernTheme.primaryColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Video grid
                      Expanded(
                        child: _isLoadingGallery
                            ? const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              )
                            : _recentVideos.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.video_library_outlined,
                                          color: Colors.white.withOpacity(0.5),
                                          size: 48,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No videos found',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.5),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : GridView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      childAspectRatio: 0.6,
                                    ),
                                    itemCount: _recentVideos.length,
                                    itemBuilder: (context, index) {
                                      final asset = _recentVideos[index];
                                      return _buildVideoThumbnail(asset);
                                    },
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
    );
  }

  Widget _buildVideoThumbnail(AssetEntity asset) {
    return GestureDetector(
      onTap: () => _selectVideoFromGallery(asset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            FutureBuilder<Uint8List?>(
              future: asset.thumbnailDataWithSize(
                const ThumbnailSize(200, 300),
                quality: 85,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                  );
                }
                return Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            
            // Duration overlay
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDuration(asset.duration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoEditor(ModernThemeExtension modernTheme, Size size) {
    return Stack(
      children: [
        // Video preview
        if (_videoController != null && _videoController!.value.isInitialized)
          GestureDetector(
            onTap: _togglePlayPause,
            child: Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            ),
          )
        else
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        
        // Gradient overlays
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.5),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
              stops: const [0.0, 0.2, 0.8, 1.0],
            ),
          ),
        ),
        
        // Header
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedVideo = null;
                      _videoController?.dispose();
                      _videoController = null;
                      _showCaption = false;
                    });
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                if (!_showCaption)
                  IconButton(
                    onPressed: () => setState(() => _showCaption = true),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.text_fields, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Play/Pause overlay
        if (_videoController != null && !_videoController!.value.isPlaying)
          Center(
            child: GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),
        
        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              children: [
                // Caption input
                if (_showCaption)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _captionController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Add a caption...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                
                // Trending tags
                if (_showCaption)
                  Container(
                    height: 36,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _trendingTags.length,
                      itemBuilder: (context, index) {
                        final tag = _trendingTags[index];
                        return GestureDetector(
                          onTap: () => _addTag(tag),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                
                // Post button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        // Video info
                        if (_videoThumbnail != null)
                          Container(
                            width: 60,
                            height: 80,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: MemoryImage(_videoThumbnail!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        
                        // Duration and size info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Duration: ${_formatDuration(_videoDuration.inSeconds)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              if (_selectedVideo != null)
                                FutureBuilder<int>(
                                  future: _selectedVideo!.length(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Text(
                                        'Size: ${_formatFileSize(snapshot.data!)}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                            ],
                          ),
                        ),
                        
                        // Post button
                        ElevatedButton(
                          onPressed: _handlePost,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: modernTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            'Post',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingOverlay(ModernThemeExtension modernTheme) {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _processingAnimController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _processingAnimController.value * 2 * 3.14159,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          modernTheme.primaryColor!,
                          modernTheme.primaryColor!.withOpacity(0.5),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_fix_high,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Processing video...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Optimizing for best quality',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOverlay(ModernThemeExtension modernTheme) {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: modernTheme.primaryColor!.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                value: _uploadProgress,
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(modernTheme.primaryColor!),
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${(_uploadProgress * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Uploading your video...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  
  Future<void> _openCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showError('No cameras available');
        return;
      }
      
      final result = await Navigator.push<MediaResult>(
        context,
        MaterialPageRoute(
          builder: (context) => ModernCameraScreen(cameras: cameras),
          fullscreenDialog: true,
        ),
      );
      
      if (result != null && result.isVideo) {
        await _processSelectedVideo(result.file);
      }
    } catch (e) {
      _showError('Failed to open camera: $e');
    }
  }
  
  Future<void> _openFullGallery() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
    
    if (video != null) {
      await _processSelectedVideo(File(video.path));
    }
  }
  
  Future<void> _selectVideoFromGallery(AssetEntity asset) async {
    setState(() => _selectedAsset = asset);
    
    final file = await asset.file;
    if (file != null) {
      await _processSelectedVideo(file);
    }
  }
  
  Future<void> _processSelectedVideo(File videoFile) async {
    setState(() => _isProcessing = true);
    
    try {
      // Initialize video controller
      _videoController = VideoPlayerController.file(videoFile);
      await _videoController!.initialize();
      
      // Generate thumbnail
      final thumbnail = await vt.VideoThumbnail.thumbnailData(
        video: videoFile.path,
        imageFormat: vt.ImageFormat.JPEG,
        maxWidth: 300,
        quality: 85,
      );
      
      setState(() {
        _selectedVideo = videoFile;
        _videoThumbnail = thumbnail;
        _videoDuration = _videoController!.value.duration;
        _isProcessing = false;
      });
      
      // Auto-play video
      _videoController!.play();
      _videoController!.setLooping(true);
      
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Failed to process video: $e');
    }
  }
  
  void _togglePlayPause() {
    if (_videoController == null) return;
    
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    });
  }
  
  void _addTag(String tag) {
    final text = _captionController.text;
    if (!text.contains('#$tag')) {
      _captionController.text = '$text #$tag ';
      _captionController.selection = TextSelection.fromPosition(
        TextPosition(offset: _captionController.text.length),
      );
    }
  }
  
  Future<void> _handlePost() async {
    final channelVideosNotifier = ref.read(channelVideosProvider.notifier);
    final channelsState = ref.read(channelsProvider);
    
    if (channelsState.userChannel == null) {
      _showError('You need to create a channel first');
      return;
    }
    
    setState(() => _isUploading = true);
    
    try {
      // Process video with FFmpeg for optimization
      final processedVideo = await _videoProcessingService.processVideo(
        inputFile: _selectedVideo!,
        trimStart: Duration.zero,
        trimEnd: _videoDuration,
        quality: VideoQuality.high,
        generateThumbnail: true,
      );
      
      // Extract tags from caption
      final caption = _captionController.text.trim();
      final tags = RegExp(r'#(\w+)').allMatches(caption)
          .map((match) => match.group(1)!)
          .toList();
      
      // Upload video
      await channelVideosNotifier.uploadVideo(
        channel: channelsState.userChannel!,
        videoFile: processedVideo.videoFile,
        caption: caption,
        tags: tags,
        trimStart: Duration.zero,
        trimEnd: _videoDuration,
        onSuccess: (message) {
          if (mounted) {
            Navigator.of(context).pop(true);
            _showSuccess(message);
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() => _isUploading = false);
            _showError('Upload failed: $error');
          }
        },
      );
      
    } catch (e) {
      setState(() => _isUploading = false);
      _showError('Failed to upload: $e');
    }
  }
  
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}:${secs.toString().padLeft(2, '0')}';
    }
    return '${secs}s';
  }
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Grid pattern painter for camera option
class GridPatternPainter extends CustomPainter {
  final Color color;
  
  GridPatternPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    const gridSize = 30.0;
    
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Media result class (reused from existing code)
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
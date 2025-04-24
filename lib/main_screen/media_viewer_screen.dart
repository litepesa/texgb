import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:share_plus/share_plus.dart';

class MediaViewerScreen extends StatefulWidget {
  final String mediaUrl;
  final bool isImage;
  final String? caption;
  final String? senderName;
  
  const MediaViewerScreen({
    Key? key,
    required this.mediaUrl,
    required this.isImage,
    this.caption,
    this.senderName,
  }) : super(key: key);

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitializing = true;
  bool _hasError = false;
  bool _showControls = true;
  final TransformationController _transformationController = TransformationController();
  
  @override
  void initState() {
    super.initState();
    
    // Lock to portrait orientation during initialization
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Enter fullscreen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    if (!widget.isImage) {
      _initializeVideoPlayer();
    } else {
      setState(() {
        _isInitializing = false;
      });
    }
    
    // Auto-hide controls after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }
  
  Future<void> _initializeVideoPlayer() async {
    try {
      _videoController = VideoPlayerController.network(widget.mediaUrl);
      await _videoController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).extension<ModernThemeExtension>()?.accentColor ?? Colors.green,
          handleColor: Theme.of(context).extension<ModernThemeExtension>()?.accentColor ?? Colors.green,
          bufferedColor: Colors.grey.withOpacity(0.5),
          backgroundColor: Colors.grey.withOpacity(0.3),
        ),
      );
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _hasError = true;
        });
      }
      debugPrint('Error initializing video: $e');
    }
  }
  
  @override
  void dispose() {
    // Restore UI and orientation when leaving
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([]);
    
    _videoController?.dispose();
    _chewieController?.dispose();
    _transformationController.dispose();
    super.dispose();
  }
  
  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    
    if (_showControls) {
      // Auto-hide after delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _showControls) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }
  
  void _shareMedia() {
    Share.share(widget.mediaUrl, subject: widget.caption ?? 'Shared media');
  }
  
  void _downloadMedia() {
    // Implement download functionality here
    // This would typically save the media to device storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading media...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<ModernThemeExtension>();
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Media content
            Center(
              child: _isInitializing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : _hasError
                      ? _buildErrorWidget()
                      : widget.isImage
                          ? _buildImageViewer()
                          : _buildVideoPlayer(),
            ),
            
            // Top controls (header)
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Visibility(
                visible: _showControls,
                child: SafeArea(
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        // Back button
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        
                        // Title/Caption
                        Expanded(
                          child: Text(
                            widget.caption ?? 'Media',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // More options menu
                        IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.black.withOpacity(0.9),
                              builder: (context) => SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.download, color: Colors.white),
                                      title: const Text('Download', style: TextStyle(color: Colors.white)),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _downloadMedia();
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.share, color: Colors.white),
                                      title: const Text('Share', style: TextStyle(color: Colors.white)),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _shareMedia();
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.close, color: Colors.white),
                                      title: const Text('Cancel', style: TextStyle(color: Colors.white)),
                                      onTap: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline,
          color: Colors.white,
          size: 48,
        ),
        const SizedBox(height: 16),
        const Text(
          'Failed to load media',
          style: TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            if (widget.isImage) {
              setState(() {
                _hasError = false;
              });
            } else {
              setState(() {
                _isInitializing = true;
                _hasError = false;
              });
              _initializeVideoPlayer();
            }
          },
          child: const Text('Retry'),
        ),
      ],
    );
  }
  
  Widget _buildImageViewer() {
    // Using InteractiveViewer for zoom and pan
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 3.0,
      child: CachedNetworkImage(
        imageUrl: widget.mediaUrl,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        errorWidget: (context, url, error) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_hasError) {
              setState(() {
                _hasError = true;
              });
            }
          });
          return const SizedBox.shrink();
        },
      ),
    );
  }
  
  Widget _buildVideoPlayer() {
    if (_chewieController == null) {
      return const Center(
        child: Text(
          'Error loading video',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    
    return Chewie(controller: _chewieController!);
  }
}
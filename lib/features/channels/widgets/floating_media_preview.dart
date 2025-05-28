// lib/features/channels/widgets/floating_media_preview.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class FloatingMediaPreview extends StatefulWidget {
  final File? video;
  final List<File>? images;
  final VideoPlayerController? videoController;
  final Duration? trimStart;
  final Duration? trimEnd;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  final VoidCallback? onAddMore;
  final Function(int)? onImageRemove;

  const FloatingMediaPreview({
    Key? key,
    this.video,
    this.images,
    this.videoController,
    this.trimStart,
    this.trimEnd,
    this.onEdit,
    this.onRemove,
    this.onAddMore,
    this.onImageRemove,
  }) : super(key: key);

  @override
  State<FloatingMediaPreview> createState() => _FloatingMediaPreviewState();
}

class _FloatingMediaPreviewState extends State<FloatingMediaPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  
  PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isExpanded = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _rotateAnimation = Tween<double>(
      begin: -0.5,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final size = MediaQuery.of(context).size;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isExpanded ? size.width - 40 : size.width - 80,
                height: _isExpanded ? size.height * 0.6 : 200,
                margin: EdgeInsets.all(_isExpanded ? 20 : 40),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: modernTheme.primaryColor!.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Media content
                      if (widget.video != null)
                        _buildVideoPreview(modernTheme)
                      else if (widget.images != null)
                        _buildImageCarousel(modernTheme),
                      
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.transparent,
                              Colors.black.withOpacity(0.5),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                      
                      // Controls
                      _buildControls(modernTheme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoPreview(ModernThemeExtension modernTheme) {
    if (widget.videoController == null || !widget.videoController!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    
    return GestureDetector(
      onTap: _toggleVideoPlayback,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: widget.videoController!.value.aspectRatio,
            child: VideoPlayer(widget.videoController!),
          ),
          
          // Play/pause indicator
          AnimatedOpacity(
            opacity: widget.videoController!.value.isPlaying ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.black,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(ModernThemeExtension modernTheme) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _currentPage = index),
      itemCount: widget.images!.length,
      itemBuilder: (context, index) {
        return Image.file(
          widget.images![index],
          fit: BoxFit.cover,
        );
      },
    );
  }

  Widget _buildControls(ModernThemeExtension modernTheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Media info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.video != null ? Icons.videocam : Icons.photo,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.video != null
                          ? _formatTrimDuration()
                          : '${widget.images!.length} photo${widget.images!.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Action buttons
              Row(
                children: [
                  if (widget.video != null && widget.onEdit != null)
                    _buildActionButton(
                      icon: Icons.content_cut,
                      onTap: widget.onEdit!,
                      color: Colors.orange,
                    ),
                  const SizedBox(width: 8),
                  if (widget.onRemove != null)
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      onTap: widget.onRemove!,
                      color: Colors.red,
                    ),
                ],
              ),
            ],
          ),
          
          // Bottom controls
          Column(
            children: [
              // Page indicators for images
              if (widget.images != null && widget.images!.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.images!.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: index == _currentPage ? 24 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index == _currentPage
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Add more images button
              if (widget.images != null && 
                  widget.images!.length < 10 && 
                  widget.onAddMore != null)
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onAddMore,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: Text('Add More (${10 - widget.images!.length} left)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
    );
  }

  void _toggleVideoPlayback() {
    if (widget.videoController == null) return;
    
    setState(() {
      if (widget.videoController!.value.isPlaying) {
        widget.videoController!.pause();
      } else {
        widget.videoController!.play();
      }
    });
  }

  String _formatTrimDuration() {
    if (widget.trimStart == null || widget.trimEnd == null) return 'Video';
    
    final duration = widget.trimEnd! - widget.trimStart!;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
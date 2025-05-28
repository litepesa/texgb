// lib/features/channels/widgets/floating_media_preview.dart
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late AnimationController _shimmerController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<Offset> _slideAnimation;
  
  PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isExpanded = false;
  bool _isLoading = true;
  bool _showVideoControls = true;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    // Simulate loading completion
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
    
    // Auto-hide video controls
    if (widget.video != null) {
      _startControlsTimer();
    }
  }
  
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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
      begin: -0.1,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.linear,
    ));
    
    _animationController.forward();
    _pulseController.repeat(reverse: true);
    _shimmerController.repeat();
  }
  
  void _startControlsTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showVideoControls) {
        setState(() {
          _showVideoControls = false;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _bounceController.dispose();
    _shimmerController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final size = MediaQuery.of(context).size;
    
    return SlideTransition(
      position: _slideAnimation,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotateAnimation.value,
              child: GestureDetector(
                onTap: _handleTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  width: _isExpanded ? size.width - 32 : size.width - 64,
                  height: _isExpanded ? size.height * 0.7 : 240,
                  margin: EdgeInsets.all(_isExpanded ? 16 : 32),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_isExpanded ? 28 : 24),
                    boxShadow: [
                      BoxShadow(
                        color: modernTheme.primaryColor!.withOpacity(0.3),
                        blurRadius: _isExpanded ? 40 : 25,
                        spreadRadius: _isExpanded ? 8 : 3,
                        offset: Offset(0, _isExpanded ? 15 : 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_isExpanded ? 28 : 24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Loading shimmer effect
                        if (_isLoading)
                          _buildShimmerLoader(modernTheme),
                        
                        // Media content
                        if (!_isLoading) ...[
                          if (widget.video != null)
                            _buildEnhancedVideoPreview(modernTheme)
                          else if (widget.images != null)
                            _buildEnhancedImageCarousel(modernTheme),
                        ],
                        
                        // Enhanced gradient overlay
                        if (!_isLoading)
                          _buildGradientOverlay(),
                        
                        // Enhanced controls
                        if (!_isLoading)
                          _buildEnhancedControls(modernTheme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoader(ModernThemeExtension modernTheme) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                modernTheme.surfaceColor ?? Colors.grey[800]!,
                modernTheme.surfaceColor?.withOpacity(0.8) ?? Colors.grey[700]!,
                modernTheme.surfaceColor ?? Colors.grey[800]!,
              ],
              stops: [
                (_shimmerAnimation.value - 1).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 1).clamp(0.0, 1.0),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: modernTheme.primaryColor?.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.video != null ? Icons.videocam : Icons.photo,
                    color: modernTheme.primaryColor,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Processing media...',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedVideoPreview(ModernThemeExtension modernTheme) {
    if (widget.videoController == null || !widget.videoController!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: modernTheme.primaryColor,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading video...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return GestureDetector(
      onTap: () {
        if (widget.video != null) {
          setState(() {
            _showVideoControls = !_showVideoControls;
          });
          if (_showVideoControls) {
            _startControlsTimer();
          }
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video player with proper aspect ratio
          Container(
            color: Colors.black,
            child: Center(
              child: AspectRatio(
                aspectRatio: widget.videoController!.value.aspectRatio,
                child: VideoPlayer(widget.videoController!),
              ),
            ),
          ),
          
          // Enhanced play/pause overlay
          AnimatedOpacity(
            opacity: !widget.videoController!.value.isPlaying ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Center(
              child: GestureDetector(
                onTap: _toggleVideoPlayback,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: _isExpanded ? 80 : 60,
                        height: _isExpanded ? 80 : 60,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.8),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: _isExpanded ? 40 : 30,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          
          // Video progress indicator
          if (_isExpanded && widget.videoController!.value.isPlaying)
            Positioned(
              bottom: 80,
              left: 20,
              right: 20,
              child: _buildVideoProgressBar(modernTheme),
            ),
          
          // Mute/unmute button
          if (_isExpanded && _showVideoControls)
            Positioned(
              top: 20,
              right: 20,
              child: _buildVolumeButton(modernTheme),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoProgressBar(ModernThemeExtension modernTheme) {
    final duration = widget.videoController!.value.duration;
    final position = widget.videoController!.value.position;
    final progress = duration.inMilliseconds > 0 
        ? position.inMilliseconds / duration.inMilliseconds 
        : 0.0;
    
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        widthFactor: progress.clamp(0.0, 1.0),
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: modernTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: modernTheme.primaryColor!.withOpacity(0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeButton(ModernThemeExtension modernTheme) {
    return GestureDetector(
      onTap: () {
        final currentVolume = widget.videoController!.value.volume;
        widget.videoController!.setVolume(currentVolume > 0 ? 0.0 : 1.0);
        setState(() {});
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          widget.videoController!.value.volume > 0 
              ? Icons.volume_up 
              : Icons.volume_off,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildEnhancedImageCarousel(ModernThemeExtension modernTheme) {
    return Stack(
      children: [
        // Image carousel
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemCount: widget.images!.length,
          itemBuilder: (context, index) {
            return Hero(
              tag: 'image_${widget.images![index].path}',
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    widget.images![index],
                    fit: BoxFit.cover,
                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded) return child;
                      return AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: const Duration(milliseconds: 300),
                        child: child,
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: modernTheme.surfaceColor,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: modernTheme.textSecondaryColor,
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Failed to load image',
                                style: TextStyle(
                                  color: modernTheme.textSecondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Image remove button
                  if (_isExpanded && widget.onImageRemove != null)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _buildImageRemoveButton(index, modernTheme),
                    ),
                ],
              ),
            );
          },
        ),
        
        // Enhanced navigation dots
        if (widget.images!.length > 1)
          Positioned(
            bottom: _isExpanded ? 80 : 40,
            left: 0,
            right: 0,
            child: _buildEnhancedPageIndicators(modernTheme),
          ),
      ],
    );
  }

  Widget _buildImageRemoveButton(int index, ModernThemeExtension modernTheme) {
    return GestureDetector(
      onTap: () {
        _bounceController.forward().then((_) {
          _bounceController.reverse();
        });
        widget.onImageRemove?.call(index);
        HapticFeedback.mediumImpact();
      },
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedPageIndicators(ModernThemeExtension modernTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.images!.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive ? modernTheme.primaryColor : Colors.white.withOpacity(0.5),
            boxShadow: isActive ? [
              BoxShadow(
                color: modernTheme.primaryColor!.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ] : null,
          ),
        );
      }),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.6),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildEnhancedControls(ModernThemeExtension modernTheme) {
    return Padding(
      padding: EdgeInsets.all(_isExpanded ? 20 : 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Enhanced media info badge
              _buildMediaInfoBadge(modernTheme),
              
              // Action buttons
              Row(
                children: [
                  if (widget.video != null && widget.onEdit != null)
                    _buildEnhancedActionButton(
                      icon: Icons.content_cut,
                      label: 'Edit',
                      onTap: widget.onEdit!,
                      color: Colors.orange,
                    ),
                  if (widget.onEdit != null) const SizedBox(width: 8),
                  if (widget.onRemove != null)
                    _buildEnhancedActionButton(
                      icon: Icons.delete_outline,
                      label: 'Remove',
                      onTap: widget.onRemove!,
                      color: Colors.red,
                    ),
                ],
              ),
            ],
          ),
          
          // Bottom controls
          if (_isExpanded) ...[
            Column(
              children: [
                // Add more images button
                if (widget.images != null && 
                    widget.images!.length < 10 && 
                    widget.onAddMore != null)
                  _buildAddMoreButton(modernTheme),
                
                // Expand/collapse indicator
                const SizedBox(height: 12),
                _buildExpandIndicator(modernTheme),
              ],
            ),
          ] else ...[
            _buildExpandIndicator(modernTheme),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaInfoBadge(ModernThemeExtension modernTheme) {
    String info = '';
    IconData icon = Icons.photo;
    
    if (widget.video != null) {
      info = _formatTrimDuration();
      icon = Icons.videocam;
    } else if (widget.images != null) {
      info = '${widget.images!.length} photo${widget.images!.length > 1 ? 's' : ''}';
      icon = Icons.photo;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: modernTheme.primaryColor!.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: modernTheme.primaryColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            info,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        _bounceController.forward().then((_) {
          _bounceController.reverse();
        });
        onTap();
        HapticFeedback.mediumImpact();
      },
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value,
            child: Container(
              padding: EdgeInsets.all(_isExpanded ? 12 : 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.9),
                    color.withOpacity(0.7),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: _isExpanded ? 20 : 16,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddMoreButton(ModernThemeExtension modernTheme) {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _bounceController.forward().then((_) {
            _bounceController.reverse();
          });
          widget.onAddMore?.call();
          HapticFeedback.lightImpact();
        },
        icon: const Icon(Icons.add_photo_alternate),
        label: Text('Add More (${10 - widget.images!.length} left)'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.9),
          foregroundColor: Colors.black87,
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildExpandIndicator(ModernThemeExtension modernTheme) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _isExpanded ? 'Collapse' : 'Expand',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap() {
    if (!_isExpanded) {
      setState(() {
        _isExpanded = true;
      });
      HapticFeedback.lightImpact();
    }
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
    
    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });
    
    HapticFeedback.mediumImpact();
  }

  String _formatTrimDuration() {
    if (widget.trimStart == null || widget.trimEnd == null) return 'Video';
    
    final duration = widget.trimEnd! - widget.trimStart!;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${seconds}s';
    }
  }
}
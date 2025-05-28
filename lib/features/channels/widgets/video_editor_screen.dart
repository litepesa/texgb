// lib/features/channels/widgets/video_editor_screen.dart
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/screens/create_channel_post_screen.dart';

class VideoEditorScreen extends StatefulWidget {
  final File videoFile;
  final VideoPlayerController videoController;
  final Duration initialStart;
  final Duration initialEnd;

  const VideoEditorScreen({
    Key? key,
    required this.videoFile,
    required this.videoController,
    required this.initialStart,
    required this.initialEnd,
  }) : super(key: key);

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen>
    with TickerProviderStateMixin {
  // Controllers
  late VideoPlayerController _controller;
  late AnimationController _playPauseController;
  late AnimationController _handleController;
  late AnimationController _scrubberController;
  late AnimationController _rippleController;
  
  // Animations
  late Animation<double> _handleScaleAnimation;
  late Animation<double> _playPauseRotation;
  late Animation<double> _scrubberOpacity;
  late Animation<double> _rippleAnimation;
  
  // Trim state
  late Duration _trimStart;
  late Duration _trimEnd;
  double _startPosition = 0.0;
  double _endPosition = 1.0;
  bool _isDraggingStart = false;
  bool _isDraggingEnd = false;
  bool _isDraggingScrubber = false;
  bool _isPlaying = false;
  
  // Timeline
  final double _timelineHeight = 60.0;
  final double _handleWidth = 20.0;
  final double _thumbnailCount = 10.0;
  List<Widget> _thumbnailFrames = [];
  
  // Playback
  Duration _currentPosition = Duration.zero;
  double _scrubberPosition = 0.0;
  
  // UI State
  bool _showControls = true;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.videoController;
    _trimStart = widget.initialStart;
    _trimEnd = widget.initialEnd;
    
    _initializePositions();
    _initializeAnimations();
    _controller.addListener(_videoListener);
    _generateThumbnailFrames();
    
    // Auto-hide controls after 3 seconds
    _startControlsTimer();
  }
  
  void _initializePositions() {
    final totalDuration = _controller.value.duration;
    if (totalDuration.inMilliseconds > 0) {
      _startPosition = _trimStart.inMilliseconds / totalDuration.inMilliseconds;
      _endPosition = _trimEnd.inMilliseconds / totalDuration.inMilliseconds;
      _scrubberPosition = _startPosition;
    }
  }
  
  void _initializeAnimations() {
    _playPauseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _handleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scrubberController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _handleScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _handleController,
      curve: Curves.elasticOut,
    ));
    
    _playPauseRotation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _playPauseController,
      curve: Curves.easeInOut,
    ));
    
    _scrubberOpacity = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(_scrubberController);
    
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
  }
  
  void _videoListener() {
    if (!mounted) return;
    
    final position = _controller.value.position;
    final totalDuration = _controller.value.duration;
    
    setState(() {
      _currentPosition = position;
      _isPlaying = _controller.value.isPlaying;
      
      if (totalDuration.inMilliseconds > 0 && !_isDraggingScrubber) {
        _scrubberPosition = position.inMilliseconds / totalDuration.inMilliseconds;
      }
    });
    
    // Auto-loop within trimmed area
    if (position >= _trimEnd && _isPlaying) {
      _controller.seekTo(_trimStart);
    }
    
    // Auto-pause if outside trimmed area
    if ((position < _trimStart || position > _trimEnd) && _isPlaying && !_isDraggingScrubber) {
      _controller.pause();
      _controller.seekTo(_trimStart);
    }
  }
  
  void _generateThumbnailFrames() {
    // Generate placeholder thumbnails - in production, extract actual frames
    final frames = <Widget>[];
    for (int i = 0; i < _thumbnailCount; i++) {
      frames.add(
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[700]!,
                Colors.grey[600]!,
                Colors.grey[700]!,
              ],
              stops: [0.0, 0.5, 1.0],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.movie,
              color: Colors.white.withOpacity(0.3),
              size: 16,
            ),
          ),
        ),
      );
    }
    setState(() {
      _thumbnailFrames = frames;
    });
  }
  
  void _startControlsTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showControls && !_isDraggingStart && !_isDraggingEnd && !_isDraggingScrubber) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _playPauseController.dispose();
    _handleController.dispose();
    _scrubberController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
          if (_showControls) {
            _startControlsTimer();
          }
        },
        child: Stack(
          children: [
            // Video preview with enhanced aspect ratio handling
            Center(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: Stack(
                      children: [
                        VideoPlayer(_controller),
                        
                        // Ripple effect on tap
                        AnimatedBuilder(
                          animation: _rippleAnimation,
                          builder: (context, child) {
                            if (_rippleAnimation.value == 0) return const SizedBox.shrink();
                            
                            return Positioned.fill(
                              child: CustomPaint(
                                painter: RipplePainter(
                                  animation: _rippleAnimation,
                                  color: Colors.white.withOpacity(0.3),
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
            
            // Enhanced play/pause overlay
            if (!_isPlaying)
              Center(
                child: GestureDetector(
                  onTap: () {
                    _togglePlayPause();
                    _rippleController.forward().then((_) {
                      _rippleController.reset();
                    });
                  },
                  child: AnimatedBuilder(
                    animation: _playPauseRotation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _playPauseRotation.value * 2 * math.pi,
                        child: Container(
                          width: 80,
                          height: 80,
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
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            
            // Enhanced header with better visibility
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              top: _showControls ? 0 : -100,
              left: 0,
              right: 0,
              child: _buildEnhancedHeader(modernTheme),
            ),
            
            // Enhanced timeline and controls
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              bottom: _showControls ? 0 : -200,
              left: 0,
              right: 0,
              child: _buildEnhancedControls(modernTheme, size),
            ),
            
            // Trim range indicator overlay
            if (_showControls)
              Positioned(
                top: MediaQuery.of(context).padding.top + 100,
                right: 20,
                child: _buildTrimIndicator(modernTheme),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader(ModernThemeExtension modernTheme) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.4),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Enhanced close button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          
          // Enhanced title with subtitle
          Column(
            children: [
              Text(
                'Trim Video',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              Text(
                'Drag handles to adjust',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
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
          
          // Enhanced done button
          GestureDetector(
            onTap: _saveTrim,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    modernTheme.primaryColor!,
                    modernTheme.primaryColor!.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: modernTheme.primaryColor!.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrimIndicator(ModernThemeExtension modernTheme) {
    final trimDuration = _trimEnd - _trimStart;
    final percentage = (trimDuration.inMilliseconds / _controller.value.duration.inMilliseconds * 100);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: modernTheme.primaryColor!.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Selected',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            _formatDuration(trimDuration),
            style: TextStyle(
              color: modernTheme.primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedControls(ModernThemeExtension modernTheme, Size size) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.black.withOpacity(0.6),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          // Current position and duration with enhanced styling
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimeDisplay(_formatDuration(_currentPosition), 'Current'),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        modernTheme.primaryColor!.withOpacity(0.2),
                        modernTheme.primaryColor!.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: modernTheme.primaryColor!.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Trim: ${_formatDuration(_trimEnd - _trimStart)}',
                    style: TextStyle(
                      color: modernTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                
                _buildTimeDisplay(_formatDuration(_controller.value.duration), 'Total'),
              ],
            ),
          ),
          
          // Enhanced timeline with better handles and scrubber
          Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Timeline background with thumbnails
                Container(
                  height: _timelineHeight,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Row(
                      children: _thumbnailFrames.map((frame) {
                        return Expanded(child: frame);
                      }).toList(),
                    ),
                  ),
                ),
                
                // Dimmed areas outside selection
                _buildDimmedArea(0, _startPosition, size.width - 40),
                _buildDimmedArea(_endPosition, 1, size.width - 40),
                
                // Enhanced selection overlay
                Positioned(
                  left: _startPosition * (size.width - 40),
                  right: (1 - _endPosition) * (size.width - 40),
                  top: 30,
                  bottom: 30,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.symmetric(
                        vertical: BorderSide(
                          color: modernTheme.primaryColor!,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Enhanced scrubber
                if (_controller.value.duration.inMilliseconds > 0)
                  AnimatedBuilder(
                    animation: _scrubberOpacity,
                    builder: (context, child) {
                      return Positioned(
                        left: _scrubberPosition * (size.width - 40) - 8,
                        top: 20,
                        bottom: 20,
                        child: GestureDetector(
                          onHorizontalDragStart: (_) => _onScrubberDragStart(),
                          onHorizontalDragUpdate: (details) => 
                              _onScrubberDragUpdate(details, size.width - 40),
                          onHorizontalDragEnd: (_) => _onScrubberDragEnd(),
                          child: Opacity(
                            opacity: _scrubberOpacity.value,
                            child: Container(
                              width: 16,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: modernTheme.primaryColor!,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: modernTheme.primaryColor!,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                
                // Enhanced start handle
                Positioned(
                  left: _startPosition * (size.width - 40) - _handleWidth / 2,
                  top: 20,
                  bottom: 20,
                  child: GestureDetector(
                    onHorizontalDragStart: (_) => _onDragStart(true),
                    onHorizontalDragUpdate: (details) => 
                        _onDragUpdate(details, true, size.width - 40),
                    onHorizontalDragEnd: (_) => _onDragEnd(),
                    child: AnimatedBuilder(
                      animation: _handleScaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isDraggingStart ? _handleScaleAnimation.value : 1.0,
                          child: _buildEnhancedHandle(modernTheme, true),
                        );
                      },
                    ),
                  ),
                ),
                
                // Enhanced end handle
                Positioned(
                  left: _endPosition * (size.width - 40) - _handleWidth / 2,
                  top: 20,
                  bottom: 20,
                  child: GestureDetector(
                    onHorizontalDragStart: (_) => _onDragStart(false),
                    onHorizontalDragUpdate: (details) => 
                        _onDragUpdate(details, false, size.width - 40),
                    onHorizontalDragEnd: (_) => _onDragEnd(),
                    child: AnimatedBuilder(
                      animation: _handleScaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isDraggingEnd ? _handleScaleAnimation.value : 1.0,
                          child: _buildEnhancedHandle(modernTheme, false),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Enhanced quick trim options
          Container(
            height: 50,
            margin: const EdgeInsets.only(top: 20, bottom: 20),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildEnhancedQuickTrimOption('15s', const Duration(seconds: 15), modernTheme),
                _buildEnhancedQuickTrimOption('30s', const Duration(seconds: 30), modernTheme),
                _buildEnhancedQuickTrimOption('1m', const Duration(minutes: 1), modernTheme),
                _buildEnhancedQuickTrimOption('2m', const Duration(minutes: 2), modernTheme),
                _buildEnhancedQuickTrimOption('5m', const Duration(minutes: 5), modernTheme),
                _buildEnhancedQuickTrimOption('Full', _controller.value.duration, modernTheme),
              ],
            ),
          ),
          
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay(String time, String label) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          time,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildDimmedArea(double start, double end, double width) {
    return Positioned(
      left: start * width,
      right: (1 - end) * width,
      top: 30,
      bottom: 30,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _buildEnhancedHandle(ModernThemeExtension modernTheme, bool isStart) {
    return Container(
      width: _handleWidth,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            modernTheme.primaryColor!,
            modernTheme.primaryColor!.withOpacity(0.8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: modernTheme.primaryColor!.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Handle grip indicator
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedQuickTrimOption(String label, Duration duration, ModernThemeExtension modernTheme) {
    final isSelected = (_trimEnd - _trimStart).inMilliseconds == duration.inMilliseconds;
    final isMaxDuration = duration >= _controller.value.duration;
    
    return GestureDetector(
      onTap: () => _applyQuickTrim(duration),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(
            colors: [
              modernTheme.primaryColor!,
              modernTheme.primaryColor!.withOpacity(0.8),
            ],
          ) : null,
          color: isSelected ? null : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? modernTheme.primaryColor! : Colors.white.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (isMaxDuration)
              Text(
                'MAX',
                style: TextStyle(
                  color: isSelected ? Colors.white.withOpacity(0.8) : Colors.white.withOpacity(0.5),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Enhanced interaction methods
  
  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _controller.pause();
      } else {
        // Always start from trim start if we're outside the range
        if (_currentPosition < _trimStart || _currentPosition >= _trimEnd) {
          _controller.seekTo(_trimStart);
        }
        _controller.play();
      }
    });
    
    _playPauseController.forward().then((_) {
      _playPauseController.reverse();
    });
  }
  
  void _onDragStart(bool isStart) {
    setState(() {
      if (isStart) {
        _isDraggingStart = true;
      } else {
        _isDraggingEnd = true;
      }
      _showControls = true;
    });
    _handleController.forward();
    _controller.pause();
    HapticFeedback.mediumImpact();
  }
  
  void _onDragUpdate(DragUpdateDetails details, bool isStart, double width) {
    final totalDuration = _controller.value.duration;
    final dx = details.localPosition.dx.clamp(0.0, width);
    final position = dx / width;
    
    setState(() {
      if (isStart) {
        _startPosition = position;
        _trimStart = Duration(
          milliseconds: (position * totalDuration.inMilliseconds).round(),
        );
        
        // Ensure start doesn't go past end
        if (_trimStart >= _trimEnd - const Duration(seconds: 1)) {
          _trimStart = _trimEnd - const Duration(seconds: 1);
          _startPosition = _trimStart.inMilliseconds / totalDuration.inMilliseconds;
        }
      } else {
        _endPosition = position;
        _trimEnd = Duration(
          milliseconds: (position * totalDuration.inMilliseconds).round(),
        );
        
        // Ensure end doesn't go before start
        if (_trimEnd <= _trimStart + const Duration(seconds: 1)) {
          _trimEnd = _trimStart + const Duration(seconds: 1);
          _endPosition = _trimEnd.inMilliseconds / totalDuration.inMilliseconds;
        }
        
        // Max 5 minutes
        if (_trimEnd - _trimStart > const Duration(minutes: 5)) {
          _trimEnd = _trimStart + const Duration(minutes: 5);
          _endPosition = _trimEnd.inMilliseconds / totalDuration.inMilliseconds;
        }
      }
    });
    
    // Seek to the new position for immediate feedback
    _controller.seekTo(isStart ? _trimStart : _trimEnd);
    HapticFeedback.selectionClick();
  }
  
  void _onDragEnd() {
    setState(() {
      _isDraggingStart = false;
      _isDraggingEnd = false;
    });
    _handleController.reverse();
    HapticFeedback.lightImpact();
    _startControlsTimer();
  }
  
  void _onScrubberDragStart() {
    setState(() {
      _isDraggingScrubber = true;
      _showControls = true;
    });
    _scrubberController.forward();
    _controller.pause();
    HapticFeedback.lightImpact();
  }
  
  void _onScrubberDragUpdate(DragUpdateDetails details, double width) {
    final totalDuration = _controller.value.duration;
    final dx = details.localPosition.dx.clamp(0.0, width);
    final position = dx / width;
    
    // Constrain scrubber to trimmed area
    final constrainedPosition = position.clamp(_startPosition, _endPosition);
    
    setState(() {
      _scrubberPosition = constrainedPosition;
    });
    
    final seekTime = Duration(
      milliseconds: (constrainedPosition * totalDuration.inMilliseconds).round(),
    );
    
    _controller.seekTo(seekTime);
    HapticFeedback.selectionClick();
  }
  
  void _onScrubberDragEnd() {
    setState(() {
      _isDraggingScrubber = false;
    });
    _scrubberController.reverse();
    HapticFeedback.lightImpact();
    _startControlsTimer();
  }
  
  void _applyQuickTrim(Duration duration) {
    final totalDuration = _controller.value.duration;
    final maxDuration = duration > totalDuration ? totalDuration : duration;
    
    setState(() {
      _trimStart = Duration.zero;
      _trimEnd = maxDuration;
      _startPosition = 0.0;
      _endPosition = maxDuration.inMilliseconds / totalDuration.inMilliseconds;
      _scrubberPosition = 0.0;
    });
    
    _controller.seekTo(_trimStart);
    HapticFeedback.mediumImpact();
  }
  
  void _saveTrim() {
    HapticFeedback.heavyImpact();
    Navigator.of(context).pop(
      VideoEditResult(
        startTime: _trimStart,
        endTime: _trimEnd,
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final centiseconds = (duration.inMilliseconds % 1000) ~/ 10;
    
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}.${centiseconds.toString().padLeft(2, '0')}';
    } else {
      return '${seconds}.${centiseconds.toString().padLeft(2, '0')}s';
    }
  }
}

// Custom painter for ripple effect
class RipplePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  
  RipplePainter({
    required this.animation,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) / 2;
    final radius = maxRadius * animation.value;
    
    final paint = Paint()
      ..color = color.withOpacity(1.0 - animation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    canvas.drawCircle(center, radius, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
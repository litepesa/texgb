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
  late Animation<double> _handleAnimation;
  
  // Trim state
  late Duration _trimStart;
  late Duration _trimEnd;
  double _startPosition = 0.0;
  double _endPosition = 1.0;
  bool _isDraggingStart = false;
  bool _isDraggingEnd = false;
  bool _isPlaying = false;
  
  // Timeline
  final double _timelineHeight = 80.0;
  final double _handleWidth = 40.0;
  List<Image> _thumbnails = [];
  
  // Playback
  Duration _currentPosition = Duration.zero;
  
  @override
  void initState() {
    super.initState();
    _controller = widget.videoController;
    _trimStart = widget.initialStart;
    _trimEnd = widget.initialEnd;
    
    _initializePositions();
    _initializeAnimations();
    _controller.addListener(_videoListener);
    _generateThumbnails();
  }
  
  void _initializePositions() {
    final totalDuration = _controller.value.duration;
    if (totalDuration.inMilliseconds > 0) {
      _startPosition = _trimStart.inMilliseconds / totalDuration.inMilliseconds;
      _endPosition = _trimEnd.inMilliseconds / totalDuration.inMilliseconds;
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
    
    _handleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _handleController,
      curve: Curves.easeOut,
    ));
  }
  
  void _videoListener() {
    if (!mounted) return;
    
    final position = _controller.value.position;
    setState(() {
      _currentPosition = position;
      _isPlaying = _controller.value.isPlaying;
    });
    
    // Loop within trimmed area
    if (position >= _trimEnd) {
      _controller.seekTo(_trimStart);
      _controller.play();
    }
  }
  
  Future<void> _generateThumbnails() async {
    // This is where you would generate video thumbnails
    // For now, we'll use placeholder
  }
  
  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _playPauseController.dispose();
    _handleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video preview
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header
                _buildHeader(modernTheme),
                
                // Video player
                Expanded(
                  child: GestureDetector(
                    onTap: _togglePlayPause,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                        
                        // Play/pause overlay
                        AnimatedOpacity(
                          opacity: _isPlaying ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Timeline and controls
                Container(
                  color: modernTheme.backgroundColor,
                  padding: const EdgeInsets.only(bottom: 34),
                  child: Column(
                    children: [
                      // Current position and duration
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_currentPosition),
                              style: TextStyle(
                                color: modernTheme.textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: modernTheme.primaryColor!.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Selected: ${_formatDuration(_trimEnd - _trimStart)}',
                                style: TextStyle(
                                  color: modernTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              _formatDuration(_controller.value.duration),
                              style: TextStyle(
                                color: modernTheme.textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Timeline
                      Container(
                        height: _timelineHeight + 40,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Timeline background
                            Container(
                              height: _timelineHeight,
                              decoration: BoxDecoration(
                                color: modernTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: modernTheme.borderColor ?? Colors.grey.withOpacity(0.2),
                                ),
                              ),
                              child: _buildTimelineThumbnails(),
                            ),
                            
                            // Selected area overlay
                            Positioned(
                              left: _startPosition * (size.width - 40),
                              right: (1 - _endPosition) * (size.width - 40),
                              top: 0,
                              bottom: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: modernTheme.primaryColor!.withOpacity(0.3),
                                  border: Border(
                                    left: BorderSide(
                                      color: modernTheme.primaryColor!,
                                      width: 3,
                                    ),
                                    right: BorderSide(
                                      color: modernTheme.primaryColor!,
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            // Current position indicator
                            if (_controller.value.duration.inMilliseconds > 0)
                              Positioned(
                                left: (_currentPosition.inMilliseconds / 
                                       _controller.value.duration.inMilliseconds) * 
                                       (size.width - 40) - 2,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            
                            // Start handle
                            Positioned(
                              left: _startPosition * (size.width - 40) - _handleWidth / 2,
                              top: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onHorizontalDragStart: (_) => _onDragStart(true),
                                onHorizontalDragUpdate: (details) => 
                                    _onDragUpdate(details, true, size.width - 40),
                                onHorizontalDragEnd: (_) => _onDragEnd(),
                                child: AnimatedBuilder(
                                  animation: _handleAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _isDraggingStart ? _handleAnimation.value : 1.0,
                                      child: _buildHandle(modernTheme, true),
                                    );
                                  },
                                ),
                              ),
                            ),
                            
                            // End handle
                            Positioned(
                              left: _endPosition * (size.width - 40) - _handleWidth / 2,
                              top: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onHorizontalDragStart: (_) => _onDragStart(false),
                                onHorizontalDragUpdate: (details) => 
                                    _onDragUpdate(details, false, size.width - 40),
                                onHorizontalDragEnd: (_) => _onDragEnd(),
                                child: AnimatedBuilder(
                                  animation: _handleAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _isDraggingEnd ? _handleAnimation.value : 1.0,
                                      child: _buildHandle(modernTheme, false),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Quick trim options
                      Container(
                        height: 60,
                        margin: const EdgeInsets.only(top: 20),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            _buildQuickTrimOption('15s', const Duration(seconds: 15), modernTheme),
                            _buildQuickTrimOption('30s', const Duration(seconds: 30), modernTheme),
                            _buildQuickTrimOption('1m', const Duration(minutes: 1), modernTheme),
                            _buildQuickTrimOption('2m', const Duration(minutes: 2), modernTheme),
                            _buildQuickTrimOption('5m', const Duration(minutes: 5), modernTheme),
                            _buildQuickTrimOption('Full', _controller.value.duration, modernTheme),
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
    );
  }

  Widget _buildHeader(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
              ),
            ),
          ),
          
          Text(
            'Trim Video',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          GestureDetector(
            onTap: _saveTrim,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: modernTheme.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle(ModernThemeExtension modernTheme, bool isStart) {
    return Container(
      width: _handleWidth,
      height: _timelineHeight,
      decoration: BoxDecoration(
        color: modernTheme.primaryColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: modernTheme.primaryColor!.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 3,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineThumbnails() {
    // In a real implementation, you would generate thumbnails from the video
    // For now, we'll use a gradient placeholder
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey[800]!,
              Colors.grey[700]!,
              Colors.grey[800]!,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTrimOption(String label, Duration duration, ModernThemeExtension modernTheme) {
    final isSelected = (_trimEnd - _trimStart) == duration;
    
    return GestureDetector(
      onTap: () => _applyQuickTrim(duration),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? modernTheme.primaryColor : modernTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? modernTheme.primaryColor! : modernTheme.borderColor ?? Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : modernTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Interaction methods
  
  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _controller.pause();
      } else {
        if (_currentPosition >= _trimEnd) {
          _controller.seekTo(_trimStart);
        }
        _controller.play();
      }
    });
  }
  
  void _onDragStart(bool isStart) {
    setState(() {
      if (isStart) {
        _isDraggingStart = true;
      } else {
        _isDraggingEnd = true;
      }
    });
    _handleController.forward();
    _controller.pause();
    HapticFeedback.lightImpact();
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
    
    // Seek to the new position
    _controller.seekTo(isStart ? _trimStart : _trimEnd);
  }
  
  void _onDragEnd() {
    setState(() {
      _isDraggingStart = false;
      _isDraggingEnd = false;
    });
    _handleController.reverse();
    HapticFeedback.lightImpact();
  }
  
  void _applyQuickTrim(Duration duration) {
    final totalDuration = _controller.value.duration;
    final maxDuration = duration > totalDuration ? totalDuration : duration;
    
    setState(() {
      _trimStart = Duration.zero;
      _trimEnd = maxDuration;
      _startPosition = 0.0;
      _endPosition = maxDuration.inMilliseconds / totalDuration.inMilliseconds;
    });
    
    _controller.seekTo(_trimStart);
    HapticFeedback.lightImpact();
  }
  
  void _saveTrim() {
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
    final milliseconds = (duration.inMilliseconds % 1000) ~/ 10;
    return '$minutes:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(2, '0')}';
  }
}
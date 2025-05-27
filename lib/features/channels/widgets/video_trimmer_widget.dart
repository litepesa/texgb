// lib/features/channels/widgets/video_trimmer_widget.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class VideoTrimmerWidget extends StatefulWidget {
  final File videoFile;
  final Duration videoDuration;
  final Function(Duration start, Duration end) onTrimComplete;
  final VoidCallback onCancel;

  const VideoTrimmerWidget({
    Key? key,
    required this.videoFile,
    required this.videoDuration,
    required this.onTrimComplete,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<VideoTrimmerWidget> createState() => _VideoTrimmerWidgetState();
}

class _VideoTrimmerWidgetState extends State<VideoTrimmerWidget>
    with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  // Trimming state
  Duration _startTime = Duration.zero;
  Duration _endTime = const Duration(minutes: 5);
  double _currentPosition = 0.0;
  bool _isPlaying = false;
  bool _isDraggingStart = false;
  bool _isDraggingEnd = false;
  bool _isDraggingPosition = false;
  
  // UI state
  final double _timelineHeight = 60.0;
  final double _handleWidth = 12.0;
  List<Uint8List> _thumbnails = [];
  
  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _initializeAnimations();
    
    // Set initial end time to min of video duration or 5 minutes
    _endTime = widget.videoDuration > const Duration(minutes: 5)
        ? const Duration(minutes: 5)
        : widget.videoDuration;
  }

  void _initializeVideo() async {
    _controller = VideoPlayerController.file(widget.videoFile);
    await _controller.initialize();
    _controller.addListener(_videoListener);
    setState(() {});
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _videoListener() {
    if (!_controller.value.isInitialized) return;
    
    final position = _controller.value.position;
    final duration = _controller.value.duration;
    
    if (duration.inMilliseconds > 0) {
      setState(() {
        _currentPosition = position.inMilliseconds / duration.inMilliseconds;
      });
    }
    
    // Loop within trimmed area
    if (position >= _endTime) {
      _controller.seekTo(_startTime);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: modernTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: modernTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title and duration
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trim Video',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 20,
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
                  _formatDuration(_endTime - _startTime),
                  style: TextStyle(
                    color: modernTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Video preview
          if (_controller.value.isInitialized)
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller),
                    
                    // Play/pause overlay
                    GestureDetector(
                      onTap: _togglePlayback,
                      child: AnimatedOpacity(
                        opacity: _isPlaying ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Timeline
          SizedBox(
            height: _timelineHeight + 40,
            child: Stack(
              children: [
                // Timeline background
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: _timelineHeight,
                    decoration: BoxDecoration(
                      color: modernTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: modernTheme.borderColor ?? Colors.grey.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
                
                // Selected area
                Positioned(
                  top: 20,
                  left: _getStartPosition(screenWidth - 40),
                  right: screenWidth - 40 - _getEndPosition(screenWidth - 40),
                  child: Container(
                    height: _timelineHeight,
                    decoration: BoxDecoration(
                      color: modernTheme.primaryColor!.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: modernTheme.primaryColor!,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                
                // Current position indicator
                Positioned(
                  top: 15,
                  left: _getCurrentPosition(screenWidth - 40) - 2,
                  child: Container(
                    width: 4,
                    height: _timelineHeight + 10,
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
                  top: 10,
                  left: _getStartPosition(screenWidth - 40) - _handleWidth / 2,
                  child: GestureDetector(
                    onHorizontalDragStart: (_) => _onDragStart(true),
                    onHorizontalDragUpdate: (details) => _onDragUpdate(details, true, screenWidth - 40),
                    onHorizontalDragEnd: (_) => _onDragEnd(),
                    child: AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isDraggingStart ? _scaleAnimation.value : 1.0,
                          child: _buildHandle(modernTheme, true),
                        );
                      },
                    ),
                  ),
                ),
                
                // End handle
                Positioned(
                  top: 10,
                  left: _getEndPosition(screenWidth - 40) - _handleWidth / 2,
                  child: GestureDetector(
                    onHorizontalDragStart: (_) => _onDragStart(false),
                    onHorizontalDragUpdate: (details) => _onDragUpdate(details, false, screenWidth - 40),
                    onHorizontalDragEnd: (_) => _onDragEnd(),
                    child: AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isDraggingEnd ? _scaleAnimation.value : 1.0,
                          child: _buildHandle(modernTheme, false),
                        );
                      },
                    ),
                  ),
                ),
                
                // Time labels
                Positioned(
                  top: 0,
                  left: _getStartPosition(screenWidth - 40) - 20,
                  child: Text(
                    _formatTime(_startTime),
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: _getEndPosition(screenWidth - 40) - 20,
                  child: Text(
                    _formatTime(_endTime),
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quick duration presets
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPresetChip('15s', const Duration(seconds: 15), modernTheme),
                const SizedBox(width: 8),
                _buildPresetChip('30s', const Duration(seconds: 30), modernTheme),
                const SizedBox(width: 8),
                _buildPresetChip('60s', const Duration(seconds: 60), modernTheme),
                const SizedBox(width: 8),
                _buildPresetChip('2min', const Duration(minutes: 2), modernTheme),
                const SizedBox(width: 8),
                _buildPresetChip('5min', const Duration(minutes: 5), modernTheme),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: modernTheme.primaryColor!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: modernTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onTrimComplete(_startTime, _endTime),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: modernTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Trim',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildHandle(ModernThemeExtension modernTheme, bool isStart) {
    return Container(
      width: _handleWidth,
      height: _timelineHeight + 20,
      decoration: BoxDecoration(
        color: modernTheme.primaryColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: modernTheme.primaryColor!.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 2,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, Duration duration, ModernThemeExtension modernTheme) {
    final isSelected = (_endTime - _startTime) == duration;
    
    return GestureDetector(
      onTap: () => _applyPreset(duration),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? modernTheme.primaryColor
              : modernTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? modernTheme.primaryColor!
                : modernTheme.borderColor ?? Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : modernTheme.textSecondaryColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Helper methods
  
  double _getStartPosition(double width) {
    return (_startTime.inMilliseconds / widget.videoDuration.inMilliseconds) * width;
  }

  double _getEndPosition(double width) {
    return (_endTime.inMilliseconds / widget.videoDuration.inMilliseconds) * width;
  }

  double _getCurrentPosition(double width) {
    return _currentPosition * width;
  }

  void _onDragStart(bool isStart) {
    setState(() {
      if (isStart) {
        _isDraggingStart = true;
      } else {
        _isDraggingEnd = true;
      }
    });
    _animationController.forward();
    _controller.pause();
  }

  void _onDragUpdate(DragUpdateDetails details, bool isStart, double width) {
    final position = details.localPosition.dx / width;
    final duration = Duration(
      milliseconds: (position * widget.videoDuration.inMilliseconds).round(),
    );
    
    setState(() {
      if (isStart) {
        // Don't allow start to go past end
        if (duration < _endTime - const Duration(seconds: 1)) {
          _startTime = duration;
          _controller.seekTo(_startTime);
        }
      } else {
        // Don't allow end to go before start
        if (duration > _startTime + const Duration(seconds: 1) &&
            duration <= const Duration(minutes: 5)) {
          _endTime = duration;
        }
      }
    });
  }

  void _onDragEnd() {
    setState(() {
      _isDraggingStart = false;
      _isDraggingEnd = false;
    });
    _animationController.reverse();
  }

  void _togglePlayback() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        // Start from beginning of trim if at end
        if (_controller.value.position >= _endTime) {
          _controller.seekTo(_startTime);
        }
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  void _applyPreset(Duration duration) {
    setState(() {
      _startTime = Duration.zero;
      _endTime = duration > widget.videoDuration ? widget.videoDuration : duration;
    });
    _controller.seekTo(_startTime);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
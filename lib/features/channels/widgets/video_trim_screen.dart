import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:textgb/features/channels/screens/create_post_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:ffmpeg_kit_flutter_new_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_gpl/return_code.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as path;

import '../../../shared/theme/theme_extensions.dart';

// Manual Video Trimming Screen
class VideoTrimScreen extends StatefulWidget {
  final File videoFile;
  final VideoInfo videoInfo;
  final Function(File) onTrimComplete;

  const VideoTrimScreen({
    super.key,
    required this.videoFile,
    required this.videoInfo,
    required this.onTrimComplete,
  });

  @override
  State<VideoTrimScreen> createState() => _VideoTrimScreenState();
}

class _VideoTrimScreenState extends State<VideoTrimScreen> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isTrimming = false;
  double _trimmingProgress = 0.0;
  
  // Cache manager for trimmed files
  static final CacheManager _cacheManager = CacheManager(
    Config(
      'trim_cache',
      stalePeriod: const Duration(days: 3),
      maxNrOfCacheObjects: 10,
    ),
  );
  
  // Enhanced trim controls with precise seconds
  final TextEditingController _startMinController = TextEditingController(text: '0');
  final TextEditingController _startSecController = TextEditingController(text: '00');
  final TextEditingController _endMinController = TextEditingController(text: '5');
  final TextEditingController _endSecController = TextEditingController(text: '00');
  
  Duration _startTime = Duration.zero;
  Duration _endTime = const Duration(minutes: 5);
  Duration _currentPosition = Duration.zero;
  Timer? _previewTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _updateEndTimeDefault();
  }

  void _updateEndTimeDefault() {
    // Set end time to minimum of video duration or 5 minutes
    final maxDuration = widget.videoInfo.duration;
    final fiveMinutes = const Duration(minutes: 5);
    
    // For videos under 5 minutes, default to full duration
    // For videos over 5 minutes, default to 5 minutes
    if (maxDuration <= fiveMinutes) {
      _endTime = maxDuration;
      final endMinutes = maxDuration.inMinutes;
      final endSeconds = maxDuration.inSeconds % 60;
      _endMinController.text = endMinutes.toString();
      _endSecController.text = endSeconds.toString().padLeft(2, '0');
    } else {
      // Keep the 5-minute default for longer videos
      _endTime = fiveMinutes;
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.file(widget.videoFile);
      await _videoController!.initialize();
      
      _videoController!.addListener(() {
        if (mounted) {
          setState(() {
            _currentPosition = _videoController!.value.position;
          });
        }
      });
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _startMinController.dispose();
    _startSecController.dispose();
    _endMinController.dispose();
    _endSecController.dispose();
    _previewTimer?.cancel();
    super.dispose();
  }

  void _updateStartTime() {
    final minutes = int.tryParse(_startMinController.text) ?? 0;
    final seconds = int.tryParse(_startSecController.text) ?? 0;
    
    // Ensure seconds are within valid range (0-59)
    final validSeconds = seconds.clamp(0, 59);
    if (seconds != validSeconds) {
      _startSecController.text = validSeconds.toString().padLeft(2, '0');
    }
    
    final newStartTime = Duration(minutes: minutes, seconds: validSeconds);
    
    // Ensure start time doesn't exceed video duration
    if (newStartTime >= widget.videoInfo.duration) {
      _startTime = widget.videoInfo.duration - const Duration(seconds: 1);
      _startMinController.text = _startTime.inMinutes.toString();
      _startSecController.text = (_startTime.inSeconds % 60).toString().padLeft(2, '0');
    } else {
      _startTime = newStartTime;
    }
    
    // Only adjust end time if it's now before the new start time
    if (_endTime <= _startTime) {
      _endTime = _startTime + const Duration(seconds: 1);
      // Make sure we don't exceed video duration
      if (_endTime > widget.videoInfo.duration) {
        _endTime = widget.videoInfo.duration;
      }
      _endMinController.text = _endTime.inMinutes.toString();
      _endSecController.text = (_endTime.inSeconds % 60).toString().padLeft(2, '0');
    }
    
    setState(() {});
  }

  void _updateEndTime() {
    final minutes = int.tryParse(_endMinController.text) ?? 0;
    final seconds = int.tryParse(_endSecController.text) ?? 0;
    
    // Ensure seconds are within valid range (0-59)
    final validSeconds = seconds.clamp(0, 59);
    if (seconds != validSeconds) {
      _endSecController.text = validSeconds.toString().padLeft(2, '0');
    }
    
    final newEndTime = Duration(minutes: minutes, seconds: validSeconds);
    
    // Check if the new end time is valid
    if (newEndTime > widget.videoInfo.duration) {
      // If exceeds video duration, set to video duration
      _endTime = widget.videoInfo.duration;
      _endMinController.text = _endTime.inMinutes.toString();
      _endSecController.text = (_endTime.inSeconds % 60).toString().padLeft(2, '0');
    } else if (newEndTime <= _startTime) {
      // If end time is before or equal to start time, set it to start time + 1 second
      _endTime = _startTime + const Duration(seconds: 1);
      // Make sure we don't exceed video duration
      if (_endTime > widget.videoInfo.duration) {
        _endTime = widget.videoInfo.duration;
      }
      _endMinController.text = _endTime.inMinutes.toString();
      _endSecController.text = (_endTime.inSeconds % 60).toString().padLeft(2, '0');
    } else {
      // Valid end time, use it
      _endTime = newEndTime;
    }
    
    setState(() {});
  }

  void _seekToStart() {
    _videoController?.seekTo(_startTime);
  }

  void _seekToEnd() {
    _videoController?.seekTo(_endTime);
  }

  void _playPause() {
    if (_videoController == null) return;
    
    setState(() {
      if (_isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  void _previewTrimmedSection() {
    if (_videoController == null) return;
    
    _previewTimer?.cancel(); // Cancel any existing timer
    
    _videoController!.seekTo(_startTime);
    _videoController!.play();
    setState(() => _isPlaying = true);
    
    // Auto-pause when reaching end time with more precise timing
    _previewTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final currentPos = _videoController!.value.position;
      if (currentPos >= _endTime || !_isPlaying) {
        timer.cancel();
        _videoController!.pause();
        setState(() => _isPlaying = false);
      }
    });
  }

  Future<void> _trimVideo() async {
    if (_isTrimming) return;
    
    setState(() {
      _isTrimming = true;
      _trimmingProgress = 0.0;
    });
    
    try {
      // Create unique filename with timestamp and trim info
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = path.extension(widget.videoFile.path);
      final startSeconds = _startTime.inSeconds;
      final endSeconds = _endTime.inSeconds;
      final trimmedFileName = 'manual_trim_${startSeconds}_${endSeconds}_$timestamp$fileExtension';
      
      // Use cache directory for better file management
      final tempDir = Directory.systemTemp;
      final trimmedPath = path.join(tempDir.path, trimmedFileName);
      
      final startSecondsDbl = _startTime.inSeconds.toDouble();
      final durationSecondsDbl = (_endTime - _startTime).inSeconds.toDouble();
      
      // FFmpeg command for precise trimming
      final command = '-y -i "${widget.videoFile.path}" '
          '-ss $startSecondsDbl '                     // Start time in seconds
          '-t $durationSecondsDbl '                   // Duration in seconds
          '-c:v libx264 '                             // Re-encode video
          '-c:a aac '                                 // Re-encode audio
          '-avoid_negative_ts make_zero '             // Clean timestamps
          '-movflags +faststart '                     // Web optimization
          '"$trimmedPath"';
      
      print('DEBUG: Manual trim command: $command');
      
      // Simulate progress updates during trimming
      final progressTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
        if (mounted && _isTrimming) {
          setState(() {
            _trimmingProgress = (_trimmingProgress + 0.1).clamp(0.0, 0.9);
          });
        } else {
          timer.cancel();
        }
      });
      
      final session = await FFmpegKit.execute(command);
      progressTimer.cancel();
      
      final returnCode = await session.getReturnCode();
      final logs = await session.getLogsAsString();
      
      if (ReturnCode.isSuccess(returnCode)) {
        setState(() => _trimmingProgress = 1.0);
        
        final trimmedFile = File(trimmedPath);
        if (await trimmedFile.exists()) {
          print('DEBUG: Manual trim successful');
          
          // Cache the trimmed file for efficient access
          final cachedFile = await _cacheVideoFile(trimmedFile);
          
          // Return the cached file
          widget.onTrimComplete(cachedFile);
        } else {
          _showError('Failed to create trimmed video');
        }
      } else {
        print('DEBUG: Manual trim failed - $logs');
        _showError('Failed to trim video. Please try again.');
      }
    } catch (e) {
      print('DEBUG: Manual trim error: $e');
      _showError('Error trimming video: ${e.toString()}');
    } finally {
      setState(() {
        _isTrimming = false;
        _trimmingProgress = 0.0;
      });
    }
  }

  // Cache video file using Flutter Cache Manager
  Future<File> _cacheVideoFile(File videoFile) async {
    try {
      print('DEBUG: Caching trimmed video file');
      
      // Generate a unique key for the trimmed video
      final fileKey = 'trimmed_video_${DateTime.now().millisecondsSinceEpoch}_${path.basename(videoFile.path)}';
      
      // Read the video file bytes
      final videoBytes = await videoFile.readAsBytes();
      
      // Store in cache with proper extension
      final cachedFile = await _cacheManager.putFile(
        fileKey,
        videoBytes,
        fileExtension: path.extension(videoFile.path),
      );
      
      print('DEBUG: Trimmed video cached successfully: ${cachedFile.path}');
      return cachedFile;
    } catch (e) {
      print('DEBUG: Caching failed, using original trimmed file: $e');
      return videoFile; // Fallback to original trimmed file
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: modernTheme.appBarColor,
        elevation: 0,
        title: Text(
          'Trim Video',
          style: TextStyle(
            color: modernTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: modernTheme.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isTrimming ? null : _trimVideo,
            child: Text(
              _isTrimming ? 'Trimming...' : 'Done',
              style: TextStyle(
                color: _isTrimming ? modernTheme.textSecondaryColor : modernTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: !_isInitialized
          ? Center(
              child: CircularProgressIndicator(
                color: modernTheme.primaryColor,
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Video Player
                  Container(
                    height: MediaQuery.of(context).size.height * 0.45,
                    width: double.infinity,
                    color: Colors.black,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                        
                        // Play/Pause Button
                        GestureDetector(
                          onTap: _playPause,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                        
                        // Enhanced trim indicators with better visibility
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: Text(
                              'Start: ${_formatDuration(_startTime)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: Text(
                              'End: ${_formatDuration(_endTime)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Progress bar for trimming
                  if (_isTrimming)
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: modernTheme.surfaceColor,
                      child: Column(
                        children: [
                          Text(
                            'Trimming video...',
                            style: TextStyle(
                              color: modernTheme.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _trimmingProgress,
                            backgroundColor: modernTheme.borderColor,
                            valueColor: AlwaysStoppedAnimation<Color>(modernTheme.primaryColor!),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(_trimmingProgress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: modernTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Controls
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: modernTheme.surfaceColor,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Current position
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: modernTheme.surfaceVariantColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Current: ${_formatDuration(_currentPosition)} / ${_formatDuration(widget.videoInfo.duration)}',
                            style: TextStyle(
                              color: modernTheme.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Enhanced Start Time Controls
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: modernTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Time',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 60,
                                    child: TextField(
                                      controller: _startMinController,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                        color: modernTheme.textColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Min',
                                        labelStyle: TextStyle(color: modernTheme.textSecondaryColor),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(color: modernTheme.borderColor!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.green),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                        filled: true,
                                        fillColor: modernTheme.backgroundColor,
                                      ),
                                      onChanged: (_) => _updateStartTime(),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      ':',
                                      style: TextStyle(
                                        color: modernTheme.textColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: TextField(
                                      controller: _startSecController,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                        color: modernTheme.textColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Sec',
                                        labelStyle: TextStyle(color: modernTheme.textSecondaryColor),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(color: modernTheme.borderColor!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.green),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                        filled: true,
                                        fillColor: modernTheme.backgroundColor,
                                      ),
                                      onChanged: (_) => _updateStartTime(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _seekToStart,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Go to Start'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Enhanced End Time Controls
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: modernTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'End Time',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 60,
                                    child: TextField(
                                      controller: _endMinController,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                        color: modernTheme.textColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Min',
                                        labelStyle: TextStyle(color: modernTheme.textSecondaryColor),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(color: modernTheme.borderColor!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.red),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                        filled: true,
                                        fillColor: modernTheme.backgroundColor,
                                      ),
                                      onChanged: (_) => _updateEndTime(),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      ':',
                                      style: TextStyle(
                                        color: modernTheme.textColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: TextField(
                                      controller: _endSecController,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                        color: modernTheme.textColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Sec',
                                        labelStyle: TextStyle(color: modernTheme.textSecondaryColor),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(color: modernTheme.borderColor!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.red),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                        filled: true,
                                        fillColor: modernTheme.backgroundColor,
                                      ),
                                      onChanged: (_) => _updateEndTime(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _seekToEnd,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Go to End'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Trim info and preview section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: modernTheme.primaryColor!.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: modernTheme.primaryColor!.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Duration info
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Trimmed Duration:',
                                    style: TextStyle(
                                      color: modernTheme.textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: modernTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _formatDuration(_endTime - _startTime),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Preview button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isTrimming ? null : _previewTrimmedSection,
                                  icon: Icon(
                                    Icons.preview,
                                    size: 20,
                                    color: _isTrimming ? modernTheme.textSecondaryColor : Colors.white,
                                  ),
                                  label: Text(
                                    'Preview Trimmed Section',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _isTrimming ? modernTheme.textSecondaryColor : Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isTrimming 
                                        ? modernTheme.borderColor 
                                        : modernTheme.primaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Add some bottom padding to ensure content is visible
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
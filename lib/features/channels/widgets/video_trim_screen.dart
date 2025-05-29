import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:textgb/features/channels/screens/create_post_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as path;

// Manual Video Trimming Screen
class VideoTrimScreen extends StatefulWidget {
  final File videoFile;
  final VideoInfo videoInfo;
  final Function(File) onTrimComplete;

  const VideoTrimScreen({
    Key? key,
    required this.videoFile,
    required this.videoInfo,
    required this.onTrimComplete,
  }) : super(key: key);

  @override
  State<VideoTrimScreen> createState() => _VideoTrimScreenState();
}

class _VideoTrimScreenState extends State<VideoTrimScreen> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isTrimming = false;
  
  // Cache manager for trimmed files
  static final CacheManager _cacheManager = CacheManager(
    Config(
      'trim_cache',
      stalePeriod: const Duration(days: 3),
      maxNrOfCacheObjects: 10,
    ),
  );
  
  // Trim controls
  final TextEditingController _startMinController = TextEditingController(text: '0');
  final TextEditingController _startSecController = TextEditingController(text: '00');
  final TextEditingController _endMinController = TextEditingController(text: '5');
  final TextEditingController _endSecController = TextEditingController(text: '00');
  
  Duration _startTime = Duration.zero;
  Duration _endTime = const Duration(minutes: 5);
  Duration _currentPosition = Duration.zero;

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
    super.dispose();
  }

  void _updateStartTime() {
    final minutes = int.tryParse(_startMinController.text) ?? 0;
    final seconds = int.tryParse(_startSecController.text) ?? 0;
    _startTime = Duration(minutes: minutes, seconds: seconds);
    
    // Ensure start time doesn't exceed video duration
    if (_startTime >= widget.videoInfo.duration) {
      _startTime = widget.videoInfo.duration - const Duration(seconds: 1);
      _startMinController.text = _startTime.inMinutes.toString();
      _startSecController.text = (_startTime.inSeconds % 60).toString().padLeft(2, '0');
    }
    
    // Ensure start time is before end time
    if (_startTime >= _endTime) {
      _endTime = _startTime + const Duration(seconds: 30);
      _endMinController.text = _endTime.inMinutes.toString();
      _endSecController.text = (_endTime.inSeconds % 60).toString().padLeft(2, '0');
    }
    
    setState(() {});
  }

  void _updateEndTime() {
    final minutes = int.tryParse(_endMinController.text) ?? 0;
    final seconds = int.tryParse(_endSecController.text) ?? 0;
    _endTime = Duration(minutes: minutes, seconds: seconds);
    
    // Ensure end time doesn't exceed video duration
    if (_endTime > widget.videoInfo.duration) {
      _endTime = widget.videoInfo.duration;
      _endMinController.text = _endTime.inMinutes.toString();
      _endSecController.text = (_endTime.inSeconds % 60).toString().padLeft(2, '0');
    }
    
    // Ensure end time is after start time
    if (_endTime <= _startTime) {
      _endTime = _startTime + const Duration(seconds: 30);
      _endMinController.text = _endTime.inMinutes.toString();
      _endSecController.text = (_endTime.inSeconds % 60).toString().padLeft(2, '0');
    }
    
    // Ensure trimmed duration doesn't exceed 5 minutes
    final trimDuration = _endTime - _startTime;
    if (trimDuration > const Duration(minutes: 5)) {
      _endTime = _startTime + const Duration(minutes: 5);
      _endMinController.text = _endTime.inMinutes.toString();
      _endSecController.text = (_endTime.inSeconds % 60).toString().padLeft(2, '0');
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
    
    _videoController!.seekTo(_startTime);
    _videoController!.play();
    setState(() => _isPlaying = true);
    
    // Auto-pause when reaching end time
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_videoController!.value.position >= _endTime || !_isPlaying) {
        timer.cancel();
        _videoController!.pause();
        setState(() => _isPlaying = false);
      }
    });
  }

  Future<void> _trimVideo() async {
    if (_isTrimming) return;
    
    setState(() => _isTrimming = true);
    
    try {
      // Create unique filename with timestamp and trim info
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = path.extension(widget.videoFile.path);
      final startSeconds = _startTime.inSeconds;
      final endSeconds = _endTime.inSeconds;
      final trimmedFileName = 'manual_trim_${startSeconds}_${endSeconds}_${timestamp}${fileExtension}';
      
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
      
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      final logs = await session.getLogsAsString();
      
      if (ReturnCode.isSuccess(returnCode)) {
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
      setState(() => _isTrimming = false);
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
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Trim Video', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isTrimming ? null : _trimVideo,
            child: Text(
              _isTrimming ? 'Trimming...' : 'Done',
              style: TextStyle(
                color: _isTrimming ? Colors.grey : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Video Player
                  Container(
                    height: MediaQuery.of(context).size.height * 0.5, // 50% of screen height
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
                        
                        // Trim indicators
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Start: ${_formatDuration(_startTime)}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                        
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'End: ${_formatDuration(_endTime)}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Controls
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey.shade900,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Current position
                        Text(
                          'Current: ${_formatDuration(_currentPosition)} / ${_formatDuration(widget.videoInfo.duration)}',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Start Time Controls
                        Row(
                          children: [
                            const SizedBox(width: 60, child: Text('Start:', style: TextStyle(color: Colors.white))),
                            SizedBox(
                              width: 45,
                              child: TextField(
                                controller: _startMinController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: 'Min',
                                  hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  isDense: true,
                                ),
                                onChanged: (_) => _updateStartTime(),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Text(':', style: TextStyle(color: Colors.white)),
                            ),
                            SizedBox(
                              width: 50,
                              child: TextField(
                                controller: _startSecController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: 'Sec',
                                  hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  isDense: true,
                                ),
                                onChanged: (_) => _updateStartTime(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _seekToStart,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                child: const Text('Go', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // End Time Controls
                        Row(
                          children: [
                            const SizedBox(width: 60, child: Text('End:', style: TextStyle(color: Colors.white))),
                            SizedBox(
                              width: 45,
                              child: TextField(
                                controller: _endMinController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: 'Min',
                                  hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  isDense: true,
                                ),
                                onChanged: (_) => _updateEndTime(),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Text(':', style: TextStyle(color: Colors.white)),
                            ),
                            SizedBox(
                              width: 50,
                              child: TextField(
                                controller: _endSecController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: 'Sec',
                                  hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  isDense: true,
                                ),
                                onChanged: (_) => _updateEndTime(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _seekToEnd,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                child: const Text('Go', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Trim info and preview
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Trimmed Duration: ${_formatDuration(_endTime - _startTime)}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _previewTrimmedSection,
                                  icon: const Icon(Icons.preview, size: 16),
                                  label: const Text('Preview Trimmed Section', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
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
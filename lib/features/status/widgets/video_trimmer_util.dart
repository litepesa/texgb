// lib/features/status/utils/video_trimmer_util.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:ffmpeg_kit_flutter_new_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class VideoTrimmerUtil {
  static Future<String?> trimVideo({
    required String inputPath,
    required Duration startTime,
    required Duration endTime,
    String? outputPath,
    Function(double)? onProgress,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basenameWithoutExtension(inputPath);
      final extension = path.extension(inputPath);
      
      outputPath ??= path.join(
        tempDir.path,
        '${fileName}_trimmed_${DateTime.now().millisecondsSinceEpoch}$extension',
      );

      final startSeconds = startTime.inMilliseconds / 1000;
      final durationSeconds = (endTime.inMilliseconds - startTime.inMilliseconds) / 1000;

      final command = '-i "$inputPath" -ss $startSeconds -t $durationSeconds -c copy -avoid_negative_ts make_zero "$outputPath"';
      
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      
      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      } else {
        final logs = await session.getLogs();
        debugPrint('FFmpeg error: ${logs.map((log) => log.getMessage()).join('\n')}');
        return null;
      }
    } catch (e) {
      debugPrint('Error trimming video: $e');
      return null;
    }
  }

  static Future<String?> compressVideo({
    required String inputPath,
    String? outputPath,
    int quality = 23, // 0-51, lower is better quality
    Function(double)? onProgress,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basenameWithoutExtension(inputPath);
      
      outputPath ??= path.join(
        tempDir.path,
        '${fileName}_compressed_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      final command = '-i "$inputPath" -c:v libx264 -crf $quality -preset medium -c:a aac -b:a 128k "$outputPath"';
      
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      
      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      } else {
        final logs = await session.getLogs();
        debugPrint('FFmpeg compression error: ${logs.map((log) => log.getMessage()).join('\n')}');
        return null;
      }
    } catch (e) {
      debugPrint('Error compressing video: $e');
      return null;
    }
  }
}

// Video Trimmer Widget (for future implementation)
class VideoTrimmerWidget extends StatefulWidget {
  final String videoPath;
  final Duration maxDuration;
  final Function(Duration start, Duration end) onTrimChanged;
  final VoidCallback? onCancel;
  final Function(String trimmedPath)? onSave;

  const VideoTrimmerWidget({
    super.key,
    required this.videoPath,
    this.maxDuration = const Duration(minutes: 1),
    required this.onTrimChanged,
    this.onCancel,
    this.onSave,
  });

  @override
  State<VideoTrimmerWidget> createState() => _VideoTrimmerWidgetState();
}

class _VideoTrimmerWidgetState extends State<VideoTrimmerWidget> {
  VideoPlayerController? _controller;
  Duration _startTrim = Duration.zero;
  Duration _endTrim = Duration.zero;
  Duration _videoDuration = Duration.zero;
  bool _isInitialized = false;
  bool _isTrimming = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.file(File(widget.videoPath));
      await _controller!.initialize();
      
      setState(() {
        _isInitialized = true;
        _videoDuration = _controller!.value.duration;
        _endTrim = _videoDuration > widget.maxDuration 
            ? widget.maxDuration 
            : _videoDuration;
      });

      widget.onTrimChanged(_startTrim, _endTrim);
    } catch (e) {
      debugPrint('Error initializing video for trimming: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Video preview
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
          
          const SizedBox(height: 16),
          
          // Trim controls
          _buildTrimControls(),
          
          const SizedBox(height: 16),
          
          // Duration info
          Text(
            'Selected: ${_formatDuration(_endTrim - _startTrim)} / Max: ${_formatDuration(widget.maxDuration)}',
            style: TextStyle(
              fontSize: 14,
              color: (_endTrim - _startTrim) <= widget.maxDuration 
                  ? Colors.green 
                  : Colors.red,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: (_endTrim - _startTrim) <= widget.maxDuration && !_isTrimming
                    ? _trimAndSave
                    : null,
                child: _isTrimming 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrimControls() {
    return Column(
      children: [
        // Timeline slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: RangeSlider(
            values: RangeValues(
              _startTrim.inMilliseconds.toDouble(),
              _endTrim.inMilliseconds.toDouble(),
            ),
            min: 0,
            max: _videoDuration.inMilliseconds.toDouble(),
            divisions: (_videoDuration.inSeconds * 4).round(), // 250ms precision
            onChanged: (values) {
              setState(() {
                _startTrim = Duration(milliseconds: values.start.round());
                _endTrim = Duration(milliseconds: values.end.round());
              });
              widget.onTrimChanged(_startTrim, _endTrim);
              
              // Seek to start position
              _controller?.seekTo(_startTrim);
            },
          ),
        ),
        
        // Time labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_startTrim),
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                _formatDuration(_endTrim),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _trimAndSave() async {
    if (widget.onSave == null) return;
    
    setState(() => _isTrimming = true);
    
    try {
      final trimmedPath = await VideoTrimmerUtil.trimVideo(
        inputPath: widget.videoPath,
        startTime: _startTrim,
        endTime: _endTrim,
      );
      
      if (trimmedPath != null) {
        widget.onSave!(trimmedPath);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to trim video')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isTrimming = false);
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

// Video duration validator
class VideoValidator {
  static bool isValidForStatus(Duration duration) {
    return duration <= const Duration(minutes: 1);
  }
  
  static String getDurationWarning(Duration duration) {
    if (duration > const Duration(minutes: 1)) {
      return 'Video is ${_formatDuration(duration)}. Status videos must be 1 minute or less.';
    }
    return '';
  }
  
  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
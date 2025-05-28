// lib/features/channels/services/video_processing_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/level.dart';
import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoProcessingService extends ChangeNotifier {
  // Processing state
  bool _isProcessing = false;
  double _progress = 0.0;
  String _currentOperation = '';
  ProcessingStats? _stats;
  
  // Getters
  bool get isProcessing => _isProcessing;
  double get progress => _progress;
  String get currentOperation => _currentOperation;
  ProcessingStats? get stats => _stats;
  
  // Quality presets
  static const Map<VideoQuality, String> _qualitySettings = {
    VideoQuality.low: '-vf scale=480:-2 -b:v 800k -b:a 96k',
    VideoQuality.medium: '-vf scale=720:-2 -b:v 1500k -b:a 128k',
    VideoQuality.high: '-vf scale=1080:-2 -b:v 2500k -b:a 192k',
    VideoQuality.ultra: '-vf scale=1920:-2 -b:v 4000k -b:a 256k',
  };
  
  // Initialize FFmpeg
  Future<void> initialize() async {
    // Set log level for debugging
    await FFmpegKitConfig.setLogLevel(Level.avLogWarning);
  }
  
  // Main video processing pipeline
  Future<VideoProcessingResult> processVideo({
    required File inputFile,
    required Duration trimStart,
    required Duration trimEnd,
    VideoQuality quality = VideoQuality.high,
    bool generateThumbnail = true,
    bool addWatermark = false,
    String? watermarkPath,
  }) async {
    _isProcessing = true;
    _progress = 0.0;
    _currentOperation = 'Preparing video...';
    notifyListeners();
    
    try {
      // Get output directory
      final tempDir = await getTemporaryDirectory();
      final outputDir = Directory('${tempDir.path}/processed_videos');
      if (!outputDir.existsSync()) {
        outputDir.createSync(recursive: true);
      }
      
      // Generate output filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${outputDir.path}/video_$timestamp.mp4';
      
      // Step 1: Trim and compress video
      _currentOperation = 'Trimming and compressing video...';
      notifyListeners();
      
      final trimmedVideo = await _trimAndCompress(
        inputFile: inputFile,
        outputPath: outputPath,
        startTime: trimStart,
        endTime: trimEnd,
        quality: quality,
      );
      
      if (trimmedVideo == null) {
        throw Exception('Failed to process video');
      }
      
      // Step 2: Add watermark if requested
      File processedVideo = trimmedVideo;
      if (addWatermark && watermarkPath != null) {
        _currentOperation = 'Adding watermark...';
        _progress = 0.6;
        notifyListeners();
        
        final watermarkedPath = '${outputDir.path}/watermarked_$timestamp.mp4';
        final watermarkedVideo = await _addWatermark(
          inputFile: trimmedVideo,
          outputPath: watermarkedPath,
          watermarkPath: watermarkPath,
        );
        
        if (watermarkedVideo != null) {
          processedVideo = watermarkedVideo;
          // Delete intermediate file
          trimmedVideo.deleteSync();
        }
      }
      
      // Step 3: Generate thumbnail
      Uint8List? thumbnail;
      if (generateThumbnail) {
        _currentOperation = 'Generating thumbnail...';
        _progress = 0.8;
        notifyListeners();
        
        thumbnail = await _generateThumbnail(processedVideo);
      }
      
      // Step 4: Get video info
      _currentOperation = 'Finalizing...';
      _progress = 0.9;
      notifyListeners();
      
      final videoInfo = await _getVideoInfo(processedVideo);
      
      // Calculate compression stats
      final originalSize = await inputFile.length();
      final processedSize = await processedVideo.length();
      final compressionRatio = ((originalSize - processedSize) / originalSize * 100).toStringAsFixed(1);
      
      _stats = ProcessingStats(
        originalSize: originalSize,
        processedSize: processedSize,
        compressionRatio: compressionRatio,
        duration: trimEnd - trimStart,
        resolution: videoInfo.resolution,
        bitrate: videoInfo.bitrate,
      );
      
      _progress = 1.0;
      _currentOperation = 'Complete!';
      notifyListeners();
      
      return VideoProcessingResult(
        videoFile: processedVideo,
        thumbnail: thumbnail,
        duration: trimEnd - trimStart,
        stats: _stats!,
      );
      
    } catch (e) {
      _currentOperation = 'Error: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
  
  // Trim and compress video
  Future<File?> _trimAndCompress({
    required File inputFile,
    required String outputPath,
    required Duration startTime,
    required Duration endTime,
    required VideoQuality quality,
  }) async {
    final duration = endTime - startTime;
    final qualityParams = _qualitySettings[quality]!;
    
    // Build FFmpeg command
    final command = '-i "${inputFile.path}" '
        '-ss ${_formatDuration(startTime)} '
        '-t ${_formatDuration(duration)} '
        '$qualityParams '
        '-c:v libx264 '
        '-preset fast '
        '-crf 23 '
        '-c:a aac '
        '-movflags +faststart '
        '-avoid_negative_ts make_zero '
        '-y "${outputPath}"';
    
    // Execute with progress callback
    final session = await FFmpegKit.executeAsync(
      command,
      (session) async {
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          debugPrint('Video processing successful');
        } else {
          debugPrint('Video processing failed');
        }
      },
      null,
      (statistics) {
        // Update progress based on time
        if (statistics.getTime() > 0) {
          final progress = statistics.getTime() / duration.inMilliseconds;
          _progress = (progress * 0.6).clamp(0.0, 0.6); // 60% for trimming
          notifyListeners();
        }
      },
    );
    
    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      return File(outputPath);
    }
    
    return null;
  }
  
  // Add watermark to video
  Future<File?> _addWatermark({
    required File inputFile,
    required String outputPath,
    required String watermarkPath,
  }) async {
    // Position watermark in bottom right with padding
    final command = '-i "${inputFile.path}" '
        '-i "$watermarkPath" '
        '-filter_complex "[1:v]scale=120:-1[wm];[0:v][wm]overlay=W-w-10:H-h-10" '
        '-c:a copy '
        '-y "$outputPath"';
    
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    
    if (ReturnCode.isSuccess(returnCode)) {
      return File(outputPath);
    }
    
    return null;
  }
  
  // Generate thumbnail
  Future<Uint8List?> _generateThumbnail(File videoFile) async {
    try {
      final thumbnail = await VideoThumbnail.thumbnailData(
        video: videoFile.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        quality: 85,
      );
      
      return thumbnail;
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }
  
  // Get video information
  Future<VideoInfo> _getVideoInfo(File videoFile) async {
    final session = await FFprobeKit.getMediaInformation(videoFile.path);
    final info = session.getMediaInformation();
    
    if (info != null) {
      final streams = info.getStreams();
      final videoStream = streams.firstWhere(
        (stream) => stream.getType() == 'video',
        orElse: () => streams.first,
      );
      
      final width = videoStream.getWidth() ?? 0;
      final height = videoStream.getHeight() ?? 0;
      final bitrateString = info.getBitrate();
      final duration = info.getDuration() ?? '0';
      
      // Parse bitrate safely
      String formattedBitrate = 'Unknown';
      if (bitrateString != null && bitrateString.isNotEmpty) {
        try {
          final bitrateValue = double.parse(bitrateString);
          formattedBitrate = '${(bitrateValue / 1000).toStringAsFixed(0)} kbps';
        } catch (e) {
          debugPrint('Error parsing bitrate: $e');
          formattedBitrate = 'Unknown';
        }
      }
      
      return VideoInfo(
        resolution: '${width}x$height',
        bitrate: formattedBitrate,
        duration: Duration(milliseconds: (double.parse(duration) * 1000).toInt()),
      );
    }
    
    return VideoInfo(
      resolution: 'Unknown',
      bitrate: 'Unknown',
      duration: Duration.zero,
    );
  }
  
  // Advanced processing methods
  
  // Apply filters (blur, brightness, contrast, etc.)
  Future<File?> applyFilters({
    required File inputFile,
    List<VideoFilter> filters = const [],
  }) async {
    if (filters.isEmpty) return inputFile;
    
    final tempDir = await getTemporaryDirectory();
    final outputPath = '${tempDir.path}/filtered_${DateTime.now().millisecondsSinceEpoch}.mp4';
    
    // Build filter string
    final filterString = filters.map((f) => f.ffmpegFilter).join(',');
    
    final command = '-i "${inputFile.path}" '
        '-vf "$filterString" '
        '-c:a copy '
        '-y "$outputPath"';
    
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    
    if (ReturnCode.isSuccess(returnCode)) {
      return File(outputPath);
    }
    
    return null;
  }
  
  // Change video speed
  Future<File?> changeSpeed({
    required File inputFile,
    required double speed, // 0.5 = slow motion, 2.0 = 2x speed
  }) async {
    final tempDir = await getTemporaryDirectory();
    final outputPath = '${tempDir.path}/speed_${DateTime.now().millisecondsSinceEpoch}.mp4';
    
    // Calculate tempo for audio
    final tempo = speed.clamp(0.5, 2.0);
    final pts = 1.0 / speed;
    
    final command = '-i "${inputFile.path}" '
        '-filter_complex "[0:v]setpts=$pts*PTS[v];[0:a]atempo=$tempo[a]" '
        '-map "[v]" -map "[a]" '
        '-y "$outputPath"';
    
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    
    if (ReturnCode.isSuccess(returnCode)) {
      return File(outputPath);
    }
    
    return null;
  }
  
  // Merge multiple videos
  Future<File?> mergeVideos({
    required List<File> videos,
    List<Duration>? transitions,
  }) async {
    if (videos.isEmpty) return null;
    if (videos.length == 1) return videos.first;
    
    final tempDir = await getTemporaryDirectory();
    final outputPath = '${tempDir.path}/merged_${DateTime.now().millisecondsSinceEpoch}.mp4';
    
    // Create concat file
    final concatFile = File('${tempDir.path}/concat.txt');
    final concatContent = videos.map((v) => "file '${v.path}'").join('\n');
    await concatFile.writeAsString(concatContent);
    
    final command = '-f concat -safe 0 -i "${concatFile.path}" '
        '-c copy '
        '-y "$outputPath"';
    
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    
    // Clean up
    concatFile.deleteSync();
    
    if (ReturnCode.isSuccess(returnCode)) {
      return File(outputPath);
    }
    
    return null;
  }
  
  // Add background music
  Future<File?> addBackgroundMusic({
    required File videoFile,
    required File audioFile,
    double audioVolume = 0.3,
    bool fadeIn = true,
    bool fadeOut = true,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final outputPath = '${tempDir.path}/with_music_${DateTime.now().millisecondsSinceEpoch}.mp4';
    
    // Build audio filters
    final audioFilters = <String>[];
    audioFilters.add('volume=$audioVolume');
    
    if (fadeIn) audioFilters.add('afade=t=in:st=0:d=2');
    if (fadeOut) audioFilters.add('afade=t=out:st=28:d=2');
    
    final audioFilterString = audioFilters.join(',');
    
    final command = '-i "${videoFile.path}" -i "${audioFile.path}" '
        '-filter_complex "[1:a]$audioFilterString[music];[0:a][music]amix=inputs=2:duration=first[out]" '
        '-map 0:v -map "[out]" '
        '-c:v copy -c:a aac '
        '-y "$outputPath"';
    
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    
    if (ReturnCode.isSuccess(returnCode)) {
      return File(outputPath);
    }
    
    return null;
  }
  
  // Utility methods
  
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    final milliseconds = duration.inMilliseconds % 1000;
    
    return '$hours:${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}.'
           '${(milliseconds ~/ 10).toString().padLeft(2, '0')}';
  }
  
  // Cancel current operation
  void cancelProcessing() {
    FFmpegKit.cancel();
    _isProcessing = false;
    _progress = 0.0;
    _currentOperation = 'Cancelled';
    notifyListeners();
  }
}

// Data classes

enum VideoQuality { low, medium, high, ultra }

class VideoProcessingResult {
  final File videoFile;
  final Uint8List? thumbnail;
  final Duration duration;
  final ProcessingStats stats;
  
  VideoProcessingResult({
    required this.videoFile,
    this.thumbnail,
    required this.duration,
    required this.stats,
  });
}

class ProcessingStats {
  final int originalSize;
  final int processedSize;
  final String compressionRatio;
  final Duration duration;
  final String resolution;
  final String bitrate;
  
  ProcessingStats({
    required this.originalSize,
    required this.processedSize,
    required this.compressionRatio,
    required this.duration,
    required this.resolution,
    required this.bitrate,
  });
  
  String get formattedOriginalSize => _formatFileSize(originalSize);
  String get formattedProcessedSize => _formatFileSize(processedSize);
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class VideoInfo {
  final String resolution;
  final String bitrate;
  final Duration duration;
  
  VideoInfo({
    required this.resolution,
    required this.bitrate,
    required this.duration,
  });
}

class VideoFilter {
  final String name;
  final String ffmpegFilter;
  
  const VideoFilter(this.name, this.ffmpegFilter);
  
  // Preset filters
  static const blur = VideoFilter('Blur', 'boxblur=5:1');
  static const sharpen = VideoFilter('Sharpen', 'unsharp=5:5:1.0:5:5:0.0');
  static const brightness = VideoFilter('Brightness', 'eq=brightness=0.1');
  static const contrast = VideoFilter('Contrast', 'eq=contrast=1.2');
  static const saturation = VideoFilter('Saturation', 'eq=saturation=1.3');
  static const grayscale = VideoFilter('Grayscale', 'colorchannelmixer=.3:.4:.3:0:.3:.4:.3:0:.3:.4:.3');
  static const vintage = VideoFilter('Vintage', 'curves=vintage');
  static const vignette = VideoFilter('Vignette', 'vignette=PI/4');
}
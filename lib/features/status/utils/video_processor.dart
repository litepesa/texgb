// lib/features/status/utils/video_processor.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_new_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_gpl/statistics.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:textgb/features/status/utils/audio_enhancement_presets.dart';

class VideoProcessor {
  static const Duration maxStatusDuration = Duration(seconds: 60);
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  static const int statusVideoWidth = 720;
  static const int statusVideoHeight = 1280;

  /// Process video for status - includes trimming, compression, and format optimization
  static Future<VideoProcessingResult> processVideoForStatus({
    required String inputPath,
    Duration? startTime,
    Duration? endTime,
    String audioPreset = 'tiktok_style',
    Function(double)? onProgress,
  }) async {
    try {
      final videoInfo = await getVideoInfo(inputPath);
      if (videoInfo == null) {
        return VideoProcessingResult.error('Unable to read video information');
      }

      // Calculate processing steps needed
      final needsTrimming = (startTime != null && endTime != null) ||
          videoInfo.duration > maxStatusDuration;
      final needsCompression = await _needsCompression(inputPath);
      final needsResize = _needsResize(videoInfo);

      if (!needsTrimming && !needsCompression && !needsResize) {
        // Still apply audio enhancement even if video doesn't need other processing
        return await compressVideo(
          inputPath: inputPath,
          quality: 23, // High quality since no other processing needed
          audioPreset: audioPreset,
          onProgress: onProgress,
        );
      }

      return await _processVideo(
        inputPath: inputPath,
        videoInfo: videoInfo,
        startTime: startTime,
        endTime: endTime,
        needsTrimming: needsTrimming,
        needsCompression: needsCompression,
        needsResize: needsResize,
        audioPreset: audioPreset,
        onProgress: onProgress,
      );
    } catch (e) {
      debugPrint('Error processing video: $e');
      return VideoProcessingResult.error('Video processing failed: $e');
    }
  }

  /// Trim video to specified duration
  static Future<VideoProcessingResult> trimVideo({
    required String inputPath,
    required Duration startTime,
    required Duration endTime,
    String audioPreset = 'tiktok_style',
    Function(double)? onProgress,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basenameWithoutExtension(inputPath);
      final outputPath = path.join(
        tempDir.path,
        '${fileName}_trimmed_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      final startSeconds = startTime.inMilliseconds / 1000;
      final durationSeconds = (endTime.inMilliseconds - startTime.inMilliseconds) / 1000;

      // Get audio filters
      final presetFilters = AudioEnhancementPresets.getPreset(audioPreset);
      final audioFilters = presetFilters ?? AudioEnhancementPresets.tiktokStyle;

      // Build command with audio enhancement
      List<String> command = [
        '-i', inputPath,
        '-ss', startSeconds.toString(),
        '-t', durationSeconds.toString(),
        '-c:v', 'libx264',
        '-preset', 'medium',
        '-crf', '23',
        '-af', audioFilters.join(','),
        '-c:a', 'aac',
        '-b:a', '192k',
        '-ar', '48000',
        '-movflags', '+faststart',
        '-avoid_negative_ts', 'make_zero',
        outputPath
      ];

      // Setup progress callback if provided
      if (onProgress != null) {
        FFmpegKitConfig.enableStatisticsCallback((statistics) {
          if (statistics.getTime() > 0) {
            final progress = statistics.getTime() / (durationSeconds * 1000000);
            onProgress(progress.clamp(0.0, 1.0));
          }
        });
      }

      final session = await FFmpegKit.execute(command.join(' '));
      final returnCode = await session.getReturnCode();

      // Disable statistics callback
      if (onProgress != null) {
        FFmpegKitConfig.enableStatisticsCallback(null);
      }

      if (ReturnCode.isSuccess(returnCode)) {
        final videoInfo = await getVideoInfo(outputPath);
        return VideoProcessingResult.success(outputPath, videoInfo);
      } else {
        final logs = await session.getLogs();
        final errorMessage = logs.map((log) => log.getMessage()).join('\n');
        debugPrint('FFmpeg trim error: $errorMessage');
        return VideoProcessingResult.error('Failed to trim video');
      }
    } catch (e) {
      debugPrint('Error trimming video: $e');
      return VideoProcessingResult.error('Video trimming failed: $e');
    }
  }

  /// Compress video for status sharing with audio normalization
  static Future<VideoProcessingResult> compressVideo({
    required String inputPath,
    int quality = 28, // CRF value (lower = higher quality)
    String audioPreset = 'tiktok_style',
    Function(double)? onProgress,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basenameWithoutExtension(inputPath);
      final outputPath = path.join(
        tempDir.path,
        '${fileName}_compressed_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      // Build audio filter chain using presets
      List<String> audioFilters = [];
      
      final presetFilters = AudioEnhancementPresets.getPreset(audioPreset);
      if (presetFilters != null) {
        audioFilters.addAll(presetFilters);
      } else {
        // Fallback to TikTok style if preset not found
        audioFilters.addAll(AudioEnhancementPresets.tiktokStyle);
      }

      // Optimized compression for status videos with enhanced audio
      List<String> command = [
        '-i', inputPath,
        '-c:v', 'libx264',
        '-preset', 'medium',
        '-crf', quality.toString(),
        '-maxrate', '2M',
        '-bufsize', '4M',
        '-movflags', '+faststart',
        '-threads', '0', // Use all available threads
      ];

      // Add audio processing
      if (audioFilters.isNotEmpty) {
        command.addAll([
          '-af', audioFilters.join(','),
          '-c:a', 'aac',
          '-b:a', '192k', // Higher bitrate for enhanced audio
          '-ar', '48000', // High sample rate
        ]);
      } else {
        command.addAll([
          '-c:a', 'aac',
          '-b:a', '128k',
        ]);
      }

      command.add(outputPath);
      final commandString = command.join(' ');

      // Setup progress callback if provided
      if (onProgress != null) {
        FFmpegKitConfig.enableStatisticsCallback((statistics) {
          if (statistics.getTime() > 0) {
            getVideoInfo(inputPath).then((info) {
              if (info != null) {
                final progress = statistics.getTime() / (info.duration.inMicroseconds);
                onProgress(progress.clamp(0.0, 1.0));
              }
            });
          }
        });
      }

      final session = await FFmpegKit.execute(commandString);
      final returnCode = await session.getReturnCode();

      // Disable statistics callback
      if (onProgress != null) {
        FFmpegKitConfig.enableStatisticsCallback(null);
      }

      if (ReturnCode.isSuccess(returnCode)) {
        final videoInfo = await getVideoInfo(outputPath);
        return VideoProcessingResult.success(outputPath, videoInfo);
      } else {
        final logs = await session.getLogs();
        final errorMessage = logs.map((log) => log.getMessage()).join('\n');
        debugPrint('FFmpeg compression error: $errorMessage');
        return VideoProcessingResult.error('Failed to compress video');
      }
    } catch (e) {
      debugPrint('Error compressing video: $e');
      return VideoProcessingResult.error('Video compression failed: $e');
    }
  }

  /// Resize video to optimal dimensions for status
  static Future<VideoProcessingResult> resizeVideo({
    required String inputPath,
    int? targetWidth,
    int? targetHeight,
    String audioPreset = 'tiktok_style',
    Function(double)? onProgress,
  }) async {
    try {
      final videoInfo = await getVideoInfo(inputPath);
      if (videoInfo == null) {
        return VideoProcessingResult.error('Unable to read video information');
      }

      // Calculate optimal dimensions maintaining aspect ratio
      final dimensions = _calculateOptimalDimensions(
        videoInfo.width,
        videoInfo.height,
        targetWidth ?? statusVideoWidth,
        targetHeight ?? statusVideoHeight,
      );

      final tempDir = await getTemporaryDirectory();
      final fileName = path.basenameWithoutExtension(inputPath);
      final outputPath = path.join(
        tempDir.path,
        '${fileName}_resized_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      // Get audio filters
      final presetFilters = AudioEnhancementPresets.getPreset(audioPreset);
      final audioFilters = presetFilters ?? AudioEnhancementPresets.tiktokStyle;

      List<String> command = [
        '-i', inputPath,
        '-vf', 'scale=${dimensions.width}:${dimensions.height}:force_original_aspect_ratio=decrease,pad=${dimensions.width}:${dimensions.height}:(ow-iw)/2:(oh-ih)/2:black',
        '-c:v', 'libx264',
        '-preset', 'medium',
        '-crf', '25',
        '-af', audioFilters.join(','),
        '-c:a', 'aac',
        '-b:a', '192k',
        '-movflags', '+faststart',
        outputPath
      ];

      // Setup progress callback if provided
      if (onProgress != null) {
        FFmpegKitConfig.enableStatisticsCallback((statistics) {
          if (statistics.getTime() > 0) {
            final progress = statistics.getTime() / (videoInfo.duration.inMicroseconds);
            onProgress(progress.clamp(0.0, 1.0));
          }
        });
      }

      final session = await FFmpegKit.execute(command.join(' '));
      final returnCode = await session.getReturnCode();

      // Disable statistics callback
      if (onProgress != null) {
        FFmpegKitConfig.enableStatisticsCallback(null);
      }

      if (ReturnCode.isSuccess(returnCode)) {
        final newVideoInfo = await getVideoInfo(outputPath);
        return VideoProcessingResult.success(outputPath, newVideoInfo);
      } else {
        final logs = await session.getLogs();
        final errorMessage = logs.map((log) => log.getMessage()).join('\n');
        debugPrint('FFmpeg resize error: $errorMessage');
        return VideoProcessingResult.error('Failed to resize video');
      }
    } catch (e) {
      debugPrint('Error resizing video: $e');
      return VideoProcessingResult.error('Video resizing failed: $e');
    }
  }

  /// Extract thumbnail from video at specific time
  static Future<String?> extractThumbnail({
    required String videoPath,
    Duration? atTime,
    int width = 400,
    int height = 400,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath = path.join(
        tempDir.path,
        'thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final timeSeconds = (atTime?.inMilliseconds ?? 1000) / 1000;

      final command = [
        '-i', videoPath,
        '-ss', timeSeconds.toString(),
        '-vframes', '1',
        '-vf', 'scale=$width:$height:force_original_aspect_ratio=decrease',
        '-q:v', '2',
        thumbnailPath
      ].join(' ');

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return thumbnailPath;
      } else {
        debugPrint('Failed to extract thumbnail');
        return null;
      }
    } catch (e) {
      debugPrint('Error extracting thumbnail: $e');
      return null;
    }
  }

  /// Get comprehensive video information
  static Future<VideoInfo?> getVideoInfo(String videoPath) async {
    try {
      final command = [
        '-i', videoPath,
        '-hide_banner',
        '-f', 'null',
        '-'
      ].join(' ');

      final session = await FFmpegKit.execute(command);
      final logs = await session.getLogs();
      final output = logs.map((log) => log.getMessage()).join('\n');

      return _parseVideoInfo(videoPath, output);
    } catch (e) {
      debugPrint('Error getting video info: $e');
      return null;
    }
  }

  /// Add watermark or overlay to video
  static Future<VideoProcessingResult> addWatermark({
    required String inputPath,
    required String watermarkText,
    String position = 'bottom-right',
    String audioPreset = 'tiktok_style',
    Function(double)? onProgress,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basenameWithoutExtension(inputPath);
      final outputPath = path.join(
        tempDir.path,
        '${fileName}_watermarked_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      // Position mapping for text overlay
      final positionMap = {
        'top-left': 'x=10:y=10',
        'top-right': 'x=w-tw-10:y=10',
        'bottom-left': 'x=10:y=h-th-10',
        'bottom-right': 'x=w-tw-10:y=h-th-10',
        'center': 'x=(w-tw)/2:y=(h-th)/2',
      };

      final textPosition = positionMap[position] ?? positionMap['bottom-right']!;

      // Get audio filters
      final presetFilters = AudioEnhancementPresets.getPreset(audioPreset);
      final audioFilters = presetFilters ?? AudioEnhancementPresets.tiktokStyle;

      List<String> command = [
        '-i', inputPath,
        '-vf', "drawtext=text='$watermarkText':fontcolor=white:fontsize=24:$textPosition:alpha=0.8",
        '-af', audioFilters.join(','),
        '-c:a', 'aac',
        '-b:a', '192k',
        '-c:v', 'libx264',
        '-preset', 'fast',
        '-crf', '23',
        outputPath
      ];

      final session = await FFmpegKit.execute(command.join(' '));
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final videoInfo = await getVideoInfo(outputPath);
        return VideoProcessingResult.success(outputPath, videoInfo);
      } else {
        return VideoProcessingResult.error('Failed to add watermark');
      }
    } catch (e) {
      debugPrint('Error adding watermark: $e');
      return VideoProcessingResult.error('Watermark addition failed: $e');
    }
  }

  /// Convert video to different format
  static Future<VideoProcessingResult> convertFormat({
    required String inputPath,
    required String outputFormat, // 'mp4', 'webm', 'mov', etc.
    String audioPreset = 'tiktok_style',
    Function(double)? onProgress,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basenameWithoutExtension(inputPath);
      final outputPath = path.join(
        tempDir.path,
        '${fileName}_converted_${DateTime.now().millisecondsSinceEpoch}.$outputFormat',
      );

      // Get audio filters
      final presetFilters = AudioEnhancementPresets.getPreset(audioPreset);
      final audioFilters = presetFilters ?? AudioEnhancementPresets.tiktokStyle;

      List<String> command = [
        '-i', inputPath,
        '-c:v', 'libx264',
        '-af', audioFilters.join(','),
        '-c:a', 'aac',
        '-b:a', '192k',
        '-preset', 'medium',
        '-crf', '23',
        '-movflags', '+faststart',
        outputPath
      ];

      final session = await FFmpegKit.execute(command.join(' '));
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final videoInfo = await getVideoInfo(outputPath);
        return VideoProcessingResult.success(outputPath, videoInfo);
      } else {
        return VideoProcessingResult.error('Failed to convert video format');
      }
    } catch (e) {
      debugPrint('Error converting video format: $e');
      return VideoProcessingResult.error('Format conversion failed: $e');
    }
  }

  /// Enhance audio only without video processing
  static Future<VideoProcessingResult> enhanceAudioOnly({
    required String inputPath,
    String audioPreset = 'tiktok_style',
    Function(double)? onProgress,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basenameWithoutExtension(inputPath);
      final outputPath = path.join(
        tempDir.path,
        '${fileName}_audio_enhanced_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      // Get audio filters
      final presetFilters = AudioEnhancementPresets.getPreset(audioPreset);
      final audioFilters = presetFilters ?? AudioEnhancementPresets.tiktokStyle;

      List<String> command = [
        '-i', inputPath,
        '-c:v', 'copy', // Copy video stream without re-encoding
        '-af', audioFilters.join(','),
        '-c:a', 'aac',
        '-b:a', '192k',
        '-ar', '48000',
        outputPath
      ];

      // Setup progress callback if provided
      if (onProgress != null) {
        FFmpegKitConfig.enableStatisticsCallback((statistics) {
          if (statistics.getTime() > 0) {
            getVideoInfo(inputPath).then((info) {
              if (info != null) {
                final progress = statistics.getTime() / (info.duration.inMicroseconds);
                onProgress(progress.clamp(0.0, 1.0));
              }
            });
          }
        });
      }

      final session = await FFmpegKit.execute(command.join(' '));
      final returnCode = await session.getReturnCode();

      // Disable statistics callback
      if (onProgress != null) {
        FFmpegKitConfig.enableStatisticsCallback(null);
      }

      if (ReturnCode.isSuccess(returnCode)) {
        final videoInfo = await getVideoInfo(outputPath);
        return VideoProcessingResult.success(outputPath, videoInfo);
      } else {
        final logs = await session.getLogs();
        final errorMessage = logs.map((log) => log.getMessage()).join('\n');
        debugPrint('FFmpeg audio enhancement error: $errorMessage');
        return VideoProcessingResult.error('Failed to enhance audio');
      }
    } catch (e) {
      debugPrint('Error enhancing audio: $e');
      return VideoProcessingResult.error('Audio enhancement failed: $e');
    }
  }

  // Private helper methods
  static Future<VideoProcessingResult> _processVideo({
    required String inputPath,
    required VideoInfo videoInfo,
    Duration? startTime,
    Duration? endTime,
    required bool needsTrimming,
    required bool needsCompression,
    required bool needsResize,
    String audioPreset = 'tiktok_style',
    Function(double)? onProgress,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basenameWithoutExtension(inputPath);
      final outputPath = path.join(
        tempDir.path,
        '${fileName}_processed_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      List<String> command = ['-i', inputPath];

      // Add trimming parameters
      if (needsTrimming) {
        final start = startTime ?? Duration.zero;
        final end = endTime ?? 
            (videoInfo.duration > maxStatusDuration ? maxStatusDuration : videoInfo.duration);
        
        final startSeconds = start.inMilliseconds / 1000;
        final durationSeconds = (end.inMilliseconds - start.inMilliseconds) / 1000;
        
        command.addAll(['-ss', startSeconds.toString(), '-t', durationSeconds.toString()]);
      }

      // Add resizing parameters
      if (needsResize) {
        final dimensions = _calculateOptimalDimensions(
          videoInfo.width,
          videoInfo.height,
          statusVideoWidth,
          statusVideoHeight,
        );
        command.addAll([
          '-vf',
          'scale=${dimensions.width}:${dimensions.height}:force_original_aspect_ratio=decrease,pad=${dimensions.width}:${dimensions.height}:(ow-iw)/2:(oh-ih)/2:black'
        ]);
      }

      // Build audio enhancement filters using presets
      List<String> audioFilters = [];
      final presetFilters = AudioEnhancementPresets.getPreset(audioPreset);
      if (presetFilters != null) {
        audioFilters.addAll(presetFilters);
      } else {
        // Fallback to TikTok style
        audioFilters.addAll(AudioEnhancementPresets.tiktokStyle);
      }

      // Add compression and audio parameters
      command.addAll([
        '-c:v', 'libx264',
        '-preset', 'medium',
        '-crf', needsCompression ? '28' : '23',
        '-maxrate', '2M',
        '-bufsize', '4M',
      ]);

      // Add audio processing
      if (audioFilters.isNotEmpty) {
        command.addAll([
          '-af', audioFilters.join(','),
          '-c:a', 'aac',
          '-b:a', '192k', // Higher bitrate for enhanced audio
          '-ar', '48000', // High sample rate
        ]);
      } else {
        command.addAll([
          '-c:a', 'aac',
          '-b:a', '128k',
        ]);
      }

      command.addAll([
        '-movflags', '+faststart',
        outputPath
      ]);

      // Setup progress callback if provided
      if (onProgress != null) {
        FFmpegKitConfig.enableStatisticsCallback((statistics) {
          if (statistics.getTime() > 0) {
            final progress = statistics.getTime() / (videoInfo.duration.inMicroseconds);
            onProgress(progress.clamp(0.0, 1.0));
          }
        });
      }

      final session = await FFmpegKit.execute(command.join(' '));
      final returnCode = await session.getReturnCode();

      // Disable statistics callback
      if (onProgress != null) {
        FFmpegKitConfig.enableStatisticsCallback(null);
      }

      if (ReturnCode.isSuccess(returnCode)) {
        final newVideoInfo = await getVideoInfo(outputPath);
        return VideoProcessingResult.success(outputPath, newVideoInfo);
      } else {
        final logs = await session.getLogs();
        final errorMessage = logs.map((log) => log.getMessage()).join('\n');
        debugPrint('FFmpeg processing error: $errorMessage');
        return VideoProcessingResult.error('Video processing failed');
      }
    } catch (e) {
      debugPrint('Error in video processing: $e');
      return VideoProcessingResult.error('Video processing failed: $e');
    }
  }

  static Future<bool> _needsCompression(String inputPath) async {
    try {
      final file = File(inputPath);
      final fileSize = await file.length();
      return fileSize > maxFileSize;
    } catch (e) {
      return true; // Default to compression if we can't determine size
    }
  }

  static bool _needsResize(VideoInfo videoInfo) {
    return videoInfo.width > statusVideoWidth || videoInfo.height > statusVideoHeight;
  }

  static VideoDimensions _calculateOptimalDimensions(
    int originalWidth,
    int originalHeight,
    int targetWidth,
    int targetHeight,
  ) {
    final aspectRatio = originalWidth / originalHeight;
    final targetAspectRatio = targetWidth / targetHeight;

    int width, height;

    if (aspectRatio > targetAspectRatio) {
      // Video is wider than target
      width = targetWidth;
      height = (targetWidth / aspectRatio).round();
    } else {
      // Video is taller than target
      height = targetHeight;
      width = (targetHeight * aspectRatio).round();
    }

    return VideoDimensions(width, height);
  }

  static VideoInfo? _parseVideoInfo(String videoPath, String ffmpegOutput) {
    try {
      final file = File(videoPath);
      
      // Parse duration
      final durationRegex = RegExp(r'Duration: (\d{2}):(\d{2}):(\d{2})\.(\d{2})');
      final durationMatch = durationRegex.firstMatch(ffmpegOutput);
      
      Duration duration = Duration.zero;
      if (durationMatch != null) {
        final hours = int.parse(durationMatch.group(1)!);
        final minutes = int.parse(durationMatch.group(2)!);
        final seconds = int.parse(durationMatch.group(3)!);
        final centiseconds = int.parse(durationMatch.group(4)!);
        
        duration = Duration(
          hours: hours,
          minutes: minutes,
          seconds: seconds,
          milliseconds: centiseconds * 10,
        );
      }

      // Parse video dimensions
      final dimensionRegex = RegExp(r'(\d{3,4})x(\d{3,4})');
      final dimensionMatch = dimensionRegex.firstMatch(ffmpegOutput);
      
      int width = 720;
      int height = 1280;
      if (dimensionMatch != null) {
        width = int.parse(dimensionMatch.group(1)!);
        height = int.parse(dimensionMatch.group(2)!);
      }

      // Parse bitrate
      final bitrateRegex = RegExp(r'bitrate: (\d+) kb/s');
      final bitrateMatch = bitrateRegex.firstMatch(ffmpegOutput);
      
      int bitrate = 0;
      if (bitrateMatch != null) {
        bitrate = int.parse(bitrateMatch.group(1)!);
      }

      return VideoInfo(
        path: videoPath,
        duration: duration,
        width: width,
        height: height,
        bitrate: bitrate,
        fileSize: file.lengthSync(),
      );
    } catch (e) {
      debugPrint('Error parsing video info: $e');
      return null;
    }
  }
}

// Data classes
class VideoInfo {
  final String path;
  final Duration duration;
  final int width;
  final int height;
  final int bitrate;
  final int fileSize;

  VideoInfo({
    required this.path,
    required this.duration,
    required this.width,
    required this.height,
    required this.bitrate,
    required this.fileSize,
  });

  bool get isValidForStatus => duration <= VideoProcessor.maxStatusDuration;
  
  String get durationText {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get fileSizeText {
    final sizeInMB = fileSize / (1024 * 1024);
    return '${sizeInMB.toStringAsFixed(1)} MB';
  }

  double get aspectRatio => width / height;

  bool get isPortrait => height > width;
  bool get isLandscape => width > height;
  bool get isSquare => width == height;

  @override
  String toString() {
    return 'VideoInfo(path: $path, duration: $durationText, ${width}x$height, ${fileSizeText})';
  }
}

class VideoDimensions {
  final int width;
  final int height;

  VideoDimensions(this.width, this.height);

  double get aspectRatio => width / height;

  @override
  String toString() => '${width}x$height';
}

class VideoProcessingResult {
  final bool isSuccess;
  final String? outputPath;
  final VideoInfo? videoInfo;
  final String? error;

  VideoProcessingResult.success(this.outputPath, this.videoInfo)
      : isSuccess = true,
        error = null;

  VideoProcessingResult.error(this.error)
      : isSuccess = false,
        outputPath = null,
        videoInfo = null;

  @override
  String toString() {
    if (isSuccess) {
      return 'VideoProcessingResult.success(outputPath: $outputPath, videoInfo: $videoInfo)';
    } else {
      return 'VideoProcessingResult.error(error: $error)';
    }
  }
}
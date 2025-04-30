import 'package:freezed_annotation/freezed_annotation.dart';

part 'status_media.freezed.dart';
part 'status_media.g.dart';

enum MediaType {
  image,
  video,
  gif
}

@freezed
class StatusMedia with _$StatusMedia {
  const factory StatusMedia({
    required String id,
    required String url,
    required MediaType type,
    String? thumbnailUrl,
    int? width,
    int? height,
    int? duration, // for videos: duration in seconds
    int? size, // file size in bytes
  }) = _StatusMedia;

  factory StatusMedia.fromJson(Map<String, dynamic> json) => _$StatusMediaFromJson(json);
  
  // Helper methods
  const StatusMedia._();
  
  bool get isVideo => type == MediaType.video;
  bool get isImage => type == MediaType.image;
  bool get isGif => type == MediaType.gif;
  
  // Get aspect ratio if dimensions are available
  double? get aspectRatio {
    if (width != null && height != null && height! > 0) {
      return width! / height!;
    }
    return null;
  }
  
  // Get formatted duration for videos
  String? get formattedDuration {
    if (!isVideo || duration == null) return null;
    
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
  
  // Get formatted file size
  String? get formattedSize {
    if (size == null) return null;
    
    if (size! < 1024) {
      return '$size B';
    } else if (size! < 1024 * 1024) {
      return '${(size! / 1024).toStringAsFixed(1)} KB';
    } else if (size! < 1024 * 1024 * 1024) {
      return '${(size! / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
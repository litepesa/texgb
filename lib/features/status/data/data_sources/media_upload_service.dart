import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:image_size_getter/file_input.dart';
import 'package:video_compress/video_compress.dart';

/// Service for handling media uploads and related operations
class MediaUploadService {
  final FirebaseStorage _storage;
  final Uuid _uuid;
  
  MediaUploadService({
    required FirebaseStorage storage,
    required Uuid uuid,
  }) : _storage = storage, _uuid = uuid;
  
  /// Upload a file to Firebase Storage
  Future<String> uploadFile({
    required File file,
    required String path,
  }) async {
    try {
      // Determine if this is a video
      final isVideo = _isVideoFile(file.path);
      
      // Compress file if needed
      File fileToUpload;
      if (isVideo) {
        fileToUpload = await _compressVideo(file);
      } else {
        fileToUpload = await _compressImage(file);
      }
      
      // Create storage reference
      final ref = _storage.ref().child(path);
      
      // Set metadata for content type
      SettableMetadata metadata;
      if (isVideo) {
        metadata = SettableMetadata(contentType: 'video/mp4');
      } else if (_isGifFile(file.path)) {
        metadata = SettableMetadata(contentType: 'image/gif');
      } else {
        metadata = SettableMetadata(contentType: 'image/jpeg');
      }
      
      // Upload the file
      final uploadTask = ref.putFile(fileToUpload, metadata);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      rethrow;
    }
  }
  
  /// Generate a thumbnail for a video file
  Future<String?> generateThumbnail(File videoFile) async {
    try {
      // Create thumbnail
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        imageFormat: ImageFormat.JPEG,
        quality: 75,
        maxWidth: 640,
      );
      
      if (thumbnailPath == null) {
        return null;
      }
      
      // Upload thumbnail to storage
      final thumbnailFile = File(thumbnailPath);
      final thumbnailId = _uuid.v4();
      final storageRef = _storage.ref().child('thumbnails/$thumbnailId.jpg');
      
      // Upload thumbnail
      final uploadTask = storageRef.putFile(
        thumbnailFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Clean up temporary file
      await thumbnailFile.delete();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }
  
  /// Fetch link preview data (title, description, image)
  Future<LinkPreviewData> fetchLinkPreview(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode != 200) {
        return LinkPreviewData(
          url: url,
          title: url,
          description: '',
          imageUrl: null,
        );
      }
      
      final document = html_parser.parse(response.body);
      
      // Try to get OpenGraph tags first
      final ogImage = document.querySelector('meta[property="og:image"]');
      final ogTitle = document.querySelector('meta[property="og:title"]');
      final ogDesc = document.querySelector('meta[property="og:description"]');
      
      String? imageUrl;
      String title = url;
      String description = '';
      
      if (ogImage != null) {
        imageUrl = ogImage.attributes['content'];
      }
      
      if (ogTitle != null) {
        title = ogTitle.attributes['content'] ?? url;
      }
      
      if (ogDesc != null) {
        description = ogDesc.attributes['content'] ?? '';
      }
      
      // If OG tags not available, use regular meta tags
      if (imageUrl == null) {
        final imgMeta = document.querySelector('meta[name="image"]');
        if (imgMeta != null) {
          imageUrl = imgMeta.attributes['content'];
        }
      }
      
      if (title == url) {
        final titleTag = document.querySelector('title');
        if (titleTag != null) {
          title = titleTag.text;
        }
      }
      
      if (description.isEmpty) {
        final descMeta = document.querySelector('meta[name="description"]');
        if (descMeta != null) {
          description = descMeta.attributes['content'] ?? '';
        }
      }
      
      return LinkPreviewData(
        url: url,
        title: title,
        description: description,
        imageUrl: imageUrl,
      );
    } catch (e) {
      debugPrint('Error fetching link preview: $e');
      return LinkPreviewData(
        url: url,
        title: url,
        description: '',
        imageUrl: null,
      );
    }
  }
  
  /// Get media metadata (dimensions, duration, size)
  Future<MediaMetadata> getMediaMetadata(File file) async {
    try {
      final fileSize = await file.length();
      
      if (_isVideoFile(file.path)) {
        // Get video metadata
        final videoInfo = await VideoCompress.getMediaInfo(file.path);
        
        return MediaMetadata(
          width: videoInfo.width,
          height: videoInfo.height,
          duration: videoInfo.duration?.toInt(),
          size: fileSize,
        );
      } else {
        // Get image dimensions
        final size = ImageSizeGetter.getSize(FileInput(file));
        
        return MediaMetadata(
          width: size.width,
          height: size.height,
          size: fileSize,
        );
      }
    } catch (e) {
      debugPrint('Error getting media metadata: $e');
      return MediaMetadata(size: await file.length());
    }
  }
  
  /// Compress an image file
  Future<File> _compressImage(File file) async {
    // Skip compression for GIFs
    if (_isGifFile(file.path)) {
      return file;
    }
    
    try {
      final fileSize = await file.length();
      final fileSizeInMB = fileSize / (1024 * 1024);
      
      // Skip compression for small files
      if (fileSizeInMB < 1) {
        return file;
      }
      
      // Create temp file for compressed image
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/${_uuid.v4()}.jpg';
      
      // Determine compression quality based on file size
      int quality = 85;
      if (fileSizeInMB > 5) {
        quality = 70;
      }
      if (fileSizeInMB > 10) {
        quality = 60;
      }
      
      // Compress the image
      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: quality,
        keepExif: false,
      );
      
      if (result == null) {
        return file;
      }
      
      return File(result.path);
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return file;
    }
  }
  
  /// Compress a video file
  Future<File> _compressVideo(File file) async {
    try {
      final fileSize = await file.length();
      final fileSizeInMB = fileSize / (1024 * 1024);
      
      // Skip compression for small files
      if (fileSizeInMB < 5) {
        return file;
      }
      
      // Compress the video
      final mediaInfo = await VideoCompress.compressVideo(
        file.path,
        quality: fileSizeInMB > 20 ? VideoQuality.MediumQuality : VideoQuality.HighQuality,
        deleteOrigin: false,
        includeAudio: true,
      );
      
      if (mediaInfo?.file == null) {
        return file;
      }
      
      return mediaInfo!.file!;
    } catch (e) {
      debugPrint('Error compressing video: $e');
      return file;
    }
  }
  
  /// Check if file is a video based on extension
  bool _isVideoFile(String path) {
    final extension = path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'].contains(extension);
  }
  
  /// Check if file is a GIF
  bool _isGifFile(String path) {
    final extension = path.split('.').last.toLowerCase();
    return extension == 'gif';
  }
}

/// Data class for media metadata
class MediaMetadata {
  final int? width;
  final int? height;
  final int? duration; // In seconds
  final int size; // In bytes
  
  MediaMetadata({
    this.width,
    this.height,
    this.duration,
    required this.size,
  });
}

/// Data class for link preview data
class LinkPreviewData {
  final String url;
  final String title;
  final String description;
  final String? imageUrl;
  
  LinkPreviewData({
    required this.url,
    required this.title,
    required this.description,
    this.imageUrl,
  });
}
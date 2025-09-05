// lib/features/videos/models/video_model.dart
import 'package:flutter/material.dart';

class VideoModel {
  final String id;
  final String userId;
  final String userName;
  final String userImage;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final int likes;
  final int comments;
  final int views;
  final int shares;
  final bool isLiked;
  final List<String> tags;
  final String createdAt;  // Changed to String for RFC3339 format
  final String updatedAt;  // Added for Go backend
  final bool isActive;
  final bool isFeatured;
  final bool isMultipleImages;
  final List<String> imageUrls;

  VideoModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.views,
    required this.shares,
    required this.isLiked,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.isFeatured,
    this.isMultipleImages = false,
    this.imageUrls = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'likes': likes,
      'comments': comments,
      'views': views,
      'shares': shares,
      'tags': tags,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'isMultipleImages': isMultipleImages,
      'imageUrls': imageUrls,
    };
  }

  factory VideoModel.fromMap(Map<String, dynamic> map, {String? id, bool isLiked = false}) {
    final videoId = id ?? map['id'] ?? '';
    
    if (videoId.isEmpty) {
      debugPrint('WARNING: Creating VideoModel with empty ID');
    }
    
    return VideoModel(
      id: videoId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userImage: map['userImage'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      caption: map['caption'] ?? '',
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      views: map['views'] ?? 0,
      shares: map['shares'] ?? 0,
      isLiked: isLiked,
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: map['createdAt'] ?? '',
      updatedAt: map['updatedAt'] ?? '',
      isActive: map['isActive'] ?? true,
      isFeatured: map['isFeatured'] ?? false,
      isMultipleImages: map['isMultipleImages'] ?? false,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
    );
  }

  VideoModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userImage,
    String? videoUrl,
    String? thumbnailUrl,
    String? caption,
    int? likes,
    int? comments,
    int? views,
    int? shares,
    bool? isLiked,
    List<String>? tags,
    String? createdAt,
    String? updatedAt,
    bool? isActive,
    bool? isFeatured,
    bool? isMultipleImages,
    List<String>? imageUrls,
  }) {
    return VideoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      views: views ?? this.views,
      shares: shares ?? this.shares,
      isLiked: isLiked ?? this.isLiked,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      isMultipleImages: isMultipleImages ?? this.isMultipleImages,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'VideoModel(id: $id, caption: $caption, userName: $userName)';
  }
}
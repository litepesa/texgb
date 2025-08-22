import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChannelVideoModel {
  final String id;
  final String channelId;
  final String channelName;
  final String channelImage;
  final String userId;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final int likes;
  final int comments;
  final int views;
  final int shares;
  final bool isLiked;
  final List<String> tags;
  final Timestamp createdAt;
  final bool isActive;
  final bool isFeatured;
  final bool isMultipleImages; // Flag to indicate if this is a carousel of images instead of video
  final List<String> imageUrls; // Used for multiple images post

  ChannelVideoModel({
    required this.id,
    required this.channelId,
    required this.channelName,
    required this.channelImage,
    required this.userId,
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
    required this.isActive,
    required this.isFeatured,
    this.isMultipleImages = false,
    this.imageUrls = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'channelId': channelId,
      'channelName': channelName,
      'channelImage': channelImage,
      'userId': userId,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'likes': likes,
      'comments': comments,
      'views': views,
      'shares': shares,
      'tags': tags,
      'createdAt': createdAt,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'isMultipleImages': isMultipleImages,
      'imageUrls': imageUrls,
    };
  }

  factory ChannelVideoModel.fromMap(Map<String, dynamic> map, {String? id, bool isLiked = false}) {
    final videoId = id ?? map['id'] ?? '';
    
    if (videoId.isEmpty) {
      debugPrint('WARNING: Creating ChannelVideoModel with empty ID');
    }
    
    return ChannelVideoModel(
      id: videoId,
      channelId: map['channelId'] ?? '',
      channelName: map['channelName'] ?? '',
      channelImage: map['channelImage'] ?? '',
      userId: map['userId'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      caption: map['caption'] ?? '',
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      views: map['views'] ?? 0,
      shares: map['shares'] ?? 0,
      isLiked: isLiked,
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: map['createdAt'] ?? Timestamp.now(),
      isActive: map['isActive'] ?? true,
      isFeatured: map['isFeatured'] ?? false,
      isMultipleImages: map['isMultipleImages'] ?? false,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
    );
  }

  get duration => null;

  get title => null;

  get fileSize => null;

  ChannelVideoModel copyWith({
    String? id,
    String? channelId,
    String? channelName,
    String? channelImage,
    String? userId,
    String? videoUrl,
    String? thumbnailUrl,
    String? caption,
    int? likes,
    int? comments,
    int? views,
    int? shares,
    bool? isLiked,
    List<String>? tags,
    Timestamp? createdAt,
    bool? isActive,
    bool? isFeatured,
    bool? isMultipleImages,
    List<String>? imageUrls,
  }) {
    return ChannelVideoModel(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      channelImage: channelImage ?? this.channelImage,
      userId: userId ?? this.userId,
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
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      isMultipleImages: isMultipleImages ?? this.isMultipleImages,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }
}
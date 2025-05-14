// lib/features/marketplace/models/marketplace_video_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MarketplaceVideoModel {
  final String id;
  final String userId;
  final String userName;
  final String userImage;
  final String businessName;
  final String videoUrl;
  final String thumbnailUrl;
  final String productName;
  final String price;
  final String description;
  final String category;
  final int likes;
  final int comments;
  final int views;
  final bool isLiked;
  final List<String> tags;
  final String location;
  final Timestamp createdAt;
  final bool isActive;
  final bool isFeatured;

  MarketplaceVideoModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.businessName,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.productName,
    required this.price,
    required this.description,
    required this.category,
    required this.likes,
    required this.comments,
    required this.views,
    required this.isLiked,
    required this.tags,
    required this.location,
    required this.createdAt,
    required this.isActive,
    required this.isFeatured,
  });

  Map<String, dynamic> toMap() {
    // Important: Do NOT include 'id' in the map for Firestore
    // as it's already the document ID
    return {
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'businessName': businessName,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'productName': productName,
      'price': price,
      'description': description,
      'category': category,
      'likes': likes,
      'comments': comments,
      'views': views,
      'tags': tags,
      'location': location,
      'createdAt': createdAt,
      'isActive': isActive,
      'isFeatured': isFeatured,
    };
  }

  factory MarketplaceVideoModel.fromMap(Map<String, dynamic> map, {bool isLiked = false}) {
    final id = map['id'] ?? '';
    
    if (id.isEmpty) {
      debugPrint('WARNING: Creating MarketplaceVideoModel with empty ID');
    }
    
    return MarketplaceVideoModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userImage: map['userImage'] ?? '',
      businessName: map['businessName'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      productName: map['productName'] ?? '',
      price: map['price'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      views: map['views'] ?? 0,
      isLiked: isLiked,
      tags: List<String>.from(map['tags'] ?? []),
      location: map['location'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      isActive: map['isActive'] ?? true,
      isFeatured: map['isFeatured'] ?? false,
    );
  }

  MarketplaceVideoModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userImage,
    String? businessName,
    String? videoUrl,
    String? thumbnailUrl,
    String? productName,
    String? price,
    String? description,
    String? category,
    int? likes,
    int? comments,
    int? views,
    bool? isLiked,
    List<String>? tags,
    String? location,
    Timestamp? createdAt,
    bool? isActive,
    bool? isFeatured,
  }) {
    return MarketplaceVideoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      businessName: businessName ?? this.businessName,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      description: description ?? this.description,
      category: category ?? this.category,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      views: views ?? this.views,
      isLiked: isLiked ?? this.isLiked,
      tags: tags ?? this.tags,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }
}
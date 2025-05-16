import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:textgb/constants.dart';

class ChannelModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final String ownerImage;
  final String name;
  final String description;
  final String profileImage;
  final String coverImage;
  final int followers;
  final int videosCount;
  final int likesCount;
  final bool isVerified;
  final List<String> tags;
  final List<String> followerUIDs;
  final Timestamp createdAt;
  final bool isActive;
  final bool isFeatured;

  ChannelModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerImage,
    required this.name,
    required this.description,
    required this.profileImage,
    required this.coverImage,
    required this.followers,
    required this.videosCount,
    required this.likesCount,
    required this.isVerified,
    required this.tags,
    required this.followerUIDs,
    required this.createdAt,
    required this.isActive,
    required this.isFeatured,
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerImage': ownerImage,
      'name': name,
      'description': description,
      'profileImage': profileImage,
      'coverImage': coverImage,
      'followers': followers,
      'videosCount': videosCount,
      'likesCount': likesCount,
      'isVerified': isVerified,
      'tags': tags,
      'followerUIDs': followerUIDs,
      'createdAt': createdAt,
      'isActive': isActive,
      'isFeatured': isFeatured,
    };
  }

  factory ChannelModel.fromMap(Map<String, dynamic> map, String id) {
    if (id.isEmpty) {
      debugPrint('WARNING: Creating ChannelModel with empty ID');
    }
    
    return ChannelModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      ownerImage: map['ownerImage'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      profileImage: map['profileImage'] ?? '',
      coverImage: map['coverImage'] ?? '',
      followers: map['followers'] ?? 0,
      videosCount: map['videosCount'] ?? 0,
      likesCount: map['likesCount'] ?? 0,
      isVerified: map['isVerified'] ?? false,
      tags: List<String>.from(map['tags'] ?? []),
      followerUIDs: List<String>.from(map['followerUIDs'] ?? []),
      createdAt: map['createdAt'] ?? Timestamp.now(),
      isActive: map['isActive'] ?? true,
      isFeatured: map['isFeatured'] ?? false,
    );
  }

  ChannelModel copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    String? ownerImage,
    String? name,
    String? description,
    String? profileImage,
    String? coverImage,
    int? followers,
    int? videosCount,
    int? likesCount,
    bool? isVerified,
    List<String>? tags,
    List<String>? followerUIDs,
    Timestamp? createdAt,
    bool? isActive,
    bool? isFeatured,
  }) {
    return ChannelModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerImage: ownerImage ?? this.ownerImage,
      name: name ?? this.name,
      description: description ?? this.description,
      profileImage: profileImage ?? this.profileImage,
      coverImage: coverImage ?? this.coverImage,
      followers: followers ?? this.followers,
      videosCount: videosCount ?? this.videosCount,
      likesCount: likesCount ?? this.likesCount,
      isVerified: isVerified ?? this.isVerified,
      tags: tags ?? this.tags,
      followerUIDs: followerUIDs ?? this.followerUIDs,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }
}
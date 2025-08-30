// lib/features/users/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:textgb/constants.dart';

class UserModel {
  final String id;
  final String phoneNumber;
  final String name;
  final String about;
  final String profileImage;
  final String coverImage;
  final int followers;
  final int following;
  final int videosCount;
  final int likesCount;
  final bool isVerified;
  final List<String> tags;
  final List<String> followerUIDs;
  final List<String> followingUIDs;
  final Timestamp createdAt;
  final Timestamp? lastPostAt;
  final bool isActive;
  final bool isFeatured;

  UserModel({
    required this.id,
    required this.phoneNumber,
    required this.name,
    required this.about,
    required this.profileImage,
    required this.coverImage,
    required this.followers,
    required this.following,
    required this.videosCount,
    required this.likesCount,
    required this.isVerified,
    required this.tags,
    required this.followerUIDs,
    required this.followingUIDs,
    required this.createdAt,
    this.lastPostAt,
    required this.isActive,
    required this.isFeatured,
  });

  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'name': name,
      'about': about,
      'profileImage': profileImage,
      'coverImage': coverImage,
      'followers': followers,
      'following': following,
      'videosCount': videosCount,
      'likesCount': likesCount,
      'isVerified': isVerified,
      'tags': tags,
      'followerUIDs': followerUIDs,
      'followingUIDs': followingUIDs,
      'createdAt': createdAt,
      'lastPostAt': lastPostAt,
      'isActive': isActive,
      'isFeatured': isFeatured,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    if (id.isEmpty) {
      debugPrint('WARNING: Creating UserModel with empty ID');
    }
    
    return UserModel(
      id: id,
      phoneNumber: map['phoneNumber'] ?? '',
      name: map['name'] ?? '',
      about: map['about'] ?? '',
      profileImage: map['profileImage'] ?? '',
      coverImage: map['coverImage'] ?? '',
      followers: map['followers'] ?? 0,
      following: map['following'] ?? 0,
      videosCount: map['videosCount'] ?? 0,
      likesCount: map['likesCount'] ?? 0,
      isVerified: map['isVerified'] ?? false,
      tags: List<String>.from(map['tags'] ?? []),
      followerUIDs: List<String>.from(map['followerUIDs'] ?? []),
      followingUIDs: List<String>.from(map['followingUIDs'] ?? []),
      createdAt: map['createdAt'] ?? Timestamp.now(),
      lastPostAt: map['lastPostAt'],
      isActive: map['isActive'] ?? true,
      isFeatured: map['isFeatured'] ?? false,
    );
  }

  UserModel copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    String? about,
    String? profileImage,
    String? coverImage,
    int? followers,
    int? following,
    int? videosCount,
    int? likesCount,
    bool? isVerified,
    List<String>? tags,
    List<String>? followerUIDs,
    List<String>? followingUIDs,
    Timestamp? createdAt,
    Timestamp? lastPostAt,
    bool? isActive,
    bool? isFeatured,
  }) {
    return UserModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      about: about ?? this.about,
      profileImage: profileImage ?? this.profileImage,
      coverImage: coverImage ?? this.coverImage,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      videosCount: videosCount ?? this.videosCount,
      likesCount: likesCount ?? this.likesCount,
      isVerified: isVerified ?? this.isVerified,
      tags: tags ?? this.tags,
      followerUIDs: followerUIDs ?? this.followerUIDs,
      followingUIDs: followingUIDs ?? this.followingUIDs,
      createdAt: createdAt ?? this.createdAt,
      lastPostAt: lastPostAt ?? this.lastPostAt,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, phoneNumber: $phoneNumber)';
  }
}
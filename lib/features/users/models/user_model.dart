// lib/features/users/models/user_model.dart
import 'package:flutter/material.dart';

class UserModel {
  final String uid;  // Using uid to match Go backend
  final String phoneNumber;
  final String name;
  final String bio;  // Changed from 'about' to 'bio'
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
  final List<String> likedVideos;  // Added for Go backend
  final String createdAt;  // Changed to String for RFC3339 format
  final String updatedAt;  // Added for Go backend
  final String lastSeen;   // Added for Go backend
  final bool isActive;
  final bool isFeatured;

  UserModel({
    required this.uid,
    required this.phoneNumber,
    required this.name,
    required this.bio,
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
    required this.likedVideos,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSeen,
    required this.isActive,
    required this.isFeatured,
  });

  // Factory constructor for creating user from Go backend data
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? map['id'] ?? '',  // Support both for compatibility
      phoneNumber: map['phoneNumber'] ?? '',
      name: map['name'] ?? '',
      bio: map['bio'] ?? '',
      profileImage: map['profileImage'] ?? '',
      coverImage: map['coverImage'] ?? '',
      followers: map['followersCount'] ?? 0,  // Updated mapping
      following: map['followingCount'] ?? 0,  // Updated mapping
      videosCount: map['videosCount'] ?? 0,
      likesCount: map['likesCount'] ?? 0,
      isVerified: map['isVerified'] ?? false,
      tags: List<String>.from(map['tags'] ?? []),
      followerUIDs: List<String>.from(map['followerUIDs'] ?? []),
      followingUIDs: List<String>.from(map['followingUIDs'] ?? []),
      likedVideos: List<String>.from(map['likedVideos'] ?? []),
      createdAt: map['createdAt'] ?? '',
      updatedAt: map['updatedAt'] ?? '',
      lastSeen: map['lastSeen'] ?? '',
      isActive: map['isActive'] ?? true,
      isFeatured: map['isFeatured'] ?? false,
    );
  }

  // Create method for new users (PHONE-ONLY)
  factory UserModel.create({
    required String uid,
    required String name,
    required String phoneNumber,
    required String profileImage,
    required String bio,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    return UserModel(
      uid: uid,
      phoneNumber: phoneNumber,
      name: name,
      bio: bio,
      profileImage: profileImage,
      coverImage: '',
      followers: 0,
      following: 0,
      videosCount: 0,
      likesCount: 0,
      isVerified: false,
      tags: [],
      followerUIDs: [],
      followingUIDs: [],
      likedVideos: [],
      createdAt: now,
      updatedAt: now,
      lastSeen: now,
      isActive: true,
      isFeatured: false,
    );
  }

  // FIXED: Updated toMap method to match Go backend schema
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'coverImage': coverImage,
      'bio': bio,
      'userType': 'user', // Add this field that Go backend expects
      'followersCount': followers,
      'followingCount': following,
      'videosCount': videosCount,
      'likesCount': likesCount,
      'isVerified': isVerified,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'tags': tags, // This should work now as an array
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastSeen': lastSeen,
      // REMOVED these fields that don't exist in Go backend:
      // 'followerUIDs': followerUIDs,
      // 'followingUIDs': followingUIDs, 
      // 'likedVideos': likedVideos,
    };
  }

  UserModel copyWith({
    String? uid,
    String? phoneNumber,
    String? name,
    String? bio,
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
    List<String>? likedVideos,
    String? createdAt,
    String? updatedAt,
    String? lastSeen,
    bool? isActive,
    bool? isFeatured,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      bio: bio ?? this.bio,
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
      likedVideos: likedVideos ?? this.likedVideos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }

  // Getter for backward compatibility
  String get id => uid;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;

  get lastPostAt => null;

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, phoneNumber: $phoneNumber)';
  }
}
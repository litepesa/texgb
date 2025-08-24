// lib/features/series/models/series_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SeriesModel {
  final String id;
  final String creatorId;
  final String creatorName;
  final String creatorPhoneNumber;
  final String creatorImage;
  final String title;
  final String description;
  final String thumbnailImage;           // Series thumbnail
  final String coverImage;               // Series banner/cover
  final int subscribers;
  final int episodeCount;
  final int totalDurationSeconds;        // Sum of all episode durations
  final int likesCount;
  final bool isVerified;
  final bool isPublished;                // Backend controlled - key field
  final Timestamp? publishedAt;
  final List<String> tags;
  final List<String> subscriberUIDs;
  final Timestamp createdAt;
  final Timestamp? lastEpisodeAt;
  final bool isActive;
  final bool isFeatured;                 // Featured series appear more prominently
  
  // Monetization fields
  final int freeEpisodeCount;            // First X episodes are free
  final double seriesPrice;              // Price to unlock paid episodes (min KES 100)
  final bool hasPaywall;                 // True if series has paid episodes
  
  // Episode management
  final int maxEpisodes;                 // Default 100
  final int nextEpisodeNumber;           // Auto-increment for new episodes
  final int featuredEpisodeCount;        // Track featured episodes (max 5)

  SeriesModel({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.creatorPhoneNumber,
    required this.creatorImage,
    required this.title,
    required this.description,
    required this.thumbnailImage,
    required this.coverImage,
    required this.subscribers,
    required this.episodeCount,
    required this.totalDurationSeconds,
    required this.likesCount,
    required this.isVerified,
    required this.isPublished,
    this.publishedAt,
    required this.tags,
    required this.subscriberUIDs,
    required this.createdAt,
    this.lastEpisodeAt,
    required this.isActive,
    required this.isFeatured,
    required this.freeEpisodeCount,
    required this.seriesPrice,
    required this.hasPaywall,
    this.maxEpisodes = 100,
    this.nextEpisodeNumber = 1,
    this.featuredEpisodeCount = 0,
  });

  // Helper getters
  String get formattedTotalDuration {
    final minutes = totalDurationSeconds ~/ 60;
    final seconds = totalDurationSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  String get formattedPrice {
    if (!hasPaywall || seriesPrice == 0) return 'Free';
    return 'KES ${seriesPrice.toInt()}';
  }

  bool get canAddMoreEpisodes => episodeCount < maxEpisodes;
  int get remainingEpisodeSlots => maxEpisodes - episodeCount;
  int get paidEpisodeCount => episodeCount > freeEpisodeCount ? episodeCount - freeEpisodeCount : 0;
  
  // Featured episodes management
  bool get canAddMoreFeaturedEpisodes => featuredEpisodeCount < 5;
  int get remainingFeaturedSlots => 5 - featuredEpisodeCount;
  
  // Paywall helpers
  bool get isEntirelyFree => !hasPaywall; // Entire series is free

  // Check if user needs to pay to access episode
  bool isEpisodeLocked(int episodeNumber) {
    return hasPaywall && episodeNumber > freeEpisodeCount;
  }

  Map<String, dynamic> toMap() {
    return {
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorPhoneNumber': creatorPhoneNumber,
      'creatorImage': creatorImage,
      'title': title,
      'description': description,
      'thumbnailImage': thumbnailImage,
      'coverImage': coverImage,
      'subscribers': subscribers,
      'episodeCount': episodeCount,
      'totalDurationSeconds': totalDurationSeconds,
      'likesCount': likesCount,
      'isVerified': isVerified,
      'isPublished': isPublished,
      'publishedAt': publishedAt,
      'tags': tags,
      'subscriberUIDs': subscriberUIDs,
      'createdAt': createdAt,
      'lastEpisodeAt': lastEpisodeAt,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'freeEpisodeCount': freeEpisodeCount,
      'seriesPrice': seriesPrice,
      'hasPaywall': hasPaywall,
      'maxEpisodes': maxEpisodes,
      'nextEpisodeNumber': nextEpisodeNumber,
      'featuredEpisodeCount': featuredEpisodeCount,
    };
  }

  factory SeriesModel.fromMap(Map<String, dynamic> map, String id) {
    if (id.isEmpty) {
      debugPrint('WARNING: Creating SeriesModel with empty ID');
    }
    
    return SeriesModel(
      id: id,
      creatorId: map['creatorId'] ?? '',
      creatorName: map['creatorName'] ?? '',
      creatorPhoneNumber: map['creatorPhoneNumber'] ?? '',
      creatorImage: map['creatorImage'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      thumbnailImage: map['thumbnailImage'] ?? '',
      coverImage: map['coverImage'] ?? '',
      subscribers: map['subscribers'] ?? 0,
      episodeCount: map['episodeCount'] ?? 0,
      totalDurationSeconds: map['totalDurationSeconds'] ?? 0,
      likesCount: map['likesCount'] ?? 0,
      isVerified: map['isVerified'] ?? false,
      isPublished: map['isPublished'] ?? false, // Key: defaults to false
      publishedAt: map['publishedAt'],
      tags: List<String>.from(map['tags'] ?? []),
      subscriberUIDs: List<String>.from(map['subscriberUIDs'] ?? []),
      createdAt: map['createdAt'] ?? Timestamp.now(),
      lastEpisodeAt: map['lastEpisodeAt'],
      isActive: map['isActive'] ?? true,
      isFeatured: map['isFeatured'] ?? false,
      freeEpisodeCount: map['freeEpisodeCount'] ?? 0,
      seriesPrice: (map['seriesPrice'] ?? 0.0).toDouble(),
      hasPaywall: map['hasPaywall'] ?? false,
      maxEpisodes: map['maxEpisodes'] ?? 100,
      nextEpisodeNumber: map['nextEpisodeNumber'] ?? 1,
      featuredEpisodeCount: map['featuredEpisodeCount'] ?? 0,
    );
  }

  SeriesModel copyWith({
    String? id,
    String? creatorId,
    String? creatorName,
    String? creatorPhoneNumber,
    String? creatorImage,
    String? title,
    String? description,
    String? thumbnailImage,
    String? coverImage,
    int? subscribers,
    int? episodeCount,
    int? totalDurationSeconds,
    int? likesCount,
    bool? isVerified,
    bool? isPublished,
    Timestamp? publishedAt,
    List<String>? tags,
    List<String>? subscriberUIDs,
    Timestamp? createdAt,
    Timestamp? lastEpisodeAt,
    bool? isActive,
    bool? isFeatured,
    int? freeEpisodeCount,
    double? seriesPrice,
    bool? hasPaywall,
    int? maxEpisodes,
    int? nextEpisodeNumber,
    int? featuredEpisodeCount,
  }) {
    return SeriesModel(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorPhoneNumber: creatorPhoneNumber ?? this.creatorPhoneNumber,
      creatorImage: creatorImage ?? this.creatorImage,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailImage: thumbnailImage ?? this.thumbnailImage,
      coverImage: coverImage ?? this.coverImage,
      subscribers: subscribers ?? this.subscribers,
      episodeCount: episodeCount ?? this.episodeCount,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      likesCount: likesCount ?? this.likesCount,
      isVerified: isVerified ?? this.isVerified,
      isPublished: isPublished ?? this.isPublished,
      publishedAt: publishedAt ?? this.publishedAt,
      tags: tags ?? this.tags,
      subscriberUIDs: subscriberUIDs ?? this.subscriberUIDs,
      createdAt: createdAt ?? this.createdAt,
      lastEpisodeAt: lastEpisodeAt ?? this.lastEpisodeAt,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      freeEpisodeCount: freeEpisodeCount ?? this.freeEpisodeCount,
      seriesPrice: seriesPrice ?? this.seriesPrice,
      hasPaywall: hasPaywall ?? this.hasPaywall,
      maxEpisodes: maxEpisodes ?? this.maxEpisodes,
      nextEpisodeNumber: nextEpisodeNumber ?? this.nextEpisodeNumber,
      featuredEpisodeCount: featuredEpisodeCount ?? this.featuredEpisodeCount,
    );
  }

  @override
  String toString() {
    return 'SeriesModel(id: $id, title: $title, episodes: $episodeCount, published: $isPublished, paywall: $hasPaywall)';
  }
}


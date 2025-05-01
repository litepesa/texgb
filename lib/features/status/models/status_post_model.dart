// lib/features/status/models/status_post_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';

class StatusPost {
  final String id;
  final String userId;
  final String userName;
  final String userImage;
  final String content;
  final List<String> mediaUrls;
  final StatusType type;
  final int timestamp;
  final List<String> likes;
  final int commentCount;
  final StatusPrivacyType privacyType;
  final List<String> visibleTo;
  final List<String> hiddenFrom;
  final Map<String, dynamic>? location;

  StatusPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.content,
    required this.mediaUrls,
    required this.type,
    required this.timestamp,
    required this.likes,
    required this.commentCount,
    required this.privacyType,
    required this.visibleTo,
    required this.hiddenFrom,
    this.location,
  });

  // Create from map (Firestore document)
  factory StatusPost.fromMap(Map<String, dynamic> map) {
    return StatusPost(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userImage: map['userImage'] ?? '',
      content: map['content'] ?? '',
      mediaUrls: List<String>.from(map['mediaUrls'] ?? []),
      type: StatusTypeExtension.fromString(map['type'] ?? 'text'),
      timestamp: map['timestamp'] ?? 0,
      likes: List<String>.from(map['likes'] ?? []),
      commentCount: map['commentCount'] ?? 0,
      privacyType: StatusPrivacyTypeExtension.fromString(map['privacyType'] ?? 'all_contacts'),
      visibleTo: List<String>.from(map['visibleTo'] ?? []),
      hiddenFrom: List<String>.from(map['hiddenFrom'] ?? []),
      location: map['location'],
    );
  }

  // Convert to map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'content': content,
      'mediaUrls': mediaUrls,
      'type': type.name,
      'timestamp': timestamp,
      'likes': likes,
      'commentCount': commentCount,
      'privacyType': privacyType.toString().split('.').last,
      'visibleTo': visibleTo,
      'hiddenFrom': hiddenFrom,
      'location': location,
    };
  }

  // Create a copy with changes
  StatusPost copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userImage,
    String? content,
    List<String>? mediaUrls,
    StatusType? type,
    int? timestamp,
    List<String>? likes,
    int? commentCount,
    StatusPrivacyType? privacyType,
    List<String>? visibleTo,
    List<String>? hiddenFrom,
    Map<String, dynamic>? location,
  }) {
    return StatusPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
      privacyType: privacyType ?? this.privacyType,
      visibleTo: visibleTo ?? this.visibleTo,
      hiddenFrom: hiddenFrom ?? this.hiddenFrom,
      location: location ?? this.location,
    );
  }
}

// Comment model for status posts
class StatusComment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String userImage;
  final String content;
  final int timestamp;
  final List<String> likes;

  StatusComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.content,
    required this.timestamp,
    required this.likes,
  });

  factory StatusComment.fromMap(Map<String, dynamic> map) {
    return StatusComment(
      id: map['id'] ?? '',
      postId: map['postId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userImage: map['userImage'] ?? '',
      content: map['content'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      likes: List<String>.from(map['likes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'content': content,
      'timestamp': timestamp,
      'likes': likes,
    };
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

enum StatusType {
  text,
  image,
  video,
  multiImage, // For multiple images in one post
}

class CommentModel {
  final String commentId;
  final String uid;
  final String userName;
  final String userImage;
  final String text;
  final DateTime createdAt;

  CommentModel({
    required this.commentId,
    required this.uid, 
    required this.userName,
    required this.userImage,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'uid': uid,
      'userName': userName,
      'userImage': userImage,
      'text': text,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      commentId: map['commentId'] ?? '',
      uid: map['uid'] ?? '',
      userName: map['userName'] ?? '',
      userImage: map['userImage'] ?? '',
      text: map['text'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }
}

class StatusModel {
  final String statusId;
  final String uid;
  final String userName;
  final String userImage;
  final String statusUrl; // Main URL (used for single image/video)
  final List<String>? mediaUrls; // For multiple images
  final String caption;
  final StatusType statusType;
  final DateTime createdAt;
  final List<String> likedBy;
  final List<String> viewedBy;
  final List<CommentModel> comments;
  final String? location;
  final String? backgroundColor; // For text statuses
  final String? textColor; // For text statuses
  final String? fontStyle; // For text statuses

  StatusModel({
    required this.statusId,
    required this.uid,
    required this.userName,
    required this.userImage,
    required this.statusUrl,
    this.mediaUrls,
    required this.caption,
    required this.statusType,
    required this.createdAt,
    required this.likedBy,
    required this.viewedBy,
    required this.comments,
    this.location,
    this.backgroundColor,
    this.textColor,
    this.fontStyle,
  });
  
  // Create a copy with modified fields
  StatusModel copyWith({
    String? statusId,
    String? uid,
    String? userName,
    String? userImage,
    String? statusUrl,
    List<String>? mediaUrls,
    String? caption,
    StatusType? statusType,
    DateTime? createdAt,
    List<String>? likedBy,
    List<String>? viewedBy,
    List<CommentModel>? comments,
    String? location,
    String? backgroundColor,
    String? textColor,
    String? fontStyle,
  }) {
    return StatusModel(
      statusId: statusId ?? this.statusId,
      uid: uid ?? this.uid,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      statusUrl: statusUrl ?? this.statusUrl,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      caption: caption ?? this.caption,
      statusType: statusType ?? this.statusType,
      createdAt: createdAt ?? this.createdAt,
      likedBy: likedBy ?? this.likedBy,
      viewedBy: viewedBy ?? this.viewedBy,
      comments: comments ?? this.comments,
      location: location ?? this.location,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      fontStyle: fontStyle ?? this.fontStyle,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'statusId': statusId,
      'uid': uid,
      'userName': userName,
      'userImage': userImage,
      'statusUrl': statusUrl,
      'mediaUrls': mediaUrls,
      'caption': caption,
      'statusType': statusType.toString().split('.').last,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'likedBy': likedBy,
      'viewedBy': viewedBy,
      'comments': comments.map((comment) => comment.toMap()).toList(),
      'location': location,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'fontStyle': fontStyle,
    };
  }

  factory StatusModel.fromMap(Map<String, dynamic> map) {
    return StatusModel(
      statusId: map['statusId'] ?? '',
      uid: map['uid'] ?? '',
      userName: map['userName'] ?? '',
      userImage: map['userImage'] ?? '',
      statusUrl: map['statusUrl'] ?? '',
      mediaUrls: map['mediaUrls'] != null 
        ? List<String>.from(map['mediaUrls']) 
        : null,
      caption: map['caption'] ?? '',
      statusType: _parseStatusType(map['statusType']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      likedBy: map['likedBy'] != null 
        ? List<String>.from(map['likedBy']) 
        : [],
      viewedBy: map['viewedBy'] != null 
        ? List<String>.from(map['viewedBy']) 
        : [],
      comments: map['comments'] != null 
        ? List<CommentModel>.from(
            (map['comments'] as List).map((comment) => CommentModel.fromMap(comment)))
        : [],
      location: map['location'],
      backgroundColor: map['backgroundColor'],
      textColor: map['textColor'],
      fontStyle: map['fontStyle'],
    );
  }
  
  // Helper method to parse StatusType enum from string
  static StatusType _parseStatusType(String? typeString) {
    if (typeString == 'image') return StatusType.image;
    if (typeString == 'video') return StatusType.video;
    if (typeString == 'multiImage') return StatusType.multiImage;
    if (typeString == 'text') return StatusType.text;
    return StatusType.image; // Default to image
  }
}
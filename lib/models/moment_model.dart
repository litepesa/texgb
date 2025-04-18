import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:textgb/constants.dart';

class MomentModel {
  final String momentId;
  final String uid;
  final String userName;
  final String userImage;
  final String text;
  final List<String> mediaUrls;
  final bool isVideo;
  final DateTime createdAt;
  final List<String> likedBy;
  final List<String> viewedBy;
  final List<CommentModel> comments;
  final String location;

  MomentModel({
    required this.momentId,
    required this.uid,
    required this.userName,
    required this.userImage,
    required this.text,
    required this.mediaUrls,
    required this.isVideo,
    required this.createdAt,
    required this.likedBy,
    required this.viewedBy,
    required this.comments,
    this.location = '',
  });

  // Create from map (Firestore document)
  factory MomentModel.fromMap(Map<String, dynamic> map) {
    List<CommentModel> commentsList = [];
    if (map['comments'] != null) {
      commentsList = List<CommentModel>.from(
        (map['comments'] as List).map(
          (comment) => CommentModel.fromMap(comment),
        ),
      );
    }

    return MomentModel(
      momentId: map['momentId'] ?? '',
      uid: map['uid'] ?? '',
      userName: map['userName'] ?? '',
      userImage: map['userImage'] ?? '',
      text: map['text'] ?? '',
      mediaUrls: List<String>.from(map['mediaUrls'] ?? []),
      isVideo: map['isVideo'] ?? false,
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      likedBy: List<String>.from(map['likedBy'] ?? []),
      viewedBy: List<String>.from(map['viewedBy'] ?? []),
      comments: commentsList,
      location: map['location'] ?? '',
    );
  }

  // Convert to map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'momentId': momentId,
      'uid': uid,
      'userName': userName,
      'userImage': userImage,
      'text': text,
      'mediaUrls': mediaUrls,
      'isVideo': isVideo,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'likedBy': likedBy,
      'viewedBy': viewedBy,
      'comments': comments.map((comment) => comment.toMap()).toList(),
      'location': location,
    };
  }

  // Create a copy with changes
  MomentModel copyWith({
    String? momentId,
    String? uid,
    String? userName,
    String? userImage,
    String? text,
    List<String>? mediaUrls,
    bool? isVideo,
    DateTime? createdAt,
    List<String>? likedBy,
    List<String>? viewedBy,
    List<CommentModel>? comments,
    String? location,
  }) {
    return MomentModel(
      momentId: momentId ?? this.momentId,
      uid: uid ?? this.uid,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      text: text ?? this.text,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      isVideo: isVideo ?? this.isVideo,
      createdAt: createdAt ?? this.createdAt,
      likedBy: likedBy ?? this.likedBy,
      viewedBy: viewedBy ?? this.viewedBy,
      comments: comments ?? this.comments,
      location: location ?? this.location,
    );
  }
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

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      commentId: map['commentId'] ?? '',
      uid: map['uid'] ?? '',
      userName: map['userName'] ?? '',
      userImage: map['userImage'] ?? '',
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

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
}
import 'package:textgb/constants.dart';

class VideoModel {
  final String id;
  final String userId;
  final String userName;
  final String userImage;
  final String videoUrl;
  final String caption;
  final String songName;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final List<String> likedBy;
  final int viewCount;
  final String createdAt;
  final int duration; // in seconds

  VideoModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.videoUrl,
    required this.caption,
    required this.songName,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.likedBy,
    required this.viewCount,
    required this.createdAt,
    required this.duration,
  });

  factory VideoModel.fromMap(Map<String, dynamic> map) {
    return VideoModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userImage: map['userImage'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      caption: map['caption'] ?? '',
      songName: map['songName'] ?? '',
      likesCount: map['likesCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      sharesCount: map['sharesCount'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      viewCount: map['viewCount'] ?? 0,
      createdAt: map['createdAt'] ?? '',
      duration: map['duration'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'videoUrl': videoUrl,
      'caption': caption,
      'songName': songName,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'likedBy': likedBy,
      'viewCount': viewCount,
      'createdAt': createdAt,
      'duration': duration,
    };
  }
}
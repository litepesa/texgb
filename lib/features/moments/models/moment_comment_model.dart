// lib/features/moments/models/moment_comment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:textgb/constants.dart';

class MomentCommentModel {
  final String id;
  final String momentId;
  final String authorId;
  final String authorName;
  final String authorImage;
  final String content;
  final DateTime createdAt;
  final String? repliedToCommentId;
  final String? repliedToAuthorName;
  final int likesCount;
  final List<String> likedBy;

  const MomentCommentModel({
    required this.id,
    required this.momentId,
    required this.authorId,
    required this.authorName,
    required this.authorImage,
    required this.content,
    required this.createdAt,
    this.repliedToCommentId,
    this.repliedToAuthorName,
    required this.likesCount,
    required this.likedBy,
  });

  factory MomentCommentModel.fromMap(Map<String, dynamic> map) {
    return MomentCommentModel(
      id: map[Constants.commentId]?.toString() ?? '',
      momentId: map[Constants.momentId]?.toString() ?? '',
      authorId: map[Constants.authorUID]?.toString() ?? '',
      authorName: map[Constants.authorName]?.toString() ?? '',
      authorImage: map[Constants.authorImage]?.toString() ?? '',
      content: map[Constants.content]?.toString() ?? '',
      createdAt: (map[Constants.createdAt] as Timestamp?)?.toDate() ?? DateTime.now(),
      repliedToCommentId: map[Constants.repliedToCommentId]?.toString(),
      repliedToAuthorName: map[Constants.repliedToAuthorName]?.toString(),
      likesCount: map[Constants.likesCount]?.toInt() ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      Constants.commentId: id,
      Constants.momentId: momentId,
      Constants.authorUID: authorId,
      Constants.authorName: authorName,
      Constants.authorImage: authorImage,
      Constants.content: content,
      Constants.createdAt: Timestamp.fromDate(createdAt),
      Constants.repliedToCommentId: repliedToCommentId,
      Constants.repliedToAuthorName: repliedToAuthorName,
      Constants.likesCount: likesCount,
      'likedBy': likedBy,
    };
  }

  MomentCommentModel copyWith({
    String? id,
    String? momentId,
    String? authorId,
    String? authorName,
    String? authorImage,
    String? content,
    DateTime? createdAt,
    String? repliedToCommentId,
    String? repliedToAuthorName,
    int? likesCount,
    List<String>? likedBy,
  }) {
    return MomentCommentModel(
      id: id ?? this.id,
      momentId: momentId ?? this.momentId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorImage: authorImage ?? this.authorImage,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      repliedToCommentId: repliedToCommentId ?? this.repliedToCommentId,
      repliedToAuthorName: repliedToAuthorName ?? this.repliedToAuthorName,
      likesCount: likesCount ?? this.likesCount,
      likedBy: likedBy ?? this.likedBy,
    );
  }

  bool get isReply => repliedToCommentId != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MomentCommentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MomentCommentModel(id: $id, momentId: $momentId, authorName: $authorName)';
  }
}
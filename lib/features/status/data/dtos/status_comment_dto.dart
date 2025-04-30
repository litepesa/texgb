import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/models/status_comment.dart';

part 'status_comment_dto.freezed.dart';
part 'status_comment_dto.g.dart';

@freezed
class StatusCommentDTO with _$StatusCommentDTO {
  const factory StatusCommentDTO({
    required String id,
    required String postId,
    required String userId,
    required String userName,
    required String userImage,
    required String content,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson) 
    required DateTime createdAt,
    @Default(false) bool isEdited,
    String? replyToCommentId,
    String? replyToUserId,
    String? replyToUserName,
  }) = _StatusCommentDTO;

  factory StatusCommentDTO.fromJson(Map<String, dynamic> json) => _$StatusCommentDTOFromJson(json);

  factory StatusCommentDTO.fromDomain(StatusComment domain) {
    return StatusCommentDTO(
      id: domain.id,
      postId: domain.postId,
      userId: domain.userId,
      userName: domain.userName,
      userImage: domain.userImage,
      content: domain.content,
      createdAt: domain.createdAt,
      isEdited: domain.isEdited,
      replyToCommentId: domain.replyToCommentId,
      replyToUserId: domain.replyToUserId,
      replyToUserName: domain.replyToUserName,
    );
  }

  StatusComment toDomain() {
    return StatusComment(
      id: id,
      postId: postId,
      userId: userId,
      userName: userName,
      userImage: userImage,
      content: content,
      createdAt: createdAt,
      isEdited: isEdited,
      replyToCommentId: replyToCommentId,
      replyToUserId: replyToUserId,
      replyToUserName: replyToUserName,
    );
  }
}

// Helper methods for DateTime conversion
DateTime _dateTimeFromJson(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return timestamp.toDate();
  } else if (timestamp is String) {
    return DateTime.parse(timestamp);
  }
  return DateTime.now();
}

String _dateTimeToJson(DateTime dateTime) {
  return dateTime.toIso8601String();
}
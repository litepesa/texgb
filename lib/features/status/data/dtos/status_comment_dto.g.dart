// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_comment_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StatusCommentDTO _$StatusCommentDTOFromJson(Map<String, dynamic> json) =>
    _StatusCommentDTO(
      id: json['id'] as String,
      postId: json['postId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userImage: json['userImage'] as String,
      content: json['content'] as String,
      createdAt: _dateTimeFromJson(json['createdAt']),
      isEdited: json['isEdited'] as bool? ?? false,
      replyToCommentId: json['replyToCommentId'] as String?,
      replyToUserId: json['replyToUserId'] as String?,
      replyToUserName: json['replyToUserName'] as String?,
    );

Map<String, dynamic> _$StatusCommentDTOToJson(_StatusCommentDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'postId': instance.postId,
      'userId': instance.userId,
      'userName': instance.userName,
      'userImage': instance.userImage,
      'content': instance.content,
      'createdAt': _dateTimeToJson(instance.createdAt),
      'isEdited': instance.isEdited,
      'replyToCommentId': instance.replyToCommentId,
      'replyToUserId': instance.replyToUserId,
      'replyToUserName': instance.replyToUserName,
    };

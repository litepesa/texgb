// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_reaction_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StatusReactionDTO _$StatusReactionDTOFromJson(Map<String, dynamic> json) =>
    _StatusReactionDTO(
      id: json['id'] as String,
      postId: json['postId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userImage: json['userImage'] as String,
      type: _reactionTypeFromJson(json['type'] as String),
      createdAt: _dateTimeFromJson(json['createdAt']),
    );

Map<String, dynamic> _$StatusReactionDTOToJson(_StatusReactionDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'postId': instance.postId,
      'userId': instance.userId,
      'userName': instance.userName,
      'userImage': instance.userImage,
      'type': _reactionTypeToJson(instance.type),
      'createdAt': _dateTimeToJson(instance.createdAt),
    };

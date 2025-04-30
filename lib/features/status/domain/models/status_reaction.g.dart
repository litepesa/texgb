// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_reaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StatusReaction _$StatusReactionFromJson(Map<String, dynamic> json) =>
    _StatusReaction(
      id: json['id'] as String,
      postId: json['postId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userImage: json['userImage'] as String,
      type: $enumDecode(_$ReactionTypeEnumMap, json['type']),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$StatusReactionToJson(_StatusReaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'postId': instance.postId,
      'userId': instance.userId,
      'userName': instance.userName,
      'userImage': instance.userImage,
      'type': _$ReactionTypeEnumMap[instance.type]!,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$ReactionTypeEnumMap = {
  ReactionType.like: 'like',
  ReactionType.love: 'love',
  ReactionType.haha: 'haha',
  ReactionType.wow: 'wow',
  ReactionType.sad: 'sad',
  ReactionType.angry: 'angry',
};

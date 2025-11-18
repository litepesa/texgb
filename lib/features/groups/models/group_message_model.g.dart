// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GroupMessageModel _$GroupMessageModelFromJson(Map<String, dynamic> json) =>
    _GroupMessageModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      senderId: json['sender_id'] as String,
      messageText: json['message_text'] as String,
      mediaUrl: json['media_url'] as String?,
      mediaType:
          $enumDecodeNullable(_$MessageMediaTypeEnumMap, json['media_type']) ??
              MessageMediaType.text,
      readBy: (json['read_by'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      insertedAt: DateTime.parse(json['inserted_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      senderName: json['sender_name'] as String?,
      senderImage: json['sender_image'] as String?,
    );

Map<String, dynamic> _$GroupMessageModelToJson(_GroupMessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'group_id': instance.groupId,
      'sender_id': instance.senderId,
      'message_text': instance.messageText,
      'media_url': instance.mediaUrl,
      'media_type': _$MessageMediaTypeEnumMap[instance.mediaType]!,
      'read_by': instance.readBy,
      'inserted_at': instance.insertedAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'sender_name': instance.senderName,
      'sender_image': instance.senderImage,
    };

const _$MessageMediaTypeEnumMap = {
  MessageMediaType.text: 'text',
  MessageMediaType.image: 'image',
  MessageMediaType.video: 'video',
  MessageMediaType.audio: 'audio',
  MessageMediaType.file: 'file',
};

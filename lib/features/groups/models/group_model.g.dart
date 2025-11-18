// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GroupModel _$GroupModelFromJson(Map<String, dynamic> json) => _GroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      groupImageUrl: json['group_image_url'] as String?,
      creatorId: json['creator_id'] as String,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      maxMembers: (json['max_members'] as num?)?.toInt() ?? 256,
      lastMessageText: json['last_message_text'] as String?,
      lastMessageAt: json['last_message_at'] == null
          ? null
          : DateTime.parse(json['last_message_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      insertedAt: json['inserted_at'] == null
          ? null
          : DateTime.parse(json['inserted_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$GroupModelToJson(_GroupModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'group_image_url': instance.groupImageUrl,
      'creator_id': instance.creatorId,
      'member_count': instance.memberCount,
      'max_members': instance.maxMembers,
      'last_message_text': instance.lastMessageText,
      'last_message_at': instance.lastMessageAt?.toIso8601String(),
      'is_active': instance.isActive,
      'inserted_at': instance.insertedAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

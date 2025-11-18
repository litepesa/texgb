// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_member_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GroupMemberModel _$GroupMemberModelFromJson(Map<String, dynamic> json) =>
    _GroupMemberModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      role: $enumDecode(_$GroupMemberRoleEnumMap, json['role']),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      userName: json['user_name'] as String?,
      userImage: json['user_image'] as String?,
      userPhone: json['user_phone'] as String?,
    );

Map<String, dynamic> _$GroupMemberModelToJson(_GroupMemberModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'group_id': instance.groupId,
      'user_id': instance.userId,
      'role': _$GroupMemberRoleEnumMap[instance.role]!,
      'joined_at': instance.joinedAt.toIso8601String(),
      'user_name': instance.userName,
      'user_image': instance.userImage,
      'user_phone': instance.userPhone,
    };

const _$GroupMemberRoleEnumMap = {
  GroupMemberRole.admin: 'admin',
  GroupMemberRole.member: 'member',
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_privacy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StatusPrivacy _$StatusPrivacyFromJson(Map<String, dynamic> json) =>
    _StatusPrivacy(
      type: $enumDecode(_$PrivacyTypeEnumMap, json['type']),
      includedUserIds: (json['includedUserIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      excludedUserIds: (json['excludedUserIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      hideViewCount: json['hideViewCount'] as bool? ?? false,
    );

Map<String, dynamic> _$StatusPrivacyToJson(_StatusPrivacy instance) =>
    <String, dynamic>{
      'type': _$PrivacyTypeEnumMap[instance.type]!,
      'includedUserIds': instance.includedUserIds,
      'excludedUserIds': instance.excludedUserIds,
      'hideViewCount': instance.hideViewCount,
    };

const _$PrivacyTypeEnumMap = {
  PrivacyType.allContacts: 'allContacts',
  PrivacyType.except: 'except',
  PrivacyType.onlySpecific: 'onlySpecific',
};

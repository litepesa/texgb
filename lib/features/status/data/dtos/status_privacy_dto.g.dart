// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_privacy_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StatusPrivacyDTO _$StatusPrivacyDTOFromJson(Map<String, dynamic> json) =>
    _StatusPrivacyDTO(
      type: _privacyTypeFromJson(json['type'] as String),
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

Map<String, dynamic> _$StatusPrivacyDTOToJson(_StatusPrivacyDTO instance) =>
    <String, dynamic>{
      'type': _privacyTypeToJson(instance.type),
      'includedUserIds': instance.includedUserIds,
      'excludedUserIds': instance.excludedUserIds,
      'hideViewCount': instance.hideViewCount,
    };

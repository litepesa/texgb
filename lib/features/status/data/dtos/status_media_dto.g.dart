// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_media_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StatusMediaDTO _$StatusMediaDTOFromJson(Map<String, dynamic> json) =>
    _StatusMediaDTO(
      id: json['id'] as String,
      url: json['url'] as String,
      type: _mediaTypeFromJson(json['type'] as String),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      duration: (json['duration'] as num?)?.toInt(),
      size: (json['size'] as num?)?.toInt(),
    );

Map<String, dynamic> _$StatusMediaDTOToJson(_StatusMediaDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'type': _mediaTypeToJson(instance.type),
      'thumbnailUrl': instance.thumbnailUrl,
      'width': instance.width,
      'height': instance.height,
      'duration': instance.duration,
      'size': instance.size,
    };

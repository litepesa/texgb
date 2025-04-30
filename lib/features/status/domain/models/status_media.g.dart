// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_media.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StatusMedia _$StatusMediaFromJson(Map<String, dynamic> json) => _StatusMedia(
      id: json['id'] as String,
      url: json['url'] as String,
      type: $enumDecode(_$MediaTypeEnumMap, json['type']),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      duration: (json['duration'] as num?)?.toInt(),
      size: (json['size'] as num?)?.toInt(),
    );

Map<String, dynamic> _$StatusMediaToJson(_StatusMedia instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'type': _$MediaTypeEnumMap[instance.type]!,
      'thumbnailUrl': instance.thumbnailUrl,
      'width': instance.width,
      'height': instance.height,
      'duration': instance.duration,
      'size': instance.size,
    };

const _$MediaTypeEnumMap = {
  MediaType.image: 'image',
  MediaType.video: 'video',
  MediaType.gif: 'gif',
};

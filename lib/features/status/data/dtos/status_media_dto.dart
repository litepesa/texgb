import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/models/status_media.dart';

part 'status_media_dto.freezed.dart';
part 'status_media_dto.g.dart';

@freezed
class StatusMediaDTO with _$StatusMediaDTO {
  const factory StatusMediaDTO({
    required String id,
    required String url,
    @JsonKey(fromJson: _mediaTypeFromJson, toJson: _mediaTypeToJson)
    required MediaType type,
    String? thumbnailUrl,
    int? width,
    int? height,
    int? duration,
    int? size,
  }) = _StatusMediaDTO;

  factory StatusMediaDTO.fromJson(Map<String, dynamic> json) => _$StatusMediaDTOFromJson(json);

  factory StatusMediaDTO.fromDomain(StatusMedia domain) {
    return StatusMediaDTO(
      id: domain.id,
      url: domain.url,
      type: domain.type,
      thumbnailUrl: domain.thumbnailUrl,
      width: domain.width,
      height: domain.height,
      duration: domain.duration,
      size: domain.size,
    );
  }

  StatusMedia toDomain() {
    return StatusMedia(
      id: id,
      url: url,
      type: type,
      thumbnailUrl: thumbnailUrl,
      width: width,
      height: height,
      duration: duration,
      size: size,
    );
  }
}

// Helper methods for MediaType conversion
MediaType _mediaTypeFromJson(String value) {
  return MediaType.values.firstWhere(
    (e) => e.toString().split('.').last == value,
    orElse: () => MediaType.image,
  );
}

String _mediaTypeToJson(MediaType type) {
  return type.toString().split('.').last;
}
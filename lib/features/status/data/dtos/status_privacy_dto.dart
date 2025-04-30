import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/models/status_privacy.dart';

part 'status_privacy_dto.freezed.dart';
part 'status_privacy_dto.g.dart';

@freezed
class StatusPrivacyDTO with _$StatusPrivacyDTO {
  const factory StatusPrivacyDTO({
    @JsonKey(fromJson: _privacyTypeFromJson, toJson: _privacyTypeToJson)
    required PrivacyType type,
    @Default([]) List<String> includedUserIds,
    @Default([]) List<String> excludedUserIds,
    @Default(false) bool hideViewCount,
  }) = _StatusPrivacyDTO;

  factory StatusPrivacyDTO.fromJson(Map<String, dynamic> json) => _$StatusPrivacyDTOFromJson(json);

  factory StatusPrivacyDTO.fromDomain(StatusPrivacy domain) {
    return StatusPrivacyDTO(
      type: domain.type,
      includedUserIds: domain.includedUserIds,
      excludedUserIds: domain.excludedUserIds,
      hideViewCount: domain.hideViewCount,
    );
  }

  StatusPrivacy toDomain() {
    return StatusPrivacy(
      type: type,
      includedUserIds: includedUserIds,
      excludedUserIds: excludedUserIds,
      hideViewCount: hideViewCount,
    );
  }
}

// Helper methods for PrivacyType conversion
PrivacyType _privacyTypeFromJson(String value) {
  return PrivacyType.values.firstWhere(
    (e) => e.toString().split('.').last == value,
    orElse: () => PrivacyType.allContacts,
  );
}

String _privacyTypeToJson(PrivacyType type) {
  return type.toString().split('.').last;
}
import 'package:freezed_annotation/freezed_annotation.dart';

part 'status_privacy.freezed.dart';
part 'status_privacy.g.dart';

enum PrivacyType {
  allContacts,
  except,
  onlySpecific
}

@freezed
class StatusPrivacy with _$StatusPrivacy {
  const factory StatusPrivacy({
    required PrivacyType type,
    @Default([]) List<String> includedUserIds,
    @Default([]) List<String> excludedUserIds,
    @Default(false) bool hideViewCount,
  }) = _StatusPrivacy;

  factory StatusPrivacy.fromJson(Map<String, dynamic> json) => _$StatusPrivacyFromJson(json);
  
  // Helper methods
  const StatusPrivacy._();
  
  // Create default privacy for all contacts
  factory StatusPrivacy.allContacts() => const StatusPrivacy(
    type: PrivacyType.allContacts,
  );
  
  // Create privacy settings for 'except' mode
  factory StatusPrivacy.except(List<String> excludedUserIds) => StatusPrivacy(
    type: PrivacyType.except,
    excludedUserIds: excludedUserIds,
  );
  
  // Create privacy settings for 'only specific' mode
  factory StatusPrivacy.onlySpecific(List<String> includedUserIds) => StatusPrivacy(
    type: PrivacyType.onlySpecific,
    includedUserIds: includedUserIds,
  );
  
  // Get a user-friendly description of the privacy setting
  String getDescription() {
    switch (type) {
      case PrivacyType.allContacts:
        return 'All Contacts';
      case PrivacyType.except:
        final count = excludedUserIds.length;
        return 'All contacts except $count ${count == 1 ? 'person' : 'people'}';
      case PrivacyType.onlySpecific:
        final count = includedUserIds.length;
        return 'Only $count ${count == 1 ? 'person' : 'people'}';
    }
  }
}
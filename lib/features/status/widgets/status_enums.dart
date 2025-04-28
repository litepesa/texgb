// lib/enums/status_enums.dart

/// Types of status posts
enum StatusType {
  image,
  video,
  text,
  link,
}

/// Extension to provide helper methods for StatusType
extension StatusTypeExtension on StatusType {
  /// Convert a string representation to StatusType enum
  static StatusType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return StatusType.video;
      case 'text':
        return StatusType.text;
      case 'link':
        return StatusType.link;
      case 'image':
      default:
        return StatusType.image;
    }
  }
  
  /// Get a user-friendly name for the status type
  String get displayName {
    switch (this) {
      case StatusType.video:
        return 'Video';
      case StatusType.text:
        return 'Text';
      case StatusType.link:
        return 'Link';
      case StatusType.image:
        return 'Photo';
    }
  }
  
  /// Get an icon for the status type
  String get icon {
    switch (this) {
      case StatusType.video:
        return 'video_camera_back';
      case StatusType.text:
        return 'text_fields';
      case StatusType.link:
        return 'link';
      case StatusType.image:
        return 'photo_camera';
    }
  }
}

/// Privacy settings for status posts
enum StatusPrivacyType {
  all_contacts,    // All contacts can see
  except,          // All contacts except specific ones
  only,            // Only specific contacts can see
}

/// Extension to provide helper methods for StatusPrivacyType
extension StatusPrivacyTypeExtension on StatusPrivacyType {
  /// Convert a string representation to StatusPrivacyType enum
  static StatusPrivacyType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'except':
        return StatusPrivacyType.except;
      case 'only':
        return StatusPrivacyType.only;
      case 'all_contacts':
      default:
        return StatusPrivacyType.all_contacts;
    }
  }
  
  /// Get a user-friendly name for the privacy type
  String get displayName {
    switch (this) {
      case StatusPrivacyType.except:
        return 'My contacts except...';
      case StatusPrivacyType.only:
        return 'Only share with...';
      case StatusPrivacyType.all_contacts:
        return 'My contacts';
    }
  }
  
  /// Get an icon for the privacy type
  String get icon {
    switch (this) {
      case StatusPrivacyType.except:
        return 'person_remove';
      case StatusPrivacyType.only:
        return 'people';
      case StatusPrivacyType.all_contacts:
        return 'contacts';
    }
  }
}
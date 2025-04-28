// lib/enums/enums.dart

enum ContactViewType {
  contacts,
  blocked,
  groupView,
  allUsers,
}

enum MessageEnum {
  text,
  image,
  video,
  audio,
}

enum GroupType {
  private,
  public,
}

/// Types of status posts
enum StatusType {
  text,
  image,
  video,
  link,
}

/// Privacy settings for status posts
enum StatusPrivacyType {
  all_contacts,    // All contacts can see
  except,          // All contacts except specific ones
  only,            // Only specific contacts can see
}

// Extension for converting string to MessageEnum
extension MessageEnumExtension on String {
  MessageEnum toMessageEnum() {
    switch (this) {
      case 'text':
        return MessageEnum.text;
      case 'image':
        return MessageEnum.image;
      case 'video':
        return MessageEnum.video;
      case 'audio':
        return MessageEnum.audio;
      default:
        return MessageEnum.text;
    }
  }
}

// Extension for StatusType to get name as string
extension StatusTypeExtension on StatusType {
  String get name {
    switch (this) {
      case StatusType.text:
        return 'text';
      case StatusType.image:
        return 'image';
      case StatusType.video:
        return 'video';
      case StatusType.link:
        return 'link';
    }
  }
  
  static StatusType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return StatusType.video;
      case 'image':
        return StatusType.image;
      case 'link':
        return StatusType.link;
      case 'text':
      default:
        return StatusType.text;
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

// Extension to convert StatusType to MessageEnum
extension StatusTypeToMessageEnum on StatusType {
  MessageEnum toMessageEnum() {
    switch (this) {
      case StatusType.text:
        return MessageEnum.text;
      case StatusType.image:
        return MessageEnum.image;
      case StatusType.video:
        return MessageEnum.video;
      case StatusType.link:
        return MessageEnum.text; // Link status maps to text message type
    }
  }
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
// Complete implementation for lib/enums/enums.dart

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

enum StatusType {
  text,
  image,
  video,
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
      default:
        return 'text';
    }
  }
  
  static StatusType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return StatusType.image;
      case 'video':
        return StatusType.video;
      case 'text':
      default:
        return StatusType.text;
    }
  }
}

// NEW: Extension to convert StatusType to MessageEnum
extension StatusTypeToMessageEnum on StatusType {
  MessageEnum toMessageEnum() {
    switch (this) {
      case StatusType.text:
        return MessageEnum.text;
      case StatusType.image:
        return MessageEnum.image;
      case StatusType.video:
        return MessageEnum.video;
      default:
        return MessageEnum.text;
    }
  }
}
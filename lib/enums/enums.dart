// lib/enums/enums.dart
import 'package:flutter/material.dart';

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
  file,        // For document files
  location,    // For location sharing
  contact,     // For contact sharing
  videoReaction, // NEW: For video reaction messages
  gift,        // For virtual gift messages
}

// New enum for message status with detailed states
enum MessageStatus {
  sending,    // Message is being sent (local only)
  sent,       // Message has been sent to server
  delivered,  // Message has been delivered to receiver's device
  read,       // ⚠️ INTENTIONALLY UNUSED - WeChat-like privacy: no read receipts shown to senders
  failed;     // Message failed to send
  
  String get name {
    switch (this) {
      case MessageStatus.sending: return 'sending';
      case MessageStatus.sent: return 'sent';
      case MessageStatus.delivered: return 'delivered';
      case MessageStatus.read: return 'read';
      case MessageStatus.failed: return 'failed';
    }
  }
  
  static MessageStatus fromString(String status) {
    switch (status) {
      case 'sending': return MessageStatus.sending;
      case 'sent': return MessageStatus.sent;
      case 'delivered': return MessageStatus.delivered;
      case 'read': return MessageStatus.read;
      case 'failed': return MessageStatus.failed;
      default: return MessageStatus.sending;
    }
  }
  
  IconData get icon {
    switch (this) {
      case MessageStatus.sending: return Icons.access_time;
      case MessageStatus.sent: return Icons.done;
      case MessageStatus.delivered: return Icons.done_all;
      case MessageStatus.read: return Icons.done_all;
      case MessageStatus.failed: return Icons.error_outline;
    }
  }
  
  Color getColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (this) {
      case MessageStatus.sending: return Colors.grey;
      case MessageStatus.sent: return Colors.grey;
      case MessageStatus.delivered: return Colors.grey;
      case MessageStatus.read: return Colors.blue;
      case MessageStatus.failed: return Colors.red;
    }
  }
  
  // Add helper extension methods for easier status checking
  bool get isDelivered => this == MessageStatus.delivered || this == MessageStatus.read;
  bool get isRead => this == MessageStatus.read;
  bool get isSent => this == MessageStatus.sent || isDelivered || isRead;
  bool get isFailed => this == MessageStatus.failed;
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
      case 'file':
        return MessageEnum.file;
      case 'location':
        return MessageEnum.location;
      case 'contact':
        return MessageEnum.contact;
      case 'videoReaction':
        return MessageEnum.videoReaction;
      default:
        return MessageEnum.text;
    }
  }
}

// Extension to add helper methods to MessageEnum
extension MessageEnumHelper on MessageEnum {
  String get name {
    switch (this) {
      case MessageEnum.text:
        return 'text';
      case MessageEnum.image:
        return 'image';
      case MessageEnum.video:
        return 'video';
      case MessageEnum.audio:
        return 'audio';
      case MessageEnum.file:
        return 'file';
      case MessageEnum.location:
        return 'location';
      case MessageEnum.contact:
        return 'contact';
      case MessageEnum.videoReaction:
        return 'videoReaction';
      case MessageEnum.gift:
        return 'gift';
    }
  }

  String get displayName {
    switch (this) {
      case MessageEnum.text:
        return 'Text';
      case MessageEnum.image:
        return 'Photo';
      case MessageEnum.video:
        return 'Video';
      case MessageEnum.audio:
        return 'Voice message';
      case MessageEnum.file:
        return 'Document';
      case MessageEnum.location:
        return 'Location';
      case MessageEnum.contact:
        return 'Contact';
      case MessageEnum.videoReaction:
        return 'Video reaction';
      case MessageEnum.gift:
        return 'Gift';
    }
  }

  String get emoji {
    switch (this) {
      case MessageEnum.text:
        return '💬';
      case MessageEnum.image:
        return '📷';
      case MessageEnum.video:
        return '📹';
      case MessageEnum.audio:
        return '🎤';
      case MessageEnum.file:
        return '📎';
      case MessageEnum.location:
        return '📍';
      case MessageEnum.contact:
        return '👤';
      case MessageEnum.videoReaction:
        return '❤️';
      case MessageEnum.gift:
        return '🎁';
    }
  }

  IconData get icon {
    switch (this) {
      case MessageEnum.text:
        return Icons.text_format;
      case MessageEnum.image:
        return Icons.image;
      case MessageEnum.video:
        return Icons.videocam;
      case MessageEnum.audio:
        return Icons.mic;
      case MessageEnum.file:
        return Icons.insert_drive_file;
      case MessageEnum.location:
        return Icons.location_on;
      case MessageEnum.contact:
        return Icons.person;
      case MessageEnum.videoReaction:
        return Icons.favorite;
      case MessageEnum.gift:
        return Icons.card_giftcard;
    }
  }

  bool get isMedia {
    return this == MessageEnum.image || 
           this == MessageEnum.video || 
           this == MessageEnum.audio || 
           this == MessageEnum.file ||
           this == MessageEnum.videoReaction; // Video reactions also contain media
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

// Define chat actions that can be performed
enum ChatAction {
  reply,
  forward,
  delete,
  copy,
  pin,
  star,
  info,
}

// Extension to provide helper methods for ChatAction
extension ChatActionExtension on ChatAction {
  String get displayName {
    switch (this) {
      case ChatAction.reply:
        return 'Reply';
      case ChatAction.forward:
        return 'Forward';
      case ChatAction.delete:
        return 'Delete';
      case ChatAction.copy:
        return 'Copy';
      case ChatAction.pin:
        return 'Pin';
      case ChatAction.star:
        return 'Star';
      case ChatAction.info:
        return 'Info';
    }
  }
  
  IconData get icon {
    switch (this) {
      case ChatAction.reply:
        return Icons.reply;
      case ChatAction.forward:
        return Icons.forward;
      case ChatAction.delete:
        return Icons.delete;
      case ChatAction.copy:
        return Icons.content_copy;
      case ChatAction.pin:
        return Icons.push_pin;
      case ChatAction.star:
        return Icons.star;
      case ChatAction.info:
        return Icons.info;
    }
  }
}
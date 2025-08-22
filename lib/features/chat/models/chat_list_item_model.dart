// lib/features/chat/models/chat_list_item_model.dart
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chat/models/chat_model.dart';

class ChatListItemModel {
  final ChatModel chat;
  final String contactName;
  final String contactImage;
  final String contactPhone;
  final bool isOnline;
  final DateTime? lastSeen;

  const ChatListItemModel({
    required this.chat,
    required this.contactName,
    required this.contactImage,
    required this.contactPhone,
    required this.isOnline,
    this.lastSeen,
  });

  String getDisplayTime() {
    final now = DateTime.now();
    final difference = now.difference(chat.lastMessageTime);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24 && chat.lastMessageTime.day == now.day) {
      return '${chat.lastMessageTime.hour.toString().padLeft(2, '0')}:${chat.lastMessageTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[chat.lastMessageTime.weekday - 1];
    } else {
      return '${chat.lastMessageTime.day}/${chat.lastMessageTime.month}/${chat.lastMessageTime.year}';
    }
  }

  String getLastMessagePreview({String? currentUserId}) {
    // Determine if the last message was sent by the current user
    final isCurrentUserSender = currentUserId != null && chat.lastMessageSender == currentUserId;
    final prefix = isCurrentUserSender ? 'You: ' : '';
    
    switch (chat.lastMessageType) {
      case MessageEnum.text:
        return '$prefix${chat.lastMessage}';
      case MessageEnum.image:
        return '${prefix}📷 Photo';
      case MessageEnum.video:
        return '${prefix}📹 Video';
      case MessageEnum.file:
        return '${prefix}📎 Document';
      case MessageEnum.audio:
        return '${prefix}🎤 Voice message';
      case MessageEnum.location:
        return '${prefix}📍 Location';
      case MessageEnum.contact:
        return '${prefix}👤 Contact';
      default:
        return '$prefix${chat.lastMessage}';
    }
  }
}
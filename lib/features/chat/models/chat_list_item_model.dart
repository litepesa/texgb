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

  String getLastMessagePreview() {
    final isCurrentUserSender = chat.lastMessageSender != chat.getOtherParticipant(chat.lastMessageSender);
    final prefix = isCurrentUserSender ? 'You: ' : '';
    
    switch (chat.lastMessageType) {
      case MessageEnum.text:
        return '$prefix${chat.lastMessage}';
      case MessageEnum.image:
        return '${prefix}📷 Photo';
      case MessageEnum.file:
        return '${prefix}📎 Document';
      default:
        return '$prefix${chat.lastMessage}';
    }
  }
}
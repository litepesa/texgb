import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chat/widgets/unread_message_counter.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/models/last_message_model.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class ChatWidget extends ConsumerWidget {
  const ChatWidget({
    super.key,
    required this.chat,
    required this.onTap,
  });

  final LastMessageModel chat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modernTheme = context.modernTheme;
    final responsiveTheme = context.responsiveTheme;
    final animationTheme = context.animationTheme;
    
    final uid = ref.read(authenticationProvider).valueOrNull?.uid;
    if (uid == null) return const SizedBox();
    
    final lastMessage = chat.message;
    final senderUID = chat.senderUID;
    final DateTime timeToUse = chat.timeSent;
    final String timeString = formatDateForChatList(timeToUse);
    final imageUrl = chat.contactImage;
    final name = chat.contactName;
    final contactUID = chat.contactUID;
    final messageType = chat.messageType;
    final bool hasUnreadMessages = !chat.isSeen && senderUID != uid;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: animationTheme.shortDuration,
          decoration: BoxDecoration(
            color: hasUnreadMessages 
                ? modernTheme.primaryColor!.withOpacity(0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(responsiveTheme.compactRadius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Row(
            children: [
              Hero(
                tag: 'avatar-$contactUID',
                child: userImageWidget(
                  imageUrl: imageUrl,
                  radius: 28,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: hasUnreadMessages ? FontWeight.bold : FontWeight.w500,
                                    color: modernTheme.textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              
                              if (hasUnreadMessages)
                                Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: modernTheme.primaryColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        Text(
                          timeString,
                          style: TextStyle(
                            fontSize: 12,
                            color: modernTheme.textTertiaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        _buildMessageTypeIcon(messageType, modernTheme),
                        const SizedBox(width: 8),
                        
                        if (uid == senderUID)
                          Text(
                            "You: ",
                            style: TextStyle(
                              color: modernTheme.textSecondaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        
                        Expanded(
                          child: Text(
                            getMessagePreview(messageType, lastMessage),
                            style: TextStyle(
                              color: hasUnreadMessages 
                                  ? modernTheme.textColor 
                                  : modernTheme.textSecondaryColor,
                              fontSize: 14,
                              fontWeight: hasUnreadMessages ? FontWeight.w500 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        UnreadMessageCounter(uid: uid, contactUID: contactUID, isGroup: false),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMessageTypeIcon(MessageEnum type, ModernThemeExtension theme) {
    IconData iconData;
    Color iconColor = theme.textTertiaryColor!;
    
    switch (type) {
      case MessageEnum.image:
        iconData = Icons.photo_outlined;
        iconColor = const Color(0xFF4CAF50);
        break;
      case MessageEnum.video:
        iconData = Icons.videocam_outlined;
        iconColor = const Color(0xFF2196F3);
        break;
      case MessageEnum.audio:
        iconData = Icons.headphones_outlined;
        iconColor = const Color(0xFFFF9800);
        break;
      case MessageEnum.text:
      default:
        return const SizedBox.shrink();
    }
    
    return Icon(
      iconData,
      size: 16,
      color: iconColor,
    );
  }
  
  String getMessagePreview(MessageEnum type, String message) {
    switch (type) {
      case MessageEnum.image:
        return '📷 Photo';
      case MessageEnum.video:
        return '🎥 Video';
      case MessageEnum.audio:
        return '🎵 Audio message';
      case MessageEnum.text:
      default:
        return message;
    }
  }
  
  String formatDateForChatList(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);
    
    if (dateToCheck == today) {
      return formatDate(date, [hh, ':', nn, ' ', am]);
    } 
    else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } 
    else if (now.difference(dateToCheck).inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    }
    else if (date.year == now.year) {
      return formatDate(date, [M, ' ', d]);
    }
    else {
      return formatDate(date, [M, ' ', d, ', ', yy]);
    }
  }
}
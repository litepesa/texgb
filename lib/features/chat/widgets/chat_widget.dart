// lib/features/chat/widgets/chat_widget.dart

import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chat/widgets/unread_message_counter.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/groups/group_model.dart';
import 'package:textgb/models/last_message_model.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/chat/chat_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class ChatWidget extends StatelessWidget {
  const ChatWidget({
    super.key,
    this.chat,
    this.group,
    required this.isGroup,
    required this.onTap,
  });

  final LastMessageModel? chat;
  final GroupModel? group;
  final bool isGroup;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Get theme colors
    final modernTheme = context.modernTheme;
    final responsiveTheme = context.responsiveTheme;
    final animationTheme = context.animationTheme;
    
    final uid = context.read<AuthenticationProvider>().userModel!.uid;
    
    // get the last message
    final lastMessage = chat != null ? chat!.message : group!.lastMessage;
    
    // get the senderUID
    final senderUID = chat != null ? chat!.senderUID : group!.senderUID;

    // get the date and time - fix the timeSent conversion issue
    final DateTime timeToUse = chat != null 
        ? chat!.timeSent  // Already a DateTime for chat
        : DateTime.fromMillisecondsSinceEpoch(group!.timeSent as int);  // Convert milliseconds to DateTime for group
    
    final String timeString = formatDateForChatList(timeToUse);

    // get the image url
    final imageUrl = chat != null ? chat!.contactImage : group!.groupImage;

    // get the name
    final name = chat != null ? chat!.contactName : group!.groupName;

    // get the contactUID
    final contactUID = chat != null ? chat!.contactUID : group!.groupId;
    
    // get the messageType - ensure we have a proper default
    final messageType = chat != null 
        ? chat!.messageType 
        : (group!.messageType as String?)?.toMessageEnum() ?? MessageEnum.text;
    
    // Check if it has unread messages
    final bool hasUnreadMessages = chat != null ? !chat!.isSeen && senderUID != uid : false;
    
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
              // Contact/Group avatar (removed online status indicator)
              Hero(
                tag: 'avatar-$contactUID',
                child: userImageWidget(
                  imageUrl: imageUrl,
                  radius: 28,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 16),
              
              // Content column (name, message)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and time row
                    Row(
                      children: [
                        // Name with unread indicator
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
                              
                              // New message dot indicator
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
                        
                        // Timestamp
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
                    
                    // Last message preview row with icon
                    Row(
                      children: [
                        // Show message type icon
                        _buildMessageTypeIcon(messageType, modernTheme),
                        const SizedBox(width: 8),
                        
                        // Show "You: " prefix if the sender is the current user
                        if (uid == senderUID)
                          Text(
                            "You: ",
                            style: TextStyle(
                              color: modernTheme.textSecondaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        
                        // Message preview
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
                        
                        // Unread counter badge
                        UnreadMessageCounter(uid: uid, contactUID: contactUID, isGroup: isGroup),
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
  
  // Helper widget to display message type icon
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
        return const SizedBox.shrink(); // No icon for text messages
    }
    
    return Icon(
      iconData,
      size: 16,
      color: iconColor,
    );
  }
  
  // Helper function to get a more descriptive message preview
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
  
  // Helper function to format date for chat list in a modern style
  String formatDateForChatList(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);
    
    // If it's today, just show the time
    if (dateToCheck == today) {
      return formatDate(date, [hh, ':', nn, ' ', am]);
    } 
    // If it's yesterday, show "Yesterday"
    else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } 
    // If it's within the last 7 days, show the day name
    else if (now.difference(dateToCheck).inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1]; // weekday is 1-7 where 1 is Monday
    }
    // If it's this year, show month and day
    else if (date.year == now.year) {
      return formatDate(date, [M, ' ', d]);
    }
    // Otherwise show month, day and year
    else {
      return formatDate(date, [M, ' ', d, ', ', yy]);
    }
  }
}

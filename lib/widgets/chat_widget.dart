import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/models/group_model.dart';
import 'package:textgb/models/last_message_model.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/providers/chat_provider.dart';
import 'package:textgb/utilities/global_methods.dart';

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
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final greyColor = themeExtension?.greyColor ?? Colors.grey;
    
    final uid = context.read<AuthenticationProvider>().userModel!.uid;
    
    // get the last message
    final lastMessage = chat != null ? chat!.message : group!.lastMessage;
    
    // get the senderUID
    final senderUID = chat != null ? chat!.senderUID : group!.senderUID;

    // get the date and time
    final timeSent = chat != null ? chat!.timeSent : group!.timeSent;
    final String timeString = formatDateForChatList(timeSent);

    // get the image url
    final imageUrl = chat != null ? chat!.contactImage : group!.groupImage;

    // get the name
    final name = chat != null ? chat!.contactName : group!.groupName;

    // get the contactUID
    final contactUID = chat != null ? chat!.contactUID : group!.groupId;
    
    // get the messageType
    final messageType = chat != null ? chat!.messageType : group!.messageType;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        child: Row(
          children: [
            // Contact/Group avatar
            userImageWidget(
              imageUrl: imageUrl,
              radius: 28,
              onTap: () {},
            ),
            const SizedBox(width: 12),
            
            // Content column (name, message)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Last message with sender prefix if needed
                  Row(
                    children: [
                      // Show "You: " prefix if the sender is the current user
                      if (uid == senderUID)
                        Text(
                          "You: ",
                          style: TextStyle(
                            color: greyColor,
                            fontSize: 14,
                          ),
                        ),
                      
                      // Message preview
                      Expanded(
                        child: messageToShow(
                          type: messageType,
                          message: lastMessage,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Timestamp and unread counter column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Timestamp
                Text(
                  timeString,
                  style: TextStyle(
                    fontSize: 12,
                    color: greyColor,
                  ),
                ),
                const SizedBox(height: 4),
                
                // Unread messages counter - WeChat style
                UnreadMessageCounter(
                  uid: uid, 
                  contactUID: contactUID, 
                  isGroup: isGroup,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper function to format date for chat list in WeChat style
  String formatDateForChatList(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);
    
    // For today, show time
    if (dateToCheck == today) {
      return formatDate(date, [hh, ':', nn, ' ', am]);
    } 
    // For yesterday, show "Yesterday"
    else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } 
    // For this week, show day of week
    else if (now.difference(dateToCheck).inDays < 7) {
      // WeChat uses short day names
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1]; // weekday is 1-7 where 1 is Monday
    } 
    // For older messages, show date in MM/DD format
    else {
      return formatDate(date, [mm, '/', dd]);
    }
  }
}

class UnreadMessageCounter extends StatelessWidget {
  const UnreadMessageCounter({
    super.key,
    required this.uid,
    required this.contactUID,
    required this.isGroup,
  });

  final String uid;
  final String contactUID;
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? const Color(0xFF07C160);
    
    return StreamBuilder<int>(
      stream: context.read<ChatProvider>().getUnreadMessagesStream(
        userId: uid,
        contactUID: contactUID,
        isGroup: isGroup,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError || 
            snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData ||
            snapshot.data == 0) {
          return const SizedBox.shrink();
        }
        
        final unreadCount = snapshot.data!;
        
        // WeChat style unread counter
        return Container(
          padding: const EdgeInsets.all(5),
          constraints: const BoxConstraints(
            minWidth: 18,
            minHeight: 18,
          ),
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              unreadCount > 99 ? '99+' : unreadCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}

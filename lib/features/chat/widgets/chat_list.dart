import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_chat_reactions/utilities/hero_dialog_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:textgb/models/message_model.dart';
import 'package:textgb/models/message_reply_model.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/chat/chat_provider.dart';
import 'package:textgb/features/groups/group_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/features/chat/widgets/align_message_left_widget.dart';
import 'package:textgb/features/chat/widgets/align_message_right_widget.dart';
import 'package:textgb/features/chat/widgets/message_widget.dart';

class ChatList extends StatefulWidget {
  const ChatList({
    super.key,
    required this.contactUID,
    required this.groupId,
  });

  final String contactUID;
  final String groupId;

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  // scroll controller
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Helper function to get a formatted date key for grouping messages
  String _getDateKey(DateTime? dateTime) {
    if (dateTime == null) return "";
    
    // Formats date as YYYY-MM-DD for consistent grouping
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
  }

  // Build the date header widget for message groups
  Widget buildDateTime(String dateKey) {
    // Convert the date key back to a DateTime object
    DateTime date;
    try {
      final parts = dateKey.split('-');
      date = DateTime(
        int.parse(parts[0]), // year
        int.parse(parts[1]), // month
        int.parse(parts[2]), // day
      );
    } catch (e) {
      // Fallback in case of parsing error
      date = DateTime.now();
    }
    
    // Get today and yesterday dates for comparison
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);
    
    // Format date based on when it is
    String dateText;
    if (dateToCheck == today) {
      dateText = 'Today';
    } else if (dateToCheck == yesterday) {
      dateText = 'Yesterday';
    } else {
      // For older dates, use the full date format
      dateText = DateFormat('MMMM d, yyyy').format(date);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800.withOpacity(0.6)
                  : Colors.grey.shade200.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              dateText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // All your other methods remain unchanged
  void onContextMenyClicked({required String item, required MessageModel message}) {
    // Your existing implementation
  }

  void showDeletBottomSheet({
    required MessageModel message,
    required String currentUserId,
    required bool isSenderOrAdmin,
  }) {
    // Your existing implementation
  }

  void sendReactionToMessage({required String reaction, required String messageId}) {
    // Your existing implementation
  }

  void showEmojiContainer({required String messageId}) {
    // Your existing implementation
  }

  @override
  Widget build(BuildContext context) {
    // current user uid
    final uid = context.read<AuthenticationProvider>().userModel!.uid;
    
    return StreamBuilder<List<MessageModel>>(
      stream: context.read<ChatProvider>().getMessagesStream(
            userId: uid,
            contactUID: widget.contactUID,
            isGroup: widget.groupId,
          ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Something went wrong'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'Start a conversation',
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2),
            ),
          );
        }

        // automatically scroll to the bottom on new message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.minScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            );
          }
        });
        
        if (snapshot.hasData) {
          final messagesList = snapshot.data!;
          return GroupedListView<MessageModel, String>(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            reverse: true,
            controller: _scrollController,
            elements: messagesList,
            groupBy: (message) => _getDateKey(message.timeSent),
            groupHeaderBuilder: (MessageModel message) => buildDateTime(_getDateKey(message.timeSent)),
            itemBuilder: (context, MessageModel message) {
              // All your existing message handling code
              // check if it's a groupChat
              if (widget.groupId.isNotEmpty) {
                context.read<ChatProvider>().setMessageStatus(
                      currentUserId: uid,
                      contactUID: widget.contactUID,
                      messageId: message.messageId,
                      isSeenByList: message.isSeenBy,
                      isGroupChat: widget.groupId.isNotEmpty,
                    );
              } else {
                if (!message.isSeen && message.senderUID != uid) {
                  context.read<ChatProvider>().setMessageStatus(
                        currentUserId: uid,
                        contactUID: widget.contactUID,
                        messageId: message.messageId,
                        isSeenByList: message.isSeenBy,
                        isGroupChat: widget.groupId.isNotEmpty,
                      );
                }
              }

              // check if we sent the last message
              final isMe = message.senderUID == uid;
              // if the deletedBy contains the current user id then dont show the message
              bool deletedByCurrentUser = message.deletedBy.contains(uid);
              return deletedByCurrentUser
                  ? const SizedBox.shrink()
                  : GestureDetector(
                      onLongPress: () async {
                        Navigator.of(context).push(
                          HeroDialogRoute(builder: (context) {
                            return ReactionsDialogWidget(
                              id: message.messageId,
                              messageWidget: isMe
                                  ? AlignMessageRightWidget(
                                      message: message,
                                      viewOnly: true,
                                      isGroupChat: widget.groupId.isNotEmpty,
                                    )
                                  : AlignMessageLeftWidget(
                                      message: message,
                                      viewOnly: true,
                                      isGroupChat: widget.groupId.isNotEmpty,
                                    ),
                              onReactionTap: (reaction) {
                                if (reaction == '➕') {
                                  showEmojiContainer(
                                    messageId: message.messageId,
                                  );
                                } else {
                                  sendReactionToMessage(
                                    reaction: reaction,
                                    messageId: message.messageId,
                                  );
                                }
                              },
                              onContextMenuTap: (item) {
                                onContextMenyClicked(
                                  item: item.label,
                                  message: message,
                                );
                              },
                              widgetAlignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                            );
                          }),
                        );
                      },
                      child: Hero(
                        tag: message.messageId,
                        child: MessageWidget(
                          message: message,
                          onRightSwipe: () {
                            // set the message reply to true
                            final messageReply = MessageReplyModel(
                              message: message.message,
                              senderUID: message.senderUID,
                              senderName: message.senderName,
                              senderImage: message.senderImage,
                              messageType: message.messageType,
                              isMe: isMe,
                            );

                            context
                                .read<ChatProvider>()
                                .setMessageReplyModel(messageReply);
                          },
                          isMe: isMe,
                          isGroupChat: widget.groupId.isNotEmpty,
                        ),
                      ),
                    );
            },
            groupComparator: (group1, group2) => group2.compareTo(group1),
            itemComparator: (item1, item2) {
              final time1 = item1.timeSent ?? DateTime.now();
              final time2 = item2.timeSent ?? DateTime.now();
              return time2.compareTo(time1);
            },
            // Turn off sticky headers to make all date headers behave the same
            useStickyGroupSeparators: false,
            // Turn off floating header to make all date headers behave the same
            floatingHeader: false,
            order: GroupedListOrder.ASC,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
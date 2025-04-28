import 'package:flutter/material.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/shared/widgets/bottom_chat_field.dart';
import 'package:textgb/features/chat/widgets/chat_app_bar.dart';
import 'package:textgb/features/chat/widgets/chat_list.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    // get arguments passed from previous screen
    final arguments = ModalRoute.of(context)!.settings.arguments as Map;
    // get the contactUID from the arguments
    final contactUID = arguments[Constants.contactUID];
    // get the contactName from the arguments
    final contactName = arguments[Constants.contactName];
    // get the contactImage from the arguments
    final contactImage = arguments[Constants.contactImage];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: // get appBar color from theme
            Theme.of(context).appBarTheme.backgroundColor,
        title: ChatAppBar(contactUID: contactUID),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: ChatList(
                contactUID: contactUID,
                groupId: '',
              ),
            ),
            BottomChatField(
              contactUID: contactUID,
              contactName: contactName,
              contactImage: contactImage,
              groupId: '',
            ),
          ],
        ),
      ),
    );
  }
}

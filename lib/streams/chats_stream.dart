import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/last_message_model.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/chat/widgets/chat_widget.dart';

class ChatsStream extends ConsumerWidget {
  const ChatsStream({
    super.key,
    required this.uid,
    this.groupId = '',
  });

  final String uid;
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsStream = ref.watch(chatProvider.notifier).getChatsListStream(uid);

    return StreamBuilder<List<LastMessageModel>>(
      stream: chatsStream,
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
        if (snapshot.hasData) {
          final chatsList = snapshot.data!;
          return ListView.builder(
            itemCount: chatsList.length,
            itemBuilder: (context, index) {
              final chat = chatsList[index];

              return ChatWidget(
                chat: chat,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    Constants.chatScreen,
                    arguments: {
                      Constants.contactUID: chat.contactUID,
                      Constants.contactName: chat.contactName,
                      Constants.contactImage: chat.contactImage,
                    },
                  );
                },
              );
            },
          );
        }
        return const Center(
          child: Text('No chats yet'),
        );
      },
    );
  }
}

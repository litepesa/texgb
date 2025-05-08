import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/last_message_model.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/chat/widgets/chat_widget.dart';

class SearchStream extends ConsumerWidget {
  const SearchStream({
    super.key,
    required this.uid,
    this.groupId = '',
  });

  final String uid;
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatNotifier = ref.watch(chatProvider.notifier);
    final searchQuery = ref.watch(searchQueryProvider);
    final lastMessageStream = chatNotifier.getLastMessageStream(
      userId: uid,
      groupId: groupId,
    );

    return StreamBuilder<QuerySnapshot>(
      stream: lastMessageStream,
      builder: (builderContext, snapshot) {
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

        if (!snapshot.hasData) {
          return const Center(
            child: Text('No chats found'),
          );
        }

        final results = snapshot.data!.docs.where((element) =>
            element[Constants.contactName]
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase()));

        if (results.isEmpty) {
          return const Center(
            child: Text('No chats found'),
          );
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final chat = LastMessageModel.fromMap(
                results.elementAt(index).data() as Map<String, dynamic>);
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
      },
    );
  }
}
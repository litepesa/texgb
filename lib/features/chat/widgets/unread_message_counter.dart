import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';

class UnreadMessageCounter extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadMessagesStream = ref.watch(chatProvider.notifier).getUnreadMessagesStream(
          userId: uid,
          contactUID: contactUID,
          isGroup: isGroup,
        );

    return StreamBuilder<int>(
        stream: unreadMessagesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const SizedBox();
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox();
          }
          final unreadMessages = snapshot.data!;
          return unreadMessages > 0
              ? Container(
                  padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                  decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          spreadRadius: 1,
                          blurRadius: 6.0,
                          offset: Offset(0, 1),
                        ),
                      ]),
                  child: Text(
                    unreadMessages.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                )
              : const SizedBox();
        });
  }
}

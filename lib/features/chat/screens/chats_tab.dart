// lib/features/chat/screens/chats_tab.dart (Updated)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/chat/screens/chat_list_screen.dart';

class ChatsTab extends ConsumerWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Simply return our new ChatListScreen
    return const ChatListScreen();
  }
}

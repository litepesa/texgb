// lib/features/chat/screens/chat_screen_wrapper.dart
// Wrapper that fetches user data when contact is not provided

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/chat/screens/chat_screen.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/chat/repositories/chat_repository.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class ChatScreenWrapper extends ConsumerStatefulWidget {
  final String chatId;

  const ChatScreenWrapper({
    super.key,
    required this.chatId,
  });

  @override
  ConsumerState<ChatScreenWrapper> createState() => _ChatScreenWrapperState();
}

class _ChatScreenWrapperState extends ConsumerState<ChatScreenWrapper> {
  UserModel? _contact;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchContact();
  }

  Future<void> _fetchContact() async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      // First try to find the chat in the current chat list
      final chatListState = ref.read(chatListProvider);

      // Check if we have data and can find the chat
      bool foundInChatList = false;

      chatListState.whenData((state) {
        final chatItem = state.chats.where((c) => c.chat.chatId == widget.chatId).firstOrNull;

        if (chatItem != null) {
          // Found in chat list - create UserModel from chat item data
          final otherUserId = chatItem.chat.getOtherParticipant(currentUser.uid);

          if (mounted) {
            setState(() {
              _contact = UserModel.fromMap({
                'uid': otherUserId,
                'name': chatItem.contactName,
                'profileImage': chatItem.contactImage,
                'phoneNumber': chatItem.contactPhone,
              });
              _isLoading = false;
            });
          }
          foundInChatList = true;
        }
      });

      // If not found in chat list or state is loading/error, fetch from API
      if (!foundInChatList) {
        await _fetchUserFromApi(currentUser.uid);
      }

    } catch (e) {
      debugPrint('Error fetching contact: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchUserFromApi(String currentUserId) async {
    try {
      // Get the chat to find other user ID
      final repository = ref.read(chatRepositoryProvider);
      final chat = await repository.getChatById(widget.chatId);

      if (chat != null) {
        final otherUserId = chat.getOtherParticipant(currentUserId);

        // Fetch user details
        final authNotifier = ref.read(authenticationProvider.notifier);
        final user = await authNotifier.getUserById(otherUserId);

        if (user != null && mounted) {
          setState(() {
            _contact = user;
            _isLoading = false;
          });
        } else if (mounted) {
          // Create minimal user
          setState(() {
            _contact = UserModel.fromMap({
              'uid': otherUserId,
              'name': 'User',
              'profileImage': '',
            });
            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _error = 'Chat not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user from API: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: AppBar(
          backgroundColor: theme.surfaceColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.textColor),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Loading...',
            style: TextStyle(color: theme.textColor),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: theme.primaryColor,
          ),
        ),
      );
    }

    if (_error != null || _contact == null) {
      return Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: AppBar(
          backgroundColor: theme.surfaceColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.textColor),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Error',
            style: TextStyle(color: theme.textColor),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load chat',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _fetchContact();
                },
                child: Text(
                  'Retry',
                  style: TextStyle(color: theme.primaryColor),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ChatScreen(
      chatId: widget.chatId,
      contact: _contact!,
    );
  }
}

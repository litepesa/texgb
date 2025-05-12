import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/chats/models/chat_message.dart';
import 'package:textgb/features/chats/models/chat_room.dart';
import 'package:textgb/features/chats/repositories/chat_repository.dart';
import 'package:textgb/models/user_model.dart';

part 'chat_provider.g.dart';

// State class for chat management
class ChatState {
  final bool isLoading;
  final List<ChatRoom> chatRooms;
  final ChatRoom? currentChatRoom;
  final List<ChatMessage> messages;
  final String? error;
  final bool isSending;
  final String? replyingTo; // Message ID of message being replied to
  final ChatMessage? replyMessage; // Message being replied to
  final Map<String, bool> uploadProgress; // Track file uploads by message ID

  const ChatState({
    this.isLoading = false,
    this.chatRooms = const [],
    this.currentChatRoom,
    this.messages = const [],
    this.error,
    this.isSending = false,
    this.replyingTo,
    this.replyMessage,
    this.uploadProgress = const {},
  });

  ChatState copyWith({
    bool? isLoading,
    List<ChatRoom>? chatRooms,
    ChatRoom? currentChatRoom,
    List<ChatMessage>? messages,
    String? error,
    bool? isSending,
    String? replyingTo,
    ChatMessage? replyMessage,
    Map<String, bool>? uploadProgress,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      chatRooms: chatRooms ?? this.chatRooms,
      currentChatRoom: currentChatRoom ?? this.currentChatRoom,
      messages: messages ?? this.messages,
      error: error,
      isSending: isSending ?? this.isSending,
      replyingTo: replyingTo,
      replyMessage: replyMessage,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

@riverpod
class ChatNotifier extends _$ChatNotifier {
  late ChatRepository _chatRepository;

  @override
  FutureOr<ChatState> build() {
    _chatRepository = ref.read(chatRepositoryProvider);
    
    // Initialize with empty state
    return const ChatState();
  }

  // Load user's chat rooms
  Future<void> loadUserChatRooms() async {
    // Don't do anything if state is loading
    if (state.isLoading) return;
    
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      // Get current user
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel == null) {
        throw Exception('User not authenticated');
      }

      // Setup stream subscription for chat rooms
      _chatRepository.getUserChatRooms(authState.userModel!.uid).listen(
        (chatRooms) {
          state = AsyncValue.data(state.value!.copyWith(
            chatRooms: chatRooms,
            isLoading: false,
          ));
        },
        onError: (error) {
          state = AsyncValue.data(state.value!.copyWith(
            isLoading: false,
            error: error.toString(),
          ));
        },
      );
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Open a chat room
  Future<void> openChatRoom({
    required String chatId,
  }) async {
    if (state.isLoading) return;
    
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      // Get current user
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel == null) {
        throw Exception('User not authenticated');
      }

      // Setup stream subscription for chat room
      _chatRepository.getChatRoomById(chatId).listen(
        (chatRoom) {
          state = AsyncValue.data(state.value!.copyWith(
            currentChatRoom: chatRoom,
            isLoading: false,
          ));
        },
        onError: (error) {
          state = AsyncValue.data(state.value!.copyWith(
            isLoading: false,
            error: error.toString(),
          ));
        },
      );

      // Setup stream subscription for messages
      _chatRepository.getChatMessages(chatId).listen(
        (messages) {
          state = AsyncValue.data(state.value!.copyWith(
            messages: messages,
          ));
        },
        onError: (error) {
          state = AsyncValue.data(state.value!.copyWith(
            error: error.toString(),
          ));
        },
      );

      // Mark all messages as read
      await _chatRepository.markAllMessagesAsRead(
        chatId: chatId,
        uid: authState.userModel!.uid,
      );
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Create a new chat room or open existing one
  Future<void> createOrOpenChatWithUser({
    required UserModel otherUser,
  }) async {
    if (state.isLoading) return;
    
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      // Get current user
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel == null) {
        throw Exception('User not authenticated');
      }

      // Create or get chat room
      final chatRoom = await _chatRepository.createOrGetChatRoom(
        currentUser: authState.userModel!,
        otherUser: otherUser,
      );

      // Open the chat room
      await openChatRoom(chatId: chatRoom.chatId);
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Send text message
  Future<void> sendTextMessage({
    required String message,
  }) async {
    if (state.isSending || state.value!.currentChatRoom == null) return;
    
    state = AsyncValue.data(state.value!.copyWith(
      isSending: true,
      error: null,
    ));

    try {
      // Get current user
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel == null) {
        throw Exception('User not authenticated');
      }

      // Get chat room
      final chatRoom = state.value!.currentChatRoom!;
      
      // Determine receiver UID (other participant)
      final receiverUID = chatRoom.participantsUIDs
          .firstWhere((uid) => uid != authState.userModel!.uid);

      // Check if there's a reply
      String? repliedTo;
      String? repliedMessage;
      MessageEnum? repliedMessageType;

      if (state.value!.replyingTo != null && state.value!.replyMessage != null) {
        repliedTo = state.value!.replyMessage!.senderUID;
        repliedMessage = state.value!.replyMessage!.messageType == MessageEnum.text
            ? state.value!.replyMessage!.message
            : state.value!.replyMessage!.mediaMetadata?['caption'] ?? '';
        repliedMessageType = state.value!.replyMessage!.messageType;
      }

      // Send message
      await _chatRepository.sendTextMessage(
        chatId: chatRoom.chatId,
        sender: authState.userModel!,
        receiverUID: receiverUID,
        message: message,
        repliedTo: repliedTo,
        repliedMessage: repliedMessage,
        repliedMessageType: repliedMessageType,
      );

      // Clear reply
      state = AsyncValue.data(state.value!.copyWith(
        isSending: false,
        replyingTo: null,
        replyMessage: null,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isSending: false,
        error: e.toString(),
      ));
    }
  }

  // Send media message
  Future<void> sendMediaMessage({
    required File file,
    required MessageEnum messageType,
    required String caption,
  }) async {
    if (state.isSending || state.value!.currentChatRoom == null) return;
    
    state = AsyncValue.data(state.value!.copyWith(
      isSending: true,
      error: null,
    ));

    try {
      // Get current user
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel == null) {
        throw Exception('User not authenticated');
      }
      
      // Get chat room
      final chatRoom = state.value!.currentChatRoom!;
      
      // Determine receiver UID (other participant)
      final receiverUID = chatRoom.participantsUIDs
          .firstWhere((uid) => uid != authState.userModel!.uid);

      // Check if there's a reply
      String? repliedTo;
      String? repliedMessage;
      MessageEnum? repliedMessageType;

      if (state.value!.replyingTo != null && state.value!.replyMessage != null) {
        repliedTo = state.value!.replyMessage!.senderUID;
        repliedMessage = state.value!.replyMessage!.messageType == MessageEnum.text
            ? state.value!.replyMessage!.message
            : state.value!.replyMessage!.mediaMetadata?['caption'] ?? '';
        repliedMessageType = state.value!.replyMessage!.messageType;
      }

      // Send media message
      await _chatRepository.sendMediaMessage(
        chatId: chatRoom.chatId,
        sender: authState.userModel!,
        receiverUID: receiverUID,
        file: file,
        messageType: messageType,
        caption: caption,
        repliedTo: repliedTo,
        repliedMessage: repliedMessage,
        repliedMessageType: repliedMessageType,
      );

      // Clear reply
      state = AsyncValue.data(state.value!.copyWith(
        isSending: false,
        replyingTo: null,
        replyMessage: null,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isSending: false,
        error: e.toString(),
      ));
    }
  }
  
  // Set reply to message
  void setReplyMessage(ChatMessage message) {
    state = AsyncValue.data(state.value!.copyWith(
      replyingTo: message.messageId,
      replyMessage: message,
    ));
  }

  // Cancel reply
  void cancelReply() {
    state = AsyncValue.data(state.value!.copyWith(
      replyingTo: null,
      replyMessage: null,
    ));
  }

  // Mark message as seen
  Future<void> markMessageAsSeen({
    required String messageId,
  }) async {
    if (state.value!.currentChatRoom == null) return;

    try {
      // Get current user
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel == null) {
        throw Exception('User not authenticated');
      }

      await _chatRepository.markMessageAsSeen(
        chatId: state.value!.currentChatRoom!.chatId,
        messageId: messageId,
        uid: authState.userModel!.uid,
      );
    } catch (e) {
      debugPrint('Error marking message as seen: $e');
    }
  }

  // Add reaction to message
  Future<void> addReaction({
    required String messageId,
    required String reaction,
  }) async {
    if (state.value!.currentChatRoom == null) return;

    try {
      // Get current user
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel == null) {
        throw Exception('User not authenticated');
      }

      await _chatRepository.addReaction(
        chatId: state.value!.currentChatRoom!.chatId,
        messageId: messageId,
        uid: authState.userModel!.uid,
        reaction: reaction,
      );
    } catch (e) {
      debugPrint('Error adding reaction: $e');
    }
  }

  // Remove reaction from message
  Future<void> removeReaction({
    required String messageId,
  }) async {
    if (state.value!.currentChatRoom == null) return;

    try {
      // Get current user
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel == null) {
        throw Exception('User not authenticated');
      }

      await _chatRepository.removeReaction(
        chatId: state.value!.currentChatRoom!.chatId,
        messageId: messageId,
        uid: authState.userModel!.uid,
      );
    } catch (e) {
      debugPrint('Error removing reaction: $e');
    }
  }

  // Delete message
  Future<void> deleteMessage({
    required String messageId,
  }) async {
    if (state.value!.currentChatRoom == null) return;

    try {
      // Get current user
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel == null) {
        throw Exception('User not authenticated');
      }

      await _chatRepository.deleteMessage(
        chatId: state.value!.currentChatRoom!.chatId,
        messageId: messageId,
        uid: authState.userModel!.uid,
      );
    } catch (e) {
      debugPrint('Error deleting message: $e');
    }
  }

  // Update chat room settings
  Future<void> updateChatRoomSettings({
    required Map<String, dynamic> settings,
  }) async {
    if (state.value!.currentChatRoom == null) return;

    try {
      // Get current user
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel == null) {
        throw Exception('User not authenticated');
      }

      // Update settings in Firestore
      await _chatRepository.updateChatRoomSettings(
        chatId: state.value!.currentChatRoom!.chatId,
        settings: settings,
      );
    } catch (e) {
      debugPrint('Error updating chat room settings: $e');
    }
  }

  // Archive chat
  Future<void> archiveChat({
    required bool isArchived,
  }) async {
    if (state.value!.currentChatRoom == null) return;

    try {
      await updateChatRoomSettings(
        settings: {'isArchived': isArchived},
      );
    } catch (e) {
      debugPrint('Error archiving chat: $e');
    }
  }

  // Pin chat
  Future<void> pinChat({
    required bool isPinned,
  }) async {
    if (state.value!.currentChatRoom == null) return;

    try {
      await updateChatRoomSettings(
        settings: {'isPinned': isPinned},
      );
    } catch (e) {
      debugPrint('Error pinning chat: $e');
    }
  }

  // Mute chat
  Future<void> muteChat({
    required bool isMuted,
  }) async {
    if (state.value!.currentChatRoom == null) return;

    try {
      await updateChatRoomSettings(
        settings: {'isMuted': isMuted},
      );
    } catch (e) {
      debugPrint('Error muting chat: $e');
    }
  }

  // Delete chat (for current user only)
  Future<void> deleteChat() async {
    if (state.value!.currentChatRoom == null) return;

    try {
      // Get current user
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel == null) {
        throw Exception('User not authenticated');
      }

      // Mark chat as deleted for current user
      await _chatRepository.markChatAsDeleted(
        chatId: state.value!.currentChatRoom!.chatId,
        uid: authState.userModel!.uid,
      );
    } catch (e) {
      debugPrint('Error deleting chat: $e');
    }
  }
}

// Create a provider to watch chat rooms
final chatRoomsProvider = StreamProvider<List<ChatRoom>>((ref) {
  final authState = ref.watch(authenticationProvider);
  
  if (authState.hasValue && authState.value!.userModel != null) {
    final chatRepository = ref.watch(chatRepositoryProvider);
    return chatRepository.getUserChatRooms(authState.value!.userModel!.uid);
  }
  
  return Stream.value([]);
});

// Create a provider to watch messages in a chat room
final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.getChatMessages(chatId);
});

// Create a provider to filter chat rooms by search query
final filteredChatRoomsProvider = Provider.family<List<ChatRoom>, String>((ref, searchQuery) {
  final chatRoomsAsync = ref.watch(chatRoomsProvider);
  
  return chatRoomsAsync.when(
    data: (chatRooms) {
      if (searchQuery.isEmpty) {
        return chatRooms;
      }
      
      return chatRooms.where((room) {
        final participants = room.participantsInfo.values;
        return participants.any((name) =>
            name.toLowerCase().contains(searchQuery.toLowerCase()));
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Create a provider to get only archived chats
final archivedChatsProvider = Provider<List<ChatRoom>>((ref) {
  final chatRoomsAsync = ref.watch(chatRoomsProvider);
  
  return chatRoomsAsync.when(
    data: (chatRooms) {
      return chatRooms.where((room) {
        return room.chatSettings['isArchived'] as bool? ?? false;
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Create a provider to get only unarchived chats
final unarchivedChatsProvider = Provider<List<ChatRoom>>((ref) {
  final chatRoomsAsync = ref.watch(chatRoomsProvider);
  
  return chatRoomsAsync.when(
    data: (chatRooms) {
      return chatRooms.where((room) {
        return !(room.chatSettings['isArchived'] as bool? ?? false);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
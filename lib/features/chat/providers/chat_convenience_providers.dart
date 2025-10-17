// lib/features/chat/providers/chat_convenience_providers.dart
// Convenience providers for easy access to chat data
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';

part 'chat_convenience_providers.g.dart';

// ========================================
// CHAT LIST PROVIDERS
// ========================================

/// Get all chats
@riverpod
List<ChatModel> allChats(AllChatsRef ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.value?.chats ?? [];
}

/// Get filtered chats (search)
@riverpod
List<ChatModel> filteredChats(FilteredChatsRef ref, String query) {
  final chats = ref.watch(allChatsProvider);
  
  if (query.isEmpty) return chats;
  
  final authState = ref.read(authenticationProvider).value;
  final currentUserId = authState?.currentUser?.uid ?? '';
  
  final lowerQuery = query.toLowerCase();
  return chats.where((chat) {
    final chatTitle = chat.getChatTitle(currentUserId).toLowerCase();
    final lastMessage = chat.lastMessage?.toLowerCase() ?? '';
    
    return chatTitle.contains(lowerQuery) || lastMessage.contains(lowerQuery);
  }).toList();
}

/// Get pinned chats
@riverpod
List<ChatModel> pinnedChats(PinnedChatsRef ref) {
  final chats = ref.watch(allChatsProvider);
  return chats.where((chat) => chat.isPinned).toList();
}

/// Get archived chats
@riverpod
List<ChatModel> archivedChats(ArchivedChatsRef ref) {
  final chats = ref.watch(allChatsProvider);
  return chats.where((chat) => chat.isArchived).toList();
}

/// Get active (non-archived) chats
@riverpod
List<ChatModel> activeChats(ActiveChatsRef ref) {
  final chats = ref.watch(allChatsProvider);
  return chats.where((chat) => !chat.isArchived).toList();
}

/// Get chats with unread messages
@riverpod
List<ChatModel> chatsWithUnread(ChatsWithUnreadRef ref) {
  final chats = ref.watch(allChatsProvider);
  final authState = ref.read(authenticationProvider).value;
  final currentUserId = authState?.currentUser?.uid ?? '';
  
  return chats.where((chat) => chat.hasUnreadMessages(currentUserId)).toList();
}

/// Get one-on-one chats
@riverpod
List<ChatModel> oneOnOneChats(OneOnOneChatsRef ref) {
  final chats = ref.watch(activeChatsProvider);
  return chats.where((chat) => chat.isOneOnOne).toList();
}

/// Get group chats
@riverpod
List<ChatModel> groupChats(GroupChatsRef ref) {
  final chats = ref.watch(activeChatsProvider);
  return chats.where((chat) => chat.isGroup).toList();
}

// ========================================
// SPECIFIC CHAT PROVIDERS
// ========================================

/// Get specific chat by ID
@riverpod
Future<ChatModel?> chatById(ChatByIdRef ref, String chatId) async {
  final chatNotifier = ref.read(chatProvider.notifier);
  return await chatNotifier.getChatById(chatId);
}

/// Get chat title for current user
@riverpod
String chatTitle(ChatTitleRef ref, String chatId) {
  final chats = ref.watch(allChatsProvider);
  final authState = ref.read(authenticationProvider).value;
  final currentUserId = authState?.currentUser?.uid ?? '';
  
  final chat = chats.firstWhere(
    (c) => c.id == chatId,
    orElse: () => ChatModel(
      id: '',
      type: ChatType.oneOnOne,
      participantIds: [],
      participantNames: [],
      participantImages: [],
      lastMessageTime: '',
      createdAt: '',
      updatedAt: '',
    ),
  );
  
  return chat.getChatTitle(currentUserId);
}

/// Get chat image for current user
@riverpod
String? chatImage(ChatImageRef ref, String chatId) {
  final chats = ref.watch(allChatsProvider);
  final authState = ref.read(authenticationProvider).value;
  final currentUserId = authState?.currentUser?.uid ?? '';
  
  final chat = chats.firstWhere(
    (c) => c.id == chatId,
    orElse: () => ChatModel(
      id: '',
      type: ChatType.oneOnOne,
      participantIds: [],
      participantNames: [],
      participantImages: [],
      lastMessageTime: '',
      createdAt: '',
      updatedAt: '',
    ),
  );
  
  return chat.getChatImage(currentUserId);
}

// ========================================
// MESSAGE PROVIDERS
// ========================================

/// Get messages for a specific chat
@riverpod
List<MessageModel> chatMessages(ChatMessagesRef ref, String chatId) {
  final chatState = ref.watch(chatProvider);
  return chatState.value?.messages[chatId] ?? [];
}

/// Get latest message for a chat
@riverpod
MessageModel? latestMessage(LatestMessageRef ref, String chatId) {
  final messages = ref.watch(chatMessagesProvider(chatId));
  return messages.isNotEmpty ? messages.first : null;
}

/// Get message count for a chat
@riverpod
int messageCount(MessageCountRef ref, String chatId) {
  final messages = ref.watch(chatMessagesProvider(chatId));
  return messages.length;
}

/// Get starred messages
@riverpod
Future<List<MessageModel>> starredMessages(StarredMessagesRef ref) async {
  final repository = ref.read(chatRepositoryProvider);
  return await repository.getStarredMessages();
}

// ========================================
// UNREAD COUNT PROVIDERS
// ========================================

/// Get unread count for a specific chat
@riverpod
int chatUnreadCount(ChatUnreadCountRef ref, String chatId) {
  final chatState = ref.watch(chatProvider);
  final authState = ref.read(authenticationProvider).value;
  final currentUserId = authState?.currentUser?.uid ?? '';
  
  final chat = chatState.value?.chats.firstWhere(
    (c) => c.id == chatId,
    orElse: () => ChatModel(
      id: '',
      type: ChatType.oneOnOne,
      participantIds: [],
      participantNames: [],
      participantImages: [],
      lastMessageTime: '',
      createdAt: '',
      updatedAt: '',
    ),
  );
  
  return chat?.getUnreadCount(currentUserId) ?? 0;
}

/// Get total unread count across all chats
@riverpod
int totalUnreadCount(TotalUnreadCountRef ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.value?.totalUnreadCount ?? 0;
}

/// Check if chat has unread messages
@riverpod
bool hasUnreadMessages(HasUnreadMessagesRef ref, String chatId) {
  final unreadCount = ref.watch(chatUnreadCountProvider(chatId));
  return unreadCount > 0;
}

// ========================================
// CONNECTION STATE PROVIDERS
// ========================================

/// Check if WebSocket is connected
@riverpod
bool isChatConnected(IsChatConnectedRef ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.value?.isConnected ?? false;
}

/// Check if chats are loading
@riverpod
bool isChatLoading(IsChatLoadingRef ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.value?.isLoading ?? false;
}

/// Get chat error if any
@riverpod
String? chatError(ChatErrorRef ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.value?.error;
}

/// Get last sync time
@riverpod
DateTime? lastChatSync(LastChatSyncRef ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.value?.lastSync;
}

// ========================================
// CHAT SETTINGS PROVIDERS
// ========================================

/// Check if chat is muted
@riverpod
bool isChatMuted(IsChatMutedRef ref, String chatId) {
  final chats = ref.watch(allChatsProvider);
  final chat = chats.firstWhere(
    (c) => c.id == chatId,
    orElse: () => ChatModel(
      id: '',
      type: ChatType.oneOnOne,
      participantIds: [],
      participantNames: [],
      participantImages: [],
      lastMessageTime: '',
      createdAt: '',
      updatedAt: '',
    ),
  );
  return chat.isMuted;
}

/// Check if chat is pinned
@riverpod
bool isChatPinned(IsChatPinnedRef ref, String chatId) {
  final chats = ref.watch(allChatsProvider);
  final chat = chats.firstWhere(
    (c) => c.id == chatId,
    orElse: () => ChatModel(
      id: '',
      type: ChatType.oneOnOne,
      participantIds: [],
      participantNames: [],
      participantImages: [],
      lastMessageTime: '',
      createdAt: '',
      updatedAt: '',
    ),
  );
  return chat.isPinned;
}

/// Check if chat is archived
@riverpod
bool isChatArchived(IsChatArchivedRef ref, String chatId) {
  final chats = ref.watch(allChatsProvider);
  final chat = chats.firstWhere(
    (c) => c.id == chatId,
    orElse: () => ChatModel(
      id: '',
      type: ChatType.oneOnOne,
      participantIds: [],
      participantNames: [],
      participantImages: [],
      lastMessageTime: '',
      createdAt: '',
      updatedAt: '',
    ),
  );
  return chat.isArchived;
}

/// Check if chat is blocked
@riverpod
bool isChatBlocked(IsChatBlockedRef ref, String chatId) {
  final chats = ref.watch(allChatsProvider);
  final chat = chats.firstWhere(
    (c) => c.id == chatId,
    orElse: () => ChatModel(
      id: '',
      type: ChatType.oneOnOne,
      participantIds: [],
      participantNames: [],
      participantImages: [],
      lastMessageTime: '',
      createdAt: '',
      updatedAt: '',
    ),
  );
  return chat.isBlocked;
}

// ========================================
// PARTICIPANT PROVIDERS
// ========================================

/// Get participant count for a chat
@riverpod
int participantCount(ParticipantCountRef ref, String chatId) {
  final chats = ref.watch(allChatsProvider);
  final chat = chats.firstWhere(
    (c) => c.id == chatId,
    orElse: () => ChatModel(
      id: '',
      type: ChatType.oneOnOne,
      participantIds: [],
      participantNames: [],
      participantImages: [],
      lastMessageTime: '',
      createdAt: '',
      updatedAt: '',
    ),
  );
  return chat.participantCount;
}

/// Get other participant ID in one-on-one chat
@riverpod
String? otherParticipantId(OtherParticipantIdRef ref, String chatId) {
  final chats = ref.watch(allChatsProvider);
  final authState = ref.read(authenticationProvider).value;
  final currentUserId = authState?.currentUser?.uid ?? '';
  
  final chat = chats.firstWhere(
    (c) => c.id == chatId,
    orElse: () => ChatModel(
      id: '',
      type: ChatType.oneOnOne,
      participantIds: [],
      participantNames: [],
      participantImages: [],
      lastMessageTime: '',
      createdAt: '',
      updatedAt: '',
    ),
  );
  
  return chat.getOtherParticipantId(currentUserId);
}

/// Get other participant name in one-on-one chat
@riverpod
String? otherParticipantName(OtherParticipantNameRef ref, String chatId) {
  final chats = ref.watch(allChatsProvider);
  final authState = ref.read(authenticationProvider).value;
  final currentUserId = authState?.currentUser?.uid ?? '';
  
  final chat = chats.firstWhere(
    (c) => c.id == chatId,
    orElse: () => ChatModel(
      id: '',
      type: ChatType.oneOnOne,
      participantIds: [],
      participantNames: [],
      participantImages: [],
      lastMessageTime: '',
      createdAt: '',
      updatedAt: '',
    ),
  );
  
  return chat.getOtherParticipantName(currentUserId);
}

// ========================================
// STATISTICS PROVIDERS
// ========================================

/// Get total chat count
@riverpod
int totalChatCount(TotalChatCountRef ref) {
  final chats = ref.watch(allChatsProvider);
  return chats.length;
}

/// Get active chat count
@riverpod
int activeChatCount(ActiveChatCountRef ref) {
  final chats = ref.watch(activeChatsProvider);
  return chats.length;
}

/// Get archived chat count
@riverpod
int archivedChatCount(ArchivedChatCountRef ref) {
  final chats = ref.watch(archivedChatsProvider);
  return chats.length;
}

/// Get unread chat count
@riverpod
int unreadChatCount(UnreadChatCountRef ref) {
  final chats = ref.watch(chatsWithUnreadProvider);
  return chats.length;
}

/// Get group chat count
@riverpod
int groupChatCount(GroupChatCountRef ref) {
  final chats = ref.watch(groupChatsProvider);
  return chats.length;
}

// ========================================
// HELPER PROVIDERS
// ========================================

/// Format last message time
@riverpod
String formattedLastMessageTime(FormattedLastMessageTimeRef ref, String chatId) {
  final chats = ref.watch(allChatsProvider);
  final chat = chats.firstWhere(
    (c) => c.id == chatId,
    orElse: () => ChatModel(
      id: '',
      type: ChatType.oneOnOne,
      participantIds: [],
      participantNames: [],
      participantImages: [],
      lastMessageTime: '',
      createdAt: '',
      updatedAt: '',
    ),
  );
  return chat.formattedLastMessageTime;
}

/// Get last message preview
@riverpod
String lastMessagePreview(LastMessagePreviewRef ref, String chatId) {
  final chats = ref.watch(allChatsProvider);
  final chat = chats.firstWhere(
    (c) => c.id == chatId,
    orElse: () => ChatModel(
      id: '',
      type: ChatType.oneOnOne,
      participantIds: [],
      participantNames: [],
      participantImages: [],
      lastMessageTime: '',
      createdAt: '',
      updatedAt: '',
    ),
  );
  return chat.getLastMessagePreview();
}

/// Check if chat is one-on-one
@riverpod
bool isOneOnOneChat(IsOneOnOneChatRef ref, String chatId) {
  final chats = ref.watch(allChatsProvider);
  final chat = chats.firstWhere(
    (c) => c.id == chatId,
    orElse: () => ChatModel(
      id: '',
      type: ChatType.oneOnOne,
      participantIds: [],
      participantNames: [],
      participantImages: [],
      lastMessageTime: '',
      createdAt: '',
      updatedAt: '',
    ),
  );
  return chat.isOneOnOne;
}

/// Check if chat is group
@riverpod
bool isGroupChat(IsGroupChatRef ref, String chatId) {
  final chats = ref.watch(allChatsProvider);
  final chat = chats.firstWhere(
    (c) => c.id == chatId,
    orElse: () => ChatModel(
      id: '',
      type: ChatType.oneOnOne,
      participantIds: [],
      participantNames: [],
      participantImages: [],
      lastMessageTime: '',
      createdAt: '',
      updatedAt: '',
    ),
  );
  return chat.isGroup;
}
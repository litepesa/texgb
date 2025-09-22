// lib/features/video_chat/providers/video_chat_provider.dart
// FIXED: Using the existing model files we created earlier

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:textgb/features/video_chat/services/video_chat_service.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:uuid/uuid.dart';

// Import our model classes (these files were created earlier)
// You need to copy the VideoConversation and ReactionMessage artifacts to your project
// For now, I'll define them inline to avoid import issues

part 'video_chat_provider.g.dart';

// ========================================
// INLINE MODEL DEFINITIONS (temporary)
// ========================================

/// Simple message types for video reaction conversations
enum ReactionMessageType {
  text,
  image,
  video,
  link,
}

/// Simple message status - only what matters
enum MessageStatus {
  failed,    // ❌ Failed to send
  sent,      // ✓ Sent (1 grey tick)
  delivered, // ✓✓ Delivered (2 grey ticks)
  read,      // ✓✓ Read (2 blue ticks)
}

/// Video Conversation Model - simplified inline version
class VideoConversation {
  final String id;
  final String videoId;
  final String videoUrl;
  final String videoThumbnail;
  final String videoCreator;
  final String videoCreatorId;
  final List<String> participants;
  final DateTime createdAt;
  final ReactionMessage? lastMessage;
  final Map<String, int> unreadCounts;

  const VideoConversation({
    required this.id,
    required this.videoId,
    required this.videoUrl,
    required this.videoThumbnail,
    required this.videoCreator,
    required this.videoCreatorId,
    required this.participants,
    required this.createdAt,
    this.lastMessage,
    required this.unreadCounts,
  });

  factory VideoConversation.fromJson(Map<String, dynamic> json) {
    return VideoConversation(
      id: json['id']?.toString() ?? '',
      videoId: json['videoId']?.toString() ?? '',
      videoUrl: json['videoUrl']?.toString() ?? '',
      videoThumbnail: json['videoThumbnail']?.toString() ?? '',
      videoCreator: json['videoCreator']?.toString() ?? 'Unknown',
      videoCreatorId: json['videoCreatorId']?.toString() ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastMessage: json['lastMessage'] != null 
          ? ReactionMessage.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCounts: Map<String, int>.from(json['unreadCounts'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoId': videoId,
      'videoUrl': videoUrl,
      'videoThumbnail': videoThumbnail,
      'videoCreator': videoCreator,
      'videoCreatorId': videoCreatorId,
      'participants': participants,
      'createdAt': createdAt.toIso8601String(),
      'lastMessage': lastMessage?.toJson(),
      'unreadCounts': unreadCounts,
    };
  }

  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => participants.isNotEmpty ? participants.first : '',
    );
  }

  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  VideoConversation markAsRead(String userId) {
    final newUnreadCounts = Map<String, int>.from(unreadCounts);
    newUnreadCounts[userId] = 0;
    
    return VideoConversation(
      id: id,
      videoId: videoId,
      videoUrl: videoUrl,
      videoThumbnail: videoThumbnail,
      videoCreator: videoCreator,
      videoCreatorId: videoCreatorId,
      participants: participants,
      createdAt: createdAt,
      lastMessage: lastMessage,
      unreadCounts: newUnreadCounts,
    );
  }

  bool get isValid {
    return id.isNotEmpty && 
           videoId.isNotEmpty && 
           videoUrl.isNotEmpty &&
           participants.length == 2;
  }
}

/// Reaction Message Model - simplified inline version
class ReactionMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final ReactionMessageType type;
  final String? mediaUrl;
  final MessageStatus status;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const ReactionMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.type,
    this.mediaUrl,
    required this.status,
    required this.timestamp,
    this.metadata,
  });

  factory ReactionMessage.create({
    required String conversationId,
    required String senderId,
    required String content,
    required ReactionMessageType type,
    String? mediaUrl,
    Map<String, dynamic>? metadata,
  }) {
    const uuid = Uuid();
    
    return ReactionMessage(
      id: uuid.v4(),
      conversationId: conversationId,
      senderId: senderId,
      content: content.trim(),
      type: type,
      mediaUrl: mediaUrl,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  factory ReactionMessage.fromJson(Map<String, dynamic> json) {
    return ReactionMessage(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      type: ReactionMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReactionMessageType.text,
      ),
      mediaUrl: json['mediaUrl']?.toString(),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.failed,
      ),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
      'type': type.name,
      'mediaUrl': mediaUrl,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  ReactionMessage withStatus(MessageStatus newStatus) {
    return ReactionMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      type: type,
      mediaUrl: mediaUrl,
      status: newStatus,
      timestamp: timestamp,
      metadata: metadata,
    );
  }

  ReactionMessage withMediaUrl(String url) {
    return ReactionMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      type: type,
      mediaUrl: url,
      status: status,
      timestamp: timestamp,
      metadata: metadata,
    );
  }

  ReactionMessage copyWith({
    Map<String, dynamic>? metadata,
  }) {
    return ReactionMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      type: type,
      mediaUrl: mediaUrl,
      status: status,
      timestamp: timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isValid {
    return id.isNotEmpty && 
           conversationId.isNotEmpty && 
           senderId.isNotEmpty &&
           (content.isNotEmpty || (mediaUrl != null && mediaUrl!.isNotEmpty));
  }

  bool get isFailed => status == MessageStatus.failed;
}

// ========================================
// STATE MODELS
// ========================================

class ConversationsState {
  final bool isLoading;
  final List<VideoConversation> conversations;
  final String? error;
  final bool isOnline;

  const ConversationsState({
    this.isLoading = false,
    this.conversations = const [],
    this.error,
    this.isOnline = false,
  });

  ConversationsState copyWith({
    bool? isLoading,
    List<VideoConversation>? conversations,
    String? error,
    bool? isOnline,
    bool clearError = false,
  }) {
    return ConversationsState(
      isLoading: isLoading ?? this.isLoading,
      conversations: conversations ?? this.conversations,
      error: clearError ? null : (error ?? this.error),
      isOnline: isOnline ?? this.isOnline,
    );
  }

  int get totalUnreadCount {
    final currentUserId = _getCurrentUserId();
    if (currentUserId == null) return 0;
    
    return conversations.fold<int>(
      0, 
      (sum, conversation) => sum + conversation.getUnreadCount(currentUserId),
    );
  }

  List<VideoConversation> get sortedConversations {
    final sorted = List<VideoConversation>.from(conversations);
    sorted.sort((a, b) {
      final aTime = a.lastMessage?.timestamp ?? a.createdAt;
      final bTime = b.lastMessage?.timestamp ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
    return sorted;
  }

  static String? _getCurrentUserId() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (e) {
      return null;
    }
  }
}

class MessagesState {
  final bool isLoading;
  final List<ReactionMessage> messages;
  final String? error;
  final bool isOnline;
  final int failedCount;

  const MessagesState({
    this.isLoading = false,
    this.messages = const [],
    this.error,
    this.isOnline = false,
    this.failedCount = 0,
  });

  MessagesState copyWith({
    bool? isLoading,
    List<ReactionMessage>? messages,
    String? error,
    bool? isOnline,
    int? failedCount,
    bool clearError = false,
  }) {
    return MessagesState(
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      error: clearError ? null : (error ?? this.error),
      isOnline: isOnline ?? this.isOnline,
      failedCount: failedCount ?? this.failedCount,
    );
  }

  List<ReactionMessage> get sortedMessages {
    final sorted = List<ReactionMessage>.from(messages);
    sorted.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return sorted;
  }

  List<ReactionMessage> get failedMessages {
    return messages.where((m) => m.status == MessageStatus.failed).toList();
  }
}

// ========================================
// SERVICE PROVIDER
// ========================================

final videoChatServiceProvider = Provider<VideoChatService>((ref) {
  final service = VideoChatService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

// ========================================
// CONVERSATIONS PROVIDER
// ========================================

@riverpod
class Conversations extends _$Conversations {
  VideoChatService get _service => ref.read(videoChatServiceProvider);
  
  StreamSubscription<List<Map<String, dynamic>>>? _conversationsSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<String>? _errorSubscription;
  
  @override
  FutureOr<ConversationsState> build() async {
    ref.onDispose(() {
      debugPrint('🧹 Conversations provider disposed');
      _conversationsSubscription?.cancel();
      _connectionSubscription?.cancel();
      _errorSubscription?.cancel();
    });

    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const ConversationsState(error: 'User not authenticated');
    }

    await _initializeService(currentUser.uid);
    _setupListeners();
    await _loadConversations();

    return ConversationsState(
      isLoading: false,
      isOnline: _service.isConnected,
    );
  }

  Future<void> _initializeService(String userId) async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('No Firebase user found');
      }

      final token = await firebaseUser.getIdToken();
      final connected = await _service.connect(userId, token!);
      if (!connected) {
        throw Exception('Failed to connect to chat service');
      }
      
      debugPrint('✅ Video chat service initialized for user: $userId');
    } catch (e) {
      debugPrint('❌ Failed to initialize service: $e');
      final currentState = state.valueOrNull ?? const ConversationsState();
      state = AsyncValue.data(currentState.copyWith(error: e.toString()));
    }
  }

  void _setupListeners() {
    _conversationsSubscription?.cancel();
    _conversationsSubscription = _service.conversationsStream.listen(
      (rawConversations) {
        try {
          final conversations = _parseConversations(rawConversations);
          final currentState = state.valueOrNull ?? const ConversationsState();
          state = AsyncValue.data(currentState.copyWith(
            conversations: conversations,
            isLoading: false,
            clearError: true,
          ));
          debugPrint('📂 Conversations updated: ${conversations.length}');
        } catch (e) {
          debugPrint('❌ Error parsing conversations: $e');
          final currentState = state.valueOrNull ?? const ConversationsState();
          state = AsyncValue.data(currentState.copyWith(error: 'Failed to parse conversations'));
        }
      },
      onError: (error) {
        debugPrint('❌ Conversations stream error: $error');
        final currentState = state.valueOrNull ?? const ConversationsState();
        state = AsyncValue.data(currentState.copyWith(error: error.toString()));
      },
    );

    _connectionSubscription?.cancel();
    _connectionSubscription = _service.connectionStream.listen((isConnected) {
      final currentState = state.valueOrNull;
      if (currentState != null) {
        state = AsyncValue.data(currentState.copyWith(isOnline: isConnected));
      }
    });

    _errorSubscription?.cancel();
    _errorSubscription = _service.errorStream.listen((error) {
      final currentState = state.valueOrNull ?? const ConversationsState();
      state = AsyncValue.data(currentState.copyWith(error: error));
    });
  }

  List<VideoConversation> _parseConversations(List<Map<String, dynamic>> rawData) {
    final conversations = <VideoConversation>[];
    
    for (final rawConversation in rawData) {
      try {
        final conversation = VideoConversation.fromJson(rawConversation);
        if (conversation.isValid) {
          conversations.add(conversation);
        }
      } catch (e) {
        debugPrint('❌ Failed to parse conversation: $e');
      }
    }
    
    return conversations;
  }

  Future<void> _loadConversations() async {
    try {
      await _service.loadConversations();
    } catch (e) {
      debugPrint('❌ Error loading conversations: $e');
      final currentState = state.valueOrNull ?? const ConversationsState();
      state = AsyncValue.data(currentState.copyWith(error: e.toString()));
    }
  }

  // ========================================
  // PUBLIC METHODS
  // ========================================

  Future<VideoConversation?> createFromVideo({
    required String videoId,
    required String videoUrl,
    required String videoThumbnail,
    required String videoCreator,
    required String videoCreatorId,
    required String otherUserId,
  }) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      debugPrint('❌ Cannot create conversation - no current user');
      return null;
    }

    try {
      final rawConversation = await _service.createConversation(
        videoId: videoId,
        videoUrl: videoUrl,
        videoThumbnail: videoThumbnail,
        videoCreator: videoCreator,
        videoCreatorId: videoCreatorId,
        otherUserId: otherUserId,
      );

      if (rawConversation != null) {
        final conversation = VideoConversation.fromJson(rawConversation);
        
        final currentState = state.valueOrNull ?? const ConversationsState();
        final updatedConversations = [conversation, ...currentState.conversations];
        state = AsyncValue.data(currentState.copyWith(
          conversations: updatedConversations,
          clearError: true,
        ));
        
        debugPrint('✅ Video conversation created: ${conversation.id}');
        return conversation;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error creating conversation: $e');
      final currentState = state.valueOrNull ?? const ConversationsState();
      state = AsyncValue.data(currentState.copyWith(error: 'Failed to create conversation'));
      return null;
    }
  }

  Future<void> markAsRead(String conversationId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      await _service.markAsRead(conversationId);
      
      final currentState = state.valueOrNull;
      if (currentState != null) {
        final updatedConversations = currentState.conversations.map((conv) {
          if (conv.id == conversationId) {
            return conv.markAsRead(currentUser.uid);
          }
          return conv;
        }).toList();
        
        state = AsyncValue.data(currentState.copyWith(
          conversations: updatedConversations,
        ));
      }
      
      debugPrint('✅ Marked conversation as read: $conversationId');
    } catch (e) {
      debugPrint('❌ Error marking as read: $e');
    }
  }

  Future<void> refresh() async {
    final currentState = state.valueOrNull ?? const ConversationsState();
    state = AsyncValue.data(currentState.copyWith(isLoading: true));
    await _loadConversations();
  }

  Future<bool> reconnect() async {
    return await _service.reconnect();
  }

  // Getters
  bool get isConnected => _service.isConnected;
  int get totalUnreadCount {
    final currentState = state.valueOrNull;
    return currentState?.totalUnreadCount ?? 0;
  }
  List<VideoConversation> get sortedConversations {
    final currentState = state.valueOrNull;
    return currentState?.sortedConversations ?? [];
  }
}

// ========================================
// MESSAGES PROVIDER
// ========================================

@riverpod
class Messages extends _$Messages {
  VideoChatService get _service => ref.read(videoChatServiceProvider);
  
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<String>? _errorSubscription;
  
  @override
  FutureOr<MessagesState> build(String conversationId) async {
    ref.onDispose(() {
      debugPrint('🧹 Messages provider disposed for: $conversationId');
      _messagesSubscription?.cancel();
      _connectionSubscription?.cancel();
      _errorSubscription?.cancel();
    });

    _setupListeners();
    await _loadMessages(conversationId);

    return MessagesState(
      isLoading: false,
      isOnline: _service.isConnected,
    );
  }

  void _setupListeners() {
    _messagesSubscription?.cancel();
    _messagesSubscription = _service.messagesStream.listen(
      (rawMessages) {
        try {
          final conversationMessages = _parseMessagesForConversation(rawMessages, conversationId);
          
          final currentState = state.valueOrNull ?? const MessagesState();
          final failedCount = conversationMessages.where((m) => m.isFailed).length;
          
          state = AsyncValue.data(currentState.copyWith(
            messages: conversationMessages,
            isLoading: false,
            failedCount: failedCount,
            clearError: true,
          ));
          
          debugPrint('📨 Messages updated for $conversationId: ${conversationMessages.length}');
        } catch (e) {
          debugPrint('❌ Error parsing messages: $e');
          final currentState = state.valueOrNull ?? const MessagesState();
          state = AsyncValue.data(currentState.copyWith(error: 'Failed to parse messages'));
        }
      },
      onError: (error) {
        debugPrint('❌ Messages stream error: $error');
        final currentState = state.valueOrNull ?? const MessagesState();
        state = AsyncValue.data(currentState.copyWith(error: error.toString()));
      },
    );

    _connectionSubscription?.cancel();
    _connectionSubscription = _service.connectionStream.listen((isConnected) {
      final currentState = state.valueOrNull;
      if (currentState != null) {
        state = AsyncValue.data(currentState.copyWith(isOnline: isConnected));
      }
    });

    _errorSubscription?.cancel();
    _errorSubscription = _service.errorStream.listen((error) {
      final currentState = state.valueOrNull ?? const MessagesState();
      state = AsyncValue.data(currentState.copyWith(error: error));
    });
  }

  List<ReactionMessage> _parseMessagesForConversation(
    List<Map<String, dynamic>> rawMessages, 
    String targetConversationId,
  ) {
    final messages = <ReactionMessage>[];
    
    for (final rawMessage in rawMessages) {
      try {
        final messageConversationId = rawMessage['conversationId']?.toString();
        if (messageConversationId == targetConversationId) {
          final message = ReactionMessage.fromJson(rawMessage);
          if (message.isValid) {
            messages.add(message);
          }
        }
      } catch (e) {
        debugPrint('❌ Failed to parse message: $e');
      }
    }
    
    return messages;
  }

  Future<void> _loadMessages(String conversationId) async {
    try {
      await _service.loadMessages(conversationId);
    } catch (e) {
      debugPrint('❌ Error loading messages: $e');
      final currentState = state.valueOrNull ?? const MessagesState();
      state = AsyncValue.data(currentState.copyWith(error: e.toString()));
    }
  }

  // ========================================
  // MESSAGE SENDING METHODS
  // ========================================

  Future<bool> sendText(String content) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || content.trim().isEmpty) return false;

    try {
      final message = ReactionMessage.create(
        conversationId: conversationId,
        senderId: currentUser.uid,
        content: content.trim(),
        type: ReactionMessageType.text,
      );

      _addOptimisticMessage(message);

      final success = await _service.sendMessage(message.toJson());
      
      if (success) {
        _updateConversationLastMessage(message);
      } else {
        _updateMessageStatus(message.id, MessageStatus.failed);
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error sending text message: $e');
      return false;
    }
  }

  Future<bool> sendImage(File imageFile, {String caption = ''}) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || !imageFile.existsSync()) return false;

    try {
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        final currentState = state.valueOrNull ?? const MessagesState();
        state = AsyncValue.data(currentState.copyWith(
          error: 'Image size exceeds 10MB limit',
        ));
        return false;
      }

      final tempMessage = ReactionMessage.create(
        conversationId: conversationId,
        senderId: currentUser.uid,
        content: caption,
        type: ReactionMessageType.image,
        metadata: {'uploading': true, 'fileSize': fileSize},
      );

      _addOptimisticMessage(tempMessage);

      final authNotifier = ref.read(authenticationProvider.notifier);
      const uuid = Uuid();
      final fileName = '${uuid.v4()}.jpg';
      final imageUrl = await authNotifier.storeFileToStorage(
        file: imageFile,
        reference: 'video_chat/$conversationId/$fileName',
      );

      final finalMessage = tempMessage.withMediaUrl(imageUrl).copyWith(
        metadata: {'uploading': false, 'fileSize': fileSize},
      );

      final success = await _service.sendMessage(finalMessage.toJson());
      
      if (success) {
        _updateMessage(tempMessage.id, finalMessage);
        _updateConversationLastMessage(finalMessage);
      } else {
        _updateMessageStatus(tempMessage.id, MessageStatus.failed);
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error sending image: $e');
      final currentState = state.valueOrNull ?? const MessagesState();
      state = AsyncValue.data(currentState.copyWith(error: 'Failed to send image'));
      return false;
    }
  }

  Future<bool> sendVideo(File videoFile, {String caption = ''}) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || !videoFile.existsSync()) return false;

    try {
      final fileSize = await videoFile.length();
      if (fileSize > 50 * 1024 * 1024) {
        final currentState = state.valueOrNull ?? const MessagesState();
        state = AsyncValue.data(currentState.copyWith(
          error: 'Video size exceeds 50MB limit',
        ));
        return false;
      }

      final tempMessage = ReactionMessage.create(
        conversationId: conversationId,
        senderId: currentUser.uid,
        content: caption,
        type: ReactionMessageType.video,
        metadata: {'uploading': true, 'fileSize': fileSize},
      );

      _addOptimisticMessage(tempMessage);

      final authNotifier = ref.read(authenticationProvider.notifier);
      const uuid = Uuid();
      final fileName = '${uuid.v4()}.mp4';
      final videoUrl = await authNotifier.storeFileToStorage(
        file: videoFile,
        reference: 'video_chat/$conversationId/$fileName',
      );

      final finalMessage = tempMessage.withMediaUrl(videoUrl).copyWith(
        metadata: {'uploading': false, 'fileSize': fileSize},
      );

      final success = await _service.sendMessage(finalMessage.toJson());
      
      if (success) {
        _updateMessage(tempMessage.id, finalMessage);
        _updateConversationLastMessage(finalMessage);
      } else {
        _updateMessageStatus(tempMessage.id, MessageStatus.failed);
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error sending video: $e');
      final currentState = state.valueOrNull ?? const MessagesState();
      state = AsyncValue.data(currentState.copyWith(error: 'Failed to send video'));
      return false;
    }
  }

  Future<bool> sendLink(String content, {String? linkUrl}) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || content.trim().isEmpty) return false;

    try {
      final message = ReactionMessage.create(
        conversationId: conversationId,
        senderId: currentUser.uid,
        content: content.trim(),
        type: ReactionMessageType.link,
        mediaUrl: linkUrl,
      );

      _addOptimisticMessage(message);

      final success = await _service.sendMessage(message.toJson());
      
      if (success) {
        _updateConversationLastMessage(message);
      } else {
        _updateMessageStatus(message.id, MessageStatus.failed);
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error sending link message: $e');
      return false;
    }
  }

  Future<bool> retryMessage(String messageId) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return false;

    try {
      final message = currentState.messages.firstWhere(
        (m) => m.id == messageId && m.isFailed,
        orElse: () => throw Exception('Message not found or not failed'),
      );

      _updateMessageStatus(messageId, MessageStatus.sent);

      final success = await _service.sendMessage(message.toJson());
      
      if (success) {
        _updateConversationLastMessage(message);
      } else {
        _updateMessageStatus(messageId, MessageStatus.failed);
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error retrying message: $e');
      return false;
    }
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  void _addOptimisticMessage(ReactionMessage message) {
    final currentState = state.valueOrNull ?? const MessagesState();
    final updatedMessages = [...currentState.messages, message];
    
    state = AsyncValue.data(currentState.copyWith(
      messages: updatedMessages,
      clearError: true,
    ));
  }

  void _updateMessage(String messageId, ReactionMessage newMessage) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final updatedMessages = currentState.messages.map((m) {
      return m.id == messageId ? newMessage : m;
    }).toList();

    state = AsyncValue.data(currentState.copyWith(messages: updatedMessages));
  }

  void _updateMessageStatus(String messageId, MessageStatus status) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final updatedMessages = currentState.messages.map((m) {
      return m.id == messageId ? m.withStatus(status) : m;
    }).toList();

    final failedCount = updatedMessages.where((m) => m.isFailed).length;

    state = AsyncValue.data(currentState.copyWith(
      messages: updatedMessages,
      failedCount: failedCount,
    ));
  }

  void _updateConversationLastMessage(ReactionMessage message) {
    ref.invalidate(conversationsProvider);
  }

  // ========================================
  // GETTERS
  // ========================================

  bool get isConnected => _service.isConnected;
  
  List<ReactionMessage> get sortedMessages {
    final currentState = state.valueOrNull;
    return currentState?.sortedMessages ?? [];
  }

  List<ReactionMessage> get failedMessages {
    final currentState = state.valueOrNull;
    return currentState?.failedMessages ?? [];
  }

  int get failedCount {
    final currentState = state.valueOrNull;
    return currentState?.failedCount ?? 0;
  }
}

// ========================================
// CACHE MANAGER PROVIDER
// ========================================

final cacheManagerProvider = Provider<CacheManager>((ref) {
  return DefaultCacheManager();
});

// ========================================
// UTILITY PROVIDERS
// ========================================

/// Get conversation by ID
final conversationByIdProvider = Provider.family<VideoConversation?, String>((ref, conversationId) {
  final conversations = ref.watch(conversationsProvider);
  
  return conversations.when(
    data: (state) {
      try {
        return state.conversations.firstWhere(
          (conv) => conv.id == conversationId,
        );
      } catch (e) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Check if user can send messages
final canSendMessagesProvider = Provider.family<bool, String>((ref, conversationId) {
  final isConnected = ref.watch(conversationsProvider.select((state) {
    return state.when(
      data: (s) => s.isOnline,
      loading: () => false,
      error: (_, __) => false,
    );
  }));
  
  final currentUser = ref.watch(currentUserProvider);
  
  return isConnected && currentUser != null;
});

/// Get unread count for conversation
final unreadCountProvider = Provider.family<int, String>((ref, conversationId) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return 0;
  
  final conversation = ref.watch(conversationByIdProvider(conversationId));
  return conversation?.getUnreadCount(currentUser.uid) ?? 0;
});

/// Get other participant in conversation
final otherParticipantProvider = Provider.family<String?, String>((ref, conversationId) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return null;
  
  final conversation = ref.watch(conversationByIdProvider(conversationId));
  return conversation?.getOtherParticipantId(currentUser.uid);
});

// ========================================
// HELPER FUNCTIONS - UTILITY FUNCTIONS
// ========================================

/// Create conversation from video (utility function)
Future<VideoConversation?> createVideoConversation(
  WidgetRef ref, {
  required String videoId,
  required String videoUrl,
  required String videoThumbnail,
  required String videoCreator,
  required String videoCreatorId,
  required String otherUserId,
}) async {
  final notifier = ref.read(conversationsProvider.notifier);
  return await notifier.createFromVideo(
    videoId: videoId,
    videoUrl: videoUrl,
    videoThumbnail: videoThumbnail,
    videoCreator: videoCreator,
    videoCreatorId: videoCreatorId,
    otherUserId: otherUserId,
  );
}

/// Send text message (utility function)
Future<bool> sendTextMessage(
  WidgetRef ref,
  String conversationId,
  String content,
) async {
  final notifier = ref.read(messagesProvider(conversationId).notifier);
  return await notifier.sendText(content);
}

/// Send image message (utility function)
Future<bool> sendImageMessage(
  WidgetRef ref,
  String conversationId,
  File imageFile, {
  String caption = '',
}) async {
  final notifier = ref.read(messagesProvider(conversationId).notifier);
  return await notifier.sendImage(imageFile, caption: caption);
}

/// Send video message (utility function)
Future<bool> sendVideoMessage(
  WidgetRef ref,
  String conversationId,
  File videoFile, {
  String caption = '',
}) async {
  final notifier = ref.read(messagesProvider(conversationId).notifier);
  return await notifier.sendVideo(videoFile, caption: caption);
}

/// Send link message (utility function)
Future<bool> sendLinkMessage(
  WidgetRef ref,
  String conversationId,
  String content, {
  String? linkUrl,
}) async {
  final notifier = ref.read(messagesProvider(conversationId).notifier);
  return await notifier.sendLink(content, linkUrl: linkUrl);
}

/// Mark conversation as read (utility function)
Future<void> markConversationAsRead(
  WidgetRef ref,
  String conversationId,
) async {
  final notifier = ref.read(conversationsProvider.notifier);
  await notifier.markAsRead(conversationId);
}

/// Retry failed message (utility function)
Future<bool> retryFailedMessage(
  WidgetRef ref,
  String conversationId,
  String messageId,
) async {
  final notifier = ref.read(messagesProvider(conversationId).notifier);
  return await notifier.retryMessage(messageId);
}

/// Get conversation info for UI
Map<String, dynamic> getConversationInfo(
  WidgetRef ref,
  String conversationId,
) {
  final conversation = ref.watch(conversationByIdProvider(conversationId));
  final currentUser = ref.watch(currentUserProvider);
  final unreadCount = ref.watch(unreadCountProvider(conversationId));
  final canSend = ref.watch(canSendMessagesProvider(conversationId));
  
  if (conversation == null || currentUser == null) {
    return {
      'isValid': false,
      'error': 'Conversation not found',
    };
  }

  final otherParticipantId = conversation.getOtherParticipantId(currentUser.uid);
  
  return {
    'isValid': true,
    'conversationId': conversationId,
    'videoId': conversation.videoId,
    'videoUrl': conversation.videoUrl,
    'videoThumbnail': conversation.videoThumbnail,
    'videoCreator': conversation.videoCreator,
    'otherParticipantId': otherParticipantId,
    'unreadCount': unreadCount,
    'canSendMessages': canSend,
    'createdAt': conversation.createdAt,
  };
}

/// Get message statistics for UI
Map<String, dynamic> getMessageStatistics(
  WidgetRef ref,
  String conversationId,
) {
  final messagesState = ref.watch(messagesProvider(conversationId));
  
  return messagesState.when(
    data: (state) => {
      'totalMessages': state.messages.length,
      'failedMessages': state.failedCount,
      'isOnline': state.isOnline,
      'isLoading': state.isLoading,
      'hasError': state.error != null,
      'error': state.error,
    },
    loading: () => {
      'totalMessages': 0,
      'failedMessages': 0,
      'isOnline': false,
      'isLoading': true,
      'hasError': false,
      'error': null,
    },
    error: (error, _) => {
      'totalMessages': 0,
      'failedMessages': 0,
      'isOnline': false,
      'isLoading': false,
      'hasError': true,
      'error': error.toString(),
    },
  );
}
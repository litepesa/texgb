import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/chats/models/chat_message_model.dart';
import 'package:textgb/features/chats/repository/chat_search_repository.dart';

part 'chat_search_provider.g.dart';

/// State class for chat search
class ChatSearchState {
  final List<ChatMessageModel> searchResults;
  final bool isLoading;
  final String? error;
  final String query;
  
  const ChatSearchState({
    this.searchResults = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
  });
  
  ChatSearchState copyWith({
    List<ChatMessageModel>? searchResults,
    bool? isLoading,
    String? error,
    String? query,
  }) {
    return ChatSearchState(
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      query: query ?? this.query,
    );
  }
}

/// Provider for searching within chats.
/// Handles searching for messages by content, type, date, etc.
@riverpod
class ChatSearchNotifier extends _$ChatSearchNotifier {
  late final ChatSearchRepository _chatSearchRepository;
  
  @override
  FutureOr<ChatSearchState> build() {
    _chatSearchRepository = ChatSearchRepository();
    return const ChatSearchState();
  }
  
  // Search messages by content
  Future<void> searchMessagesByContent(String query, {int limit = 20}) async {
    if (query.isEmpty) {
      state = AsyncValue.data(const ChatSearchState());
      return;
    }
    
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      query: query,
    ));
    
    try {
      // Get current user ID
      final authState = ref.read(authenticationProvider);
      final uid = authState.value?.uid;
      
      if (uid == null) {
        throw Exception('User not authenticated');
      }
      
      final searchResults = await _chatSearchRepository.searchMessagesByContent(
        uid: uid,
        query: query,
        limit: limit,
      );
      
      state = AsyncValue.data(state.value!.copyWith(
        searchResults: searchResults,
        isLoading: false,
      ));
    } catch (e) {
      debugPrint('Error searching messages by content: $e');
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }
  
  // Search messages by type in a specific chat
  Future<void> searchMessagesByType({
    required String contactUID,
    required String messageType,
    int limit = 20,
  }) async {
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      query: 'Type: $messageType',
    ));
    
    try {
      // Get current user ID
      final authState = ref.read(authenticationProvider);
      final uid = authState.value?.uid;
      
      if (uid == null) {
        throw Exception('User not authenticated');
      }
      
      final searchResults = await _chatSearchRepository.searchMessagesByType(
        uid: uid,
        contactUID: contactUID,
        messageType: messageType,
        limit: limit,
      );
      
      state = AsyncValue.data(state.value!.copyWith(
        searchResults: searchResults,
        isLoading: false,
      ));
    } catch (e) {
      debugPrint('Error searching messages by type: $e');
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }
  
  // Search messages by date range in a specific chat
  Future<void> searchMessagesByDateRange({
    required String contactUID,
    required DateTime startDate,
    required DateTime endDate,
    int limit = 50,
  }) async {
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      query: 'Date: ${startDate.toString().substring(0, 10)} to ${endDate.toString().substring(0, 10)}',
    ));
    
    try {
      // Get current user ID
      final authState = ref.read(authenticationProvider);
      final uid = authState.value?.uid;
      
      if (uid == null) {
        throw Exception('User not authenticated');
      }
      
      final searchResults = await _chatSearchRepository.searchMessagesByDateRange(
        uid: uid,
        contactUID: contactUID,
        startTimestamp: startDate.millisecondsSinceEpoch,
        endTimestamp: endDate.millisecondsSinceEpoch,
        limit: limit,
      );
      
      state = AsyncValue.data(state.value!.copyWith(
        searchResults: searchResults,
        isLoading: false,
      ));
    } catch (e) {
      debugPrint('Error searching messages by date range: $e');
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }
  
  // Get all media messages in a chat
  Future<void> getAllMediaMessages({
    required String contactUID,
    int limit = 50,
  }) async {
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      query: 'All Media',
    ));
    
    try {
      // Get current user ID
      final authState = ref.read(authenticationProvider);
      final uid = authState.value?.uid;
      
      if (uid == null) {
        throw Exception('User not authenticated');
      }
      
      final mediaMessages = await _chatSearchRepository.getAllMediaMessages(
        uid: uid,
        contactUID: contactUID,
        limit: limit,
      );
      
      state = AsyncValue.data(state.value!.copyWith(
        searchResults: mediaMessages,
        isLoading: false,
      ));
    } catch (e) {
      debugPrint('Error getting all media messages: $e');
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }
  
  // Get all messages containing links
  Future<void> getMessagesWithLinks({
    required String contactUID,
    int limit = 30,
  }) async {
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      query: 'All Links',
    ));
    
    try {
      // Get current user ID
      final authState = ref.read(authenticationProvider);
      final uid = authState.value?.uid;
      
      if (uid == null) {
        throw Exception('User not authenticated');
      }
      
      final messagesWithLinks = await _chatSearchRepository.getMessagesWithLinks(
        uid: uid,
        contactUID: contactUID,
        limit: limit,
      );
      
      state = AsyncValue.data(state.value!.copyWith(
        searchResults: messagesWithLinks,
        isLoading: false,
      ));
    } catch (e) {
      debugPrint('Error getting messages with links: $e');
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }
  
  // Clear search results
  void clearSearch() {
    state = AsyncValue.data(const ChatSearchState());
  }
}

/// Provider for media gallery access in a specific chat
@riverpod
class MediaGalleryNotifier extends _$MediaGalleryNotifier {
  late final ChatSearchRepository _chatSearchRepository;
  
  @override
  FutureOr<List<ChatMessageModel>> build(String contactUID) {
    _chatSearchRepository = ChatSearchRepository();
    
    // Get current user ID
    final authState = ref.watch(authenticationProvider);
    final uid = authState.value?.uid;
    
    if (uid == null) {
      return [];
    }
    
    // Load media
    return _loadMedia(uid, contactUID);
  }
  
  Future<List<ChatMessageModel>> _loadMedia(String uid, String contactUID) async {
    try {
      return await _chatSearchRepository.getAllMediaMessages(
        uid: uid,
        contactUID: contactUID,
        limit: 100, // Higher limit for gallery view
      );
    } catch (e) {
      debugPrint('Error loading media gallery: $e');
      return [];
    }
  }
  
  // Refresh media gallery
  Future<void> refreshMedia() async {
    state = const AsyncValue.loading();
    
    // Get current user ID
    final authState = ref.read(authenticationProvider);
    final uid = authState.value?.uid;
    
    if (uid == null) {
      state = const AsyncValue.data([]);
      return;
    }
    
    try {
      final media = await _chatSearchRepository.getAllMediaMessages(
        uid: uid,
        contactUID: contactUID,
        limit: 100,
      );
      state = AsyncValue.data(media);
    } catch (e) {
      debugPrint('Error refreshing media gallery: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  // Filter media by type
  List<ChatMessageModel> filterByType(MessageEnum type) {
    final media = state.value ?? [];
    return media.where((message) => message.messageType == type).toList();
  }
  
  // Get images only
  List<ChatMessageModel> getImages() {
    final media = state.value ?? [];
    return media.where((message) => message.messageType == MessageEnum.image).toList();
  }
  
  // Get videos only
  List<ChatMessageModel> getVideos() {
    final media = state.value ?? [];
    return media.where((message) => message.messageType == MessageEnum.video).toList();
  }
  
  // Get documents only
  List<ChatMessageModel> getDocuments() {
    final media = state.value ?? [];
    return media.where((message) => message.messageType == MessageEnum.file).toList();
  }
  
  // Get audio only
  List<ChatMessageModel> getAudio() {
    final media = state.value ?? [];
    return media.where((message) => message.messageType == MessageEnum.audio).toList();
  }
}
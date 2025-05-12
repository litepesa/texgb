import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chats/models/draft_message_model.dart';
import 'package:textgb/features/chats/repository/draft_repository.dart';

part 'draft_provider.g.dart';

/// State class for draft message provider
class DraftState {
  final DraftMessageModel? draft;
  final bool isLoading;
  final String? error;
  
  const DraftState({
    this.draft,
    this.isLoading = false,
    this.error,
  });
  
  DraftState copyWith({
    DraftMessageModel? draft,
    bool? isLoading,
    String? error,
  }) {
    return DraftState(
      draft: draft ?? this.draft,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for managing message drafts.
/// Handles saving, retrieving, and updating draft messages.
@riverpod
class DraftNotifier extends _$DraftNotifier {
  late final DraftRepository _draftRepository;
  
  @override
  FutureOr<DraftState> build(String contactUID) {
    _draftRepository = DraftRepository();
    
    // Load draft for this contact
    return _loadDraft(contactUID);
  }
  
  // Load draft message for a contact
  Future<DraftState> _loadDraft(String contactUID) async {
    state = AsyncValue.data(const DraftState(isLoading: true));
    
    try {
      final draft = await _draftRepository.getDraft(contactUID);
      return DraftState(draft: draft);
    } catch (e) {
      debugPrint('Error loading draft: $e');
      return DraftState(error: e.toString());
    }
  }
  
  // Save draft message
  Future<void> saveDraft(DraftMessageModel draft) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));
    
    try {
      await _draftRepository.saveDraft(draft);
      state = AsyncValue.data(state.value!.copyWith(
        draft: draft,
        isLoading: false,
      ));
    } catch (e) {
      debugPrint('Error saving draft: $e');
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }
  
  // Update draft text content
  Future<void> updateDraftContent(String message) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));
    
    try {
      await _draftRepository.updateDraftContent(
        contactUID: contactUID,
        message: message,
      );
      
      // Reload draft
      final draft = await _draftRepository.getDraft(contactUID);
      state = AsyncValue.data(state.value!.copyWith(
        draft: draft,
        isLoading: false,
      ));
    } catch (e) {
      debugPrint('Error updating draft content: $e');
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }
  
  // Update draft reply data
  Future<void> updateDraftReply({
    String? repliedMessage,
    String? repliedTo,
    MessageEnum? repliedMessageType,
  }) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));
    
    try {
      await _draftRepository.updateDraftReply(
        contactUID: contactUID,
        repliedMessage: repliedMessage,
        repliedTo: repliedTo,
        repliedMessageType: repliedMessageType,
      );
      
      // Reload draft
      final draft = await _draftRepository.getDraft(contactUID);
      state = AsyncValue.data(state.value!.copyWith(
        draft: draft,
        isLoading: false,
      ));
    } catch (e) {
      debugPrint('Error updating draft reply: $e');
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }
  
  // Update draft media attachment
  Future<void> updateDraftMedia({
    required String mediaPath,
    required MessageEnum messageType,
    Map<String, dynamic>? attachmentData,
  }) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));
    
    try {
      await _draftRepository.updateDraftMedia(
        contactUID: contactUID,
        mediaPath: mediaPath,
        messageType: messageType,
        attachmentData: attachmentData,
      );
      
      // Reload draft
      final draft = await _draftRepository.getDraft(contactUID);
      state = AsyncValue.data(state.value!.copyWith(
        draft: draft,
        isLoading: false,
      ));
    } catch (e) {
      debugPrint('Error updating draft media: $e');
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }
  
  // Clear draft media but keep text
  Future<void> clearDraftMedia() async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));
    
    try {
      await _draftRepository.clearDraftMedia(contactUID);
      
      // Reload draft
      final draft = await _draftRepository.getDraft(contactUID);
      state = AsyncValue.data(state.value!.copyWith(
        draft: draft,
        isLoading: false,
      ));
    } catch (e) {
      debugPrint('Error clearing draft media: $e');
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }
  
  // Delete draft
  Future<void> deleteDraft() async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));
    
    try {
      await _draftRepository.deleteDraft(contactUID);
      state = AsyncValue.data(const DraftState());
    } catch (e) {
      debugPrint('Error deleting draft: $e');
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }
}

/// Provider for accessing all drafts
@riverpod
class AllDraftsNotifier extends _$AllDraftsNotifier {
  late final DraftRepository _draftRepository;
  
  @override
  FutureOr<List<DraftMessageModel>> build() {
    _draftRepository = DraftRepository();
    return _loadAllDrafts();
  }
  
  // Load all drafts
  Future<List<DraftMessageModel>> _loadAllDrafts() async {
    try {
      return await _draftRepository.getAllDrafts();
    } catch (e) {
      debugPrint('Error loading all drafts: $e');
      return [];
    }
  }
  
  // Clear all drafts
  Future<void> clearAllDrafts() async {
    try {
      await _draftRepository.clearAllDrafts();
      state = const AsyncValue.data([]);
    } catch (e) {
      debugPrint('Error clearing all drafts: $e');
    }
  }
  
  // Refresh drafts list
  Future<void> refreshDrafts() async {
    state = const AsyncValue.loading();
    try {
      final drafts = await _draftRepository.getAllDrafts();
      state = AsyncValue.data(drafts);
    } catch (e) {
      debugPrint('Error refreshing drafts: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
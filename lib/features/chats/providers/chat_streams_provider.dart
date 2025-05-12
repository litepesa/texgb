import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/chats/models/chat_model.dart';
import 'package:textgb/features/chats/repository/chat_repository.dart';

part 'chat_streams_provider.g.dart';

/// Provider that exposes a stream of chats
@riverpod
Stream<List<ChatModel>> chatStream(ChatStreamRef ref) {
  // Get current user ID
  final authState = ref.watch(authenticationProvider);
  final currentUID = authState.value?.uid;
  
  if (currentUID == null) {
    // Return empty stream if no authenticated user
    return Stream.value([]);
  }
  
  // Get the repository
  final chatRepository = ChatRepository();
  
  // Return the stream of chats
  return chatRepository.getAllChatsForUser(currentUID);
}
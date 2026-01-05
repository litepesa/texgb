// lib/shared/providers/websocket_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/services/websocket_service.dart';

// WebSocket service provider
final websocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();

  // Ensure cleanup when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

// WebSocket connection state provider
final websocketConnectionStateProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(websocketServiceProvider);
  return service.connectionStateStream;
});

// WebSocket event stream provider
final websocketEventStreamProvider = StreamProvider<WebSocketMessage>((ref) {
  final service = ref.watch(websocketServiceProvider);
  return service.eventStream;
});

// WebSocket error stream provider
final websocketErrorStreamProvider = StreamProvider<String>((ref) {
  final service = ref.watch(websocketServiceProvider);
  return service.errorStream;
});

// Provider for specific event type stream
final websocketEventTypeStreamProvider =
    StreamProvider.family<WebSocketMessage, String>((ref, eventType) {
  final service = ref.watch(websocketServiceProvider);
  return service.subscribeToEvent(eventType);
});

// Provider for multiple event types stream
final websocketEventTypesStreamProvider =
    StreamProvider.family<WebSocketMessage, List<String>>((ref, eventTypes) {
  final service = ref.watch(websocketServiceProvider);
  return service.subscribeToEvents(eventTypes);
});

// Helper providers for common event types

// Chat events stream
final chatEventsStreamProvider = StreamProvider<WebSocketMessage>((ref) {
  final service = ref.watch(websocketServiceProvider);
  return service.subscribeToEvents([
    'chat_created',
    'chat_updated',
    'chat_deleted',
  ]);
});

// Message events stream
final messageEventsStreamProvider = StreamProvider<WebSocketMessage>((ref) {
  final service = ref.watch(websocketServiceProvider);
  return service.subscribeToEvents([
    'message_received',
    'message_sent',
    'message_updated',
    'message_deleted',
    'message_delivered',
    'message_read',
  ]);
});

// Typing events stream
final typingEventsStreamProvider = StreamProvider<WebSocketMessage>((ref) {
  final service = ref.watch(websocketServiceProvider);
  return service.subscribeToEvents([
    'user_typing',
    'user_stopped_typing',
  ]);
});

// Presence events stream
final presenceEventsStreamProvider = StreamProvider<WebSocketMessage>((ref) {
  final service = ref.watch(websocketServiceProvider);
  return service.subscribeToEvents([
    'user_online',
    'user_offline',
  ]);
});

// Reaction events stream
final reactionEventsStreamProvider = StreamProvider<WebSocketMessage>((ref) {
  final service = ref.watch(websocketServiceProvider);
  return service.subscribeToEvents([
    'reaction_added',
    'reaction_removed',
  ]);
});

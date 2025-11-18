// lib/features/groups/services/group_websocket_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:phoenix_socket/phoenix_socket.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:textgb/features/groups/models/group_message_model.dart';

// WebSocket events for group chats
enum GroupWebSocketEvent {
  // Message events
  newMessage,
  deleteMessage,
  messageRead,
  messageDeleted,

  // Typing events
  typing,
  stopTyping,
  userTyping,
  userStoppedTyping,

  // Member events
  memberJoined,
  memberLeft,
  memberAdded,
  memberRemoved,

  // Group events
  groupUpdated,
  markRead,
}

class GroupWebSocketService {
  // Singleton pattern
  static final GroupWebSocketService _instance =
      GroupWebSocketService._internal();
  factory GroupWebSocketService() => _instance;
  GroupWebSocketService._internal();

  // Phoenix Socket configuration
  static String get _wsUrl {
    if (kDebugMode) {
      // Use your Elixir Phoenix server URL
      return 'ws://localhost:4000/socket/websocket';
    } else {
      return 'ws://144.126.252.66:4000/socket/websocket';
    }
  }

  // Socket and channels
  PhoenixSocket? _socket;
  final Map<String, PhoenixChannel> _channels = {};
  final Map<String, StreamController<Map<String, dynamic>>> _eventControllers =
      {};

  bool _isConnected = false;
  bool _isConnecting = false;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;

  // Connect to Phoenix WebSocket
  Future<void> connect() async {
    if (_isConnected || _isConnecting) {
      debugPrint('GroupWebSocket: Already connected or connecting');
      return;
    }

    _isConnecting = true;

    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not available');
      }

      final socketUrl = Uri.parse(_wsUrl);
      _socket = PhoenixSocket(
        socketUrl.toString(),
        socketOptions: PhoenixSocketOptions(
          params: {'token': token},
        ),
      );

      await _socket!.connect();

      _isConnected = true;
      _isConnecting = false;

      debugPrint('GroupWebSocket: Connected successfully');
    } catch (e) {
      _isConnecting = false;
      debugPrint('GroupWebSocket: Connection failed: $e');
      rethrow;
    }
  }

  // Disconnect from WebSocket
  Future<void> disconnect() async {
    debugPrint('GroupWebSocket: Disconnecting');

    // Leave all channels
    for (final channel in _channels.values) {
      channel.leave();
    }
    _channels.clear();

    // Close all event controllers
    for (final controller in _eventControllers.values) {
      await controller.close();
    }
    _eventControllers.clear();

    // Disconnect socket
    if (_socket != null) {
      _socket!.dispose();
      _socket = null;
    }

    _isConnected = false;
  }

  // Join a group channel
  Future<PhoenixChannel> joinGroup(String groupId) async {
    if (!_isConnected) {
      await connect();
    }

    // Check if already joined
    if (_channels.containsKey(groupId)) {
      debugPrint('GroupWebSocket: Already joined group $groupId');
      return _channels[groupId]!;
    }

    final channelName = 'group:$groupId';
    final channel = _socket!.addChannel(topic: channelName);

    // Set up event stream controller for this group
    _eventControllers[groupId] =
        StreamController<Map<String, dynamic>>.broadcast();

    // Listen to all events on this channel
    channel.messages.listen((message) {
      debugPrint('GroupWebSocket: Received message on $channelName: ${message.event}');

      final eventData = {
        'event': message.event.value,
        'payload': message.payload,
      };

      _eventControllers[groupId]?.add(eventData);
    });

    // Join the channel
    try {
      final push = channel.join();
      final pushResponse = await push.future;

      if (pushResponse.isOk) {
        _channels[groupId] = channel;
        debugPrint('GroupWebSocket: Joined group $groupId successfully');
        return channel;
      } else {
        debugPrint('GroupWebSocket: Failed to join group $groupId: ${pushResponse.response}');
        throw Exception('Failed to join group channel');
      }
    } catch (e) {
      debugPrint('GroupWebSocket: Error joining group $groupId: $e');
      throw Exception('Failed to join group channel: $e');
    }
  }

  // Leave a group channel
  Future<void> leaveGroup(String groupId) async {
    final channel = _channels[groupId];
    if (channel == null) {
      debugPrint('GroupWebSocket: Not in group $groupId');
      return;
    }

    channel.leave();
    _channels.remove(groupId);

    // Close event stream
    await _eventControllers[groupId]?.close();
    _eventControllers.remove(groupId);

    debugPrint('GroupWebSocket: Left group $groupId');
  }

  // Get event stream for a specific group
  Stream<Map<String, dynamic>> getGroupEventStream(String groupId) {
    if (!_eventControllers.containsKey(groupId)) {
      _eventControllers[groupId] =
          StreamController<Map<String, dynamic>>.broadcast();
    }
    return _eventControllers[groupId]!.stream;
  }

  // ==================== MESSAGE ACTIONS ====================

  /// Send a message to the group
  Future<void> sendMessage({
    required String groupId,
    required String messageText,
    String? mediaUrl,
    String mediaType = 'text',
  }) async {
    final channel = _channels[groupId];
    if (channel == null) {
      throw Exception('Not joined to group $groupId');
    }

    channel.push('new_message', {
      'message_text': messageText,
      if (mediaUrl != null) 'media_url': mediaUrl,
      'media_type': mediaType,
    });

    debugPrint('GroupWebSocket: Sent message to group $groupId');
  }

  /// Delete a message
  Future<void> deleteMessage({
    required String groupId,
    required String messageId,
  }) async {
    final channel = _channels[groupId];
    if (channel == null) {
      throw Exception('Not joined to group $groupId');
    }

    channel.push('delete_message', {
      'message_id': messageId,
    });

    debugPrint('GroupWebSocket: Deleted message $messageId in group $groupId');
  }

  /// Mark messages as read
  Future<void> markRead({
    required String groupId,
    required String messageId,
  }) async {
    final channel = _channels[groupId];
    if (channel == null) {
      throw Exception('Not joined to group $groupId');
    }

    channel.push('mark_read', {
      'message_id': messageId,
    });

    debugPrint('GroupWebSocket: Marked message $messageId as read in group $groupId');
  }

  // ==================== TYPING INDICATORS ====================

  /// Send typing indicator
  Future<void> sendTyping(String groupId) async {
    final channel = _channels[groupId];
    if (channel == null) {
      throw Exception('Not joined to group $groupId');
    }

    channel.push('typing', {});
    debugPrint('GroupWebSocket: Sent typing indicator to group $groupId');
  }

  /// Send stop typing indicator
  Future<void> sendStopTyping(String groupId) async {
    final channel = _channels[groupId];
    if (channel == null) {
      throw Exception('Not joined to group $groupId');
    }

    channel.push('stop_typing', {});
    debugPrint('GroupWebSocket: Sent stop typing indicator to group $groupId');
  }

  // ==================== HELPER METHODS ====================

  /// Get Firebase auth token
  Future<String?> _getAuthToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
    } catch (e) {
      debugPrint('GroupWebSocket: Failed to get auth token: $e');
    }
    return null;
  }

  /// Subscribe to specific event type
  Stream<Map<String, dynamic>> subscribeToEvent(
      String groupId, String eventType) {
    return getGroupEventStream(groupId)
        .where((event) => event['event'] == eventType);
  }

  /// Subscribe to multiple event types
  Stream<Map<String, dynamic>> subscribeToEvents(
      String groupId, List<String> eventTypes) {
    return getGroupEventStream(groupId)
        .where((event) => eventTypes.contains(event['event']));
  }

  /// Dispose
  Future<void> dispose() async {
    await disconnect();
  }

  // ==================== CONVENIENCE METHODS ====================

  /// Listen to new messages
  Stream<GroupMessageModel> listenToNewMessages(String groupId) {
    return subscribeToEvent(groupId, 'new_message').map((event) {
      final payload = event['payload'] as Map<String, dynamic>;
      return GroupMessageModel.fromJson(payload['message'] ?? payload);
    });
  }

  /// Listen to deleted messages
  Stream<String> listenToDeletedMessages(String groupId) {
    return subscribeToEvent(groupId, 'message_deleted').map((event) {
      final payload = event['payload'] as Map<String, dynamic>;
      return payload['message_id'] as String;
    });
  }

  /// Listen to typing indicators
  Stream<Map<String, dynamic>> listenToTyping(String groupId) {
    return subscribeToEvents(groupId, ['user_typing', 'user_stopped_typing']);
  }

  /// Listen to member changes
  Stream<Map<String, dynamic>> listenToMemberChanges(String groupId) {
    return subscribeToEvents(
        groupId, ['member_joined', 'member_left', 'member_added', 'member_removed']);
  }

  /// Listen to group updates
  Stream<Map<String, dynamic>> listenToGroupUpdates(String groupId) {
    return subscribeToEvent(groupId, 'group_updated');
  }
}
// lib/shared/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:firebase_auth/firebase_auth.dart';

enum WebSocketEvent {
  // Connection events
  connected,
  disconnected,
  error,
  reconnecting,
  
  // Chat events
  chatCreated,
  chatUpdated,
  chatDeleted,
  
  // Message events
  messageReceived,
  messageSent,
  messageUpdated,
  messageDeleted,
  messageDelivered,
  messageRead,
  
  // Typing events
  userTyping,
  userStoppedTyping,
  
  // Presence events
  userOnline,
  userOffline,
  
  // Reaction events
  reactionAdded,
  reactionRemoved,
}

class WebSocketMessage {
  final String type;
  final Map<String, dynamic> data;
  final String? id;
  final DateTime timestamp;

  WebSocketMessage({
    required this.type,
    required this.data,
    this.id,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
      'id': id,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
      id: json['id'] as String?,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}

class WebSocketService {
  // Singleton pattern
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  // WebSocket configuration
  static String get _wsUrl {
    if (kDebugMode) {
      return 'ws://144.126.252.66:8080/ws';
    } else {
      return 'ws://144.126.252.66:8080/ws';
    }
  }

  // Connection state
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 2);
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  Timer? _connectionTimeoutTimer;
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _connectionTimeout = Duration(seconds: 10);

  // Message handling
  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};
  int _messageIdCounter = 0;

  // Event streams
  final _eventController = StreamController<WebSocketMessage>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // Public streams
  Stream<WebSocketMessage> get eventStream => _eventController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  Stream<String> get errorStream => _errorController.stream;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;

  // Connect to WebSocket server
  Future<void> connect() async {
    if (_isConnected || _isConnecting) {
      debugPrint('WebSocket: Already connected or connecting');
      return;
    }

    _isConnecting = true;
    _shouldReconnect = true;

    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw WebSocketException('Authentication token not available');
      }

      final uri = Uri.parse('$_wsUrl?token=$token');
      debugPrint('WebSocket: Connecting to $uri');

      _connectionTimeoutTimer?.cancel();
      _connectionTimeoutTimer = Timer(_connectionTimeout, () {
        if (_isConnecting) {
          debugPrint('WebSocket: Connection timeout');
          _handleConnectionError('Connection timeout');
        }
      });

      _channel = WebSocketChannel.connect(uri);
      
      // Listen to messages
      _channelSubscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleConnectionError,
        onDone: _handleConnectionClosed,
        cancelOnError: false,
      );

      // Wait for initial connection confirmation
      await _waitForConnection();

      _connectionTimeoutTimer?.cancel();
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      
      _connectionStateController.add(true);
      debugPrint('WebSocket: Connected successfully');

      // Start heartbeat
      _startHeartbeat();

      // Emit connected event
      _emitEvent(WebSocketEvent.connected, {});

    } catch (e) {
      _connectionTimeoutTimer?.cancel();
      _isConnecting = false;
      debugPrint('WebSocket: Connection failed: $e');
      _errorController.add('Connection failed: $e');
      
      if (_shouldReconnect) {
        _scheduleReconnect();
      }
    }
  }

  // Wait for initial connection confirmation
  Future<void> _waitForConnection() async {
    final completer = Completer<void>();
    Timer? timeoutTimer;

    final subscription = _eventController.stream.listen((message) {
      if (message.type == 'connection_established') {
        timeoutTimer?.cancel();
        completer.complete();
      }
    });

    timeoutTimer = Timer(_connectionTimeout, () {
      if (!completer.isCompleted) {
        completer.completeError('Connection confirmation timeout');
      }
    });

    try {
      await completer.future;
    } finally {
      await subscription.cancel();
      timeoutTimer.cancel();
    }
  }

  // Disconnect from WebSocket server
  Future<void> disconnect() async {
    debugPrint('WebSocket: Disconnecting');
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _connectionTimeoutTimer?.cancel();
    
    await _channelSubscription?.cancel();
    await _channel?.sink.close(status.normalClosure);
    
    _channel = null;
    _channelSubscription = null;
    _isConnected = false;
    _isConnecting = false;
    
    _connectionStateController.add(false);
    _emitEvent(WebSocketEvent.disconnected, {});
  }

  // Send message to server
  Future<Map<String, dynamic>?> send(String type, Map<String, dynamic> data, {bool waitForResponse = false}) async {
    if (!_isConnected) {
      throw WebSocketException('WebSocket not connected');
    }

    final messageId = _generateMessageId();
    final message = WebSocketMessage(
      type: type,
      data: data,
      id: messageId,
    );

    Completer<Map<String, dynamic>>? completer;
    if (waitForResponse) {
      completer = Completer<Map<String, dynamic>>();
      _pendingRequests[messageId] = completer;

      // Set timeout for response
      Timer(const Duration(seconds: 30), () {
        if (_pendingRequests.containsKey(messageId)) {
          _pendingRequests.remove(messageId);
          if (!completer!.isCompleted) {
            completer.completeError('Request timeout');
          }
        }
      });
    }

    try {
      final jsonMessage = jsonEncode(message.toJson());
      _channel!.sink.add(jsonMessage);
      debugPrint('WebSocket: Sent message: $type');

      if (waitForResponse && completer != null) {
        return await completer.future;
      }
      return null;
    } catch (e) {
      _pendingRequests.remove(messageId);
      debugPrint('WebSocket: Failed to send message: $e');
      rethrow;
    }
  }

  // Handle incoming messages
  void _handleMessage(dynamic message) {
    try {
      final jsonMessage = jsonDecode(message as String) as Map<String, dynamic>;
      final wsMessage = WebSocketMessage.fromJson(jsonMessage);

      debugPrint('WebSocket: Received message: ${wsMessage.type}');

      // Handle response to pending request
      if (wsMessage.id != null && _pendingRequests.containsKey(wsMessage.id)) {
        final completer = _pendingRequests.remove(wsMessage.id);
        if (!completer!.isCompleted) {
          completer.complete(wsMessage.data);
        }
        return;
      }

      // Handle different message types
      switch (wsMessage.type) {
        case 'connection_established':
          debugPrint('WebSocket: Connection established');
          break;
        
        case 'pong':
          debugPrint('WebSocket: Heartbeat acknowledged');
          break;

        case 'error':
          final error = wsMessage.data['message'] as String? ?? 'Unknown error';
          _errorController.add(error);
          break;

        default:
          // Emit event for all other message types
          _eventController.add(wsMessage);
      }

    } catch (e) {
      debugPrint('WebSocket: Failed to handle message: $e');
      _errorController.add('Failed to handle message: $e');
    }
  }

  // Handle connection errors
  void _handleConnectionError(dynamic error) {
    debugPrint('WebSocket: Connection error: $error');
    _isConnected = false;
    _connectionStateController.add(false);
    _errorController.add('Connection error: $error');
    _emitEvent(WebSocketEvent.error, {'error': error.toString()});

    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  // Handle connection closed
  void _handleConnectionClosed() {
    debugPrint('WebSocket: Connection closed');
    _isConnected = false;
    _heartbeatTimer?.cancel();
    _connectionStateController.add(false);
    _emitEvent(WebSocketEvent.disconnected, {});

    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  // Schedule reconnection
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('WebSocket: Max reconnection attempts reached');
      _errorController.add('Failed to reconnect after $_maxReconnectAttempts attempts');
      return;
    }

    _reconnectAttempts++;
    final delay = _reconnectDelay * _reconnectAttempts;
    
    debugPrint('WebSocket: Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s');
    _emitEvent(WebSocketEvent.reconnecting, {'attempt': _reconnectAttempts});

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      debugPrint('WebSocket: Attempting to reconnect...');
      connect();
    });
  }

  // Start heartbeat
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_isConnected) {
        try {
          send('ping', {});
        } catch (e) {
          debugPrint('WebSocket: Heartbeat failed: $e');
          _handleConnectionError('Heartbeat failed');
        }
      }
    });
  }

  // Get Firebase auth token
  Future<String?> _getAuthToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
    } catch (e) {
      debugPrint('WebSocket: Failed to get auth token: $e');
    }
    return null;
  }

  // Generate unique message ID
  String _generateMessageId() {
    return 'ws_msg_${DateTime.now().millisecondsSinceEpoch}_${_messageIdCounter++}';
  }

  // Emit event
  void _emitEvent(WebSocketEvent event, Map<String, dynamic> data) {
    final message = WebSocketMessage(
      type: event.name,
      data: data,
    );
    _eventController.add(message);
  }

  // Subscribe to specific event type
  Stream<WebSocketMessage> subscribeToEvent(String eventType) {
    return _eventController.stream.where((message) => message.type == eventType);
  }

  // Subscribe to multiple event types
  Stream<WebSocketMessage> subscribeToEvents(List<String> eventTypes) {
    return _eventController.stream.where((message) => eventTypes.contains(message.type));
  }

  // Dispose
  Future<void> dispose() async {
    await disconnect();
    await _eventController.close();
    await _connectionStateController.close();
    await _errorController.close();
    _pendingRequests.clear();
  }

  // Public API methods for video reaction chats

  // Subscribe to chat updates
  Future<void> subscribeToChat(String chatId) async {
    await send('subscribe_chat', {'chatId': chatId});
  }

  // Unsubscribe from chat updates
  Future<void> unsubscribeFromChat(String chatId) async {
    await send('unsubscribe_chat', {'chatId': chatId});
  }

  // Subscribe to all user's chats
  Future<void> subscribeToUserChats(String userId) async {
    await send('subscribe_user_chats', {'userId': userId});
  }

  // Send typing indicator
  Future<void> sendTypingIndicator(String chatId, bool isTyping) async {
    await send('typing', {
      'chatId': chatId,
      'isTyping': isTyping,
    });
  }

  // Mark message as delivered
  Future<void> markMessageDelivered(String chatId, String messageId) async {
    await send('message_delivered', {
      'chatId': chatId,
      'messageId': messageId,
    });
  }

  // Mark message as read
  // ⚠️ PRIVACY: Intentionally NOT called - WeChat-like privacy (no read receipts)
  // This method exists for backend compatibility but is never invoked
  Future<void> markMessageRead(String chatId, String messageId) async {
    await send('message_read', {
      'chatId': chatId,
      'messageId': messageId,
    });
  }

  // Mark chat as read (updates unread count only, does not send read receipts)
  Future<void> markChatRead(String chatId) async {
    await send('chat_read', {
      'chatId': chatId,
    });
  }

  // Update user presence
  Future<void> updatePresence(bool isOnline) async {
    await send('presence', {
      'isOnline': isOnline,
    });
  }

  // Send message through WebSocket
  Future<Map<String, dynamic>?> sendMessage(Map<String, dynamic> messageData) async {
    return await send('send_message', messageData, waitForResponse: true);
  }

  // Create chat through WebSocket
  Future<Map<String, dynamic>?> createChat(Map<String, dynamic> chatData) async {
    return await send('create_chat', chatData, waitForResponse: true);
  }

  // Update message through WebSocket
  Future<void> updateMessage(String chatId, String messageId, Map<String, dynamic> updates) async {
    await send('update_message', {
      'chatId': chatId,
      'messageId': messageId,
      'updates': updates,
    });
  }

  // Delete message through WebSocket
  Future<void> deleteMessage(String chatId, String messageId, bool deleteForEveryone) async {
    await send('delete_message', {
      'chatId': chatId,
      'messageId': messageId,
      'deleteForEveryone': deleteForEveryone,
    });
  }

  // Pin message through WebSocket
  Future<void> pinMessage(String chatId, String messageId) async {
    await send('pin_message', {
      'chatId': chatId,
      'messageId': messageId,
    });
  }

  // Unpin message through WebSocket
  Future<void> unpinMessage(String chatId, String messageId) async {
    await send('unpin_message', {
      'chatId': chatId,
      'messageId': messageId,
    });
  }

  // Add reaction to message
  Future<void> addReaction(String chatId, String messageId, String reaction) async {
    await send('add_reaction', {
      'chatId': chatId,
      'messageId': messageId,
      'reaction': reaction,
    });
  }

  // Remove reaction from message
  Future<void> removeReaction(String chatId, String messageId) async {
    await send('remove_reaction', {
      'chatId': chatId,
      'messageId': messageId,
    });
  }
}

// Custom exception for WebSocket errors
class WebSocketException implements Exception {
  final String message;
  const WebSocketException(this.message);
  
  @override
  String toString() => 'WebSocketException: $message';
}
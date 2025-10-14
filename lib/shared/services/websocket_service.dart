// lib/shared/services/websocket_service.dart
// WebSocket service for real-time messaging
// Handles connection, reconnection, and message events

import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

/// WebSocket message types
enum WSMessageType {
  // Connection
  connect('connect'),
  disconnect('disconnect'),
  ping('ping'),
  pong('pong'),
  
  // Chat messages
  newMessage('new_message'),
  messageStatus('message_status'),
  messageDeleted('message_deleted'),
  messageReaction('message_reaction'),
  
  // Chat operations
  chatCreated('chat_created'),
  chatUpdated('chat_updated'),
  chatDeleted('chat_deleted'),
  
  // Group operations
  participantAdded('participant_added'),
  participantRemoved('participant_removed'),
  participantPromoted('participant_promoted'),
  participantDemoted('participant_demoted'),
  
  // Status updates
  userOnline('user_online'),
  userOffline('user_offline'),
  
  // Error
  error('error');

  const WSMessageType(this.value);
  final String value;

  static WSMessageType fromString(String? value) {
    return WSMessageType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WSMessageType.error,
    );
  }
}

/// WebSocket connection state
enum WSConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// WebSocket message model
class WSMessage {
  final WSMessageType type;
  final Map<String, dynamic> data;
  final String? messageId;
  final DateTime timestamp;

  WSMessage({
    required this.type,
    required this.data,
    this.messageId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory WSMessage.fromJson(Map<String, dynamic> json) {
    return WSMessage(
      type: WSMessageType.fromString(json['type']),
      data: json['data'] ?? {},
      messageId: json['messageId'] ?? json['message_id'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'data': data,
      if (messageId != null) 'messageId': messageId,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// WebSocket service for real-time communication
class WebSocketService {
  // WebSocket URL based on environment
  static String get _wsUrl {
    if (kDebugMode) {
      // For development - use production server for now
      return 'ws://144.126.252.66:8080/ws';
      
      // Alternative: Use localhost only for iOS simulator
      // if (Platform.isIOS) {
      //   return 'ws://localhost:8080/ws';
      // } else {
      //   return 'ws://64.227.142.38:8080/ws';
      // }
    } else {
      return 'ws://144.126.252.66:8080/ws';
    }
  }

  // Singleton pattern
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  // WebSocket channel
  WebSocketChannel? _channel;
  
  // Connection state
  WSConnectionState _connectionState = WSConnectionState.disconnected;
  final _connectionStateController = StreamController<WSConnectionState>.broadcast();
  
  // Message streams
  final _messageController = StreamController<WSMessage>.broadcast();
  
  // Reconnection settings
  static const int _maxReconnectAttempts = 5;
  static const Duration _initialReconnectDelay = Duration(seconds: 1);
  static const Duration _maxReconnectDelay = Duration(seconds: 30);
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  
  // Current user info
  String? _currentUserId;
  String? _authToken;

  // ===============================
  // PUBLIC GETTERS
  // ===============================

  bool get isConnected => _connectionState == WSConnectionState.connected;
  WSConnectionState get connectionState => _connectionState;
  Stream<WSConnectionState> get connectionStateStream => _connectionStateController.stream;
  Stream<WSMessage> get messageStream => _messageController.stream;

  // ===============================
  // CONNECTION MANAGEMENT
  // ===============================

  /// Connect to WebSocket server
  Future<void> connect() async {
    if (_connectionState == WSConnectionState.connected ||
        _connectionState == WSConnectionState.connecting) {
      debugPrint('🔌 Already connected or connecting');
      return;
    }

    try {
      _updateConnectionState(WSConnectionState.connecting);
      debugPrint('🔌 Connecting to WebSocket: $_wsUrl');

      // Get auth token and user ID
      await _getAuthInfo();

      if (_authToken == null || _currentUserId == null) {
        throw Exception('Authentication required');
      }

      // Create WebSocket connection with auth token
      final uri = Uri.parse('$_wsUrl?token=$_authToken&userId=$_currentUserId');
      _channel = WebSocketChannel.connect(uri);

      // Listen to messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      // Send connect message
      _sendMessage(WSMessage(
        type: WSMessageType.connect,
        data: {
          'userId': _currentUserId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));

      _updateConnectionState(WSConnectionState.connected);
      _reconnectAttempts = 0;
      
      // Start ping timer
      _startPingTimer();

      debugPrint('✅ WebSocket connected successfully');
    } catch (e) {
      debugPrint('❌ WebSocket connection failed: $e');
      _updateConnectionState(WSConnectionState.error);
      _scheduleReconnect();
    }
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    debugPrint('🔌 Disconnecting from WebSocket');
    
    _cancelReconnect();
    _cancelPingTimer();
    
    if (_channel != null) {
      // Send disconnect message
      try {
        _sendMessage(WSMessage(
          type: WSMessageType.disconnect,
          data: {'userId': _currentUserId},
        ));
      } catch (e) {
        debugPrint('Error sending disconnect message: $e');
      }

      await _channel?.sink.close(status.goingAway);
      _channel = null;
    }

    _updateConnectionState(WSConnectionState.disconnected);
    debugPrint('✅ WebSocket disconnected');
  }

  /// Reconnect to WebSocket server
  Future<void> reconnect() async {
    debugPrint('🔄 Manually reconnecting to WebSocket');
    await disconnect();
    await connect();
  }

  // ===============================
  // MESSAGE HANDLING
  // ===============================

  /// Handle incoming WebSocket message
  void _handleMessage(dynamic message) {
    try {
      final jsonData = jsonDecode(message as String);
      final wsMessage = WSMessage.fromJson(jsonData);

      debugPrint('📩 Received WS message: ${wsMessage.type.value}');

      // Handle pong response
      if (wsMessage.type == WSMessageType.pong) {
        debugPrint('🏓 Pong received');
        return;
      }

      // Broadcast message to listeners
      _messageController.add(wsMessage);
    } catch (e) {
      debugPrint('❌ Error parsing WebSocket message: $e');
    }
  }

  /// Handle WebSocket error
  void _handleError(dynamic error) {
    debugPrint('❌ WebSocket error: $error');
    _updateConnectionState(WSConnectionState.error);
    _scheduleReconnect();
  }

  /// Handle WebSocket disconnect
  void _handleDisconnect() {
    debugPrint('🔌 WebSocket disconnected');
    _updateConnectionState(WSConnectionState.disconnected);
    _cancelPingTimer();
    _scheduleReconnect();
  }

  // ===============================
  // SENDING MESSAGES
  // ===============================

  /// Send a message through WebSocket
  void sendMessage(WSMessage message) {
    if (!isConnected) {
      debugPrint('⚠️ Cannot send message - not connected');
      throw Exception('WebSocket not connected');
    }

    _sendMessage(message);
  }

  void _sendMessage(WSMessage message) {
    try {
      final jsonString = jsonEncode(message.toJson());
      _channel?.sink.add(jsonString);
      debugPrint('📤 Sent WS message: ${message.type.value}');
    } catch (e) {
      debugPrint('❌ Error sending WebSocket message: $e');
      rethrow;
    }
  }

  /// Send a text message
  void sendTextMessage({
    required String chatId,
    required String content,
    String? repliedToMessageId,
  }) {
    sendMessage(WSMessage(
      type: WSMessageType.newMessage,
      data: {
        'chatId': chatId,
        'senderId': _currentUserId,
        'content': content,
        'type': 'text',
        if (repliedToMessageId != null) 'repliedToMessageId': repliedToMessageId,
      },
    ));
  }

  /// Update message status
  void updateMessageStatus({
    required String messageId,
    required String status,
  }) {
    sendMessage(WSMessage(
      type: WSMessageType.messageStatus,
      messageId: messageId,
      data: {
        'messageId': messageId,
        'status': status,
        'userId': _currentUserId,
      },
    ));
  }

  /// Send message reaction
  void sendReaction({
    required String messageId,
    required String emoji,
    required bool isAdd,
  }) {
    sendMessage(WSMessage(
      type: WSMessageType.messageReaction,
      messageId: messageId,
      data: {
        'messageId': messageId,
        'emoji': emoji,
        'userId': _currentUserId,
        'action': isAdd ? 'add' : 'remove',
      },
    ));
  }

  // ===============================
  // RECONNECTION LOGIC
  // ===============================

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('❌ Max reconnection attempts reached');
      _updateConnectionState(WSConnectionState.error);
      return;
    }

    if (_reconnectTimer?.isActive ?? false) {
      return; // Already scheduled
    }

    _updateConnectionState(WSConnectionState.reconnecting);
    
    // Calculate exponential backoff delay
    final delay = _calculateReconnectDelay();
    _reconnectAttempts++;

    debugPrint('🔄 Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s');

    _reconnectTimer = Timer(delay, () async {
      debugPrint('🔄 Attempting reconnect $_reconnectAttempts/$_maxReconnectAttempts');
      await connect();
    });
  }

  Duration _calculateReconnectDelay() {
    final exponentialDelay = _initialReconnectDelay * (1 << (_reconnectAttempts - 1));
    return exponentialDelay > _maxReconnectDelay ? _maxReconnectDelay : exponentialDelay;
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
  }

  // ===============================
  // PING/PONG (KEEPALIVE)
  // ===============================

  void _startPingTimer() {
    _cancelPingTimer();
    
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (isConnected) {
        try {
          _sendMessage(WSMessage(
            type: WSMessageType.ping,
            data: {'timestamp': DateTime.now().toIso8601String()},
          ));
          debugPrint('🏓 Ping sent');
        } catch (e) {
          debugPrint('❌ Error sending ping: $e');
        }
      }
    });
  }

  void _cancelPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  // ===============================
  // AUTHENTICATION
  // ===============================

  Future<void> _getAuthInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _authToken = await user.getIdToken();
        _currentUserId = user.uid;
        debugPrint('🔐 Auth info retrieved for user: $_currentUserId');
      } else {
        throw Exception('No authenticated user');
      }
    } catch (e) {
      debugPrint('❌ Failed to get auth info: $e');
      rethrow;
    }
  }

  // ===============================
  // STATE MANAGEMENT
  // ===============================

  void _updateConnectionState(WSConnectionState state) {
    _connectionState = state;
    _connectionStateController.add(state);
    debugPrint('🔌 Connection state: ${state.name}');
  }

  // ===============================
  // CLEANUP
  // ===============================

  /// Dispose of the service
  Future<void> dispose() async {
    await disconnect();
    await _messageController.close();
    await _connectionStateController.close();
  }
}
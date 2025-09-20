// lib/features/chat/services/websocket_chat_service.dart
// Real-time WebSocket chat service
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/enums/enums.dart';

class WebSocketChatService {
  static final WebSocketChatService _instance = WebSocketChatService._internal();
  factory WebSocketChatService() => _instance;
  WebSocketChatService._internal();

  // WebSocket connection
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  
  // Connection state
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const int _reconnectDelaySeconds = 5;

  // Authentication
  String? _currentUserId;
  String? _authToken;

  // Chat subscriptions
  final Set<String> _subscribedChats = {};

  // Stream controllers for real-time updates
  final StreamController<MessageModel> _messageController = 
      StreamController<MessageModel>.broadcast();
  final StreamController<ChatModel> _chatUpdateController = 
      StreamController<ChatModel>.broadcast();
  final StreamController<Map<String, dynamic>> _typingController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _userStatusController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionController = 
      StreamController<bool>.broadcast();

  // Pending messages (for offline support)
  final List<Map<String, dynamic>> _pendingMessages = [];

  // Message request tracking
  final Map<String, Completer<bool>> _messageCompleters = {};

  // Getters for streams
  Stream<MessageModel> get messageStream => _messageController.stream;
  Stream<ChatModel> get chatUpdateStream => _chatUpdateController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get userStatusStream => _userStatusController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  // Connection status
  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;

  // WebSocket URL
  String get _webSocketUrl {
    if (kDebugMode) {
      return 'ws://144.126.252.66:8080/api/v1/ws/chat';
    } else {
      return 'wss://144.126.252.66:8080/api/v1/ws/chat';
    }
  }

  // Connect to WebSocket
  Future<bool> connect(String userId, String authToken) async {
    if (_isConnecting || (_isConnected && _currentUserId == userId)) {
      return _isConnected;
    }

    _isConnecting = true;
    _currentUserId = userId;
    _authToken = authToken;
    _shouldReconnect = true;
    _reconnectAttempts = 0;

    try {
      debugPrint('🔌 Connecting to WebSocket: $_webSocketUrl');
      
      _channel = IOWebSocketChannel.connect(
        Uri.parse(_webSocketUrl),
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      );

      // Listen to messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );

      // Send authentication
      await _sendAuth();

      // Start ping timer
      _startPingTimer();

      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      _connectionController.add(true);

      debugPrint('✅ WebSocket connected successfully');

      // Send pending messages
      await _sendPendingMessages();

      return true;
    } catch (e) {
      debugPrint('❌ WebSocket connection failed: $e');
      _isConnecting = false;
      _handleConnectionFailure();
      return false;
    }
  }

  // Disconnect from WebSocket
  Future<void> disconnect() async {
    debugPrint('🔌 Disconnecting WebSocket');
    
    _shouldReconnect = false;
    _isConnected = false;
    _isConnecting = false;

    _reconnectTimer?.cancel();
    _pingTimer?.cancel();

    _subscribedChats.clear();
    _pendingMessages.clear();

    await _channel?.sink.close();
    _channel = null;

    _connectionController.add(false);
    debugPrint('🔌 WebSocket disconnected');
  }

  // Send authentication message
  Future<void> _sendAuth() async {
    final authMessage = {
      'type': 'auth',
      'data': {
        'userId': _currentUserId,
        'token': _authToken,
      },
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _sendMessage(authMessage);
  }

  // Join chat rooms
  Future<void> joinChats(List<String> chatIds) async {
    if (!_isConnected) {
      debugPrint('⚠️ Cannot join chats - not connected');
      return;
    }

    _subscribedChats.addAll(chatIds);

    final joinMessage = {
      'type': 'join_chats',
      'data': {
        'chatIds': chatIds,
      },
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _sendMessage(joinMessage);
    debugPrint('📱 Joined chats: $chatIds');
  }

  // Leave chat rooms
  Future<void> leaveChats(List<String> chatIds) async {
    if (!_isConnected) {
      return;
    }

    _subscribedChats.removeAll(chatIds);

    final leaveMessage = {
      'type': 'leave_chats',
      'data': {
        'chatIds': chatIds,
      },
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _sendMessage(leaveMessage);
    debugPrint('📱 Left chats: $chatIds');
  }

  // Send message via WebSocket
  Future<bool> sendMessage(MessageModel message) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    final completer = Completer<bool>();
    _messageCompleters[requestId] = completer;

    final messageData = {
      'type': 'send_message',
      'data': {
        'message': message.toMap(),
      },
      'chatId': message.chatId,
      'requestId': requestId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (_isConnected) {
      try {
        await _sendMessage(messageData);
        debugPrint('📤 Message sent via WebSocket: ${message.messageId}');
        
        // Wait for confirmation with timeout
        return await completer.future.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            _messageCompleters.remove(requestId);
            return false;
          },
        );
      } catch (e) {
        debugPrint('❌ Failed to send message via WebSocket: $e');
        _messageCompleters.remove(requestId);
        _addToPendingMessages(messageData);
        return false;
      }
    } else {
      debugPrint('⚠️ WebSocket not connected - adding to pending messages');
      _messageCompleters.remove(requestId);
      _addToPendingMessages(messageData);
      return false;
    }
  }

  // Send typing status
  Future<void> sendTypingStatus(String chatId, bool isTyping) async {
    if (!_isConnected) return;

    final typingMessage = {
      'type': isTyping ? 'typing_start' : 'typing_stop',
      'data': {
        'chatId': chatId,
        'userId': _currentUserId,
        'isTyping': isTyping,
      },
      'chatId': chatId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _sendMessage(typingMessage);
  }

  // Handle incoming WebSocket messages
  void _handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data as String) as Map<String, dynamic>;
      final type = message['type'] as String;

      debugPrint('📨 Received WebSocket message: $type');

      switch (type) {
        case 'message_received':
          _handleMessageReceived(message);
          break;
        case 'message_sent':
          _handleMessageSent(message);
          break;
        case 'message_failed':
          _handleMessageFailed(message);
          break;
        case 'chat_updated':
          _handleChatUpdated(message);
          break;
        case 'typing_start':
        case 'typing_stop':
          _handleTypingStatus(message);
          break;
        case 'user_online':
        case 'user_offline':
          _handleUserStatus(message);
          break;
        case 'error':
          _handleErrorMessage(message);
          break;
        case 'pong':
          // Pong received - connection is alive
          break;
        default:
          debugPrint('🤷 Unknown message type: $type');
      }
    } catch (e) {
      debugPrint('❌ Error handling WebSocket message: $e');
    }
  }

  void _handleMessageReceived(Map<String, dynamic> message) {
    try {
      final messageData = message['data'] as Map<String, dynamic>;
      final chatMessage = MessageModel.fromMap(messageData);
      _messageController.add(chatMessage);
      debugPrint('📨 New message received: ${chatMessage.messageId}');
    } catch (e) {
      debugPrint('❌ Error parsing received message: $e');
    }
  }

  void _handleMessageSent(Map<String, dynamic> message) {
    final requestId = message['requestId'] as String?;
    if (requestId != null && _messageCompleters.containsKey(requestId)) {
      _messageCompleters[requestId]!.complete(true);
      _messageCompleters.remove(requestId);
      debugPrint('✅ Message confirmed sent: $requestId');
    }
  }

  void _handleMessageFailed(Map<String, dynamic> message) {
    final requestId = message['requestId'] as String?;
    if (requestId != null && _messageCompleters.containsKey(requestId)) {
      _messageCompleters[requestId]!.complete(false);
      _messageCompleters.remove(requestId);
      debugPrint('❌ Message failed: $requestId');
    }
  }

  void _handleChatUpdated(Map<String, dynamic> message) {
    try {
      final chatData = message['data'] as Map<String, dynamic>;
      final chat = ChatModel.fromMap(chatData);
      _chatUpdateController.add(chat);
      debugPrint('📱 Chat updated: ${chat.chatId}');
    } catch (e) {
      debugPrint('❌ Error parsing chat update: $e');
    }
  }

  void _handleTypingStatus(Map<String, dynamic> message) {
    try {
      final typingData = message['data'] as Map<String, dynamic>;
      _typingController.add({
        'chatId': typingData['chatId'],
        'userId': typingData['userId'],
        'isTyping': typingData['isTyping'],
        'type': message['type'],
      });
      debugPrint('⌨️ Typing status: ${typingData['userId']} - ${typingData['isTyping']}');
    } catch (e) {
      debugPrint('❌ Error parsing typing status: $e');
    }
  }

  void _handleUserStatus(Map<String, dynamic> message) {
    try {
      final statusData = message['data'] as Map<String, dynamic>;
      _userStatusController.add({
        'userId': statusData['userId'],
        'isOnline': statusData['isOnline'],
        'type': message['type'],
      });
      debugPrint('👤 User status: ${statusData['userId']} - ${statusData['isOnline']}');
    } catch (e) {
      debugPrint('❌ Error parsing user status: $e');
    }
  }

  void _handleErrorMessage(Map<String, dynamic> message) {
    try {
      final errorData = message['data'] as Map<String, dynamic>;
      final errorMessage = errorData['message'] as String;
      final errorCode = errorData['code'] as String?;
      debugPrint('🚨 WebSocket error: $errorMessage ($errorCode)');
    } catch (e) {
      debugPrint('❌ Error parsing error message: $e');
    }
  }

  // Handle WebSocket errors
  void _handleError(error) {
    debugPrint('❌ WebSocket error: $error');
    _handleConnectionFailure();
  }

  // Handle WebSocket disconnection
  void _handleDisconnect() {
    debugPrint('🔌 WebSocket disconnected');
    _isConnected = false;
    _connectionController.add(false);
    _handleConnectionFailure();
  }

  // Handle connection failures and implement reconnection
  void _handleConnectionFailure() {
    if (!_shouldReconnect) return;

    _isConnected = false;
    _isConnecting = false;
    _connectionController.add(false);

    _pingTimer?.cancel();

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      final delay = _reconnectDelaySeconds * _reconnectAttempts;
      
      debugPrint('🔄 Reconnecting in ${delay}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)');
      
      _reconnectTimer = Timer(Duration(seconds: delay), () {
        if (_shouldReconnect && _currentUserId != null && _authToken != null) {
          connect(_currentUserId!, _authToken!);
        }
      });
    } else {
      debugPrint('❌ Max reconnection attempts reached');
      _shouldReconnect = false;
    }
  }

  // Send raw message to WebSocket
  Future<void> _sendMessage(Map<String, dynamic> message) async {
    if (_channel?.sink != null) {
      _channel!.sink.add(jsonEncode(message));
    } else {
      throw Exception('WebSocket not connected');
    }
  }

  // Start ping timer to keep connection alive
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        _sendMessage({
          'type': 'ping',
          'timestamp': DateTime.now().toIso8601String(),
        }).catchError((e) {
          debugPrint('❌ Failed to send ping: $e');
        });
      } else {
        timer.cancel();
      }
    });
  }

  // Add message to pending queue for offline support
  void _addToPendingMessages(Map<String, dynamic> messageData) {
    _pendingMessages.add(messageData);
    debugPrint('📥 Added message to pending queue (${_pendingMessages.length} pending)');
  }

  // Send all pending messages when connection is restored
  Future<void> _sendPendingMessages() async {
    if (_pendingMessages.isEmpty) return;

    debugPrint('📤 Sending ${_pendingMessages.length} pending messages');
    
    final messagesToSend = List<Map<String, dynamic>>.from(_pendingMessages);
    _pendingMessages.clear();

    for (final messageData in messagesToSend) {
      try {
        await _sendMessage(messageData);
        debugPrint('✅ Pending message sent');
      } catch (e) {
        debugPrint('❌ Failed to send pending message: $e');
        _addToPendingMessages(messageData);
      }
    }
  }

  // Manually trigger reconnection
  Future<bool> reconnect() async {
    if (_currentUserId == null || _authToken == null) {
      debugPrint('❌ Cannot reconnect - missing auth data');
      return false;
    }

    debugPrint('🔄 Manual reconnection triggered');
    _reconnectAttempts = 0;
    await disconnect();
    await Future.delayed(const Duration(seconds: 1));
    return await connect(_currentUserId!, _authToken!);
  }

  // Get connection statistics
  Map<String, dynamic> getStats() {
    return {
      'isConnected': _isConnected,
      'isConnecting': _isConnecting,
      'reconnectAttempts': _reconnectAttempts,
      'subscribedChats': _subscribedChats.length,
      'pendingMessages': _pendingMessages.length,
      'activeRequestTrackers': _messageCompleters.length,
    };
  }

  // Dispose and cleanup
  void dispose() {
    debugPrint('🧹 Disposing WebSocketChatService');
    
    _shouldReconnect = false;
    disconnect();
    
    _messageController.close();
    _chatUpdateController.close();
    _typingController.close();
    _userStatusController.close();
    _connectionController.close();
    
    _subscribedChats.clear();
    _pendingMessages.clear();
    _messageCompleters.clear();
  }
}

// WebSocket message types (matching backend)
class WSMessageType {
  static const String auth = 'auth';
  static const String joinChats = 'join_chats';
  static const String leaveChats = 'leave_chats';
  static const String sendMessage = 'send_message';
  static const String messageReceived = 'message_received';
  static const String messageSent = 'message_sent';
  static const String messageFailed = 'message_failed';
  static const String typingStart = 'typing_start';
  static const String typingStop = 'typing_stop';
  static const String userOnline = 'user_online';
  static const String userOffline = 'user_offline';
  static const String chatUpdated = 'chat_updated';
  static const String error = 'error';
  static const String ping = 'ping';
  static const String pong = 'pong';
}

// Helper class for WebSocket connection status
enum WSConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

class WSConnectionState {
  final WSConnectionStatus status;
  final String? error;
  final int reconnectAttempts;
  final DateTime? lastConnected;

  const WSConnectionState({
    required this.status,
    this.error,
    this.reconnectAttempts = 0,
    this.lastConnected,
  });

  bool get isConnected => status == WSConnectionStatus.connected;
  bool get isConnecting => status == WSConnectionStatus.connecting || status == WSConnectionStatus.reconnecting;
  bool get hasError => error != null;

  WSConnectionState copyWith({
    WSConnectionStatus? status,
    String? error,
    int? reconnectAttempts,
    DateTime? lastConnected,
    bool clearError = false,
  }) {
    return WSConnectionState(
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      lastConnected: lastConnected ?? this.lastConnected,
    );
  }
}
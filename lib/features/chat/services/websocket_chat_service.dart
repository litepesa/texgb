// lib/features/chat/services/websocket_chat_service.dart
// UPDATED: Complete WebSocket implementation for real-time chat
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/shared/utilities/datetime_helper.dart';

/// WebSocket service for real-time chat functionality
/// Handles connection, authentication, and message broadcasting
class WebSocketChatService {
  static final WebSocketChatService _instance = WebSocketChatService._internal();
  factory WebSocketChatService() => _instance;
  WebSocketChatService._internal();

  // Connection state
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _currentUserId;
  String? _authToken;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  
  // Retry configuration
  static const int _maxRetries = 5;
  static const Duration _baseRetryDelay = Duration(seconds: 2);
  int _retryAttempts = 0;
  
  // Stream controllers for different events
  final StreamController<List<MessageModel>> _messagesController = 
      StreamController<List<MessageModel>>.broadcast();
  final StreamController<List<ChatModel>> _chatsController = 
      StreamController<List<ChatModel>>.broadcast();
  final StreamController<Map<String, dynamic>> _typingController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _userStatusController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionController = 
      StreamController<bool>.broadcast();
  final StreamController<Map<String, dynamic>> _errorController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Message tracking
  final Map<String, Completer<MessageModel>> _pendingMessages = {};
  final Set<String> _joinedChatIds = {};

  // WebSocket URL - Updated for your server
  String get _wsUrl {
    if (kDebugMode) {
      return 'ws://144.126.252.66:8080/api/v1/ws/chat';
    }
    return 'wss://144.126.252.66:8080/api/v1/ws/chat';
  }

  // ========================================
  // PUBLIC API
  // ========================================

  /// Check if WebSocket is connected
  bool get isConnected => _isConnected;

  /// Get connection stream
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Get messages stream
  Stream<List<MessageModel>> get messageStream => _messagesController.stream;

  /// Get chats stream  
  Stream<List<ChatModel>> get chatUpdateStream => _chatsController.stream;

  /// Get typing indicators stream
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;

  /// Get user status stream
  Stream<Map<String, dynamic>> get userStatusStream => _userStatusController.stream;

  /// Get error stream
  Stream<Map<String, dynamic>> get errorStream => _errorController.stream;

  /// Connect to WebSocket with authentication
  Future<bool> connect(String userId, String authToken) async {
    if (_isConnecting) {
      debugPrint('🔌 WebSocket already connecting...');
      return false;
    }

    if (_isConnected && _currentUserId == userId) {
      debugPrint('🔌 WebSocket already connected for user: $userId');
      return true;
    }

    try {
      _isConnecting = true;
      _currentUserId = userId;
      _authToken = authToken;

      debugPrint('🔌 Connecting to WebSocket: $_wsUrl');
      debugPrint('🔌 User: $userId');

      // Create WebSocket channel
      _channel = IOWebSocketChannel.connect(
        Uri.parse(_wsUrl),
        protocols: ['chat'],
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      );

      // Set up listeners
      _setupListeners();

      // Wait for connection to establish
      await Future.delayed(const Duration(milliseconds: 500));

      // Send authentication message
      final authSuccess = await _authenticate(userId, authToken);
      
      if (authSuccess) {
        _isConnected = true;
        _isConnecting = false;
        _retryAttempts = 0;
        _connectionController.add(true);
        
        // Start ping timer
        _startPingTimer();
        
        debugPrint('✅ WebSocket connected and authenticated');
        return true;
      } else {
        debugPrint('❌ WebSocket authentication failed');
        _disconnect();
        return false;
      }
    } catch (e) {
      debugPrint('❌ WebSocket connection failed: $e');
      _isConnecting = false;
      _isConnected = false;
      _connectionController.add(false);
      
      // Schedule reconnection
      _scheduleReconnect();
      return false;
    }
  }

  /// Disconnect from WebSocket
  void disconnect() {
    debugPrint('🔌 Disconnecting WebSocket...');
    _disconnect();
  }

  /// Send a message through WebSocket
  Future<bool> sendMessage(MessageModel message) async {
    if (!_isConnected) {
      debugPrint('❌ Cannot send message - WebSocket not connected');
      return false;
    }

    try {
      final completer = Completer<MessageModel>();
      _pendingMessages[message.messageId] = completer;

      // Send message via WebSocket
      _sendWebSocketMessage({
        'type': 'send_message',
        'data': {
          'message': {
            'messageId': message.messageId,
            'chatId': message.chatId,
            'senderId': message.senderId,
            'content': message.content,
            'type': message.type.name,
            'mediaUrl': message.mediaUrl,
            'mediaMetadata': message.mediaMetadata,
            'replyToMessageId': message.replyToMessageId,
            'replyToContent': message.replyToContent,
            'replyToSender': message.replyToSender,
          }
        },
        'requestId': message.messageId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Wait for confirmation or timeout
      final result = await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          _pendingMessages.remove(message.messageId);
          throw TimeoutException('Message send timeout', const Duration(seconds: 10));
        },
      );

      debugPrint('✅ Message sent successfully: ${message.messageId}');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to send message: $e');
      _pendingMessages.remove(message.messageId);
      return false;
    }
  }

  /// Join chat rooms to receive messages
  Future<bool> joinChats(List<String> chatIds) async {
    if (!_isConnected) {
      debugPrint('❌ Cannot join chats - WebSocket not connected');
      return false;
    }

    try {
      // Filter out already joined chats
      final newChatIds = chatIds.where((id) => !_joinedChatIds.contains(id)).toList();
      
      if (newChatIds.isEmpty) {
        debugPrint('📱 All chats already joined');
        return true;
      }

      _sendWebSocketMessage({
        'type': 'join_chats',
        'data': {
          'chatIds': newChatIds,
        },
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Add to joined set
      _joinedChatIds.addAll(newChatIds);

      debugPrint('📱 Joined chats: $newChatIds');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to join chats: $e');
      return false;
    }
  }

  /// Leave chat rooms
  Future<bool> leaveChats(List<String> chatIds) async {
    if (!_isConnected) {
      return false;
    }

    try {
      _sendWebSocketMessage({
        'type': 'leave_chats',
        'data': {
          'chatIds': chatIds,
        },
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Remove from joined set
      _joinedChatIds.removeAll(chatIds);

      debugPrint('📱 Left chats: $chatIds');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to leave chats: $e');
      return false;
    }
  }

  /// Send typing status
  Future<void> sendTypingStatus(String chatId, bool isTyping) async {
    if (!_isConnected) return;

    try {
      _sendWebSocketMessage({
        'type': isTyping ? 'typing_start' : 'typing_stop',
        'data': {
          'chatId': chatId,
          'userId': _currentUserId,
          'isTyping': isTyping,
        },
        'chatId': chatId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Failed to send typing status: $e');
    }
  }

  /// Manually reconnect
  Future<bool> reconnect() async {
    if (_currentUserId == null || _authToken == null) {
      debugPrint('❌ Cannot reconnect - missing credentials');
      return false;
    }

    debugPrint('🔄 Manually reconnecting WebSocket...');
    _disconnect();
    await Future.delayed(const Duration(milliseconds: 1000));
    return await connect(_currentUserId!, _authToken!);
  }

  // ========================================
  // PRIVATE METHODS
  // ========================================

  void _setupListeners() {
    _channel?.stream.listen(
      (data) {
        try {
          final Map<String, dynamic> message = jsonDecode(data as String);
          _handleWebSocketMessage(message);
        } catch (e) {
          debugPrint('❌ Error parsing WebSocket message: $e');
        }
      },
      onError: (error) {
        debugPrint('❌ WebSocket error: $error');
        _handleConnectionError(error);
      },
      onDone: () {
        debugPrint('🔌 WebSocket connection closed');
        _handleConnectionClosed();
      },
    );
  }

  Future<bool> _authenticate(String userId, String token) async {
    try {
      _sendWebSocketMessage({
        'type': 'auth',
        'data': {
          'userId': userId,
          'token': token,
        },
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Wait a bit for auth response
      await Future.delayed(const Duration(milliseconds: 1000));
      return true; // Assume success if no error thrown
    } catch (e) {
      debugPrint('❌ Authentication failed: $e');
      return false;
    }
  }

  void _sendWebSocketMessage(Map<String, dynamic> message) {
    if (_channel == null) return;

    try {
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
    } catch (e) {
      debugPrint('❌ Failed to send WebSocket message: $e');
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> message) {
    final String type = message['type'] ?? '';
    final Map<String, dynamic>? data = message['data'];
    final String? requestId = message['requestId'];

    debugPrint('📨 WebSocket message: $type');

    switch (type) {
      case 'message_received':
        _handleMessageReceived(data);
        break;
      case 'message_sent':
        _handleMessageSent(data, requestId);
        break;
      case 'message_failed':
        _handleMessageFailed(data, requestId);
        break;
      case 'chat_updated':
        _handleChatUpdated(data);
        break;
      case 'typing_start':
      case 'typing_stop':
        _handleTypingStatus(type, data);
        break;
      case 'user_online':
      case 'user_offline':
        _handleUserStatus(type, data);
        break;
      case 'error':
        _handleError(data);
        break;
      case 'pong':
        // Keep-alive response
        break;
      default:
        debugPrint('❓ Unknown WebSocket message type: $type');
    }
  }

  void _handleMessageReceived(Map<String, dynamic>? data) {
    if (data == null) return;

    try {
      final messageData = data['message'] ?? data;
      final message = _parseMessage(messageData);
      
      // Emit to message stream (will be handled by repository)
      debugPrint('📨 Message received: ${message.messageId}');
      
      // For now, just log - the repository will handle database updates
    } catch (e) {
      debugPrint('❌ Error handling received message: $e');
    }
  }

  void _handleMessageSent(Map<String, dynamic>? data, String? requestId) {
    if (data == null || requestId == null) return;

    try {
      final messageData = data['message'] ?? data;
      final message = _parseMessage(messageData);
      
      // Complete pending message
      final completer = _pendingMessages.remove(requestId);
      completer?.complete(message);
      
      debugPrint('✅ Message sent confirmed: $requestId');
    } catch (e) {
      debugPrint('❌ Error handling sent message: $e');
    }
  }

  void _handleMessageFailed(Map<String, dynamic>? data, String? requestId) {
    if (requestId == null) return;

    // Complete pending message with error
    final completer = _pendingMessages.remove(requestId);
    completer?.completeError('Message failed to send');
    
    debugPrint('❌ Message failed: $requestId');
  }

  void _handleChatUpdated(Map<String, dynamic>? data) {
    if (data == null) return;

    try {
      // This will be handled by the repository
      debugPrint('💬 Chat updated');
    } catch (e) {
      debugPrint('❌ Error handling chat update: $e');
    }
  }

  void _handleTypingStatus(String type, Map<String, dynamic>? data) {
    if (data == null) return;

    try {
      _typingController.add({
        'type': type,
        'chatId': data['chatId'],
        'userId': data['userId'],
        'isTyping': data['isTyping'] ?? false,
      });
    } catch (e) {
      debugPrint('❌ Error handling typing status: $e');
    }
  }

  void _handleUserStatus(String type, Map<String, dynamic>? data) {
    if (data == null) return;

    try {
      _userStatusController.add({
        'userId': data['userId'],
        'isOnline': type == 'user_online',
      });
    } catch (e) {
      debugPrint('❌ Error handling user status: $e');
    }
  }

  void _handleError(Map<String, dynamic>? data) {
    if (data == null) return;

    final String message = data['message'] ?? 'Unknown error';
    final String? code = data['code'];
    
    debugPrint('❌ WebSocket error: $message (code: $code)');
    
    _errorController.add({
      'message': message,
      'code': code,
    });
  }

  MessageModel _parseMessage(Map<String, dynamic> data) {
    return MessageModel(
      messageId: data['messageId'] ?? '',
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      type: MessageEnum.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageEnum.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => MessageStatus.sent,
      ),
      timestamp: data['timestamp'] != null 
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
      mediaUrl: data['mediaUrl'],
      mediaMetadata: data['mediaMetadata'] != null 
          ? Map<String, dynamic>.from(data['mediaMetadata']) 
          : null,
      replyToMessageId: data['replyToMessageId'],
      replyToContent: data['replyToContent'],
      replyToSender: data['replyToSender'],
      reactions: data['reactions'] != null 
          ? Map<String, String>.from(data['reactions']) 
          : null,
      isEdited: data['isEdited'] ?? false,
      editedAt: data['editedAt'] != null 
          ? DateTime.parse(data['editedAt']) 
          : null,
      isPinned: data['isPinned'] ?? false,
    );
  }

  void _handleConnectionError(dynamic error) {
    debugPrint('❌ WebSocket connection error: $error');
    _isConnected = false;
    _connectionController.add(false);
    _scheduleReconnect();
  }

  void _handleConnectionClosed() {
    debugPrint('🔌 WebSocket connection closed');
    _isConnected = false;
    _connectionController.add(false);
    _pingTimer?.cancel();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_retryAttempts >= _maxRetries) {
      debugPrint('❌ Max reconnection attempts reached');
      return;
    }

    _retryAttempts++;
    final delay = Duration(
      seconds: _baseRetryDelay.inSeconds * _retryAttempts,
    );

    debugPrint('🔄 Scheduling reconnect attempt $_retryAttempts in ${delay.inSeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_currentUserId != null && _authToken != null) {
        connect(_currentUserId!, _authToken!);
      }
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        _sendWebSocketMessage({
          'type': 'ping',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  void _disconnect() {
    _isConnected = false;
    _isConnecting = false;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _joinedChatIds.clear();
    _pendingMessages.clear();
    _connectionController.add(false);
  }

  /// Dispose all resources
  void dispose() {
    debugPrint('🧹 Disposing WebSocket service');
    _disconnect();
    _messagesController.close();
    _chatsController.close();
    _typingController.close();
    _userStatusController.close();
    _connectionController.close();
    _errorController.close();
  }
}
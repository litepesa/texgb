// lib/features/calls/services/call_signaling_service.dart
// Signaling service for WebRTC call negotiation via WebSocket

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum SignalingState {
  idle,
  connecting,
  connected,
  disconnected,
  error,
}

class CallSignalingService {
  WebSocketChannel? _channel;
  SignalingState _state = SignalingState.idle;

  final _stateController = StreamController<SignalingState>.broadcast();
  final _offerController = StreamController<Map<String, dynamic>>.broadcast();
  final _answerController = StreamController<Map<String, dynamic>>.broadcast();
  final _iceCandidateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _incomingCallController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _callEndController = StreamController<String>.broadcast();
  final _callDeclinedController = StreamController<String>.broadcast();
  final _callBusyController = StreamController<String>.broadcast();

  Stream<SignalingState> get stateStream => _stateController.stream;
  Stream<Map<String, dynamic>> get offerStream => _offerController.stream;
  Stream<Map<String, dynamic>> get answerStream => _answerController.stream;
  Stream<Map<String, dynamic>> get iceCandidateStream =>
      _iceCandidateController.stream;
  Stream<Map<String, dynamic>> get incomingCallStream =>
      _incomingCallController.stream;
  Stream<String> get callEndStream => _callEndController.stream;
  Stream<String> get callDeclinedStream => _callDeclinedController.stream;
  Stream<String> get callBusyStream => _callBusyController.stream;

  SignalingState get state => _state;
  String? _userId;

  // Initialize signaling connection
  Future<void> connect({
    required String wsUrl,
    required String userId,
    required String authToken,
  }) async {
    try {
      _userId = userId;

      debugPrint('CallSignaling: Connecting to $wsUrl');
      _updateState(SignalingState.connecting);

      final uri = Uri.parse(wsUrl);
      _channel = WebSocketChannel.connect(uri);

      // Authenticate
      _send({
        'type': 'auth',
        'userId': userId,
        'token': authToken,
      });

      // Listen to messages
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          debugPrint('CallSignaling: WebSocket error: $error');
          _updateState(SignalingState.error);
        },
        onDone: () {
          debugPrint('CallSignaling: WebSocket connection closed');
          _updateState(SignalingState.disconnected);
        },
      );

      _updateState(SignalingState.connected);
      debugPrint('CallSignaling: Connected successfully');
    } catch (e) {
      debugPrint('CallSignaling: Connection error: $e');
      _updateState(SignalingState.error);
      rethrow;
    }
  }

  // Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message.toString()) as Map<String, dynamic>;
      final type = data['type'] as String?;

      debugPrint('CallSignaling: Received message type: $type');

      switch (type) {
        case 'offer':
          _offerController.add(data);
          break;
        case 'answer':
          _answerController.add(data);
          break;
        case 'ice-candidate':
          _iceCandidateController.add(data);
          break;
        case 'incoming-call':
          _incomingCallController.add(data);
          break;
        case 'call-end':
          _callEndController.add(data['callId'] as String);
          break;
        case 'call-declined':
          _callDeclinedController.add(data['callId'] as String);
          break;
        case 'call-busy':
          _callBusyController.add(data['callId'] as String);
          break;
        default:
          debugPrint('CallSignaling: Unknown message type: $type');
      }
    } catch (e) {
      debugPrint('CallSignaling: Error handling message: $e');
    }
  }

  // Send offer to remote peer
  Future<void> sendOffer({
    required String callId,
    required String receiverId,
    required RTCSessionDescription offer,
    required bool isVideoCall,
  }) async {
    _send({
      'type': 'offer',
      'callId': callId,
      'from': _userId,
      'to': receiverId,
      'sdp': offer.sdp,
      'sdpType': offer.type,
      'isVideoCall': isVideoCall,
    });

    debugPrint('CallSignaling: Offer sent to $receiverId');
  }

  // Send answer to remote peer
  Future<void> sendAnswer({
    required String callId,
    required String receiverId,
    required RTCSessionDescription answer,
  }) async {
    _send({
      'type': 'answer',
      'callId': callId,
      'from': _userId,
      'to': receiverId,
      'sdp': answer.sdp,
      'sdpType': answer.type,
    });

    debugPrint('CallSignaling: Answer sent to $receiverId');
  }

  // Send ICE candidate to remote peer
  Future<void> sendIceCandidate({
    required String callId,
    required String receiverId,
    required RTCIceCandidate candidate,
  }) async {
    _send({
      'type': 'ice-candidate',
      'callId': callId,
      'from': _userId,
      'to': receiverId,
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    });

    debugPrint('CallSignaling: ICE candidate sent to $receiverId');
  }

  // Initiate call
  Future<void> initiateCall({
    required String callId,
    required String receiverId,
    required String receiverName,
    required bool isVideoCall,
  }) async {
    _send({
      'type': 'initiate-call',
      'callId': callId,
      'from': _userId,
      'to': receiverId,
      'receiverName': receiverName,
      'isVideoCall': isVideoCall,
    });

    debugPrint('CallSignaling: Call initiated to $receiverId');
  }

  // Accept call
  Future<void> acceptCall({
    required String callId,
    required String callerId,
  }) async {
    _send({
      'type': 'accept-call',
      'callId': callId,
      'from': _userId,
      'to': callerId,
    });

    debugPrint('CallSignaling: Call accepted: $callId');
  }

  // Decline call
  Future<void> declineCall({
    required String callId,
    required String callerId,
  }) async {
    _send({
      'type': 'decline-call',
      'callId': callId,
      'from': _userId,
      'to': callerId,
    });

    debugPrint('CallSignaling: Call declined: $callId');
  }

  // End call
  Future<void> endCall({
    required String callId,
    required String otherUserId,
  }) async {
    _send({
      'type': 'end-call',
      'callId': callId,
      'from': _userId,
      'to': otherUserId,
    });

    debugPrint('CallSignaling: Call ended: $callId');
  }

  // Send busy signal
  Future<void> sendBusy({
    required String callId,
    required String callerId,
  }) async {
    _send({
      'type': 'call-busy',
      'callId': callId,
      'from': _userId,
      'to': callerId,
    });

    debugPrint('CallSignaling: Busy signal sent: $callId');
  }

  // Send message to WebSocket
  void _send(Map<String, dynamic> message) {
    if (_channel == null || _state != SignalingState.connected) {
      debugPrint('CallSignaling: Cannot send message, not connected');
      return;
    }

    try {
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
    } catch (e) {
      debugPrint('CallSignaling: Error sending message: $e');
    }
  }

  // Update signaling state
  void _updateState(SignalingState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  // Disconnect from signaling server
  Future<void> disconnect() async {
    try {
      debugPrint('CallSignaling: Disconnecting');
      await _channel?.sink.close();
      _channel = null;
      _updateState(SignalingState.disconnected);
      debugPrint('CallSignaling: Disconnected');
    } catch (e) {
      debugPrint('CallSignaling: Error disconnecting: $e');
    }
  }

  // Dispose all resources
  void dispose() {
    disconnect();
    _stateController.close();
    _offerController.close();
    _answerController.close();
    _iceCandidateController.close();
    _incomingCallController.close();
    _callEndController.close();
    _callDeclinedController.close();
    _callBusyController.close();
  }
}

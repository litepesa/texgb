// lib/features/calls/providers/call_provider.dart
// Riverpod provider for managing call state and WebRTC connections

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:textgb/features/calls/models/call_model.dart';
import 'package:textgb/features/calls/services/webrtc_service.dart';
import 'package:textgb/features/calls/services/call_signaling_service.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

part 'call_provider.g.dart';

@riverpod
class Call extends _$Call {
  WebRTCService? _webrtcService;
  CallSignalingService? _signalingService;
  Timer? _callDurationTimer;
  int _callDuration = 0;
  StreamSubscription? _offerSubscription;
  StreamSubscription? _answerSubscription;
  StreamSubscription? _iceCandidateSubscription;
  StreamSubscription? _incomingCallSubscription;
  StreamSubscription? _callEndSubscription;
  StreamSubscription? _callDeclinedSubscription;
  StreamSubscription? _callBusySubscription;

  @override
  CallModel? build() {
    // Cleanup when provider is disposed
    ref.onDispose(() {
      _cleanup();
    });

    return null;
  }

  // Initialize services
  Future<void> initializeServices({
    required String wsUrl,
    required String userId,
    required String authToken,
  }) async {
    try {
      debugPrint('Call: Initializing services');

      _webrtcService = WebRTCService();
      _signalingService = CallSignalingService();

      // Connect to signaling server
      await _signalingService!.connect(
        wsUrl: wsUrl,
        userId: userId,
        authToken: authToken,
      );

      // Setup signaling listeners
      _setupSignalingListeners();

      debugPrint('Call: Services initialized successfully');
    } catch (e) {
      debugPrint('Call: Error initializing services: $e');
      rethrow;
    }
  }

  // Setup signaling event listeners
  void _setupSignalingListeners() {
    // Listen for offers (incoming calls)
    _offerSubscription = _signalingService!.offerStream.listen((data) async {
      await _handleIncomingOffer(data);
    });

    // Listen for answers
    _answerSubscription = _signalingService!.answerStream.listen((data) async {
      await _handleAnswer(data);
    });

    // Listen for ICE candidates
    _iceCandidateSubscription =
        _signalingService!.iceCandidateStream.listen((data) async {
      await _handleIceCandidate(data);
    });

    // Listen for incoming calls
    _incomingCallSubscription =
        _signalingService!.incomingCallStream.listen((data) async {
      await _handleIncomingCall(data);
    });

    // Listen for call end
    _callEndSubscription = _signalingService!.callEndStream.listen((callId) {
      _handleCallEnd(callId);
    });

    // Listen for call declined
    _callDeclinedSubscription =
        _signalingService!.callDeclinedStream.listen((callId) {
      _handleCallDeclined(callId);
    });

    // Listen for call busy
    _callBusySubscription = _signalingService!.callBusyStream.listen((callId) {
      _handleCallBusy(callId);
    });
  }

  // Start outgoing call
  Future<void> startCall({
    required String chatId,
    required String receiverId,
    required String receiverName,
    required String receiverAvatar,
    required String currentUserId,
    required String currentUserName,
    required String currentUserAvatar,
    required bool isVideoCall,
  }) async {
    try {
      debugPrint(
          'Call: Starting ${isVideoCall ? 'video' : 'voice'} call to $receiverName');

      // Create call model
      final callId = const Uuid().v4();
      final call = CallModel(
        callId: callId,
        chatId: chatId,
        callerId: currentUserId,
        callerName: currentUserName,
        callerAvatar: currentUserAvatar,
        receiverId: receiverId,
        receiverName: receiverName,
        receiverAvatar: receiverAvatar,
        type: isVideoCall ? CallType.video : CallType.voice,
        status: CallStatus.ringing,
        direction: CallDirection.outgoing,
        startedAt: DateTime.now(),
      );

      state = call;

      // Initialize local media stream
      await _webrtcService!.initializeLocalStream(isVideoCall: isVideoCall);

      // Create peer connection
      await _webrtcService!.setupPeerConnection();

      // Initiate call via signaling
      await _signalingService!.initiateCall(
        callId: callId,
        receiverId: receiverId,
        receiverName: receiverName,
        isVideoCall: isVideoCall,
      );

      // Create and send offer
      final offer = await _webrtcService!.createOffer();
      await _signalingService!.sendOffer(
        callId: callId,
        receiverId: receiverId,
        offer: offer,
        isVideoCall: isVideoCall,
      );

      // Play ringtone
      _playRingtone();

      debugPrint('Call: Call initiated successfully');
    } catch (e) {
      debugPrint('Call: Error starting call: $e');
      await endCall();
      rethrow;
    }
  }

  // Handle incoming call
  Future<void> _handleIncomingCall(Map<String, dynamic> data) async {
    try {
      debugPrint('Call: Incoming call received');

      final callId = data['callId'] as String;
      final callerId = data['from'] as String;
      final callerName = data['callerName'] as String? ?? 'Unknown';
      final callerAvatar = data['callerAvatar'] as String? ?? '';
      final isVideoCall = data['isVideoCall'] as bool? ?? false;
      final chatId = data['chatId'] as String? ?? '';

      // Create call model
      final call = CallModel(
        callId: callId,
        chatId: chatId,
        callerId: callerId,
        callerName: callerName,
        callerAvatar: callerAvatar,
        receiverId: '', // Will be set by current user
        receiverName: '',
        receiverAvatar: '',
        type: isVideoCall ? CallType.video : CallType.voice,
        status: CallStatus.ringing,
        direction: CallDirection.incoming,
        startedAt: DateTime.now(),
      );

      state = call;

      // Play ringtone
      _playRingtone();

      debugPrint('Call: Incoming call handled');
    } catch (e) {
      debugPrint('Call: Error handling incoming call: $e');
    }
  }

  // Answer incoming call
  Future<void> answerCall() async {
    try {
      if (state == null || !state!.isIncoming) {
        throw Exception('No incoming call to answer');
      }

      debugPrint('Call: Answering call');

      // Stop ringtone
      _stopRingtone();

      // Update call status
      state = state!.copyWith(status: CallStatus.connecting);

      // Initialize local media stream
      await _webrtcService!
          .initializeLocalStream(isVideoCall: state!.isVideoCall);

      // Create peer connection
      await _webrtcService!.setupPeerConnection();

      // Accept call via signaling
      await _signalingService!.acceptCall(
        callId: state!.callId,
        callerId: state!.callerId,
      );

      debugPrint('Call: Call answered');
    } catch (e) {
      debugPrint('Call: Error answering call: $e');
      await endCall();
      rethrow;
    }
  }

  // Handle incoming offer
  Future<void> _handleIncomingOffer(Map<String, dynamic> data) async {
    try {
      debugPrint('Call: Handling incoming offer');

      final sdp = data['sdp'] as String;
      final sdpType = data['sdpType'] as String;

      // Set remote description
      final offer = RTCSessionDescription(sdp, sdpType);
      await _webrtcService!.setRemoteDescription(offer);

      // Create and send answer
      final answer = await _webrtcService!.createAnswer();
      await _signalingService!.sendAnswer(
        callId: state!.callId,
        receiverId: state!.callerId,
        answer: answer,
      );

      debugPrint('Call: Offer handled and answer sent');
    } catch (e) {
      debugPrint('Call: Error handling offer: $e');
    }
  }

  // Handle answer
  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    try {
      debugPrint('Call: Handling answer');

      final sdp = data['sdp'] as String;
      final sdpType = data['sdpType'] as String;

      // Set remote description
      final answer = RTCSessionDescription(sdp, sdpType);
      await _webrtcService!.setRemoteDescription(answer);

      // Stop ringtone
      _stopRingtone();

      // Update call status
      state = state!.copyWith(
        status: CallStatus.connected,
        connectedAt: DateTime.now(),
      );

      // Start call duration timer
      _startCallDurationTimer();

      debugPrint('Call: Answer handled, call connected');
    } catch (e) {
      debugPrint('Call: Error handling answer: $e');
    }
  }

  // Handle ICE candidate
  Future<void> _handleIceCandidate(Map<String, dynamic> data) async {
    try {
      debugPrint('Call: Handling ICE candidate');

      final candidate = data['candidate'] as String?;
      final sdpMid = data['sdpMid'] as String?;
      final sdpMLineIndex = data['sdpMLineIndex'] as int?;

      if (candidate != null && sdpMid != null && sdpMLineIndex != null) {
        final iceCandidate = RTCIceCandidate(candidate, sdpMid, sdpMLineIndex);
        await _webrtcService!.addIceCandidate(iceCandidate);
        debugPrint('Call: ICE candidate added');
      }
    } catch (e) {
      debugPrint('Call: Error handling ICE candidate: $e');
    }
  }

  // Handle call end
  void _handleCallEnd(String callId) {
    if (state?.callId == callId) {
      debugPrint('Call: Remote peer ended call');
      endCall();
    }
  }

  // Handle call declined
  void _handleCallDeclined(String callId) {
    if (state?.callId == callId) {
      debugPrint('Call: Call was declined');
      state = state!.copyWith(status: CallStatus.declined);
      _stopRingtone();
      _cleanup();
    }
  }

  // Handle call busy
  void _handleCallBusy(String callId) {
    if (state?.callId == callId) {
      debugPrint('Call: Callee is busy');
      state = state!.copyWith(status: CallStatus.busy);
      _stopRingtone();
      _cleanup();
    }
  }

  // Decline incoming call
  Future<void> declineCall() async {
    try {
      if (state == null || !state!.isIncoming) {
        throw Exception('No incoming call to decline');
      }

      debugPrint('Call: Declining call');

      // Send decline signal
      await _signalingService!.declineCall(
        callId: state!.callId,
        callerId: state!.callerId,
      );

      // Update call status
      state = state!.copyWith(status: CallStatus.declined);

      // Stop ringtone
      _stopRingtone();

      // Cleanup
      await _cleanup();

      debugPrint('Call: Call declined');
    } catch (e) {
      debugPrint('Call: Error declining call: $e');
    }
  }

  // End call
  Future<void> endCall() async {
    try {
      debugPrint('Call: Ending call');

      if (state != null) {
        // Send end call signal
        final otherUserId =
            state!.isIncoming ? state!.callerId : state!.receiverId;
        await _signalingService!.endCall(
          callId: state!.callId,
          otherUserId: otherUserId,
        );

        // Update call status
        state = state!.copyWith(
          status: CallStatus.ended,
          endedAt: DateTime.now(),
          duration: _callDuration,
        );
      }

      // Stop ringtone
      _stopRingtone();

      // Stop call duration timer
      _stopCallDurationTimer();

      // Cleanup
      await _cleanup();

      debugPrint('Call: Call ended');
    } catch (e) {
      debugPrint('Call: Error ending call: $e');
    }
  }

  // Toggle video
  Future<void> toggleVideo(bool enabled) async {
    await _webrtcService?.toggleVideo(enabled);
  }

  // Toggle audio
  Future<void> toggleAudio(bool enabled) async {
    await _webrtcService?.toggleAudio(enabled);
  }

  // Switch camera
  Future<void> switchCamera() async {
    await _webrtcService?.switchCamera();
  }

  // Toggle speaker
  Future<void> toggleSpeaker(bool enabled) async {
    await _webrtcService?.enableSpeaker(enabled);
  }

  // Get local stream
  MediaStream? get localStream => _webrtcService?.localStream;

  // Get remote stream
  MediaStream? get remoteStream => _webrtcService?.remoteStream;

  // Get local stream stream
  Stream<MediaStream?>? get localStreamStream =>
      _webrtcService?.localStreamStream;

  // Get remote stream stream
  Stream<MediaStream?>? get remoteStreamStream =>
      _webrtcService?.remoteStreamStream;

  // Start call duration timer
  void _startCallDurationTimer() {
    _callDuration = 0;
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDuration++;
      // Update UI with duration
      if (state != null) {
        state = state!.copyWith(duration: _callDuration);
      }
    });
  }

  // Stop call duration timer
  void _stopCallDurationTimer() {
    _callDurationTimer?.cancel();
    _callDurationTimer = null;
  }

  // Play ringtone
  void _playRingtone() {
    try {
      FlutterRingtonePlayer().playRingtone(
        looping: true,
        volume: 0.5,
        asAlarm: false,
      );
    } catch (e) {
      debugPrint('Call: Error playing ringtone: $e');
    }
  }

  // Stop ringtone
  void _stopRingtone() {
    try {
      FlutterRingtonePlayer().stop();
    } catch (e) {
      debugPrint('Call: Error stopping ringtone: $e');
    }
  }

  // Cleanup resources
  Future<void> _cleanup() async {
    debugPrint('Call: Cleaning up resources');

    // Stop timers
    _stopCallDurationTimer();

    // Cancel subscriptions
    await _offerSubscription?.cancel();
    await _answerSubscription?.cancel();
    await _iceCandidateSubscription?.cancel();
    await _incomingCallSubscription?.cancel();
    await _callEndSubscription?.cancel();
    await _callDeclinedSubscription?.cancel();
    await _callBusySubscription?.cancel();

    // Cleanup WebRTC
    await _webrtcService?.close();

    debugPrint('Call: Cleanup completed');
  }
}

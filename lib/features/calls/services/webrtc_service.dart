// lib/features/calls/services/webrtc_service.dart
// WebRTC Service for handling peer connections, media streams, and signaling

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final _localStreamController = StreamController<MediaStream?>.broadcast();
  final _remoteStreamController = StreamController<MediaStream?>.broadcast();
  final _connectionStateController = StreamController<RTCPeerConnectionState>.broadcast();
  final _iceStateController = StreamController<RTCIceConnectionState>.broadcast();

  Stream<MediaStream?> get localStreamStream => _localStreamController.stream;
  Stream<MediaStream?> get remoteStreamStream => _remoteStreamController.stream;
  Stream<RTCPeerConnectionState> get connectionStateStream => _connectionStateController.stream;
  Stream<RTCIceConnectionState> get iceStateStream => _iceStateController.stream;

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  // ICE servers configuration (STUN/TURN servers)
  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
        ]
      },
      // Add TURN servers here for production
      // {
      //   'urls': 'turn:your-turn-server.com:3478',
      //   'username': 'username',
      //   'credential': 'password'
      // }
    ]
  };

  final Map<String, dynamic> _dcConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  // Initialize local media stream (camera/microphone)
  Future<void> initializeLocalStream({required bool isVideoCall}) async {
    try {
      debugPrint('WebRTC: Initializing local stream (video: $isVideoCall)');

      final mediaConstraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': isVideoCall
            ? {
                'mandatory': {
                  'minWidth': '640',
                  'minHeight': '480',
                  'minFrameRate': '30',
                },
                'facingMode': 'user',
                'optional': [],
              }
            : false,
      };

      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localStreamController.add(_localStream);

      debugPrint('WebRTC: Local stream initialized successfully');
    } catch (e) {
      debugPrint('WebRTC: Error initializing local stream: $e');
      rethrow;
    }
  }

  // Create peer connection
  Future<void> setupPeerConnection() async {
    try {
      debugPrint('WebRTC: Creating peer connection');

      _peerConnection = await createPeerConnection(_iceServers);

      // Add local stream tracks to peer connection
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          _peerConnection!.addTrack(track, _localStream!);
        });
      }

      // Handle peer connection state changes
      _peerConnection!.onConnectionState = (state) {
        debugPrint('WebRTC: Connection state changed to: $state');
        _connectionStateController.add(state);
      };

      // Handle ICE connection state changes
      _peerConnection!.onIceConnectionState = (state) {
        debugPrint('WebRTC: ICE connection state changed to: $state');
        _iceStateController.add(state);
      };

      // Handle ICE candidates
      _peerConnection!.onIceCandidate = (candidate) {
        debugPrint('WebRTC: ICE candidate generated');
        // Send ICE candidate to remote peer via signaling
        // This will be handled by the signaling service
      };

      // Handle remote stream
      _peerConnection!.onTrack = (event) {
        debugPrint('WebRTC: Remote track received');
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          _remoteStreamController.add(_remoteStream);
        }
      };

      debugPrint('WebRTC: Peer connection created successfully');
    } catch (e) {
      debugPrint('WebRTC: Error creating peer connection: $e');
      rethrow;
    }
  }

  // Create offer (caller)
  Future<RTCSessionDescription> createOffer() async {
    try {
      debugPrint('WebRTC: Creating offer');

      final offer = await _peerConnection!.createOffer(_dcConstraints);
      await _peerConnection!.setLocalDescription(offer);

      debugPrint('WebRTC: Offer created successfully');
      return offer;
    } catch (e) {
      debugPrint('WebRTC: Error creating offer: $e');
      rethrow;
    }
  }

  // Create answer (callee)
  Future<RTCSessionDescription> createAnswer() async {
    try {
      debugPrint('WebRTC: Creating answer');

      final answer = await _peerConnection!.createAnswer(_dcConstraints);
      await _peerConnection!.setLocalDescription(answer);

      debugPrint('WebRTC: Answer created successfully');
      return answer;
    } catch (e) {
      debugPrint('WebRTC: Error creating answer: $e');
      rethrow;
    }
  }

  // Set remote description
  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    try {
      debugPrint('WebRTC: Setting remote description');
      await _peerConnection!.setRemoteDescription(description);
      debugPrint('WebRTC: Remote description set successfully');
    } catch (e) {
      debugPrint('WebRTC: Error setting remote description: $e');
      rethrow;
    }
  }

  // Add ICE candidate
  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    try {
      debugPrint('WebRTC: Adding ICE candidate');
      await _peerConnection!.addCandidate(candidate);
      debugPrint('WebRTC: ICE candidate added successfully');
    } catch (e) {
      debugPrint('WebRTC: Error adding ICE candidate: $e');
      rethrow;
    }
  }

  // Toggle video (enable/disable camera)
  Future<void> toggleVideo(bool enabled) async {
    try {
      if (_localStream != null) {
        final videoTracks = _localStream!.getVideoTracks();
        for (var track in videoTracks) {
          track.enabled = enabled;
        }
        debugPrint('WebRTC: Video ${enabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      debugPrint('WebRTC: Error toggling video: $e');
    }
  }

  // Toggle audio (mute/unmute microphone)
  Future<void> toggleAudio(bool enabled) async {
    try {
      if (_localStream != null) {
        final audioTracks = _localStream!.getAudioTracks();
        for (var track in audioTracks) {
          track.enabled = enabled;
        }
        debugPrint('WebRTC: Audio ${enabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      debugPrint('WebRTC: Error toggling audio: $e');
    }
  }

  // Switch camera (front/back)
  Future<void> switchCamera() async {
    try {
      if (_localStream != null) {
        final videoTrack = _localStream!.getVideoTracks().first;
        await Helper.switchCamera(videoTrack);
        debugPrint('WebRTC: Camera switched');
      }
    } catch (e) {
      debugPrint('WebRTC: Error switching camera: $e');
    }
  }

  // Enable speaker
  Future<void> enableSpeaker(bool enabled) async {
    try {
      if (_localStream != null) {
        await Helper.setSpeakerphoneOn(enabled);
        debugPrint('WebRTC: Speaker ${enabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      debugPrint('WebRTC: Error toggling speaker: $e');
    }
  }

  // Close peer connection and clean up
  Future<void> close() async {
    try {
      debugPrint('WebRTC: Closing peer connection and cleaning up');

      // Stop all tracks
      _localStream?.getTracks().forEach((track) {
        track.stop();
      });

      _remoteStream?.getTracks().forEach((track) {
        track.stop();
      });

      // Close peer connection
      await _peerConnection?.close();

      // Dispose streams
      await _localStream?.dispose();
      await _remoteStream?.dispose();

      // Clear references
      _peerConnection = null;
      _localStream = null;
      _remoteStream = null;

      // Add null to streams to notify listeners
      _localStreamController.add(null);
      _remoteStreamController.add(null);

      debugPrint('WebRTC: Cleanup completed');
    } catch (e) {
      debugPrint('WebRTC: Error during cleanup: $e');
    }
  }

  // Dispose all resources
  void dispose() {
    close();
    _localStreamController.close();
    _remoteStreamController.close();
    _connectionStateController.close();
    _iceStateController.close();
  }

  // Get connection statistics
  Future<List<StatsReport>> getStats() async {
    if (_peerConnection == null) return [];

    try {
      final stats = await _peerConnection!.getStats();
      return stats;
    } catch (e) {
      debugPrint('WebRTC: Error getting stats: $e');
      return [];
    }
  }

  // Check if connection is established
  bool get isConnected => _peerConnection?.connectionState == RTCPeerConnectionState.RTCPeerConnectionStateConnected;

  // Check if video is enabled
  bool get isVideoEnabled {
    if (_localStream == null) return false;
    final videoTracks = _localStream!.getVideoTracks();
    return videoTracks.isNotEmpty && videoTracks.first.enabled == true;
  }

  // Check if audio is enabled
  bool get isAudioEnabled {
    if (_localStream == null) return false;
    final audioTracks = _localStream!.getAudioTracks();
    return audioTracks.isNotEmpty && audioTracks.first.enabled == true;
  }
}

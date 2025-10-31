// lib/features/live_streaming/services/agora_service.dart

import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

/// Agora live streaming service wrapper
/// Handles video/audio streaming, remote users, and stream state
class AgoraService {
  RtcEngine? _engine;
  bool _isInitialized = false;
  bool _isJoined = false;

  // Stream controllers for real-time updates
  final _remoteUsersController = StreamController<List<int>>.broadcast();
  final _localUserJoinedController = StreamController<int>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _warningController = StreamController<String>.broadcast();
  final _connectionStateController = StreamController<ConnectionStateType>.broadcast();

  // State
  final Set<int> _remoteUsers = {};
  int? _localUid;
  String? _currentChannel;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isJoined => _isJoined;
  int? get localUid => _localUid;
  String? get currentChannel => _currentChannel;
  List<int> get remoteUsers => _remoteUsers.toList();

  // Streams
  Stream<List<int>> get remoteUsersStream => _remoteUsersController.stream;
  Stream<int> get localUserJoinedStream => _localUserJoinedController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<String> get warningStream => _warningController.stream;
  Stream<ConnectionStateType> get connectionStateStream => _connectionStateController.stream;

  // ==================== INITIALIZATION ====================

  /// Initialize Agora engine
  Future<void> initialize({required String appId}) async {
    if (_isInitialized) {
      print('Agora engine already initialized');
      return;
    }

    try {
      // Request permissions
      await _requestPermissions();

      // Create RTC engine
      _engine = createAgoraRtcEngine();

      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      // Register event handlers
      _registerEventHandlers();

      _isInitialized = true;
      print('Agora engine initialized successfully');
    } catch (e) {
      print('Failed to initialize Agora engine: $e');
      _errorController.add('Initialization failed: $e');
      rethrow;
    }
  }

  /// Register Agora event handlers
  void _registerEventHandlers() {
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print('Local user ${connection.localUid} joined channel ${connection.channelId}');
          _localUid = connection.localUid;
          _currentChannel = connection.channelId;
          _isJoined = true;
          _localUserJoinedController.add(connection.localUid!);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          print('Remote user $remoteUid joined');
          _remoteUsers.add(remoteUid);
          _remoteUsersController.add(_remoteUsers.toList());
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          print('Remote user $remoteUid left channel');
          _remoteUsers.remove(remoteUid);
          _remoteUsersController.add(_remoteUsers.toList());
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          print('Left channel ${connection.channelId}');
          _isJoined = false;
          _localUid = null;
          _currentChannel = null;
          _remoteUsers.clear();
          _remoteUsersController.add([]);
        },
        onError: (ErrorCodeType err, String msg) {
          print('Agora error: $err - $msg');
          _errorController.add('$err: $msg');
        },
        onConnectionStateChanged: (RtcConnection connection,
            ConnectionStateType state, ConnectionChangedReasonType reason) {
          print('Connection state changed: $state (reason: $reason)');
          _connectionStateController.add(state);
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          print('Token will expire, need to renew');
          _warningController.add('Token expiring soon');
        },
      ),
    );
  }

  /// Request camera and microphone permissions
  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      throw Exception('Camera and microphone permissions are required');
    }
  }

  // ==================== BROADCASTING (HOST) ====================

  /// Start broadcasting as host
  Future<void> startBroadcasting({
    required String channelName,
    required String token,
    int uid = 0,
    bool enableVideo = true,
    bool enableAudio = true,
  }) async {
    if (!_isInitialized) {
      throw Exception('Agora engine not initialized');
    }

    try {
      // Set client role to broadcaster
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // Enable video if needed
      if (enableVideo) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      }

      // Enable audio
      if (enableAudio) {
        await _engine!.enableAudio();
      }

      // Join channel
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
        ),
      );

      print('Started broadcasting in channel: $channelName');
    } catch (e) {
      print('Failed to start broadcasting: $e');
      _errorController.add('Broadcast failed: $e');
      rethrow;
    }
  }

  /// Stop broadcasting
  Future<void> stopBroadcasting() async {
    if (!_isJoined) {
      print('Not currently broadcasting');
      return;
    }

    try {
      await _engine!.stopPreview();
      await _engine!.leaveChannel();
      print('Stopped broadcasting');
    } catch (e) {
      print('Failed to stop broadcasting: $e');
      _errorController.add('Stop broadcast failed: $e');
    }
  }

  // ==================== VIEWING (AUDIENCE) ====================

  /// Join as audience (viewer)
  Future<void> joinAsAudience({
    required String channelName,
    required String token,
    int uid = 0,
  }) async {
    if (!_isInitialized) {
      throw Exception('Agora engine not initialized');
    }

    try {
      // Set client role to audience
      await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);

      // Enable video rendering
      await _engine!.enableVideo();

      // Join channel
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleAudience,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );

      print('Joined as audience in channel: $channelName');
    } catch (e) {
      print('Failed to join as audience: $e');
      _errorController.add('Join failed: $e');
      rethrow;
    }
  }

  /// Leave channel (as audience)
  Future<void> leaveChannel() async {
    if (!_isJoined) {
      print('Not currently in a channel');
      return;
    }

    try {
      await _engine!.leaveChannel();
      print('Left channel');
    } catch (e) {
      print('Failed to leave channel: $e');
      _errorController.add('Leave failed: $e');
    }
  }

  // ==================== AUDIO/VIDEO CONTROLS ====================

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    if (!_isInitialized) return;

    try {
      await _engine!.switchCamera();
      print('Camera switched');
    } catch (e) {
      print('Failed to switch camera: $e');
      _errorController.add('Camera switch failed: $e');
    }
  }

  /// Toggle local video
  Future<void> toggleVideo(bool enable) async {
    if (!_isInitialized) return;

    try {
      if (enable) {
        await _engine!.enableLocalVideo(true);
        await _engine!.startPreview();
      } else {
        await _engine!.enableLocalVideo(false);
        await _engine!.stopPreview();
      }
      print('Video ${enable ? 'enabled' : 'disabled'}');
    } catch (e) {
      print('Failed to toggle video: $e');
      _errorController.add('Toggle video failed: $e');
    }
  }

  /// Toggle local audio (mute/unmute)
  Future<void> toggleAudio(bool enable) async {
    if (!_isInitialized) return;

    try {
      await _engine!.muteLocalAudioStream(!enable);
      print('Audio ${enable ? 'enabled' : 'disabled'}');
    } catch (e) {
      print('Failed to toggle audio: $e');
      _errorController.add('Toggle audio failed: $e');
    }
  }

  /// Mute remote user audio
  Future<void> muteRemoteAudio(int uid, bool mute) async {
    if (!_isInitialized) return;

    try {
      await _engine!.muteRemoteAudioStream(uid: uid, mute: mute);
      print('Remote user $uid audio ${mute ? 'muted' : 'unmuted'}');
    } catch (e) {
      print('Failed to mute remote audio: $e');
    }
  }

  /// Set video quality preset
  Future<void> setVideoQuality(VideoQualityPreset preset) async {
    if (!_isInitialized) return;

    try {
      VideoEncoderConfiguration config;

      switch (preset) {
        case VideoQualityPreset.low:
          config = const VideoEncoderConfiguration(
            dimensions: VideoDimensions(width: 320, height: 240),
            frameRate: 15,
            bitrate: 200,
          );
          break;
        case VideoQualityPreset.medium:
          config = const VideoEncoderConfiguration(
            dimensions: VideoDimensions(width: 640, height: 360),
            frameRate: 24,
            bitrate: 500,
          );
          break;
        case VideoQualityPreset.high:
          config = const VideoEncoderConfiguration(
            dimensions: VideoDimensions(width: 1280, height: 720),
            frameRate: 30,
            bitrate: 1500,
          );
          break;
      }

      await _engine!.setVideoEncoderConfiguration(config);
      print('Video quality set to: ${preset.name}');
    } catch (e) {
      print('Failed to set video quality: $e');
    }
  }

  // ==================== TOKEN RENEWAL ====================

  /// Renew Agora token when about to expire
  Future<void> renewToken(String newToken) async {
    if (!_isInitialized || !_isJoined) return;

    try {
      await _engine!.renewToken(newToken);
      print('Token renewed successfully');
    } catch (e) {
      print('Failed to renew token: $e');
      _errorController.add('Token renewal failed: $e');
    }
  }

  // ==================== CLEANUP ====================

  /// Dispose Agora engine and clean up resources
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      if (_isJoined) {
        await leaveChannel();
      }

      await _engine!.release();
      _engine = null;
      _isInitialized = false;
      _isJoined = false;
      _localUid = null;
      _currentChannel = null;
      _remoteUsers.clear();

      // Close streams
      await _remoteUsersController.close();
      await _localUserJoinedController.close();
      await _errorController.close();
      await _warningController.close();
      await _connectionStateController.close();

      print('Agora engine disposed');
    } catch (e) {
      print('Error disposing Agora engine: $e');
    }
  }

  // ==================== STATISTICS ====================

  /// Get RTC engine stats
  Future<RtcStats?> getStats() async {
    if (!_isInitialized || !_isJoined) return null;

    // Stats are provided via onRtcStats callback
    // You would need to listen to this event and store stats
    return null;
  }

  /// Get local video stats
  Future<void> enableStats({required Function(RtcStats stats) onStats}) async {
    if (!_isInitialized) return;

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onRtcStats: (RtcConnection connection, RtcStats stats) {
          onStats(stats);
        },
      ),
    );
  }
}

// ==================== ENUMS ====================

enum VideoQualityPreset {
  low,    // 320x240, 15fps, 200kbps
  medium, // 640x360, 24fps, 500kbps
  high,   // 1280x720, 30fps, 1500kbps
}

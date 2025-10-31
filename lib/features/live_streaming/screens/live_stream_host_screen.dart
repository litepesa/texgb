// lib/features/live_streaming/screens/live_stream_host_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:textgb/features/live_streaming/models/live_chat_message_model.dart';
import 'package:textgb/features/live_streaming/widgets/gift_animation_overlay.dart';
import 'package:textgb/features/live_streaming/models/live_gift_model.dart';
import 'package:textgb/features/live_streaming/constants/live_streaming_constants.dart';

class LiveStreamHostScreen extends ConsumerStatefulWidget {
  final String streamId;

  const LiveStreamHostScreen({
    super.key,
    required this.streamId,
  });

  @override
  ConsumerState<LiveStreamHostScreen> createState() => _LiveStreamHostScreenState();
}

class _LiveStreamHostScreenState extends ConsumerState<LiveStreamHostScreen> {
  // Agora
  RtcEngine? _engine;
  bool _isStreaming = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isFrontCamera = true;

  // Stream stats
  int _viewerCount = 0;
  int _likeCount = 0;
  double _totalRevenue = 0.0;
  Duration _streamDuration = Duration.zero;
  Timer? _durationTimer;

  // Chat
  final List<LiveChatMessageModel> _recentMessages = [];

  // Gifts
  LiveGiftModel? _currentGiftAnimation;

  // UI State
  bool _showControls = true;
  bool _showStats = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
    _startDurationTimer();
    _startStatsTimer();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _stopStreaming();
    super.dispose();
  }

  Future<void> _initAgora() async {
    try {
      // Create Agora engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: LiveStreamingConstants.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      // Register event handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            setState(() {
              _isStreaming = true;
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            setState(() {
              _viewerCount++;
            });
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            setState(() {
              _viewerCount--;
              if (_viewerCount < 0) _viewerCount = 0;
            });
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('Agora Error: $err - $msg');
          },
        ),
      );

      // Set client role to broadcaster
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // Enable video
      await _engine!.enableVideo();
      await _engine!.startPreview();

      // Join channel (TODO: Get token from backend)
      await _engine!.joinChannel(
        token: '', // TODO: Get from backend
        channelId: widget.streamId,
        uid: 0,
        options: const ChannelMediaOptions(),
      );
    } catch (e) {
      debugPrint('Failed to initialize Agora: $e');
    }
  }

  Future<void> _stopStreaming() async {
    await _engine?.leaveChannel();
    await _engine?.release();
    _durationTimer?.cancel();
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _streamDuration += const Duration(seconds: 1);
        });
      }
    });
  }

  void _startStatsTimer() {
    // Simulate incoming stats
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          // Simulate viewer fluctuations
          final change = (DateTime.now().second % 5) - 2;
          _viewerCount = (_viewerCount + change).clamp(0, 10000);

          // Simulate likes
          _likeCount += DateTime.now().millisecond % 10;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _endStream() async {
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'End Live Stream?',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to end this stream?',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            _buildStat('Duration', _formatDuration(_streamDuration)),
            const SizedBox(height: 8),
            _buildStat('Viewers', '$_viewerCount'),
            const SizedBox(height: 8),
            _buildStat('Likes', '$_likeCount'),
            const SizedBox(height: 8),
            _buildStat('Revenue', 'KES ${_totalRevenue.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('End Stream'),
          ),
        ],
      ),
    );

    if (shouldEnd == true && mounted) {
      await _stopStreaming();
      if (mounted) {
        // TODO: Navigate to analytics screen
        Navigator.pop(context);
      }
    }
  }

  Widget _buildStat(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _toggleMute() async {
    await _engine?.muteLocalAudioStream(!_isMuted);
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  Future<void> _toggleCamera() async {
    await _engine?.muteLocalVideoStream(!_isCameraOff);
    setState(() {
      _isCameraOff = !_isCameraOff;
    });
  }

  Future<void> _switchCamera() async {
    await _engine?.switchCamera();
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          children: [
            // Camera preview
            _buildCameraPreview(),

            // Gradient overlays
            _buildGradientOverlays(),

            // Top bar
            if (_showControls) _buildTopBar(),

            // Stats overlay
            if (_showStats) _buildStatsOverlay(),

            // Recent chat messages
            _buildRecentMessages(),

            // Bottom controls
            if (_showControls) _buildBottomControls(),

            // Gift animations
            if (_currentGiftAnimation != null)
              GiftAnimationOverlay(
                gift: _currentGiftAnimation!,
                onComplete: () {
                  setState(() {
                    _currentGiftAnimation = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_engine != null && _isStreaming) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine!,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    }

    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: CircularProgressIndicator(color: Colors.red),
      ),
    );
  }

  Widget _buildGradientOverlays() {
    return Column(
      children: [
        // Top gradient
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const Spacer(),
        // Bottom gradient
        Container(
          height: 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Stream status
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 8),
                          SizedBox(width: 6),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.remove_red_eye,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_viewerCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDuration(_streamDuration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Stats toggle
            GestureDetector(
              onTap: () {
                setState(() {
                  _showStats = !_showStats;
                });
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _showStats ? Colors.red : Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(Icons.bar_chart, color: Colors.white, size: 20),
              ),
            ),

            const SizedBox(width: 8),

            // End stream button
            GestureDetector(
              onTap: _endStream,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverlay() {
    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live Stats',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  icon: Icons.remove_red_eye,
                  label: 'Viewers',
                  value: '$_viewerCount',
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.favorite,
                  label: 'Likes',
                  value: '$_likeCount',
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard(
                  icon: Icons.card_giftcard,
                  label: 'Revenue',
                  value: 'KES ${_totalRevenue.toStringAsFixed(0)}',
                  color: Colors.amber,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.access_time,
                  label: 'Duration',
                  value: _formatDuration(_streamDuration),
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMessages() {
    if (_recentMessages.isEmpty) return const SizedBox.shrink();

    return Positioned(
      left: 16,
      bottom: 180,
      right: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _recentMessages.take(3).map((message) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${message.senderName}: ${message.message}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Flip camera
              _buildControlButton(
                icon: Icons.flip_camera_ios,
                label: 'Flip',
                onTap: _switchCamera,
              ),

              // Mute audio
              _buildControlButton(
                icon: _isMuted ? Icons.mic_off : Icons.mic,
                label: _isMuted ? 'Unmute' : 'Mute',
                onTap: _toggleMute,
                isActive: _isMuted,
              ),

              // Toggle camera
              _buildControlButton(
                icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                label: _isCameraOff ? 'Camera Off' : 'Camera On',
                onTap: _toggleCamera,
                isActive: _isCameraOff,
              ),

              // Settings (product pins, moderators, etc.)
              _buildControlButton(
                icon: Icons.settings,
                label: 'Settings',
                onTap: () {
                  // TODO: Show host settings
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive ? Colors.red : Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? Colors.red : Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.red : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

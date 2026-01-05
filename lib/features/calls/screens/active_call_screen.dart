// lib/features/calls/screens/active_call_screen.dart
// Active call screen with video/voice controls

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/features/calls/models/call_model.dart';
import 'package:textgb/features/calls/providers/call_provider.dart';

class ActiveCallScreen extends ConsumerStatefulWidget {
  const ActiveCallScreen({super.key});

  @override
  ConsumerState<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends ConsumerState<ActiveCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerEnabled = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    // Listen to stream changes
    ref.read(callProvider.notifier).localStreamStream?.listen((stream) {
      if (stream != null && mounted) {
        setState(() {
          _localRenderer.srcObject = stream;
        });
      }
    });

    ref.read(callProvider.notifier).remoteStreamStream?.listen((stream) {
      if (stream != null && mounted) {
        setState(() {
          _remoteRenderer.srcObject = stream;
        });
      }
    });
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final call = ref.watch(callProvider);

    if (call == null || call.isEnded) {
      // Call ended, close this screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pop();
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video (full screen) or avatar
            if (call.isVideoCall && _remoteRenderer.srcObject != null)
              Positioned.fill(
                child: RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              )
            else
              _buildAvatarBackground(call),

            // Local video (picture-in-picture)
            if (call.isVideoCall &&
                _isVideoEnabled &&
                _localRenderer.srcObject != null)
              Positioned(
                top: 16,
                right: 16,
                width: 120,
                height: 160,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: RTCVideoView(
                      _localRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      mirror: true,
                    ),
                  ),
                ),
              ),

            // Top bar with caller info
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      call.isOutgoing ? call.receiverName : call.callerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      call.statusDisplay,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom controls
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Main controls row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Mute/Unmute
                          _buildControlButton(
                            icon: _isMuted ? Icons.mic_off : Icons.mic,
                            label: _isMuted ? 'Unmute' : 'Mute',
                            isActive: !_isMuted,
                            onTap: () {
                              setState(() {
                                _isMuted = !_isMuted;
                              });
                              ref
                                  .read(callProvider.notifier)
                                  .toggleAudio(!_isMuted);
                            },
                          ),

                          // End call
                          _buildControlButton(
                            icon: Icons.call_end,
                            label: 'End',
                            backgroundColor: const Color(0xFFF5222D),
                            onTap: () async {
                              await ref.read(callProvider.notifier).endCall();
                              if (mounted) {
                                context.pop();
                              }
                            },
                          ),

                          // Speaker
                          _buildControlButton(
                            icon: _isSpeakerEnabled
                                ? Icons.volume_up
                                : Icons.volume_down,
                            label: _isSpeakerEnabled ? 'Speaker' : 'Earpiece',
                            isActive: _isSpeakerEnabled,
                            onTap: () {
                              setState(() {
                                _isSpeakerEnabled = !_isSpeakerEnabled;
                              });
                              ref
                                  .read(callProvider.notifier)
                                  .toggleSpeaker(_isSpeakerEnabled);
                            },
                          ),
                        ],
                      ),

                      // Video call specific controls
                      if (call.isVideoCall) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Toggle video
                            _buildControlButton(
                              icon: _isVideoEnabled
                                  ? Icons.videocam
                                  : Icons.videocam_off,
                              label:
                                  _isVideoEnabled ? 'Camera On' : 'Camera Off',
                              isActive: _isVideoEnabled,
                              onTap: () {
                                setState(() {
                                  _isVideoEnabled = !_isVideoEnabled;
                                });
                                ref
                                    .read(callProvider.notifier)
                                    .toggleVideo(_isVideoEnabled);
                              },
                            ),

                            // Switch camera
                            _buildControlButton(
                              icon: Icons.flip_camera_ios,
                              label: 'Flip',
                              onTap: () {
                                ref.read(callProvider.notifier).switchCamera();
                              },
                            ),

                            // Placeholder for symmetry
                            const SizedBox(width: 72),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Tap to toggle controls
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showControls = !_showControls;
                  });
                },
                behavior: HitTestBehavior.translucent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarBackground(CallModel call) {
    final userName = call.isOutgoing ? call.receiverName : call.callerName;
    final userAvatar =
        call.isOutgoing ? call.receiverAvatar : call.callerAvatar;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1C1C1E),
            const Color(0xFF2C2C2E),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 80,
              backgroundColor: Colors.grey[800],
              backgroundImage: userAvatar.isNotEmpty
                  ? CachedNetworkImageProvider(userAvatar)
                  : null,
              child: userAvatar.isEmpty
                  ? Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    Color? backgroundColor,
    bool isActive = true,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: backgroundColor ??
                  (isActive
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1)),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: backgroundColor != null
                  ? Colors.white
                  : (isActive ? Colors.white : Colors.white.withOpacity(0.5)),
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

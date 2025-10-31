// lib/features/live_streaming/screens/live_stream_viewer_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:textgb/features/live_streaming/models/refined_live_stream_model.dart';
import 'package:textgb/features/live_streaming/models/live_chat_message_model.dart';
import 'package:textgb/features/live_streaming/models/live_gift_model.dart';
import 'package:textgb/features/live_streaming/widgets/gift_selection_sheet.dart';
import 'package:textgb/features/live_streaming/widgets/gift_animation_overlay.dart';
import 'package:textgb/features/live_streaming/widgets/live_product_catalog_sheet.dart';
import 'package:textgb/features/live_streaming/constants/live_streaming_constants.dart';
import 'package:share_plus/share_plus.dart';
import 'package:textgb/shared/utils/deep_link_helper.dart';

class LiveStreamViewerScreen extends ConsumerStatefulWidget {
  final String streamId;
  final String? referrerId;
  final bool autoJoin;

  const LiveStreamViewerScreen({
    super.key,
    required this.streamId,
    this.referrerId,
    this.autoJoin = false,
  });

  @override
  ConsumerState<LiveStreamViewerScreen> createState() => _LiveStreamViewerScreenState();
}

class _LiveStreamViewerScreenState extends ConsumerState<LiveStreamViewerScreen>
    with TickerProviderStateMixin {
  // Agora
  RtcEngine? _engine;
  bool _isJoined = false;
  int? _remoteUid;

  // Chat
  final List<LiveChatMessageModel> _chatMessages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  // Gifts
  LiveGiftModel? _currentGiftAnimation;

  // Likes
  final List<_HeartAnimation> _hearts = [];
  late AnimationController _heartAnimationController;

  // Stream data (mock for now - will be from provider)
  RefinedLiveStreamModel? _stream;
  bool _isLoading = true;
  int _viewerCount = 0;
  int _likeCount = 0;

  // UI State
  bool _showChat = true;
  bool _showProductCatalog = false;

  @override
  void initState() {
    super.initState();
    _heartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.autoJoin) {
      _initAgora();
    }

    _loadStreamData();
    _startViewerCountTimer();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _chatScrollController.dispose();
    _heartAnimationController.dispose();
    _leaveChannel();
    super.dispose();
  }

  Future<void> _loadStreamData() async {
    // TODO: Load from provider
    // For now, mock data
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _viewerCount = 1247;
      _likeCount = 5643;
      _isLoading = false;
    });
  }

  void _startViewerCountTimer() {
    // Simulate viewer count updates
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _viewerCount += (DateTime.now().second % 3) - 1;
          if (_viewerCount < 0) _viewerCount = 0;
        });
      } else {
        timer.cancel();
      }
    });
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
              _isJoined = true;
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            setState(() {
              _remoteUid = remoteUid;
            });
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            setState(() {
              _remoteUid = null;
            });
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('Agora Error: $err - $msg');
          },
        ),
      );

      // Set client role to audience
      await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);

      // Enable video
      await _engine!.enableVideo();

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

  Future<void> _leaveChannel() async {
    await _engine?.leaveChannel();
    await _engine?.release();
  }

  void _onLike() {
    setState(() {
      _likeCount++;
      _addHeartAnimation();
    });

    // TODO: Send like to backend/WebSocket
  }

  void _addHeartAnimation() {
    final heart = _HeartAnimation(
      offset: Offset(
        MediaQuery.of(context).size.width * 0.8 + (DateTime.now().millisecond % 40 - 20),
        MediaQuery.of(context).size.height * 0.6,
      ),
    );

    setState(() {
      _hearts.add(heart);
    });

    // Remove heart after animation
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _hearts.remove(heart);
        });
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final message = LiveChatMessageModel.createTextMessage(
      liveStreamId: widget.streamId,
      senderId: 'currentUserId', // TODO: Get from auth provider
      senderName: 'You',
      senderImage: '',
      senderIsVerified: false,
      senderIsHost: false,
      senderIsModerator: false,
      message: _messageController.text.trim(),
    );

    setState(() {
      _chatMessages.add(message);
      _messageController.clear();
    });

    // Auto scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });

    // TODO: Send to backend/WebSocket
  }

  void _onSendGift(GiftType gift, int quantity) {
    final giftModel = LiveGiftModel.create(
      liveStreamId: widget.streamId,
      senderId: 'currentUserId', // TODO: Get from auth provider
      senderName: 'You',
      senderImage: '', // TODO: Get from auth provider
      senderIsVerified: false, // TODO: Get from auth provider
      receiverId: _stream?.hostId ?? '',
      receiverName: _stream?.hostName ?? '',
      giftType: gift,
      comboCount: quantity,
    );

    // Show gift animation
    setState(() {
      _currentGiftAnimation = giftModel;
    });

    // Add gift message to chat
    final giftMessage = LiveChatMessageModel.createGiftMessage(
      liveStreamId: widget.streamId,
      senderId: 'currentUserId',
      senderName: 'You',
      senderImage: '',
      senderIsVerified: false,
      giftId: gift.id,
      giftName: gift.name,
      giftEmoji: gift.emoji,
      giftPrice: gift.price * quantity,
      giftComboCount: quantity,
    );

    setState(() {
      _chatMessages.add(giftMessage);
    });

    // TODO: Send gift to backend/WebSocket
    // TODO: Deduct from user balance
  }

  void _shareStream() async {
    if (_stream == null) return;

    final link = DeepLinkHelper.liveStreamLink(
      widget.streamId,
      referrerId: 'currentUserId', // TODO: Get from auth provider
      autoJoin: true,
    );

    final shareText = DeepLinkHelper.liveStreamShareText(
      _stream!.hostName,
      _stream!.title,
      link,
    );

    await Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video view
          _buildVideoView(),

          // Gradient overlays for text readability
          _buildGradientOverlays(),

          // Top bar
          _buildTopBar(),

          // Chat messages
          if (_showChat) _buildChatOverlay(),

          // Bottom action buttons
          _buildBottomActions(),

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

          // Heart animations
          ..._hearts.map((heart) => _buildHeartAnimation(heart)),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoView() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.streamId),
        ),
      );
    }

    // Placeholder when no video
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Connecting to stream...',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
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
                Colors.black.withOpacity(0.6),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const Spacer(),
        // Bottom gradient
        Container(
          height: 300,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
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
            // Host info
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // TODO: Navigate to host profile
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey[800],
                        child: const Icon(Icons.person, size: 20, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    _stream?.hostName ?? 'Host',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  color: Colors.blue,
                                  size: 14,
                                ),
                              ],
                            ),
                            Text(
                              '$_viewerCount viewers',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: Colors.white, size: 6),
                            SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Share button
            GestureDetector(
              onTap: _shareStream,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(Icons.share, color: Colors.white, size: 20),
              ),
            ),

            const SizedBox(width: 8),

            // Close button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatOverlay() {
    return Positioned(
      left: 16,
      bottom: 120,
      right: 100,
      height: 300,
      child: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _chatScrollController,
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final message = _chatMessages[index];
                return _buildChatMessage(message);
              },
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Say something...',
                      hintStyle: TextStyle(color: Colors.white60),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    maxLength: 200,
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(LiveChatMessageModel message) {
    if (message.isGiftMessage) {
      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.withOpacity(0.6),
              Colors.pink.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.giftEmoji ?? '🎁',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (message.isSystemMessage || message.isWelcomeMessage) {
      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.message,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    // Regular text message
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${message.senderName}: ',
              style: TextStyle(
                color: message.senderIsHost
                    ? Colors.red
                    : message.senderIsModerator
                        ? Colors.amber
                        : Colors.blue[300],
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: message.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Positioned(
      right: 16,
      bottom: 120,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Like button
          GestureDetector(
            onTap: _onLike,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.favorite, color: Colors.red, size: 28),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCount(_likeCount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Gift button
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => GiftSelectionSheet(
                  userBalance: 5000.0, // TODO: Get from provider
                  onSendGift: _onSendGift,
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.pink],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.card_giftcard, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Gift',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Product catalog button (for shop streams)
          if (_stream?.isShopStream ?? false)
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => LiveProductCatalogSheet(
                    streamId: widget.streamId,
                    products: const [], // TODO: Get from stream model
                    pinnedProductId: null, // TODO: Get from stream model
                    onAddToCart: (product) {
                      // TODO: Add to cart functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} added to cart'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Colors.deepOrange],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.shopping_bag, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Shop',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Chat toggle button
          GestureDetector(
            onTap: () {
              setState(() {
                _showChat = !_showChat;
              });
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Icon(
                _showChat ? Icons.chat_bubble : Icons.chat_bubble_outline,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartAnimation(_HeartAnimation heart) {
    return Positioned(
      left: heart.offset.dx,
      bottom: MediaQuery.of(context).size.height - heart.offset.dy,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(seconds: 2),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          final yOffset = value * 300; // Float up 300px
          final opacity = 1.0 - value;
          final scale = 0.5 + (value * 0.5); // Grow slightly

          return Transform.translate(
            offset: Offset(0, -yOffset),
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: child,
              ),
            ),
          );
        },
        child: const Icon(
          Icons.favorite,
          color: Colors.red,
          size: 36,
          shadows: [
            Shadow(
              color: Colors.white,
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

// Helper class for heart animations
class _HeartAnimation {
  final Offset offset;

  _HeartAnimation({required this.offset});
}

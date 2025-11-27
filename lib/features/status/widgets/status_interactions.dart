// ===============================
// Status Interactions Widget
// Gift, Save, Like, and DM buttons (borrowed from video feature)
// ===============================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/providers/status_providers.dart';
import 'package:textgb/features/status/models/status_constants.dart';
import 'package:textgb/features/gifts/widgets/virtual_gifts_bottom_sheet.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/core/router/route_paths.dart';

class StatusInteractions extends ConsumerStatefulWidget {
  final StatusModel status;
  final bool isMyStatus;

  const StatusInteractions({
    super.key,
    required this.status,
    this.isMyStatus = false,
  });

  @override
  ConsumerState<StatusInteractions> createState() => _StatusInteractionsState();
}

class _StatusInteractionsState extends ConsumerState<StatusInteractions>
    with SingleTickerProviderStateMixin {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  // Animation for like button
  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;

  @override
  void initState() {
    super.initState();

    _likeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Gift button
        if (!widget.isMyStatus) _buildGiftButton(),

        const SizedBox(height: 16),

        // Save button (download)
        _buildSaveButton(),

        const SizedBox(height: 16),

        // Like button
        if (!widget.isMyStatus) _buildLikeButton(),

        const SizedBox(height: 16),

        // DM button
        if (!widget.isMyStatus) _buildDMButton(),
      ],
    );
  }

  // ===============================
  // GIFT BUTTON
  // ===============================

  Widget _buildGiftButton() {
    return _InteractionButton(
      icon: Icons.card_giftcard_rounded,
      label: widget.status.giftsCount > 0 ? '${widget.status.giftsCount}' : null,
      color: const Color(0xFFE55252),
      onTap: _handleGiftTap,
    );
  }

  void _handleGiftTap() {
    final currentUser = ref.read(currentUserProvider);

    if (currentUser == null) {
      _showSnackBar('Please log in to send gifts');
      return;
    }

    if (widget.status.userId == currentUser.uid) {
      _showSnackBar('You cannot send gifts to yourself');
      return;
    }

    _showVirtualGifts();
  }

  void _showVirtualGifts() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VirtualGiftsBottomSheet(
        recipientId: widget.status.userId,
        recipientName: widget.status.userName,
        onGiftSelected: (gift) async {
          try {
            await ref.read(statusFeedProvider.notifier).sendGift(
                  statusId: widget.status.id,
                  recipientId: widget.status.userId,
                  giftId: gift.id,
                );
            _showSnackBar(StatusConstants.successGiftSent);
          } catch (e) {
            _showSnackBar('Failed to send gift');
          }
        },
      ),
    );
  }

  // ===============================
  // SAVE BUTTON (DOWNLOAD)
  // ===============================

  Widget _buildSaveButton() {
    if (_isDownloading) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: _downloadProgress,
              strokeWidth: 3,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            Text(
              '${(_downloadProgress * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return _InteractionButton(
      icon: Icons.download_rounded,
      color: const Color(0xFF25D366),
      onTap: _handleSaveTap,
    );
  }

  void _handleSaveTap() async {
    if (widget.status.mediaUrl == null) {
      _showSnackBar('No media to download');
      return;
    }

    // Check permission for Android 13+
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidInfo();
      if (androidInfo != null && androidInfo >= 33) {
        // Android 13+ uses different permission model
        // Photos permission is granted by default for own app
      } else {
        // Request storage permission for older Android versions
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          _showSnackBar('Storage permission denied');
          return;
        }
      }
    }

    await _downloadStatus();
  }

  Future<int?> _getAndroidInfo() async {
    try {
      // This is a simplified version - in production, use device_info_plus
      return 33; // Assume Android 13+
    } catch (e) {
      return null;
    }
  }

  Future<void> _downloadStatus() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final dio = Dio();

      // Get downloads directory
      final directory = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download/WemaChat')
          : await getApplicationDocumentsDirectory();

      // Create directory if it doesn't exist
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Generate filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = widget.status.mediaType.isVideo ? 'mp4' : 'jpg';
      final fileName = 'status_$timestamp.$extension';
      final filePath = '${directory.path}/$fileName';

      // Download file with progress
      await dio.download(
        widget.status.mediaUrl!,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      _showSnackBar(StatusConstants.successSaved);
    } catch (e) {
      print('Error downloading status: $e');
      _showSnackBar('Failed to download status');
    } finally {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });
    }
  }

  // ===============================
  // LIKE BUTTON
  // ===============================

  Widget _buildLikeButton() {
    final isLiked = widget.status.isLikedByMe;

    return ScaleTransition(
      scale: _likeScaleAnimation,
      child: _InteractionButton(
        icon: isLiked ? Icons.favorite : Icons.favorite_border,
        label: widget.status.likesCount > 0 ? '${widget.status.likesCount}' : null,
        color: const Color(0xFFE55252),
        onTap: _handleLikeTap,
      ),
    );
  }

  void _handleLikeTap() async {
    final currentUser = ref.read(currentUserProvider);

    if (currentUser == null) {
      _showSnackBar('Please log in to like');
      return;
    }

    // Animate
    await _likeAnimationController.forward();
    await _likeAnimationController.reverse();

    try {
      await ref.read(statusFeedProvider.notifier).toggleLike(
            widget.status.id,
            widget.status.isLikedByMe,
          );
    } catch (e) {
      _showSnackBar('Failed to like status');
    }
  }

  // ===============================
  // DM BUTTON
  // ===============================

  Widget _buildDMButton() {
    return _InteractionButton(
      icon: Icons.send_rounded,
      color: const Color(0xFF53BDEB),
      onTap: _handleDMTap,
    );
  }

  void _handleDMTap() async {
    final currentUser = ref.read(currentUserProvider);

    if (currentUser == null) {
      _showSnackBar('Please log in to send messages');
      return;
    }

    if (widget.status.userId == currentUser.uid) {
      _showSnackBar('You cannot message yourself');
      return;
    }

    try {
      // Get or create chat with this user
      final chatProvider = ref.read(chatListProvider.notifier);
      final chatId = await chatProvider.createOrGetChat(widget.status.userId);

      if (mounted && chatId != null) {
        // Navigate to chat screen
        context.push(RoutePaths.chat(chatId));
      }
    } catch (e) {
      _showSnackBar('Failed to open chat');
    }
  }

  // ===============================
  // HELPERS
  // ===============================

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

// ===============================
// INTERACTION BUTTON WIDGET
// ===============================

class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color color;
  final VoidCallback onTap;

  const _InteractionButton({
    required this.icon,
    this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 24,
              color: Colors.white,
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
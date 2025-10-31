// lib/features/live_streaming/widgets/gift_animation_overlay.dart

import 'package:flutter/material.dart';
import 'package:textgb/features/live_streaming/models/live_gift_model.dart';

class GiftAnimationOverlay extends StatefulWidget {
  final LiveGiftModel gift;
  final VoidCallback onComplete;

  const GiftAnimationOverlay({
    super.key,
    required this.gift,
    required this.onComplete,
  });

  @override
  State<GiftAnimationOverlay> createState() => _GiftAnimationOverlayState();
}

class _GiftAnimationOverlayState extends State<GiftAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.gift.animationType == GiftAnimationType.fullscreen ? 3000 : 2000),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: _buildAnimationByType(),
        );
      },
    );
  }

  Widget _buildAnimationByType() {
    switch (widget.gift.animationType) {
      case GiftAnimationType.float:
        return _buildFloatAnimation();
      case GiftAnimationType.burst:
        return _buildBurstAnimation();
      case GiftAnimationType.cascade:
        return _buildCascadeAnimation();
      case GiftAnimationType.fullscreen:
        return _buildFullscreenAnimation();
      case GiftAnimationType.combo:
        return _buildComboAnimation();
    }
  }

  Widget _buildFloatAnimation() {
    return SlideTransition(
      position: _slideAnimation,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.only(bottom: 200),
          child: _buildGiftContent(),
        ),
      ),
    );
  }

  Widget _buildBurstAnimation() {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildGiftContent(size: 120),
      ),
    );
  }

  Widget _buildCascadeAnimation() {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildGiftContent(size: 150),
      ),
    );
  }

  Widget _buildFullscreenAnimation() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGiftContent(size: 200),
              const SizedBox(height: 24),
              Text(
                widget.gift.senderName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComboAnimation() {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.gift.giftEmoji,
              style: const TextStyle(fontSize: 100),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Text(
                'x${widget.gift.comboCount} COMBO!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftContent({double size = 80}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.8),
            Colors.pink.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.gift.giftEmoji,
            style: TextStyle(fontSize: size),
          ),
          const SizedBox(height: 8),
          Text(
            widget.gift.senderName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            widget.gift.giftName,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

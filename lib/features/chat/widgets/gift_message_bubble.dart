// lib/features/chat/widgets/gift_message_bubble.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class GiftMessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isCurrentUser;
  final double fontSize;

  const GiftMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.fontSize = 16.0,
  });

  @override
  State<GiftMessageBubble> createState() => _GiftMessageBubbleState();
}

class _GiftMessageBubbleState extends State<GiftMessageBubble>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _glowController;
  late AnimationController _openController;
  late AnimationController _confettiController;

  late Animation<double> _bounceAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _lidAnimation;

  bool _isOpened = false;
  final List<ConfettiParticle> _confettiParticles = [];

  @override
  void initState() {
    super.initState();

    // Check if gift was already opened
    _isOpened = widget.message.mediaMetadata?['isOpened'] == true;

    // Continuous bounce animation for unopened gift
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -8.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -8.0, end: 0.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 75,
      ),
    ]).animate(_bounceController);

    // Glow pulse animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Open animation
    _openController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _openController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(
        parent: _openController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
      ),
    );

    _lidAnimation = Tween<double>(begin: 0.0, end: -math.pi / 3).animate(
      CurvedAnimation(
        parent: _openController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    // Confetti animation
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Start animations if not opened
    if (!_isOpened) {
      _bounceController.repeat();
      _glowController.repeat(reverse: true);
    }
  }

  void _handleTap() async {
    if (_isOpened) return;

    setState(() {
      _isOpened = true;
    });

    // Stop bounce and glow
    _bounceController.stop();
    _glowController.stop();

    // Generate confetti particles
    for (int i = 0; i < 50; i++) {
      _confettiParticles.add(ConfettiParticle());
    }

    // Start open and confetti animations
    await Future.wait([
      _openController.forward(),
      _confettiController.forward(),
    ]);

    // TODO: Mark gift as opened in backend
    // You can call a method to update the message metadata
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _glowController.dispose();
    _openController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final giftData = widget.message.mediaMetadata ?? {};
    final giftName = giftData['giftName'] ?? 'Gift';
    final giftIcon = giftData['giftIcon'] ?? '🎁';
    final giftValue = giftData['giftValue'] ?? 0;

    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 250,
          minWidth: 200,
        ),
        margin: EdgeInsets.only(
          left: widget.isCurrentUser ? 50 : 16,
          right: widget.isCurrentUser ? 16 : 50,
          bottom: 8,
          top: 1,
        ),
        child: Stack(
          children: [
            // Main gift container
            AnimatedBuilder(
              animation: Listenable.merge([
                _bounceController,
                _glowController,
                _openController,
              ]),
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _isOpened ? 0 : _bounceAnimation.value),
                  child: Transform.scale(
                    scale: _isOpened ? _scaleAnimation.value : 1.0,
                    child: Transform.rotate(
                      angle: _isOpened ? _rotationAnimation.value : 0.0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              modernTheme.primaryColor ?? Colors.purple,
                              modernTheme.primaryColor?.withOpacity(0.7) ??
                                  Colors.purpleAccent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: (modernTheme.primaryColor ?? Colors.purple)
                                  .withOpacity(_isOpened
                                      ? 0.3
                                      : _glowAnimation.value * 0.5),
                              blurRadius: _isOpened ? 20 : 15,
                              spreadRadius: _isOpened ? 5 : 3,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Gift box with lid
                            SizedBox(
                              height: 100,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Gift box base
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        giftIcon,
                                        style: const TextStyle(fontSize: 40),
                                      ),
                                    ),
                                  ),

                                  // Animated lid (opens upward)
                                  if (_isOpened)
                                    Transform.translate(
                                      offset: Offset(
                                        0,
                                        -40 *
                                            math.sin(_lidAnimation.value.abs()),
                                      ),
                                      child: Transform.rotate(
                                        angle: _lidAnimation.value,
                                        alignment: Alignment.bottomCenter,
                                        child: Container(
                                          width: 90,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.95),
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(8),
                                              topRight: Radius.circular(8),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Container(
                                              width: 70,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: modernTheme.primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Gift details
                            Text(
                              giftName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.monetization_on,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$giftValue coins',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (!_isOpened) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Tap to open! 🎉',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Confetti particles
            if (_isOpened)
              ...List.generate(_confettiParticles.length, (index) {
                return AnimatedBuilder(
                  animation: _confettiController,
                  builder: (context, child) {
                    final particle = _confettiParticles[index];
                    final progress = _confettiController.value;

                    return Positioned(
                      left: 125 + particle.dx * progress * 150,
                      top: 80 +
                          particle.dy * progress * 200 +
                          (progress * progress * 200), // Gravity effect
                      child: Transform.rotate(
                        angle: particle.rotation * progress * 4 * math.pi,
                        child: Opacity(
                          opacity: (1 - progress).clamp(0.0, 1.0),
                          child: Container(
                            width: particle.size,
                            height: particle.size,
                            decoration: BoxDecoration(
                              color: particle.color,
                              shape: particle.isCircle
                                  ? BoxShape.circle
                                  : BoxShape.rectangle,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
          ],
        ),
      ),
    );
  }
}

class ConfettiParticle {
  final double dx;
  final double dy;
  final double size;
  final Color color;
  final double rotation;
  final bool isCircle;

  ConfettiParticle()
      : dx = (math.Random().nextDouble() - 0.5) * 2,
        dy = -math.Random().nextDouble(),
        size = math.Random().nextDouble() * 8 + 4,
        color =
            Colors.primaries[math.Random().nextInt(Colors.primaries.length)],
        rotation = math.Random().nextDouble(),
        isCircle = math.Random().nextBool();
}

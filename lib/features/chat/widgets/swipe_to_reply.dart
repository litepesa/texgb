// lib/features/chat/widgets/swipe_to_reply.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class SwipeToReply extends StatefulWidget {
  final Widget child;
  final MessageModel message;
  final Function(MessageModel) onReply;
  final bool isMyMessage;
  final double swipeThreshold;
  final Duration animationDuration;

  const SwipeToReply({
    Key? key,
    required this.child,
    required this.message,
    required this.onReply,
    required this.isMyMessage,
    this.swipeThreshold = 0.6,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply>
    with TickerProviderStateMixin {
  late AnimationController _swipeAnimationController;
  late AnimationController _resetAnimationController;
  late AnimationController _iconAnimationController;
  late AnimationController _rippleAnimationController;
  
  late Animation<double> _swipeAnimation;
  late Animation<double> _resetAnimation;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconOpacityAnimation;
  late Animation<Color?> _backgroundColorAnimation;
  late Animation<double> _rippleAnimation;

  double _swipeProgress = 0.0;
  double _currentOffset = 0.0;
  bool _isSwipeActive = false;
  bool _hasTriggeredHaptic = false;
  bool _hasReachedThreshold = false;

  static const double _maxSwipeOffset = 80.0;
  static const double _iconSize = 24.0;
  static const double _iconMaxScale = 1.3;
  static const double _rippleMaxRadius = 30.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Swipe animation controller
    _swipeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Reset animation controller
    _resetAnimationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // Icon animation controller
    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Ripple animation controller
    _rippleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Swipe offset animation
    _swipeAnimation = Tween<double>(
      begin: 0.0,
      end: _maxSwipeOffset,
    ).animate(CurvedAnimation(
      parent: _swipeAnimationController,
      curve: Curves.easeOut,
    ));

    // Reset animation with elastic curve
    _resetAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _resetAnimationController,
      curve: Curves.elasticOut,
    ));

    // Icon scale animation
    _iconScaleAnimation = Tween<double>(
      begin: 0.8,
      end: _iconMaxScale,
    ).animate(CurvedAnimation(
      parent: _iconAnimationController,
      curve: Curves.elasticOut,
    ));

    // Icon opacity animation
    _iconOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconAnimationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    // Ripple animation
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: _rippleMaxRadius,
    ).animate(CurvedAnimation(
      parent: _rippleAnimationController,
      curve: Curves.easeOut,
    ));

    // Background color animation
    _backgroundColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Theme.of(context).primaryColor.withOpacity(0.15),
    ).animate(CurvedAnimation(
      parent: _iconAnimationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _swipeAnimationController.dispose();
    _resetAnimationController.dispose();
    _iconAnimationController.dispose();
    _rippleAnimationController.dispose();
    super.dispose();
  }

  void _handlePanStart(DragStartDetails details) {
    setState(() {
      _isSwipeActive = true;
      _hasTriggeredHaptic = false;
      _hasReachedThreshold = false;
    });
    
    _resetAnimationController.stop();
    _iconAnimationController.forward();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isSwipeActive) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final swipeDirection = widget.isMyMessage ? -1.0 : 1.0;
    final deltaX = details.delta.dx * swipeDirection;

    // Only allow positive swipe (in the correct direction)
    if (deltaX > 0 || _currentOffset > 0) {
      setState(() {
        _currentOffset = (_currentOffset + deltaX).clamp(0.0, _maxSwipeOffset);
        _swipeProgress = (_currentOffset / _maxSwipeOffset).clamp(0.0, 1.0);
      });

      // Update animations based on progress
      _iconAnimationController.value = _swipeProgress;

      // Trigger haptic feedback at threshold
      if (_swipeProgress >= widget.swipeThreshold && !_hasTriggeredHaptic) {
        _hasTriggeredHaptic = true;
        _hasReachedThreshold = true;
        HapticFeedback.mediumImpact();
        
        // Start ripple animation
        _rippleAnimationController.forward();
      } else if (_swipeProgress < widget.swipeThreshold && _hasReachedThreshold) {
        _hasReachedThreshold = false;
        _rippleAnimationController.reset();
      }
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() => _isSwipeActive = false);

    if (_swipeProgress >= widget.swipeThreshold) {
      // Trigger reply action
      HapticFeedback.heavyImpact();
      widget.onReply(widget.message);
      
      // Success animation
      _triggerSuccessAnimation();
    } else {
      // Reset to original position with elastic animation
      _resetToOriginalPosition();
    }
  }

  void _triggerSuccessAnimation() {
    _rippleAnimationController.forward().then((_) {
      _resetToOriginalPosition();
    });
  }

  void _resetToOriginalPosition() {
    _resetAnimationController.forward().then((_) {
      setState(() {
        _currentOffset = 0.0;
        _swipeProgress = 0.0;
        _hasTriggeredHaptic = false;
        _hasReachedThreshold = false;
      });
      
      _resetAnimationController.reset();
      _iconAnimationController.reverse();
      _rippleAnimationController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _resetAnimationController,
          _iconAnimationController,
          _rippleAnimationController,
        ]),
        builder: (context, child) {
          final effectiveOffset = _currentOffset * _resetAnimation.value;
          
          return Stack(
            children: [
              // Background with swipe indicator
              if (_isSwipeActive || effectiveOffset > 0)
                _buildSwipeBackground(modernTheme, effectiveOffset),
              
              // Main content with offset
              Transform.translate(
                offset: Offset(
                  widget.isMyMessage ? -effectiveOffset : effectiveOffset,
                  0,
                ),
                child: widget.child,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSwipeBackground(ModernThemeExtension modernTheme, double offset) {
    final primaryColor = modernTheme.primaryColor ?? Theme.of(context).primaryColor;
    
    return Positioned.fill(
      child: Container(
        alignment: widget.isMyMessage 
            ? Alignment.centerRight 
            : Alignment.centerLeft,
        padding: EdgeInsets.only(
          left: widget.isMyMessage ? 0 : 20,
          right: widget.isMyMessage ? 20 : 0,
        ),
        decoration: BoxDecoration(
          color: _backgroundColorAnimation.value,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ripple effect when threshold reached
            if (_hasReachedThreshold)
              AnimatedBuilder(
                animation: _rippleAnimation,
                builder: (context, child) {
                  return Container(
                    width: _rippleAnimation.value * 2,
                    height: _rippleAnimation.value * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(
                        0.3 * (1 - _rippleAnimationController.value),
                      ),
                    ),
                  );
                },
              ),
            
            // Reply icon with animations
            AnimatedBuilder(
              animation: Listenable.merge([
                _iconScaleAnimation,
                _iconOpacityAnimation,
              ]),
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.8 + (_swipeProgress * 0.5),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _hasReachedThreshold
                          ? primaryColor.withOpacity(0.9)
                          : primaryColor.withOpacity(_swipeProgress * 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.reply_rounded,
                      size: _iconSize,
                      color: Colors.white.withOpacity(
                        _iconOpacityAnimation.value,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
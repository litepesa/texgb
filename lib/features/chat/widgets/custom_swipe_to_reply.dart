// lib/features/chat/widgets/custom_swipe_to_reply.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:textgb/features/chat/models/message_model.dart';

class CustomSwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onSwipeToReply;
  final MessageModel message;
  final bool isCurrentUser;

  const CustomSwipeToReply({
    super.key,
    required this.child,
    required this.onSwipeToReply,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  State<CustomSwipeToReply> createState() => _CustomSwipeToReplyState();
}

class _CustomSwipeToReplyState extends State<CustomSwipeToReply>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late AnimationController _replyIconController;
  late Animation<double> _slideAnimation;
  late Animation<double> _replyIconAnimation;
  
  double _dragExtent = 0.0;
  bool _dragUnderway = false;
  bool _hasTriggeredReply = false;
  
  static const double _kSwipeThreshold = 80.0;
  static const double _kMaxSwipeDistance = 120.0;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _replyIconController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _replyIconAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _replyIconController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _replyIconController.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    _dragUnderway = true;
    _hasTriggeredReply = false;
    
    if (_animationController.isAnimating) {
      _animationController.stop();
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_dragUnderway) return;
    
    final delta = details.primaryDelta ?? 0.0;
    
    // Only allow right swipes (positive delta for LTR)
    if (delta > 0) {
      setState(() {
        _dragExtent = (_dragExtent + delta).clamp(0.0, _kMaxSwipeDistance);
      });
      
      // Trigger haptic feedback and icon animation when threshold is reached
      if (_dragExtent >= _kSwipeThreshold && !_hasTriggeredReply) {
        _hasTriggeredReply = true;
        _replyIconController.forward().then((_) {
          _replyIconController.reverse();
        });
        
        // Haptic feedback
        HapticFeedback.mediumImpact();
      } else if (_dragExtent < _kSwipeThreshold && _hasTriggeredReply) {
        _hasTriggeredReply = false;
        _replyIconController.reverse();
      }
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_dragUnderway) return;
    
    _dragUnderway = false;
    
    if (_dragExtent >= _kSwipeThreshold) {
      // Trigger reply
      widget.onSwipeToReply();
      
      // Show completion animation
      _animationController.forward().then((_) {
        _animationController.reverse().then((_) {
          setState(() {
            _dragExtent = 0.0;
          });
        });
      });
    } else {
      // Snap back
      _animateToPosition(0.0);
    }
  }

  void _animateToPosition(double targetPosition) {
    final currentPosition = _dragExtent;
    final controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    final animation = Tween<double>(
      begin: currentPosition,
      end: targetPosition,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));
    
    animation.addListener(() {
      setState(() {
        _dragExtent = animation.value;
      });
    });
    
    controller.forward().then((_) {
      controller.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // Reply icon background
          if (_dragExtent > 0) ...[
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _replyIconAnimation,
                builder: (context, child) {
                  final opacity = (_dragExtent / _kSwipeThreshold).clamp(0.0, 1.0);
                  final scale = 0.8 + (0.4 * _replyIconAnimation.value);
                  
                  return Center(
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _hasTriggeredReply 
                            ? Colors.green.withOpacity(0.9)
                            : Colors.green.withOpacity(0.7 * opacity),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.reply,
                          color: Colors.white.withOpacity(opacity),
                          size: 20,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          
          // Message content with slide transformation
          Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                // Add a subtle scale effect during completion animation
                final scale = 1.0 - (0.02 * _slideAnimation.value);
                return Transform.scale(
                  scale: scale,
                  child: widget.child,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
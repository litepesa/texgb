// lib/features/video_reactions/widgets/video_reaction_swipe_to_wrapper.dart
// COPIED: Exact same UI as chat SwipeToWrapper but for video reactions
import 'package:flutter/material.dart';
import 'package:textgb/features/video_reactions/models/video_reaction_message_model.dart';
import 'package:textgb/features/video_reactions/widgets/video_reaction_message_bubble.dart';

class VideoReactionSwipeToWrapper extends StatefulWidget {
  final VideoReactionMessageModel message;
  final bool isCurrentUser;
  final bool isLastInGroup;
  final double fontSize;
  final String? contactName;
  final VoidCallback? onLongPress;
  final VoidCallback? onVideoTap;
  final VoidCallback? onRightSwipe;

  const VideoReactionSwipeToWrapper({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.isLastInGroup = true,
    this.fontSize = 16.0,
    this.contactName,
    this.onLongPress,
    this.onVideoTap,
    this.onRightSwipe,
  });

  @override
  State<VideoReactionSwipeToWrapper> createState() => _VideoReactionSwipeToWrapperState();
}

class _VideoReactionSwipeToWrapperState extends State<VideoReactionSwipeToWrapper>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  double _dragDistance = 0;
  bool _isDragging = false;
  static const double _swipeThreshold = 100.0;
  static const double _maxDragDistance = 150.0;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.3, 0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _handlePanStart(DragStartDetails details) {
    _isDragging = true;
    _fadeController.forward();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    
    // Only allow right swipe (positive delta for LTR languages)
    final delta = details.delta.dx;
    if (delta > 0) {
      setState(() {
        _dragDistance = (_dragDistance + delta).clamp(0.0, _maxDragDistance);
      });
      
      // Update slide animation based on drag distance
      final progress = (_dragDistance / _maxDragDistance).clamp(0.0, 1.0);
      _slideController.value = progress;
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!_isDragging) return;
    
    _isDragging = false;
    _fadeController.reverse();
    
    if (_dragDistance > _swipeThreshold) {
      // Trigger reply action
      widget.onRightSwipe?.call();
    }
    
    // Reset position
    _slideController.reverse().then((_) {
      setState(() {
        _dragDistance = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Stack(
        children: [
          // Reply indicator (appears during swipe)
          if (_isDragging && _dragDistance > 20)
            Positioned(
              left: widget.isCurrentUser ? null : 16,
              right: widget.isCurrentUser ? 16 : null,
              top: 0,
              bottom: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  alignment: widget.isCurrentUser 
                    ? Alignment.centerLeft 
                    : Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.reply,
                      color: Colors.white,
                      size: _dragDistance > _swipeThreshold ? 24 : 20,
                    ),
                  ),
                ),
              ),
            ),
          
          // Message bubble
          SlideTransition(
            position: _slideAnimation,
            child: VideoReactionMessageBubble(
              message: widget.message,
              isCurrentUser: widget.isCurrentUser,
              isLastInGroup: widget.isLastInGroup,
              fontSize: widget.fontSize,
              contactName: widget.contactName,
              onLongPress: widget.onLongPress,
              onVideoTap: widget.onVideoTap,
            ),
          ),
        ],
      ),
    );
  }
}


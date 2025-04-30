import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import '../../domain/models/status_post.dart';
import '../../domain/models/status_reaction.dart';
import '../../application/providers/app_providers.dart';
import '../../../../features/authentication/authentication_provider.dart';

class StatusReactionButton extends ConsumerStatefulWidget {
  final StatusPost post;
  final Function(ReactionType) onReact;
  
  const StatusReactionButton({
    Key? key,
    required this.post,
    required this.onReact,
  }) : super(key: key);
  
  @override
  ConsumerState<StatusReactionButton> createState() => _StatusReactionButtonState();
}

class _StatusReactionButtonState extends ConsumerState<StatusReactionButton> {
  bool _isReactionMenuOpen = false;
  
  @override
  Widget build(BuildContext context) {
    // Get current user using the Provider-based auth
    final authProvider = provider_pkg.Provider.of<AuthenticationProvider>(context, listen: false);
    final currentUser = authProvider.userModel;
    
    if (currentUser == null) {
      return TextButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to react to posts')),
          );
        },
        icon: const Icon(Icons.thumb_up_outlined, size: 20, color: Colors.grey),
        label: const Text('Like', style: TextStyle(color: Colors.grey)),
      );
    }
    
    // Check if user already reacted
    final userReaction = widget.post.getReactionByUser(currentUser.uid);
    
    return GestureDetector(
      onLongPress: _showReactionMenu,
      child: TextButton.icon(
        onPressed: () {
          if (userReaction != null) {
            // If already reacted, remove the reaction
            widget.onReact(userReaction.type);
          } else {
            // Default to like if not reacted yet
            widget.onReact(ReactionType.like);
          }
        },
        icon: Icon(
          userReaction != null ? Icons.thumb_up : Icons.thumb_up_outlined,
          size: 20,
          color: userReaction != null ? Theme.of(context).primaryColor : Colors.grey[700],
        ),
        label: Text(
          userReaction != null ? _getReactionText(userReaction.type) : 'Like',
          style: TextStyle(
            color: userReaction != null ? Theme.of(context).primaryColor : Colors.grey[700],
          ),
        ),
      ),
    );
  }
  
  void _showReactionMenu() {
    setState(() {
      _isReactionMenuOpen = true;
    });
    
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(Offset.zero);
    
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Stack(
          children: [
            Positioned(
              left: position.dx,
              top: position.dy - 60, // Position above the button
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildReactionOption(ReactionType.like),
                      _buildReactionOption(ReactionType.love),
                      _buildReactionOption(ReactionType.haha),
                      _buildReactionOption(ReactionType.wow),
                      _buildReactionOption(ReactionType.sad),
                      _buildReactionOption(ReactionType.angry),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _isReactionMenuOpen = false;
        });
      }
    });
  }
  
  Widget _buildReactionOption(ReactionType type) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        widget.onReact(type);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getReactionEmoji(type),
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              _getReactionText(type),
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getReactionEmoji(ReactionType type) {
    switch (type) {
      case ReactionType.like:
        return '👍';
      case ReactionType.love:
        return '❤️';
      case ReactionType.haha:
        return '😂';
      case ReactionType.wow:
        return '😮';
      case ReactionType.sad:
        return '😢';
      case ReactionType.angry:
        return '😠';
    }
  }
  
  String _getReactionText(ReactionType type) {
    switch (type) {
      case ReactionType.like:
        return 'Like';
      case ReactionType.love:
        return 'Love';
      case ReactionType.haha:
        return 'Haha';
      case ReactionType.wow:
        return 'Wow';
      case ReactionType.sad:
        return 'Sad';
      case ReactionType.angry:
        return 'Angry';
    }
  }
}
// lib/features/video_reactions/widgets/video_reaction_input_widget.dart
// COPIED: Exact same UI as the chat version but for video reactions
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/video_reactions/services/video_thumbnail_service.dart';
import 'package:textgb/features/video_reactions/widgets/video_thumbnail_widget.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class VideoReactionInputWidget extends ConsumerStatefulWidget {
  final VideoModel video;
  final Function(String reaction) onSendReaction;
  final VoidCallback onCancel;

  const VideoReactionInputWidget({
    super.key,
    required this.video,
    required this.onSendReaction,
    required this.onCancel,
  });

  @override
  ConsumerState<VideoReactionInputWidget> createState() => _VideoReactionInputWidgetState();
}

class _VideoReactionInputWidgetState extends ConsumerState<VideoReactionInputWidget>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final VideoThumbnailService _thumbnailService = VideoThumbnailService();
  
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    // Start animations
    _slideController.forward();
    _fadeController.forward();
    
    // Auto-focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _sendReaction(String reaction) {
    if (reaction.trim().isNotEmpty) {
      widget.onSendReaction(reaction);
      _textController.clear();
      _closeWithAnimation();
    }
  }

  void _closeWithAnimation() async {
    await _fadeController.reverse();
    await _slideController.reverse();
    widget.onCancel();
  }

  // Get the best available thumbnail URL
  String? _getBestThumbnailUrl() {
    if (widget.video.thumbnailUrl.isNotEmpty) {
      return widget.video.thumbnailUrl;
    }
    
    if (widget.video.isMultipleImages && widget.video.imageUrls.isNotEmpty) {
      return widget.video.imageUrls.first;
    }
    
    return null;
  }

  // Get video creator info from user provider
  UserModel? _getVideoCreator() {
    final users = ref.watch(usersProvider);
    try {
      return users.firstWhere(
        (user) => user.uid == widget.video.userId,
        orElse: () => null as UserModel,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final currentUser = ref.watch(currentUserProvider);
    final videoCreator = _getVideoCreator();
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.only(bottom: keyboardHeight),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                modernTheme.surfaceColor?.withOpacity(0.98) ?? Colors.white.withOpacity(0.98),
                modernTheme.surfaceColor ?? Colors.white,
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 32,
                offset: const Offset(0, -8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: modernTheme.primaryColor?.withOpacity(0.08) ?? Colors.blue.withOpacity(0.08),
                blurRadius: 48,
                offset: const Offset(0, -12),
                spreadRadius: 0,
              ),
            ],
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Enhanced handle bar
                  Center(
                    child: Container(
                      width: 56,
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            modernTheme.primaryColor?.withOpacity(0.4) ?? Colors.grey.withOpacity(0.4),
                            modernTheme.primaryColor?.withOpacity(0.7) ?? Colors.grey.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: modernTheme.primaryColor?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Enhanced header with better typography and layout
                  Row(
                    children: [
                      // Enhanced reaction badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              modernTheme.primaryColor?.withOpacity(0.15) ?? Colors.blue.withOpacity(0.15),
                              modernTheme.primaryColor?.withOpacity(0.08) ?? Colors.blue.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: modernTheme.primaryColor?.withOpacity(0.25) ?? Colors.blue.withOpacity(0.25),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: modernTheme.primaryColor?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: modernTheme.primaryColor?.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                CupertinoIcons.bubble_left,
                                size: 16,
                                color: modernTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Share Reaction',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: modernTheme.primaryColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      
                      // Enhanced close button
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              modernTheme.surfaceVariantColor?.withOpacity(0.8) ?? Colors.grey.shade100,
                              modernTheme.surfaceVariantColor?.withOpacity(0.4) ?? Colors.grey.shade50,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: modernTheme.dividerColor?.withOpacity(0.4) ?? Colors.grey.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: _closeWithAnimation,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.close_rounded,
                                color: modernTheme.textSecondaryColor,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Enhanced video preview card with user provider data
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          modernTheme.surfaceColor ?? Colors.white,
                          modernTheme.surfaceVariantColor?.withOpacity(0.4) ?? Colors.grey.shade50,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: modernTheme.dividerColor?.withOpacity(0.6) ?? Colors.grey.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: modernTheme.primaryColor?.withOpacity(0.04) ?? Colors.blue.withOpacity(0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Enhanced video thumbnail with play overlay
                          Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SizedBox(
                                    width: 88,
                                    height: 88,
                                    child: VideoThumbnailWidget(
                                      videoUrl: widget.video.videoUrl,
                                      fallbackThumbnailUrl: _getBestThumbnailUrl(),
                                      width: 88,
                                      height: 88,
                                      fit: BoxFit.cover,
                                      showPlayButton: false,
                                      enableGestures: false,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          
                          // Enhanced video info with real user data
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // User info row with real data from user provider
                                Row(
                                  children: [
                                    // Enhanced avatar with verification badge
                                    Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: modernTheme.primaryColor?.withOpacity(0.4) ?? Colors.blue.withOpacity(0.4),
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: modernTheme.primaryColor?.withOpacity(0.2) ?? Colors.blue.withOpacity(0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            radius: 16,
                                            backgroundColor: modernTheme.primaryColor?.withOpacity(0.1),
                                            backgroundImage: (videoCreator?.profileImage.isNotEmpty == true)
                                                ? NetworkImage(videoCreator!.profileImage)
                                                : null,
                                            child: (videoCreator?.profileImage.isEmpty != false)
                                                ? Text(
                                                    (videoCreator?.name.isNotEmpty == true) 
                                                      ? videoCreator!.name[0].toUpperCase()
                                                      : widget.video.userName.isNotEmpty 
                                                        ? widget.video.userName[0].toUpperCase()
                                                        : 'U',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: modernTheme.primaryColor,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                        ),
                                        
                                        // Verification badge
                                        if (videoCreator?.isVerified == true)
                                          Positioned(
                                            bottom: -2,
                                            right: -2,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: modernTheme.surfaceColor ?? Colors.white,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.verified_rounded,
                                                size: 12,
                                                color: modernTheme.primaryColor,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    
                                    // User name and metadata
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Use real username from user provider
                                          Text(
                                            videoCreator?.name ?? widget.video.userName,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: modernTheme.textColor,
                                              letterSpacing: 0.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          
                                          // Enhanced metadata row
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      modernTheme.primaryColor?.withOpacity(0.12) ?? Colors.blue.withOpacity(0.12),
                                                      modernTheme.primaryColor?.withOpacity(0.06) ?? Colors.blue.withOpacity(0.06),
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: modernTheme.primaryColor?.withOpacity(0.2) ?? Colors.blue.withOpacity(0.2),
                                                    width: 0.5,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      widget.video.isMultipleImages 
                                                        ? Icons.photo_library_rounded 
                                                        : Icons.videocam_rounded,
                                                      size: 10,
                                                      color: modernTheme.primaryColor,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      widget.video.isMultipleImages ? 'Photos' : 'Video',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                        color: modernTheme.primaryColor,
                                                        letterSpacing: 0.4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              
                                              // Follower count if available
                                              if (videoCreator != null) ...[
                                                const SizedBox(width: 8),
                                                Text(
                                                  '${videoCreator.followers} followers',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: modernTheme.textSecondaryColor?.withOpacity(0.8),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // Video caption preview (if available)
                                if (widget.video.caption.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: modernTheme.surfaceVariantColor?.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: modernTheme.dividerColor?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      widget.video.caption,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: modernTheme.textSecondaryColor,
                                        fontWeight: FontWeight.w400,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Enhanced text input section header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Your reaction',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: modernTheme.textColor,
                                letterSpacing: -0.3,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: modernTheme.primaryColor?.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'to ${videoCreator?.name ?? widget.video.userName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: modernTheme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Share your thoughts about this ${widget.video.isMultipleImages ? 'post' : 'video'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: modernTheme.textSecondaryColor?.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Enhanced text input with modern design
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          modernTheme.surfaceColor ?? Colors.white,
                          modernTheme.surfaceVariantColor?.withOpacity(0.2) ?? Colors.grey.shade50,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _focusNode.hasFocus 
                          ? modernTheme.primaryColor?.withOpacity(0.8) ?? Colors.blue.withOpacity(0.8)
                          : modernTheme.dividerColor?.withOpacity(0.6) ?? Colors.grey.withOpacity(0.3),
                        width: _focusNode.hasFocus ? 2 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                        if (_focusNode.hasFocus)
                          BoxShadow(
                            color: modernTheme.primaryColor?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Current user avatar
                        Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: modernTheme.primaryColor?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: modernTheme.primaryColor?.withOpacity(0.1),
                            backgroundImage: currentUser?.profileImage.isNotEmpty == true
                                ? NetworkImage(currentUser!.profileImage)
                                : null,
                            child: currentUser?.profileImage.isEmpty != false
                                ? Text(
                                    currentUser?.name.isNotEmpty == true 
                                      ? currentUser!.name[0].toUpperCase()
                                      : 'Y',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: modernTheme.primaryColor,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        
                        // Text input
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            focusNode: _focusNode,
                            maxLines: 4,
                            minLines: 1,
                            textCapitalization: TextCapitalization.sentences,
                            style: TextStyle(
                              color: modernTheme.textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.1,
                              height: 1.4,
                            ),
                            decoration: InputDecoration(
                              hintText: widget.video.isMultipleImages 
                                ? 'What do you think about these photos?'
                                : 'Share your reaction to this video...',
                              hintStyle: TextStyle(
                                color: modernTheme.textSecondaryColor?.withOpacity(0.6),
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.1,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            onSubmitted: _sendReaction,
                          ),
                        ),
                        
                        // Enhanced send button
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _textController.text.trim().isNotEmpty ? [
                                modernTheme.primaryColor ?? Colors.blue,
                                modernTheme.primaryColor?.withOpacity(0.8) ?? Colors.blue.withOpacity(0.8),
                              ] : [
                                modernTheme.dividerColor?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3),
                                modernTheme.dividerColor?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _textController.text.trim().isNotEmpty ? [
                              BoxShadow(
                                color: modernTheme.primaryColor?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ] : [],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: _textController.text.trim().isNotEmpty 
                                ? () => _sendReaction(_textController.text)
                                : null,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  Icons.send_rounded,
                                  color: _textController.text.trim().isNotEmpty 
                                    ? Colors.white 
                                    : modernTheme.textSecondaryColor?.withOpacity(0.5),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Enhanced bottom spacing with keyboard adjustment
                  SizedBox(height: keyboardHeight > 0 ? 16 : 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


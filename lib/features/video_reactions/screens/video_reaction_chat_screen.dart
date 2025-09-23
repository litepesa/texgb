// lib/features/video_reactions/screens/video_reaction_chat_screen.dart
// COPIED: Exact same UI as ChatScreen but specialized for video reactions
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/video_reactions/models/video_reaction_message_model.dart';
import 'package:textgb/features/video_reactions/providers/video_reactions_provider.dart';
import 'package:textgb/features/video_reactions/widgets/video_reaction_bubble_widget.dart';
import 'package:textgb/features/video_reactions/widgets/video_reaction_message_input.dart';
import 'package:textgb/features/video_reactions/widgets/video_reaction_swipe_to_wrapper.dart';
import 'package:textgb/features/video_reactions/widgets/video_player_overlay.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class VideoReactionChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final UserModel contact;

  const VideoReactionChatScreen({
    super.key,
    required this.chatId,
    required this.contact,
  });

  @override
  ConsumerState<VideoReactionChatScreen> createState() => _VideoReactionChatScreenState();
}

class _VideoReactionChatScreenState extends ConsumerState<VideoReactionChatScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;
  String? _backgroundImage;
  double _fontSize = 16.0;
  bool _hasMessageBeenSent = false;
  
  // Video player state
  bool _isVideoPlayerVisible = false;
  String? _currentVideoUrl;

  // Cache manager instances
  static final DefaultCacheManager _imageCacheManager = DefaultCacheManager();
  static final DefaultCacheManager _videoCacheManager = DefaultCacheManager();
  static final DefaultCacheManager _fileCacheManager = DefaultCacheManager();

  // RFC 3339 date formatters
  static final DateFormat _rfc3339Format = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
  static final DateFormat _displayDateFormat = DateFormat('MMM dd, HH:mm');
  static final DateFormat _searchDateFormat = DateFormat('MMM dd, yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_scrollListener);
    
    // Mark messages as read when entering chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _markMessagesAsRead();
    }
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final showButton = _scrollController.offset > 200;
      if (showButton != _showScrollToBottom) {
        setState(() {
          _showScrollToBottom = showButton;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _markMessagesAsRead() {
    final messageNotifier = ref.read(videoReactionMessagesProvider(widget.chatId).notifier);
    final currentUser = ref.read(currentUserProvider);
    
    if (currentUser != null) {
      final messageState = ref.read(videoReactionMessagesProvider(widget.chatId)).valueOrNull;
      if (messageState != null) {
        final unreadMessageIds = messageState.messages
            .where((msg) => msg.senderId != currentUser.uid && !msg.isReadBy(currentUser.uid))
            .map((msg) => msg.messageId)
            .toList();
        
        if (unreadMessageIds.isNotEmpty) {
          messageNotifier.markMessagesAsDelivered(widget.chatId, unreadMessageIds);
        }
      }
    }
  }

  // Helper method to format timestamp to RFC 3339
  String _formatTimestampToRFC3339(DateTime timestamp) {
    final utcTimestamp = timestamp.toUtc();
    return _rfc3339Format.format(utcTimestamp);
  }

  // Helper method to parse RFC 3339 timestamp
  DateTime _parseRFC3339Timestamp(String rfc3339String) {
    try {
      return _rfc3339Format.parse(rfc3339String, true).toLocal();
    } catch (e) {
      debugPrint('Error parsing RFC 3339 timestamp: $e');
      return DateTime.now();
    }
  }

  // Helper method to format timestamp for display
  String _formatTimestampForDisplay(DateTime timestamp) {
    return _displayDateFormat.format(timestamp);
  }

  // Helper method to format timestamp for search results
  String _formatTimestampForSearch(DateTime timestamp) {
    return _searchDateFormat.format(timestamp);
  }

  // Helper method to determine verification status
  bool _isContactVerified() {
    return widget.contact.isVerified;
  }

  // Cache management methods
  Future<File?> _getCachedFile(String url, {String? cacheKey}) async {
    try {
      final key = cacheKey ?? url;
      final fileInfo = await _fileCacheManager.getFileFromCache(key);
      if (fileInfo != null && fileInfo.file.existsSync()) {
        return fileInfo.file;
      }
      
      // Download and cache the file
      final file = await _fileCacheManager.getSingleFile(url, key: key);
      return file;
    } catch (e) {
      debugPrint('Error caching file: $e');
      return null;
    }
  }

  Future<void> _preloadMessageMedia(List<VideoReactionMessageModel> messages) async {
    // Preload recent images and videos for smooth scrolling
    final recentMessages = messages.take(20).where((msg) => 
      msg.type == MessageEnum.image || 
      msg.type == MessageEnum.video ||
      msg.isOriginalReaction ||
      (msg.videoReactionData != null)
    );

    for (final message in recentMessages) {
      try {
        if (message.type == MessageEnum.image && message.mediaUrl?.isNotEmpty == true) {
          // Preload image
          _imageCacheManager.getSingleFile(message.mediaUrl!);
        } else if (message.type == MessageEnum.video && message.mediaUrl?.isNotEmpty == true) {
          // Preload video thumbnail or video file
          _videoCacheManager.getSingleFile(message.mediaUrl!);
        } else if (message.isOriginalReaction && message.videoReactionData != null) {
          // Preload video reaction thumbnail
          final videoUrl = message.videoReactionData!.videoUrl;
          if (videoUrl.isNotEmpty) {
            _videoCacheManager.getSingleFile(videoUrl);
          }
        }
      } catch (e) {
        // Continue preloading other media even if one fails
        debugPrint('Error preloading media: $e');
      }
    }
  }

  Future<void> _clearChatCache() async {
    try {
      await _imageCacheManager.emptyCache();
      await _videoCacheManager.emptyCache();
      await _fileCacheManager.emptyCache();
      
      if (mounted) {
        showSnackBar(context, 'Chat cache cleared');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to clear cache');
      }
    }
  }

  // Video player methods with caching
  void _handleVideoThumbnailTap(VideoReactionMessageModel message) async {
    String? videoUrl;
    
    if (message.type == MessageEnum.video) {
      videoUrl = message.mediaUrl;
    } else if (message.isOriginalReaction && message.videoReactionData != null) {
      videoUrl = message.videoReactionData!.videoUrl;
    }
    
    if (videoUrl == null || videoUrl.isEmpty) {
      showSnackBar(context, 'Video not available');
      return;
    }
    
    // Show loading indicator while getting cached video
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      // Get cached video file
      final cachedFile = await _getCachedFile(videoUrl, cacheKey: '${message.messageId}_video');
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        if (cachedFile != null) {
          _showVideoPlayer(cachedFile.path);
        } else {
          _showVideoPlayer(videoUrl); // Fallback to URL
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        showSnackBar(context, 'Failed to load video');
      }
    }
  }

  void _showVideoPlayer(String videoPath) {
    setState(() {
      _currentVideoUrl = videoPath;
      _isVideoPlayerVisible = true;
    });
  }

  void _closeVideoPlayer() {
    setState(() {
      _isVideoPlayerVisible = false;
      _currentVideoUrl = null;
    });
  }

  // Method to get cached contact image
  Widget _buildContactAvatar({double radius = 18}) {
    if (widget.contact.profileImage.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: context.modernTheme.primaryColor?.withOpacity(0.2),
        child: Text(
          widget.contact.name.isNotEmpty 
            ? widget.contact.name[0].toUpperCase()
            : '?',
          style: TextStyle(
            color: context.modernTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.6,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.contact.profileImage,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: context.modernTheme.primaryColor?.withOpacity(0.2),
        child: SizedBox(
          width: radius,
          height: radius,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.modernTheme.primaryColor,
          ),
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: context.modernTheme.primaryColor?.withOpacity(0.2),
        child: Text(
          widget.contact.name.isNotEmpty 
            ? widget.contact.name[0].toUpperCase()
            : '?',
          style: TextStyle(
            color: context.modernTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.6,
          ),
        ),
      ),
      cacheManager: _imageCacheManager,
    );
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final chatTheme = context.chatTheme;
    final currentUser = ref.watch(currentUserProvider);
    final messageState = ref.watch(videoReactionMessagesProvider(widget.chatId));
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('User not authenticated')),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        // Close video player if open
        if (_isVideoPlayerVisible) {
          _closeVideoPlayer();
          return false;
        }
        
        // Return whether any message was sent when popping
        Navigator.of(context).pop(_hasMessageBeenSent);
        return false;
      },
      child: Scaffold(
        backgroundColor: chatTheme.chatBackgroundColor,
        extendBodyBehindAppBar: false,
        appBar: _buildAppBar(modernTheme),
        body: Stack(
          children: [
            // Main chat content
            Container(
              decoration: _backgroundImage != null
                  ? BoxDecoration(
                      image: DecorationImage(
                        image: FileImage(File(_backgroundImage!)),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.1),
                          BlendMode.darken,
                        ),
                      ),
                    )
                  : null,
              child: Column(
                children: [
                  // Original video reaction display (NEW)
                  _buildOriginalVideoReactionDisplay(),
                  
                  // Messages list
                  Expanded(
                    child: messageState.when(
                      loading: () => _buildLoadingState(modernTheme),
                      error: (error, stack) => _buildErrorState(modernTheme, error.toString()),
                      data: (state) {
                        // Preload media for smooth scrolling
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _preloadMessageMedia(state.messages);
                        });
                        return _buildMessagesList(state, currentUser);
                      },
                    ),
                  ),
                  
                  // Message input (hide when video player is visible)
                  if (!_isVideoPlayerVisible)
                    messageState.maybeWhen(
                      data: (state) => VideoReactionMessageInput(
                        onSendText: (text) => _handleSendText(text),
                        contactName: widget.contact.name,
                        replyToMessage: state.replyToMessage,
                        onCancelReply: () => _cancelReply(),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
            
            // Video Player Overlay
            if (_isVideoPlayerVisible && _currentVideoUrl != null)
              VideoPlayerOverlay(
                videoUrl: _currentVideoUrl!,
                onClose: _closeVideoPlayer,
                title: 'Shared Video',
              ),
              
            // Scroll to bottom button
            if (_showScrollToBottom && !_isVideoPlayerVisible)
              Positioned(
                right: 8,
                bottom: 80,
                child: FloatingActionButton.small(
                  onPressed: _scrollToBottom,
                  backgroundColor: modernTheme.primaryColor?.withOpacity(0.3),
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.keyboard_arrow_down),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // NEW: Display the original video reaction at the top
  Widget _buildOriginalVideoReactionDisplay() {
    final messageState = ref.watch(videoReactionMessagesProvider(widget.chatId)).valueOrNull;
    final originalVideoReaction = messageState?.originalVideoReaction;
    
    if (originalVideoReaction == null) {
      return const SizedBox.shrink();
    }

    final modernTheme = context.modernTheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor?.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: modernTheme.dividerColor?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.video_library,
                size: 16,
                color: modernTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Original Video Reaction',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: modernTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Video reaction bubble (smaller version)
          Transform.scale(
            scale: 0.85,
            child: VideoReactionBubbleWidget(
              videoReaction: originalVideoReaction,
              isCurrentUser: false, // Always show as received since it's the original
              onVideoTap: () => _handleOriginalVideoTap(originalVideoReaction),
            ),
          ),
        ],
      ),
    );
  }

  void _handleOriginalVideoTap(videoReaction) {
    // Handle tapping on the original video reaction
    _handleVideoThumbnailTap(VideoReactionMessageModel(
      messageId: 'original',
      chatId: widget.chatId,
      senderId: '',
      content: '',
      type: MessageEnum.text,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
      videoReactionData: videoReaction,
      isOriginalReaction: true,
    ));
  }

  PreferredSizeWidget _buildAppBar(ModernThemeExtension modernTheme) {
    final isVerified = _isContactVerified();
    
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: BoxDecoration(
          color: modernTheme.appBarColor?.withOpacity(0.95),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: modernTheme.textColor == Colors.white 
              ? Brightness.light 
              : Brightness.dark,
          ),
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop(_hasMessageBeenSent);
            },
            icon: Icon(
              Icons.arrow_back,
              color: modernTheme.textColor,
            ),
          ),
          title: GestureDetector(
            onTap: () => _showContactProfile(),
            child: Row(
              children: [
                _buildContactAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.contact.name,
                              style: TextStyle(
                                color: modernTheme.textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Video reaction indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: modernTheme.primaryColor?.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.video_library,
                                  size: 10,
                                  color: modernTheme.primaryColor,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Video',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    color: modernTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isVerified ? Icons.verified : Icons.help_outline,
                            size: 12,
                            color: isVerified ? Colors.blue : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isVerified ? 'Verified' : 'Not Verified',
                            style: TextStyle(
                              color: isVerified ? Colors.blue : Colors.grey[600],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => _showSearchDialog(),
              icon: Icon(
                Icons.search,
                color: modernTheme.textColor,
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: modernTheme.textColor,
              ),
              color: modernTheme.surfaceColor,
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'pinned_messages',
                  child: Row(
                    children: [
                      Icon(Icons.push_pin, color: modernTheme.textColor, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Pinned Messages',
                        style: TextStyle(color: modernTheme.textColor),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'wallpaper',
                  child: Row(
                    children: [
                      Icon(Icons.wallpaper, color: modernTheme.textColor, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Wallpaper',
                        style: TextStyle(color: modernTheme.textColor),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'font_size',
                  child: Row(
                    children: [
                      Icon(Icons.text_fields, color: modernTheme.textColor, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Font Size',
                        style: TextStyle(color: modernTheme.textColor),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear_cache',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, color: modernTheme.textColor, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Clear Cache',
                        style: TextStyle(color: modernTheme.textColor),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      const Icon(Icons.block, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      const Text(
                        'Block Contact',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ModernThemeExtension modernTheme) {
    return Center(
      child: CircularProgressIndicator(
        color: modernTheme.primaryColor,
      ),
    );
  }

  Widget _buildErrorState(ModernThemeExtension modernTheme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: modernTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load messages',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(VideoReactionMessagesState state, UserModel currentUser) {
    if (state.messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.only(
        top: 16,
        bottom: 16,
      ),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        final isCurrentUser = message.senderId == currentUser.uid;
        final isLastInGroup = _isLastInGroup(state.messages, index);
        
        // Use VideoReactionSwipeToWrapper for all messages
        return VideoReactionSwipeToWrapper(
          message: message,
          isCurrentUser: isCurrentUser,
          isLastInGroup: isLastInGroup,
          fontSize: _fontSize,
          contactName: widget.contact.name,
          onLongPress: () => _showMessageOptions(message, isCurrentUser),
          onVideoTap: () => _handleVideoThumbnailTap(message),
          onRightSwipe: () => _replyToMessage(message),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final modernTheme = context.modernTheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildContactAvatar(radius: 40),
          const SizedBox(height: 16),
          Text(
            'Video reaction chat with ${widget.contact.name}',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Continue your conversation about the video',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  bool _isLastInGroup(List<VideoReactionMessageModel> messages, int index) {
    if (index == 0) return true;
    
    final currentMessage = messages[index];
    final nextMessage = messages[index - 1];
    
    return currentMessage.senderId != nextMessage.senderId ||
           nextMessage.timestamp.difference(currentMessage.timestamp).inMinutes > 5;
  }

  void _handleSendText(String text) {
    final messageNotifier = ref.read(videoReactionMessagesProvider(widget.chatId).notifier);
    messageNotifier.sendTextMessage(widget.chatId, text);
    _hasMessageBeenSent = true;
  }

  void _cancelReply() {
    final messageNotifier = ref.read(videoReactionMessagesProvider(widget.chatId).notifier);
    messageNotifier.cancelReply();
  }

  void _replyToMessage(VideoReactionMessageModel message) {
    final messageNotifier = ref.read(videoReactionMessagesProvider(widget.chatId).notifier);
    messageNotifier.setReplyToMessage(message);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _showMessageOptions(VideoReactionMessageModel message, bool isCurrentUser) {
    final modernTheme = context.modernTheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: modernTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: modernTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              _MessageActionTile(
                icon: Icons.reply,
                title: 'Reply',
                onTap: () {
                  Navigator.pop(context);
                  _replyToMessage(message);
                },
              ),
              
              if (isCurrentUser && message.type == MessageEnum.text) ...[
                _MessageActionTile(
                  icon: Icons.edit,
                  title: 'Edit',
                  onTap: () {
                    Navigator.pop(context);
                    _editMessage(message);
                  },
                ),
              ],
              
              _MessageActionTile(
                icon: message.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                title: message.isPinned ? 'Unpin' : 'Pin',
                onTap: () {
                  Navigator.pop(context);
                  _togglePinMessage(message);
                },
              ),
              
              if (message.type == MessageEnum.text || 
                  message.isOriginalReaction) ...[
                _MessageActionTile(
                  icon: Icons.copy,
                  title: 'Copy',
                  onTap: () {
                    Navigator.pop(context);
                    _copyMessage(message);
                  },
                ),
              ],
              
              if (isCurrentUser) ...[
                _MessageActionTile(
                  icon: Icons.delete_outline,
                  title: 'Delete for me',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(message, false);
                  },
                ),
                _MessageActionTile(
                  icon: Icons.delete,
                  title: 'Delete for everyone',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteForEveryone(message);
                  },
                ),
              ] else ...[
                _MessageActionTile(
                  icon: Icons.delete_outline,
                  title: 'Delete for me',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(message, false);
                  },
                ),
              ],
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _editMessage(VideoReactionMessageModel message) {
    showDialog(
      context: context,
      builder: (context) => _EditMessageDialog(
        message: message,
        onEdit: (newContent) => _handleEditMessage(message, newContent),
      ),
    );
  }

  void _handleEditMessage(VideoReactionMessageModel message, String newContent) {
    final messageNotifier = ref.read(videoReactionMessagesProvider(widget.chatId).notifier);
    messageNotifier.editMessage(widget.chatId, message.messageId, newContent);
  }

  void _togglePinMessage(VideoReactionMessageModel message) {
    final messageNotifier = ref.read(videoReactionMessagesProvider(widget.chatId).notifier);
    messageNotifier.togglePinMessage(widget.chatId, message.messageId, message.isPinned);
  }

  void _copyMessage(VideoReactionMessageModel message) {
    String textToCopy = message.content;
    
    // For video reaction messages, copy the reaction text
    if (message.isOriginalReaction && message.videoReactionData != null) {
      final reaction = message.videoReactionData!.reaction ?? '';
      final userName = message.videoReactionData!.userName;
      textToCopy = reaction.isNotEmpty ? reaction : 'Reacted to $userName\'s video';
    }
    
    Clipboard.setData(ClipboardData(text: textToCopy));
    showSnackBar(context, 'Message copied to clipboard');
  }

  void _deleteMessage(VideoReactionMessageModel message, bool deleteForEveryone) {
    final messageNotifier = ref.read(videoReactionMessagesProvider(widget.chatId).notifier);
    messageNotifier.deleteMessage(widget.chatId, message.messageId, deleteForEveryone);
  }

  void _confirmDeleteForEveryone(VideoReactionMessageModel message) {
    final modernTheme = context.modernTheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: modernTheme.surfaceColor,
        title: Text(
          'Delete for everyone?',
          style: TextStyle(color: modernTheme.textColor),
        ),
        content: Text(
          'This message will be deleted for everyone in this chat.',
          style: TextStyle(color: modernTheme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: modernTheme.textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(message, true);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactProfile() {
    showSnackBar(context, 'Contact profile - Coming soon');
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => _SearchMessagesDialog(
        chatId: widget.chatId,
        onMessageSelected: (message) {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'pinned_messages':
        _showPinnedMessages();
        break;
      case 'wallpaper':
        _showWallpaperOptions();
        break;
      case 'font_size':
        _showFontSizeDialog();
        break;
      case 'clear_cache':
        _clearChatCache();
        break;
      case 'block':
        _confirmBlockContact();
        break;
    }
  }

  void _showPinnedMessages() {
    final messageState = ref.read(videoReactionMessagesProvider(widget.chatId)).valueOrNull;
    final pinnedMessages = messageState?.pinnedMessages ?? [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.modernTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => _PinnedMessagesSheet(
          messages: pinnedMessages,
          scrollController: scrollController,
          onUnpin: (message) => _togglePinMessage(message),
        ),
      ),
    );
  }

  void _showWallpaperOptions() {
    showSnackBar(context, 'Wallpaper selection - Coming soon');
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => _FontSizeDialog(
        currentSize: _fontSize,
        onSizeChanged: (size) {
          setState(() {
            _fontSize = size;
          });
        },
      ),
    );
  }

  void _confirmBlockContact() {
    final modernTheme = context.modernTheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: modernTheme.surfaceColor,
        title: Text(
          'Block ${widget.contact.name}?',
          style: TextStyle(color: modernTheme.textColor),
        ),
        content: Text(
          'Blocked contacts will not be able to send you messages.',
          style: TextStyle(color: modernTheme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: modernTheme.textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _blockContact();
            },
            child: const Text(
              'Block',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _blockContact() {
    showSnackBar(context, 'Contact blocked');
    Navigator.pop(context);
  }
}

// Supporting widgets with RFC 3339 time formatting
class _MessageActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final VoidCallback onTap;

  const _MessageActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final effectiveColor = color ?? modernTheme.textColor;
    
    return ListTile(
      leading: Icon(icon, color: effectiveColor, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: effectiveColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _EditMessageDialog extends StatefulWidget {
  final VideoReactionMessageModel message;
  final Function(String) onEdit;

  const _EditMessageDialog({
    required this.message,
    required this.onEdit,
  });

  @override
  State<_EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<_EditMessageDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.message.content);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return AlertDialog(
      backgroundColor: modernTheme.surfaceColor,
      title: Text(
        'Edit Message',
        style: TextStyle(color: modernTheme.textColor),
      ),
      content: TextField(
        controller: _controller,
        maxLines: 5,
        minLines: 1,
        autofocus: true,
        style: TextStyle(color: modernTheme.textColor),
        decoration: InputDecoration(
          hintText: 'Enter your message...',
          hintStyle: TextStyle(color: modernTheme.textSecondaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: modernTheme.dividerColor!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: modernTheme.primaryColor!),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: modernTheme.textSecondaryColor),
          ),
        ),
        TextButton(
          onPressed: () {
            final newContent = _controller.text.trim();
            if (newContent.isNotEmpty && newContent != widget.message.content) {
              widget.onEdit(newContent);
            }
            Navigator.pop(context);
          },
          child: Text(
            'Save',
            style: TextStyle(color: modernTheme.primaryColor),
          ),
        ),
      ],
    );
  }
}

class _SearchMessagesDialog extends ConsumerStatefulWidget {
  final String chatId;
  final Function(VideoReactionMessageModel) onMessageSelected;

  const _SearchMessagesDialog({
    required this.chatId,
    required this.onMessageSelected,
  });

  @override
  ConsumerState<_SearchMessagesDialog> createState() => _SearchMessagesDialogState();
}

class _SearchMessagesDialogState extends ConsumerState<_SearchMessagesDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<VideoReactionMessageModel> _searchResults = [];
  bool _isSearching = false;

  // RFC 3339 date formatter for search results
  static final DateFormat _searchDateFormat = DateFormat('MMM dd, yyyy HH:mm');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final messageNotifier = ref.read(videoReactionMessagesProvider(widget.chatId).notifier);
      final results = await messageNotifier.searchMessages(widget.chatId, query);
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Dialog(
      backgroundColor: modernTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Search Messages',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(color: modernTheme.textColor),
              decoration: InputDecoration(
                hintText: 'Search in chat...',
                hintStyle: TextStyle(color: modernTheme.textSecondaryColor),
                prefixIcon: Icon(Icons.search, color: modernTheme.textSecondaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: modernTheme.dividerColor!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: modernTheme.primaryColor!),
                ),
              ),
              onChanged: _performSearch,
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: _isSearching
                  ? Center(
                      child: CircularProgressIndicator(
                        color: modernTheme.primaryColor,
                      ),
                    )
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'Enter text to search'
                                : 'No messages found',
                            style: TextStyle(
                              color: modernTheme.textSecondaryColor,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final message = _searchResults[index];
                            return ListTile(
                              title: Text(
                                message.getDisplayContent(),
                                style: TextStyle(color: modernTheme.textColor),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                _searchDateFormat.format(message.timestamp),
                                style: TextStyle(color: modernTheme.textSecondaryColor),
                              ),
                              onTap: () => widget.onMessageSelected(message),
                            );
                          },
                        ),
            ),
            
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: TextStyle(color: modernTheme.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinnedMessagesSheet extends StatelessWidget {
  final List<VideoReactionMessageModel> messages;
  final ScrollController scrollController;
  final Function(VideoReactionMessageModel) onUnpin;

  const _PinnedMessagesSheet({
    required this.messages,
    required this.scrollController,
    required this.onUnpin,
  });

  // RFC 3339 date formatter for pinned messages
  static final DateFormat _pinnedDateFormat = DateFormat('MMM dd, HH:mm');

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Container(
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: modernTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Pinned Messages',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'No pinned messages',
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return ListTile(
                        title: Text(
                          message.getDisplayContent(),
                          style: TextStyle(color: modernTheme.textColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          _pinnedDateFormat.format(message.timestamp),
                          style: TextStyle(color: modernTheme.textSecondaryColor),
                        ),
                        trailing: IconButton(
                          onPressed: () => onUnpin(message),
                          icon: Icon(
                            Icons.push_pin_outlined,
                            color: modernTheme.textSecondaryColor,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FontSizeDialog extends StatefulWidget {
  final double currentSize;
  final Function(double) onSizeChanged;

  const _FontSizeDialog({
    required this.currentSize,
    required this.onSizeChanged,
  });

  @override
  State<_FontSizeDialog> createState() => _FontSizeDialogState();
}

class _FontSizeDialogState extends State<_FontSizeDialog> {
  late double _fontSize;

  @override
  void initState() {
    super.initState();
    _fontSize = widget.currentSize;
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return AlertDialog(
      backgroundColor: modernTheme.surfaceColor,
      title: Text(
        'Font Size',
        style: TextStyle(color: modernTheme.textColor),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sample message text',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: _fontSize,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Small',
                style: TextStyle(color: modernTheme.textSecondaryColor),
              ),
              Expanded(
                child: Slider(
                  value: _fontSize,
                  min: 12.0,
                  max: 24.0,
                  divisions: 12,
                  activeColor: modernTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _fontSize = value;
                    });
                  },
                ),
              ),
              Text(
                'Large',
                style: TextStyle(color: modernTheme.textSecondaryColor),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: modernTheme.textSecondaryColor),
          ),
        ),
        TextButton(
          onPressed: () {
            widget.onSizeChanged(_fontSize);
            Navigator.pop(context);
          },
          child: Text(
            'Apply',
            style: TextStyle(color: modernTheme.primaryColor),
          ),
        ),
      ],
    );
  }
}

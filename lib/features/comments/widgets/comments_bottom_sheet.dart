// lib/features/comments/widgets/comments_bottom_sheet.dart
// UPDATED: Enhanced comment system with media support, nested replies, pinning, and sorting
// 🔧 FIXED: Changed imageUrls to imageFiles parameter to match provider method signature
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/features/threads/models/comment_model.dart'; // ✅ Using thread comment model
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/authentication/widgets/login_required_widget.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Comment sort options
enum CommentSortOption {
  top,
  latest,
  oldest,
}

class ExpandableCommentText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final int maxLines;
  final bool isMainComment;

  const ExpandableCommentText({
    super.key,
    required this.text,
    required this.style,
    this.maxLines = 3,
    this.isMainComment = true,
  });

  @override
  State<ExpandableCommentText> createState() => _ExpandableCommentTextState();
}

class _ExpandableCommentTextState extends State<ExpandableCommentText>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _needsExpansion = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfNeedsExpansion();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _checkIfNeedsExpansion() {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: widget.maxLines,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 120);
    
    if (textPainter.didExceedMaxLines) {
      setState(() {
        _needsExpansion = true;
      });
    }
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    
    HapticFeedback.lightImpact();
  }

  String _getTruncatedText() {
    if (!_needsExpansion || _isExpanded) return widget.text;
    
    final words = widget.text.split(' ');
    if (words.length <= 20) return widget.text;
    
    final targetLength = widget.isMainComment ? 120 : 100;
    int currentLength = 0;
    int wordIndex = 0;
    
    for (int i = 0; i < words.length; i++) {
      currentLength += words[i].length + 1;
      if (currentLength > targetLength) {
        wordIndex = i;
        break;
      }
    }
    
    if (wordIndex == 0) wordIndex = words.length ~/ 2;
    
    return '${words.take(wordIndex).join(' ')}...';
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _getTruncatedText();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          firstChild: Text(
            displayText,
            style: widget.style,
          ),
          secondChild: Text(
            widget.text,
            style: widget.style,
          ),
          crossFadeState: _isExpanded 
              ? CrossFadeState.showSecond 
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
        
        if (_needsExpansion) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _toggleExpansion,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: Text(
                _isExpanded ? 'Show less' : 'Read more',
                style: const TextStyle(
                  color: Color(0xFF007AFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class CommentsBottomSheet extends ConsumerStatefulWidget {
  final VideoModel video;
  final VoidCallback? onClose;

  const CommentsBottomSheet({
    super.key,
    required this.video,
    this.onClose,
  });

  @override
  ConsumerState<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet>
    with TickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  String? _replyingToCommentId;
  String? _replyingToAuthorName;
  bool _isExpanded = false;
  List<CommentModel> _comments = [];
  bool _isLoadingComments = false;
  CommentSortOption _sortOption = CommentSortOption.top;
  
  // 🆕 Media state
  List<File> _selectedImages = [];
  bool _isUploadingMedia = false;

  // Custom theme-independent colors
  static const Color _pureWhite = Color(0xFFFFFFFF);
  static const Color _pureBlack = Color(0xFF000000);
  static const Color _darkGray = Color(0xFF3C3C43);
  static const Color _mediumGray = Color(0xFF8E8E93);
  static const Color _lightGray = Color(0xFFF2F2F7);
  static const Color _borderGray = Color(0xFFE5E5E7);
  static const Color _iosBlue = Color(0xFF007AFF);
  static const Color _iosRed = Color(0xFFFF3B30);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupKeyboardListener();
    _setupTextControllerListener();
    _loadComments();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
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

    _slideController.forward();
  }

  void _setupKeyboardListener() {
    _commentFocusNode.addListener(() {
      if (_commentFocusNode.hasFocus) {
        _expandSheet();
      }
    });
  }

  void _setupTextControllerListener() {
    _commentController.addListener(() {
      setState(() {});
    });
  }

  void _expandSheet() {
    if (!_isExpanded) {
      setState(() {
        _isExpanded = true;
      });
    }
  }

  void _loadComments() async {
    setState(() {
      _isLoadingComments = true;
    });

    try {
      final authProvider = ref.read(authenticationProvider.notifier);
      final comments = await authProvider.getVideoComments(widget.video.id);
      
      if (mounted) {
        setState(() {
          _comments = _sortComments(comments);
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingComments = false;
        });
        showSnackBar(context, 'Failed to load comments: $e');
      }
    }
  }

  List<CommentModel> _sortComments(List<CommentModel> comments) {
    switch (_sortOption) {
      case CommentSortOption.top:
        return comments.sortByLikes(descending: true);
      case CommentSortOption.latest:
        return comments.sortByDate(descending: true);
      case CommentSortOption.oldest:
        return comments.sortByDate(descending: false);
    }
  }

  void _changeSortOption(CommentSortOption option) {
    setState(() {
      _sortOption = option;
      _comments = _sortComments(_comments);
    });
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _closeSheet() async {
    await _slideController.reverse();
    
    if (mounted) {
      widget.onClose?.call();
      Navigator.of(context).pop();
    }
  }

  // 🆕 Image picker methods
  Future<void> _pickImages() async {
    if (_selectedImages.length >= 2) {
      showSnackBar(context, 'Maximum 2 images allowed per comment');
      return;
    }

    try {
      final images = await _picker.pickMultiImage(
        maxWidth: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        final remainingSlots = 2 - _selectedImages.length;
        final imagesToAdd = images.take(remainingSlots).map((xFile) => File(xFile.path)).toList();
        
        setState(() {
          _selectedImages.addAll(imagesToAdd);
        });
        
        if (images.length > remainingSlots) {
          showSnackBar(context, 'Only ${remainingSlots} image(s) added (max 2 total)');
        }
      }
    } catch (e) {
      showSnackBar(context, 'Failed to pick images');
    }
  }

  Future<void> _pickCamera() async {
    if (_selectedImages.length >= 2) {
      showSnackBar(context, 'Maximum 2 images allowed per comment');
      return;
    }

    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      showSnackBar(context, 'Failed to take photo');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    HapticFeedback.lightImpact();
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: _iosBlue),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: _iosBlue),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(context);
                _pickCamera();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(String timestampString) {
    try {
      final dateTime = DateTime.parse(timestampString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 7) {
        return '${(difference.inDays / 7).floor()}w ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatVideoTime(String timestampString) {
    try {
      final dateTime = DateTime.parse(timestampString);
      return timeago.format(dateTime);
    } catch (e) {
      return 'Unknown time';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = _isExpanded ? screenHeight * 0.9 : screenHeight * 0.6;
    
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _closeSheet();
        }
      },
      child: Theme(
        data: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.transparent,
          colorScheme: const ColorScheme.light(
            surface: _pureWhite,
            onSurface: _pureBlack,
            primary: _iosBlue,
            onPrimary: _pureWhite,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeSheet,
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ),
              
              SlideTransition(
                position: _slideAnimation,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: sheetHeight + bottomInset + systemBottomPadding,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: _pureWhite,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSheetHeader(),
                        _buildVideoInfo(),
                        Expanded(child: _buildCommentsList()),
                        _buildCommentInput(bottomInset, systemBottomPadding),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: _pureWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _borderGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Comments',
                    style: TextStyle(
                      color: _pureBlack,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Sort dropdown
                PopupMenuButton<CommentSortOption>(
                  icon: const Icon(Icons.sort, color: _mediumGray, size: 20),
                  onSelected: _changeSortOption,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: CommentSortOption.top,
                      child: Row(
                        children: [
                          Icon(Icons.trending_up, size: 18),
                          SizedBox(width: 8),
                          Text('Top'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: CommentSortOption.latest,
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 18),
                          SizedBox(width: 8),
                          Text('Latest'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: CommentSortOption.oldest,
                      child: Row(
                        children: [
                          Icon(Icons.history, size: 18),
                          SizedBox(width: 8),
                          Text('Oldest'),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 8),
                
                GestureDetector(
                  onTap: _closeSheet,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: _lightGray,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: _mediumGray,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: _pureWhite,
        border: Border(
          bottom: BorderSide(
            color: _borderGray,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: widget.video.userImage.isNotEmpty
                ? NetworkImage(widget.video.userImage)
                : null,
            backgroundColor: _lightGray,
            child: widget.video.userImage.isEmpty
                ? Text(
                    widget.video.userName.isNotEmpty 
                        ? widget.video.userName[0].toUpperCase()
                        : "U",
                    style: const TextStyle(
                      color: _mediumGray,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.video.userName,
                  style: const TextStyle(
                    color: _pureBlack,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatVideoTime(widget.video.createdAt),
                  style: const TextStyle(
                    color: _mediumGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    if (_isLoadingComments) {
      return const Center(
        child: CircularProgressIndicator(
          color: _iosBlue,
        ),
      );
    }

    if (_comments.isEmpty) {
      return _buildEmptyCommentsState();
    }

    final groupedComments = _groupCommentsByReplies(_comments);

    return Container(
      color: _pureWhite,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: groupedComments.length,
        itemBuilder: (context, index) {
          final commentGroup = groupedComments[index];
          return _buildCommentGroup(commentGroup);
        },
      ),
    );
  }

  List<CommentGroup> _groupCommentsByReplies(List<CommentModel> comments) {
    final Map<String, CommentGroup> groups = {};
    final List<CommentGroup> result = [];

    for (final comment in comments) {
      if (!comment.isReply) {
        final group = CommentGroup(mainComment: comment, replies: []);
        groups[comment.id] = group;
        result.add(group);
      }
    }

    for (final comment in comments) {
      if (comment.isReply && comment.parentCommentId != null) {
        final group = groups[comment.parentCommentId!];
        if (group != null) {
          group.replies.add(comment);
        }
      }
    }

    for (final group in result) {
      group.replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return result;
  }

  Widget _buildCommentGroup(CommentGroup group) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: _buildCommentThread(group),
    );
  }

  Widget _buildCommentThread(CommentGroup group) {
    return Column(
      children: [
        _buildEnhancedCommentItem(group.mainComment),
        if (group.replies.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Column(
              children: group.replies.take(2).map((reply) => 
                _buildEnhancedCommentItem(reply, isReply: true)
              ).toList(),
            ),
          ),
          
          if (group.replies.length > 2) ...[
            _buildViewMoreReplies(group),
          ],
        ],
      ],
    );
  }

  Widget _buildViewMoreReplies(CommentGroup group) {
    return Container(
      padding: const EdgeInsets.only(left: 64, right: 16, top: 8, bottom: 8),
      child: GestureDetector(
        onTap: () => _showAllReplies(group),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 1,
              color: _borderGray,
            ),
            const SizedBox(width: 8),
            Text(
              'View ${group.replies.length - 2} more replies',
              style: const TextStyle(
                color: _iosBlue,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: _iosBlue,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showAllReplies(CommentGroup group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFullRepliesSheet(group),
    );
  }

  Widget _buildFullRepliesSheet(CommentGroup group) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: _pureWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: _pureWhite,
              border: Border(
                bottom: BorderSide(color: _borderGray),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Replies to ${group.mainComment.userName}',
                    style: const TextStyle(
                      color: _pureBlack,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    color: _mediumGray,
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: _lightGray,
              border: Border(
                bottom: BorderSide(color: _borderGray),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: group.mainComment.userImage.isNotEmpty
                      ? NetworkImage(group.mainComment.userImage)
                      : null,
                  backgroundColor: _borderGray,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.mainComment.userName,
                        style: const TextStyle(
                          color: _pureBlack,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        group.mainComment.content,
                        style: const TextStyle(
                          color: _darkGray,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Container(
              color: _pureWhite,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: group.replies.length,
                itemBuilder: (context, index) {
                  return _buildEnhancedCommentItem(group.replies[index], isReply: true);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedCommentItem(CommentModel comment, {bool isReply = false}) {
    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    
    final isLiked = currentUserId != null && comment.likes > 0; // Simplified like check
    final isOwn = currentUserId != null && comment.userId == currentUserId;
    final isVideoCreator = currentUserId != null && widget.video.userId == currentUserId;
    final canPin = isVideoCreator && !isReply; // Only video creator can pin top-level comments

    return Container(
      padding: EdgeInsets.only(
        left: isReply ? 32 : 16,
        right: 16,
        top: 12,
        bottom: isReply ? 8 : 12,
      ),
      color: _pureWhite,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 14 : 16,
            backgroundImage: comment.userImage.isNotEmpty
                ? NetworkImage(comment.userImage)
                : null,
            backgroundColor: _lightGray,
            child: comment.userImage.isEmpty
                ? Text(
                    comment.userName.isNotEmpty 
                        ? comment.userName[0].toUpperCase()
                        : "U",
                    style: TextStyle(
                      color: _mediumGray,
                      fontSize: isReply ? 10 : 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(isReply ? 10 : 12),
                  decoration: BoxDecoration(
                    color: isReply ? _lightGray : const Color(0xFFEBEBF0),
                    borderRadius: BorderRadius.circular(isReply ? 14 : 16),
                    border: comment.isReply && comment.replyToUserName != null 
                        ? Border.all(
                            color: _iosBlue.withOpacity(0.3),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              comment.userName,
                              style: TextStyle(
                                color: _pureBlack,
                                fontSize: isReply ? 13 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          
                          // 🆕 Pin indicator
                          if (comment.isPinned) ...[
                            const Icon(
                              Icons.push_pin,
                              color: _iosBlue,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                          ],
                        ],
                      ),
                      
                      if (comment.isReply && comment.replyToUserName != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.reply,
                              color: _iosBlue,
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Replying to ${comment.replyToUserName}',
                              style: const TextStyle(
                                color: _iosBlue,
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 4),
                      
                      ExpandableCommentText(
                        text: comment.content,
                        style: TextStyle(
                          color: _pureBlack,
                          fontSize: isReply ? 13 : 14,
                          height: 1.3,
                        ),
                        maxLines: isReply ? 2 : 3,
                        isMainComment: !isReply,
                      ),
                      
                      // 🆕 Display comment images
                      if (comment.imageUrls.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildCommentImages(comment.imageUrls),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Text(
                      _formatTimeAgo(comment.createdAt),
                      style: const TextStyle(
                        color: _mediumGray,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    GestureDetector(
                      onTap: () => _likeComment(comment),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: isLiked ? _iosRed.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                key: ValueKey(isLiked),
                                color: isLiked ? _iosRed : _mediumGray,
                                size: 14,
                              ),
                            ),
                            if (comment.likes > 0) ...[
                              const SizedBox(width: 4),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  comment.likes.toString(),
                                  key: ValueKey(comment.likes),
                                  style: TextStyle(
                                    color: isLiked ? _iosRed : _mediumGray,
                                    fontSize: 11,
                                    fontWeight: isLiked ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    if (!isReply) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => _replyToComment(comment),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Reply',
                            style: TextStyle(
                              color: _iosBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                    
                    // 🆕 Pin/Unpin button (video creator only)
                    if (canPin) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => _togglePinComment(comment),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                comment.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                color: comment.isPinned ? _iosBlue : _mediumGray,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                comment.isPinned ? 'Unpin' : 'Pin',
                                style: TextStyle(
                                  color: comment.isPinned ? _iosBlue : _mediumGray,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    if (isOwn) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => _deleteComment(comment),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              color: _iosRed,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
    );
  }

  // 🆕 Build comment images widget
  Widget _buildCommentImages(List<String> imageUrls) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();
    
    if (imageUrls.length == 1) {
      return GestureDetector(
        onTap: () => _showFullscreenImage(imageUrls, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 200,
            ),
            child: CachedNetworkImage(
              imageUrl: imageUrls[0],
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (context, url) => Container(
                height: 200,
                color: _lightGray,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: _iosBlue,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                color: _lightGray,
                child: const Center(
                  child: Icon(Icons.error, color: _mediumGray),
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    // Two images side by side
    return Row(
      children: imageUrls.asMap().entries.map((entry) {
        final index = entry.key;
        final url = entry.value;
        
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 0 ? 4 : 0, left: index == 1 ? 4 : 0),
            child: GestureDetector(
              onTap: () => _showFullscreenImage(imageUrls, index),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  height: 150,
                  placeholder: (context, url) => Container(
                    height: 150,
                    color: _lightGray,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: _iosBlue,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 150,
                    color: _lightGray,
                    child: const Center(
                      child: Icon(Icons.error, color: _mediumGray),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 🆕 Show fullscreen image viewer
  void _showFullscreenImage(List<String> imageUrls, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: imageUrls.length,
              controller: PageController(initialPage: initialIndex),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: imageUrls[index],
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCommentsState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: Color(0xFFAEAEB2),
          ),
          SizedBox(height: 16),
          Text(
            'No comments yet',
            style: TextStyle(
              color: _pureBlack,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Be the first to comment!',
            style: TextStyle(
              color: _darkGray,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(double bottomInset, double systemBottomPadding) {
    final currentUser = ref.watch(currentUserProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final hasContent = _commentController.text.trim().isNotEmpty || _selectedImages.isNotEmpty;
    
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + bottomInset + systemBottomPadding,
      ),
      decoration: const BoxDecoration(
        color: _pureWhite,
        border: Border(
          top: BorderSide(
            color: _borderGray,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_replyingToCommentId != null) _buildReplyingIndicator(),
          
          // 🆕 Image preview
          if (_selectedImages.isNotEmpty) _buildImagePreview(),
          
          if (!isAuthenticated) ...[
            _buildGuestCommentPrompt(),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _lightGray,
                  child: currentUser?.profileImage.isNotEmpty == true
                      ? ClipOval(
                          child: Image.network(
                            currentUser!.profileImage,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                color: _mediumGray,
                                size: 18,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: _mediumGray,
                          size: 18,
                        ),
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 100),
                    decoration: BoxDecoration(
                      color: _lightGray,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _commentFocusNode.hasFocus 
                            ? _iosBlue.withOpacity(0.5)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _commentController,
                      focusNode: _commentFocusNode,
                      decoration: InputDecoration(
                        hintText: _replyingToCommentId != null 
                            ? 'Reply to $_replyingToAuthorName...'
                            : 'Add a comment...',
                        hintStyle: const TextStyle(
                          color: _mediumGray,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      style: const TextStyle(
                        color: _pureBlack,
                        fontSize: 14,
                      ),
                      maxLines: null,
                      maxLength: 500,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                        return null;
                      },
                      textCapitalization: TextCapitalization.sentences,
                      onTap: _expandSheet,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // 🆕 Media picker button
                GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _selectedImages.isNotEmpty ? _iosBlue.withOpacity(0.1) : _borderGray,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.image,
                      color: _selectedImages.isNotEmpty ? _iosBlue : _mediumGray,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: hasContent ? _sendComment : null,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: hasContent
                            ? _iosBlue
                            : _borderGray,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.send,
                        color: hasContent
                            ? _pureWhite
                            : _mediumGray,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            if (_commentController.text.length > 400) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_commentController.text.length}/500',
                  style: TextStyle(
                    color: _commentController.text.length > 450
                        ? _iosRed
                        : _mediumGray,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // 🆕 Build image preview widget
  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImages[index],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGuestCommentPrompt() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _iosBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _iosBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _iosBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              color: _iosBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  Constants.guestModeCommentPrompt,
                  style: TextStyle(
                    color: _pureBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamed(Constants.landingScreen);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _iosBlue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: _pureWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyingIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _iosBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _iosBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.reply,
            color: _iosBlue,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Replying to $_replyingToAuthorName',
              style: const TextStyle(
                color: _iosBlue,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: _cancelReply,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _iosBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: _iosBlue,
                size: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _likeComment(CommentModel comment) async {
    final currentUserId = ref.read(currentUserIdProvider);
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    
    if (!isAuthenticated || currentUserId == null) {
      await requireLogin(
        context,
        ref,
        customTitle: 'Sign In to Like Comments',
        customSubtitle: Constants.guestModeCommentPrompt,
        showContinueBrowsing: false,
      );
      return;
    }
    
    try {
      final authProvider = ref.read(authenticationProvider.notifier);
      
      // Simple like/unlike (backend handles the logic)
      await authProvider.likeComment(comment.id);
      
      _loadComments();
      
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to update comment like');
      }
    }
  }

  void _replyToComment(CommentModel comment) {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    
    if (!isAuthenticated) {
      requireLogin(
        context,
        ref,
        customTitle: 'Sign In to Reply',
        customSubtitle: Constants.guestModeCommentPrompt,
        showContinueBrowsing: false,
      );
      return;
    }
    
    setState(() {
      _replyingToCommentId = comment.id;
      _replyingToAuthorName = comment.userName;
    });
    _commentFocusNode.requestFocus();
    _expandSheet();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToAuthorName = null;
    });
  }

  // 🆕 Pin/Unpin comment (video creator only)
  void _togglePinComment(CommentModel comment) async {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    
    if (!isAuthenticated) return;
    
    try {
      final authProvider = ref.read(authenticationProvider.notifier);
      
      if (comment.isPinned) {
        await authProvider.unpinComment(comment.id, widget.video.id, (error) {
          if (mounted) {
            showSnackBar(context, error);
          }
        });
      } else {
        await authProvider.pinComment(comment.id, widget.video.id, (error) {
          if (mounted) {
            showSnackBar(context, error);
          }
        });
      }
      
      _loadComments();
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to pin comment');
      }
    }
  }

  void _deleteComment(CommentModel comment) {
    showDialog(
      context: context,
      builder: (context) => Theme(
        data: ThemeData(
          brightness: Brightness.light,
          dialogBackgroundColor: _pureWhite,
        ),
        child: AlertDialog(
          backgroundColor: _pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Comment',
            style: TextStyle(
              color: _pureBlack,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this comment? This action cannot be undone.',
            style: TextStyle(
              color: _darkGray,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: _mediumGray,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                
                try {
                  await ref.read(authenticationProvider.notifier)
                      .deleteComment(comment.id, (error) {
                    if (mounted) {
                      showSnackBar(context, error);
                    }
                  });
                  
                  _loadComments();
                  
                  HapticFeedback.lightImpact();
                  
                  if (mounted) {
                    showSnackBar(context, Constants.commentDeleted);
                  }
                } catch (e) {
                  if (mounted) {
                    showSnackBar(context, 'Failed to delete comment');
                  }
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: _iosRed,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔧 FIXED: Changed to pass imageFiles instead of imageUrls, let the provider handle upload
  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty && _selectedImages.isEmpty) return;

    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      await requireLogin(
        context,
        ref,
        customTitle: 'Sign In to Comment',
        customSubtitle: Constants.guestModeCommentPrompt,
        showContinueBrowsing: false,
      );
      return;
    }

    HapticFeedback.lightImpact();

    try {
      setState(() {
        _isUploadingMedia = true;
      });

      // 🔧 FIXED: Pass imageFiles directly to provider, which will handle the upload
      await ref.read(authenticationProvider.notifier).addComment(
        videoId: widget.video.id,
        content: content,
        imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null, // 🔧 Changed from imageUrls to imageFiles
        repliedToCommentId: _replyingToCommentId,
        repliedToAuthorName: _replyingToAuthorName,
        onSuccess: (message) async {
          setState(() {
            _isUploadingMedia = false;
          });
          
          if (mounted) {
            _commentController.clear();
            _selectedImages.clear();
            _cancelReply();
            
            _loadComments();
            
            Future.delayed(const Duration(milliseconds: 100), () {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
            
            showSnackBar(context, Constants.commentAdded);
          }
        },
        onError: (error) {
          setState(() {
            _isUploadingMedia = false;
          });
          
          if (mounted) {
            showSnackBar(context, error);
          }
        },
      );
    } catch (e) {
      setState(() {
        _isUploadingMedia = false;
      });
      
      if (mounted) {
        showSnackBar(context, 'Failed to send comment: $e');
      }
    }
  }
}

class CommentGroup {
  final CommentModel mainComment;
  final List<CommentModel> replies;

  CommentGroup({
    required this.mainComment,
    required this.replies,
  });
}
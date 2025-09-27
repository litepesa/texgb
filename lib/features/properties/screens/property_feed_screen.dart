// lib/features/properties/screens/property_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/properties/models/property_engagement_models.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:textgb/features/properties/providers/property_providers.dart';
import 'package:textgb/features/properties/models/property_listing_model.dart';
import 'package:textgb/features/properties/widgets/property_info_overlay.dart';
import 'package:textgb/features/properties/widgets/property_actions_sidebar.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class PropertyFeedScreen extends ConsumerStatefulWidget {
  final String? initialPropertyId;
  final PropertyType? filterType;
  final String? filterCity;

  const PropertyFeedScreen({
    super.key,
    this.initialPropertyId,
    this.filterType,
    this.filterCity,
  });

  @override
  ConsumerState<PropertyFeedScreen> createState() => _PropertyFeedScreenState();
}

class _PropertyFeedScreenState extends ConsumerState<PropertyFeedScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  final Map<int, VideoPlayerController?> _videoControllers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Set system UI for immersive video experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _disposeVideoControllers();
    
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    
    super.dispose();
  }

  void _disposeVideoControllers() {
    for (final controller in _videoControllers.values) {
      controller?.dispose();
    }
    _videoControllers.clear();
  }

  VideoPlayerController? _getVideoController(int index, String videoUrl) {
    if (_videoControllers[index] != null) {
      return _videoControllers[index];
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    _videoControllers[index] = controller;

    controller.initialize().then((_) {
      if (mounted && index == _currentIndex) {
        controller.play();
        controller.setLooping(true);
      }
    });

    return controller;
  }

  void _onPageChanged(int index) {
    if (!mounted) return;

    final oldIndex = _currentIndex;
    _currentIndex = index;

    // Pause previous video
    _videoControllers[oldIndex]?.pause();

    // Play current video
    final currentController = _videoControllers[index];
    if (currentController != null && currentController.value.isInitialized) {
      currentController.play();
      
      // Record view
      final propertyFeedState = ref.read(propertyFeedProvider()).value;
      if (propertyFeedState != null && index < propertyFeedState.properties.length) {
        final property = propertyFeedState.properties[index];
        ref.read(propertyEngagementProvider.notifier).recordView(property.id);
      }
    }

    // Load more properties when approaching end
    final propertyFeedState = ref.read(propertyFeedProvider()).value;
    if (propertyFeedState != null && 
        index >= propertyFeedState.properties.length - 3 && 
        propertyFeedState.hasMore &&
        !_isLoading) {
      _loadMoreProperties();
    }
  }

  Future<void> _loadMoreProperties() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      await ref.read(propertyFeedProvider().notifier).loadMore();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load more properties: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshProperties() async {
    try {
      // Dispose existing controllers
      _disposeVideoControllers();
      _currentIndex = 0;
      
      // Refresh data
      await ref.read(propertyFeedProvider().notifier).refresh();
      
      // Reset page controller
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyFeedAsync = ref.watch(propertyFeedProvider(
      city: widget.filterCity,
      propertyType: widget.filterType,
    ));
    final theme = Theme.of(context).extension<ModernThemeExtension>();

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Properties',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Navigate to property search/filter screen
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.search,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: propertyFeedAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
        error: (error, stackTrace) => _buildErrorState(error.toString()),
        data: (propertyFeedState) {
          if (propertyFeedState.properties.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _refreshProperties,
            color: theme?.primaryColor ?? const Color(0xFFFE2C55),
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: _onPageChanged,
              itemCount: propertyFeedState.properties.length + (propertyFeedState.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= propertyFeedState.properties.length) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  );
                }

                final property = propertyFeedState.properties[index];
                return _buildPropertyVideo(property, index);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPropertyVideo(PropertyListingModel property, int index) {
    final videoController = _getVideoController(index, property.videoUrl);

    return Stack(
      children: [
        // Video player
        if (videoController != null)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                if (videoController.value.isPlaying) {
                  videoController.pause();
                } else {
                  videoController.play();
                }
              },
              child: VideoPlayer(videoController),
            ),
          ),

        // Video loading indicator
        if (videoController == null || !videoController.value.isInitialized)
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading ${property.title}...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Property info overlay (bottom left)
        Positioned(
          left: 16,
          right: 80, // Leave space for actions sidebar
          bottom: 100,
          child: PropertyInfoOverlay(property: property),
        ),

        // Actions sidebar (right side)
        Positioned(
          right: 16,
          bottom: 100,
          child: PropertyActionsSidebar(
            property: property,
            onLike: () => _handleLike(property),
            onComment: () => _showComments(property),
            onShare: () => _handleShare(property),
            onContact: () => _handleContact(property),
          ),
        ),

        // Play/pause overlay
        if (videoController != null)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                if (videoController.value.isPlaying) {
                  videoController.pause();
                } else {
                  videoController.play();
                }
              },
              child: AnimatedOpacity(
                opacity: videoController.value.isPlaying ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 80,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load properties',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _refreshProperties,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFE2C55),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.home_outlined,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'No Properties Available',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'There are no property listings at the moment. Check back later!',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _refreshProperties,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFE2C55),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Action handlers
  void _handleLike(PropertyListingModel property) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      _showLoginRequired();
      return;
    }

    ref.read(propertyEngagementProvider.notifier).togglePropertyLike(property);
    
    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  void _showComments(PropertyListingModel property) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PropertyCommentsBottomSheet(property: property),
    );
  }

  void _handleShare(PropertyListingModel property) {
    // TODO: Implement sharing functionality
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleContact(PropertyListingModel property) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      _showLoginRequired();
      return;
    }

    try {
      // Record inquiry
      await ref.read(propertyEngagementProvider.notifier).recordInquiry(property);

      // Launch WhatsApp
      if (property.hasWhatsApp && property.whatsappLinkWithMessage != null) {
        final uri = Uri.parse(property.whatsappLinkWithMessage!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not launch WhatsApp');
        }
      } else {
        throw Exception('Host WhatsApp number not available');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to contact host: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLoginRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please log in to interact with properties'),
        action: SnackBarAction(
          label: 'Login',
          onPressed: null, // TODO: Navigate to login
        ),
      ),
    );
  }
}

// Property Comments Bottom Sheet
class PropertyCommentsBottomSheet extends ConsumerStatefulWidget {
  final PropertyListingModel property;

  const PropertyCommentsBottomSheet({
    super.key,
    required this.property,
  });

  @override
  ConsumerState<PropertyCommentsBottomSheet> createState() => _PropertyCommentsBottomSheetState();
}

class _PropertyCommentsBottomSheetState extends ConsumerState<PropertyCommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  bool _isAddingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(propertyCommentsProvider(widget.property.id));
    final theme = Theme.of(context).extension<ModernThemeExtension>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme?.surfaceColor ?? Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme?.textColor ?? Colors.black,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.property.commentsCount}',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme?.textSecondaryColor ?? Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: theme?.textSecondaryColor ?? Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Comments list
          Expanded(
            child: commentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load comments',
                      style: TextStyle(
                        color: theme?.textSecondaryColor ?? Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              data: (comments) {
                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: theme?.textTertiaryColor ?? Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No comments yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: theme?.textSecondaryColor ?? Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to comment!',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme?.textTertiaryColor ?? Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return _buildCommentItem(comment, theme);
                  },
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Add comment section
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      focusNode: _commentFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(
                          color: theme?.textTertiaryColor ?? Colors.grey[400],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(
                            color: theme?.dividerColor ?? Colors.grey[300]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(
                            color: theme?.primaryColor ?? const Color(0xFFFE2C55),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: theme?.primaryColor ?? const Color(0xFFFE2C55),
                    borderRadius: BorderRadius.circular(25),
                    child: InkWell(
                      onTap: _isAddingComment ? null : _addComment,
                      borderRadius: BorderRadius.circular(25),
                      child: Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        child: _isAddingComment
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(PropertyCommentModel comment, ModernThemeExtension? theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar
          CircleAvatar(
            radius: 20,
            backgroundImage: comment.authorImage.isNotEmpty
                ? NetworkImage(comment.authorImage)
                : null,
            backgroundColor: theme?.primaryColor ?? const Color(0xFFFE2C55),
            child: comment.authorImage.isEmpty
                ? Text(
                    comment.authorName.isNotEmpty
                        ? comment.authorName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author name and time
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme?.textColor ?? Colors.black,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.timeAgo,
                      style: TextStyle(
                        color: theme?.textTertiaryColor ?? Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Comment text
                Text(
                  comment.content,
                  style: TextStyle(
                    color: theme?.textColor ?? Colors.black,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Comment actions
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _likeComment(comment),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            comment.isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: comment.isLiked
                                ? const Color(0xFFFE2C55)
                                : theme?.textTertiaryColor ?? Colors.grey[400],
                          ),
                          if (comment.likesCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              comment.likesCount.toString(),
                              style: TextStyle(
                                color: theme?.textTertiaryColor ?? Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _replyToComment(comment),
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          color: theme?.textTertiaryColor ?? Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to comment')),
      );
      return;
    }

    setState(() => _isAddingComment = true);

    try {
      await ref.read(propertyEngagementProvider.notifier).addComment(
        propertyId: widget.property.id,
        content: content,
      );

      _commentController.clear();
      _commentFocusNode.unfocus();

      // Refresh comments
      ref.invalidate(propertyCommentsProvider(widget.property.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment added!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingComment = false);
      }
    }
  }

  void _likeComment(PropertyCommentModel comment) {
    // TODO: Implement comment like functionality
    HapticFeedback.lightImpact();
  }

  void _replyToComment(PropertyCommentModel comment) {
    _commentController.text = '@${comment.authorName} ';
    _commentFocusNode.requestFocus();
  }
}
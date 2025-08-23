// lib/features/moments/screens/moments_feed_screen.dart - Simplified version
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/providers/moments_provider.dart';
import 'package:textgb/features/moments/widgets/moment_video_item.dart';
import 'package:textgb/features/moments/widgets/moment_comments_bottom_sheet.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/chat/screens/chat_screen.dart';
import 'package:textgb/features/chat/models/moment_reaction_model.dart';
import 'package:textgb/features/chat/widgets/moment_reaction_input.dart';
import 'package:textgb/features/chat/repositories/chat_repository.dart';
import 'package:textgb/features/gifts/widgets/virtual_gifts_bottom_sheet.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/constants.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class MomentsFeedScreen extends ConsumerStatefulWidget {
  final String? startMomentId;

  const MomentsFeedScreen({
    super.key,
    this.startMomentId,
  });

  // Static method to create from route arguments
  static MomentsFeedScreen fromRoute(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    String? startMomentId;
    
    if (args is Map<String, dynamic>) {
      startMomentId = args['startMomentId'] as String?;
    }
    
    return MomentsFeedScreen(
      startMomentId: startMomentId,
    );
  }

  @override
  ConsumerState<MomentsFeedScreen> createState() => MomentsFeedScreenState();
}

class MomentsFeedScreenState extends ConsumerState<MomentsFeedScreen> 
    with TickerProviderStateMixin, WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  
  // Core controllers
  final PageController _pageController = PageController();
  
  // State management
  int _currentIndex = 0;
  bool _isScreenActive = true;
  bool _isAppInForeground = true;
  bool _hasNavigatedToStart = false;
  bool _isCommentsSheetOpen = false;
  bool _hasInitialized = false;
  bool _isNavigatingAway = false;
  bool _isManuallyPaused = false;
  
  // Store original system UI for restoration
  SystemUiOverlayStyle? _originalSystemUiStyle;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupSystemUI();
    _hasInitialized = true;
    WakelockPlus.enable();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_originalSystemUiStyle == null) {
      _storeOriginalSystemUI();
    }
  }

  void _storeOriginalSystemUI() {
    final brightness = Theme.of(context).brightness;
    _originalSystemUiStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    );
  }

  void _setupSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ));
  }

  void _restoreOriginalSystemUI() {
    if (_originalSystemUiStyle != null) {
      SystemChrome.setSystemUIOverlayStyle(_originalSystemUiStyle!);
    } else {
      final brightness = Theme.of(context).brightness;
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInForeground = true;
        if (_isScreenActive && !_isCommentsSheetOpen && !_isNavigatingAway) {
          WakelockPlus.enable();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _isAppInForeground = false;
        WakelockPlus.disable();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  // Lifecycle methods
  void onScreenBecameActive() {
    if (!_hasInitialized) return;
    
    debugPrint('MomentsFeedScreen: Screen became active');
    _isScreenActive = true;
    _isNavigatingAway = false;
    _setupSystemUI();
    
    if (_isAppInForeground && !_isManuallyPaused) {
      WakelockPlus.enable();
    }
  }

  void onScreenBecameInactive() {
    if (!_hasInitialized) return;
    
    debugPrint('MomentsFeedScreen: Screen became inactive');
    _isScreenActive = false;
    _restoreOriginalSystemUI();
    WakelockPlus.disable();
  }

  void _pauseForNavigation() {
    debugPrint('MomentsFeedScreen: Pausing for navigation');
    _isNavigatingAway = true;
  }

  void _resumeFromNavigation() {
    debugPrint('MomentsFeedScreen: Resuming from navigation');
    _isNavigatingAway = false;
    if (_isScreenActive && _isAppInForeground && !_isManuallyPaused) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_isNavigatingAway && _isScreenActive && _isAppInForeground && !_isManuallyPaused) {
          WakelockPlus.enable();
        }
      });
    }
  }

  @override
  void dispose() {
    debugPrint('MomentsFeedScreen: Disposing');
    
    WidgetsBinding.instance.removeObserver(this);
    _restoreOriginalSystemUI();
    _pageController.dispose();
    WakelockPlus.disable();
    
    super.dispose();
  }

  // Enhanced back navigation with proper system UI restoration
  void _handleBackNavigation() {
    // Close comments sheet if open
    if (_isCommentsSheetOpen) {
      Navigator.of(context).pop();
      return;
    }
    
    WakelockPlus.disable();
    _restoreOriginalSystemUI();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _onPageChanged(int index) {
    if (_isCommentsSheetOpen) return;
    
    final momentsAsyncValue = ref.read(momentsFeedStreamProvider);
    if (!momentsAsyncValue.hasValue) return;
    
    final moments = momentsAsyncValue.value!;
    if (index >= moments.length) {
      // Loop back to beginning when reaching the end
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
      return;
    }

    setState(() {
      _currentIndex = index;
      _isManuallyPaused = false; // Reset manual pause state for new video
    });

    // Record view
    final moment = moments[index];
    ref.read(momentsProvider.notifier).recordView(moment.id);
  }

  void _navigateToStartMoment(List<MomentModel> moments) {
    if (_hasNavigatedToStart) return;
    
    // Find start moment index or use 0 (chronologically first)
    int startIndex = 0;
    if (widget.startMomentId != null) {
      final foundIndex = moments.indexWhere((m) => m.id == widget.startMomentId!);
      if (foundIndex != -1) {
        startIndex = foundIndex;
      }
    }
    
    _hasNavigatedToStart = true;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.animateToPage(
          startIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        
        setState(() {
          _currentIndex = startIndex;
        });
        
        final moment = moments[startIndex];
        ref.read(momentsProvider.notifier).recordView(moment.id);
      }
    });
  }

  void _onVideoControllerReady(VideoPlayerController controller) {
    // Handle video controller ready if needed
  }

  void _onManualPlayPause(bool isPlaying) {
    setState(() {
      _isManuallyPaused = !isPlaying;
    });
  }

  // Add this method to control video window mode
  void _setVideoWindowMode(bool isSmallWindow) {
    setState(() {
      _isCommentsSheetOpen = isSmallWindow;
    });
  }

  // Build the small video window
  Widget _buildSmallVideoWindow() {
    final systemTopPadding = MediaQuery.of(context).padding.top;
    final momentsAsyncValue = ref.read(momentsFeedStreamProvider);
    if (!momentsAsyncValue.hasValue) return const SizedBox.shrink();
    
    final moments = momentsAsyncValue.value!;
    if (_currentIndex >= moments.length) return const SizedBox.shrink();
    
    final currentMoment = moments[_currentIndex];
    
    return Positioned(
      top: systemTopPadding + 20,
      right: 20,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
          _setVideoWindowMode(false);
        },
        child: Container(
          width: 120,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Video content
                Positioned.fill(
                  child: MomentVideoItem(
                    moment: currentMoment,
                    momentIndex: _currentIndex,
                    isActive: true,
                    isCommentsOpen: true,
                    onVideoControllerReady: _onVideoControllerReady,
                    onManualPlayPause: _onManualPlayPause,
                  ),
                ),
                
                // Close button overlay
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // NEW: Navigate to moment author chat with moment reaction system
  Future<void> _navigateToMomentAuthorChat(MomentModel? moment) async {
    if (moment == null) {
      debugPrint('No moment available for reaction');
      return;
    }

    final currentUser = ref.read(authenticationProvider).valueOrNull?.userModel;
    if (currentUser == null) {
      debugPrint('User not authenticated');
      return;
    }

    // Check if user is trying to react to their own moment
    if (moment.authorId == currentUser.uid) {
      _showCannotReactToOwnMomentMessage();
      return;
    }

    _pauseForNavigation();

    try {
      // Get moment author's user data
      final authNotifier = ref.read(authenticationProvider.notifier);
      final momentAuthor = await authNotifier.getUserDataById(moment.authorId);
      
      if (momentAuthor == null) {
        debugPrint('Moment author not found');
        _resumeFromNavigation();
        return;
      }

      // Show moment reaction input bottom sheet
      final reaction = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => MomentReactionInput(
          moment: moment,
          onSendReaction: (reaction) => Navigator.pop(context, reaction),
          onCancel: () => Navigator.pop(context),
        ),
      );

      // If reaction was provided, create chat and send reaction
      if (reaction != null && reaction.trim().isNotEmpty && mounted) {
        final chatListNotifier = ref.read(chatListProvider.notifier);
        final chatId = await chatListNotifier.createOrGetChat(currentUser.uid, momentAuthor.uid);
        
        if (chatId != null) {
          // Send moment reaction message
          await _sendMomentReactionMessage(
            chatId: chatId,
            moment: moment,
            reaction: reaction,
            senderId: currentUser.uid,
          );

          // Navigate to chat to show the sent reaction
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatId: chatId,
                contact: momentAuthor,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error creating moment reaction: $e');
      _showSnackBar('Failed to send reaction');
    } finally {
      _resumeFromNavigation();
    }
  }

  // Helper method to send moment reaction message
  Future<void> _sendMomentReactionMessage({
    required String chatId,
    required MomentModel moment,
    required String reaction,
    required String senderId,
  }) async {
    try {
      final chatRepository = ref.read(chatRepositoryProvider);
      
      // Determine media URL and type
      final String mediaUrl = moment.hasVideo 
          ? moment.videoUrl! 
          : (moment.hasImages && moment.imageUrls.isNotEmpty 
              ? moment.imageUrls.first 
              : '');
      
      final String thumbnailUrl = moment.hasImages && moment.imageUrls.isNotEmpty 
          ? moment.imageUrls.first 
          : (moment.videoThumbnail ?? '');
          
      final String mediaType = moment.hasVideo ? 'video' : 'image';
      
      // Create moment reaction data
      final momentReaction = MomentReactionModel(
        momentId: moment.id,
        mediaUrl: mediaUrl,
        thumbnailUrl: thumbnailUrl,
        authorName: moment.authorName,
        authorImage: moment.authorImage,
        content: moment.content,
        reaction: reaction,
        timestamp: DateTime.now(),
        mediaType: mediaType,
      );

      // Send as a moment reaction message
      await chatRepository.sendMomentReactionMessage(
        chatId: chatId,
        senderId: senderId,
        momentReaction: momentReaction,
      );
      
    } catch (e) {
      debugPrint('Error sending moment reaction message: $e');
      rethrow;
    }
  }

  // Helper method to show cannot react to own moment message
  void _showCannotReactToOwnMomentMessage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Cannot React to Your Own Moment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You cannot send reactions to your own moments.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Show virtual gifts bottom sheet for current moment
  Future<void> _showVirtualGiftsForCurrentMoment(MomentModel? moment) async {
    if (moment == null) {
      debugPrint('No moment available for gift');
      return;
    }

    final currentUser = ref.read(authenticationProvider).valueOrNull?.userModel;
    if (currentUser == null) {
      debugPrint('User not authenticated');
      return;
    }

    // Check if user is trying to gift to their own moment
    if (moment.authorId == currentUser.uid) {
      _showCannotGiftToOwnMomentMessage();
      return;
    }

    // Pause video before showing gifts
    _pauseForNavigation();

    try {
      // Get moment author's user data for recipient info
      final authNotifier = ref.read(authenticationProvider.notifier);
      final momentAuthor = await authNotifier.getUserDataById(moment.authorId);
      
      if (momentAuthor == null) {
        debugPrint('Moment author not found');
        _resumeFromNavigation();
        return;
      }

      // Show virtual gifts bottom sheet
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => VirtualGiftsBottomSheet(
          recipientName: momentAuthor.name, // Fixed: use 'name' instead of 'displayName'
          recipientImage: momentAuthor.image, // Fixed: use 'image' instead of 'profilePictureUrl'
          onGiftSelected: (gift) => _handleGiftSent(gift, moment, momentAuthor),
          onClose: () {
            // Resume video when gifts sheet closes
            _resumeFromNavigation();
          },
        ),
      );
    } catch (e) {
      debugPrint('Error showing virtual gifts: $e');
      _showSnackBar('Failed to load gifts');
    } finally {
      // Resume video after interaction
      _resumeFromNavigation();
    }
  }

  // NEW: Handle gift being sent
  void _handleGiftSent(VirtualGift gift, MomentModel moment, dynamic momentAuthor) {
    // TODO: Implement actual gift sending logic here
    // This would typically involve:
    // 1. Deducting coins from user's balance
    // 2. Adding coins to recipient's balance
    // 3. Creating a gift transaction record
    // 4. Possibly sending a notification to the recipient
    
    debugPrint('Gift sent: ${gift.name} (${gift.price} KES) to ${momentAuthor.displayName}');
    
    // Show success message
    _showSnackBar('${gift.emoji} ${gift.name} sent to ${momentAuthor.name}!'); // Fixed: use 'name' instead of 'displayName'
    
    // Optional: Trigger celebration animation on the moment
    // You could add a gift animation overlay similar to the like animation
  }

  // Helper method to show snackbar
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // NEW: Helper method to show cannot gift to own moment message
  void _showCannotGiftToOwnMomentMessage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Cannot Gift to Your Own Moment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You cannot send gifts to your own moments.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    _setupSystemUI();
    
    final systemTopPadding = MediaQuery.of(context).padding.top;
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;

    return WillPopScope(
      onWillPop: () async {
        _handleBackNavigation();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: Stack(
            children: [
              // Main video content
              Positioned(
                top: systemTopPadding,
                left: 0,
                right: 0,
                bottom: systemBottomPadding,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  child: _buildBody(),
                ),
              ),
              
              // Small video window when comments are open
              if (_isCommentsSheetOpen) _buildSmallVideoWindow(),
              
              // Top bar with back button and title
              if (!_isCommentsSheetOpen) _buildTopBar(systemTopPadding),
              
              // TikTok-style right side menu
              if (!_isCommentsSheetOpen) _buildRightSideMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(double systemTopPadding) {
    return Positioned(
      top: systemTopPadding + 16,
      left: 0,
      right: 0,
      child: Row(
        children: [
          // Back button
          Material(
            type: MaterialType.transparency,
            child: IconButton(
              onPressed: _handleBackNavigation,
              icon: const Icon(
                CupertinoIcons.chevron_left,
                color: Colors.white,
                size: 28,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              iconSize: 28,
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
              splashRadius: 24,
              tooltip: 'Back',
            ),
          ),
          
          // Title
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.camera,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.7),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Text(
                  'Moments',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.7),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Search button
          IconButton(
            onPressed: () {
              // TODO: Add search functionality
            },
            icon: const Icon(
              CupertinoIcons.search,
              color: Colors.white,
              size: 28,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            iconSize: 28,
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            splashRadius: 24,
            tooltip: 'Search',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final momentsStream = ref.watch(momentsFeedStreamProvider);

    return momentsStream.when(
      loading: () => _buildLoadingState(),
      error: (error, stackTrace) => _buildErrorState(error.toString()),
      data: (moments) {
        if (moments.isEmpty) {
          return _buildEmptyState();
        }

        // Handle navigation to start moment when data is available
        _navigateToStartMoment(moments);

        return PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: moments.length + 1, // +1 for loop detection
          onPageChanged: _onPageChanged,
          physics: _isCommentsSheetOpen ? const NeverScrollableScrollPhysics() : null,
          itemBuilder: (context, index) {
            // Handle loop back to beginning
            if (index >= moments.length) {
              return const SizedBox.shrink();
            }
            
            final moment = moments[index];
            
            return MomentVideoItem(
              moment: moment,
              momentIndex: index,
              isActive: index == _currentIndex && _isScreenActive && _isAppInForeground && !_isNavigatingAway,
              isCommentsOpen: _isCommentsSheetOpen,
              onVideoControllerReady: _onVideoControllerReady,
              onManualPlayPause: _onManualPlayPause,
              onGiftSent: (gift) => _handleGiftSent(gift, moment, null), // Pass gift callback
            );
          },
        );
      },
    );
  }

  // TikTok-style right side menu
  Widget _buildRightSideMenu() {
    final momentsAsyncValue = ref.watch(momentsFeedStreamProvider);
    if (!momentsAsyncValue.hasValue) return const SizedBox.shrink();
    
    final moments = momentsAsyncValue.value!;
    final currentMoment = moments.isNotEmpty && _currentIndex < moments.length 
        ? moments[_currentIndex] 
        : null;
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      right: 4,
      bottom: systemBottomPadding + 16,
      child: Column(
        children: [
          // Like button
          _buildRightMenuItem(
            child: Icon(
              currentMoment?.likedBy.contains(ref.read(currentUserProvider)?.uid) == true 
                  ? CupertinoIcons.heart
                  : CupertinoIcons.heart,
              color: currentMoment?.likedBy.contains(ref.read(currentUserProvider)?.uid) == true 
                  ? Colors.red 
                  : Colors.white,
              size: 28,
            ),
            label: _formatCount(currentMoment?.likesCount ?? 0),
            onTap: () => _likeCurrentMoment(currentMoment),
          ),
          
          const SizedBox(height: 10),
          
          // Comment button
          _buildRightMenuItem(
            child: const Icon(
              CupertinoIcons.captions_bubble,
              color: Colors.white,
              size: 28,
            ),
            label: _formatCount(currentMoment?.commentsCount ?? 0),
            onTap: () => _showCommentsForCurrentMoment(currentMoment),
          ),
          
          const SizedBox(height: 10),
          
          // Gift button - UPDATED to show virtual gifts
          _buildRightMenuItem(
            child: const Icon(
              CupertinoIcons.gift,
              color: Colors.white,
              size: 28,
            ),
            label: 'Gift',
            onTap: () => _showVirtualGiftsForCurrentMoment(currentMoment),
          ),
          
          const SizedBox(height: 10),
          
          // DM button
          _buildRightMenuItem(
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text(
                  'DM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            label: 'Inbox',
            onTap: () => _navigateToMomentAuthorChat(currentMoment),
          ),
        ],
      ),
    );
  }

  Widget _buildRightMenuItem({
    required Widget child,
    String? label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            child: child,
          ),
          if (label != null) ...[
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'No moments yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share a moment!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, Constants.createMomentScreen),
            icon: const Icon(Icons.add),
            label: const Text('Create Moment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.modernTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(momentsFeedStreamProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _likeCurrentMoment(MomentModel? moment) {
    if (moment == null) return;
    
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final isLiked = moment.likedBy.contains(currentUser.uid);
    ref.read(momentsProvider.notifier).toggleLikeMoment(moment.id, isLiked);
    
    // Trigger haptic feedback for button tap
    if (!isLiked) {
      HapticFeedback.mediumImpact();
    }
  }

  void _showCommentsForCurrentMoment(MomentModel? moment) {
    if (moment == null || _isCommentsSheetOpen) return;
    
    // Set video to small window mode
    _setVideoWindowMode(true);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => MomentCommentsBottomSheet(
        moment: moment,
        onClose: () {
          // Reset video to full screen mode
          _setVideoWindowMode(false);
        },
      ),
    ).whenComplete(() {
      // Ensure video returns to full screen mode
      _setVideoWindowMode(false);
    });
  }

  String _formatCount(int count) {
    if (count == 0) return '0';
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}
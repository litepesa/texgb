// lib/features/moments/screens/moments_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/providers/moments_provider.dart';
import 'package:textgb/features/moments/widgets/moment_actions.dart';
//import 'package:textgb/features/moments/widgets/moment_info.dart';
//import 'package:textgb/features/moments/widgets/image_carousel.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/constants.dart';

class MomentsFeedScreen extends ConsumerStatefulWidget {
  final String? startMomentId;

  const MomentsFeedScreen({
    super.key,
    this.startMomentId,
  });

  @override
  ConsumerState<MomentsFeedScreen> createState() => _MomentsFeedScreenState();
}

class _MomentsFeedScreenState extends ConsumerState<MomentsFeedScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, ChewieController> _chewieControllers = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _disposeVideoControllers();
    super.dispose();
  }

  void _disposeVideoControllers() {
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    for (final controller in _chewieControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    _chewieControllers.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Moments',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            onPressed: () => _navigateToCreateMoment(),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final momentsStream = ref.watch(momentsFeedStreamProvider);

    return momentsStream.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      error: (error, stackTrace) => _buildErrorState(error.toString()),
      data: (moments) {
        if (moments.isEmpty) {
          return _buildEmptyState();
        }

        // Find starting index if startMomentId is provided
        int startIndex = 0;
        if (widget.startMomentId != null) {
          startIndex = moments.indexWhere((m) => m.id == widget.startMomentId!);
          if (startIndex == -1) startIndex = 0;
        }

        return PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: moments.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
            _handlePageChange(moments[index]);
          },
          itemBuilder: (context, index) {
            return _buildMomentPage(moments[index]);
          },
        );
      },
    );
  }

  Widget _buildMomentPage(MomentModel moment) {
    return Stack(
      children: [
        // Background content (video or image)
        Positioned.fill(
          child: _buildMomentContent(moment),
        ),

        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
        ),

        // Content overlay
        Positioned(
          left: 16,
          right: 80,
          bottom: 100,
          child: MomentInfo(moment: moment),
        ),

        // Actions panel
        Positioned(
          right: 8,
          bottom: 100,
          child: MomentActions(
            moment: moment,
            onLike: () => _handleLike(moment),
            onComment: () => _showCommentsSheet(moment),
            onShare: () => _handleShare(moment),
            onMore: () => _showMoreOptions(moment),
          ),
        ),

        // Progress indicator
        if (moment.hasVideo)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 16,
            right: 16,
            child: _buildProgressIndicator(moment),
          ),
      ],
    );
  }

  Widget _buildMomentContent(MomentModel moment) {
    if (moment.hasVideo) {
      return _buildVideoContent(moment);
    } else if (moment.hasImages) {
      return ImageCarousel(imageUrls: moment.imageUrls);
    } else {
      return _buildTextContent(moment);
    }
  }

  Widget _buildVideoContent(MomentModel moment) {
    if (!_videoControllers.containsKey(moment.id)) {
      _initializeVideoController(moment);
    }

    final chewieController = _chewieControllers[moment.id];
    if (chewieController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Chewie(controller: chewieController);
  }

  Widget _buildTextContent(MomentModel moment) {
    return Container(
      color: context.modernTheme.primaryColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            moment.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(MomentModel moment) {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: _getProgressFactor(moment),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  double _getProgressFactor(MomentModel moment) {
    final totalDuration = const Duration(hours: 72);
    final elapsed = DateTime.now().difference(moment.createdAt);
    final remaining = totalDuration - elapsed;
    
    if (remaining.isNegative) return 0.0;
    return remaining.inMilliseconds / totalDuration.inMilliseconds;
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
            onPressed: _navigateToCreateMoment,
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

  void _initializeVideoController(MomentModel moment) {
    if (moment.videoUrl == null) return;

    final videoController = VideoPlayerController.networkUrl(
      Uri.parse(moment.videoUrl!),
    );

    final chewieController = ChewieController(
      videoPlayerController: videoController,
      autoPlay: _currentIndex == 0, // Only autoplay first video
      looping: true,
      showControls: false,
      aspectRatio: 9 / 16,
      placeholder: moment.videoThumbnail != null
          ? Image.network(
              moment.videoThumbnail!,
              fit: BoxFit.cover,
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
    );

    _videoControllers[moment.id] = videoController;
    _chewieControllers[moment.id] = chewieController;

    videoController.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _handlePageChange(MomentModel moment) {
    // Pause all videos
    for (final controller in _videoControllers.values) {
      controller.pause();
    }

    // Play current video if it's a video moment
    if (moment.hasVideo) {
      final controller = _videoControllers[moment.id];
      controller?.play();
    }

    // Record view
    ref.read(momentsProvider.notifier).recordView(moment.id);
  }

  void _handleLike(MomentModel moment) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final isLiked = moment.likedBy.contains(currentUser.uid);
    ref.read(momentsProvider.notifier).toggleLikeMoment(moment.id, isLiked);
  }

  void _handleShare(MomentModel moment) {
    // Implement share functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Moment'),
        content: const Text('Share functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCommentsSheet(MomentModel moment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MomentCommentsSheet(moment: moment),
    );
  }

  void _showMoreOptions(MomentModel moment) {
    final currentUser = ref.read(currentUserProvider);
    final isOwner = currentUser?.uid == moment.authorId;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwner) ...[
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Moment'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteMoment(moment);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                // Implement report functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMoment(MomentModel moment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Moment'),
        content: const Text('Are you sure you want to delete this moment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(momentsProvider.notifier).deleteMoment(moment.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateMoment() {
    Navigator.pushNamed(context, Constants.createMomentScreen);
  }
}

// Placeholder for comments sheet - implement separately
class MomentCommentsSheet extends StatelessWidget {
  final MomentModel moment;

  const MomentCommentsSheet({super.key, required this.moment});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: const Center(
        child: Text('Comments sheet - to be implemented'),
      ),
    );
  }
}
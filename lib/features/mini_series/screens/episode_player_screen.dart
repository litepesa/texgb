// lib/features/mini_series/screens/episode_player_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:textgb/features/mini_series/widgets/video_player_widget.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../providers/mini_series_provider.dart';
import '../widgets/comment_widget.dart';
import '../models/episode_model.dart';
import '../models/comment_model.dart';
import '../../authentication/providers/auth_providers.dart';


class EpisodePlayerScreen extends ConsumerStatefulWidget {
  final String episodeId;
  final String seriesId;
  final bool autoPlay;
  final bool showRelatedEpisodes;

  const EpisodePlayerScreen({
    super.key,
    required this.episodeId,
    required this.seriesId,
    this.autoPlay = true,
    this.showRelatedEpisodes = true,
  });

  @override
  ConsumerState<EpisodePlayerScreen> createState() => _EpisodePlayerScreenState();
}

class _EpisodePlayerScreenState extends ConsumerState<EpisodePlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _overlayAnimationController;
  late AnimationController _commentsAnimationController;
  late Animation<Offset> _commentsSlideAnimation;
  late Animation<double> _overlayFadeAnimation;
  
  bool _showComments = false;
  bool _showControls = true;
  bool _hasIncrementedView = false;
  bool _isFullscreen = false;
  bool _showRelatedEpisodes = false;
  
  final PageController _pageController = PageController();
  int _currentEpisodeIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadEpisodeData();
    _setupAutoHideControls();
  }

  void _setupAnimations() {
    _overlayAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _commentsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    
    _overlayFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _overlayAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _commentsSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _commentsAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _overlayAnimationController.forward();
  }

  void _loadEpisodeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(miniSeriesProvider.notifier).loadEpisode(widget.episodeId);
      ref.read(miniSeriesProvider.notifier).loadEpisodes(widget.seriesId);
      ref.read(miniSeriesProvider.notifier).loadComments(widget.episodeId);
    });
  }

  void _setupAutoHideControls() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() {
          _showControls = false;
        });
        _overlayAnimationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _overlayAnimationController.dispose();
    _commentsAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final currentEpisode = ref.watch(currentEpisodeProvider);
        final episodes = ref.watch(seriesEpisodesProvider);
        final comments = ref.watch(episodeCommentsProvider);
        final currentUser = ref.watch(currentUserProvider);
        
        if (currentEpisode == null) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final isLiked = currentUser != null && currentEpisode.isLikedBy(currentUser.uid);
        final currentIndex = episodes.indexWhere((e) => e.episodeId == currentEpisode.episodeId);
        
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                // Main content
                Column(
                  children: [
                    // Video player section
                    Expanded(
                      flex: _isFullscreen ? 1 : 3,
                      child: _buildVideoPlayerSection(currentEpisode),
                    ),
                    
                    // Bottom content
                    if (!_isFullscreen)
                      Expanded(
                        flex: 2,
                        child: _buildBottomContent(
                          currentEpisode,
                          episodes,
                          comments,
                          currentUser,
                          isLiked,
                        ),
                      ),
                  ],
                ),
                
                // Top overlay controls
                if (_showControls || _showComments)
                  _buildTopOverlay(currentEpisode),
                
                // Comments overlay
                if (_showComments)
                  _buildCommentsOverlay(currentEpisode, comments, currentUser),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoPlayerSection(EpisodeModel episode) {
    return GestureDetector(
      onTap: _toggleControlsVisibility,
      child: Container(
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          children: [
            // Video player
            Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: MiniSeriesVideoPlayer(
                  videoUrl: episode.videoUrl,
                  autoPlay: widget.autoPlay,
                  showControls: _showControls,
                  onVideoEnd: () => _onVideoEnd(episode),
                  //onProgress: _onVideoProgress,
                ),
              ),
            ),
            
            // Video overlay info
            if (_showControls)
              AnimatedBuilder(
                animation: _overlayFadeAnimation,
                child: _buildVideoOverlayInfo(episode),
                builder: (context, child) {
                  return Opacity(
                    opacity: _overlayFadeAnimation.value,
                    child: child,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoOverlayInfo(EpisodeModel episode) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              episode.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Episode ${episode.episodeNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_formatCount(episode.views)} views',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopOverlay(EpisodeModel episode) {
    return AnimatedBuilder(
      animation: _overlayFadeAnimation,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            episode.title,
            style: const TextStyle(color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () => _shareEpisode(episode),
            ),
            IconButton(
              icon: Icon(
                _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                color: Colors.white,
              ),
              onPressed: _toggleFullscreen,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'report',
                  child: ListTile(
                    leading: Icon(Icons.flag),
                    title: Text('Report'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'download',
                  child: ListTile(
                    leading: Icon(Icons.download),
                    title: Text('Download'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'quality',
                  child: ListTile(
                    leading: Icon(Icons.hd),
                    title: Text('Quality'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              onSelected: (value) => _handleMenuAction(value, episode),
            ),
          ],
        ),
      ),
      builder: (context, child) {
        return Opacity(
          opacity: _overlayFadeAnimation.value,
          child: child,
        );
      },
    );
  }

  Widget _buildBottomContent(
    EpisodeModel episode,
    List<EpisodeModel> episodes,
    List<EpisodeCommentModel> comments,
    currentUser,
    bool isLiked,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Action buttons
          _buildActionButtons(episode, currentUser, isLiked),
          
          // Tab content
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(text: 'Description'),
                      Tab(text: 'Comments (${comments.length})'),
                      Tab(text: 'Episodes (${episodes.length})'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildDescriptionTab(episode),
                        _buildCommentsTab(episode, comments, currentUser),
                        _buildEpisodesTab(episodes, episode),
                      ],
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

  Widget _buildActionButtons(EpisodeModel episode, currentUser, bool isLiked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Like button
          _buildActionButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            label: _formatCount(episode.likes),
            color: isLiked ? Colors.red : null,
            onTap: () => _toggleLike(episode, isLiked),
          ),
          
          const SizedBox(width: 24),
          
          // Comment button
          _buildActionButton(
            icon: Icons.comment_outlined,
            label: _formatCount(episode.comments),
            onTap: () => _toggleComments(),
          ),
          
          const SizedBox(width: 24),
          
          // Share button
          _buildActionButton(
            icon: Icons.share_outlined,
            label: 'Share',
            onTap: () => _shareEpisode(episode),
          ),
          
          const Spacer(),
          
          // Add to playlist
          _buildActionButton(
            icon: Icons.playlist_add,
            label: 'Save',
            onTap: () => _addToPlaylist(episode),
          ),
          
          const SizedBox(width: 16),
          
          // Next episode button
          if (_hasNextEpisode())
            ElevatedButton.icon(
              onPressed: _playNextEpisode,
              icon: const Icon(Icons.skip_next, size: 16),
              label: const Text('Next'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionTab(EpisodeModel episode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (episode.description.isNotEmpty) ...[
            Text(
              episode.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
          ],
          
          // Episode stats
          _buildStatRow('Views', _formatCount(episode.views)),
          _buildStatRow('Likes', _formatCount(episode.likes)),
          _buildStatRow('Comments', _formatCount(episode.comments)),
          _buildStatRow('Duration', _formatDuration(episode.duration)),
          _buildStatRow('Published', _formatDate(episode.publishedAt)),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsTab(EpisodeModel episode, List<EpisodeCommentModel> comments, currentUser) {
    return Column(
      children: [
        // Comments list
        Expanded(
          child: comments.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.comment_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No comments yet'),
                      Text(
                        'Be the first to share your thoughts!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final isLiked = currentUser != null && 
                        comment.isLikedBy(currentUser.uid);
                    
                    return CommentWidget(
                      comment: comment,
                      isLiked: isLiked,
                      onLike: () => _toggleCommentLike(comment, isLiked),
                      canDelete: currentUser?.uid == comment.authorUID,
                      onDelete: () => _deleteComment(comment),
                      onReply: () => _replyToComment(comment),
                    );
                  },
                ),
        ),
        
        // Comment input
        if (currentUser != null)
          _buildCommentInput(episode, currentUser),
      ],
    );
  }

  Widget _buildCommentInput(EpisodeModel episode, currentUser) {
    final TextEditingController commentController = TextEditingController();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: currentUser.image.isNotEmpty
                ? CachedNetworkImageProvider(currentUser.image)
                : null,
            child: currentUser.image.isEmpty
                ? const Icon(Icons.person, size: 16)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: commentController,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (text) => _addComment(episode, text.trim(), commentController),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _addComment(episode, commentController.text.trim(), commentController),
            icon: Icon(
              Icons.send,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesTab(List<EpisodeModel> episodes, EpisodeModel currentEpisode) {
    if (episodes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No other episodes available'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final episode = episodes[index];
        final isCurrentEpisode = episode.episodeId == currentEpisode.episodeId;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isCurrentEpisode 
                ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: Container(
              width: 80,
              height: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[300],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: episode.thumbnailUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: episode.thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.play_circle_outline),
                        ),
                      )
                    : const Icon(Icons.play_circle_outline),
              ),
            ),
            title: Text(
              episode.title,
              style: TextStyle(
                fontWeight: isCurrentEpisode ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Episode ${episode.episodeNumber}'),
                Text(
                  '${_formatCount(episode.views)} views • ${_formatDuration(episode.duration)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            trailing: isCurrentEpisode 
                ? Icon(
                    Icons.play_circle_filled,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : const Icon(Icons.play_circle_outline),
            onTap: isCurrentEpisode ? null : () => _playEpisode(episode),
          ),
        );
      },
    );
  }

  Widget _buildCommentsOverlay(EpisodeModel episode, List<EpisodeCommentModel> comments, currentUser) {
    return SlideTransition(
      position: _commentsSlideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Comments (${comments.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _toggleComments,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Comments content
            Expanded(
              child: _buildCommentsTab(episode, comments, currentUser),
            ),
          ],
        ),
      ),
    );
  }

  // Action methods
  void _toggleControlsVisibility() {
    setState(() {
      _showControls = !_showControls;
    });
    
    if (_showControls) {
      _overlayAnimationController.forward();
      _setupAutoHideControls();
    } else {
      _overlayAnimationController.reverse();
    }
  }

  void _toggleComments() {
    setState(() {
      _showComments = !_showComments;
    });
    
    if (_showComments) {
      _commentsAnimationController.forward();
    } else {
      _commentsAnimationController.reverse();
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  void _onVideoEnd(EpisodeModel episode) {
    if (!_hasIncrementedView) {
      ref.read(miniSeriesProvider.notifier).incrementView(episode.episodeId);
      _hasIncrementedView = true;
    }
    
    // Show next episode suggestion
    if (_hasNextEpisode()) {
      _showNextEpisodeDialog();
    }
  }

  void _onVideoProgress(Duration position, Duration duration) {
    // Track watch time for analytics
    final watchPercentage = position.inMilliseconds / duration.inMilliseconds;
    
    // Increment view count when 25% watched
    if (!_hasIncrementedView && watchPercentage >= 0.25) {
      final episode = ref.read(currentEpisodeProvider);
      if (episode != null) {
        ref.read(miniSeriesProvider.notifier).incrementView(episode.episodeId);
        _hasIncrementedView = true;
      }
    }
  }

  void _toggleLike(EpisodeModel episode, bool isLiked) {
    if (isLiked) {
      ref.read(miniSeriesProvider.notifier).unlikeEpisode(episode.episodeId);
    } else {
      ref.read(miniSeriesProvider.notifier).likeEpisode(episode.episodeId);
    }
    
    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  void _shareEpisode(EpisodeModel episode) {
    final shareText = '${episode.title}\n'
        'Episode ${episode.episodeNumber}\n'
        '${_formatCount(episode.views)} views\n'
        'Watch on Mini Series App';
    
    Share.share(
      shareText,
      subject: 'Check out this episode: ${episode.title}',
    );
  }

  void _addToPlaylist(EpisodeModel episode) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add to Playlist',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Create New Playlist'),
              onTap: () {
                Navigator.of(context).pop();
                showSnackBar(context, 'Creating new playlist...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_play),
              title: const Text('Watch Later'),
              onTap: () {
                Navigator.of(context).pop();
                showSnackBar(context, 'Added to Watch Later');
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favorites'),
              onTap: () {
                Navigator.of(context).pop();
                showSnackBar(context, 'Added to Favorites');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, EpisodeModel episode) {
    switch (action) {
      case 'report':
        _reportEpisode(episode);
        break;
      case 'download':
        _downloadEpisode(episode);
        break;
      case 'quality':
        _showQualitySettings();
        break;
    }
  }

  void _reportEpisode(EpisodeModel episode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Episode'),
        content: const Text('Why are you reporting this episode?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              showSnackBar(context, 'Episode reported. Thank you for your feedback.');
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _downloadEpisode(EpisodeModel episode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Episode'),
        content: const Text('Download this episode for offline viewing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              showSnackBar(context, 'Download started...');
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  void _showQualitySettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Video Quality',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.hd),
              title: const Text('Auto (Recommended)'),
              trailing: const Icon(Icons.check),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.hd),
              title: const Text('1080p'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.hd),
              title: const Text('720p'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.sd),
              title: const Text('480p'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _addComment(EpisodeModel episode, String content, TextEditingController controller) {
    if (content.isNotEmpty) {
      ref.read(miniSeriesProvider.notifier).addComment(
        episodeId: episode.episodeId,
        seriesId: episode.seriesId,
        content: content,
      );
      controller.clear();
      
      // Haptic feedback
      HapticFeedback.selectionClick();
    }
  }

  void _toggleCommentLike(EpisodeCommentModel comment, bool isLiked) {
    if (isLiked) {
      ref.read(miniSeriesProvider.notifier).unlikeComment(comment.commentId);
    } else {
      ref.read(miniSeriesProvider.notifier).likeComment(comment.commentId);
    }
  }

  void _deleteComment(EpisodeCommentModel comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(miniSeriesProvider.notifier).deleteComment(comment.commentId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _replyToComment(EpisodeCommentModel comment) {
    // This would focus the comment input and add @username
    showSnackBar(context, 'Reply feature coming soon!');
  }

  bool _hasNextEpisode() {
    final episodes = ref.read(seriesEpisodesProvider);
    final currentEpisode = ref.read(currentEpisodeProvider);
    
    if (currentEpisode == null) return false;
    
    final currentIndex = episodes.indexWhere((e) => e.episodeId == currentEpisode.episodeId);
    return currentIndex != -1 && currentIndex < episodes.length - 1;
  }

  void _playNextEpisode() {
    final episodes = ref.read(seriesEpisodesProvider);
    final currentEpisode = ref.read(currentEpisodeProvider);
    
    if (currentEpisode != null) {
      final currentIndex = episodes.indexWhere((e) => e.episodeId == currentEpisode.episodeId);
      if (currentIndex != -1 && currentIndex < episodes.length - 1) {
        final nextEpisode = episodes[currentIndex + 1];
        _playEpisode(nextEpisode);
      }
    }
  }

  void _playEpisode(EpisodeModel episode) {
    Navigator.pushReplacementNamed(
      context,
      '/episodePlayerScreen',
      arguments: {
        'episodeId': episode.episodeId,
        'seriesId': episode.seriesId,
      },
    );
  }

  void _showNextEpisodeDialog() {
    final episodes = ref.read(seriesEpisodesProvider);
    final currentEpisode = ref.read(currentEpisodeProvider);
    
    if (currentEpisode == null) return;
    
    final currentIndex = episodes.indexWhere((e) => e.episodeId == currentEpisode.episodeId);
    if (currentIndex == -1 || currentIndex >= episodes.length - 1) return;
    
    final nextEpisode = episodes[currentIndex + 1];
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Next episode thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: nextEpisode.thumbnailUrl,
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 120,
                  color: Colors.grey[300],
                  child: const Icon(Icons.play_circle_outline, size: 48),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Next Episode',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              nextEpisode.title,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 4),
            
            Text(
              'Episode ${nextEpisode.episodeNumber} • ${_formatDuration(nextEpisode.duration)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _playEpisode(nextEpisode);
            },
            child: const Text('Play Next'),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${difference.inDays > 730 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${difference.inDays > 60 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

// Next Episode Countdown Widget
class NextEpisodeCountdown extends StatefulWidget {
  final Duration countdown;
  final VoidCallback onCountdownEnd;
  final VoidCallback onCancel;
  final EpisodeModel nextEpisode;

  const NextEpisodeCountdown({
    super.key,
    required this.countdown,
    required this.onCountdownEnd,
    required this.onCancel,
    required this.nextEpisode,
  });

  @override
  State<NextEpisodeCountdown> createState() => _NextEpisodeCountdownState();
}

class _NextEpisodeCountdownState extends State<NextEpisodeCountdown>
    with TickerProviderStateMixin {
  late AnimationController _countdownController;
  late Animation<double> _progressAnimation;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.countdown;
    
    _countdownController = AnimationController(
      duration: widget.countdown,
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_countdownController);
    
    _countdownController.forward();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCountdownEnd();
      }
    });
  }

  @override
  void dispose() {
    _countdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Next episode thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: widget.nextEpisode.thumbnailUrl,
                  width: 60,
                  height: 40,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 60,
                    height: 40,
                    color: Colors.grey[700],
                    child: const Icon(Icons.play_circle_outline, 
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Episode info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Next Episode',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      widget.nextEpisode.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Cancel button
              IconButton(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.close, color: Colors.white),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Countdown progress
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              final remainingSeconds = (_progressAnimation.value * 
                  widget.countdown.inSeconds).round();
              
              return Column(
                children: [
                  LinearProgressIndicator(
                    value: 1 - _progressAnimation.value,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Auto-play in ${remainingSeconds}s',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// Picture-in-Picture Mode Widget
class PictureInPicturePlayer extends StatefulWidget {
  final String videoUrl;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const PictureInPicturePlayer({
    super.key,
    required this.videoUrl,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<PictureInPicturePlayer> createState() => _PictureInPicturePlayerState();
}

class _PictureInPicturePlayerState extends State<PictureInPicturePlayer> {
  Offset _position = const Offset(20, 100);
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: Draggable(
        feedback: _buildPipWidget(),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          setState(() {
            _position = details.offset;
          });
        },
        child: _buildPipWidget(),
      ),
    );
  }

  Widget _buildPipWidget() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 120,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Video content placeholder
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            
            // Close button
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
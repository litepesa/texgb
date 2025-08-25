// lib/features/dramas/screens/drama_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/dramas/providers/drama_providers.dart';
import 'package:textgb/features/dramas/providers/drama_actions_provider.dart';
import 'package:textgb/features/dramas/widgets/drama_unlock_dialog.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/wallet/providers/wallet_providers.dart';
import 'package:textgb/models/drama_model.dart';
import 'package:textgb/models/episode_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class DramaDetailsScreen extends ConsumerStatefulWidget {
  final String dramaId;

  const DramaDetailsScreen({
    super.key,
    required this.dramaId,
  });

  @override
  ConsumerState<DramaDetailsScreen> createState() => _DramaDetailsScreenState();
}

class _DramaDetailsScreenState extends ConsumerState<DramaDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Listen to action messages
    ref.listenManual(dramaActionsProvider, (previous, next) {
      if (next.error != null) {
        showSnackBar(context, next.error!);
        ref.read(dramaActionsProvider.notifier).clearMessages();
      } else if (next.successMessage != null) {
        showSnackBar(context, next.successMessage!);
        ref.read(dramaActionsProvider.notifier).clearMessages();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final drama = ref.watch(dramaProvider(widget.dramaId));
    final episodes = ref.watch(dramaEpisodesProvider(widget.dramaId));

    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      body: drama.when(
        data: (dramaModel) {
          if (dramaModel == null) {
            return _buildNotFound();
          }
          
          return _buildDramaDetails(dramaModel, episodes);
        },
        loading: () => _buildLoading(),
        error: (error, stack) => _buildError(error.toString()),
      ),
    );
  }

  Widget _buildDramaDetails(DramaModel drama, AsyncValue<List<EpisodeModel>> episodes) {
    final modernTheme = context.modernTheme;
    final isFavorited = ref.watch(isDramaFavoritedProvider(drama.dramaId));
    final isUnlocked = ref.watch(isDramaUnlockedProvider(drama.dramaId));
    final userProgress = ref.watch(dramaUserProgressProvider(drama.dramaId));
    final coinsBalance = ref.watch(coinsBalanceProvider) ?? 0; // Fixed provider name

    return CustomScrollView(
      slivers: [
        // App bar with banner
        SliverAppBar(
          expandedHeight: 250,
          floating: false,
          pinned: true,
          backgroundColor: modernTheme.backgroundColor,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: isFavorited ? Colors.red.shade400 : Colors.white,
                ),
              ),
              onPressed: () => _toggleFavorite(),
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$coinsBalance',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              onPressed: () => Navigator.pushNamed(context, Constants.walletScreen),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Banner image
                drama.bannerImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: drama.bannerImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: modernTheme.surfaceVariantColor,
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: modernTheme.surfaceVariantColor,
                          child: Icon(
                            Icons.tv,
                            size: 64,
                            color: modernTheme.textSecondaryColor,
                          ),
                        ),
                      )
                    : Container(
                        color: modernTheme.surfaceVariantColor,
                        child: Icon(
                          Icons.tv,
                          size: 64,
                          color: modernTheme.textSecondaryColor,
                        ),
                      ),

                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),

                // Badges
                Positioned(
                  top: 100,
                  left: 16,
                  child: Row(
                    children: [
                      if (drama.isPremium)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium, size: 16, color: Colors.white),
                              const SizedBox(width: 4),
                              const Text(
                                'Premium',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(width: 8),
                      
                      if (drama.isFeatured)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFE2C55),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 16, color: Colors.white),
                              const SizedBox(width: 4),
                              const Text(
                                'Featured',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(width: 8),
                      
                      // Unlocked badge
                      if (isUnlocked)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_open, size: 16, color: Colors.white),
                              const SizedBox(width: 4),
                              const Text(
                                'Unlocked',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Drama info
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  drama.title,
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // Stats row
                Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.visibility,
                      label: _formatCount(drama.viewCount),
                      color: Colors.blue.shade400,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      icon: Icons.favorite,
                      label: _formatCount(drama.favoriteCount),
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      icon: Icons.play_circle,
                      label: '${drama.totalEpisodes} episodes',
                      color: Colors.green.shade400,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Premium info
                if (drama.isPremium)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFE2C55).withOpacity(0.1),
                          const Color(0xFFFE2C55).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFE2C55).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isUnlocked ? Icons.lock_open : Icons.info_outline,
                              color: isUnlocked ? Colors.green.shade600 : const Color(0xFFFE2C55),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isUnlocked ? 'Premium Content - Unlocked' : 'Premium Content',
                              style: TextStyle(
                                color: isUnlocked ? Colors.green.shade600 : const Color(0xFFFE2C55),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isUnlocked 
                              ? 'You have full access to all episodes in this drama!'
                              : drama.premiumInfo,
                          style: TextStyle(
                            color: modernTheme.textColor,
                            fontSize: 14,
                          ),
                        ),
                        if (!isUnlocked) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Unlock all episodes for ${Constants.dramaUnlockCost} coins',
                            style: TextStyle(
                              color: modernTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Description
                Text(
                  'Description',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  drama.description,
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _watchNow(drama, episodes),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(userProgress > 0 ? 'Continue Watching' : 'Watch Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFE2C55),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _toggleFavorite(),
                      icon: Icon(isFavorited ? Icons.favorite : Icons.favorite_border),
                      label: Text(isFavorited ? 'Favorited' : 'Favorite'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFavorited 
                            ? Colors.red.shade400 
                            : modernTheme.surfaceVariantColor,
                        foregroundColor: isFavorited 
                            ? Colors.white 
                            : modernTheme.textColor,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Episodes section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Episodes',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Episodes list
        episodes.when(
          data: (episodeList) {
            if (episodeList.isEmpty) {
              return SliverToBoxAdapter(
                child: _buildEmptyEpisodes(),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final episode = episodeList[index];
                  return _buildEpisodeItem(drama, episode, isUnlocked);
                },
                childCount: episodeList.length,
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: Color(0xFFFE2C55)),
              ),
            ),
          ),
          error: (error, stack) => SliverToBoxAdapter(
            child: _buildEpisodesError(error.toString()),
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeItem(DramaModel drama, EpisodeModel episode, bool isDramaUnlocked) {
    final modernTheme = context.modernTheme;
    final user = ref.watch(currentUserProvider);
    final hasWatched = user?.hasWatched(episode.episodeId) ?? false;
    final canWatch = drama.canWatchEpisode(episode.episodeNumber, isDramaUnlocked);
    final isLocked = !canWatch;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: hasWatched
            ? Border.all(color: const Color(0xFFFE2C55).withOpacity(0.3), width: 1)
            : null,
      ),
      child: ListTile(
        leading: Stack(
          children: [
            Container(
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                color: modernTheme.surfaceVariantColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: episode.thumbnailUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: episode.thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: modernTheme.surfaceVariantColor,
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.play_circle_outline,
                          color: modernTheme.textSecondaryColor,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.play_circle_outline,
                      color: modernTheme.textSecondaryColor,
                    ),
            ),
            if (hasWatched)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFE2C55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          episode.displayTitle,
          style: TextStyle(
            color: hasWatched 
                ? modernTheme.textColor?.withOpacity(0.7)
                : modernTheme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          episode.formattedDuration,
          style: TextStyle(
            color: modernTheme.textSecondaryColor,
            fontSize: 12,
          ),
        ),
        trailing: isLocked
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${Constants.dramaUnlockCost}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFE2C55),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  size: 16,
                  color: Colors.white,
                ),
              ),
        onTap: () => _playEpisode(drama, episode, canWatch),
      ),
    );
  }

  Widget _buildEmptyEpisodes() {
    final modernTheme = context.modernTheme;
    
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 64,
            color: modernTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No episodes available yet',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesError(String error) {
    final modernTheme = context.modernTheme;
    
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load episodes',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(dramaEpisodesProvider(widget.dramaId)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFE2C55),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFFE2C55)),
      ),
    );
  }

  Widget _buildError(String error) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load drama',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: modernTheme.surfaceVariantColor,
                      foregroundColor: modernTheme.textColor,
                    ),
                    child: const Text('Go Back'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => ref.refresh(dramaProvider(widget.dramaId)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFE2C55),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.tv_off,
                size: 64,
                color: modernTheme.textSecondaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Drama not found',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This drama may have been removed or is no longer available.',
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFE2C55),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleFavorite() {
    ref.read(dramaActionsProvider.notifier).toggleFavorite(widget.dramaId);
  }

  void _watchNow(DramaModel drama, AsyncValue<List<EpisodeModel>> episodes) {
    episodes.when(
      data: (episodeList) {
        if (episodeList.isEmpty) {
          showSnackBar(context, 'No episodes available');
          return;
        }

        final userProgress = ref.read(dramaUserProgressProvider(widget.dramaId));
        final nextEpisode = userProgress > 0 
            ? episodeList.firstWhere(
                (ep) => ep.episodeNumber == userProgress + 1,
                orElse: () => episodeList.first,
              )
            : episodeList.first;

        // Navigate to the TikTok-style feed
        Navigator.pushNamed(
          context,
          Constants.episodeFeedScreen,
          arguments: {
            'dramaId': drama.dramaId,
            'initialEpisodeId': nextEpisode.episodeId,
          },
        );
      },
      loading: () => showSnackBar(context, 'Loading episodes...'),
      error: (error, stack) => showSnackBar(context, 'Failed to load episodes'),
    );
  }

  void _playEpisode(DramaModel drama, EpisodeModel episode, bool canWatch) {
    if (!canWatch) {
      // Show unlock dialog
      showDramaUnlockDialog(context, drama);
      return;
    }

    // Navigate to the TikTok-style feed
    Navigator.pushNamed(
      context,
      Constants.episodeFeedScreen,
      arguments: {
        'dramaId': drama.dramaId,
        'initialEpisodeId': episode.episodeId,
      },
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}
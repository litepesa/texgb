// lib/features/dramas/screens/drama_details_screen.dart - SIMPLIFIED VERSION
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
        
        // If it was an unlock success, clear the recently unlocked status after a delay
        if (next.successMessage!.contains('unlocked')) {
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              ref.read(dramaActionsProvider.notifier).clearRecentlyUnlocked(widget.dramaId);
            }
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final drama = ref.watch(dramaProvider(widget.dramaId));

    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () => _handleRefresh(),
        backgroundColor: modernTheme.surfaceColor,
        color: modernTheme.textColor,
        child: drama.when(
          data: (dramaModel) {
            if (dramaModel == null) {
              return _buildNotFound();
            }
            
            return _buildDramaDetails(dramaModel);
          },
          loading: () => _buildLoading(),
          error: (error, stack) => _buildError(error.toString()),
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    // Force refresh all drama-related data
    await ref.read(dramaActionsProvider.notifier).forceRefreshAll();
    
    // Specifically refresh this drama
    ref.invalidate(dramaProvider(widget.dramaId));
  }

  Widget _buildDramaDetails(DramaModel drama) {
    final modernTheme = context.modernTheme;
    
    // Use enhanced providers for better state management
    final isFavorited = ref.watch(isDramaFavoritedProvider(drama.dramaId));
    final isUnlocked = ref.watch(isDramaUnlockedEnhancedProvider(drama.dramaId));
    final userProgress = ref.watch(dramaUserProgressProvider(drama.dramaId));
    final coinsBalance = ref.watch(coinsBalanceProvider) ?? 0;

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
            // Favorite button with real-time updates
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    isFavorited ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(isFavorited),
                    color: isFavorited ? Colors.red.shade400 : Colors.white,
                  ),
                ),
              ),
              onPressed: () => _toggleFavorite(),
            ),
            
            // Wallet balance with real-time updates
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
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        '$coinsBalance',
                        key: ValueKey(coinsBalance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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

                // Badges with unlock status animation
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
                      
                      // Enhanced unlocked badge with animation
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: isUnlocked
                            ? Container(
                                key: const ValueKey('unlocked'),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade600,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.shade600.withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
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
                              )
                            : const SizedBox.shrink(),
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

                // Enhanced premium info with unlock status
                if (drama.isPremium)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isUnlocked
                            ? [
                                Colors.green.shade600.withOpacity(0.1),
                                Colors.green.shade600.withOpacity(0.05),
                              ]
                            : [
                                const Color(0xFFFE2C55).withOpacity(0.1),
                                const Color(0xFFFE2C55).withOpacity(0.05),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isUnlocked
                            ? Colors.green.shade600.withOpacity(0.3)
                            : const Color(0xFFFE2C55).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                isUnlocked ? Icons.lock_open : Icons.info_outline,
                                key: ValueKey(isUnlocked),
                                color: isUnlocked ? Colors.green.shade600 : const Color(0xFFFE2C55),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                isUnlocked ? 'Premium Content - Unlocked' : 'Premium Content',
                                key: ValueKey(isUnlocked),
                                style: TextStyle(
                                  color: isUnlocked ? Colors.green.shade600 : const Color(0xFFFE2C55),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            isUnlocked 
                                ? 'You have full access to all episodes in this drama!'
                                : drama.premiumInfo,
                            key: ValueKey(isUnlocked),
                            style: TextStyle(
                              color: modernTheme.textColor,
                              fontSize: 14,
                            ),
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

                // Enhanced action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _watchNow(drama),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(userProgress > 0 ? 'Continue Watching' : 'Watch Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFE2C55),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: ElevatedButton.icon(
                        onPressed: () => _toggleFavorite(),
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            isFavorited ? Icons.favorite : Icons.favorite_border,
                            key: ValueKey(isFavorited),
                          ),
                        ),
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
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Episodes section - Enhanced with better unlock status
        if (drama.hasEpisodes) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Episodes (${drama.totalEpisodes})',
                    style: TextStyle(
                      color: modernTheme.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (drama.isPremium && !isUnlocked)
                    TextButton.icon(
                      onPressed: () => _showUnlockDialog(drama),
                      icon: const Icon(Icons.workspace_premium, size: 16),
                      label: Text('Unlock All (${Constants.dramaUnlockCost})'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFE2C55),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Episodes list - Enhanced with real-time unlock status
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final episodeNumber = index + 1;
                return _buildEnhancedEpisodeItem(drama, episodeNumber, isUnlocked);
              },
              childCount: drama.totalEpisodes,
            ),
          ),
        ] else ...[
          // No episodes state
          SliverToBoxAdapter(
            child: _buildEmptyEpisodes(),
          ),
        ],

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

  // Enhanced episode item with real-time unlock status updates
  Widget _buildEnhancedEpisodeItem(DramaModel drama, int episodeNumber, bool isDramaUnlocked) {
    final modernTheme = context.modernTheme;
    final user = ref.watch(currentUserProvider);
    final userProgress = ref.watch(dramaUserProgressProvider(drama.dramaId));
    
    // Use enhanced provider for real-time can-watch status
    final canWatch = ref.watch(canWatchDramaEpisodeEnhancedProvider(drama.dramaId, episodeNumber));
    
    // Simple check for episode unlock requirement (no need for separate provider)
    final episodeRequiresUnlock = drama.isPremium && 
        episodeNumber > drama.freeEpisodesCount && 
        !isDramaUnlocked && 
        !ref.read(dramaActionsProvider).wasRecentlyUnlocked(drama.dramaId);
    
    final hasWatched = userProgress >= episodeNumber;
    final isLocked = !canWatch;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: hasWatched
            ? Border.all(color: const Color(0xFFFE2C55).withOpacity(0.3), width: 1)
            : null,
        boxShadow: !isLocked ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: drama.bannerImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: drama.bannerImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: modernTheme.surfaceVariantColor,
                          child: Center(
                            child: Text(
                              '$episodeNumber',
                              style: TextStyle(
                                color: modernTheme.textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: modernTheme.surfaceVariantColor,
                          child: Center(
                            child: Text(
                              '$episodeNumber',
                              style: TextStyle(
                                color: modernTheme.textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          '$episodeNumber',
                          style: TextStyle(
                            color: modernTheme.textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
          drama.getEpisodeTitle(episodeNumber),
          style: TextStyle(
            color: hasWatched 
                ? modernTheme.textColor?.withOpacity(0.7)
                : modernTheme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          hasWatched ? 'Watched' : (canWatch ? 'Tap to watch' : 'Requires unlock'),
          style: TextStyle(
            color: modernTheme.textSecondaryColor,
            fontSize: 12,
          ),
        ),
        trailing: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isLocked
              ? Container(
                  key: const ValueKey('locked'),
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
                  key: const ValueKey('unlocked'),
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
        ),
        onTap: () => _playEpisode(drama, episodeNumber, canWatch),
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

  void _watchNow(DramaModel drama) {
    if (!drama.hasEpisodes) {
      showSnackBar(context, 'No episodes available');
      return;
    }

    final userProgress = ref.read(dramaUserProgressProvider(widget.dramaId));
    final nextEpisodeNumber = userProgress > 0 ? userProgress + 1 : 1;
    
    final episodeToWatch = nextEpisodeNumber <= drama.totalEpisodes ? nextEpisodeNumber : 1;

    Navigator.pushNamed(
      context,
      Constants.episodeFeedScreen,
      arguments: {
        'dramaId': drama.dramaId,
        'initialEpisodeNumber': episodeToWatch,
      },
    );
  }

  void _playEpisode(DramaModel drama, int episodeNumber, bool canWatch) {
    if (!canWatch) {
      _showUnlockDialog(drama);
      return;
    }

    Navigator.pushNamed(
      context,
      Constants.episodeFeedScreen,
      arguments: {
        'dramaId': drama.dramaId,
        'initialEpisodeNumber': episodeNumber,
      },
    );
  }

  void _showUnlockDialog(DramaModel drama) {
    showDialog(
      context: context,
      builder: (context) => DramaUnlockDialog(drama: drama),
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
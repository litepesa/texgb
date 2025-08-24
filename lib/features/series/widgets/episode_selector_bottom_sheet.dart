// lib/features/series/widgets/episode_selector_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:textgb/features/series/models/series_model.dart';
import 'package:textgb/features/series/models/series_episode_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class EpisodeSelectorBottomSheet extends StatefulWidget {
  final SeriesModel series;
  final List<SeriesEpisodeModel> episodes;
  final int currentEpisodeIndex;
  final bool hasPurchased;
  final Function(int) onEpisodeSelected;

  const EpisodeSelectorBottomSheet({
    super.key,
    required this.series,
    required this.episodes,
    required this.currentEpisodeIndex,
    required this.hasPurchased,
    required this.onEpisodeSelected,
  });

  @override
  State<EpisodeSelectorBottomSheet> createState() => _EpisodeSelectorBottomSheetState();
}

class _EpisodeSelectorBottomSheetState extends State<EpisodeSelectorBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Check if user can access a specific episode
  bool _canAccessEpisode(int episodeNumber) {
    // If series has no paywall, all episodes are accessible
    if (!widget.series.hasPaywall) {
      return true;
    }

    // If episode is within free range, accessible
    if (episodeNumber <= widget.series.freeEpisodeCount) {
      return true;
    }

    // If episode is paid, check if user purchased the series
    return widget.hasPurchased;
  }

  // Get access status text for episode
  String _getAccessStatusText(int episodeNumber) {
    if (!widget.series.hasPaywall) {
      return 'Free';
    }

    if (episodeNumber <= widget.series.freeEpisodeCount) {
      return 'Free';
    }

    if (widget.hasPurchased) {
      return 'Purchased';
    }

    return 'Locked';
  }

  // Get access status color
  Color _getAccessStatusColor(int episodeNumber) {
    if (!widget.series.hasPaywall) {
      return Colors.green;
    }

    if (episodeNumber <= widget.series.freeEpisodeCount) {
      return Colors.green;
    }

    if (widget.hasPurchased) {
      return Colors.blue;
    }

    return Colors.orange;
  }

  void _handleEpisodeSelection(int index) {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
      widget.onEpisodeSelected(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.8;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5 * _animation.value),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Transform.translate(
              offset: Offset(0, (1 - _animation.value) * 300),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: maxHeight,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                decoration: BoxDecoration(
                  color: modernTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: modernTheme.primaryColor!.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Drag handle
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: modernTheme.textSecondaryColor!.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          
                          // Series info
                          Row(
                            children: [
                              // Series thumbnail
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: modernTheme.primaryColor!.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: widget.series.thumbnailImage.isNotEmpty
                                      ? Image.network(
                                          widget.series.thumbnailImage,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey,
                                              child: Icon(
                                                Icons.play_circle_outline,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: Colors.grey,
                                          child: Icon(
                                            Icons.play_circle_outline,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                ),
                              ),
                              
                              const SizedBox(width: 12),
                              
                              // Series title and episode count
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.series.title,
                                      style: TextStyle(
                                        color: modernTheme.textColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${widget.episodes.length} episodes • ${widget.series.formattedTotalDuration}',
                                      style: TextStyle(
                                        color: modernTheme.textSecondaryColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Close button
                              IconButton(
                                onPressed: () {
                                  _animationController.reverse().then((_) {
                                    Navigator.of(context).pop();
                                  });
                                },
                                icon: Icon(
                                  CupertinoIcons.xmark,
                                  color: modernTheme.textSecondaryColor,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Episodes list
                    Flexible(
                      child: widget.episodes.isEmpty
                          ? _buildEmptyState(modernTheme)
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shrinkWrap: true,
                              itemCount: widget.episodes.length,
                              itemBuilder: (context, index) {
                                final episode = widget.episodes[index];
                                final canAccess = _canAccessEpisode(episode.episodeNumber);
                                final isCurrentEpisode = index == widget.currentEpisodeIndex;
                                
                                return _buildEpisodeItem(
                                  episode,
                                  index,
                                  canAccess,
                                  isCurrentEpisode,
                                  modernTheme,
                                );
                              },
                            ),
                    ),
                    
                    // Paywall info (if applicable)
                    if (widget.series.hasPaywall && !widget.hasPurchased)
                      _buildPaywallInfo(modernTheme),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEpisodeItem(
    SeriesEpisodeModel episode,
    int index,
    bool canAccess,
    bool isCurrentEpisode,
    ModernThemeExtension modernTheme,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentEpisode 
            ? modernTheme.primaryColor!.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentEpisode
            ? Border.all(
                color: modernTheme.primaryColor!.withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => _handleEpisodeSelection(index),
        
        // Episode thumbnail/number
        leading: Container(
          width: 60,
          height: 40,
          decoration: BoxDecoration(
            color: canAccess 
                ? modernTheme.primaryColor!.withOpacity(0.2)
                : modernTheme.textSecondaryColor!.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: episode.thumbnailUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: [
                      Image.network(
                        episode.thumbnailUrl,
                        width: 60,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildEpisodeNumberContainer(episode, canAccess, modernTheme);
                        },
                      ),
                      if (!canAccess)
                        Container(
                          width: 60,
                          height: 40,
                          color: Colors.black.withOpacity(0.6),
                          child: const Icon(
                            CupertinoIcons.lock_fill,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      if (isCurrentEpisode)
                        Container(
                          width: 60,
                          height: 40,
                          color: modernTheme.primaryColor!.withOpacity(0.3),
                          child: const Icon(
                            CupertinoIcons.play_fill,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                )
              : _buildEpisodeNumberContainer(episode, canAccess, modernTheme),
        ),
        
        // Episode info
        title: Row(
          children: [
            Expanded(
              child: Text(
                episode.title.isNotEmpty 
                    ? 'Ep ${episode.episodeNumber}: ${episode.title}'
                    : 'Episode ${episode.episodeNumber}',
                style: TextStyle(
                  color: canAccess 
                      ? modernTheme.textColor
                      : modernTheme.textSecondaryColor,
                  fontSize: 16,
                  fontWeight: isCurrentEpisode ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Access status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getAccessStatusColor(episode.episodeNumber).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _getAccessStatusText(episode.episodeNumber),
                style: TextStyle(
                  color: _getAccessStatusColor(episode.episodeNumber),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        
        subtitle: Row(
          children: [
            // Duration
            Text(
              episode.formattedDuration,
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
            
            // Episode stats
            if (episode.views > 0) ...[
              const SizedBox(width: 8),
              Icon(
                CupertinoIcons.eye,
                color: modernTheme.textSecondaryColor,
                size: 12,
              ),
              const SizedBox(width: 2),
              Text(
                _formatCount(episode.views),
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ],
            
            if (episode.likes > 0) ...[
              const SizedBox(width: 8),
              Icon(
                CupertinoIcons.heart,
                color: modernTheme.textSecondaryColor,
                size: 12,
              ),
              const SizedBox(width: 2),
              Text(
                _formatCount(episode.likes),
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ],
            
            // Featured badge
            if (episode.isFeatured) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'FEATURED',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        
        // Access indicator
        trailing: canAccess
            ? (isCurrentEpisode 
                ? Icon(
                    CupertinoIcons.play_circle_fill,
                    color: modernTheme.primaryColor,
                    size: 24,
                  )
                : Icon(
                    CupertinoIcons.play_circle,
                    color: modernTheme.textSecondaryColor,
                    size: 20,
                  ))
            : Icon(
                CupertinoIcons.lock_circle_fill,
                color: Colors.orange,
                size: 20,
              ),
      ),
    );
  }

  Widget _buildEpisodeNumberContainer(
    SeriesEpisodeModel episode,
    bool canAccess,
    ModernThemeExtension modernTheme,
  ) {
    return Stack(
      children: [
        Container(
          width: 60,
          height: 40,
          child: Center(
            child: Text(
              episode.episodeNumber.toString(),
              style: TextStyle(
                color: canAccess 
                    ? modernTheme.primaryColor
                    : modernTheme.textSecondaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (!canAccess)
          Container(
            width: 60,
            height: 40,
            color: Colors.black.withOpacity(0.6),
            child: const Icon(
              CupertinoIcons.lock_fill,
              color: Colors.white,
              size: 16,
            ),
          ),
      ],
    );
  }

  Widget _buildPaywallInfo(ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.primaryColor!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: modernTheme.primaryColor!.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.lock_shield,
                color: modernTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Unlock Full Series',
                  style: TextStyle(
                    color: modernTheme.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Episodes ${widget.series.freeEpisodeCount + 1}-${widget.series.episodeCount} require purchase • ${widget.series.formattedPrice}',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ModernThemeExtension modernTheme) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.play_circle,
            color: modernTheme.textSecondaryColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No Episodes Yet',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Episodes will appear here once they\'re added to the series',
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

  String _formatCount(int count) {
    if (count == 0) return '0';
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}
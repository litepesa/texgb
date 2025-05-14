// lib/features/marketplace/screens/marketplace_video_feed_screen.dart - Further UI Refinements
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/marketplace/providers/marketplace_provider.dart';
import 'package:textgb/features/marketplace/widgets/marketplace_video_item.dart';
import 'package:textgb/features/marketplace/screens/create_marketplace_video_screen.dart';
import 'package:textgb/constants.dart';

class MarketplaceVideoFeedScreen extends ConsumerStatefulWidget {
  const MarketplaceVideoFeedScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MarketplaceVideoFeedScreen> createState() => _MarketplaceVideoFeedScreenState();
}

class _MarketplaceVideoFeedScreenState extends ConsumerState<MarketplaceVideoFeedScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _progressController;
  bool _isFirstLoad = true;
  int _currentVideoIndex = 0;
  double _currentProgress = 0.0;
  final Duration _videoDuration = const Duration(seconds: 30); // Approximate average video duration

  @override
  void initState() {
    super.initState();
    _loadVideos();
    
    // Set up the progress controller for the progress bar
    _progressController = AnimationController(
      vsync: this,
      duration: _videoDuration,
    )..addListener(() {
      setState(() {
        _currentProgress = _progressController.value;
      });
    });
    
    // Set up transparent status bar for immersive experience
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  Future<void> _loadVideos() async {
    // Only load on first load
    if (_isFirstLoad) {
      debugPrint('MarketplaceVideoFeedScreen: Initial video load');
      await ref.read(marketplaceProvider.notifier).debugMarketplaceData();
      await ref.read(marketplaceProvider.notifier).loadVideos();
      
      if (mounted) {
        setState(() {
          _isFirstLoad = false;
        });
        // Start progress animation when videos are loaded
        _progressController.forward();
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    // Reset system UI when leaving this screen
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Read state from provider
    final marketplaceState = ref.watch(marketplaceProvider);
    final modernTheme = context.modernTheme;
    
    // Calculate bottom padding to account for navigation bar and system navigation
    final bottomNavHeight = 100.0; // Increased height to account for system navigation
    
    return Scaffold(
      extendBodyBehindAppBar: true, // Extend content behind app bar
      extendBody: true, // Extend content behind bottom nav
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          _buildBody(marketplaceState, modernTheme, bottomNavHeight),
          
          // Top transparent gradient for status bar protection
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top + 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // Category filters at top with transparent background
          if (marketplaceState.categories.isNotEmpty && !marketplaceState.isLoading && marketplaceState.videos.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: _buildCategoryFilters(marketplaceState, modernTheme),
            ),
          
          // Add a refresh button in top-right
          Positioned(
            top: MediaQuery.of(context).padding.top + 5,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: modernTheme.primaryColor,
                ),
                onPressed: () {
                  debugPrint('Manual refresh requested');
                  ref.read(marketplaceProvider.notifier).loadVideos(forceRefresh: true);
                  _resetProgress();
                },
              ),
            ),
          ),
          
          // Progress bar divider above bottom nav
          Positioned(
            bottom: bottomNavHeight + 8, // Position above bottom nav with gap
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Video progress indicator
                Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: LinearProgressIndicator(
                    value: _currentProgress,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(modernTheme.primaryColor!),
                  ),
                ),
                // Divider line
                Container(
                  height: 1,
                  color: Colors.grey[900],
                ),
              ],
            ),
          ),
          
          // Show error message if any, with special handling for index errors
          if (marketplaceState.error != null)
            _buildErrorOverlay(marketplaceState.error!, modernTheme),
        ],
      ),
      // Remove FAB as requested
    );
  }

  Widget _buildCategoryFilters(MarketplaceState state, ModernThemeExtension modernTheme) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.categories.length + 1, // +1 for "All" option
        itemBuilder: (context, index) {
          // "All" category option
          if (index == 0) {
            final isSelected = state.selectedCategory == null;
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: const Text('All'),
                selected: isSelected,
                showCheckmark: false,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(marketplaceProvider.notifier).filterByCategory(null);
                    _resetProgress();
                  }
                },
                backgroundColor: Colors.black.withOpacity(0.5),
                selectedColor: modernTheme.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            );
          }
          
          final category = state.categories[index - 1];
          final isSelected = state.selectedCategory == category;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              showCheckmark: false,
              onSelected: (selected) {
                if (selected) {
                  ref.read(marketplaceProvider.notifier).filterByCategory(category);
                  _resetProgress();
                }
              },
              backgroundColor: Colors.black.withOpacity(0.5),
              selectedColor: modernTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorOverlay(String error, ModernThemeExtension modernTheme) {
    // Format for index errors
    if (error.contains('failed-precondition') && error.contains('index')) {
      return Positioned(
        bottom: 160,
        left: 20,
        right: 20,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red.shade700,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Database index is being created',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'This may take a few minutes. Please try again shortly.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    ref.read(marketplaceProvider.notifier).loadVideos(forceRefresh: true);
                    _resetProgress();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('RETRY'),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Generic error message
    return Positioned(
      bottom: 160,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Error: ${error.split(']').last.trim()}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBody(MarketplaceState state, ModernThemeExtension modernTheme, double bottomPadding) {
    // Show loading indicator when loading and no videos yet
    if (state.isLoading && _isFirstLoad) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: modernTheme.primaryColor,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading Marketplace',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Finding the best products for you',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Show empty state when no videos
    if (!state.isLoading && state.videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              color: modernTheme.primaryColor,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              'No Products Yet',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Be the first to share a product video!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateVideo(),
              icon: const Icon(Icons.add),
              label: const Text('Create Listing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Video feed with padding at bottom to prevent overlap with nav bar
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: state.videos.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  color: modernTheme.primaryColor,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'No videos in this category',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () {
                    ref.read(marketplaceProvider.notifier).filterByCategory(null);
                    _resetProgress();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: modernTheme.primaryColor,
                    side: BorderSide(color: modernTheme.primaryColor!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('View All Categories'),
                ),
              ],
            ),
          )
        : PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: state.videos.length,
            onPageChanged: (index) {
              setState(() {
                _currentVideoIndex = index;
              });
              
              // Reset progress bar for new video
              _resetProgress();
              
              // Increment view count when a video is watched
              ref.read(marketplaceProvider.notifier).incrementViewCount(
                state.videos[index].id,
              );
            },
            itemBuilder: (context, index) {
              final video = state.videos[index];
              
              return MarketplaceVideoItem(
                video: video,
                isActive: index == _currentVideoIndex,
              );
            },
          ),
    );
  }

  void _resetProgress() {
    // Reset and restart progress animation
    _progressController.reset();
    _progressController.forward();
  }

  void _navigateToCreateVideo() async {
    debugPrint('Navigating to create video screen');
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateMarketplaceVideoScreen(),
      ),
    );
    
    // Refresh videos after returning from create screen
    debugPrint('Returned from create video screen, refreshing videos');
    ref.read(marketplaceProvider.notifier).loadVideos(forceRefresh: true);
    _resetProgress();
  }
}
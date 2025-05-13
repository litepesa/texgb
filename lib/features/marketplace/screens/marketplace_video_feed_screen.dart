import 'package:flutter/material.dart';
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

class _MarketplaceVideoFeedScreenState extends ConsumerState<MarketplaceVideoFeedScreen> {
  final PageController _pageController = PageController();
  int _currentVideoIndex = 0;

  @override
  void initState() {
    super.initState();
    // Add post-frame callback to ensure the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initially load all videos
      ref.read(marketplaceProvider.notifier).loadVideos();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marketplaceState = ref.watch(marketplaceProvider);
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: Colors.black,
      // AppBar is already handled in HomeScreen
      body: _buildBody(marketplaceState, modernTheme),
    );
  }

  Widget _buildBody(MarketplaceState state, ModernThemeExtension modernTheme) {
    if (state.isLoading && state.videos.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: modernTheme.primaryColor,
        ),
      );
    }

    if (state.videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              color: modernTheme.primaryColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No videos yet',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share a product video!',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateVideo(),
              icon: const Icon(Icons.add),
              label: const Text('Create Video'),
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Category filter at the top
    return Column(
      children: [
        // Categories list
        if (state.categories.isNotEmpty)
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(marketplaceProvider.notifier).filterByCategory(null);
                        }
                      },
                      backgroundColor: Colors.grey.shade800,
                      selectedColor: modernTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
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
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(marketplaceProvider.notifier).filterByCategory(category);
                      }
                    },
                    backgroundColor: Colors.grey.shade800,
                    selectedColor: modernTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                );
              },
            ),
          ),
          
        // Video feed
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: state.videos.length,
            onPageChanged: (index) {
              setState(() {
                _currentVideoIndex = index;
              });
              
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
        ),
      ],
    );
  }

  void _navigateToCreateVideo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateMarketplaceVideoScreen(),
      ),
    );
  }
}
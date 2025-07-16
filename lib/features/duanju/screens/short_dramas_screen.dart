// lib/features/duanju/screens/short_dramas_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class ShortDramasScreen extends ConsumerStatefulWidget {
  const ShortDramasScreen({super.key});

  @override
  ConsumerState<ShortDramasScreen> createState() => _ShortDramasScreenState();
}

class _ShortDramasScreenState extends ConsumerState<ShortDramasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<String> _categories = [
    'All',
    'Following',
    'Trending',
    'Latest',
    'Popular',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: modernTheme.surfaceColor,
      body: Column(
        children: [
          // Category tabs
          Container(
            color: modernTheme.surfaceColor,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              padding: EdgeInsets.zero,
              tabAlignment: TabAlignment.start,
              labelColor: modernTheme.primaryColor,
              unselectedLabelColor: modernTheme.textSecondaryColor,
              indicatorColor: modernTheme.primaryColor,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: _categories.map((category) => Tab(text: category)).toList(),
            ),
          ),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((category) => _buildCategoryContent(category, modernTheme)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryContent(String category, ModernThemeExtension modernTheme) {
    return CustomScrollView(
      slivers: [
        // Subscriptions section
        SliverToBoxAdapter(
          child: _buildSubscriptionsSection(modernTheme),
        ),
        
        // Popular dramas grid
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.65,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildDramaCard(index, modernTheme),
              childCount: 20, // Dummy count
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionsSection(ModernThemeExtension modernTheme) {
    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Your Subscriptions',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 10,
              itemBuilder: (context, index) => _buildSubscriptionCard(index, modernTheme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(int index, ModernThemeExtension modernTheme) {
    final dummyTitles = [
      'Love in Seoul',
      'Midnight Detective',
      'Royal Romance',
      'City of Dreams',
      'Secret Garden',
      'Heart Signal',
      'Time Traveler',
      'Cherry Blossoms',
      'Ocean Blue',
      'Golden Hour'
    ];

    // Generate dummy view counts
    final viewCounts = [
      '2.1M views',
      '850K views',
      '1.3M views',
      '500K views',
      '750K views',
      '1.8M views',
      '320K views',
      '990K views',
      '1.5M views',
      '420K views'
    ];

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          // Full color background
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.primaries[index % Colors.primaries.length].shade300,
                  Colors.primaries[index % Colors.primaries.length].shade600,
                ],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.play_circle_filled,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'UNLOCKED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Floating transparent overlay at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dummyTitles[index % dummyTitles.length],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          blurRadius: 8,
                          color: Colors.black54,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.visibility,
                        color: Colors.white70,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          viewCounts[index % viewCounts.length],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            shadows: [
                              Shadow(
                                blurRadius: 8,
                                color: Colors.black54,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDramaCard(int index, ModernThemeExtension modernTheme) {
    final dummyTitles = [
      'Eternal Love Story',
      'Midnight Mystery',
      'Royal Court',
      'Dream City',
      'Secret Love',
      'Heart Beats',
      'Time Loop',
      'Spring Flowers',
      'Blue Ocean',
      'Golden Dreams',
      'Silver Moon',
      'Red Roses',
      'Green Valley',
      'Purple Sky',
      'Orange Sunset',
      'Pink Dawn',
      'Black Night',
      'White Snow',
      'Yellow Sun',
      'Brown Earth'
    ];

    final episodes = [12, 16, 20, 24, 8, 10, 14, 18, 22, 26][index % 10];
    
    // Generate dummy view counts for main grid
    final viewCounts = [
      '1.2M',
      '850K',
      '2.1M',
      '450K',
      '1.8M',
      '650K',
      '3.2M',
      '920K',
      '1.5M',
      '380K',
      '2.7M',
      '590K',
      '1.1M',
      '750K',
      '1.9M',
      '420K',
      '2.5M',
      '680K',
      '1.4M',
      '330K'
    ];

    return GestureDetector(
      onTap: () => _showDramaDetails(dummyTitles[index], modernTheme),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Full color background cover
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.primaries[index % Colors.primaries.length].shade200,
                    Colors.primaries[index % Colors.primaries.length].shade500,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_circle_filled,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$episodes Episodes',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Floating transparent overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dummyTitles[index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            blurRadius: 8,
                            color: Colors.black54,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.visibility,
                          color: Colors.white70,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${viewCounts[index]} views',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            shadows: [
                              Shadow(
                                blurRadius: 8,
                                color: Colors.black54,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDramaDetails(String title, ModernThemeExtension modernTheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: modernTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: modernTheme.textSecondaryColor?.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drama poster and info
                    Row(
                      children: [
                        Container(
                          width: 120,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                modernTheme.primaryColor!.withOpacity(0.3),
                                modernTheme.primaryColor!,
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.play_circle_filled,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: modernTheme.textColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.visibility, color: modernTheme.textSecondaryColor, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '2.1M views • 2024 • 16 Episodes',
                                    style: TextStyle(
                                      color: modernTheme.textSecondaryColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                                      label: const Text('Play', style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: modernTheme.primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {},
                                    icon: Icon(
                                      Icons.add,
                                      color: modernTheme.textColor,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: modernTheme.surfaceColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(color: modernTheme.dividerColor!),
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
                    
                    const SizedBox(height: 20),
                    
                    // Description
                    Text(
                      'Description',
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A captivating drama that follows the journey of love, friendship, and personal growth. Set in modern times with a touch of romance and mystery that will keep you engaged throughout all episodes.',
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Episodes list
                    Text(
                      'Episodes',
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: 16,
                        itemBuilder: (context, index) => ListTile(
                          leading: Container(
                            width: 60,
                            height: 40,
                            decoration: BoxDecoration(
                              color: modernTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: modernTheme.dividerColor!.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.play_arrow,
                                color: modernTheme.textColor,
                                size: 20,
                              ),
                            ),
                          ),
                          title: Text(
                            'Episode ${index + 1}',
                            style: TextStyle(
                              color: modernTheme.textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${25 + (index % 10)}min',
                            style: TextStyle(
                              color: modernTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () {},
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
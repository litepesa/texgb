// lib/features/short_dramas/screens/short_dramas_screen.dart
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
    'For You',
    'Romance',
    'Drama',
    'Comedy',
    'Action',
    'Thriller',
    'Fantasy',
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
      backgroundColor: modernTheme.backgroundColor,
      body: Column(
        children: [
          // Category tabs
          Container(
            color: modernTheme.surfaceColor,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: modernTheme.primaryColor,
              unselectedLabelColor: modernTheme.textSecondaryColor,
              indicatorColor: modernTheme.primaryColor,
              indicatorWeight: 3,
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
        // Featured dramas section
        SliverToBoxAdapter(
          child: _buildFeaturedSection(modernTheme),
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

  Widget _buildFeaturedSection(ModernThemeExtension modernTheme) {
    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Featured Dramas',
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
              itemBuilder: (context, index) => _buildFeaturedCard(index, modernTheme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(int index, ModernThemeExtension modernTheme) {
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

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
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
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'EP 1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dummyTitles[index % dummyTitles.length],
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber,
                size: 14,
              ),
              const SizedBox(width: 2),
              Text(
                '${(4.0 + (index % 10) * 0.1).toStringAsFixed(1)}',
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '${(index + 1) * 15}min',
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ],
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
    final rating = 3.5 + (index % 15) * 0.1;

    return GestureDetector(
      onTap: () => _showDramaDetails(dummyTitles[index], modernTheme),
      child: Container(
        decoration: BoxDecoration(
          color: modernTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                      child: Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dummyTitles[index],
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: modernTheme.primaryColor?.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'HD',
                            style: TextStyle(
                              color: modernTheme.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
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
                                  Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '4.5 • 2024 • 16 Episodes',
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
                                      backgroundColor: modernTheme.backgroundColor,
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
                              color: modernTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(4),
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
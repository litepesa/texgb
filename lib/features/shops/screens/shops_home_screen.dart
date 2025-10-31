// lib/features/shops/screens/shops_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/features/shops/routes/shop_routes.dart';

class ShopsHomeScreen extends ConsumerStatefulWidget {
  const ShopsHomeScreen({super.key});

  @override
  ConsumerState<ShopsHomeScreen> createState() => _ShopsHomeScreenState();
}

class _ShopsHomeScreenState extends ConsumerState<ShopsHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTab = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _selectedTab = ['all', 'featured', 'verified'][_tabController.index];
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Load shops from provider
    final List<Map<String, dynamic>> mockShops = _getMockShops();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Shops',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Open search
            },
            icon: const Icon(Icons.search, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              context.goToCart();
            },
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.white),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: const Text(
                      '3', // TODO: Get from cart provider
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.red,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Featured'),
            Tab(text: 'Verified'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildShopGrid(mockShops),
          _buildShopGrid(mockShops.where((s) => s['isFeatured'] == true).toList()),
          _buildShopGrid(mockShops.where((s) => s['isVerified'] == true).toList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.goToCreateShop();
        },
        backgroundColor: Colors.red,
        icon: const Icon(Icons.store, color: Colors.white),
        label: const Text(
          'Create Shop',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildShopGrid(List<Map<String, dynamic>> shops) {
    if (shops.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Refresh shops
        await Future.delayed(const Duration(seconds: 1));
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: shops.length,
        itemBuilder: (context, index) {
          return _buildShopCard(shops[index]);
        },
      ),
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shop) {
    return GestureDetector(
      onTap: () {
        context.goToShopDetail(shop['id']);
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Banner
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                image: shop['shopBanner'].isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(shop['shopBanner']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: shop['shopBanner'].isEmpty
                  ? const Center(
                      child: Icon(
                        Icons.store,
                        color: Colors.grey,
                        size: 48,
                      ),
                    )
                  : Stack(
                      children: [
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.3),
                              ],
                            ),
                          ),
                        ),
                        // Badges
                        if (shop['isFeatured'] || shop['isVerified'])
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Row(
                              children: [
                                if (shop['isFeatured'])
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 2),
                                        Text(
                                          'FEATURED',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (shop['isVerified'])
                                  const SizedBox(width: 4),
                                if (shop['isVerified'])
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.verified,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),

            // Shop Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Shop Name
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            shop['shopName'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Location
                    if (shop['location'].isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.grey,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              shop['location'],
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    const Spacer(),

                    // Stats
                    Row(
                      children: [
                        const Icon(
                          Icons.inventory_2,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${shop['productsCount']}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.people,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatCount(shop['followersCount']),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.store_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No shops found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Be the first to create a shop',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.goToCreateShop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Create Shop',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
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

  List<Map<String, dynamic>> _getMockShops() {
    return [
      {
        'id': 'shop1',
        'shopName': 'Fashion Hub',
        'shopBanner': '',
        'location': 'Nairobi, Kenya',
        'productsCount': 245,
        'followersCount': 12500,
        'isFeatured': true,
        'isVerified': true,
      },
      {
        'id': 'shop2',
        'shopName': 'Tech Store',
        'shopBanner': '',
        'location': 'Mombasa',
        'productsCount': 89,
        'followersCount': 5600,
        'isFeatured': false,
        'isVerified': true,
      },
      {
        'id': 'shop3',
        'shopName': 'Home Essentials',
        'shopBanner': '',
        'location': 'Kisumu',
        'productsCount': 156,
        'followersCount': 8900,
        'isFeatured': true,
        'isVerified': false,
      },
      {
        'id': 'shop4',
        'shopName': 'Beauty & Care',
        'shopBanner': '',
        'location': 'Nakuru',
        'productsCount': 78,
        'followersCount': 3400,
        'isFeatured': false,
        'isVerified': false,
      },
    ];
  }
}

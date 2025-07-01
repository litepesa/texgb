// lib/features/shop/screens/shops_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:textgb/constants.dart';

class ShopsListScreen extends StatefulWidget {
  const ShopsListScreen({super.key});

  @override
  State<ShopsListScreen> createState() => _ShopsListScreenState();
}

class _ShopsListScreenState extends State<ShopsListScreen> {
  final ScrollController _scrollController = ScrollController();
  
  final List<ShopData> shops = [
    ShopData(
      name: "Maya's Fashion Hub",
      category: "Fashion & Style",
      followers: "12.5K",
      isVerified: true,
      isLive: true,
      coverImage: "fashion_cover",
      profileImage: "maya_profile",
      description: "Trendy outfits for the modern woman",
      products: 89,
      rating: 4.8,
    ),
    ShopData(
      name: "TechZone Kenya",
      category: "Electronics",
      followers: "8.2K",
      isVerified: true,
      isLive: false,
      coverImage: "tech_cover",
      profileImage: "tech_profile",
      description: "Latest gadgets & accessories",
      products: 156,
      rating: 4.9,
    ),
    ShopData(
      name: "Mama's Kitchen",
      category: "Food & Snacks",
      followers: "15.1K",
      isVerified: false,
      isLive: true,
      coverImage: "food_cover",
      profileImage: "mama_profile",
      description: "Homemade treats & local delicacies",
      products: 45,
      rating: 4.7,
    ),
    ShopData(
      name: "Urban Beauty",
      category: "Beauty & Care",
      followers: "6.8K",
      isVerified: true,
      isLive: false,
      coverImage: "beauty_cover",
      profileImage: "beauty_profile",
      description: "Natural skincare & makeup",
      products: 67,
      rating: 4.6,
    ),
    ShopData(
      name: "Fitness Corner",
      category: "Sports & Fitness",
      followers: "4.3K",
      isVerified: false,
      isLive: true,
      coverImage: "fitness_cover",
      profileImage: "fitness_profile",
      description: "Quality gym equipment & supplements",
      products: 78,
      rating: 4.5,
    ),
    ShopData(
      name: "Home Essentials",
      category: "Home & Living",
      followers: "9.7K",
      isVerified: true,
      isLive: false,
      coverImage: "home_cover",
      profileImage: "home_profile",
      description: "Everything for your perfect home",
      products: 134,
      rating: 4.8,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Quick Categories
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Browse by Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCategoryChip('All', Icons.grid_view, Colors.purple),
                        _buildCategoryChip('Fashion', Icons.checkroom, Colors.pink),
                        _buildCategoryChip('Electronics', Icons.devices, Colors.blue),
                        _buildCategoryChip('Beauty', Icons.face, Colors.orange),
                        _buildCategoryChip('Food', Icons.restaurant, Colors.green),
                        _buildCategoryChip('Sports', Icons.fitness_center, Colors.red),
                        _buildCategoryChip('Home', Icons.home, Colors.teal),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Live Shops Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 8),
                        SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Live Shops',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Shops List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final shop = shops[index];
                return _buildShopCard(shop);
              },
              childCount: shops.length,
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCard(ShopData shop) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cover Image with Live Indicator
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.primaries[shop.name.hashCode % Colors.primaries.length].withOpacity(0.3),
                  Colors.primaries[shop.name.hashCode % Colors.primaries.length].withOpacity(0.1),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(
              children: [
                if (shop.isLive)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 6),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Shop Profile Picture
                Positioned(
                  bottom: -20,
                  left: 20,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        shop.name[0],
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.primaries[shop.name.hashCode % Colors.primaries.length],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Shop Info
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                shop.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (shop.isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  color: Colors.blue,
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            shop.category,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${shop.followers} followers',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  shop.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    _buildStatChip(Icons.shopping_bag, '${shop.products} products'),
                    const SizedBox(width: 12),
                    _buildStatChip(Icons.star, '${shop.rating}'),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          Constants.individualShopScreen,
                          arguments: {
                            'shopName': shop.name,
                            'shopCategory': shop.category,
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366), // Green color
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      ),
                      child: const Text(
                        'Visit Shop',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class ShopData {
  final String name;
  final String category;
  final String followers;
  final bool isVerified;
  final bool isLive;
  final String coverImage;
  final String profileImage;
  final String description;
  final int products;
  final double rating;

  ShopData({
    required this.name,
    required this.category,
    required this.followers,
    required this.isVerified,
    required this.isLive,
    required this.coverImage,
    required this.profileImage,
    required this.description,
    required this.products,
    required this.rating,
  });
}
// lib/features/shop/screens/shops_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class ShopsListScreen extends StatefulWidget {
  const ShopsListScreen({super.key});

  @override
  State<ShopsListScreen> createState() => _ShopsListScreenState();
}

class _ShopsListScreenState extends State<ShopsListScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'All';
  
  final List<String> categories = [
    'All',
    'Following',
    'Verified',
  ];
  
  final List<ShopData> shops = [
    ShopData(
      name: "Maya's Fashion Hub",
      category: "Fashion & Style",
      followers: "12.5K",
      isVerified: true,
      description: "Trendy outfits for the modern woman",
      products: 89,
      rating: 4.8,
      lastUpdate: "2m",
      profileColor: Colors.pink,
    ),
    ShopData(
      name: "TechZone Kenya",
      category: "Electronics",
      followers: "8.2K",
      isVerified: true,
      description: "Latest gadgets & accessories",
      products: 156,
      rating: 4.9,
      lastUpdate: "5m",
      profileColor: Colors.blue,
    ),
    ShopData(
      name: "Mama's Kitchen",
      category: "Food & Snacks",
      followers: "15.1K",
      isVerified: false,
      description: "Homemade treats & local delicacies",
      products: 45,
      rating: 4.7,
      lastUpdate: "1m",
      profileColor: Colors.orange,
    ),
    ShopData(
      name: "Urban Beauty",
      category: "Beauty & Care",
      followers: "6.8K",
      isVerified: true,
      description: "Natural skincare & makeup",
      products: 67,
      rating: 4.6,
      lastUpdate: "1h",
      profileColor: Colors.purple,
    ),
    ShopData(
      name: "Fitness Corner",
      category: "Sports & Fitness",
      followers: "4.3K",
      isVerified: false,
      description: "Quality gym equipment & supplements",
      products: 78,
      rating: 4.5,
      lastUpdate: "30m",
      profileColor: Colors.green,
    ),
    ShopData(
      name: "Home Essentials",
      category: "Home & Living",
      followers: "9.7K",
      isVerified: true,
      description: "Everything for your perfect home",
      products: 134,
      rating: 4.8,
      lastUpdate: "2h",
      profileColor: Colors.teal,
    ),
    ShopData(
      name: "Street Style Co.",
      category: "Fashion & Style",
      followers: "7.1K",
      isVerified: false,
      description: "Urban streetwear and accessories",
      products: 52,
      rating: 4.4,
      lastUpdate: "4h",
      profileColor: Colors.indigo,
    ),
    ShopData(
      name: "Fresh Market",
      category: "Food & Snacks",
      followers: "11.3K",
      isVerified: true,
      description: "Fresh organic produce and groceries",
      products: 92,
      rating: 4.7,
      lastUpdate: "6h",
      profileColor: Colors.lightGreen,
    ),
  ];

  List<ShopData> get filteredShops {
    if (_selectedCategory == 'All') return shops;
    if (_selectedCategory == 'Verified') {
      return shops.where((shop) => shop.isVerified).toList();
    }
    if (_selectedCategory == 'Following') {
      // For demo purposes, return shops with followers > 10K
      // In real implementation, this would filter based on user's following list
      return shops.where((shop) => double.parse(shop.followers.replaceAll('K', '')) > 10).toList();
    }
    return shops;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: theme.surfaceColor,
      body: Column(
        children: [
          // Category filter tabs (WhatsApp-style)
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor!,
                  width: 0.5,
                ),
              ),
            ),
            child: SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = _selectedCategory == category;
                  return _buildCategoryTab(category, isSelected);
                },
              ),
            ),
          ),

          // Shops list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: filteredShops.length,
              itemBuilder: (context, index) {
                final shop = filteredShops[index];
                return _buildShopListItem(shop);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String category, bool isSelected) {
    final theme = context.modernTheme;
    final modernTheme = context.modernTheme;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 24),
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF25D366) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? modernTheme.primaryColor : theme.textSecondaryColor,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildShopListItem(ShopData shop) {
    final theme = context.modernTheme;
    
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          Constants.individualShopScreen,
          arguments: {
            'shopName': shop.name,
            'shopCategory': shop.category,
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Shop avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: shop.profileColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  shop.name[0],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: shop.profileColor,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Shop info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop name and verification
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          shop.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (shop.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 2),
                  
                  // Description and category
                  Text(
                    shop.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Stats row - only followers
                  Text(
                    '${shop.followers} followers',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTertiaryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Right side - Time
            Text(
              shop.lastUpdate,
              style: TextStyle(
                fontSize: 12,
                color: theme.textTertiaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShopData {
  final String name;
  final String category;
  final String followers;
  final bool isVerified;
  final String description;
  final int products;
  final double rating;
  final String lastUpdate;
  final Color profileColor;

  ShopData({
    required this.name,
    required this.category,
    required this.followers,
    required this.isVerified,
    required this.description,
    required this.products,
    required this.rating,
    required this.lastUpdate,
    required this.profileColor,
  });
}
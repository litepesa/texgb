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
  String _selectedCategory = 'All';
  
  final List<String> categories = [
    'All',
    'Fashion',
    'Electronics',
    'Beauty',
    'Food',
    'Sports',
    'Home',
  ];
  
  final List<ShopData> shops = [
    ShopData(
      name: "Maya's Fashion Hub",
      category: "Fashion & Style",
      followers: "12.5K",
      isVerified: true,
      hasFlashSale: true,
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
      hasFlashSale: false,
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
      hasFlashSale: true,
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
      hasFlashSale: false,
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
      hasFlashSale: true,
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
      hasFlashSale: false,
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
      hasFlashSale: false,
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
      hasFlashSale: false,
      description: "Fresh organic produce and groceries",
      products: 92,
      rating: 4.7,
      lastUpdate: "6h",
      profileColor: Colors.lightGreen,
    ),
  ];

  List<ShopData> get filteredShops {
    if (_selectedCategory == 'All') return shops;
    return shops.where((shop) => shop.category.contains(_selectedCategory)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Category filter tabs (WhatsApp-style)
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
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

          // Flash sale shops indicator
          if (filteredShops.any((shop) => shop.hasFlashSale))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.red[50],
              child: Row(
                children: [
                  Icon(
                    Icons.flash_on,
                    color: Colors.red[600],
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${filteredShops.where((shop) => shop.hasFlashSale).length} Shops have Flash sales',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
            color: isSelected ? const Color(0xFF00A884) : Colors.grey[600],
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildShopListItem(ShopData shop) {
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
              color: Colors.grey[100]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Shop avatar
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: shop.profileColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: shop.hasFlashSale ? Colors.red : Colors.transparent,
                      width: shop.hasFlashSale ? 2 : 0,
                    ),
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
                // Flash sale indicator
                if (shop.hasFlashSale)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.flash_on,
                        color: Colors.white,
                        size: 8,
                      ),
                    ),
                  ),
              ],
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
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
                      color: Colors.grey[600],
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
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            
            // Right side - Time and status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  shop.lastUpdate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                if (shop.hasFlashSale)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.flash_on,
                          color: Colors.white,
                          size: 8,
                        ),
                        SizedBox(width: 2),
                        Text(
                          'SALE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
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
  final bool hasFlashSale;
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
    required this.hasFlashSale,
    required this.description,
    required this.products,
    required this.rating,
    required this.lastUpdate,
    required this.profileColor,
  });
}
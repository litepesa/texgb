// lib/features/shops/screens/shop_products_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/features/shops/routes/shop_routes.dart';

class ShopProductsScreen extends ConsumerStatefulWidget {
  final String shopId;

  const ShopProductsScreen({
    super.key,
    required this.shopId,
  });

  @override
  ConsumerState<ShopProductsScreen> createState() => _ShopProductsScreenState();
}

class _ShopProductsScreenState extends ConsumerState<ShopProductsScreen> {
  String _sortBy = 'latest';

  @override
  Widget build(BuildContext context) {
    // TODO: Load products from provider
    final mockProducts = _getMockProducts();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'All Products',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            color: const Color(0xFF1A1A1A),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
              // TODO: Sort products
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'latest',
                child: Text('Latest', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'price_low',
                child: Text('Price: Low to High', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'price_high',
                child: Text('Price: High to Low', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'popular',
                child: Text('Most Popular', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemCount: mockProducts.length,
        itemBuilder: (context, index) {
          return _buildProductCard(mockProducts[index]);
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () {
        context.goToProductDetail(product['id']);
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.image, color: Colors.grey, size: 40),
                  ),
                  if (product['flashSale'])
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${product['discount']}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['description'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'KES ${product['price']}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (product['flashSale']) ...[
                        const SizedBox(width: 8),
                        Text(
                          'KES ${product['originalPrice']}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye, color: Colors.grey, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${product['views']}',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.favorite, color: Colors.grey, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${product['likes']}',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getMockProducts() {
    return List.generate(
      20,
      (index) => {
        'id': 'prod$index',
        'description': 'Product ${index + 1}',
        'price': (1000 + (index * 500)),
        'originalPrice': (1500 + (index * 500)),
        'flashSale': index % 3 == 0,
        'discount': 30,
        'views': 100 + (index * 10),
        'likes': 50 + (index * 5),
      },
    );
  }
}

// lib/features/shop/screens/individual_shop_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class IndividualShopScreen extends StatefulWidget {
  final String shopName;
  final String shopCategory;
  
  const IndividualShopScreen({
    super.key,
    required this.shopName,
    required this.shopCategory,
  });

  @override
  State<IndividualShopScreen> createState() => _IndividualShopScreenState();
}

class _IndividualShopScreenState extends State<IndividualShopScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  bool _isFollowing = false;
  int _cartItemCount = 0;
  int _currentProductIndex = 0;
  
  final List<ProductData> products = [
    ProductData(
      name: 'Vintage Denim Jacket',
      price: 'KES 2,500',
      originalPrice: 'KES 3,500',
      discount: '29%',
      rating: 4.8,
      reviews: 156,
      isLiked: false,
      isNew: true,
      isSale: true,
      description: 'Premium vintage denim jacket with distressed finish. Perfect for casual and street style looks.',
      colors: ['Blue', 'Black', 'Light Blue'],
      sizes: ['S', 'M', 'L', 'XL'],
      inStock: 15,
      images: 3,
    ),
    ProductData(
      name: 'Bohemian Summer Dress',
      price: 'KES 1,800',
      originalPrice: null,
      discount: null,
      rating: 4.9,
      reviews: 89,
      isLiked: true,
      isNew: false,
      isSale: false,
      description: 'Flowy bohemian summer dress with floral patterns. Made from breathable cotton blend.',
      colors: ['Floral', 'White', 'Navy'],
      sizes: ['XS', 'S', 'M', 'L'],
      inStock: 8,
      images: 4,
    ),
    ProductData(
      name: 'Leather Ankle Boots',
      price: 'KES 3,200',
      originalPrice: 'KES 4,000',
      discount: '20%',
      rating: 4.7,
      reviews: 234,
      isLiked: false,
      isNew: true,
      isSale: true,
      description: 'Genuine leather ankle boots with comfortable sole. Perfect for all-day wear.',
      colors: ['Black', 'Brown', 'Tan'],
      sizes: ['36', '37', '38', '39', '40', '41'],
      inStock: 12,
      images: 5,
    ),
    ProductData(
      name: 'Silk Scarf Collection',
      price: 'KES 800',
      originalPrice: null,
      discount: null,
      rating: 4.6,
      reviews: 67,
      isLiked: false,
      isNew: false,
      isSale: false,
      description: 'Luxury silk scarf with unique patterns. Can be worn multiple ways.',
      colors: ['Rose Gold', 'Navy', 'Emerald', 'Burgundy'],
      sizes: ['One Size'],
      inStock: 25,
      images: 2,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-screen product feed
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (index) {
              setState(() {
                _currentProductIndex = index;
              });
            },
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _buildProductTile(products[index]);
            },
          ),
          
          // Top overlay with shop info and actions
          _buildTopOverlay(),
          
          // Side actions (like, share, cart)
          _buildSideActions(),
          
          // Bottom product info overlay
          _buildBottomOverlay(),
        ],
      ),
    );
  }

  Widget _buildProductTile(ProductData product) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Main product image/video area
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey[300]!,
                  Colors.grey[500]!,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Placeholder for product image
                const Center(
                  child: Icon(
                    Icons.image,
                    size: 120,
                    color: Colors.white54,
                  ),
                ),
                
                // Image indicator dots
                if (product.images > 1)
                  Positioned(
                    top: 60,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        product.images,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: index == 0 ? Colors.white : Colors.white54,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // Badges overlay
                Positioned(
                  top: 80,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (product.discount != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '-${product.discount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Shop info
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        widget.shopName[0],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF25D366),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.shopName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '12.5K followers',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Follow button
            GestureDetector(
              onTap: () {
                setState(() {
                  _isFollowing = !_isFollowing;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: _isFollowing ? Colors.grey[800] : const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _isFollowing ? 'Following' : 'Follow',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideActions() {
    final currentProduct = products[_currentProductIndex];
    
    return Positioned(
      right: 12,
      bottom: 200,
      child: Column(
        children: [
          // Like button
          _buildActionButton(
            icon: currentProduct.isLiked ? Icons.favorite : Icons.favorite_border,
            color: currentProduct.isLiked ? Colors.red : Colors.white,
            label: '${currentProduct.reviews}',
            onTap: () {
              setState(() {
                currentProduct.isLiked = !currentProduct.isLiked;
              });
            },
          ),
          
          const SizedBox(height: 20),
          
          // Share button
          _buildActionButton(
            icon: Icons.share,
            color: Colors.white,
            label: 'Share',
            onTap: () {},
          ),
          
          const SizedBox(height: 20),
          
          // Cart button
          _buildActionButton(
            icon: Icons.shopping_cart,
            color: Colors.white,
            label: _cartItemCount > 0 ? '$_cartItemCount' : '',
            onTap: () {},
            showBadge: _cartItemCount > 0,
          ),
          
          const SizedBox(height: 20),
          
          // Call button
          _buildActionButton(
            icon: Icons.phone,
            color: const Color(0xFF25D366),
            label: 'Call',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                if (showBadge)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomOverlay() {
    final currentProduct = products[_currentProductIndex];
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: 24,
          left: 16,
          right: 80, // Space for side actions
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
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
            // Product name and price
            Text(
              currentProduct.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 8),
            
            // Price row
            Row(
              children: [
                Text(
                  currentProduct.price,
                  style: const TextStyle(
                    color: Color(0xFF25D366),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (currentProduct.originalPrice != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    currentProduct.originalPrice!,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Rating and stock
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${currentProduct.rating} (${currentProduct.reviews} reviews)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '${currentProduct.inStock} in stock',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              currentProduct.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 16),
            
            // Colors and sizes
            if (currentProduct.colors.isNotEmpty) ...[
              Text(
                'Colors: ${currentProduct.colors.join(', ')}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
            ],
            
            if (currentProduct.sizes.isNotEmpty) ...[
              Text(
                'Sizes: ${currentProduct.sizes.join(', ')}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Add to cart button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _cartItemCount++;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${currentProduct.name} added to cart'),
                      duration: const Duration(seconds: 1),
                      backgroundColor: const Color(0xFF25D366),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Add to Cart',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductData {
  final String name;
  final String price;
  final String? originalPrice;
  final String? discount;
  final double rating;
  final int reviews;
  bool isLiked;
  final bool isNew;
  final bool isSale;
  final String description;
  final List<String> colors;
  final List<String> sizes;
  final int inStock;
  final int images;

  ProductData({
    required this.name,
    required this.price,
    this.originalPrice,
    this.discount,
    required this.rating,
    required this.reviews,
    required this.isLiked,
    required this.isNew,
    required this.isSale,
    required this.description,
    required this.colors,
    required this.sizes,
    required this.inStock,
    required this.images,
  });
}
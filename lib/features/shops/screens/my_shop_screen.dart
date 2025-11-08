// lib/features/shops/screens/my_shop_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/shops/routes/shop_routes.dart';

class MyShopScreen extends ConsumerWidget {
  const MyShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Load shop from provider
    final mockShop = _getMockShop();
    final mockStats = _getMockStats();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'My Shop',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => context.goToEditShop(),
            icon: const Icon(Icons.edit, color: Colors.white),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF1A1A1A),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Text('Share Shop', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Text('Settings', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Shop Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.withValues(alpha: 0.2), Colors.pink.withValues(alpha: 0.2)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mockShop['shopName'],
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mockShop['location'],
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    if (mockShop['isVerified'])
                      const Icon(Icons.verified, color: Colors.blue, size: 24),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('Products', '${mockStats['products']}', Icons.inventory_2, Colors.blue, () => context.goToInventory()),
              _buildStatCard('Orders', '${mockStats['orders']}', Icons.shopping_bag, Colors.green, () => context.goToSellerOrders()),
              _buildStatCard('Revenue', 'KES ${mockStats['revenue']}', Icons.attach_money, Colors.amber, () => context.goToEarnings()),
              _buildStatCard('Followers', '${mockStats['followers']}', Icons.people, Colors.purple, null),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            'Add Product',
            'List a new product in your shop',
            Icons.add_box,
            Colors.red,
            () => context.goToAddProduct(),
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            'Manage Inventory',
            'Update stock and prices',
            Icons.inventory,
            Colors.orange,
            () => context.goToInventory(),
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            'View Orders',
            'Process customer orders',
            Icons.list_alt,
            Colors.green,
            () => context.goToSellerOrders(),
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            'Earnings & Payouts',
            'Track your revenue',
            Icons.account_balance_wallet,
            Colors.blue,
            () => context.goToEarnings(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getMockShop() {
    return {
      'shopName': 'Fashion Hub',
      'location': 'Nairobi, Kenya',
      'isVerified': true,
    };
  }

  Map<String, dynamic> _getMockStats() {
    return {
      'products': 245,
      'orders': 128,
      'revenue': 450000,
      'followers': 12500,
    };
  }
}

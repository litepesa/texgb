// lib/features/shops/screens/inventory_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/shops/routes/shop_routes.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mockProducts = List.generate(10, (i) => {'id': 'p$i', 'name': 'Product $i', 'price': 1000 + (i * 500), 'stock': 10 + i});

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Inventory', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: () => context.goToAddProduct(),
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockProducts.length,
        itemBuilder: (context, index) {
          final product = mockProducts[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('KES ${product['price']}', style: const TextStyle(color: Colors.red)),
                      Text('Stock: ${product['stock']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.goToEditProduct(product['id'] as String),
                  icon: const Icon(Icons.edit, color: Colors.white),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

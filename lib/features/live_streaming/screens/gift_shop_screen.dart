// lib/features/live_streaming/screens/gift_shop_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gift coin packages that users can purchase
class GiftPackage {
  final String id;
  final String name;
  final int coins;
  final double price;
  final String? bonusText;
  final bool isPopular;
  final Color color;

  const GiftPackage({
    required this.id,
    required this.name,
    required this.coins,
    required this.price,
    this.bonusText,
    this.isPopular = false,
    required this.color,
  });

  String get priceText => 'KES ${price.toStringAsFixed(0)}';
  String get coinsText => '$coins Coins';
}

class GiftShopScreen extends ConsumerStatefulWidget {
  const GiftShopScreen({super.key});

  @override
  ConsumerState<GiftShopScreen> createState() => _GiftShopScreenState();
}

class _GiftShopScreenState extends ConsumerState<GiftShopScreen> {
  // Mock gift packages
  final List<GiftPackage> _packages = const [
    GiftPackage(
      id: 'starter',
      name: 'Starter Pack',
      coins: 100,
      price: 100,
      color: Colors.blue,
    ),
    GiftPackage(
      id: 'basic',
      name: 'Basic Pack',
      coins: 500,
      price: 450,
      bonusText: '+50 Bonus',
      color: Colors.green,
    ),
    GiftPackage(
      id: 'popular',
      name: 'Popular Pack',
      coins: 1000,
      price: 850,
      bonusText: '+150 Bonus',
      isPopular: true,
      color: Colors.purple,
    ),
    GiftPackage(
      id: 'mega',
      name: 'Mega Pack',
      coins: 2500,
      price: 2000,
      bonusText: '+500 Bonus',
      color: Colors.orange,
    ),
    GiftPackage(
      id: 'super',
      name: 'Super Pack',
      coins: 5000,
      price: 3800,
      bonusText: '+1200 Bonus',
      color: Colors.red,
    ),
    GiftPackage(
      id: 'ultimate',
      name: 'Ultimate Pack',
      coins: 10000,
      price: 7000,
      bonusText: '+3000 Bonus',
      color: Colors.amber,
    ),
  ];

  double _currentBalance = 250; // Mock balance

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Gift Shop',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Transaction history
          IconButton(
            onPressed: () {
              // TODO: Show transaction history
            },
            icon: const Icon(Icons.history, color: Colors.white),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Balance card
          _buildBalanceCard(),

          const SizedBox(height: 24),

          // Info banner
          _buildInfoBanner(),

          const SizedBox(height: 24),

          // Package grid
          const Text(
            'Coin Packages',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _packages.length,
            itemBuilder: (context, index) {
              final package = _packages[index];
              return _buildPackageCard(package);
            },
          ),

          const SizedBox(height: 24),

          // Benefits section
          _buildBenefitsSection(),

          const SizedBox(height: 24),

          // Payment methods
          _buildPaymentMethods(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Balance',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_currentBalance Coins',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: Colors.white,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.blue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '1 Coin = 1 KES. Send gifts to your favorite streamers!',
              style: TextStyle(
                color: Colors.blue[100],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(GiftPackage package) {
    return GestureDetector(
      onTap: () => _purchasePackage(package),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  package.color.withOpacity(0.3),
                  package.color.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: package.isPopular
                    ? package.color
                    : package.color.withOpacity(0.3),
                width: package.isPopular ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Coin icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: package.color.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.stars,
                      color: package.color,
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Coins amount
                  Text(
                    package.coinsText,
                    style: TextStyle(
                      color: package.color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Package name
                  Text(
                    package.name,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),

                  if (package.bonusText != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Text(
                        package.bonusText!,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Price button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: package.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      package.priceText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Popular badge
          if (package.isPopular)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'POPULAR',
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
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Why Buy Coins?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(
            icon: Icons.favorite,
            title: 'Support Creators',
            description: 'Help your favorite streamers earn revenue',
          ),
          const SizedBox(height: 12),
          _buildBenefitItem(
            icon: Icons.emoji_events,
            title: 'Get Noticed',
            description: 'Send gifts to stand out in the chat',
          ),
          const SizedBox(height: 12),
          _buildBenefitItem(
            icon: Icons.trending_up,
            title: 'Earn Bonuses',
            description: 'Bigger packages come with bonus coins',
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.purple, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Methods',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildPaymentMethodChip('M-Pesa', Icons.phone_android, Colors.green),
            _buildPaymentMethodChip('Card', Icons.credit_card, Colors.blue),
            _buildPaymentMethodChip('PayPal', Icons.paypal, Colors.indigo),
            _buildPaymentMethodChip('Bank', Icons.account_balance, Colors.orange),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _purchasePackage(GiftPackage package) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF0D0D0D),
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 24),

            // Package icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    package.color.withOpacity(0.3),
                    package.color.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.stars,
                color: package.color,
                size: 48,
              ),
            ),

            const SizedBox(height: 20),

            // Package details
            Text(
              package.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              package.coinsText,
              style: TextStyle(
                color: package.color,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (package.bonusText != null) ...[
              const SizedBox(height: 8),
              Text(
                package.bonusText!,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Price breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    package.priceText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Purchase button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _processPurchase(package);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: package.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_cart, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Purchase ${package.priceText}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _processPurchase(GiftPackage package) {
    // TODO: Integrate with payment gateway
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Processing purchase of ${package.name}...'),
        backgroundColor: package.color,
        duration: const Duration(seconds: 2),
      ),
    );

    // Mock success
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _currentBalance += package.coins;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${package.coinsText} added to your balance!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }
}

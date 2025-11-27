// lib/features/marketplace/widgets/marketplace_boost_tab_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/wallet/providers/wallet_providers.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';

class MarketplaceBoostTabWidget extends ConsumerStatefulWidget {
  final AnimationController rocketAnimationController;
  final Animation<double> rocketAnimation;
  final Function(String boostTier) onBoostPost; // Now accepts boost tier parameter

  const MarketplaceBoostTabWidget({
    super.key,
    required this.rocketAnimationController,
    required this.rocketAnimation,
    required this.onBoostPost,
  });

  @override
  ConsumerState<MarketplaceBoostTabWidget> createState() => _MarketplaceBoostTabWidgetState();
}

class _MarketplaceBoostTabWidgetState extends ConsumerState<MarketplaceBoostTabWidget> {
  String? _selectedTier;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;

    // Watch wallet balance
    final walletState = ref.watch(walletProvider);
    final coinsBalance = walletState.value?.wallet?.coinsBalance ?? 0;
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wallet Balance Card
          if (isAuthenticated) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    modernTheme.primaryColor!.withOpacity(0.1),
                    modernTheme.primaryColor!.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: modernTheme.primaryColor!.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: modernTheme.primaryColor!.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: modernTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wallet Balance',
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'KES $coinsBalance',
                          style: TextStyle(
                            color: modernTheme.textColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // Navigate to wallet top-up
                      Navigator.pushNamed(context, '/wallet');
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text('Top Up'),
                    style: TextButton.styleFrom(
                      foregroundColor: modernTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Enhanced Boost Header
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  modernTheme.primaryColor!,
                  modernTheme.primaryColor!.withOpacity(0.7),
                  modernTheme.primaryColor!.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: modernTheme.primaryColor!.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: widget.rocketAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, -widget.rocketAnimation.value * 30),
                      child: Transform.rotate(
                        angle: widget.rocketAnimation.value * 0.8,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.rocket_launch,
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  '🚀 BOOST YOUR POST',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Get maximum visibility in 72 hours',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Reach millions of viewers',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Choose Your Boost Package',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Boost Options with CORRECT pricing and view ranges
          _buildBoostOption(
            tier: 'basic',
            title: 'Basic Boost',
            duration: '72 hours',
            price: 'KES 99',
            viewRange: '1,713 - 10K views',
            icon: Icons.flash_on,
            color: Colors.orange,
            modernTheme: modernTheme,
            coinsBalance: coinsBalance,
            isPopular: false,
          ),
          _buildBoostOption(
            tier: 'standard',
            title: 'Standard Boost',
            duration: '72 hours',
            price: 'KES 999',
            viewRange: '17,138 - 100K views',
            icon: Icons.rocket_launch,
            color: Colors.red,
            modernTheme: modernTheme,
            coinsBalance: coinsBalance,
            isPopular: true,
          ),
          _buildBoostOption(
            tier: 'advanced',
            title: 'Advanced Boost',
            duration: '72 hours',
            price: 'KES 9,999',
            viewRange: '171,388 - 1M views',
            icon: Icons.star,
            color: Colors.purple,
            modernTheme: modernTheme,
            coinsBalance: coinsBalance,
            isPopular: false,
          ),

          const SizedBox(height: 24),

          // Benefits Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: modernTheme.primaryColor!.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: modernTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Why Boost Your Post?',
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildBenefitItem(
                  'Reach guaranteed view targets',
                  Icons.visibility,
                  modernTheme,
                ),
                _buildBenefitItem(
                  'Get featured on explore page',
                  Icons.explore,
                  modernTheme,
                ),
                _buildBenefitItem(
                  'Increase engagement & followers',
                  Icons.people,
                  modernTheme,
                ),
                _buildBenefitItem(
                  'Priority in search results',
                  Icons.search,
                  modernTheme,
                ),
                _buildBenefitItem(
                  'Active for full 72 hours',
                  Icons.schedule,
                  modernTheme,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Payment secured notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: modernTheme.primaryColor!.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  color: modernTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure Payment',
                        style: TextStyle(
                          color: modernTheme.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Coins will be deducted from your wallet balance',
                        style: TextStyle(
                          color: modernTheme.textSecondaryColor,
                          fontSize: 12,
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

  Widget _buildBenefitItem(
    String text,
    IconData icon,
    ModernThemeExtension modernTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: modernTheme.primaryColor!.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: modernTheme.primaryColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoostOption({
    required String tier,
    required String title,
    required String duration,
    required String price,
    required String viewRange,
    required IconData icon,
    required Color color,
    required ModernThemeExtension modernTheme,
    required int coinsBalance,
    bool isPopular = false,
  }) {
    // Extract price value for comparison
    final priceValue = int.parse(price.replaceAll(RegExp(r'[^0-9]'), ''));
    final canAfford = coinsBalance >= priceValue;
    final isSelected = _selectedTier == tier;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? color.withOpacity(0.5)
                    : isPopular
                        ? color.withOpacity(0.3)
                        : Colors.transparent,
                width: isSelected ? 2 : (isPopular ? 2 : 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: isPopular
                      ? color.withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: isPopular ? 15 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 12),

                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and Price
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    color: modernTheme.textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Text(
                                price,
                                style: TextStyle(
                                  color: modernTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // View Range
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              viewRange,
                              style: TextStyle(
                                color: color,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Duration
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                color: modernTheme.textSecondaryColor,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Duration: $duration',
                                style: TextStyle(
                                  color: modernTheme.textSecondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Insufficient balance warning
                if (!canAfford)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Insufficient balance. Top up your wallet.',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Select button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canAfford && !_isProcessing
                        ? () {
                            setState(() {
                              _selectedTier = tier;
                              _isProcessing = true;
                            });

                            // Trigger rocket animation
                            widget.rocketAnimationController.forward().then((_) {
                              widget.rocketAnimationController.reset();
                            });

                            // Call the boost function
                            widget.onBoostPost(tier);

                            // Reset processing state after a delay
                            Future.delayed(const Duration(seconds: 2), () {
                              if (mounted) {
                                setState(() {
                                  _isProcessing = false;
                                });
                              }
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAfford ? color : Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                    ),
                    child: _isProcessing && isSelected
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            canAfford ? 'Select & Boost' : 'Insufficient Balance',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Popular badge
          if (isPopular)
            Positioned(
              top: -5,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'MOST POPULAR',
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
    );
  }
}

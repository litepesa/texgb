// lib/features/wallet/screens/wallet_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  bool _balanceVisible = true;
  int _selectedTab = 0; // 0: Overview, 1: Gifts, 2: Coins

  // Empty gifts list for new user experience
  final List<ReceivedGift> _receivedGifts = [];

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: modernTheme.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(modernTheme),
            _buildTabBar(modernTheme),
            Expanded(
              child: _buildTabContent(modernTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ModernThemeExtension modernTheme) {
    final totalGiftValue = _receivedGifts
        .where((gift) => !gift.isConverted)
        .fold(0, (sum, gift) => sum + gift.value);
    final convertedValue = _receivedGifts
        .where((gift) => gift.isConverted)
        .fold(0, (sum, gift) => sum + gift.value);

    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Main Balance Card - Weibao Coins
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  modernTheme.primaryColor!,
                  modernTheme.primaryColor!.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: modernTheme.primaryColor!.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        const Text(
                          'Weibao Coins',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _balanceVisible = !_balanceVisible;
                        });
                      },
                      child: Icon(
                        _balanceVisible ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                        color: Colors.white.withOpacity(0.8),
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _balanceVisible ? '0' : '••••••',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.gift,
                      color: Colors.white.withOpacity(0.8),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      totalGiftValue > 0 ? '$totalGiftValue coins from gifts' : 'No gift coins yet',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Cash Balance & Creator Bonus Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: modernTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: modernTheme.dividerColor!.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              CupertinoIcons.money_dollar,
                              color: Colors.green,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Cash Balance',
                            style: TextStyle(
                              color: modernTheme.textSecondaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'KES 0.00',
                        style: TextStyle(
                          color: modernTheme.textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: modernTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: modernTheme.dividerColor!.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '⭐',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Creator Bonus',
                            style: TextStyle(
                              color: modernTheme.textSecondaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '0 coins',
                        style: TextStyle(
                          color: modernTheme.textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: modernTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: modernTheme.dividerColor!.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabItem('Overview', 0, CupertinoIcons.home, modernTheme),
          ),
          Expanded(
            child: _buildTabItem('Gifts', 1, CupertinoIcons.gift, modernTheme),
          ),
          Expanded(
            child: _buildTabItem('Coins', 2, CupertinoIcons.money_dollar_circle, modernTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index, IconData icon, ModernThemeExtension modernTheme) {
    final isSelected = _selectedTab == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? modernTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : modernTheme.textSecondaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : modernTheme.textSecondaryColor,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(ModernThemeExtension modernTheme) {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab(modernTheme);
      case 1:
        return _buildGiftsTab(modernTheme);
      case 2:
        return _buildCoinsTab(modernTheme);
      default:
        return _buildOverviewTab(modernTheme);
    }
  }

  Widget _buildOverviewTab(ModernThemeExtension modernTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: CupertinoIcons.money_dollar_circle,
                  title: 'Convert Gifts',
                  subtitle: 'To cash',
                  color: Colors.green,
                  modernTheme: modernTheme,
                  onTap: () => setState(() => _selectedTab = 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: CupertinoIcons.plus_circle,
                  title: 'Buy Coins',
                  subtitle: 'Top up',
                  color: Colors.amber,
                  modernTheme: modernTheme,
                  onTap: () => setState(() => _selectedTab = 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: CupertinoIcons.arrow_down_to_line,
                  title: 'Withdraw',
                  subtitle: 'M-Pesa',
                  color: Colors.blue,
                  modernTheme: modernTheme,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent Activity
          Text(
            'Recent Activity',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // Show recent gifts and transactions
          ..._receivedGifts.take(3).map((gift) => _buildActivityItem(gift, modernTheme)),

          const SizedBox(height: 16),

          // Creator Bonus Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade600,
                  Colors.purple.shade700,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Creator Bonus Program',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Get verified to start earning',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  CupertinoIcons.arrow_right,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftsTab(ModernThemeExtension modernTheme) {
    final unconvertedGifts = _receivedGifts.where((gift) => !gift.isConverted).toList();
    final convertedGifts = _receivedGifts.where((gift) => gift.isConverted).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Convert All Button
          if (unconvertedGifts.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              child:               ElevatedButton(
                onPressed: () {
                  _showConvertAllDialog(modernTheme);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Convert All Gifts to Cash (${unconvertedGifts.fold(0, (sum, gift) => sum + gift.value)} coins)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Unconverted Gifts
          if (unconvertedGifts.isNotEmpty) ...[
            Text(
              'Pending Conversion',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...unconvertedGifts.map((gift) => _buildGiftItem(gift, modernTheme, true)),
            const SizedBox(height: 24),
          ],

          // Converted Gifts
          if (convertedGifts.isNotEmpty) ...[
            Text(
              'Converted to Cash',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...convertedGifts.map((gift) => _buildGiftItem(gift, modernTheme, false)),
          ],

          if (unconvertedGifts.isEmpty && convertedGifts.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  const Text('🎁', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    'No gifts received yet',
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCoinsTab(ModernThemeExtension modernTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Balance
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade600, Colors.orange.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                const Text(
                  '0 Weibao Coins',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Buy coins to send virtual gifts',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Buy More Coins',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Coin packages
          ...coinPackages.map((package) => _buildCoinPackage(package, modernTheme)),
        ],
      ),
    );
  }

  Widget _buildGiftItem(ReceivedGift gift, ModernThemeExtension modernTheme, bool canConvert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: modernTheme.dividerColor!.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: canConvert ? Colors.amber.withOpacity(0.2) : Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(gift.giftEmoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gift.giftName,
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'From ${gift.sender}',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatTimestamp(gift.timestamp),
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${gift.value} coins',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              if (canConvert)
                GestureDetector(
                  onTap: () => _convertSingleGift(gift),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Convert',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Converted',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(ReceivedGift gift, ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: modernTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: modernTheme.dividerColor!.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Text(gift.giftEmoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${gift.giftName} from ${gift.sender}',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatTimestamp(gift.timestamp),
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${gift.value} coins',
            style: TextStyle(
              color: gift.isConverted ? Colors.green : Colors.amber.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinPackage(CoinPackage package, ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: package.isPopular ? Colors.orange : modernTheme.dividerColor!.withOpacity(0.3),
          width: package.isPopular ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('🪙', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${package.coins} Coins',
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (package.isPopular) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'POPULAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (package.bonus > 0)
                  Text(
                    '+${package.bonus} bonus coins',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'KES ${package.price}',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => _buyCoins(package),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Buy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required ModernThemeExtension modernTheme,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title feature coming soon!')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: modernTheme.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: modernTheme.dividerColor!.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showConvertAllDialog(ModernThemeExtension modernTheme) {
    final unconvertedGifts = _receivedGifts.where((gift) => !gift.isConverted).toList();
    final totalValue = unconvertedGifts.fold(0, (sum, gift) => sum + gift.value);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: modernTheme.backgroundColor,
        title: Text(
          'Convert All Gifts',
          style: TextStyle(color: modernTheme.textColor),
        ),
        content: Text(
          'Convert ${unconvertedGifts.length} gifts to ${totalValue} coins for cash withdrawal?',
          style: TextStyle(color: modernTheme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                for (var gift in unconvertedGifts) {
                  gift.isConverted = true;
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Converted ${totalValue} coins to cash!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Convert', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _convertSingleGift(ReceivedGift gift) {
    setState(() {
      gift.isConverted = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Converted ${gift.giftName} (${gift.value} coins) to cash!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _buyCoins(CoinPackage package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buy Coins'),
        content: Text('Purchase ${package.coins} coins for KES ${package.price}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Successfully purchased ${package.coins} coins!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Buy'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// Data Models
class ReceivedGift {
  final String id;
  final String giftName;
  final String giftEmoji;
  final int value; // Value in Weibao coins
  final String sender;
  final DateTime timestamp;
  bool isConverted;

  ReceivedGift({
    required this.id,
    required this.giftName,
    required this.giftEmoji,
    required this.value,
    required this.sender,
    required this.timestamp,
    required this.isConverted,
  });
}

class CoinPackage {
  final int coins;
  final int bonus;
  final int price; // Price in KES
  final bool isPopular;

  CoinPackage({
    required this.coins,
    required this.bonus,
    required this.price,
    this.isPopular = false,
  });
}

// Dummy coin packages
final List<CoinPackage> coinPackages = [
  CoinPackage(coins: 100, bonus: 0, price: 50),
  CoinPackage(coins: 500, bonus: 50, price: 200, isPopular: true),
  CoinPackage(coins: 1000, bonus: 150, price: 350),
  CoinPackage(coins: 2500, bonus: 500, price: 800),
  CoinPackage(coins: 5000, bonus: 1200, price: 1500),
  CoinPackage(coins: 10000, bonus: 3000, price: 2800),
];
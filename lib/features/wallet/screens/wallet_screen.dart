// lib/features/wallet/screens/wallet_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/wallet/providers/wallet_providers.dart';
import 'package:textgb/features/wallet/widgets/coin_packages_widget.dart';
import 'package:textgb/features/wallet/models/wallet_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  bool _balanceVisible = true;

  // Helper method to get safe theme with fallback
  ModernThemeExtension _getSafeTheme(BuildContext context) {
    return Theme.of(context).extension<ModernThemeExtension>() ?? 
        ModernThemeExtension(
          primaryColor: const Color(0xFFFE2C55),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceColor: Theme.of(context).cardColor,
          textColor: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
          textSecondaryColor: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey[600],
          dividerColor: Theme.of(context).dividerColor,
          textTertiaryColor: Colors.grey[400],
          surfaceVariantColor: Colors.grey[100],
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getSafeTheme(context);
    final walletState = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: theme.surfaceColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(walletProvider.notifier).refresh();
          },
          color: theme.primaryColor ?? const Color(0xFFFE2C55),
          backgroundColor: theme.surfaceColor,
          child: walletState.when(
            loading: () => Center(
              child: CircularProgressIndicator(
                color: theme.primaryColor ?? const Color(0xFFFE2C55),
                strokeWidth: 3,
              ),
            ),
            error: (error, stackTrace) => _buildErrorState(error.toString(), theme),
            data: (state) => _buildWalletContent(state, theme),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, ModernThemeExtension theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade600,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to load wallet',
              style: TextStyle(
                color: theme.textColor ?? Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: TextStyle(
                color: theme.textSecondaryColor ?? Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => ref.read(walletProvider.notifier).refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor ?? const Color(0xFFFE2C55),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Try Again',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletContent(WalletState walletState, ModernThemeExtension theme) {
    final wallet = walletState.wallet;
    final transactions = walletState.transactions;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coins Balance Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.teal.shade600,
                  Colors.blue.shade700,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.teal.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.stars,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Coins Balance',
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.stars,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _balanceVisible 
                        ? (wallet?.coinsBalance.toString() ?? '0') 
                        : '••••••',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'coins',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_balanceVisible && wallet != null) ...[
                  Text(
                    '≈ ${wallet.formattedKESEquivalent}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      wallet?.hasBalance == true 
                        ? CupertinoIcons.checkmark_circle
                        : CupertinoIcons.minus_circle,
                      color: Colors.white.withOpacity(0.7),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      wallet?.hasBalance == true 
                        ? 'Ready to send amazing gifts'
                        : 'Buy coins to send gifts',
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

          const SizedBox(height: 24),

          // Quick Actions
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.card_giftcard,
                  title: 'Buy Coins',
                  subtitle: 'Get coins for gifts',
                  color: Colors.green,
                  onTap: () => CoinPackagesWidget.show(context),
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.history,
                  title: 'History',
                  subtitle: 'View transactions',
                  color: Colors.blue,
                  onTap: () => _showTransactionHistory(context, transactions, theme),
                  theme: theme,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent Transactions Section
          if (transactions.isNotEmpty) ...[
            Text(
              'Recent Transactions',
              style: TextStyle(
                color: theme.textColor ?? Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: theme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (theme.dividerColor ?? Colors.grey[300]!).withOpacity(0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  ...transactions.take(5).map((transaction) => 
                    _buildTransactionItem(transaction, theme)),
                  if (transactions.length > 5)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showTransactionHistory(context, transactions, theme),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'View All Transactions',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.primaryColor ?? const Color(0xFFFE2C55),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            // Empty state
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (theme.dividerColor ?? Colors.grey[300]!).withOpacity(0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.card_giftcard_outlined,
                    size: 48,
                    color: theme.textTertiaryColor ?? Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Transactions Yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor ?? Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Buy coins to start sending amazing gifts',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textSecondaryColor ?? Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.blue.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'About Coins',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• Use coins to send creators virtual gifts\n'
                  '• Unlock premium episodes (mini dramas) with coins\n'
                  '• Some coin purchases are processed manually by admin. Updated within 10 minutes\n'
                  '• Choose from 3 coin packages: 100, 500, or 1000 coins',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required ModernThemeExtension theme,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (theme.dividerColor ?? Colors.grey[300]!).withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: theme.textColor ?? Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: theme.textSecondaryColor ?? Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(WalletTransaction transaction, ModernThemeExtension theme) {
    final isCredit = transaction.isCredit;
    
    IconData icon;
    Color iconColor;
    
    switch (transaction.type) {
      case 'coin_purchase':
        icon = Icons.add_shopping_cart;
        iconColor = Colors.green;
        break;
      case 'gift_sent':
        icon = Icons.card_giftcard;
        iconColor = Colors.pink;
        break;
      case 'admin_credit':
        icon = Icons.admin_panel_settings;
        iconColor = Colors.purple;
        break;
      default:
        icon = Icons.account_balance_wallet;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: (theme.dividerColor ?? Colors.grey[300]!).withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.displayTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textColor ?? Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textSecondaryColor ?? Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTransactionDate(transaction.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textSecondaryColor ?? Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction.formattedAmount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCredit ? Colors.green : Colors.red,
                ),
              ),
              if (transaction.paidAmount != null) ...[
                const SizedBox(height: 2),
                Text(
                  'KES ${transaction.paidAmount!.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textSecondaryColor ?? Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showTransactionHistory(BuildContext context, List<WalletTransaction> transactions, ModernThemeExtension theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.textTertiaryColor ?? Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaction History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor ?? Colors.black,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.close,
                          color: theme.primaryColor ?? const Color(0xFFFE2C55),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.card_giftcard_outlined,
                            size: 64,
                            color: theme.textTertiaryColor ?? Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.textSecondaryColor ?? Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return _buildTransactionItem(transaction, theme);
                      },
                    ),
            ),
            // Load more button if needed
            if (transactions.length >= 10)
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(walletProvider.notifier).loadMoreTransactions();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor ?? const Color(0xFFFE2C55),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text('Load More'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTransactionDate(String timestamp) {
    try {
      final dateTime = DateTime.fromMicrosecondsSinceEpoch(int.parse(timestamp));
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
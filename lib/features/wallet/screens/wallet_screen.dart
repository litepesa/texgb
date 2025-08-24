// lib/features/wallet/screens/wallet_screen.dart (Updated)
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/wallet/providers/wallet_providers.dart';
import 'package:textgb/features/wallet/widgets/top_up_info_widget.dart';
import 'package:textgb/features/wallet/models/wallet_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  bool _balanceVisible = true;

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final walletState = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: modernTheme.surfaceColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(walletProvider.notifier).refresh();
          },
          child: walletState.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => _buildErrorState(error.toString(), modernTheme),
            data: (state) => _buildWalletContent(state, modernTheme),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, ModernThemeExtension modernTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load wallet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: modernTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: modernTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(walletProvider.notifier).refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletContent(WalletState walletState, ModernThemeExtension modernTheme) {
    final wallet = walletState.wallet;
    final transactions = walletState.transactions;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wallet Balance Card
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
                    const Text(
                      'Wallet Balance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
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
                  _balanceVisible 
                    ? (wallet?.formattedBalance ?? 'KES 0.00') 
                    : '••••••',
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
                      wallet?.hasBalance == true 
                        ? CupertinoIcons.checkmark_circle
                        : CupertinoIcons.minus_circle,
                      color: Colors.grey[300],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      wallet?.hasBalance == true 
                        ? 'Ready for purchases'
                        : 'No balance available',
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
                  icon: Icons.add,
                  title: 'Add Money',
                  subtitle: 'Top up wallet',
                  color: Colors.green,
                  onTap: () => TopUpInfoWidget.show(context),
                  modernTheme: modernTheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.history,
                  title: 'History',
                  subtitle: 'View transactions',
                  color: Colors.blue,
                  onTap: () => _showTransactionHistory(context, transactions, modernTheme),
                  modernTheme: modernTheme,
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
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: modernTheme.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: modernTheme.dividerColor!.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  ...transactions.take(5).map((transaction) => 
                    _buildTransactionItem(transaction, modernTheme)).toList(),
                  if (transactions.length > 5)
                    InkWell(
                      onTap: () => _showTransactionHistory(context, transactions, modernTheme),
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
                            color: modernTheme.primaryColor,
                            fontWeight: FontWeight.w600,
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
                color: modernTheme.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: modernTheme.dividerColor!.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: modernTheme.textSecondaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Transactions Yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: modernTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add money to your wallet to start making purchases',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: modernTheme.textSecondaryColor,
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
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade50,
                  Colors.blue.shade100,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Wallet Information',
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
                  '• Use your wallet balance to unlock premium episodes\n'
                  '• Some payments are processed manually by our admin team\n'
                  '• Balance updates may take upto 30 minutes after top-up\n'
                  '• Minimum top-up amount is KES 100',
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
    required ModernThemeExtension modernTheme,
  }) {
    return GestureDetector(
      onTap: onTap,
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
                color: modernTheme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(WalletTransaction transaction, ModernThemeExtension modernTheme) {
    final isCredit = transaction.isCredit || transaction.isRefund;
    final icon = transaction.isCredit 
        ? Icons.add_circle_outline 
        : transaction.isPurchase 
            ? Icons.shopping_cart_outlined
            : Icons.remove_circle_outline;
    
    final iconColor = transaction.isCredit 
        ? Colors.green 
        : transaction.isPurchase 
            ? Colors.blue
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: modernTheme.dividerColor!.withOpacity(0.1),
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
                  transaction.description,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: modernTheme.textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTransactionDate(transaction.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: modernTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            transaction.formattedAmount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isCredit ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionHistory(BuildContext context, List<WalletTransaction> transactions, ModernThemeExtension modernTheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: modernTheme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
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
                      color: modernTheme.textColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: modernTheme.textSecondaryColor,
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
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: modernTheme.textSecondaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: modernTheme.textSecondaryColor,
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
                        return _buildTransactionItem(transaction, modernTheme);
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
                      backgroundColor: modernTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
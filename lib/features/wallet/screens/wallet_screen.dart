// lib/features/wallet/screens/wallet_screen.dart
// FINAL VERSION: True cache-aware loading with SharedPreferences persistence
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:textgb/features/wallet/providers/wallet_providers.dart';
import 'package:textgb/features/wallet/widgets/coin_packages_widget.dart';
import 'package:textgb/features/wallet/models/wallet_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  bool _balanceVisible = true;
  bool _isInitialized = false;
  bool _isLoadingInitial = false;
  String? _error;
  
  // Cached data
  WalletModel? _cachedWallet;
  List<WalletTransaction> _cachedTransactions = [];

  // Cache keys
  static const String _walletCacheKey = 'cached_wallet_data';
  static const String _transactionsCacheKey = 'cached_transactions_data';
  static const String _walletCacheTimestampKey = 'wallet_cache_timestamp';
  static const Duration _cacheValidityDuration = Duration(minutes: 15); // Cache valid for 15 minutes

  // Custom Blue Fintech Colors - dark theme with bright text
  static const _fintechPrimary = Color(0xFF64B5F6); // Bright blue for text
  static const _fintechSecondary = Color(0xFF42A5F5); // Medium bright blue
  static const _fintechLight = Color(0xFF90CAF9); // Light blue for accents
  static const _fintechSuccess = Color(0xFF81C784); // Success green
  static const _fintechWarning = Color(0xFFFFB74D); // Warning orange
  static const _fintechError = Color(0xFFEF5350); // Error red
  static const _fintechGradientStart = Color(0xFF1976D2);
  static const _fintechGradientEnd = Color(0xFF1565C0);
  static const _fintechCardGradientStart = Color(0xFF42A5F5);
  static const _fintechCardGradientEnd = Color(0xFF1976D2);
  static const _fintechCardBg = Color(0xFF263238); // Dark card background
  static const _fintechCardBgLight = Color(0xFF37474F); // Slightly lighter card background

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  // ENHANCED: True cache detection with SharedPreferences
  Future<bool> get _hasCachedData async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final walletData = prefs.getString(_walletCacheKey);
      final cacheTimestamp = prefs.getInt(_walletCacheTimestampKey);
      
      if (walletData == null || cacheTimestamp == null) {
        return false;
      }
      
      // Check if cache is still valid (not expired)
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(cacheTimestamp);
      final isExpired = DateTime.now().difference(cacheTime) > _cacheValidityDuration;
      
      return !isExpired;
    } catch (e) {
      debugPrint('Error checking cached data: $e');
      return false;
    }
  }

  // NEW: Load cached data from SharedPreferences
  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load wallet data
      final walletJson = prefs.getString(_walletCacheKey);
      if (walletJson != null) {
        final walletMap = jsonDecode(walletJson) as Map<String, dynamic>;
        _cachedWallet = WalletModel.fromMap(walletMap);
      }
      
      // Load transactions data
      final transactionsJson = prefs.getString(_transactionsCacheKey);
      if (transactionsJson != null) {
        final transactionsList = jsonDecode(transactionsJson) as List<dynamic>;
        _cachedTransactions = transactionsList
            .map((json) => WalletTransaction.fromMap(json as Map<String, dynamic>))
            .toList();
      }
      
      debugPrint('Wallet screen: Loaded cached data - Wallet: ${_cachedWallet != null}, Transactions: ${_cachedTransactions.length}');
    } catch (e) {
      debugPrint('Error loading cached data: $e');
      _cachedWallet = null;
      _cachedTransactions = [];
    }
  }

  // NEW: Save data to cache
  Future<void> _saveCachedData(WalletModel? wallet, List<WalletTransaction> transactions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save wallet data
      if (wallet != null) {
        final walletJson = jsonEncode(wallet.toMap());
        await prefs.setString(_walletCacheKey, walletJson);
      }
      
      // Save transactions data
      final transactionsJson = jsonEncode(
        transactions.map((t) => t.toMap()).toList(),
      );
      await prefs.setString(_transactionsCacheKey, transactionsJson);
      
      // Save cache timestamp
      await prefs.setInt(_walletCacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      
      debugPrint('Wallet screen: Saved data to cache');
    } catch (e) {
      debugPrint('Error saving cached data: $e');
    }
  }

  // NEW: Clear cached data
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_walletCacheKey);
      await prefs.remove(_transactionsCacheKey);
      await prefs.remove(_walletCacheTimestampKey);
      debugPrint('Wallet screen: Cache cleared');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  // ENHANCED: True cache-aware initialization
  void _initializeScreen() async {
    final hasCached = await _hasCachedData;
    
    if (hasCached) {
      // Load cached data and display immediately
      await _loadCachedData();
      setState(() {
        _isInitialized = true;
      });
      debugPrint('Wallet screen: Using cached data');
    } else {
      // No valid cache - load fresh data
      debugPrint('Wallet screen: No valid cache found, loading initial data');
      _loadInitialData();
    }
  }

  // UPDATED: Load initial data for new users or expired cache
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingInitial = true;
      _error = null;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoadingInitial = false;
          _isInitialized = true;
        });
        return;
      }

      // Load fresh data from repository
      final repository = ref.read(walletRepositoryProvider);
      final wallet = await repository.getUserWallet(currentUser.id);
      final transactions = await repository.getWalletTransactions(
        currentUser.id,
        limit: 10,
      );
      
      // Update cached data
      _cachedWallet = wallet;
      _cachedTransactions = transactions;
      
      // Save to persistent cache
      await _saveCachedData(wallet, transactions);
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoadingInitial = false;
        });
        debugPrint('Wallet screen: Initial data loaded and cached successfully');
      }
    } catch (e) {
      debugPrint('Wallet screen: Error loading initial data: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingInitial = false;
          _isInitialized = true; // Still mark as initialized to show error state
        });
      }
    }
  }

  // UPDATED: Refresh wallet data (only called by pull-to-refresh)
  Future<void> _refreshWallet() async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;
      
      // Load fresh data from repository
      final repository = ref.read(walletRepositoryProvider);
      final wallet = await repository.getUserWallet(currentUser.id);
      final transactions = await repository.getWalletTransactions(
        currentUser.id,
        limit: 10,
      );
      
      // Update cached data
      _cachedWallet = wallet;
      _cachedTransactions = transactions;
      
      // Save to persistent cache
      await _saveCachedData(wallet, transactions);
      
      // Clear any previous errors on successful refresh
      if (_error != null) {
        setState(() {
          _error = null;
        });
      }
      
      // Trigger rebuild to show new data
      setState(() {});
      
      debugPrint('Wallet screen: Data refreshed and cached successfully');
    } catch (e) {
      debugPrint('Wallet screen: Error refreshing data: $e');
      // Don't update error state on refresh failure to avoid disrupting UX
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;

    return Scaffold(
      backgroundColor: modernTheme.surfaceColor,
      body: SafeArea(
        child: !_isInitialized
            ? _buildInitialLoadingView(modernTheme)
            : _error != null
                ? _buildErrorState(_error!, modernTheme)
                : RefreshIndicator(
                    onRefresh: _refreshWallet,
                    color: _fintechPrimary,
                    child: _buildWalletContent(_cachedWallet, _cachedTransactions, modernTheme),
                  ),
      ),
    );
  }

  Widget _buildInitialLoadingView(ModernThemeExtension modernTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: _fintechPrimary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            _isLoadingInitial ? 'Loading wallet...' : 'Initializing...',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _fintechError.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: _fintechError,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Unable to load wallet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _fintechPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: modernTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _loadInitialData(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _fintechPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 16,
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

  Widget _buildWalletContent(WalletModel? wallet, List<WalletTransaction> transactions, ModernThemeExtension modernTheme) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100), // Add bottom padding for nav bar
      child: Column(
        children: [
          // Balance Card Section
          Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_fintechGradientStart, _fintechGradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _fintechPrimary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _buildBalanceCard(wallet, modernTheme),
          ),

          // Quick Actions Grid
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildQuickActionsGrid(),
          ),

          const SizedBox(height: 24),

          // Statistics Cards
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildStatsSection(wallet),
          ),

          const SizedBox(height: 24),

          // Recent Transactions
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildTransactionsSection(transactions, modernTheme),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(WalletModel? wallet, ModernThemeExtension modernTheme) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'KEST Balance',
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
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'KES',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _balanceVisible 
                  ? (wallet?.coinsBalance.toString() ?? '0') 
                  : '••••••',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'KEST',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      wallet?.hasBalance == true 
                        ? Icons.check_circle
                        : Icons.info_outline,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      wallet?.hasBalance == true 
                        ? 'Wallet Active'
                        : 'Buy KEST to start',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _fintechCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _fintechLight.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _fintechPrimary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _fintechPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.add_card,
                  title: 'Buy KEST',
                  subtitle: 'Add funds',
                  color: _fintechSuccess,
                  onTap: () => CoinPackagesWidget.show(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.send,
                  title: 'Send',
                  subtitle: 'Transfer KEST',
                  color: _fintechSecondary,
                  onTap: () {
                    // TODO: Implement send functionality
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.qr_code_scanner,
                  title: 'Scan QR',
                  subtitle: 'Quick pay',
                  color: _fintechLight,
                  onTap: () {
                    // TODO: Implement QR scan
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.history,
                  title: 'History',
                  subtitle: 'View all',
                  color: _fintechWarning,
                  onTap: () => _showTransactionHistory(context, _cachedTransactions, context.modernTheme),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _fintechCardBgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(WalletModel? wallet) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _fintechCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _fintechLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wallet Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _fintechPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.account_balance,
                  title: 'Current Balance',
                  value: '${wallet?.coinsBalance ?? 0} KEST',
                  color: _fintechSuccess,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.trending_up,
                  title: 'Est. Value',
                  value: wallet?.formattedKESEquivalent ?? 'KES 0',
                  color: _fintechSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _fintechCardBgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection(List<WalletTransaction> transactions, ModernThemeExtension modernTheme) {
    return Container(
      decoration: BoxDecoration(
        color: _fintechCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _fintechLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _fintechPrimary,
                  ),
                ),
                if (transactions.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showTransactionHistory(context, transactions, modernTheme),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _fintechSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (transactions.isEmpty)
            _buildEmptyTransactions()
          else
            Column(
              children: transactions.take(4).map((transaction) => 
                _buildTransactionItem(transaction)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _fintechLight.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long,
              size: 40,
              color: _fintechLight,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Transactions Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _fintechPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your transaction history will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _fintechSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(WalletTransaction transaction) {
    final isCredit = transaction.isCredit;
    
    IconData icon;
    Color iconColor;
    
    switch (transaction.type) {
      case 'coin_purchase':
        icon = Icons.add_circle_outline;
        iconColor = _fintechSuccess;
        break;
      case 'gift_sent':
        icon = Icons.send;
        iconColor = _fintechError;
        break;
      case 'admin_credit':
        icon = Icons.admin_panel_settings;
        iconColor = _fintechWarning;
        break;
      default:
        icon = Icons.swap_horiz;
        iconColor = _fintechSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _fintechLight.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _fintechCardBgLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: iconColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.displayTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _fintechPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: _fintechSecondary.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTransactionDate(transaction.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: _fintechSecondary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}${transaction.coinAmount}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isCredit ? _fintechSuccess : _fintechError,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'KEST',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _fintechSecondary,
                ),
              ),
            ],
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
        decoration: const BoxDecoration(
          color: _fintechCardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _fintechLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transaction History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _fintechPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: _fintechSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: transactions.isEmpty
                  ? _buildEmptyTransactions()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return _buildTransactionItem(transaction);
                      },
                    ),
            ),
            if (transactions.length >= 10)
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Load more transactions and update cache
                      try {
                        final currentUser = ref.read(currentUserProvider);
                        if (currentUser != null) {
                          final repository = ref.read(walletRepositoryProvider);
                          final moreTransactions = await repository.getWalletTransactions(
                            currentUser.id,
                            limit: 20,
                            lastTransactionId: _cachedTransactions.isNotEmpty 
                                ? _cachedTransactions.last.transactionId 
                                : null,
                          );
                          
                          _cachedTransactions = [..._cachedTransactions, ...moreTransactions];
                          await _saveCachedData(_cachedWallet, _cachedTransactions);
                          setState(() {});
                        }
                      } catch (e) {
                        debugPrint('Error loading more transactions: $e');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _fintechPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Load More',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
// lib/features/wallet/screens/wallet_screen.dart
// ESCROW-FOCUSED VERSION: Wallet system designed for e-commerce marketplace escrow services
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:textgb/features/wallet/providers/wallet_providers.dart';
import 'package:textgb/features/wallet/models/wallet_model.dart';
import 'package:textgb/features/wallet/widgets/escrow_funding_widget.dart';
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
  static const Duration _cacheValidityDuration = Duration(minutes: 15);

  // Escrow-focused color scheme - professional and trustworthy
  static const _escrowPrimary = Color(0xFF1E88E5); // Professional blue
  static const _escrowSecondary = Color(0xFF42A5F5); // Lighter blue
  static const _escrowAccent = Color(0xFF90CAF9); // Light accent blue
  static const _escrowSuccess = Color(0xFF4CAF50); // Trust green
  static const _escrowWarning = Color(0xFFFF9800); // Alert orange
  static const _escrowError = Color(0xFFE53935); // Error red
  static const _escrowPending = Color(0xFFFFB74D); // Pending amber
  static const _escrowReleased = Color(0xFF66BB6A); // Released green
  static const _escrowHeld = Color(0xFF5C6BC0); // Held purple
  static const _escrowCardBg = Color(0xFF263238); // Dark card background
  static const _escrowCardBgLight = Color(0xFF37474F); // Lighter card background

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<bool> get _hasCachedData async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final walletData = prefs.getString(_walletCacheKey);
      final cacheTimestamp = prefs.getInt(_walletCacheTimestampKey);
      
      if (walletData == null || cacheTimestamp == null) {
        return false;
      }
      
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(cacheTimestamp);
      final isExpired = DateTime.now().difference(cacheTime) > _cacheValidityDuration;
      
      return !isExpired;
    } catch (e) {
      debugPrint('Error checking cached data: $e');
      return false;
    }
  }

  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final walletJson = prefs.getString(_walletCacheKey);
      if (walletJson != null) {
        final walletMap = jsonDecode(walletJson) as Map<String, dynamic>;
        _cachedWallet = WalletModel.fromMap(walletMap);
      }
      
      final transactionsJson = prefs.getString(_transactionsCacheKey);
      if (transactionsJson != null) {
        final transactionsList = jsonDecode(transactionsJson) as List<dynamic>;
        _cachedTransactions = transactionsList
            .map((json) => WalletTransaction.fromMap(json as Map<String, dynamic>))
            .toList();
      }
      
      debugPrint('Escrow wallet: Loaded cached data - Wallet: ${_cachedWallet != null}, Transactions: ${_cachedTransactions.length}');
    } catch (e) {
      debugPrint('Error loading cached data: $e');
      _cachedWallet = null;
      _cachedTransactions = [];
    }
  }

  Future<void> _saveCachedData(WalletModel? wallet, List<WalletTransaction> transactions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (wallet != null) {
        final walletJson = jsonEncode(wallet.toMap());
        await prefs.setString(_walletCacheKey, walletJson);
      }
      
      final transactionsJson = jsonEncode(
        transactions.map((t) => t.toMap()).toList(),
      );
      await prefs.setString(_transactionsCacheKey, transactionsJson);
      
      await prefs.setInt(_walletCacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      
      debugPrint('Escrow wallet: Saved data to cache');
    } catch (e) {
      debugPrint('Error saving cached data: $e');
    }
  }

  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_walletCacheKey);
      await prefs.remove(_transactionsCacheKey);
      await prefs.remove(_walletCacheTimestampKey);
      debugPrint('Escrow wallet: Cache cleared');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  void _initializeScreen() async {
    final hasCached = await _hasCachedData;
    
    if (hasCached) {
      await _loadCachedData();
      setState(() {
        _isInitialized = true;
      });
      debugPrint('Escrow wallet: Using cached data');
    } else {
      debugPrint('Escrow wallet: No valid cache found, loading initial data');
      _loadInitialData();
    }
  }

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

      final repository = ref.read(walletRepositoryProvider);
      final wallet = await repository.getUserWallet(currentUser.id);
      final transactions = await repository.getWalletTransactions(
        currentUser.id,
        limit: 10,
      );
      
      _cachedWallet = wallet;
      _cachedTransactions = transactions;
      
      await _saveCachedData(wallet, transactions);
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoadingInitial = false;
        });
        debugPrint('Escrow wallet: Initial data loaded and cached successfully');
      }
    } catch (e) {
      debugPrint('Escrow wallet: Error loading initial data: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingInitial = false;
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _refreshWallet() async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;
      
      final repository = ref.read(walletRepositoryProvider);
      final wallet = await repository.getUserWallet(currentUser.id);
      final transactions = await repository.getWalletTransactions(
        currentUser.id,
        limit: 10,
      );
      
      _cachedWallet = wallet;
      _cachedTransactions = transactions;
      
      await _saveCachedData(wallet, transactions);
      
      if (_error != null) {
        setState(() {
          _error = null;
        });
      }
      
      setState(() {});
      
      debugPrint('Escrow wallet: Data refreshed and cached successfully');
    } catch (e) {
      debugPrint('Escrow wallet: Error refreshing data: $e');
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
                    color: _escrowPrimary,
                    child: _buildEscrowWalletContent(_cachedWallet, _cachedTransactions, modernTheme),
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
            color: _escrowPrimary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            _isLoadingInitial ? 'Loading escrow wallet...' : 'Initializing...',
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
                color: _escrowError.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: _escrowError,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Unable to load escrow wallet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _escrowPrimary,
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
                  backgroundColor: _escrowPrimary,
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

  Widget _buildEscrowWalletContent(WalletModel? wallet, List<WalletTransaction> transactions, ModernThemeExtension modernTheme) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          // Escrow Balance Card Section
          Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_escrowPrimary, Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _escrowPrimary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _buildEscrowBalanceCard(wallet, modernTheme),
          ),

          // Escrow Actions Grid
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildEscrowActionsGrid(),
          ),

          const SizedBox(height: 24),

          // Escrow Statistics
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildEscrowStatsSection(wallet),
          ),

          const SizedBox(height: 24),

          // Active Escrows Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildActiveEscrowsSection(),
          ),

          const SizedBox(height: 24),

          // Recent Escrow Transactions
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildEscrowTransactionsSection(transactions, modernTheme),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEscrowBalanceCard(WalletModel? wallet, ModernThemeExtension modernTheme) {
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
                      Icons.security,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Escrow Balance',
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
                  'Available',
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
                    const Icon(
                      Icons.verified_user,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      wallet?.hasBalance == true 
                        ? 'Escrow Active'
                        : 'Add funds to use escrow',
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

  Widget _buildEscrowActionsGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _escrowCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _escrowAccent.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _escrowPrimary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Escrow Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _escrowPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildEscrowActionButton(
                  icon: Icons.add_card,
                  title: 'Add Funds',
                  subtitle: 'Top up wallet',
                  color: _escrowSuccess,
                  onTap: () => EscrowFundingWidget.show(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEscrowActionButton(
                  icon: Icons.lock,
                  title: 'Create Escrow',
                  subtitle: 'Secure payment',
                  color: _escrowHeld,
                  onTap: () => _showComingSoonDialog('Create Escrow'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEscrowActionButton(
                  icon: Icons.lock_open,
                  title: 'Release Funds',
                  subtitle: 'Complete order',
                  color: _escrowReleased,
                  onTap: () => _showComingSoonDialog('Release Funds'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEscrowActionButton(
                  icon: Icons.report_problem,
                  title: 'Dispute',
                  subtitle: 'Report issue',
                  color: _escrowWarning,
                  onTap: () => _showComingSoonDialog('Dispute Resolution'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEscrowActionButton({
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
          color: _escrowCardBgLight,
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

  Widget _buildEscrowStatsSection(WalletModel? wallet) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _escrowCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _escrowAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Escrow Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _escrowPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEscrowStatItem(
                  icon: Icons.account_balance_wallet,
                  title: 'Available Balance',
                  value: '${wallet?.coinsBalance ?? 0} KES',
                  color: _escrowSuccess,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEscrowStatItem(
                  icon: Icons.lock,
                  title: 'Funds in Escrow',
                  value: '0 KES', // Dummy value
                  color: _escrowHeld,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEscrowStatItem(
                  icon: Icons.pending_actions,
                  title: 'Pending Releases',
                  value: '0', // Dummy value
                  color: _escrowPending,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEscrowStatItem(
                  icon: Icons.check_circle,
                  title: 'Completed Escrows',
                  value: '0', // Dummy value
                  color: _escrowReleased,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEscrowStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _escrowCardBgLight,
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

  Widget _buildActiveEscrowsSection() {
    return Container(
      decoration: BoxDecoration(
        color: _escrowCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _escrowAccent.withOpacity(0.3),
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
                  'Active Escrows',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _escrowPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showComingSoonDialog('View All Escrows'),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _escrowSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildEmptyActiveEscrows(),
        ],
      ),
    );
  }

  Widget _buildEmptyActiveEscrows() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _escrowAccent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.security,
              size: 40,
              color: _escrowAccent,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Active Escrows',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _escrowPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your secure transactions will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _escrowSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showComingSoonDialog('Create Your First Escrow'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _escrowPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Create First Escrow',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscrowTransactionsSection(List<WalletTransaction> transactions, ModernThemeExtension modernTheme) {
    return Container(
      decoration: BoxDecoration(
        color: _escrowCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _escrowAccent.withOpacity(0.3),
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
                  'Escrow Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _escrowPrimary,
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
                        color: _escrowSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (transactions.isEmpty)
            _buildEmptyEscrowTransactions()
          else
            Column(
              children: transactions.take(4).map((transaction) => 
                _buildEscrowTransactionItem(transaction)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyEscrowTransactions() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _escrowAccent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long,
              size: 40,
              color: _escrowAccent,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Escrow Transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _escrowPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your escrow transaction history will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _escrowSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscrowTransactionItem(WalletTransaction transaction) {
    final isCredit = transaction.isCredit;
    
    IconData icon;
    Color iconColor;
    
    switch (transaction.type) {
      case 'escrow_created':
        icon = Icons.lock;
        iconColor = _escrowHeld;
        break;
      case 'escrow_released':
        icon = Icons.lock_open;
        iconColor = _escrowReleased;
        break;
      case 'escrow_refunded':
        icon = Icons.refresh;
        iconColor = _escrowWarning;
        break;
      case 'coin_purchase':
        icon = Icons.add_circle_outline;
        iconColor = _escrowSuccess;
        break;
      case 'dispute_created':
        icon = Icons.report_problem;
        iconColor = _escrowError;
        break;
      default:
        icon = Icons.swap_horiz;
        iconColor = _escrowSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _escrowAccent.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _escrowCardBgLight,
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
                    color: _escrowPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: _escrowSecondary.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTransactionDate(transaction.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: _escrowSecondary.withOpacity(0.6),
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
                  color: isCredit ? _escrowSuccess : _escrowError,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'KES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _escrowSecondary,
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
          color: _escrowCardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _escrowAccent.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Escrow Transaction History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _escrowPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: _escrowSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: transactions.isEmpty
                  ? _buildEmptyEscrowTransactions()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return _buildEscrowTransactionItem(transaction);
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
                      backgroundColor: _escrowPrimary,
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

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _escrowCardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _escrowPrimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.construction,
                color: _escrowPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 18,
                color: _escrowPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$feature is currently under development.',
              style: const TextStyle(
                fontSize: 16,
                color: _escrowSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _escrowPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: _escrowPrimary,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This feature will be available in a future update. Stay tuned!',
                      style: TextStyle(
                        fontSize: 14,
                        color: _escrowPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it',
              style: TextStyle(
                color: _escrowSuccess,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
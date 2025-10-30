// lib/features/wallet/screens/wallet_screen.dart
// VIRTUAL GIFTING WALLET: TikTok-style gift system that converts to real cash
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  String _selectedTab = 'Overview'; // Overview, Send Gifts, My Earnings
  
  // Cached data
  WalletModel? _cachedWallet;
  List<WalletTransaction> _cachedTransactions = [];

  // Cache keys
  static const String _walletCacheKey = 'cached_wallet_data';
  static const String _transactionsCacheKey = 'cached_transactions_data';
  static const String _walletCacheTimestampKey = 'wallet_cache_timestamp';
  static const Duration _cacheValidityDuration = Duration(minutes: 15);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

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
      
      debugPrint('Gift wallet: Loaded cached data - Wallet: ${_cachedWallet != null}, Transactions: ${_cachedTransactions.length}');
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
      
      debugPrint('Gift wallet: Saved data to cache');
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
      debugPrint('Gift wallet: Cache cleared');
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
      debugPrint('Gift wallet: Using cached data');
    } else {
      debugPrint('Gift wallet: No valid cache found, loading initial data');
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
        debugPrint('Gift wallet: Initial data loaded and cached successfully');
      }
    } catch (e) {
      debugPrint('Gift wallet: Error loading initial data: $e');
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
      
      debugPrint('Gift wallet: Data refreshed and cached successfully');
    } catch (e) {
      debugPrint('Gift wallet: Error refreshing data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getSafeTheme(context);

    return Scaffold(
      backgroundColor: theme.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            // Enhanced App Bar            
            _buildAppBar(theme),
            
            // Main Content
            Expanded(
              child: !_isInitialized
                  ? _buildInitialLoadingView(theme)
                  : _error != null
                      ? _buildErrorState(_error!, theme)
                      : RefreshIndicator(
                          onRefresh: _refreshWallet,
                          color: theme.primaryColor ?? const Color(0xFFFE2C55),
                          child: _buildWalletContent(_cachedWallet, _cachedTransactions, theme),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ModernThemeExtension theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
      child: Row(
        children: [
          // Back Button
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                context.pop();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: theme.primaryColor ?? const Color(0xFFFE2C55),
                  size: 20,
                ),
              ),
            ),
          ),
          
          // Title Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Wallet',
                    style: TextStyle(
                      color: theme.textColor ?? Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Send gifts & earn from your content',
                    style: TextStyle(
                      color: theme.textSecondaryColor ?? Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Menu Button (Cupertino style)
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _showMenuOptions(context, theme),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.chart_bar_alt_fill,
                  color: theme.primaryColor ?? const Color(0xFFFE2C55),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMenuOptions(BuildContext context, ModernThemeExtension theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wallet Menu',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: theme.textColor ?? Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildMenuItem(
                      icon: CupertinoIcons.chart_bar_square,
                      title: 'Statistics',
                      subtitle: 'View gifting & earnings analytics',
                      onTap: () {
                        context.pop();
                        _showComingSoonDialog('Statistics');
                      },
                      theme: theme,
                    ),
                    _buildMenuItem(
                      icon: CupertinoIcons.doc_text,
                      title: 'Statements',
                      subtitle: 'Download transaction statements',
                      onTap: () {
                        context.pop();
                        _showComingSoonDialog('Statements');
                      },
                      theme: theme,
                    ),
                    _buildMenuItem(
                      icon: CupertinoIcons.gift,
                      title: 'Gift Shop',
                      subtitle: 'Browse available virtual gifts',
                      onTap: () {
                        context.pop();
                        _showComingSoonDialog('Gift Shop');
                      },
                      theme: theme,
                    ),
                    _buildMenuItem(
                      icon: CupertinoIcons.money_dollar_circle,
                      title: 'Conversion Rates',
                      subtitle: 'View gift to cash conversion rates',
                      onTap: () {
                        context.pop();
                        _showComingSoonDialog('Conversion Rates');
                      },
                      theme: theme,
                    ),
                    _buildMenuItem(
                      icon: CupertinoIcons.question_circle,
                      title: 'Help & Support',
                      subtitle: 'Get help with gifts & withdrawals',
                      onTap: () {
                        context.pop();
                        _showComingSoonDialog('Help & Support');
                      },
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ModernThemeExtension theme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: (theme.surfaceVariantColor ?? Colors.grey[100]!).withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (theme.dividerColor ?? Colors.grey[300]!).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: theme.primaryColor ?? const Color(0xFFFE2C55),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor ?? Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textSecondaryColor ?? Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                color: theme.textTertiaryColor ?? Colors.grey[400],
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialLoadingView(ModernThemeExtension theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.primaryColor ?? const Color(0xFFFE2C55),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            _isLoadingInitial ? 'Loading wallet...' : 'Initializing...',
            style: TextStyle(
              color: theme.textSecondaryColor ?? Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
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
              onPressed: () => _loadInitialData(),
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

  Widget _buildWalletContent(WalletModel? wallet, List<WalletTransaction> transactions, ModernThemeExtension theme) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          // Balance Card Section
          Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor ?? const Color(0xFFFE2C55),
                  (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _buildBalanceCard(wallet, theme),
          ),

          // Tab Selector
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildTabSelector(theme),
          ),

          const SizedBox(height: 24),

          // Content based on selected tab
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildTabContent(wallet, transactions, theme),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(WalletModel? wallet, ModernThemeExtension theme) {
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
                      Icons.card_giftcard,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
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
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(
                Icons.monetization_on,
                color: Colors.white,
                size: 24,
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
                  'Coins',
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
          Text(
            _balanceVisible 
              ? '≈ KES ${wallet?.coinsBalance ?? 0}' 
              : '≈ KES •••',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.card_giftcard,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          wallet?.hasBalance == true 
                            ? 'Send gifts & earn cash'
                            : 'Buy coins to send gifts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
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

  Widget _buildTabSelector(ModernThemeExtension theme) {
    final tabs = ['Overview', 'Send Gifts', 'My Earnings'];
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
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
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = tab;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.1)
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected ? Border.all(
                    color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.3),
                    width: 1,
                  ) : null,
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected 
                      ? theme.primaryColor ?? const Color(0xFFFE2C55)
                      : theme.textSecondaryColor ?? Colors.grey[600],
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(WalletModel? wallet, List<WalletTransaction> transactions, ModernThemeExtension theme) {
    switch (_selectedTab) {
      case 'Send Gifts':
        return _buildSendGiftsSection(wallet, theme);
      case 'My Earnings':
        return _buildEarningsSection(wallet, theme);
      default:
        return _buildOverviewSection(wallet, transactions, theme);
    }
  }

  Widget _buildOverviewSection(WalletModel? wallet, List<WalletTransaction> transactions, ModernThemeExtension theme) {
    return Column(
      children: [
        // Quick Actions
        _buildQuickActionsGrid(theme),
        
        const SizedBox(height: 24),
        
        // Statistics
        _buildStatsSection(wallet, theme),
        
        const SizedBox(height: 24),
        
        // Recent Transactions
        _buildTransactionsSection(transactions, theme),
      ],
    );
  }

  Widget _buildSendGiftsSection(WalletModel? wallet, ModernThemeExtension theme) {
    return Column(
      children: [
        // Gifting Actions
        Container(
          padding: const EdgeInsets.all(20),
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
                      color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.card_giftcard,
                      color: theme.primaryColor ?? const Color(0xFFFE2C55),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Send Virtual Gifts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.textColor ?? Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildActionButton(
                icon: Icons.shopping_bag,
                title: 'Browse Gift Shop',
                subtitle: 'Explore available virtual gifts',
                value: '${wallet?.coinsBalance ?? 0} coins',
                color: theme.primaryColor ?? const Color(0xFFFE2C55),
                onTap: () => _showComingSoonDialog('Gift Shop'),
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                icon: Icons.history,
                title: 'Gifts Sent',
                subtitle: 'View your gifting history',
                value: '0 gifts',
                color: Colors.purple,
                onTap: () => _showComingSoonDialog('Gifts Sent History'),
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                icon: Icons.people,
                title: 'Favorite Creators',
                subtitle: 'Support creators you follow',
                value: '0 favorites',
                color: Colors.blue,
                onTap: () => _showComingSoonDialog('Favorite Creators'),
                theme: theme,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Gift Info
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: theme.primaryColor ?? const Color(0xFFFE2C55),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'How Virtual Gifts Work',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.textColor ?? Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Send virtual gifts to creators during live streams or on their posts. Your gifts help creators earn real money and show your appreciation!',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textSecondaryColor ?? Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsSection(WalletModel? wallet, ModernThemeExtension theme) {
    return Column(
      children: [
        // Earnings Overview
        Container(
          padding: const EdgeInsets.all(20),
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
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'My Earnings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.textColor ?? Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildActionButton(
                icon: Icons.card_giftcard,
                title: 'Gifts Received',
                subtitle: 'Total gifts from supporters',
                value: '0 gifts',
                color: theme.primaryColor ?? const Color(0xFFFE2C55),
                onTap: () => _showComingSoonDialog('Gifts Received'),
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                icon: Icons.account_balance_wallet,
                title: 'Total Earnings',
                subtitle: 'Lifetime earnings from gifts',
                value: '0 KES',
                color: Colors.green,
                onTap: () => _showComingSoonDialog('Earnings Breakdown'),
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                icon: Icons.payments,
                title: 'Withdraw',
                subtitle: 'Transfer earnings to M-Pesa',
                value: '${wallet?.coinsBalance ?? 0} KES',
                color: Colors.blue,
                onTap: () => _showComingSoonDialog('Withdraw to M-Pesa'),
                theme: theme,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Creator Tips
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.green.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lightbulb,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Earning Tips',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.textColor ?? Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Create engaging content to receive more gifts! Go live regularly, interact with your audience, and thank supporters to build a loyal community.',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textSecondaryColor ?? Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required Color color,
    required VoidCallback onTap,
    required ModernThemeExtension theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (theme.surfaceVariantColor ?? Colors.grey[100]!).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
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
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor ?? Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
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
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: theme.textTertiaryColor ?? Colors.grey[400],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(ModernThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.textColor ?? Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.add_card,
                  title: 'Buy Coins',
                  color: Colors.green,
                  onTap: () => EscrowFundingWidget.show(context),
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.card_giftcard,
                  title: 'Send Gift',
                  color: theme.primaryColor ?? const Color(0xFFFE2C55),
                  onTap: () => _showComingSoonDialog('Send Gift'),
                  theme: theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.payments,
                  title: 'Withdraw',
                  color: Colors.blue,
                  onTap: () => _showComingSoonDialog('Withdraw'),
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.history,
                  title: 'History',
                  color: Colors.purple,
                  onTap: () => _showComingSoonDialog('Transaction History'),
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required ModernThemeExtension theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
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
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(WalletModel? wallet, ModernThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wallet Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.textColor ?? Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.monetization_on,
                  title: 'Coin Balance',
                  value: '${wallet?.coinsBalance ?? 0}',
                  color: theme.primaryColor ?? const Color(0xFFFE2C55),
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.card_giftcard,
                  title: 'Gifts Sent',
                  value: '0',
                  color: Colors.purple,
                  theme: theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.favorite,
                  title: 'Gifts Received',
                  value: '0',
                  color: Colors.orange,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.account_balance_wallet,
                  title: 'Total Earned',
                  value: '0 KES',
                  color: Colors.green,
                  theme: theme,
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
    required ModernThemeExtension theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (theme.surfaceVariantColor ?? Colors.grey[100]!).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.textSecondaryColor ?? Colors.grey[600],
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

  Widget _buildTransactionsSection(List<WalletTransaction> transactions, ModernThemeExtension theme) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.textColor ?? Colors.black,
                  ),
                ),
                if (transactions.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showTransactionHistory(context, transactions, theme),
                    child: Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryColor ?? const Color(0xFFFE2C55),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (transactions.isEmpty)
            _buildEmptyTransactions(theme)
          else
            Column(
              children: transactions.take(4).map((transaction) => 
                _buildTransactionItem(transaction, theme)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions(ModernThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.card_giftcard,
              size: 40,
              color: theme.primaryColor ?? const Color(0xFFFE2C55),
            ),
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
            'Your gifting history will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: theme.textSecondaryColor ?? Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(WalletTransaction transaction, ModernThemeExtension theme) {
    final isCredit = transaction.isCredit;
    
    IconData icon;
    Color iconColor;
    
    switch (transaction.type) {
      case 'gift_sent':
        icon = Icons.card_giftcard;
        iconColor = theme.primaryColor ?? const Color(0xFFFE2C55);
        break;
      case 'gift_received':
        icon = Icons.favorite;
        iconColor = Colors.orange;
        break;
      case 'coin_purchase':
        icon = Icons.add_circle_outline;
        iconColor = Colors.green;
        break;
      case 'withdrawal':
        icon = Icons.payments;
        iconColor = Colors.blue;
        break;
      default:
        icon = Icons.swap_horiz;
        iconColor = theme.primaryColor ?? const Color(0xFFFE2C55);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: (theme.dividerColor ?? Colors.grey[300]!).withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor ?? Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textSecondaryColor ?? Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTransactionDate(transaction.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTertiaryColor ?? Colors.grey[400],
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
                  color: isCredit ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'coins',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.textSecondaryColor ?? Colors.grey[600],
                ),
              ),
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
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: theme.textColor ?? Colors.black,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(
                      Icons.close,
                      color: theme.textSecondaryColor ?? Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: transactions.isEmpty
                  ? _buildEmptyTransactions(theme)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return _buildTransactionItem(transaction, theme);
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
                      backgroundColor: theme.primaryColor ?? const Color(0xFFFE2C55),
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
      builder: (context) {
        final theme = _getSafeTheme(context);
        return AlertDialog(
          backgroundColor: theme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.construction,
                  color: theme.primaryColor ?? const Color(0xFFFE2C55),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 18,
                  color: theme.textColor ?? Colors.black,
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
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textSecondaryColor ?? Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.primaryColor ?? const Color(0xFFFE2C55),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This feature will be available in a future update. Stay tuned!',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.primaryColor ?? const Color(0xFFFE2C55),
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
              onPressed: () => context.pop(),
              child: const Text(
                'Got it',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
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
// lib/features/wallet/screens/wallet_screen_v2.dart
// WEMACHAT WALLET: Premium Coin Wallet with Virtual Gifts
// Modern, clean design with 1 coin = 1.5 KES conversion
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:textgb/features/wallet/providers/wallet_providers.dart';
import 'package:textgb/features/wallet/models/wallet_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';

class WalletScreenV2 extends ConsumerStatefulWidget {
  const WalletScreenV2({super.key});

  @override
  ConsumerState<WalletScreenV2> createState() => _WalletScreenV2State();
}

class _WalletScreenV2State extends ConsumerState<WalletScreenV2> with SingleTickerProviderStateMixin {
  bool _balanceVisible = true;
  bool _isInitialized = false;
  bool _isLoadingInitial = false;
  String? _error;
  String _selectedTab = 'Overview'; // Overview, Gifts
  late TabController _tabController;

  // Premium color scheme
  static const Color _primaryPurple = Color(0xFF6366F1);
  static const Color _deepPurple = Color(0xFF4F46E5);
  static const Color _accentGold = Color(0xFFFBBF24);
  static const Color _surfaceWhite = Color(0xFFFAFAFA);
  static const Color _cardWhite = Colors.white;

  // Cached data
  WalletModel? _cachedWallet;
  List<WalletTransaction> _cachedTransactions = [];

  // Cache keys
  static const String _walletCacheKey = 'cached_wallet_data_v2';
  static const String _transactionsCacheKey = 'cached_transactions_data_v2';
  static const String _walletCacheTimestampKey = 'wallet_cache_timestamp_v2';
  static const Duration _cacheValidityDuration = Duration(minutes: 15);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = _tabController.index == 0 ? 'Overview' : 'Gifts';
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper method to get safe theme with fallback
  ModernThemeExtension _getSafeTheme(BuildContext context) {
    return Theme.of(context).extension<ModernThemeExtension>() ??
        ModernThemeExtension(
          primaryColor: _primaryPurple,
          backgroundColor: _surfaceWhite,
          surfaceColor: _cardWhite,
          textColor: const Color(0xFF1F2937),
          textSecondaryColor: const Color(0xFF6B7280),
          dividerColor: const Color(0xFFE5E7EB),
          textTertiaryColor: const Color(0xFF9CA3AF),
          surfaceVariantColor: const Color(0xFFF3F4F6),
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

      debugPrint('Wallet: Loaded cached data - Wallet: ${_cachedWallet != null}, Transactions: ${_cachedTransactions.length}');
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

      debugPrint('Wallet: Saved data to cache');
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
      debugPrint('Wallet: Cache cleared');
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
      debugPrint('Wallet: Using cached data');
    } else {
      debugPrint('Wallet: No valid cache found, loading initial data');
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
      final wallet = await repository.getUserWallet(currentUser.uid);
      final transactions = await repository.getWalletTransactions(
        currentUser.uid,
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
        debugPrint('Wallet: Initial data loaded and cached successfully');
      }
    } catch (e) {
      debugPrint('Wallet: Error loading initial data: $e');
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
      final wallet = await repository.getUserWallet(currentUser.uid);
      final transactions = await repository.getWalletTransactions(
        currentUser.uid,
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

      debugPrint('Wallet: Data refreshed and cached successfully');
    } catch (e) {
      debugPrint('Wallet: Error refreshing data: $e');
    }
  }

  double _coinsToKES(int coins) {
    return coins * 1.5;
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getSafeTheme(context);

    return Scaffold(
      backgroundColor: _surfaceWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Premium App Bar
            _buildAppBar(theme),

            // Main Content
            Expanded(
              child: !_isInitialized
                  ? _buildInitialLoadingView(theme)
                  : _error != null
                      ? _buildErrorState(_error!, theme)
                      : RefreshIndicator(
                          onRefresh: _refreshWallet,
                          color: _primaryPurple,
                          child: _buildWalletContent(_cachedWallet, _cachedTransactions, theme),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ModernThemeExtension theme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 12 : 20,
        isSmallScreen ? 8 : 12,
        isSmallScreen ? 12 : 20,
        isSmallScreen ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: _cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          Container(
            decoration: BoxDecoration(
              color: _primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              color: _primaryPurple,
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(),
            ),
          ),

          const SizedBox(width: 16),

          // Title Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Wallet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: Color(0xFF1F2937),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_accentGold, _accentGold.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const Text(
                  '1 coin = 1.5 KES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Menu Button
          Container(
            decoration: BoxDecoration(
              color: _primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _showMenuOptions(context, theme),
              icon: const Icon(Icons.more_vert),
              color: _primaryPurple,
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletContent(WalletModel? wallet, List<WalletTransaction> transactions, ModernThemeExtension theme) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Premium Balance Card
          _buildPremiumBalanceCard(wallet, theme),

          const SizedBox(height: 20),

          // Tab Bar
          _buildTabBar(theme),

          const SizedBox(height: 20),

          // Tab Content
          _buildTabContent(wallet, transactions, theme),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPremiumBalanceCard(WalletModel? wallet, ModernThemeExtension theme) {
    final balance = wallet?.coinsBalance ?? 0;
    final kesValue = _coinsToKES(balance);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryPurple, _deepPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryPurple.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      flex: 1,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Flexible(
                            child: Text(
                              'Coin Balance',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _balanceVisible = !_balanceVisible;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _balanceVisible ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _balanceVisible ? balance.toString() : '••••••',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 48 : 56,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                            letterSpacing: -2,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8, left: 8),
                      child: Text(
                        'coins',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isSmallScreen ? 16 : 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _balanceVisible ? '≈ KES ${kesValue.toStringAsFixed(2)}' : '≈ KES •••',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _accentGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _accentGold.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: _accentGold,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          '100 coins = KES 150  •  Min: 50 coins',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
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

  Widget _buildTabBar(ModernThemeExtension theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: ['Overview', 'Gifts'].map((tab) {
          final isSelected = _selectedTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = tab;
                  _tabController.animateTo(tab == 'Overview' ? 0 : 1);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [_primaryPurple, _deepPurple],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab == 'Overview' ? Icons.dashboard_rounded : Icons.card_giftcard_rounded,
                      color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tab,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF6B7280),
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(WalletModel? wallet, List<WalletTransaction> transactions, ModernThemeExtension theme) {
    if (_selectedTab == 'Gifts') {
      return _buildGiftsTab(wallet, theme);
    }
    return _buildOverviewTab(wallet, transactions, theme);
  }

  Widget _buildOverviewTab(WalletModel? wallet, List<WalletTransaction> transactions, ModernThemeExtension theme) {
    return Column(
      children: [
        // Quick Actions
        _buildQuickActions(theme),

        const SizedBox(height: 16),

        // Services Grid
        _buildServicesGrid(theme),

        const SizedBox(height: 16),

        // Recent Transactions
        _buildTransactionsSection(transactions, theme),
      ],
    );
  }

  Widget _buildGiftsTab(WalletModel? wallet, ModernThemeExtension theme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    // Get gift-related transactions
    final giftTransactions = _cachedTransactions
        .where((t) => t.type == 'gift_received')
        .toList();

    return Column(
      children: [
        // Gifts Stats Card
        Container(
          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 20),
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          decoration: BoxDecoration(
            color: _cardWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_accentGold.withOpacity(0.2), _accentGold.withOpacity(0.1)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.card_giftcard_rounded,
                      color: _accentGold,
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Virtual Gifts Received',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F2937),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Track gifts from your supporters',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            color: const Color(0xFF6B7280),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildGiftStatItem(
                      'Total Gifts',
                      giftTransactions.length.toString(),
                      Icons.favorite_rounded,
                      const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGiftStatItem(
                      'Coin Value',
                      giftTransactions
                          .fold(0, (sum, t) => sum + t.coinAmount)
                          .toString(),
                      Icons.monetization_on_rounded,
                      _accentGold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: isSmallScreen ? 12 : 16),

        // Received Gifts List
        Container(
          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 20),
          decoration: BoxDecoration(
            color: _cardWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Received Gifts',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (giftTransactions.isNotEmpty)
                      Text(
                        '${giftTransactions.length} gifts',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: _primaryPurple,
                        ),
                      ),
                  ],
                ),
              ),
              if (giftTransactions.isEmpty)
                _buildEmptyGifts(theme)
              else
                Column(
                  children: giftTransactions.take(5).map((transaction) =>
                    _buildGiftItem(transaction, theme)).toList(),
                ),
            ],
          ),
        ),

        SizedBox(height: isSmallScreen ? 12 : 16),

        // Info Card
        Container(
          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 20),
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryPurple.withOpacity(0.1), _deepPurple.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _primaryPurple.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  color: _primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.lightbulb_rounded,
                  color: _primaryPurple,
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: Text(
                  'Create engaging content to receive more virtual gifts from your supporters!',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    color: const Color(0xFF4B5563),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGiftStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGifts(ModernThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _accentGold.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.card_giftcard_rounded,
              size: 48,
              color: _accentGold,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Gifts Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gifts you receive will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftItem(WalletTransaction transaction, ModernThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE5E7EB).withOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accentGold.withOpacity(0.2), _accentGold.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.card_giftcard_rounded,
              color: _accentGold,
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
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTransactionDate(transaction.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${transaction.coinAmount}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _accentGold,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'coins',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ModernThemeExtension theme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 20),
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.add_circle_rounded,
                  label: 'Top Up',
                  color: const Color(0xFF10B981),
                  onTap: () => context.push('/wallet-topup'),
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.send_rounded,
                  label: 'Send',
                  color: const Color(0xFF3B82F6),
                  onTap: () => _showComingSoonDialog('Send Coins'),
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.qr_code_rounded,
                  label: 'Receive',
                  color: _accentGold,
                  onTap: () => _showComingSoonDialog('Receive via QR'),
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.history_rounded,
                  label: 'History',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => _showTransactionHistory(context, _cachedTransactions, theme),
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
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: isSmallScreen ? 22 : 26,
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 10),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4B5563),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid(ModernThemeExtension theme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 20),
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Services',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: isSmallScreen ? 12 : 20,
            crossAxisSpacing: isSmallScreen ? 8 : 12,
            childAspectRatio: isSmallScreen ? 0.80 : 0.88,
            children: [
              _buildServiceItem(
                icon: Icons.phone_android,
                label: 'M-Pesa',
                color: const Color(0xFF10B981),
                onTap: () => _showComingSoonDialog('M-Pesa Integration'),
              ),
              _buildServiceItem(
                icon: Icons.shopping_bag_rounded,
                label: 'Shop',
                color: const Color(0xFF3B82F6),
                onTap: () => _showComingSoonDialog('Shopping'),
              ),
              _buildServiceItem(
                icon: Icons.receipt_long_rounded,
                label: 'Split Bill',
                color: const Color(0xFFF59E0B),
                onTap: () => _showComingSoonDialog('Split Bill'),
              ),
              _buildServiceItem(
                icon: Icons.bolt_rounded,
                label: 'Utilities',
                color: const Color(0xFFEF4444),
                onTap: () => _showComingSoonDialog('Pay Utilities'),
              ),
              _buildServiceItem(
                icon: Icons.directions_bus_rounded,
                label: 'Transport',
                color: const Color(0xFF06B6D4),
                onTap: () => _showComingSoonDialog('Book Transport'),
              ),
              _buildServiceItem(
                icon: Icons.restaurant_rounded,
                label: 'Food',
                color: const Color(0xFFEC4899),
                onTap: () => _showComingSoonDialog('Order Food'),
              ),
              _buildServiceItem(
                icon: Icons.local_activity_rounded,
                label: 'Events',
                color: const Color(0xFF8B5CF6),
                onTap: () => _showComingSoonDialog('Events'),
              ),
              _buildServiceItem(
                icon: Icons.more_horiz_rounded,
                label: 'More',
                color: const Color(0xFF6B7280),
                onTap: () => _showMenuOptions(context, theme),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
            ),
            child: Icon(
              icon,
              color: color,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4B5563),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection(List<WalletTransaction> transactions, ModernThemeExtension theme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 20),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (transactions.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showTransactionHistory(context, transactions, theme),
                    child: Text(
                      'View All',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: _primaryPurple,
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
              children: transactions.take(5).map((transaction) =>
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _primaryPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 48,
              color: _primaryPurple,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Transactions Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your transaction history will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
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
      case 'transfer_sent':
        icon = Icons.send_rounded;
        iconColor = const Color(0xFF3B82F6);
        break;
      case 'gift_received':
      case 'transfer_received':
        icon = Icons.call_received_rounded;
        iconColor = const Color(0xFF10B981);
        break;
      case 'coin_purchase':
      case 'topup':
        icon = Icons.add_circle_rounded;
        iconColor = const Color(0xFF10B981);
        break;
      case 'withdrawal':
        icon = Icons.payment_rounded;
        iconColor = const Color(0xFFEF4444);
        break;
      case 'payment':
        icon = Icons.shopping_bag_rounded;
        iconColor = _accentGold;
        break;
      default:
        icon = Icons.swap_horiz_rounded;
        iconColor = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE5E7EB).withOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
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
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTransactionDate(transaction.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'coins',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
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
        decoration: const BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
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
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: transactions.isEmpty
                  ? _buildEmptyTransactions(theme)
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return _buildTransactionItem(transaction, theme);
                      },
                    ),
            ),
          ],
        ),
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
        decoration: const BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Wallet Services',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildMenuItem(
                      icon: CupertinoIcons.chart_bar_square,
                      title: 'Transaction Analytics',
                      subtitle: 'View spending insights & reports',
                      onTap: () {
                        context.pop();
                        _showComingSoonDialog('Analytics');
                      },
                      theme: theme,
                    ),
                    _buildMenuItem(
                      icon: CupertinoIcons.money_dollar_circle,
                      title: 'Withdraw to M-Pesa',
                      subtitle: 'Cash out to your mobile money',
                      onTap: () {
                        context.pop();
                        _showComingSoonDialog('M-Pesa Withdrawal');
                      },
                      theme: theme,
                    ),
                    _buildMenuItem(
                      icon: CupertinoIcons.person_2,
                      title: 'Request Money',
                      subtitle: 'Request coins from contacts',
                      onTap: () {
                        context.pop();
                        _showComingSoonDialog('Request Money');
                      },
                      theme: theme,
                    ),
                    _buildMenuItem(
                      icon: CupertinoIcons.shield_lefthalf_fill,
                      title: 'Security & Privacy',
                      subtitle: 'Manage wallet security settings',
                      onTap: () {
                        context.pop();
                        _showComingSoonDialog('Security Settings');
                      },
                      theme: theme,
                    ),
                    _buildMenuItem(
                      icon: CupertinoIcons.question_circle,
                      title: 'Help & Support',
                      subtitle: 'Get help with transactions',
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: _primaryPurple,
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_right,
                color: Color(0xFF9CA3AF),
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
            color: _primaryPurple,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            _isLoadingInitial ? 'Loading wallet...' : 'Initializing...',
            style: const TextStyle(
              color: Color(0xFF6B7280),
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
                color: const Color(0xFFEF4444).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Unable to load wallet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _loadInitialData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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
          backgroundColor: _cardWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.construction_rounded,
                  color: _primaryPurple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$feature will be available soon as part of the WemaChat wallet!',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryPurple.withOpacity(0.1), _deepPurple.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: _primaryPurple,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Building the best wallet experience for you!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4B5563),
                          fontWeight: FontWeight.w600,
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
              child: Text(
                'Got it',
                style: TextStyle(
                  color: _primaryPurple,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
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
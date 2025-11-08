// lib/features/shops/screens/shops_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/shops/routes/shop_routes.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class ShopsHomeScreen extends ConsumerStatefulWidget {
  const ShopsHomeScreen({super.key});

  @override
  ConsumerState<ShopsHomeScreen> createState() => _ShopsHomeScreenState();
}

class _ShopsHomeScreenState extends ConsumerState<ShopsHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update tab icons
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Helper method to get safe theme with fallback
  ModernThemeExtension _getSafeTheme() {
    if (!mounted) {
      return _getFallbackTheme();
    }
    
    try {
      final extension = Theme.of(context).extension<ModernThemeExtension>();
      return extension ?? _getFallbackTheme();
    } catch (e) {
      debugPrint('Modern theme error: $e');
      return _getFallbackTheme();
    }
  }

  ModernThemeExtension _getFallbackTheme() {
    final isDark = mounted ? Theme.of(context).brightness == Brightness.dark : false;
    
    return ModernThemeExtension(
      primaryColor: const Color(0xFF07C160), // WeChat green
      surfaceColor: isDark ? Colors.grey[900] : Colors.grey[50],
      textColor: isDark ? Colors.white : Colors.black,
      textSecondaryColor: isDark ? Colors.grey[400] : Colors.grey[600],
      dividerColor: isDark ? Colors.grey[800] : Colors.grey[300],
      textTertiaryColor: isDark ? Colors.grey[500] : Colors.grey[400],
      surfaceVariantColor: isDark ? Colors.grey[800] : Colors.grey[100],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getSafeTheme();
    
    // TODO: Load shops from provider
    final List<Map<String, dynamic>> shops = []; // Empty list - no mock data

    return Container(
      color: theme.surfaceColor,
      child: Column(
        children: [
          // Search bar (matching chat list screen style)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: theme.backgroundColor?.withOpacity(0.6),
              border: Border(
                bottom: BorderSide(
                  color: (theme.dividerColor ?? Colors.grey).withOpacity(0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: theme.textColor),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(color: theme.textSecondaryColor),
                      prefixIcon: Icon(
                        CupertinoIcons.search,
                        color: theme.textSecondaryColor,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                CupertinoIcons.clear_circled_solid,
                                color: theme.textSecondaryColor,
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: theme.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Cart button
                GestureDetector(
                  onTap: () {
                    context.goToCart();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          CupertinoIcons.cart,
                          color: theme.textColor,
                          size: 24,
                        ),
                        // TODO: Get cart count from provider
                        // Positioned(
                        //   right: -4,
                        //   top: -4,
                        //   child: Container(
                        //     padding: const EdgeInsets.all(4),
                        //     decoration: BoxDecoration(
                        //       color: Colors.red,
                        //       shape: BoxShape.circle,
                        //     ),
                        //     constraints: const BoxConstraints(
                        //       minWidth: 16,
                        //       minHeight: 16,
                        //     ),
                        //     child: const Text(
                        //       '0',
                        //       style: TextStyle(
                        //         color: Colors.white,
                        //         fontSize: 9,
                        //         fontWeight: FontWeight.w600,
                        //       ),
                        //       textAlign: TextAlign.center,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tabs (matching user list screen style)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (theme.dividerColor ?? Colors.grey[300]!).withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (theme.primaryColor ?? const Color(0xFF07C160)).withOpacity(0.08),
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
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  bottom: BorderSide(
                    color: theme.primaryColor ?? const Color(0xFF07C160),
                    width: 3,
                  ),
                ),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: theme.primaryColor ?? const Color(0xFF07C160),
              unselectedLabelColor: theme.textSecondaryColor,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _tabController.index == 0
                              ? (theme.primaryColor ?? const Color(0xFF07C160)).withOpacity(0.15)
                              : (theme.primaryColor ?? const Color(0xFF07C160)).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.store,
                          size: 14,
                          color: _tabController.index == 0
                              ? theme.primaryColor ?? const Color(0xFF07C160)
                              : theme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Flexible(
                        child: Text(
                          'All',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _tabController.index == 1
                              ? (theme.primaryColor ?? const Color(0xFF07C160)).withOpacity(0.15)
                              : (theme.primaryColor ?? const Color(0xFF07C160)).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.star,
                          size: 14,
                          color: _tabController.index == 1
                              ? theme.primaryColor ?? const Color(0xFF07C160)
                              : theme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Flexible(
                        child: Text(
                          'Featured',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _tabController.index == 2
                              ? (theme.primaryColor ?? const Color(0xFF07C160)).withOpacity(0.15)
                              : (theme.primaryColor ?? const Color(0xFF07C160)).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.verified,
                          size: 14,
                          color: _tabController.index == 2
                              ? theme.primaryColor ?? const Color(0xFF07C160)
                              : theme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Flexible(
                        child: Text(
                          'Verified',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildShopGrid(shops, theme),
                _buildShopGrid(shops.where((s) => s['isFeatured'] == true).toList(), theme),
                _buildShopGrid(shops.where((s) => s['isVerified'] == true).toList(), theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopGrid(List<Map<String, dynamic>> shops, ModernThemeExtension theme) {
    if (shops.isEmpty) {
      return _buildEmptyState(theme);
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Refresh shops
        await Future.delayed(const Duration(seconds: 1));
      },
      color: theme.primaryColor ?? const Color(0xFF07C160),
      backgroundColor: theme.surfaceColor,
      child: GridView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80), // FAB clearance
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: shops.length,
        itemBuilder: (context, index) {
          return _buildShopCard(shops[index], theme);
        },
      ),
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shop, ModernThemeExtension theme) {
    return GestureDetector(
      onTap: () {
        context.goToShopDetail(shop['id']);
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (theme.dividerColor ?? Colors.grey[300]!).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Banner
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: theme.surfaceVariantColor ?? Colors.grey[100],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                image: shop['shopBanner']?.isNotEmpty == true
                    ? DecorationImage(
                        image: NetworkImage(shop['shopBanner']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: shop['shopBanner']?.isEmpty != false
                  ? Center(
                      child: Icon(
                        Icons.store,
                        color: theme.textTertiaryColor ?? Colors.grey[400],
                        size: 48,
                      ),
                    )
                  : Stack(
                      children: [
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                        // Badges
                        if (shop['isFeatured'] == true || shop['isVerified'] == true)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Row(
                              children: [
                                if (shop['isFeatured'] == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 2),
                                        Text(
                                          'FEATURED',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (shop['isVerified'] == true)
                                  const SizedBox(width: 4),
                                if (shop['isVerified'] == true)
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.verified,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),

            // Shop Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Shop Name
                    Text(
                      shop['shopName'] ?? 'Unknown Shop',
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Location
                    if (shop['location']?.isNotEmpty == true)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: theme.textSecondaryColor,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              shop['location'],
                              style: TextStyle(
                                color: theme.textSecondaryColor,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    const Spacer(),

                    // Stats
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          color: theme.textSecondaryColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${shop['productsCount'] ?? 0}',
                          style: TextStyle(
                            color: theme.textSecondaryColor,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.people,
                          color: theme.textSecondaryColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatCount(shop['followersCount'] ?? 0),
                          style: TextStyle(
                            color: theme.textSecondaryColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
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

  Widget _buildEmptyState(ModernThemeExtension theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (theme.primaryColor ?? const Color(0xFF07C160)).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.store_outlined,
                size: 64,
                color: theme.textTertiaryColor ?? Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Shops Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to create a shop',
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
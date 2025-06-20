// lib/features/public_groups/screens/explore_public_groups_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/public_groups/models/public_group_model.dart';
import 'package:textgb/features/public_groups/providers/public_group_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class ExplorePublicGroupsScreen extends ConsumerStatefulWidget {
  const ExplorePublicGroupsScreen({super.key});

  @override
  ConsumerState<ExplorePublicGroupsScreen> createState() => _ExplorePublicGroupsScreenState();
}

class _ExplorePublicGroupsScreenState extends ConsumerState<ExplorePublicGroupsScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  List<PublicGroupModel> _searchResults = [];
  List<PublicGroupModel> _trendingGroups = [];
  
  bool _isSearching = false;
  bool _isLoadingTrending = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTrendingGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTrendingGroups() async {
    setState(() {
      _isLoadingTrending = true;
    });

    try {
      await ref.read(publicGroupProvider.notifier).getTrendingPublicGroups();
      final state = ref.read(publicGroupProvider).valueOrNull;
      if (state != null) {
        setState(() {
          _trendingGroups = state.discoveredPublicGroups;
        });
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error loading trending groups: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTrending = false;
        });
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await ref.read(publicGroupProvider.notifier).searchPublicGroups(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        showSnackBar(context, 'Search error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Explore Groups',
          style: TextStyle(
            color: theme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.surfaceVariantColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for groups...',
                      hintStyle: TextStyle(
                        color: theme.textSecondaryColor,
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: theme.textSecondaryColor,
                        size: 22,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 16,
                    ),
                    onChanged: _performSearch,
                  ),
                ),
              ),
              
              // Tab bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                height: 44,
                decoration: BoxDecoration(
                  color: theme.surfaceVariantColor,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(3),
                  labelColor: Colors.white,
                  unselectedLabelColor: theme.textSecondaryColor,
                  labelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Search Results'),
                    Tab(text: 'Trending'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(theme),
          _buildTrendingTab(theme),
        ],
      ),
    );
  }

  Widget _buildSearchTab(ModernThemeExtension theme) {
    if (_searchController.text.trim().isEmpty) {
      return _buildSearchPrompt(theme);
    }

    if (_isSearching) {
      return _buildLoadingState(theme);
    }

    if (_searchResults.isEmpty) {
      return _buildNoResultsState(theme);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final group = _searchResults[index];
        return _buildGroupCard(group, theme);
      },
    );
  }

  Widget _buildTrendingTab(ModernThemeExtension theme) {
    if (_isLoadingTrending) {
      return _buildLoadingState(theme);
    }

    if (_trendingGroups.isEmpty) {
      return _buildEmptyTrendingState(theme);
    }

    return RefreshIndicator(
      onRefresh: _loadTrendingGroups,
      color: theme.primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _trendingGroups.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final group = _trendingGroups[index];
          return _buildGroupCard(group, theme, showTrendingBadge: true);
        },
      ),
    );
  }

  Widget _buildGroupCard(
    PublicGroupModel group, 
    ModernThemeExtension theme, 
    {bool showTrendingBadge = false}
  ) {
    final currentUser = ref.watch(currentUserProvider);
    final isSubscribed = currentUser != null && group.isSubscriber(currentUser.uid);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPublicGroup(group),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header section
                Row(
                  children: [
                    // Group Avatar
                    _buildGroupAvatar(group, theme),
                    
                    const SizedBox(width: 16),
                    
                    // Group Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  group.groupName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: theme.textColor,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (group.isVerified) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.verified_rounded,
                                  size: 20,
                                  color: theme.primaryColor,
                                ),
                              ],
                              if (showTrendingBadge) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.orange.shade400,
                                        Colors.orange.shade600,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'TRENDING',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Followers count
                          Row(
                            children: [
                              Icon(
                                Icons.people_alt_rounded,
                                size: 16,
                                color: theme.textTertiaryColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                group.getSubscribersText(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.textTertiaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Description
                if (group.groupDescription.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      group.groupDescription,
                      style: TextStyle(
                        fontSize: 15,
                        color: theme.textSecondaryColor,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),
                
                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubscribed ? null : () => _subscribeToGroup(group),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSubscribed 
                          ? theme.surfaceVariantColor 
                          : theme.primaryColor,
                      foregroundColor: isSubscribed 
                          ? theme.textSecondaryColor 
                          : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: isSubscribed 
                            ? BorderSide(
                                color: theme.borderColor!.withOpacity(0.2),
                                width: 1,
                              )
                            : BorderSide.none,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSubscribed ? Icons.check_rounded : Icons.add_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isSubscribed ? 'Following' : 'Follow',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupAvatar(PublicGroupModel group, ModernThemeExtension theme) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.primaryColor!.withOpacity(0.1),
      ),
      child: group.groupImage.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                group.groupImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackAvatar(group.groupName, theme);
                },
              ),
            )
          : _buildFallbackAvatar(group.groupName, theme),
    );
  }

  Widget _buildFallbackAvatar(String groupName, ModernThemeExtension theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor!,
            theme.primaryColor!.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Text(
          groupName.isNotEmpty ? groupName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchPrompt(ModernThemeExtension theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.surfaceVariantColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_rounded,
                size: 48,
                color: theme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Search for Groups',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Type in the search box above to find communities',
              style: TextStyle(
                fontSize: 15,
                color: theme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(ModernThemeExtension theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.surfaceVariantColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48,
                color: theme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No groups found',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                fontSize: 15,
                color: theme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTrendingState(ModernThemeExtension theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.surfaceVariantColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.trending_up_rounded,
                size: 48,
                color: theme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No trending groups',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Check back later for popular communities',
              style: TextStyle(
                fontSize: 15,
                color: theme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ModernThemeExtension theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.primaryColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Loading...',
            style: TextStyle(
              color: theme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _subscribeToGroup(PublicGroupModel group) async {
    try {
      await ref.read(publicGroupProvider.notifier).subscribeToPublicGroup(group.groupId);
      if (mounted) {
        showSnackBar(context, 'Following ${group.groupName}');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error following group: $e');
      }
    }
  }

  void _openPublicGroup(PublicGroupModel group) {
    Navigator.pushNamed(
      context,
      Constants.publicGroupFeedScreen,
      arguments: group,
    );
  }
}
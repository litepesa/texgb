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

  Future<void> _subscribeToGroup(PublicGroupModel group) async {
    try {
      await ref.read(publicGroupProvider.notifier).subscribeToPublicGroup(group.groupId);
      if (mounted) {
        showSnackBar(context, 'Subscribed to ${group.groupName}');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error subscribing: $e');
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
        title: Text(
          'Explore Groups',
          style: TextStyle(color: theme.textColor),
        ),
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.surfaceVariantColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search public groups...',
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                decoration: BoxDecoration(
                  color: theme.surfaceVariantColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(2),
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
              const SizedBox(height: 16),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        itemCount: _trendingGroups.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.borderColor!.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPublicGroup(group),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Group Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: theme.primaryColor!.withOpacity(0.1),
                      ),
                      child: group.groupImage.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                group.groupImage,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildGroupAvatar(group.groupName, theme);
                                },
                              ),
                            )
                          : _buildGroupAvatar(group.groupName, theme),
                    ),
                    
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
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (group.isVerified)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  child: Icon(
                                    Icons.verified,
                                    size: 20,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              if (showTrendingBadge)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'TRENDING',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 4),
                          
                          Text(
                            group.getSubscribersText(),
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textSecondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                if (group.groupDescription.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    group.groupDescription,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textColor,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSubscribed 
                              ? theme.surfaceVariantColor 
                              : theme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isSubscribed ? null : () => _subscribeToGroup(group),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                isSubscribed ? 'Following' : 'Follow',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSubscribed 
                                      ? theme.textColor 
                                      : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: theme.surfaceVariantColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openPublicGroup(group),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: theme.textColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupAvatar(String groupName, ModernThemeExtension theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor!,
            theme.primaryColor!.withOpacity(0.8),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 80,
              color: theme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Search for Groups',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type in the search box above to find public groups',
              style: TextStyle(
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: theme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No groups found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 80,
              color: theme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No trending groups',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for trending public groups',
              style: TextStyle(
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
          CircularProgressIndicator(color: theme.primaryColor),
          const SizedBox(height: 16),
          Text(
            'Loading groups...',
            style: TextStyle(
              color: theme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _openPublicGroup(PublicGroupModel group) {
    Navigator.pushNamed(
      context,
      Constants.publicGroupFeedScreen,
      arguments: group,
    );
  }
}
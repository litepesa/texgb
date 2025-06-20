// lib/features/public_groups/screens/public_groups_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/public_groups/models/public_group_model.dart';
import 'package:textgb/features/public_groups/providers/public_group_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class PublicGroupsScreen extends ConsumerStatefulWidget {
  const PublicGroupsScreen({super.key});

  @override
  ConsumerState<PublicGroupsScreen> createState() => _PublicGroupsScreenState();
}

class _PublicGroupsScreenState extends ConsumerState<PublicGroupsScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchActive = false;
  List<PublicGroupModel> _searchResults = [];
  bool _isSearching = false;
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
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
    super.build(context);
    final theme = context.modernTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          pinned: true,
          elevation: 0,
          backgroundColor: theme.backgroundColor,
          title: _isSearchActive
              ? null
              : Text(
                  'Public Groups',
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          centerTitle: false,
          actions: [
            if (!_isSearchActive)
              TextButton(
                onPressed: () => Navigator.pushNamed(
                    context, Constants.explorePublicGroupsScreen),
                child: Text(
                  'Explore',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(72),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildSearchBar(theme),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(bottom: bottomPadding + 16),
          sliver: _isSearchActive && _searchQuery.isNotEmpty
              ? _buildSearchResultsSliver(theme)
              : _buildMainContentSliver(theme),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ModernThemeExtension theme) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: theme.surfaceVariantColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: TextField(
          controller: _searchController,
          onTap: () {
            if (!_isSearchActive) {
              setState(() => _isSearchActive = true);
            }
          },
          onChanged: (value) {
            setState(() => _searchQuery = value);
            _performSearch(value);
          },
          decoration: InputDecoration(
            hintText: 'Search public groups...',
            hintStyle: TextStyle(
              color: theme.textSecondaryColor,
              fontSize: 15,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: theme.textSecondaryColor,
              size: 20,
            ),
            suffixIcon: _isSearchActive
                ? IconButton(
                    icon: Icon(Icons.close, color: theme.textSecondaryColor),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _isSearchActive = false;
                        _searchQuery = '';
                        _searchResults = [];
                      });
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          style: TextStyle(
            color: theme.textColor,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildMainContentSliver(ModernThemeExtension theme) {
    final publicGroupsAsync = ref.watch(userPublicGroupsStreamProvider);

    return publicGroupsAsync.when(
      data: (publicGroups) {
        if (publicGroups.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(theme),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final publicGroup = publicGroups[index];
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _buildGroupCard(publicGroup, theme),
              );
            },
            childCount: publicGroups.length,
          ),
        );
      },
      loading: () => SliverFillRemaining(
        child: _buildLoadingState(theme),
      ),
      error: (error, stack) => SliverFillRemaining(
        child: _buildErrorState(error.toString(), theme),
      ),
    );
  }

  // Missing method - this is what was causing the red line!
  Widget _buildSearchResultsSliver(ModernThemeExtension theme) {
    if (_isSearching) {
      return SliverFillRemaining(
        child: _buildLoadingState(theme),
      );
    }

    if (_searchResults.isEmpty && _searchQuery.isNotEmpty) {
      return SliverFillRemaining(
        child: _buildNoResultsState(theme),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final publicGroup = _searchResults[index];
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _buildGroupCard(publicGroup, theme),
          );
        },
        childCount: _searchResults.length,
      ),
    );
  }

  Widget _buildGroupCard(PublicGroupModel publicGroup, ModernThemeExtension theme) {
    final currentUser = ref.watch(currentUserProvider);
    final isSubscribed = currentUser != null && 
        publicGroup.isSubscriber(currentUser.uid);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openPublicGroup(publicGroup),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGroupAvatar(publicGroup, theme),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            publicGroup.groupName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (publicGroup.isVerified)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.verified,
                              size: 18,
                              color: theme.primaryColor,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: theme.textTertiaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          publicGroup.getSubscribersText(),
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.textTertiaryColor,
                          ),
                        ),
                        if (isSubscribed) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor!.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Following',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (publicGroup.groupDescription.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        publicGroup.groupDescription,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textSecondaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupAvatar(PublicGroupModel publicGroup, ModernThemeExtension theme) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.primaryColor!.withOpacity(0.1),
      ),
      child: publicGroup.groupImage.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                publicGroup.groupImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackAvatar(publicGroup.groupName, theme);
                },
              ),
            )
          : _buildFallbackAvatar(publicGroup.groupName, theme),
    );
  }

  Widget _buildFallbackAvatar(String groupName, ModernThemeExtension theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ModernThemeExtension theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.surfaceVariantColor,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.campaign_outlined,
                size: 40,
                color: theme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No groups yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create or discover communities to get started',
              style: TextStyle(
                fontSize: 15,
                color: theme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  theme: theme,
                  icon: Icons.add,
                  label: 'Create',
                  isPrimary: true,
                  onTap: () => Navigator.pushNamed(
                      context, Constants.createPublicGroupScreen),
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  theme: theme,
                  icon: Icons.explore,
                  label: 'Explore',
                  isPrimary: false,
                  onTap: () => Navigator.pushNamed(
                      context, Constants.explorePublicGroupsScreen),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required ModernThemeExtension theme,
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isPrimary ? theme.primaryColor : theme.surfaceVariantColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isPrimary ? Colors.white : theme.textColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isPrimary ? Colors.white : theme.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
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
            Icon(
              Icons.search_off,
              size: 48,
              color: theme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No groups found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords',
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
      child: CircularProgressIndicator(color: theme.primaryColor),
    );
  }

  Widget _buildErrorState(String error, ModernThemeExtension theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: theme.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(userPublicGroupsStreamProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _openPublicGroup(PublicGroupModel publicGroup) {
    Navigator.pushNamed(
      context,
      Constants.publicGroupFeedScreen,
      arguments: publicGroup,
    );
  }
}
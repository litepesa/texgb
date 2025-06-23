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

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: theme.backgroundColor,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: theme.textColor,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: _isSearchActive
                ? null
                : Text(
                    'Public Groups',
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
            centerTitle: false,
            actions: [
              if (!_isSearchActive)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(
                        context, Constants.explorePublicGroupsScreen),
                    style: TextButton.styleFrom(
                      backgroundColor: theme.primaryColor!.withOpacity(0.1),
                      foregroundColor: theme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Explore',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: _buildSearchBar(theme),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: bottomPadding + 16,
            ),
            sliver: _isSearchActive && _searchQuery.isNotEmpty
                ? _buildSearchResultsSliver(theme)
                : _buildMainContentSliver(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ModernThemeExtension theme) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: _isSearchActive 
              ? theme.primaryColor!.withOpacity(0.3)
              : theme.surfaceVariantColor!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
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
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(14),
            child: Icon(
              Icons.search_rounded,
              color: _isSearchActive 
                  ? theme.primaryColor 
                  : theme.textSecondaryColor,
              size: 22,
            ),
          ),
          suffixIcon: _isSearchActive
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: theme.textSecondaryColor,
                    size: 22,
                  ),
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
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        style: TextStyle(
          color: theme.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w400,
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
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
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
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
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

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.surfaceVariantColor!.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openPublicGroup(publicGroup),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: theme.textColor,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (publicGroup.isVerified) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: theme.primaryColor!.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.verified,
                                size: 16,
                                color: theme.primaryColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.surfaceVariantColor!.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.people_rounded,
                              size: 12,
                              color: theme.textTertiaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            publicGroup.getSubscribersText(),
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textTertiaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isSubscribed) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primaryColor!.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
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
                        const SizedBox(height: 12),
                        Text(
                          publicGroup.groupDescription,
                          style: TextStyle(
                            fontSize: 15,
                            color: theme.textSecondaryColor,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
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
      ),
    );
  }

  Widget _buildGroupAvatar(PublicGroupModel publicGroup, ModernThemeExtension theme) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.surfaceVariantColor!.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: publicGroup.groupImage.isNotEmpty
            ? Image.network(
                publicGroup.groupImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackAvatar(publicGroup.groupName, theme);
                },
              )
            : _buildFallbackAvatar(publicGroup.groupName, theme),
      ),
    );
  }

  Widget _buildFallbackAvatar(String groupName, ModernThemeExtension theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
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
            fontSize: 22,
            fontWeight: FontWeight.w700,
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.surfaceVariantColor!.withOpacity(0.6),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.campaign_outlined,
                size: 48,
                color: theme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No groups yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create or discover communities to get started',
              style: TextStyle(
                fontSize: 16,
                color: theme.textSecondaryColor,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  theme: theme,
                  icon: Icons.add_rounded,
                  label: 'Create',
                  isPrimary: true,
                  onTap: () => Navigator.pushNamed(
                      context, Constants.createPublicGroupScreen),
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  theme: theme,
                  icon: Icons.explore_rounded,
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
        color: isPrimary ? theme.primaryColor : theme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: isPrimary ? null : Border.all(
          color: theme.surfaceVariantColor!.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isPrimary ? Colors.white : theme.textColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isPrimary ? Colors.white : theme.textColor,
                    fontSize: 16,
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.surfaceVariantColor!.withOpacity(0.6),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 40,
                color: theme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No groups found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: TextStyle(
                fontSize: 16,
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
      child: CircularProgressIndicator(
        color: theme.primaryColor,
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildErrorState(String error, ModernThemeExtension theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Colors.red.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                color: theme.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(userPublicGroupsStreamProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Retry',
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

  void _openPublicGroup(PublicGroupModel publicGroup) {
    Navigator.pushNamed(
      context,
      Constants.publicGroupFeedScreen,
      arguments: publicGroup,
    );
  }
}
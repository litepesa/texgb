// lib/features/users/screens/users_list_screen.dart
// UPDATED: Live status tracking with Chinese Red styling and last post time display
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/core/router/route_paths.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

// Chinese Red color for live indicators
const Color kChineseRed = Color(0xFFDE2910);

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'All';
  bool _isInitialized = false;
  bool _isLoadingInitial = false;
  String? _error;
  bool _showMarketplaceBanner = true;
  late AnimationController _bannerAnimationController;
  late Animation<double> _bannerAnimation;
  
  final List<String> categories = ['All', 'Following', 'Live'];

  @override
  void initState() {
    super.initState();
    _bannerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bannerAnimation = CurvedAnimation(
      parent: _bannerAnimationController,
      curve: Curves.elasticOut,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
      _checkBannerStatus();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bannerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _checkBannerStatus() async {
    if (mounted) {
      setState(() {
        _showMarketplaceBanner = true;
      });
      _bannerAnimationController.forward();
    }
  }

  Future<void> _dismissBanner() async {
    if (mounted) {
      setState(() {
        _showMarketplaceBanner = false;
      });
    }
  }

  void _navigateToMarketplace() {
    HapticFeedback.mediumImpact();
    context.push(RoutePaths.videosFeed);
  }

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

  bool get _hasCachedData {
    final users = ref.read(usersProvider);
    return users.isNotEmpty;
  }

  void _initializeScreen() {
    if (_hasCachedData) {
      setState(() {
        _isInitialized = true;
      });
      debugPrint('Users screen: Using cached data');
    } else {
      debugPrint('Users screen: No cached data found, loading initial data');
      _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingInitial = true;
      _error = null;
    });

    try {
      await ref.read(authenticationProvider.notifier).loadUsers();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoadingInitial = false;
        });
        debugPrint('Users screen: Initial data loaded successfully');
      }
    } catch (e) {
      debugPrint('Users screen: Error loading initial data: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingInitial = false;
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _refreshUsers() async {
    try {
      await ref.read(authenticationProvider.notifier).loadUsers();
      if (_error != null) {
        setState(() {
          _error = null;
        });
      }
      debugPrint('Users screen: Data refreshed successfully');
    } catch (e) {
      debugPrint('Users screen: Error refreshing data: $e');
    }
  }

  List<UserModel> get filteredUsers {
    final users = ref.watch(usersProvider);
    final followedUsers = ref.watch(followedUsersProvider);
    final currentUser = ref.watch(currentUserProvider);
    
    List<UserModel> filteredList;
    
    switch (_selectedCategory) {
      case 'Following':
        filteredList = users
            .where((user) => followedUsers.contains(user.id))
            .toList();
        break;
      case 'Live':
        filteredList = users
            .where((user) => user.isLive)
            .toList();
        break;
      default:
        filteredList = users;
        break;
    }

    if (currentUser != null) {
      filteredList.removeWhere((user) => user.id == currentUser.id);
    }
    
    filteredList.removeWhere((user) => user.videosCount == 0);
    
    filteredList.sort((a, b) {
      // Live users always come first
      if (a.isLive && !b.isLive) return -1;
      if (!a.isLive && b.isLive) return 1;
      
      final aLastPost = a.lastPostAtDateTime;
      final bLastPost = b.lastPostAtDateTime;
      
      if (aLastPost != null && bLastPost != null) {
        return bLastPost.compareTo(aLastPost);
      }
      
      if (aLastPost != null && bLastPost == null) return -1;
      if (aLastPost == null && bLastPost != null) return 1;
      
      return b.createdAt.compareTo(a.createdAt);
    });
    
    return filteredList;
  }

  Future<void> _navigateToUserProfile(UserModel user) async {
    try {
      HapticFeedback.lightImpact();
      
      final userVideos = ref.read(videosProvider).where((video) => video.userId == user.id).toList();
      
      if (userVideos.isNotEmpty) {
        // Navigate to single video with user context
        context.push(
          RoutePaths.singleVideo(userVideos.first.id),
          extra: {
            'userId': user.id,
          },
        );
      } else {
        _showSnackBar('${user.name} hasn\'t posted any videos yet');
        context.push(RoutePaths.userProfile(user.id));
      }
    } catch (e) {
      context.push(RoutePaths.userProfile(user.id));
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getSafeTheme(context);
    
    return Scaffold(
      backgroundColor: theme.surfaceColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Enhanced Custom App Bar
                Container(
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
                      // Manage Button - Navigate to Manage Post Screen
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.push(RoutePaths.managePosts);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              CupertinoIcons.gear,
                              color: theme.primaryColor ?? const Color(0xFFFE2C55),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      
                      Expanded(
                        child: Center(
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: _navigateToMarketplace,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFFE2C55),
                                      const Color(0xFFFE2C55).withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFE2C55).withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.explore_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Discover',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Search Button
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            showSearch(
                              context: context,
                              delegate: UserSearchDelegate(ref: ref),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.search_rounded,
                              color: theme.primaryColor ?? const Color(0xFFFE2C55),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Users List with integrated filter tabs
                Expanded(
                  child: Container(
                    color: theme.surfaceColor,
                    child: !_isInitialized 
                      ? _buildInitialLoadingView(theme)
                      : _error != null
                          ? _buildErrorView(theme)
                          : _buildUsersListWithTabs(),
                  ),
                ),
              ],
            ),
            
            // Eye-catching Marketplace Banner
            if (_showMarketplaceBanner)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.35,
                left: 16,
                right: 16,
                child: ScaleTransition(
                  scale: _bannerAnimation,
                  child: _buildMarketplaceBanner(theme),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketplaceBanner(ModernThemeExtension theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFE2C55),
            const Color(0xFFFF6B6B),
            const Color(0xFFFE2C55),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFE2C55).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToMarketplace,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                // Close button
                Positioned(
                  top: 0,
                  right: 0,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _dismissBanner();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Banner content
                Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Row(
                    children: [
                      // Animated icon
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(seconds: 2),
                        builder: (context, value, child) {
                          return Transform.rotate(
                            angle: value * 0.1,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                CupertinoIcons.compass,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  '🎉 Tap to Explore!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'NEW',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Discover amazing stories and live streams on WemaChat!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Watch Now',
                                    style: TextStyle(
                                      color: theme.primaryColor ?? const Color(0xFFFE2C55),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: theme.primaryColor ?? const Color(0xFFFE2C55),
                                    size: 14,
                                  ),
                                ],
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
            _isLoadingInitial ? 'Loading users...' : 'Initializing...',
            style: TextStyle(
              color: theme.textSecondaryColor ?? Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(ModernThemeExtension theme) {
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
              'Unable to load users',
              style: TextStyle(
                color: theme.textColor ?? Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(
                color: theme.textSecondaryColor ?? Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadInitialData,
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Following':
        return Icons.favorite;
      case 'Live':
        return Icons.sensors;
      default:
        return Icons.people;
    }
  }

  Widget _buildUsersListWithTabs() {
    final theme = _getSafeTheme(context);
    final users = filteredUsers;

    if (users.isEmpty && _error == null) {
      return RefreshIndicator(
        onRefresh: _refreshUsers,
        color: theme.primaryColor ?? const Color(0xFFFE2C55),
        backgroundColor: theme.surfaceColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildCategoryTabs(theme),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getEmptyStateIcon(),
                          color: theme.textTertiaryColor ?? Colors.grey[400],
                          size: 64,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _getEmptyStateTitle(),
                          style: TextStyle(
                            color: theme.textColor ?? Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getEmptyStateSubtitle(),
                          style: TextStyle(
                            color: theme.textSecondaryColor ?? Colors.grey[600],
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_selectedCategory == 'All') ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.push(RoutePaths.createProfile);
                            },
                            icon: const Icon(Icons.person_add),
                            label: const Text('Join WeiBao'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor ?? const Color(0xFFFE2C55),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshUsers,
      color: theme.primaryColor ?? const Color(0xFFFE2C55),
      backgroundColor: theme.surfaceColor,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildCategoryTabs(theme),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final user = users[index];
                return Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: index == users.length - 1 ? 16 : 8,
                  ),
                  child: _buildUserItem(user),
                );
              },
              childCount: users.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(ModernThemeExtension theme) {
    return Container(
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
        children: categories.map((category) {
          final isSelected = _selectedCategory == category;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedCategory = category;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? Border(
                    bottom: BorderSide(
                      color: theme.primaryColor ?? const Color(0xFFFE2C55),
                      width: 3,
                    ),
                  ) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.15)
                          : (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _getCategoryIcon(category),
                        color: isSelected 
                          ? theme.primaryColor ?? const Color(0xFFFE2C55)
                          : theme.textSecondaryColor ?? Colors.grey[600],
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: isSelected 
                            ? theme.primaryColor ?? const Color(0xFFFE2C55)
                            : theme.textSecondaryColor ?? Colors.grey[600],
                          fontWeight: isSelected 
                            ? FontWeight.w700 
                            : FontWeight.w500,
                          fontSize: 12,
                          letterSpacing: 0.1,
                        ),
                        child: Text(
                          category,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
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

  IconData _getEmptyStateIcon() {
    switch (_selectedCategory) {
      case 'Following':
        return Icons.favorite_outline;
      case 'Live':
        return Icons.sensors_off;
      default:
        return Icons.people_outline;
    }
  }

  String _getEmptyStateTitle() {
    switch (_selectedCategory) {
      case 'Following':
        return 'No Followed Users';
      case 'Live':
        return 'No Live Streams';
      default:
        return 'No Users Available';
    }
  }

  String _getEmptyStateSubtitle() {
    switch (_selectedCategory) {
      case 'Following':
        return 'Start following users to see them here';
      case 'Live':
        return 'No one is currently live streaming';
      default:
        return 'Users will appear here when they join WeiBao';
    }
  }

  Widget _buildUserItem(UserModel user) {
    final followedUsers = ref.watch(followedUsersProvider);
    final isFollowing = followedUsers.contains(user.id);
    final theme = _getSafeTheme(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: user.isLive 
            ? kChineseRed.withOpacity(0.4)
            : (theme.dividerColor ?? Colors.grey[300]!).withOpacity(0.15),
          width: user.isLive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: user.isLive 
              ? kChineseRed.withOpacity(0.2)
              : (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.08),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToUserProfile(user),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: user.isLive ? BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kChineseRed.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ) : null,
            child: Row(
              children: [
                Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 52,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: user.isLive ? LinearGradient(
                          colors: [kChineseRed, kChineseRed.withOpacity(0.7)],
                        ) : null,
                        border: !user.isLive ? Border.all(
                          color: (theme.dividerColor ?? Colors.grey[300]!).withOpacity(0.2),
                          width: 1,
                        ) : null,
                        boxShadow: [
                          BoxShadow(
                            color: (user.isLive ? kChineseRed : (theme.primaryColor ?? const Color(0xFFFE2C55)))
                                .withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: user.profileImage.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: user.profileImage,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    decoration: BoxDecoration(
                                      color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: theme.primaryColor ?? const Color(0xFFFE2C55),
                                      size: 22,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    decoration: BoxDecoration(
                                      color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: theme.primaryColor ?? const Color(0xFFFE2C55),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: theme.primaryColor ?? const Color(0xFFFE2C55),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    if (user.isLive)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: kChineseRed,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.surfaceColor ?? Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: kChineseRed.withOpacity(0.5),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.sensors,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: theme.textColor ?? Colors.black,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 16,
                            ),
                          ],
                          if (user.isLive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: kChineseRed,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: kChineseRed.withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.circle,
                                    color: Colors.white,
                                    size: 8,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'LIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildStatChip(
                              icon: Icons.video_library_outlined,
                              text: '${user.videosCount} posts',
                              theme: theme,
                            ),
                            const SizedBox(width: 8),
                            _buildStatChip(
                              icon: Icons.people_outline_rounded,
                              text: _formatCount(user.followers),
                              theme: theme,
                            ),
                            const SizedBox(width: 8),
                            _buildStatChip(
                              icon: Icons.favorite_outline,
                              text: _formatCount(user.likesCount),
                              theme: theme,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Last activity - exact styling from sample screen
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 10,
                              color: theme.primaryColor ?? const Color(0xFFFE2C55),
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                user.lastPostAt != null 
                                  ? 'last Post ${user.lastPostTimeAgo}'
                                  : 'No posts',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.primaryColor ?? const Color(0xFFFE2C55),
                                  fontWeight: FontWeight.w600,
                                ),
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
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(authenticationProvider.notifier).followUser(user.id);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      constraints: const BoxConstraints(
                        minWidth: 80,
                        maxWidth: 100,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isFollowing ? (theme.surfaceVariantColor ?? Colors.grey[100]) : (theme.primaryColor ?? const Color(0xFFFE2C55)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isFollowing 
                            ? (theme.dividerColor ?? Colors.grey[300]!).withOpacity(0.3)
                            : (theme.primaryColor ?? const Color(0xFFFE2C55)),
                          width: 1,
                        ),
                        boxShadow: !isFollowing ? [
                          BoxShadow(
                            color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isFollowing 
                                ? (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.15)
                                : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Icon(
                              isFollowing ? Icons.check_rounded : Icons.add_rounded,
                              color: isFollowing ? (theme.primaryColor ?? const Color(0xFFFE2C55)) : Colors.white,
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              isFollowing ? 'Following' : 'Follow',
                              style: TextStyle(
                                color: isFollowing ? (theme.primaryColor ?? const Color(0xFFFE2C55)) : Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildStatChip({
    required IconData icon,
    required String text,
    required ModernThemeExtension theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: (theme.surfaceVariantColor ?? Colors.grey[100]!).withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (theme.dividerColor ?? Colors.grey[300]!).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: theme.textSecondaryColor ?? Colors.grey[600],
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: theme.textSecondaryColor ?? Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}

// Search Delegate with GoRouter navigation
class UserSearchDelegate extends SearchDelegate<UserModel?> {
  final WidgetRef ref;

  UserSearchDelegate({required this.ref});

  @override
  String get searchFieldLabel => 'Search users...';

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

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = _getSafeTheme(context);
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.surfaceColor,
        foregroundColor: theme.textColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: theme.textSecondaryColor),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final theme = _getSafeTheme(context);
    
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: theme.textTertiaryColor ?? Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Search for users',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textColor ?? Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find sellers and businesses on WeiBao',
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondaryColor ?? Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<UserModel>>(
      future: ref.read(authenticationProvider.notifier).searchUsers(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: theme.primaryColor ?? const Color(0xFFFE2C55),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.textTertiaryColor ?? Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Search Error',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor ?? Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Unable to search users at the moment',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textSecondaryColor ?? Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final filteredUsers = snapshot.data ?? [];

        if (filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_search,
                  size: 64,
                  color: theme.textTertiaryColor ?? Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No users found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor ?? Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try searching with different keywords',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textSecondaryColor ?? Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          color: theme.surfaceColor,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              final followedUsers = ref.watch(followedUsersProvider);
              final isFollowing = followedUsers.contains(user.id);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (theme.dividerColor ?? Colors.grey[300]!).withOpacity(0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    close(context, user);
                    context.push(RoutePaths.userProfile(user.id));
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (theme.dividerColor ?? Colors.grey[300]!).withOpacity(0.2),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: user.profileImage.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: user.profileImage,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.1),
                                    child: Icon(
                                      Icons.person,
                                      color: theme.primaryColor ?? const Color(0xFFFE2C55),
                                      size: 24,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.15),
                                    child: Center(
                                      child: Text(
                                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: theme.primaryColor ?? const Color(0xFFFE2C55),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.15),
                                  child: Center(
                                    child: Text(
                                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: theme.primaryColor ?? const Color(0xFFFE2C55),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: theme.textColor ?? Colors.black,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (user.isLive) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: kChineseRed,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.circle,
                                          color: Colors.white,
                                          size: 8,
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          'LIVE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${user.videosCount} posts • ${_formatCount(user.followers)} followers',
                              style: TextStyle(
                                color: theme.textSecondaryColor ?? Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            if (user.bio.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                user.bio,
                                style: TextStyle(
                                  color: theme.textSecondaryColor ?? Colors.grey[600],
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref.read(authenticationProvider.notifier).followUser(user.id);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isFollowing ? (theme.surfaceVariantColor ?? Colors.grey[100]) : (theme.primaryColor ?? const Color(0xFFFE2C55)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isFollowing 
                                  ? (theme.dividerColor ?? Colors.grey[300]!).withOpacity(0.3)
                                  : (theme.primaryColor ?? const Color(0xFFFE2C55)),
                              ),
                            ),
                            child: Text(
                              isFollowing ? 'Following' : 'Follow',
                              style: TextStyle(
                                color: isFollowing ? (theme.primaryColor ?? const Color(0xFFFE2C55)) : Colors.white,
                                fontSize: 12,
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
            },
          ),
        );
      },
    );
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}
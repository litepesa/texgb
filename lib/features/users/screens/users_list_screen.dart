// lib/features/users/screens/users_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'All';
  
  final List<String> categories = ['All', 'Following', 'Verified'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authenticationProvider.notifier).loadUsers();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      case 'Verified':
        filteredList = users
            .where((user) => user.isVerified)
            .toList();
        break;
      default: // 'All'
        filteredList = users;
        break;
    }

    // Always filter out current user
    if (currentUser != null) {
      filteredList.removeWhere((user) => user.id == currentUser.id);
    }
    
    // Sort by latest activity - most recent first
    filteredList.sort((a, b) {
      // Verified users always come first
      if (a.isVerified && !b.isVerified) return -1;
      if (!a.isVerified && b.isVerified) return 1;
      
      // Then sort by last activity
      final aLastPost = a.lastPostAtDateTime;
      final bLastPost = b.lastPostAtDateTime;
      
      // Users with recent posts come first
      if (aLastPost != null && bLastPost != null) {
        return bLastPost.compareTo(aLastPost); // Most recent first
      }
      
      // Users with any posts come before users with no posts
      if (aLastPost != null && bLastPost == null) return -1;
      if (aLastPost == null && bLastPost != null) return 1;
      
      // For users with no posts, sort by creation date (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });
    
    return filteredList;
  }

  Future<void> _navigateToUserProfile(UserModel user) async {
    try {
      HapticFeedback.lightImpact();
      
      final userVideos = ref.read(videosProvider).where((video) => video.userId == user.id).toList();
      
      if (userVideos.isNotEmpty) {
        Navigator.pushNamed(
          context,
          Constants.singleVideoScreen,
          arguments: {
            Constants.startVideoId: userVideos.first.id,
            Constants.userId: user.id,
          },
        );
      } else {
        _showSnackBar('${user.name} hasn\'t posted any videos yet');
        Navigator.pushNamed(
          context,
          Constants.userProfileScreen,
          arguments: user.id,
        );
      }
    } catch (e) {
      Navigator.pushNamed(
        context,
        Constants.userProfileScreen,
        arguments: user.id,
      );
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
    final theme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: theme.surfaceColor, // Use surfaceColor as primary background
      body: SafeArea(
        child: Column(
          children: [
            // Category Filter Tabs - Enhanced Design
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: theme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor!.withOpacity(0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor!.withOpacity(0.08),
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
                              color: theme.primaryColor!,
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
                                  ? theme.primaryColor!.withOpacity(0.15)
                                  : theme.primaryColor!.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                _getCategoryIcon(category),
                                color: isSelected 
                                  ? theme.primaryColor 
                                  : theme.textSecondaryColor,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  color: isSelected 
                                    ? theme.primaryColor 
                                    : theme.textSecondaryColor,
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
            ),
            
            // Users List
            Expanded(
              child: Container(
                color: theme.surfaceColor, // Consistent background
                child: _buildUsersList(),
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
      case 'Verified':
        return Icons.verified;
      default:
        return Icons.people;
    }
  }

  Widget _buildUsersList() {
    final theme = context.modernTheme;
    final authState = ref.watch(authenticationProvider);
    
    return authState.when(
      data: (data) {
        if (data.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: theme.primaryColor,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading users...',
                  style: TextStyle(
                    color: theme.textSecondaryColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        final users = filteredUsers;

        if (users.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getEmptyStateIcon(),
                    color: theme.textTertiaryColor,
                    size: 64,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _getEmptyStateTitle(),
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getEmptyStateSubtitle(),
                    style: TextStyle(
                      color: theme.textSecondaryColor,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_selectedCategory == 'All') ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, Constants.createProfileScreen);
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Join WeiBao'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
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
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(authenticationProvider.notifier).loadUsers();
          },
          color: theme.primaryColor,
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final user = users[index];
              return _buildUserItem(user);
            },
          ),
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(
          color: theme.primaryColor,
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: theme.textTertiaryColor,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load users',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(
                  color: theme.textSecondaryColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(authenticationProvider.notifier).loadUsers();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getEmptyStateIcon() {
    switch (_selectedCategory) {
      case 'Following':
        return Icons.favorite_outline;
      case 'Verified':
        return Icons.verified_outlined;
      default:
        return Icons.people_outline;
    }
  }

  String _getEmptyStateTitle() {
    switch (_selectedCategory) {
      case 'Following':
        return 'No Followed Users';
      case 'Verified':
        return 'No Verified Users';
      default:
        return 'No Users Available';
    }
  }

  String _getEmptyStateSubtitle() {
    switch (_selectedCategory) {
      case 'Following':
        return 'Start following users to see them here';
      case 'Featured':
        return 'Featured creators will appear here when available';
      default:
        return 'Users will appear here when they join WeiBao';
    }
  }

  Widget _buildUserItem(UserModel user) {
    final followedUsers = ref.watch(followedUsersProvider);
    final isFollowing = followedUsers.contains(user.id);
    final theme = context.modernTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: user.isVerified 
            ? Colors.blue.withOpacity(0.3)
            : theme.dividerColor!.withOpacity(0.15),
          width: user.isVerified ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: user.isVerified 
              ? Colors.blue.withOpacity(0.12)
              : theme.primaryColor!.withOpacity(0.08),
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
            decoration: user.isVerified ? BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ) : null,
            child: Row(
              children: [
                // Enhanced User Avatar
                Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 52,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: user.isVerified ? LinearGradient(
                          colors: [Colors.blue.shade300, Colors.indigo.shade400],
                        ) : null,
                        border: !user.isVerified ? Border.all(
                          color: theme.dividerColor!.withOpacity(0.2),
                          width: 1,
                        ) : null,
                        boxShadow: [
                          BoxShadow(
                            color: (user.isVerified ? Colors.blue : theme.primaryColor!)
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
                                      color: theme.primaryColor!.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: theme.primaryColor,
                                      size: 22,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor!.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: theme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor!.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    
                    // Verified indicator on avatar (changed from featured)
                    if (user.isVerified)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.surfaceColor!, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(width: 12),
                
                // Enhanced User Info with proper flex control
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // User name with prominent verified badge
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: theme.textColor,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user.isVerified) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Enhanced stats with proper wrapping
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
                      
                      // Last activity with enhanced styling
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.primaryColor!.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 10,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                user.lastPostAt != null 
                                  ? 'Active ${user.lastPostTimeAgo}'
                                  : 'No posts',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.primaryColor,
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
                
                // Enhanced Follow Button with better constraints
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
                        color: isFollowing ? theme.surfaceVariantColor : theme.primaryColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isFollowing 
                            ? theme.dividerColor!.withOpacity(0.3)
                            : theme.primaryColor!,
                          width: 1,
                        ),
                        boxShadow: !isFollowing ? [
                          BoxShadow(
                            color: theme.primaryColor!.withOpacity(0.3),
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
                                ? theme.primaryColor!.withOpacity(0.15)
                                : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Icon(
                              isFollowing ? Icons.check_rounded : Icons.add_rounded,
                              color: isFollowing ? theme.primaryColor : Colors.white,
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              isFollowing ? 'Following' : 'Follow',
                              style: TextStyle(
                                color: isFollowing ? theme.primaryColor : Colors.white,
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
    required theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: theme.surfaceVariantColor!.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.dividerColor!.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: theme.textSecondaryColor,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: theme.textSecondaryColor,
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

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}

// Search Delegate for User Search
class UserSearchDelegate extends SearchDelegate<UserModel?> {
  final WidgetRef ref;

  UserSearchDelegate({required this.ref});

  @override
  String get searchFieldLabel => 'Search users...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context).extension<ModernThemeExtension>()!;
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
    final theme = context.modernTheme;
    
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: theme.textTertiaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Search for users',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find creators and friends on WeiBao',
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    // Use the search functionality from the authentication provider
    return FutureBuilder<List<UserModel>>(
      future: ref.read(authenticationProvider.notifier).searchUsers(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: theme.primaryColor,
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
                  color: theme.textTertiaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Search Error',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Unable to search users at the moment',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textSecondaryColor,
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
                  color: theme.textTertiaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No users found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try searching with different keywords',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textSecondaryColor,
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
                    color: theme.dividerColor!.withOpacity(0.2),
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
                    Navigator.pushNamed(
                      context,
                      Constants.userProfileScreen,
                      arguments: user.id,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      // User Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.dividerColor!.withOpacity(0.2),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: user.profileImage.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: user.profileImage,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: theme.primaryColor!.withOpacity(0.1),
                                    child: Icon(
                                      Icons.person,
                                      color: theme.primaryColor,
                                      size: 24,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: theme.primaryColor!.withOpacity(0.15),
                                    child: Center(
                                      child: Text(
                                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: theme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: theme.primaryColor!.withOpacity(0.15),
                                  child: Center(
                                    child: Text(
                                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // User Info
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
                                      color: theme.textColor,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (user.isVerified) ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.verified,
                                    color: Colors.blue,
                                    size: 16,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${user.videosCount} posts • ${_formatCount(user.followers)} followers',
                              style: TextStyle(
                                color: theme.textSecondaryColor,
                                fontSize: 14,
                              ),
                            ),
                            if (user.bio.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                user.bio,
                                style: TextStyle(
                                  color: theme.textSecondaryColor,
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
                      
                      // Follow Button
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
                              color: isFollowing ? theme.surfaceVariantColor : theme.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isFollowing 
                                  ? theme.dividerColor!.withOpacity(0.3)
                                  : theme.primaryColor!,
                              ),
                            ),
                            child: Text(
                              isFollowing ? 'Following' : 'Follow',
                              style: TextStyle(
                                color: isFollowing ? theme.primaryColor : Colors.white,
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
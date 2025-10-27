// lib/features/users/screens/live_users_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'dart:math' as math;

class LiveUsersScreen extends ConsumerStatefulWidget {
  const LiveUsersScreen({super.key});

  @override
  ConsumerState<LiveUsersScreen> createState() => _LiveUsersScreenState();
}

class _LiveUsersScreenState extends ConsumerState<LiveUsersScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _initializeScreen() {
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _refreshLiveUsers() async {
    HapticFeedback.lightImpact();
    await ref.read(authenticationProvider.notifier).loadUsers();
  }

  List<UserModel> get liveUsers {
    final users = ref.watch(usersProvider);
    final currentUser = ref.watch(currentUserProvider);
    
    List<UserModel> filteredList = users.where((user) => user.isLive).toList();

    if (currentUser != null) {
      filteredList.removeWhere((user) => user.id == currentUser.id);
    }
    
    filteredList.sort((a, b) {
      if (a.isVerified && !b.isVerified) return -1;
      if (!a.isVerified && b.isVerified) return 1;
      return b.followers.compareTo(a.followers);
    });
    
    return filteredList;
  }

  Future<void> _navigateToLiveStream(UserModel user) async {
    try {
      HapticFeedback.lightImpact();
      Navigator.pushNamed(
        context,
        Constants.userProfileScreen,
        arguments: user.id,
      );
    } catch (e) {
      _showSnackBar('Unable to join live stream');
    }
  }

  void _showSnackBar(String message) {
    final theme = context.modernTheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        backgroundColor: theme.surfaceVariantColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: !_isInitialized 
        ? _buildLoadingView(theme)
        : _buildContent(theme),
    );
  }

  Widget _buildContent(ModernThemeExtension theme) {
    final users = liveUsers;
    
    return RefreshIndicator(
      onRefresh: _refreshLiveUsers,
      color: theme.primaryColor,
      backgroundColor: theme.surfaceColor,
      child: users.isEmpty 
        ? _buildPremiumEmptyState(theme)
        : _buildLiveUsersGrid(users, theme),
    );
  }

  Widget _buildLoadingView(ModernThemeExtension theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.primaryColor!.withOpacity(0.05),
            theme.backgroundColor!,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 100 + (30 * _pulseController.value),
                      height: 100 + (30 * _pulseController.value),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            theme.primaryColor!.withOpacity(0.3 * (1 - _pulseController.value)),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor!.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Loading Live Streams',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumEmptyState(ModernThemeExtension theme) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.primaryColor!.withOpacity(0.05),
                  theme.backgroundColor!,
                  theme.backgroundColor!,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Main animated icon
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating gradient rings
                      AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationController.value * 2 * math.pi,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  colors: [
                                    theme.primaryColor!.withOpacity(0.2),
                                    theme.primaryColor!.withOpacity(0.1),
                                    theme.primaryColor!.withOpacity(0.05),
                                    theme.primaryColor!.withOpacity(0.1),
                                    theme.primaryColor!.withOpacity(0.2),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // Pulsing circle
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 160 + (20 * _pulseController.value),
                            height: 160 + (20 * _pulseController.value),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.primaryColor!.withOpacity(
                                  0.3 * (1 - _pulseController.value),
                                ),
                                width: 3,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // Main container
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.surfaceColor,
                          border: Border.all(
                            color: theme.primaryColor!.withOpacity(0.3),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor!.withOpacity(0.2),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.videocam_off_rounded,
                          color: theme.primaryColor,
                          size: 56,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Title
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        theme.primaryColor!,
                        theme.primaryColor!.withOpacity(0.7),
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'No Live Streams',
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    'There are no active live streams at the moment.\nCheck back soon for exciting shopping experiences!',
                    style: TextStyle(
                      color: theme.textSecondaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Feature cards
                  _buildFeatureCards(theme),
                  
                  const SizedBox(height: 48),
                  
                  // CTA Button
                  _buildNotifyButton(theme),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCards(ModernThemeExtension theme) {
    return Row(
      children: [
        Expanded(
          child: _buildFeatureCard(
            icon: Icons.notifications_active_rounded,
            title: 'Get Notified',
            description: 'Never miss a stream',
            theme: theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFeatureCard(
            icon: Icons.local_offer_rounded,
            title: 'Exclusive Deals',
            description: 'Limited time offers',
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required ModernThemeExtension theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.primaryColor!.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor!.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              color: theme.textSecondaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotifyButton(ModernThemeExtension theme) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          _showSnackBar('You\'ll be notified when streams go live!');
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: theme.primaryColor!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                /*boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor!.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],*/
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Notify Me When Live',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLiveUsersGrid(List<UserModel> users, ModernThemeExtension theme) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Header with count
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  theme.primaryColor!,
                  theme.primaryColor!.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor!.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(
                              0.6 * _pulseController.value,
                            ),
                            blurRadius: 15 * _pulseController.value,
                            spreadRadius: 3 * _pulseController.value,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.fiber_manual_record,
                        color: theme.primaryColor,
                        size: 12,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Text(
                  '${users.length} ${users.length == 1 ? 'Stream' : 'Streams'} Live Now',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'HOT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Grid of live users
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildLiveUserCard(users[index], theme, index);
              },
              childCount: users.length,
            ),
          ),
        ),
        
        // Bottom padding to avoid bottom nav bar
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildLiveUserCard(UserModel user, ModernThemeExtension theme, int index) {
    final isTopSeller = index < 3;
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _navigateToLiveStream(user),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTopSeller 
                  ? theme.primaryColor! 
                  : theme.dividerColor!.withOpacity(0.3),
              width: isTopSeller ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isTopSeller 
                    ? theme.primaryColor!.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background
                user.profileImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: user.profileImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: theme.surfaceVariantColor,
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.surfaceVariantColor,
                          child: Center(
                            child: Text(
                              user.name[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: theme.surfaceVariantColor,
                        child: Center(
                          child: Text(
                            user.name[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row
                      Row(
                        children: [
                          // LIVE badge
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primaryColor!.withOpacity(
                                        0.6 * _pulseController.value,
                                      ),
                                      blurRadius: 10 * _pulseController.value,
                                      spreadRadius: 2 * _pulseController.value,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              );
                            },
                          ),
                          const Spacer(),
                          // Viewers
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.visibility_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatViewers(user.followers),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // Top seller badge
                      if (isTopSeller) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.emoji_events_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Top ${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const Spacer(),
                      
                      // Bottom info
                      Row(
                        children: [
                          // Avatar
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: user.profileImage.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: user.profileImage,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: theme.primaryColor,
                                      child: Center(
                                        child: Text(
                                          user.name[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Name
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
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (user.isVerified) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.verified_rounded,
                                        color: Colors.blue,
                                        size: 14,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    'Shopping Live',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  String _formatViewers(int followers) {
    final viewers = (followers * 0.1).toInt().clamp(10, 10000);
    if (viewers < 1000) return viewers.toString();
    if (viewers < 1000000) return '${(viewers / 1000).toStringAsFixed(1)}K';
    return '${(viewers / 1000000).toStringAsFixed(1)}M';
  }
}
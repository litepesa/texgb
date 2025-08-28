// lib/features/dramas/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/dramas/providers/drama_actions_provider.dart';
import 'package:textgb/features/dramas/providers/drama_providers.dart';
import 'package:textgb/features/dramas/widgets/drama_card.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Check admin access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isAdmin = ref.read(isAdminProvider);
      if (!isAdmin) {
        showSnackBar(context, Constants.adminOnly);
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final currentUser = ref.watch(currentUserProvider);
    final adminDramas = ref.watch(adminDramasProvider);

    if (currentUser == null || !currentUser.isAdmin) {
      return Scaffold(
        backgroundColor: modernTheme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                size: 64,
                color: modernTheme.textSecondaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Admin Access Required',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This section is only available for administrators.',
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFE2C55),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(modernTheme, currentUser.name),
            _buildQuickActions(modernTheme),
            _buildStatsCards(modernTheme),
            Expanded(
              child: _buildDramasList(modernTheme, adminDramas),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, Constants.createDramaScreen),
        backgroundColor: const Color(0xFFFE2C55),
        icon: const Icon(Icons.add),
        label: const Text('New Drama'),
      ),
    );
  }

  Widget _buildHeader(ModernThemeExtension modernTheme, String adminName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFE2C55), Color(0xFFFF6B9D)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Welcome back, $adminName',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: modernTheme.textSecondaryColor,
            ),
            onSelected: (value) {
              switch (value) {
                case 'manage_all':
                  Navigator.pushNamed(context, Constants.manageDramasScreen);
                  break;
                case 'settings':
                  Navigator.pushNamed(context, Constants.settingsScreen);
                  break;
                case 'refresh':
                  ref.invalidate(adminDramasProvider);
                  showSnackBar(context, 'Data refreshed');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'manage_all',
                child: Row(
                  children: [
                    Icon(Icons.manage_search),
                    SizedBox(width: 8),
                    Text('Manage All Dramas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              modernTheme,
              icon: Icons.add_circle,
              title: 'New Drama',
              subtitle: 'Create a new drama series',
              color: const Color(0xFFFE2C55),
              onTap: () => Navigator.pushNamed(context, Constants.createDramaScreen),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              modernTheme,
              icon: Icons.manage_search,
              title: 'Manage All',
              subtitle: 'View & manage all dramas',
              color: Colors.blue.shade400,
              onTap: () => Navigator.pushNamed(context, Constants.manageDramasScreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    ModernThemeExtension modernTheme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: modernTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
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
                color: modernTheme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(ModernThemeExtension modernTheme) {
    final adminDramas = ref.watch(adminDramasProvider);
    
    return adminDramas.when(
      data: (dramas) {
        final totalDramas = dramas.length;
        final activeDramas = dramas.where((d) => d.isActive).length;
        final premiumDramas = dramas.where((d) => d.isPremium).length;
        final totalViews = dramas.fold<int>(0, (sum, drama) => sum + drama.viewCount);
        final drafts = dramas.where((d) => d.totalEpisodes == 0).length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  modernTheme,
                  icon: Icons.tv,
                  title: 'Total',
                  value: totalDramas.toString(),
                  color: Colors.blue.shade400,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  modernTheme,
                  icon: Icons.play_circle,
                  title: 'Active',
                  value: activeDramas.toString(),
                  color: Colors.green.shade400,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  modernTheme,
                  icon: Icons.edit_note,
                  title: 'Drafts',
                  value: drafts.toString(),
                  color: Colors.orange.shade400,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  modernTheme,
                  icon: Icons.visibility,
                  title: 'Views',
                  value: _formatCount(totalViews),
                  color: Colors.purple.shade400,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(4, (index) => 
            Expanded(
              child: Container(
                height: 70,
                margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                decoration: BoxDecoration(
                  color: modernTheme.surfaceVariantColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFE2C55),
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatCard(
    ModernThemeExtension modernTheme, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
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
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDramasList(
    ModernThemeExtension modernTheme,
    AsyncValue<List<dynamic>> adminDramas,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Dramas',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, Constants.manageDramasScreen),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View All'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFE2C55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: adminDramas.when(
              data: (dramas) {
                if (dramas.isEmpty) {
                  return _buildEmptyDramas(modernTheme);
                }

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(adminDramasProvider.future),
                  color: const Color(0xFFFE2C55),
                  child: GridView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: dramas.length,
                    itemBuilder: (context, index) {
                      final drama = dramas[index];
                      return _buildEnhancedDramaCard(drama);
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFFE2C55)),
              ),
              error: (error, stack) => _buildErrorState(modernTheme, error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Removed double gesture detection
  Widget _buildEnhancedDramaCard(dynamic drama) {
    final bool hasDrafts = drama.totalEpisodes == 0;
    final bool needsEpisodes = drama.totalEpisodes < 3; // Suggest adding more if less than 3 episodes
    
    return Stack(
      children: [
        // FIXED: Only one gesture detector via DramaCard onTap
        DramaCard(
          drama: drama,
          onTap: () => Navigator.pushNamed(
            context,
            Constants.dramaDetailsScreen,
            arguments: {'dramaId': drama.dramaId},
          ),
        ),
        
        // Status indicators
        Positioned(
          top: 8,
          left: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Draft/Episode status
              if (hasDrafts)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_note, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Draft',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else if (needsEpisodes)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${drama.totalEpisodes} Eps',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              
              const SizedBox(height: 4),
              
              // Active/Inactive status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: drama.isActive 
                      ? Colors.green.shade600 
                      : Colors.red.shade600,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  drama.isActive ? 'Active' : 'Inactive',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // FIXED: Quick action button with proper hit test behavior to prevent event bubbling
        if (hasDrafts)
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                Constants.addEpisodeScreen,
                arguments: {'dramaId': drama.dramaId},
              ),
              behavior: HitTestBehavior.opaque, // FIXED: Prevent event bubbling
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFE2C55),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFE2C55).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Add Episodes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // FIXED: Standard admin menu with proper hit test behavior
        if (!hasDrafts)
          Positioned(
            top: 4,
            right: 4,
            child: PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    Navigator.pushNamed(
                      context,
                      Constants.editDramaScreen,
                      arguments: {'dramaId': drama.dramaId},
                    );
                    break;
                  case 'episodes':
                    Navigator.pushNamed(
                      context,
                      Constants.addEpisodeScreen,
                      arguments: {'dramaId': drama.dramaId},
                    );
                    break;
                  case 'toggle_featured':
                    ref.read(adminDramaActionsProvider.notifier)
                        .toggleFeatured(drama.dramaId, !drama.isFeatured);
                    break;
                  case 'toggle_active':
                    ref.read(adminDramaActionsProvider.notifier)
                        .toggleActive(drama.dramaId, !drama.isActive);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Edit Drama'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'episodes',
                  child: Row(
                    children: [
                      Icon(Icons.video_library, size: 16),
                      SizedBox(width: 8),
                      Text('Add Episodes'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_featured',
                  child: Row(
                    children: [
                      Icon(
                        drama.isFeatured ? Icons.star : Icons.star_border,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(drama.isFeatured ? 'Unfeature' : 'Feature'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_active',
                  child: Row(
                    children: [
                      Icon(
                        drama.isActive ? Icons.pause_circle : Icons.play_circle,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(drama.isActive ? 'Deactivate' : 'Activate'),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyDramas(ModernThemeExtension modernTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: modernTheme.surfaceVariantColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.tv_off,
              size: 48,
              color: modernTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Dramas Yet',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start creating your first drama to share with viewers',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, Constants.createDramaScreen),
            icon: const Icon(Icons.add),
            label: const Text('Create Drama'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFE2C55),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tip: After creating a drama, add episodes to make it available to viewers',
            style: TextStyle(
              color: modernTheme.textSecondaryColor?.withOpacity(0.8),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ModernThemeExtension modernTheme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load dramas',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(adminDramasProvider.future),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFE2C55),
              ),
              child: const Text('Retry'),
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
    } else {
      return count.toString();
    }
  }
}
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
        label: const Text('Add Drama'),
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
                case 'manage_dramas':
                  Navigator.pushNamed(context, Constants.manageDramasScreen);
                  break;
                case 'settings':
                  Navigator.pushNamed(context, Constants.settingsScreen);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'manage_dramas',
                child: Row(
                  children: [
                    const Icon(Icons.manage_search),
                    const SizedBox(width: 8),
                    const Text('Manage All Dramas'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings),
                    const SizedBox(width: 8),
                    const Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
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

        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  modernTheme,
                  icon: Icons.tv,
                  title: 'Total Dramas',
                  value: totalDramas.toString(),
                  color: Colors.blue.shade400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  modernTheme,
                  icon: Icons.play_circle,
                  title: 'Active',
                  value: activeDramas.toString(),
                  color: Colors.green.shade400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  modernTheme,
                  icon: Icons.workspace_premium,
                  title: 'Premium',
                  value: premiumDramas.toString(),
                  color: Colors.orange.shade400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  modernTheme,
                  icon: Icons.visibility,
                  title: 'Total Views',
                  value: _formatCount(totalViews),
                  color: Colors.purple.shade400,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: List.generate(4, (index) => 
            Expanded(
              child: Container(
                height: 80,
                margin: EdgeInsets.only(right: index < 3 ? 12 : 0),
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
      padding: const EdgeInsets.all(16),
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
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 12,
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
                icon: const Icon(Icons.manage_search, size: 16),
                label: const Text('Manage All'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFE2C55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                      return _buildAdminDramaCard(drama);
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

  Widget _buildAdminDramaCard(dynamic drama) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        Constants.editDramaScreen,
        arguments: {'dramaId': drama.dramaId},
      ),
      child: Stack(
        children: [
          DramaCard(
            drama: drama,
            onTap: () => Navigator.pushNamed(
              context,
              Constants.dramaDetailsScreen,
              arguments: {'dramaId': drama.dramaId},
            ),
          ),
          
          // Admin status overlay
          Positioned(
            top: 8,
            left: 8,
            child: Container(
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
          ),

          // Admin actions menu
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
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit, size: 16),
                      const SizedBox(width: 8),
                      const Text('Edit Drama'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'episodes',
                  child: Row(
                    children: [
                      const Icon(Icons.video_library, size: 16),
                      const SizedBox(width: 8),
                      const Text('Manage Episodes'),
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
      ),
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
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
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
        ),
      );
    }

    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Fixed Header
            SliverToBoxAdapter(
              child: _buildHeader(modernTheme, currentUser.name),
            ),
            
            // Quick Actions
            SliverToBoxAdapter(
              child: _buildQuickActions(modernTheme),
            ),
            
            // Stats Cards
            SliverToBoxAdapter(
              child: _buildStatsCards(modernTheme),
            ),
            
            // Dramas List Header
            SliverToBoxAdapter(
              child: _buildDramasHeader(modernTheme),
            ),
            
            // Dramas Grid
            _buildDramasGrid(modernTheme, adminDramas),
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
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Welcome back, $adminName',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
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
                  mainAxisSize: MainAxisSize.min,
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
                  mainAxisSize: MainAxisSize.min,
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
                  mainAxisSize: MainAxisSize.min,
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
    return Padding(
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
            mainAxisSize: MainAxisSize.min,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
        final totalViews = dramas.fold<int>(0, (sum, drama) => sum + drama.viewCount);
        final drafts = dramas.where((d) => d.totalEpisodes == 0).length;

        return Padding(
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
      loading: () => Padding(
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
        mainAxisSize: MainAxisSize.min,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

  Widget _buildDramasHeader(ModernThemeExtension modernTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
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
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDramasGrid(
    ModernThemeExtension modernTheme,
    AsyncValue<List<dynamic>> adminDramas,
  ) {
    return adminDramas.when(
      data: (dramas) {
        if (dramas.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyDramas(modernTheme),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100), // Bottom padding for FAB
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: MediaQuery.of(context).size.width > 400 ? 0.75 : 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final drama = dramas[index];
                return Container(
                  constraints: const BoxConstraints(
                    maxWidth: 200,
                    maxHeight: 280,
                  ),
                  child: _buildEnhancedDramaCard(drama),
                );
              },
              childCount: dramas.length,
            ),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(color: Color(0xFFFE2C55)),
          ),
        ),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: _buildErrorState(modernTheme, error.toString()),
      ),
    );
  }

  Widget _buildEnhancedDramaCard(dynamic drama) {
    final bool hasDrafts = drama.totalEpisodes == 0;
    final bool needsEpisodes = drama.totalEpisodes < 3;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.antiAlias,
          children: [
            // Main Drama Card with constrained size
            SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DramaCard(
                  drama: drama,
                  onTap: () => Navigator.pushNamed(
                    context,
                    Constants.dramaDetailsScreen,
                    arguments: {'dramaId': drama.dramaId},
                  ),
                ),
              ),
            ),
            
            // Status indicators with improved positioning and overflow protection
            Positioned(
              top: 6,
              left: 6,
              right: 30, // Leave space for menu button
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Draft/Episode status
                  if (hasDrafts)
                    Container(
                      constraints: const BoxConstraints(maxWidth: 60),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_note, size: 8, color: Colors.white),
                          SizedBox(width: 1),
                          Flexible(
                            child: Text(
                              'Draft',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (needsEpisodes)
                    Container(
                      constraints: const BoxConstraints(maxWidth: 60),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        '${drama.totalEpisodes}Ep',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  
                  const SizedBox(height: 2),
                  
                  // Active/Inactive status
                  Container(
                    constraints: const BoxConstraints(maxWidth: 60),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: drama.isActive 
                          ? Colors.green.shade600 
                          : Colors.red.shade600,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      drama.isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Action button for drafts with overflow protection
            if (hasDrafts)
              Positioned(
                bottom: 6,
                right: 6,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(
                      context,
                      Constants.addEpisodeScreen,
                      arguments: {'dramaId': drama.dramaId},
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 60,
                        maxHeight: 24,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFE2C55),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFE2C55).withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 10,
                          ),
                          SizedBox(width: 1),
                          Flexible(
                            child: Text(
                              'Add',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Admin menu for non-drafts with overflow protection  
            if (!hasDrafts)
              Positioned(
                top: 4,
                right: 4,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 0,
                    maxWidth: 200,
                  ),
                  icon: Container(
                    width: 20,
                    height: 20,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 12,
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
                      height: 36,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 12),
                          SizedBox(width: 4),
                          Text('Edit', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'episodes',
                      height: 36,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.video_library, size: 12),
                          SizedBox(width: 4),
                          Text('Episodes', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_featured',
                      height: 36,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            drama.isFeatured ? Icons.star : Icons.star_border,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            drama.isFeatured ? 'Unfeature' : 'Feature',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_active',
                      height: 36,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            drama.isActive ? Icons.pause_circle : Icons.play_circle,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            drama.isActive ? 'Deactivate' : 'Activate',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyDramas(ModernThemeExtension modernTheme) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Tip: After creating a drama, add episodes to make it available to viewers',
              style: TextStyle(
                color: modernTheme.textSecondaryColor?.withOpacity(0.8),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ModernThemeExtension modernTheme, String error) {
    return Padding(
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
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
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
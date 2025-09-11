// lib/features/dramas/screens/admin_dashboard_screen.dart - OWNERSHIP FOCUSED
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
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
      final currentUser = ref.read(currentUserProvider);
      final isVerified = currentUser?.isVerified ?? false;
      if (!isVerified) {
        showSnackBar(context, Constants.verifiedOnly);
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final currentUser = ref.watch(currentUserProvider);
    final adminDramas = ref.watch(userDramasProvider);

    if (currentUser == null || !currentUser.isVerified) {
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
                  'My Drama Studio',
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
                case 'manage_my_dramas':
                  Navigator.pushNamed(context, Constants.manageDramasScreen);
                  break;
                case 'settings':
                  Navigator.pushNamed(context, Constants.settingsScreen);
                  break;
                case 'refresh':
                  ref.invalidate(userDramasProvider);
                  showSnackBar(context, 'Data refreshed');
                  break;
                case 'help':
                  _showHelpDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'manage_my_dramas',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.manage_search),
                    SizedBox(width: 8),
                    Text('Manage My Dramas'),
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
                value: 'help',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.help_outline),
                    SizedBox(width: 8),
                    Text('Help'),
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
              title: 'Create Drama',
              subtitle: 'Start a new drama series',
              color: const Color(0xFFFE2C55),
              onTap: () => Navigator.pushNamed(context, Constants.createDramaScreen),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              modernTheme,
              icon: Icons.library_books,
              title: 'My Library',
              subtitle: 'Manage your dramas',
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
    final adminDramas = ref.watch(userDramasProvider);
    
    return adminDramas.when(
      data: (dramas) {
        final totalDramas = dramas.length;
        final activeDramas = dramas.where((d) => d.isActive).length;
        final totalViews = dramas.fold<int>(0, (sum, drama) => sum + drama.viewCount);
        final featuredDramas = dramas.where((d) => d.isFeatured).length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  modernTheme,
                  icon: Icons.tv,
                  title: 'My Dramas',
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
                  icon: Icons.star,
                  title: 'Featured',
                  value: featuredDramas.toString(),
                  color: Colors.amber.shade600,
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
            'Recent Dramas',
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

        // Show only first 6 dramas on dashboard
        final displayDramas = dramas.take(6).toList();

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100), // Bottom padding for FAB
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final drama = displayDramas[index];
                return _buildEnhancedDramaCard(drama);
              },
              childCount: displayDramas.length,
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
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Main Drama Card
            ClipRRect(
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
            
            // Status indicators with improved positioning
            Positioned(
              top: 8,
              left: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Draft status
                  if (hasDrafts)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_note, size: 10, color: Colors.white),
                          SizedBox(width: 2),
                          Text(
                            'Draft',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 4),
                  
                  // Active/Inactive status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: drama.isActive 
                          ? Colors.green.shade600 
                          : Colors.red.shade600,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      drama.isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Featured indicator
                  if (drama.isFeatured) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade600,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 8, color: Colors.white),
                          SizedBox(width: 2),
                          Text(
                            'Featured',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Action button for drafts
            if (hasDrafts)
              Positioned(
                bottom: 8,
                right: 8,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(
                      context,
                      Constants.addEpisodeScreen,
                      arguments: {'dramaId': drama.dramaId},
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFE2C55),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFE2C55).withOpacity(0.3),
                            blurRadius: 6,
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
                            size: 12,
                          ),
                          SizedBox(width: 2),
                          Text(
                            'Add Ep',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Admin menu for completed dramas
            if (!hasDrafts)
              Positioned(
                top: 4,
                right: 4,
                child: PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 14,
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 14),
                          SizedBox(width: 6),
                          Text('Edit', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    /*const PopupMenuItem(
                      value: 'episodes',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.video_library, size: 14),
                          SizedBox(width: 6),
                          Text('Episodes', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),*/
                    PopupMenuItem(
                      value: 'toggle_featured',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            drama.isFeatured ? Icons.star : Icons.star_border,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            drama.isFeatured ? 'Unfeature' : 'Feature',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_active',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            drama.isActive ? Icons.pause_circle : Icons.play_circle,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            drama.isActive ? 'Deactivate' : 'Activate',
                            style: const TextStyle(fontSize: 12),
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
              Icons.video_collection_outlined,
              size: 48,
              color: modernTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start Your Drama Journey',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first drama series and share your story with viewers around the world',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, Constants.createDramaScreen),
            icon: const Icon(Icons.add_circle),
            label: const Text('Create My First Drama'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFE2C55),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: modernTheme.surfaceVariantColor!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.amber.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Tips',
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Upload high-quality banner images\n'
                  '• Add engaging descriptions\n'
                  '• Upload episodes in supported formats\n'
                  '• Use featured status to promote your best content',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
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
            onPressed: () => ref.refresh(userDramasProvider.future),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFE2C55),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Dashboard Help'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Drama Studio',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('This is your personal drama creation and management space. You can only see and manage dramas that you have created.'),
              SizedBox(height: 12),
              Text(
                'Quick Actions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Create Drama: Start a new drama series'),
              Text('• My Library: View and manage all your dramas'),
              SizedBox(height: 12),
              Text(
                'Drama Management',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Only you can edit, delete, or modify your dramas'),
              Text('• Use Featured status to highlight your best content'),
              Text('• Active/Inactive controls public visibility'),
              Text('• Track views and engagement for each drama'),
              SizedBox(height: 12),
              Text(
                'Content Guidelines',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Upload high-quality video content'),
              Text('• Ensure appropriate content ratings'),
              Text('• Add descriptive titles and summaries'),
              Text('• Use attractive banner images'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
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
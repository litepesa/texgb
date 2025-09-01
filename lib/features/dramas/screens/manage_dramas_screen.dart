// lib/features/dramas/screens/manage_dramas_screen.dart - ADMIN OWNERSHIP ONLY
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/dramas/providers/drama_providers.dart';
import 'package:textgb/features/dramas/providers/drama_actions_provider.dart';
import 'package:textgb/features/dramas/widgets/drama_card.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class ManageDramasScreen extends ConsumerStatefulWidget {
  const ManageDramasScreen({super.key});

  @override
  ConsumerState<ManageDramasScreen> createState() => _ManageDramasScreenState();
}

class _ManageDramasScreenState extends ConsumerState<ManageDramasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // UPDATED: Simplified tabs - only admin's own dramas and status filters
  final List<String> _tabs = ['My Dramas', 'Active', 'Inactive', 'Featured'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    
    // Check admin access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isAdmin = ref.read(isAdminProvider);
      if (!isAdmin) {
        showSnackBar(context, Constants.adminOnly);
        Navigator.of(context).pop();
      }
    });

    // Listen to admin action messages
    ref.listenManual(adminDramaActionsProvider, (previous, next) {
      if (next.error != null) {
        showSnackBar(context, next.error!);
        ref.read(adminDramaActionsProvider.notifier).clearMessages();
      } else if (next.successMessage != null) {
        showSnackBar(context, next.successMessage!);
        ref.read(adminDramaActionsProvider.notifier).clearMessages();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final currentUser = ref.watch(currentUserProvider);

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
            _buildHeader(modernTheme),
            _buildSearchBar(modernTheme),
            _buildTabBar(modernTheme),
            Expanded(
              child: _buildTabContent(),
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

  Widget _buildHeader(ModernThemeExtension modernTheme) {
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
          IconButton(
            icon: Icon(Icons.arrow_back, color: modernTheme.textColor),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage My Dramas',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manage the dramas you have created',
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
                case 'refresh':
                  _refreshData();
                  break;
                case 'help':
                  _showHelpDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help_outline),
                    SizedBox(width: 8),
                    Text('Help'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim();
          });
        },
        style: TextStyle(color: modernTheme.textColor),
        decoration: InputDecoration(
          hintText: 'Search your dramas...',
          hintStyle: TextStyle(color: modernTheme.textSecondaryColor),
          prefixIcon: Icon(
            Icons.search,
            color: modernTheme.textSecondaryColor,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: modernTheme.textSecondaryColor,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: modernTheme.surfaceVariantColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: const Color(0xFFFE2C55),
        unselectedLabelColor: modernTheme.textSecondaryColor,
        indicatorColor: const Color(0xFFFE2C55),
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildMyDramas(), // All dramas created by this admin
        _buildActiveDramas(), // Active dramas only
        _buildInactiveDramas(), // Inactive dramas only
        _buildFeaturedDramas(), // Featured dramas only
      ],
    );
  }

  Widget _buildMyDramas() {
    final adminDramas = ref.watch(adminDramasProvider);
    
    return adminDramas.when(
      data: (dramas) {
        final filteredDramas = _filterDramas(dramas);
        
        if (filteredDramas.isEmpty) {
          return _buildEmptyState(
            'No dramas found',
            _searchQuery.isNotEmpty 
                ? 'Try adjusting your search query'
                : 'Create your first drama to get started',
            Icons.tv_off,
          );
        }
        
        return RefreshIndicator(
          onRefresh: () => ref.refresh(adminDramasProvider.future),
          color: const Color(0xFFFE2C55),
          child: _buildDramaGrid(filteredDramas),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFE2C55)),
      ),
      error: (error, stack) => _buildErrorState('Failed to load your dramas', error.toString()),
    );
  }

  Widget _buildActiveDramas() {
    final adminDramas = ref.watch(adminDramasProvider);
    
    return adminDramas.when(
      data: (dramas) {
        final activeDramas = dramas.where((drama) => drama.isActive).toList();
        final filteredDramas = _filterDramas(activeDramas);
        
        if (filteredDramas.isEmpty) {
          return _buildEmptyState(
            'No active dramas',
            _searchQuery.isNotEmpty 
                ? 'No active dramas match your search'
                : 'All your dramas are currently inactive',
            Icons.play_circle_outline,
          );
        }
        
        return RefreshIndicator(
          onRefresh: () => ref.refresh(adminDramasProvider.future),
          color: const Color(0xFFFE2C55),
          child: _buildDramaGrid(filteredDramas),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFE2C55)),
      ),
      error: (error, stack) => _buildErrorState('Failed to load active dramas', error.toString()),
    );
  }

  Widget _buildInactiveDramas() {
    final adminDramas = ref.watch(adminDramasProvider);
    
    return adminDramas.when(
      data: (dramas) {
        final inactiveDramas = dramas.where((drama) => !drama.isActive).toList();
        final filteredDramas = _filterDramas(inactiveDramas);
        
        if (filteredDramas.isEmpty) {
          return _buildEmptyState(
            'No inactive dramas',
            _searchQuery.isNotEmpty 
                ? 'No inactive dramas match your search'
                : 'All your dramas are currently active',
            Icons.pause_circle_outline,
          );
        }
        
        return RefreshIndicator(
          onRefresh: () => ref.refresh(adminDramasProvider.future),
          color: const Color(0xFFFE2C55),
          child: _buildDramaGrid(filteredDramas),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFE2C55)),
      ),
      error: (error, stack) => _buildErrorState('Failed to load inactive dramas', error.toString()),
    );
  }

  Widget _buildFeaturedDramas() {
    final adminDramas = ref.watch(adminDramasProvider);
    
    return adminDramas.when(
      data: (dramas) {
        final featuredDramas = dramas.where((drama) => drama.isFeatured).toList();
        final filteredDramas = _filterDramas(featuredDramas);
        
        if (filteredDramas.isEmpty) {
          return _buildEmptyState(
            'No featured dramas',
            _searchQuery.isNotEmpty 
                ? 'No featured dramas match your search'
                : 'None of your dramas are currently featured',
            Icons.star_border,
          );
        }
        
        return RefreshIndicator(
          onRefresh: () => ref.refresh(adminDramasProvider.future),
          color: const Color(0xFFFE2C55),
          child: _buildDramaGrid(filteredDramas),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFE2C55)),
      ),
      error: (error, stack) => _buildErrorState('Failed to load featured dramas', error.toString()),
    );
  }

  Widget _buildDramaGrid(List<dynamic> dramas) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: dramas.length,
      itemBuilder: (context, index) {
        final drama = dramas[index];
        return _buildManageableDramaCard(drama);
      },
    );
  }

  Widget _buildManageableDramaCard(dynamic drama) {
    return Stack(
      children: [
        DramaCard(
          drama: drama,
          onTap: () => Navigator.pushNamed(
            context,
            Constants.myDramaDetailsScreen,
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
              // Active/Inactive status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: drama.isActive 
                      ? Colors.green.shade600 
                      : Colors.red.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  drama.isActive ? 'Active' : 'Inactive',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Featured status (if featured)
              if (drama.isFeatured)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade600,
                    borderRadius: BorderRadius.circular(8),
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
                color: Colors.black.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.more_vert,
                color: Colors.white,
                size: 16,
              ),
            ),
            onSelected: (value) => _handleDramaAction(value, drama),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'episodes',
                child: Row(
                  children: [
                    Icon(Icons.video_library, size: 16),
                    SizedBox(width: 8),
                    Text('Episodes'),
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
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Episode count indicator
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${drama.totalEpisodes} Episodes',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    final modernTheme = context.modernTheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: modernTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty && title == 'No dramas found') ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, Constants.createDramaScreen),
                icon: const Icon(Icons.add),
                label: const Text('Create Your First Drama'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFE2C55),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String title, String error) {
    final modernTheme = context.modernTheme;
    
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
              title,
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
              onPressed: _refreshData,
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

  List<dynamic> _filterDramas(List<dynamic> dramas) {
    if (_searchQuery.isEmpty) return dramas;
    
    return dramas.where((drama) {
      final title = drama.title.toLowerCase();
      final description = drama.description.toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      return title.contains(query) || description.contains(query);
    }).toList();
  }

  void _handleDramaAction(String action, dynamic drama) {
    switch (action) {
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
      case 'delete':
        _confirmDeleteDrama(drama);
        break;
    }
  }

  void _confirmDeleteDrama(dynamic drama) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Drama'),
        content: Text(
          'Are you sure you want to delete "${drama.title}"?\n\nThis will permanently delete the drama and all its episodes. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(adminDramaActionsProvider.notifier)
                  .deleteDrama(drama.dramaId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Drama Management Help'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Your Dramas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text('• You can only see and manage dramas you have created'),
            Text('• Use tabs to filter by status (Active, Inactive, Featured)'),
            Text('• Search to find specific dramas quickly'),
            SizedBox(height: 12),
            Text(
              'Drama Actions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text('• Edit: Modify drama details and episodes'),
            Text('• Episodes: Manage episode videos'),
            Text('• Feature/Unfeature: Control visibility on homepage'),
            Text('• Activate/Deactivate: Control public availability'),
            Text('• Delete: Permanently remove drama'),
            SizedBox(height: 12),
            Text(
              'Note: Only platform administrators can create and manage dramas.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
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

  void _refreshData() {
    ref.invalidate(adminDramasProvider);
    showSnackBar(context, 'Data refreshed');
  }
}
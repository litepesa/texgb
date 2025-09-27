// lib/features/properties/screens/host_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/properties/models/property_engagement_models.dart';
import 'package:textgb/features/properties/providers/property_providers.dart';
import 'package:textgb/features/properties/models/property_listing_model.dart';
import 'package:textgb/features/properties/widgets/property_card.dart';
import 'package:textgb/features/properties/widgets/property_status_badge.dart';
import 'package:textgb/features/properties/widgets/empty_properties_state.dart';
import 'package:textgb/features/properties/constants/property_constants.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class HostDashboardScreen extends ConsumerStatefulWidget {
  const HostDashboardScreen({super.key});

  @override
  ConsumerState<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends ConsumerState<HostDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final hostPropertiesAsync = ref.watch(hostPropertiesProvider);
    final hostInquiriesAsync = ref.watch(hostInquiriesProvider);
    final theme = Theme.of(context).extension<ModernThemeExtension>();

    // Check if user is a host
    if (currentUser == null || !currentUser.isHost) {
      return _buildNotHostScreen(theme);
    }

    return Scaffold(
      backgroundColor: theme?.backgroundColor ?? Colors.grey[50],
      appBar: AppBar(
        backgroundColor: theme?.surfaceColor ?? Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Host Dashboard',
              style: TextStyle(
                color: theme?.textColor ?? Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Welcome back, ${currentUser.name}',
              style: TextStyle(
                color: theme?.textSecondaryColor ?? Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          // Notifications
          IconButton(
            onPressed: () {
              // TODO: Navigate to notifications
            },
            icon: Stack(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: theme?.textColor ?? Colors.black,
                ),
                // Notification badge (if any)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFE2C55),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Profile menu
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            icon: CircleAvatar(
              radius: 16,
              backgroundImage: currentUser.profileImage.isNotEmpty
                  ? NetworkImage(currentUser.profileImage)
                  : null,
              backgroundColor: theme?.primaryColor ?? const Color(0xFFFE2C55),
              child: currentUser.profileImage.isEmpty
                  ? Text(
                      currentUser.name.isNotEmpty
                          ? currentUser.name[0].toUpperCase()
                          : 'H',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 8),
                    Text('My Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'analytics',
                child: Row(
                  children: [
                    Icon(Icons.analytics_outlined),
                    SizedBox(width: 8),
                    Text('Analytics'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help_outline),
                    SizedBox(width: 8),
                    Text('Help & Support'),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: theme?.primaryColor ?? const Color(0xFFFE2C55),
          unselectedLabelColor: theme?.textSecondaryColor ?? Colors.grey[600],
          indicatorColor: theme?.primaryColor ?? const Color(0xFFFE2C55),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Properties'),
            Tab(text: 'Inquiries'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(hostPropertiesAsync, hostInquiriesAsync, theme),
          _buildPropertiesTab(hostPropertiesAsync, theme),
          _buildInquiriesTab(hostInquiriesAsync, theme),
          _buildAnalyticsTab(theme),
        ],
      ),
      floatingActionButton: _selectedTabIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToCreateProperty(),
              backgroundColor: theme?.primaryColor ?? const Color(0xFFFE2C55),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text(
                'Add Property',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : null,
    );
  }

  Widget _buildNotHostScreen(ModernThemeExtension? theme) {
    return Scaffold(
      backgroundColor: theme?.backgroundColor ?? Colors.grey[50],
      appBar: AppBar(
        backgroundColor: theme?.surfaceColor ?? Colors.white,
        elevation: 0,
        title: Text(
          'Host Dashboard',
          style: TextStyle(
            color: theme?.textColor ?? Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: EmptyPropertiesState(
        title: 'Host Access Required',
        description: 'You need to be a verified host to access the property dashboard. Contact support to upgrade your account.',
        icon: Icons.admin_panel_settings_outlined,
        actionText: 'Contact Support',
        onAction: () {
          // TODO: Navigate to support or upgrade screen
        },
      ),
    );
  }

  Widget _buildOverviewTab(
    AsyncValue<HostPropertyState> hostPropertiesAsync,
    AsyncValue<List<PropertyInquiryModel>> hostInquiriesAsync,
    ModernThemeExtension? theme,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(hostPropertiesProvider.notifier).refresh();
        ref.invalidate(hostInquiriesProvider);
      },
      color: theme?.primaryColor ?? const Color(0xFFFE2C55),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats
            _buildQuickStats(hostPropertiesAsync, hostInquiriesAsync, theme),
            
            const SizedBox(height: 24),
            
            // Recent Activity
            _buildRecentActivity(theme),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            _buildQuickActions(theme),
            
            const SizedBox(height: 24),
            
            // Recent Properties
            Text(
              'Recent Properties',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme?.textColor ?? Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildRecentProperties(hostPropertiesAsync, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(
    AsyncValue<HostPropertyState> hostPropertiesAsync,
    AsyncValue<List<PropertyInquiryModel>> hostInquiriesAsync,
    ModernThemeExtension? theme,
  ) {
    return hostPropertiesAsync.when(
      loading: () => _buildStatsLoading(theme),
      error: (error, stack) => _buildStatsError(theme),
      data: (hostPropertyState) {
        final properties = hostPropertyState.properties;
        final activeProperties = properties.where((p) => p.isActive).length;
        final pendingProperties = properties.where((p) => p.status == PropertyStatus.pending).length;
        final totalViews = properties.fold<int>(0, (sum, p) => sum + p.viewsCount);
        final totalLikes = properties.fold<int>(0, (sum, p) => sum + p.likesCount);
        
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Active Properties',
                value: activeProperties.toString(),
                icon: Icons.home,
                color: Colors.green,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Pending Review',
                value: pendingProperties.toString(),
                icon: Icons.pending,
                color: Colors.orange,
                theme: theme,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ModernThemeExtension? theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme?.surfaceColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  size: 20,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme?.textColor ?? Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: theme?.textSecondaryColor ?? Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsLoading(ModernThemeExtension? theme) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: theme?.surfaceColor ?? Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: theme?.surfaceColor ?? Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsError(ModernThemeExtension? theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme?.surfaceColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[400],
          ),
          const SizedBox(width: 8),
          Text(
            'Failed to load statistics',
            style: TextStyle(
              color: theme?.textSecondaryColor ?? Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(ModernThemeExtension? theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme?.textColor ?? Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme?.surfaceColor ?? Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActivityItem(
                icon: Icons.favorite,
                title: 'New like on "Modern Apartment in Westlands"',
                time: '2 hours ago',
                color: Colors.red,
                theme: theme,
              ),
              const Divider(height: 24),
              _buildActivityItem(
                icon: Icons.chat,
                title: 'New comment on "Cozy Studio in Kilimani"',
                time: '4 hours ago',
                color: Colors.blue,
                theme: theme,
              ),
              const Divider(height: 24),
              _buildActivityItem(
                icon: Icons.contact_phone,
                title: 'New inquiry for "Villa in Karen"',
                time: '1 day ago',
                color: Colors.green,
                theme: theme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String time,
    required Color color,
    required ModernThemeExtension? theme,
  }) {
    return Row(
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
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme?.textColor ?? Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: theme?.textSecondaryColor ?? Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(ModernThemeExtension? theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme?.textColor ?? Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.add_home,
                title: 'Add Property',
                subtitle: 'Create new listing',
                onTap: () => _navigateToCreateProperty(),
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.analytics,
                title: 'View Analytics',
                subtitle: 'Performance insights',
                onTap: () => _tabController.animateTo(3),
                theme: theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ModernThemeExtension? theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme?.surfaceColor ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (theme?.dividerColor ?? Colors.grey[300]!).withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (theme?.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: theme?.primaryColor ?? const Color(0xFFFE2C55),
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme?.textColor ?? Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: theme?.textSecondaryColor ?? Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentProperties(
    AsyncValue<HostPropertyState> hostPropertiesAsync,
    ModernThemeExtension? theme,
  ) {
    return hostPropertiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text(
        'Failed to load properties: $error',
        style: TextStyle(
          color: theme?.textSecondaryColor ?? Colors.grey[600],
        ),
      ),
      data: (hostPropertyState) {
        final properties = hostPropertyState.properties;
        if (properties.isEmpty) {
          return EmptyPropertiesState(
            title: 'No Properties Yet',
            description: 'Start by creating your first property listing to showcase your space.',
            actionText: 'Create Property',
            onAction: () => _navigateToCreateProperty(),
          );
        }

        final recentProperties = properties.take(3).toList();
        return Column(
          children: recentProperties.map((property) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: PropertyCard(
                property: property,
                showActions: false,
                onTap: () => _navigateToPropertyDetails(property),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPropertiesTab(
    AsyncValue<HostPropertyState> hostPropertiesAsync,
    ModernThemeExtension? theme,
  ) {
    return hostPropertiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load properties',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme?.textColor ?? Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                color: theme?.textSecondaryColor ?? Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(hostPropertiesProvider.notifier).refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme?.primaryColor ?? const Color(0xFFFE2C55),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
      data: (hostPropertyState) {
        final properties = hostPropertyState.properties;
        
        if (properties.isEmpty) {
          return EmptyPropertiesState(
            title: 'No Properties Yet',
            description: 'Start by creating your first property listing to showcase your space to potential guests.',
            actionText: 'Create Your First Property',
            onAction: () => _navigateToCreateProperty(),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(hostPropertiesProvider.notifier).refresh(),
          color: theme?.primaryColor ?? const Color(0xFFFE2C55),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final property = properties[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: _buildPropertyListItem(property, theme),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPropertyListItem(
    PropertyListingModel property,
    ModernThemeExtension? theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme?.surfaceColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Property thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  image: property.thumbnailUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(property.thumbnailUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: property.thumbnailUrl.isEmpty ? Colors.grey[300] : null,
                ),
                child: Stack(
                  children: [
                    if (property.thumbnailUrl.isEmpty)
                      const Center(
                        child: Icon(
                          Icons.videocam_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    
                    // Status badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: PropertyStatusBadge(status: property.status),
                    ),
                    
                    // Play button
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Property info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        property.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme?.textColor ?? Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      property.formattedRate + '/night',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme?.primaryColor ?? const Color(0xFFFE2C55),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: theme?.textSecondaryColor ?? Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.location.shortAddress,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme?.textSecondaryColor ?? Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    _buildPropertyStat(
                      icon: Icons.visibility_outlined,
                      count: property.viewsCount,
                      theme: theme,
                    ),
                    const SizedBox(width: 16),
                    _buildPropertyStat(
                      icon: Icons.favorite_outline,
                      count: property.likesCount,
                      theme: theme,
                    ),
                    const SizedBox(width: 16),
                    _buildPropertyStat(
                      icon: Icons.chat_bubble_outline,
                      count: property.commentsCount,
                      theme: theme,
                    ),
                    const Spacer(),
                    
                    // Action buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _navigateToEditProperty(property),
                          icon: const Icon(Icons.edit_outlined),
                          iconSize: 20,
                          color: theme?.textSecondaryColor ?? Colors.grey[600],
                        ),
                        IconButton(
                          onPressed: () => _showDeleteConfirmation(property),
                          icon: const Icon(Icons.delete_outline),
                          iconSize: 20,
                          color: Colors.red[400],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyStat({
    required IconData icon,
    required int count,
    required ModernThemeExtension? theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: theme?.textSecondaryColor ?? Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          PropertyConstants.formatViewCount(count),
          style: TextStyle(
            fontSize: 12,
            color: theme?.textSecondaryColor ?? Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInquiriesTab(
    AsyncValue<List<PropertyInquiryModel>> hostInquiriesAsync,
    ModernThemeExtension? theme,
  ) {
    return hostInquiriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'Failed to load inquiries: $error',
          style: TextStyle(
            color: theme?.textSecondaryColor ?? Colors.grey[600],
          ),
        ),
      ),
      data: (inquiries) {
        if (inquiries.isEmpty) {
          return const EmptyPropertiesState(
            title: 'No Inquiries Yet',
            description: 'When guests contact you about your properties, their inquiries will appear here.',
            icon: Icons.contact_phone_outlined,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(hostInquiriesProvider);
          },
          color: theme?.primaryColor ?? const Color(0xFFFE2C55),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: inquiries.length,
            itemBuilder: (context, index) {
              final inquiry = inquiries[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: _buildInquiryItem(inquiry, theme),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInquiryItem(
    PropertyInquiryModel inquiry,
    ModernThemeExtension? theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme?.surfaceColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: inquiry.inquirerImage.isNotEmpty
                    ? NetworkImage(inquiry.inquirerImage)
                    : null,
                backgroundColor: theme?.primaryColor ?? const Color(0xFFFE2C55),
                child: inquiry.inquirerImage.isEmpty
                    ? Text(
                        inquiry.inquirerName.isNotEmpty
                            ? inquiry.inquirerName[0].toUpperCase()
                            : 'G',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inquiry.inquirerName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme?.textColor ?? Colors.black,
                      ),
                    ),
                    Text(
                      inquiry.timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme?.textSecondaryColor ?? Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat,
                      size: 12,
                      color: Colors.green[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'WhatsApp',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (theme?.backgroundColor ?? Colors.grey[50]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inquiry for:',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme?.textSecondaryColor ?? Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  inquiry.propertyTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme?.textColor ?? Colors.black,
                  ),
                ),
                if (inquiry.message != null && inquiry.message!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    inquiry.message!,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme?.textColor ?? Colors.black,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Text(
                inquiry.inquirerPhoneNumber,
                style: TextStyle(
                  fontSize: 12,
                  color: theme?.textSecondaryColor ?? Colors.grey[600],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _contactInquirer(inquiry),
                icon: const Icon(
                  Icons.chat,
                  size: 16,
                ),
                label: const Text(
                  'Contact',
                  style: TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green[700],
                  backgroundColor: Colors.green.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(ModernThemeExtension? theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme?.textColor ?? Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          // Analytics cards
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  title: 'Total Views',
                  value: '1.2k',
                  change: '+12%',
                  isPositive: true,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  title: 'Total Likes',
                  value: '89',
                  change: '+8%',
                  isPositive: true,
                  theme: theme,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  title: 'Inquiries',
                  value: '24',
                  change: '+15%',
                  isPositive: true,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  title: 'Response Rate',
                  value: '95%',
                  change: '+2%',
                  isPositive: true,
                  theme: theme,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Performance chart placeholder
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme?.surfaceColor ?? Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Property Views (Last 30 Days)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme?.textColor ?? Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 48,
                          color: theme?.textTertiaryColor ?? Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Analytics chart coming soon',
                          style: TextStyle(
                            color: theme?.textSecondaryColor ?? Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Top performing properties
          Text(
            'Top Performing Properties',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme?.textColor ?? Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          
          ...List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme?.surfaceColor ?? Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (theme?.dividerColor ?? Colors.grey[300]!).withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: [Colors.green, Colors.blue, Colors.orange][index],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Property ${index + 1} Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme?.textColor ?? Colors.black,
                      ),
                    ),
                  ),
                  Text(
                    '${(150 - index * 20)} views',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme?.textSecondaryColor ?? Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required String value,
    required String change,
    required bool isPositive,
    required ModernThemeExtension? theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme?.surfaceColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: theme?.textSecondaryColor ?? Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme?.textColor ?? Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                size: 14,
                color: isPositive ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _navigateToCreateProperty() {
    Navigator.pushNamed(context, PropertyConstants.createPropertyScreen);
  }

  void _navigateToEditProperty(PropertyListingModel property) {
    Navigator.pushNamed(
      context,
      PropertyConstants.editPropertyScreen,
      arguments: {
        PropertyConstants.propertyModel: property,
        PropertyConstants.isEditing: true,
      },
    );
  }

  void _navigateToPropertyDetails(PropertyListingModel property) {
    Navigator.pushNamed(
      context,
      PropertyConstants.propertyDetailsScreen,
      arguments: property.id,
    );
  }

  // Action methods
  void _handleMenuAction(String action) {
    switch (action) {
      case 'profile':
        Navigator.pushNamed(context, '/myProfile');
        break;
      case 'analytics':
        _tabController.animateTo(3);
        break;
      case 'settings':
        // TODO: Navigate to settings
        break;
      case 'help':
        // TODO: Navigate to help
        break;
    }
  }

  void _contactInquirer(PropertyInquiryModel inquiry) {
    final whatsappLink = PropertyConstants.generateWhatsAppLink(
      inquiry.inquirerPhoneNumber,
      message: 'Hi ${inquiry.inquirerName}! Thanks for your interest in "${inquiry.propertyTitle}". How can I help you?',
    );
    
    // TODO: Launch WhatsApp link
    print('Launch WhatsApp: $whatsappLink');
  }

  void _showDeleteConfirmation(PropertyListingModel property) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property'),
        content: Text(
          'Are you sure you want to delete "${property.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProperty(property);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProperty(PropertyListingModel property) async {
    try {
      await ref.read(hostPropertiesProvider.notifier).deleteProperty(property.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(PropertyConstants.propertyDeleted),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete property: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
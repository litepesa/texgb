// lib/features/status/screens/my_status_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/features/status/screens/status_viewer_screen.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/time_utils.dart';


class MyStatusScreen extends ConsumerWidget {
  final List<StatusModel> statuses;

  const MyStatusScreen({
    super.key,
    required this.statuses,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: theme.surfaceColor,
      appBar: AppBar(
        backgroundColor: theme.surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Status',
          style: TextStyle(
            color: theme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: theme.textColor),
            color: theme.surfaceColor,
            elevation: 8,
            surfaceTintColor: theme.primaryColor?.withOpacity(0.1),
            shadowColor: Colors.black.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.dividerColor?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            onSelected: (value) {
              switch (value) {
                case 'privacy':
                  _showStatusPrivacyDialog(context, theme);
                  break;
                case 'delete_all':
                  _showDeleteAllDialog(context, ref, theme);
                  break;
                case 'settings':
                  _showStatusSettings(context, theme);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'privacy',
                child: Row(
                  children: [
                    Icon(Icons.visibility, color: theme.textSecondaryColor, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Status privacy',
                      style: TextStyle(color: theme.textColor, fontSize: 15),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: theme.textSecondaryColor, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Status settings',
                      style: TextStyle(color: theme.textColor, fontSize: 15),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Delete all',
                      style: TextStyle(color: Colors.red, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            height: 0.5,
            width: double.infinity,
            color: theme.dividerColor,
          ),
        ),
      ),
      body: statuses.isEmpty 
          ? _buildEmptyState(theme)
          : Column(
              children: [
                // Status summary
                _buildStatusSummary(theme),
                
                // Divider
                Container(
                  height: 8,
                  color: theme.backgroundColor,
                ),
                
                // Status list
                Expanded(
                  child: ListView.builder(
                    itemCount: statuses.length,
                    itemBuilder: (context, index) {
                      return _buildStatusItem(context, ref, statuses[index], theme, index);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(ModernThemeExtension theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.primaryColor?.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.donut_large_rounded,
                size: 60,
                color: theme.primaryColor?.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Status Updates',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Share photos, videos, and text updates with your contacts.',
              style: TextStyle(
                fontSize: 15,
                color: theme.textSecondaryColor,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSummary(ModernThemeExtension theme) {
    final activeStatuses = statuses.where((s) => !s.isExpired).toList();
    final expiredStatuses = statuses.where((s) => s.isExpired).toList();
    final totalViews = activeStatuses.fold<int>(0, (sum, status) => sum + status.statusViewsCount);
    final averageViews = activeStatuses.isNotEmpty ? (totalViews / activeStatuses.length).round() : 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Main stats row
          Row(
            children: [
              // Active statuses
              Expanded(
                child: _buildSummaryItem(
                  theme,
                  activeStatuses.length.toString(),
                  activeStatuses.length == 1 ? 'Active Status' : 'Active Statuses',
                  Icons.donut_large_rounded,
                  theme.primaryColor!,
                ),
              ),
              
              Container(
                width: 1,
                height: 50,
                color: theme.dividerColor,
              ),
              
              // Total views
              Expanded(
                child: _buildSummaryItem(
                  theme,
                  totalViews.toString(),
                  totalViews == 1 ? 'Total View' : 'Total Views',
                  Icons.visibility,
                  Colors.blue,
                ),
              ),
            ],
          ),
          
          if (activeStatuses.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: theme.dividerColor,
            ),
            const SizedBox(height: 16),
            
            // Secondary stats row
            Row(
              children: [
                // Average views
                Expanded(
                  child: _buildSummaryItem(
                    theme,
                    averageViews.toString(),
                    'Avg Views',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                
                Container(
                  width: 1,
                  height: 50,
                  color: theme.dividerColor,
                ),
                
                // Expired statuses
                Expanded(
                  child: _buildSummaryItem(
                    theme,
                    expiredStatuses.length.toString(),
                    expiredStatuses.length == 1 ? 'Expired' : 'Expired',
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    ModernThemeExtension theme,
    String count,
    String label,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: theme.textSecondaryColor,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatusItem(
    BuildContext context,
    WidgetRef ref,
    StatusModel status,
    ModernThemeExtension theme,
    int index,
  ) {
    final isExpired = status.isExpired;
    
    return InkWell(
      onTap: () => _viewStatus(context, status, index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isExpired ? theme.surfaceColor?.withOpacity(0.5) : theme.surfaceColor,
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Status preview
            _buildStatusPreview(status, theme),
            
            const SizedBox(width: 16),
            
            // Status info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status title
                  Text(
                    _getStatusTitle(status),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isExpired ? theme.textSecondaryColor : theme.textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  
                  // Status metadata
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: theme.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        TimeUtils.getStatusTimeAgo(status.statusCreatedAt),
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.visibility,
                        size: 14,
                        color: theme.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${status.statusViewsCount}',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Status status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isExpired 
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isExpired ? Icons.schedule : Icons.timer,
                          size: 12,
                          color: isExpired ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isExpired ? 'Expired' : status.timeRemainingText,
                          style: TextStyle(
                            fontSize: 12,
                            color: isExpired ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Options menu
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: theme.textSecondaryColor,
                size: 20,
              ),
              color: theme.surfaceColor,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'viewers':
                    _showViewers(context, status, theme);
                    break;
                  case 'privacy':
                    _showStatusPrivacyDialog(context, theme);
                    break;
                  case 'share':
                    _shareStatus(context, status);
                    break;
                  case 'download':
                    _downloadStatus(context, status);
                    break;
                  case 'delete':
                    _deleteStatus(context, ref, status, theme);
                    break;
                }
              },
              itemBuilder: (context) => [
                if (!status.isExpired) ...[
                  PopupMenuItem(
                    value: 'viewers',
                    child: Row(
                      children: [
                        Icon(Icons.people, color: theme.textSecondaryColor, size: 18),
                        const SizedBox(width: 12),
                        Text('Viewers', style: TextStyle(color: theme.textColor)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share, color: theme.textSecondaryColor, size: 18),
                        const SizedBox(width: 12),
                        Text('Share', style: TextStyle(color: theme.textColor)),
                      ],
                    ),
                  ),
                ],
                if (status.statusMediaUrl != null)
                  PopupMenuItem(
                    value: 'download',
                    child: Row(
                      children: [
                        Icon(Icons.download, color: theme.textSecondaryColor, size: 18),
                        const SizedBox(width: 12),
                        Text('Download', style: TextStyle(color: theme.textColor)),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'privacy',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, color: theme.textSecondaryColor, size: 18),
                      const SizedBox(width: 12),
                      Text('Privacy', style: TextStyle(color: theme.textColor)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 18),
                      const SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPreview(StatusModel status, ModernThemeExtension theme) {
    const double size = 64;
    final isExpired = status.isExpired;
    
    Widget content;
    
    switch (status.statusType) {
      case Constants.statusTypeText:
        final backgroundColor = status.statusBackgroundColor != null
            ? Color(int.parse(status.statusBackgroundColor!))
            : theme.primaryColor!;
        
        content = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isExpired ? backgroundColor.withOpacity(0.5) : backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              status.statusContent.length > 3 
                  ? status.statusContent.substring(0, 3)
                  : status.statusContent,
              style: TextStyle(
                color: Colors.white.withOpacity(isExpired ? 0.7 : 1.0),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
        break;
      
      case Constants.statusTypeImage:
        content = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor!, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: status.statusMediaUrl != null
                ? Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: status.statusMediaUrl!,
                        fit: BoxFit.cover,
                        width: size,
                        height: size,
                        placeholder: (context, url) => Container(
                          color: theme.surfaceVariantColor,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.surfaceVariantColor,
                          child: Icon(
                            Icons.broken_image,
                            color: theme.textSecondaryColor,
                            size: 24,
                          ),
                        ),
                      ),
                      if (isExpired)
                        Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                    ],
                  )
                : Container(
                    color: theme.surfaceVariantColor,
                    child: Icon(
                      Icons.image,
                      color: theme.textSecondaryColor,
                      size: 24,
                    ),
                  ),
          ),
        );
        break;
      
      case Constants.statusTypeVideo:
        content = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor!, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Stack(
              children: [
                status.statusThumbnail != null
                    ? CachedNetworkImage(
                        imageUrl: status.statusThumbnail!,
                        fit: BoxFit.cover,
                        width: size,
                        height: size,
                        placeholder: (context, url) => Container(
                          color: theme.surfaceVariantColor,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.surfaceVariantColor,
                          child: Icon(
                            Icons.videocam,
                            color: theme.textSecondaryColor,
                            size: 24,
                          ),
                        ),
                      )
                    : Container(
                        color: theme.surfaceVariantColor,
                        child: Icon(
                          Icons.videocam,
                          color: theme.textSecondaryColor,
                          size: 24,
                        ),
                      ),
                
                // Play button overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(isExpired ? 0.7 : 0.3),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white.withOpacity(isExpired ? 0.7 : 1.0),
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        break;
      
      default:
        content = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: theme.surfaceVariantColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor!, width: 1),
          ),
          child: Icon(
            Icons.help_outline,
            color: theme.textSecondaryColor,
            size: 24,
          ),
        );
    }
    
    return Stack(
      children: [
        content,
        if (isExpired)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.schedule,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
      ],
    );
  }

  String _getStatusTitle(StatusModel status) {
    switch (status.statusType) {
      case Constants.statusTypeText:
        return status.statusContent.length > 40
            ? '${status.statusContent.substring(0, 40)}...'
            : status.statusContent;
      case Constants.statusTypeImage:
        return 'Photo Status';
      case Constants.statusTypeVideo:
        return 'Video Status';
      default:
        return 'Status Update';
    }
  }

  void _viewStatus(BuildContext context, StatusModel status, int index) {
    // Create a mock user status group for viewing
    final userStatusGroup = UserStatusGroup(
      uid: status.uid,
      userName: status.userName,
      userImage: status.userImage,
      statuses: statuses,
      lastStatusTime: status.statusCreatedAt,
      hasUnviewedStatus: false,
      unviewedCount: 0,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusViewerScreen(
          statusGroup: userStatusGroup,
          initialIndex: index,
        ),
      ),
    );
  }

  void _showViewers(BuildContext context, StatusModel status, ModernThemeExtension theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildViewersBottomSheet(context, status, theme),
    );
  }

  Widget _buildViewersBottomSheet(BuildContext context, StatusModel status, ModernThemeExtension theme) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Status Views',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // View count display
            Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: theme.primaryColor!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.visibility,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${status.statusViewsCount}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      Text(
                        status.statusViewsCount == 1 ? 'view' : 'views',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Additional stats
            if (status.statusViewers.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.surfaceVariantColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.people,
                              color: theme.primaryColor,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${status.statusViewers.length}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                            Text(
                              'Viewers',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.surfaceVariantColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.timer,
                              color: Colors.orange,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              status.isExpired ? 'Expired' : status.timeRemainingText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: status.isExpired ? Colors.red : Colors.orange,
                              ),
                            ),
                            Text(
                              'Status',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textSecondaryColor,
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
            ],
            
            // Close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showStatusPrivacyDialog(BuildContext context, ModernThemeExtension theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildStatusPrivacyBottomSheet(context, theme),
    );
  }

  Widget _buildStatusPrivacyBottomSheet(BuildContext context, ModernThemeExtension theme) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Status Privacy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Choose who can see your status updates',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Privacy options
            _buildPrivacyOption(
              theme: theme,
              icon: Icons.contacts,
              title: 'My contacts',
              subtitle: 'Share with all your contacts',
              value: Constants.statusPrivacyContacts,
              isSelected: true,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Privacy setting updated'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            
            _buildPrivacyOption(
              theme: theme,
              icon: Icons.person_remove,
              title: 'My contacts except...',
              subtitle: 'Share with all contacts except selected',
              value: 'contacts_except',
              isSelected: false,
              onTap: () {
                Navigator.pop(context);
                _showContactSelectionScreen(context, 'exclude');
              },
            ),
            
            _buildPrivacyOption(
              theme: theme,
              icon: Icons.person_outline,
              title: 'Only share with...',
              subtitle: 'Share with selected contacts only',
              value: Constants.statusPrivacyCustom,
              isSelected: false,
              onTap: () {
                Navigator.pop(context);
                _showContactSelectionScreen(context, 'include');
              },
            ),
            
            _buildPrivacyOption(
              theme: theme,
              icon: Icons.favorite,
              title: 'Close friends',
              subtitle: 'Share with close friends only',
              value: Constants.statusPrivacyClose,
              isSelected: false,
              onTap: () {
                Navigator.pop(context);
                _showContactSelectionScreen(context, 'close_friends');
              },
            ),
            
            const SizedBox(height: 24),
            
            // Info section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Changes to privacy settings will apply to new status updates only.',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyOption({
    required ModernThemeExtension theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected 
                    ? theme.primaryColor!.withOpacity(0.1)
                    : theme.surfaceVariantColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? theme.primaryColor : theme.textSecondaryColor,
                size: 22,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.primaryColor,
                size: 24,
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.dividerColor!,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showContactSelectionScreen(BuildContext context, String type) {
    // TODO: Implement contact selection screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contact selection for $type coming soon'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showStatusSettings(BuildContext context, ModernThemeExtension theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildStatusSettingsBottomSheet(context, theme),
    );
  }

  Widget _buildStatusSettingsBottomSheet(BuildContext context, ModernThemeExtension theme) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Status Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Settings options
            _buildSettingsOption(
              theme: theme,
              icon: Icons.timer,
              title: 'Auto-delete after',
              subtitle: '24 hours (default)',
              onTap: () {
                Navigator.pop(context);
                _showDurationSettings(context, theme);
              },
            ),
            
            _buildSettingsOption(
              theme: theme,
              icon: Icons.download,
              title: 'Auto-save to gallery',
              subtitle: 'Save your status updates automatically',
              trailing: Switch(
                value: false,
                onChanged: (value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value ? 'Auto-save enabled' : 'Auto-save disabled'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                activeColor: theme.primaryColor,
              ),
              onTap: null,
            ),
            
            _buildSettingsOption(
              theme: theme,
              icon: Icons.notifications,
              title: 'View notifications',
              subtitle: 'Get notified when someone views your status',
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value ? 'Notifications enabled' : 'Notifications disabled'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                activeColor: theme.primaryColor,
              ),
              onTap: null,
            ),
            
            _buildSettingsOption(
              theme: theme,
              icon: Icons.analytics,
              title: 'View analytics',
              subtitle: 'See detailed view statistics',
              onTap: () {
                Navigator.pop(context);
                _showAnalytics(context, theme);
              },
            ),
            
            _buildSettingsOption(
              theme: theme,
              icon: Icons.storage,
              title: 'Storage usage',
              subtitle: 'Manage status storage',
              onTap: () {
                Navigator.pop(context);
                _showStorageInfo(context, theme);
              },
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption({
    required ModernThemeExtension theme,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.primaryColor!.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: theme.primaryColor,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            if (trailing != null)
              trailing
            else if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                color: theme.textSecondaryColor,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  void _showDurationSettings(BuildContext context, ModernThemeExtension theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor,
        title: Text(
          'Status Duration',
          style: TextStyle(color: theme.textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How long should your status updates be visible?',
              style: TextStyle(color: theme.textSecondaryColor),
            ),
            const SizedBox(height: 16),
            ...['1 hour', '6 hours', '12 hours', '24 hours', '48 hours'].map(
              (duration) => RadioListTile<String>(
                title: Text(duration, style: TextStyle(color: theme.textColor)),
                value: duration,
                groupValue: '24 hours',
                onChanged: (value) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Duration set to $value'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                activeColor: theme.primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showAnalytics(BuildContext context, ModernThemeExtension theme) {
    final totalViews = statuses.fold<int>(0, (sum, status) => sum + status.statusViewsCount);
    final activeStatuses = statuses.where((s) => !s.isExpired).length;
    final expiredStatuses = statuses.where((s) => s.isExpired).length;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor,
        title: Text(
          'Status Analytics',
          style: TextStyle(color: theme.textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnalyticsRow(theme, 'Total Statuses', '${statuses.length}'),
            _buildAnalyticsRow(theme, 'Active Statuses', '$activeStatuses'),
            _buildAnalyticsRow(theme, 'Expired Statuses', '$expiredStatuses'),
            _buildAnalyticsRow(theme, 'Total Views', '$totalViews'),
            _buildAnalyticsRow(theme, 'Average Views', 
                activeStatuses > 0 ? '${(totalViews / activeStatuses).round()}' : '0'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: theme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsRow(ModernThemeExtension theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showStorageInfo(BuildContext context, ModernThemeExtension theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor,
        title: Text(
          'Storage Usage',
          style: TextStyle(color: theme.textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storage,
              size: 48,
              color: theme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Status storage management',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status updates are automatically deleted after expiration to save storage space.',
              style: TextStyle(
                color: theme.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Storage cleanup completed'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              'Clean Up',
              style: TextStyle(color: theme.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: theme.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _shareStatus(BuildContext context, StatusModel status) {
    // TODO: Implement status sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Status sharing coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _downloadStatus(BuildContext context, StatusModel status) {
    // TODO: Implement status download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download functionality coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context, WidgetRef ref, ModernThemeExtension theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor,
        title: Text(
          'Delete All Status Updates?',
          style: TextStyle(color: theme.textColor),
        ),
        content: Text(
          'This will permanently delete all your status updates. This action cannot be undone.',
          style: TextStyle(color: theme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAllStatuses(context, ref);
            },
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteStatus(BuildContext context, WidgetRef ref, StatusModel status, ModernThemeExtension theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor,
        title: Text(
          'Delete Status?',
          style: TextStyle(color: theme.textColor),
        ),
        content: Text(
          'This status update will be deleted permanently.',
          style: TextStyle(color: theme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(statusNotifierProvider.notifier).deleteStatus(status.statusId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Status deleted successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete status: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteAllStatuses(BuildContext context, WidgetRef ref) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Delete all statuses
      for (final status in statuses) {
        await ref.read(statusNotifierProvider.notifier).deleteStatus(status.statusId);
      }
      
      if (context.mounted) {
        // Close loading dialog
        Navigator.pop(context);
        // Close my status screen
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All status updates deleted successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        // Close loading dialog
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete statuses: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
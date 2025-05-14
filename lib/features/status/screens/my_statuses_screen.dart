import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class MyStatusesScreen extends ConsumerWidget {
  const MyStatusesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modernTheme = context.modernTheme;
    final myStatusesStream = ref.watch(myStatusesStreamProvider);
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Status'),
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, Constants.createStatusScreen);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, Constants.statusSettingsScreen);
            },
          ),
        ],
      ),
      body: myStatusesStream.when(
        data: (statuses) {
          if (statuses.isEmpty) {
            return _buildEmptyState(context, modernTheme);
          }
          
          return ListView(
            children: [
              // Status stats
              _buildStatusStats(context, modernTheme, statuses),
              
              const SizedBox(height: 8),
              
              // Statuses list
              ...statuses.map((status) => _buildStatusItem(context, ref, modernTheme, status)).toList(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, Constants.createStatusScreen);
        },
        child: const Icon(Icons.add),
        backgroundColor: modernTheme.primaryColor,
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context, ModernThemeExtension modernTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: modernTheme.textSecondaryColor?.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "No status updates yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: modernTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap the + button to create your first status",
            style: TextStyle(
              fontSize: 16,
              color: modernTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, Constants.createStatusScreen);
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Status'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              backgroundColor: modernTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusStats(BuildContext context, ModernThemeExtension modernTheme, List<StatusModel> statuses) {
    // Count total views across all statuses
    int totalViews = 0;
    for (var status in statuses) {
      totalViews += status.seenBy.length;
    }
    
    // Group statuses by type
    final Map<StatusType, int> typeCounter = {};
    for (var status in statuses) {
      typeCounter[status.type] = (typeCounter[status.type] ?? 0) + 1;
    }
    
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status Overview',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  modernTheme,
                  Icons.photo_library,
                  '${statuses.length}',
                  'Total',
                ),
                _buildStatItem(
                  context,
                  modernTheme,
                  Icons.visibility,
                  '$totalViews',
                  'Views',
                ),
                _buildStatItem(
                  context,
                  modernTheme,
                  Icons.access_time,
                  '24h',
                  'Duration',
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Status Types',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (typeCounter.containsKey(StatusType.text))
                  _buildTypeChip(
                    modernTheme,
                    'Text',
                    typeCounter[StatusType.text]!,
                    Colors.blue,
                  ),
                if (typeCounter.containsKey(StatusType.image))
                  _buildTypeChip(
                    modernTheme,
                    'Image',
                    typeCounter[StatusType.image]!,
                    Colors.green,
                  ),
                if (typeCounter.containsKey(StatusType.video))
                  _buildTypeChip(
                    modernTheme,
                    'Video',
                    typeCounter[StatusType.video]!,
                    Colors.red,
                  ),
                if (typeCounter.containsKey(StatusType.link))
                  _buildTypeChip(
                    modernTheme,
                    'Link',
                    typeCounter[StatusType.link]!,
                    Colors.purple,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(
    BuildContext context,
    ModernThemeExtension modernTheme,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: modernTheme.primaryColor!.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: modernTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: modernTheme.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: modernTheme.textSecondaryColor,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTypeChip(
    ModernThemeExtension modernTheme,
    String label,
    int count,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusItem(
    BuildContext context,
    WidgetRef ref,
    ModernThemeExtension modernTheme,
    StatusModel status,
  ) {
    IconData typeIcon;
    String typeName;
    Color typeColor;
    
    switch (status.type) {
      case StatusType.text:
        typeIcon = Icons.text_fields;
        typeName = 'Text';
        typeColor = Colors.blue;
        break;
      case StatusType.image:
        typeIcon = Icons.image;
        typeName = 'Image';
        typeColor = Colors.green;
        break;
      case StatusType.video:
        typeIcon = Icons.videocam;
        typeName = 'Video';
        typeColor = Colors.red;
        break;
      case StatusType.link:
        typeIcon = Icons.link;
        typeName = 'Link';
        typeColor = Colors.purple;
        break;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: InkWell(
        onTap: () {
          // Navigate to view own status
          Navigator.pushNamed(
            context,
            Constants.statusViewerScreen,
            arguments: {
              'contactUid': status.uid,
              'initialStatusId': status.statusId,
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with type and time
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      typeIcon,
                      color: typeColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    typeName,
                    style: TextStyle(
                      color: modernTheme.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    status.timeAgo,
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: modernTheme.textSecondaryColor,
                    ),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteConfirmation(context, ref, status);
                      } else if (value == 'edit') {
                        // Navigate to edit status screen
                        // This would be implemented in a real app
                        showSnackBar(context, 'Edit feature coming soon');
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Status preview
              _buildStatusPreview(modernTheme, status),
              
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              
              // Status stats
              Row(
                children: [
                  Icon(
                    Icons.visibility,
                    color: modernTheme.textSecondaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${status.seenBy.length} views',
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.privacy_tip,
                    color: modernTheme.textSecondaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    status.privacyType.displayName,
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusPreview(ModernThemeExtension modernTheme, StatusModel status) {
    switch (status.type) {
      case StatusType.text:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade100.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.blue.shade200,
              width: 1,
            ),
          ),
          child: Text(
            status.content,
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 16,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        );
        
      case StatusType.image:
        return Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade200,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: status.content,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.error),
              ),
            ),
          ),
        );
        
      case StatusType.video:
        return Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video thumbnail would be shown here in a real app
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: Colors.grey.shade800,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              const Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 50,
              ),
            ],
          ),
        );
        
      case StatusType.link:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.shade100.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.purple.shade200,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.link, color: Colors.purple),
              const SizedBox(height: 8),
              Text(
                status.content,
                style: TextStyle(
                  color: Colors.purple.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (status.caption != null && status.caption!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  status.caption!,
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
    }
  }
  
  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, StatusModel status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Status'),
        content: const Text('Are you sure you want to delete this status?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await ref.read(statusProvider.notifier).deleteStatus(status.statusId);
                if (context.mounted) {
                  showSnackBar(context, 'Status deleted');
                }
              } catch (e) {
                if (context.mounted) {
                  showSnackBar(context, 'Error deleting status: $e');
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
// ===============================
// My Status Detail Screen
// View and manage your own statuses
// ===============================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/providers/status_providers.dart';
import 'package:textgb/features/status/services/status_time_service.dart';
import 'package:textgb/core/router/route_paths.dart';

class MyStatusDetailScreen extends ConsumerWidget {
  const MyStatusDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFeedAsync = ref.watch(statusFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.push(RoutePaths.createStatus),
            tooltip: 'Add Status',
          ),
        ],
      ),
      body: statusFeedAsync.when(
        data: (state) {
          final myStatuses = state.myStatuses;

          if (myStatuses.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myStatuses.length,
            itemBuilder: (context, index) {
              final status = myStatuses[index];
              return _StatusCard(status: status);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading statuses: $error'),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No status yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first status',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push(RoutePaths.createStatus),
            icon: const Icon(Icons.add),
            label: const Text('Add Status'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends ConsumerWidget {
  final StatusModel status;

  const _StatusCard({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status preview
          _buildStatusPreview(context),

          // Status info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time and expiry
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      StatusTimeService.formatStatusTime(status.createdAt),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status.isExpired
                            ? Colors.red[100]
                            : Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.isExpired
                            ? 'Expired'
                            : StatusTimeService.formatTimeRemaining(status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: status.isExpired
                              ? Colors.red[700]
                              : Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Stats
                Row(
                  children: [
                    _StatItem(
                      icon: Icons.visibility_outlined,
                      count: status.viewsCount,
                      label: 'Views',
                    ),
                    const SizedBox(width: 24),
                    _StatItem(
                      icon: Icons.favorite_outline,
                      count: status.likesCount,
                      label: 'Likes',
                    ),
                    const SizedBox(width: 24),
                    _StatItem(
                      icon: Icons.card_giftcard_outlined,
                      count: status.giftsCount,
                      label: 'Gifts',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewStatus(context, ref),
                        icon: const Icon(Icons.remove_red_eye_outlined),
                        label: const Text('View'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteStatus(context, ref),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
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

  Widget _buildStatusPreview(BuildContext context) {
    if (status.mediaType.isImage && status.mediaUrl != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: CachedNetworkImage(
            imageUrl: status.mediaUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      );
    } else if (status.mediaType.isVideo && status.thumbnailUrl != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: status.thumbnailUrl!,
                fit: BoxFit.cover,
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (status.mediaType.isText && status.content != null) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: status.textBackground != null
              ? LinearGradient(
                  colors: status.textBackground!.colors.map((hex) => _hexToColor(hex)).toList(),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                ),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              status.content!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _viewStatus(BuildContext context, WidgetRef ref) {
    final statusFeedState = ref.read(statusFeedProvider).value;
    final myStatusGroup = statusFeedState?.myStatusGroup;

    if (myStatusGroup != null) {
      final statusIndex = myStatusGroup.statuses.indexOf(status);
      context.push(
        RoutePaths.statusViewer,
        extra: {
          'group': myStatusGroup,
          'initialIndex': statusIndex >= 0 ? statusIndex : 0,
        },
      );
    }
  }

  void _deleteStatus(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Status?'),
        content: const Text(
          'This status will be permanently deleted. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(statusFeedProvider.notifier).deleteStatus(status.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Status deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;

  const _StatItem({
    required this.icon,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

// Helper function to convert hex color string to Color
Color _hexToColor(String hex) {
  final hexCode = hex.replaceAll('#', '');
  return Color(int.parse('FF$hexCode', radix: 16));
}
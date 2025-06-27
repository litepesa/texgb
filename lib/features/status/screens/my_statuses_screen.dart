import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/features/status/screens/status_detail_screen.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';
import 'package:timeago/timeago.dart' as timeago;

class MyStatusesScreen extends ConsumerWidget {
  const MyStatusesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modernTheme = context.modernTheme;
    final myStatusesAsyncValue = ref.watch(myStatusesStreamProvider);
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: modernTheme.backgroundColor,
        elevation: 0,
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Status',
          style: TextStyle(
            color: modernTheme.textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.pushNamed(context, Constants.createStatusScreen);
            },
          ),
        ],
      ),
      body: myStatusesAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Error loading your statuses: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (statuses) {
          if (statuses.isEmpty) {
            return _buildNoStatusesView(context, modernTheme);
          }
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status count and time info
              Text(
                'You have ${statuses.length} active ${statuses.length == 1 ? 'status' : 'statuses'}',
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Status will disappear after 24 hours',
                style: TextStyle(
                  color: modernTheme.textSecondaryColor!.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
              
              // Status list
              ...statuses.map((status) => _buildStatusItem(context, status, modernTheme)).toList(),
              
              const SizedBox(height: 24),
              
              // Create new status button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, Constants.createStatusScreen);
                },
                icon: const Icon(Icons.add),
                label: const Text('Add New Status'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: modernTheme.primaryColor,
                  side: BorderSide(color: modernTheme.primaryColor!),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoStatusesView(BuildContext context, ModernThemeExtension modernTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_album_outlined,
            size: 80,
            color: modernTheme.textSecondaryColor!.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No active statuses',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share a photo, video or text with your contacts',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, Constants.createStatusScreen);
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Status'),
            style: ElevatedButton.styleFrom(
              backgroundColor: modernTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(BuildContext context, StatusModel status, ModernThemeExtension modernTheme) {
    // Format the time
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      int.parse(status.createdAt),
    );
    final timeAgo = timeago.format(createdAt);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StatusDetailScreen(status: status),
            ),
          );
        },
        child: Container(
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
              // Preview of the status content
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: _buildStatusPreview(status, modernTheme),
              ),
              
              // Status info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getStatusTypeIcon(status.type),
                              size: 18,
                              color: modernTheme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              status.type.displayName,
                              style: TextStyle(
                                color: modernTheme.textSecondaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (status.caption.isNotEmpty) ...[
                      Text(
                        status.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: modernTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Icon(
                          Icons.remove_red_eye,
                          size: 16,
                          color: modernTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${status.viewCount} ${status.viewCount == 1 ? 'view' : 'views'}',
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        // Privacy indicator
                        Row(
                          children: [
                            Icon(
                              _getPrivacyTypeIcon(status.privacyType),
                              size: 16,
                              color: modernTheme.textSecondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getPrivacyTypeText(status.privacyType),
                              style: TextStyle(
                                color: modernTheme.textSecondaryColor,
                                fontSize: 12,
                              ),
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
        ),
      ),
    );
  }

  Widget _buildStatusPreview(StatusModel status, ModernThemeExtension modernTheme) {
    switch (status.type) {
      case StatusType.image:
        return Image.network(
          status.content,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              width: double.infinity,
              color: modernTheme.surfaceColor!.withOpacity(0.7),
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              width: double.infinity,
              color: modernTheme.surfaceColor!.withOpacity(0.7),
              child: const Center(
                child: Icon(Icons.error_outline, size: 40),
              ),
            );
          },
        );
      
      case StatusType.video:
        return Container(
          height: 200,
          width: double.infinity,
          color: Colors.black87,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.network(
                // Here you would ideally use a video thumbnail
                status.content,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.black54,
                  );
                },
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ],
          ),
        );
      
      case StatusType.text:
        return Container(
          padding: const EdgeInsets.all(16),
          height: 150,
          width: double.infinity,
          color: modernTheme.primaryColor,
          child: Center(
            child: Text(
              status.content,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      
      case StatusType.link:
        return Container(
          padding: const EdgeInsets.all(16),
          height: 120,
          width: double.infinity,
          color: modernTheme.surfaceColor!.withOpacity(0.7),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.link_rounded,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                status.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: modernTheme.primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        );
    }
  }

  IconData _getStatusTypeIcon(StatusType type) {
    switch (type) {
      case StatusType.text:
        return Icons.text_fields;
      case StatusType.image:
        return Icons.image;
      case StatusType.video:
        return Icons.videocam;
      case StatusType.link:
        return Icons.link;
    }
  }

  IconData _getPrivacyTypeIcon(StatusPrivacyType type) {
    switch (type) {
      case StatusPrivacyType.all_contacts:
        return Icons.people;
      case StatusPrivacyType.except:
        return Icons.person_remove;
      case StatusPrivacyType.only:
        return Icons.person_add;
    }
  }

  String _getPrivacyTypeText(StatusPrivacyType type) {
    switch (type) {
      case StatusPrivacyType.all_contacts:
        return 'All contacts';
      case StatusPrivacyType.except:
        return 'Except some';
      case StatusPrivacyType.only:
        return 'Only some';
    }
  }
}
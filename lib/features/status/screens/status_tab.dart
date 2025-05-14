import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class StatusTab extends ConsumerWidget {
  const StatusTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modernTheme = context.modernTheme;
    final currentUser = ref.watch(currentUserProvider);
    final statusState = ref.watch(statusProvider).valueOrNull;
    
    if (currentUser == null) {
      return Center(
        child: CircularProgressIndicator(
          color: modernTheme.primaryColor,
        ),
      );
    }
    
    return Container(
      color: modernTheme.backgroundColor,
      child: ListView(
        padding: const EdgeInsets.only(top: 8.0, bottom: 100),
        children: [
          // My status section
          _buildMyStatusSection(context, ref, currentUser, modernTheme, statusState),
          
          // Recent updates section if there are any contacts with statuses
          if (statusState != null && statusState.contactStatuses.isNotEmpty) ...[
            _buildSectionHeader(context, modernTheme, 'Recent Updates'),
            
            // List of contact statuses
            _buildContactStatusesList(context, ref, modernTheme, statusState),
          ],
          
          // Viewed updates section
          if (statusState != null && _hasViewedStatuses(statusState, currentUser.uid)) ...[
            _buildSectionHeader(context, modernTheme, 'Viewed Updates'),
            
            // List of already viewed contact statuses
            _buildViewedStatusesList(context, ref, modernTheme, statusState, currentUser.uid),
          ],
          
          // Show empty state if no contact has posted any status
          if (statusState == null || statusState.contactStatuses.isEmpty) 
            _buildEmptyState(context, modernTheme),
        ],
      ),
    );
  }
  
  Widget _buildMyStatusSection(
    BuildContext context,
    WidgetRef ref,
    dynamic currentUser,
    ModernThemeExtension modernTheme,
    StatusState? statusState,
  ) {
    final hasMyStatus = statusState != null && statusState.myStatuses.isNotEmpty;
    
    return ListTile(
      leading: Stack(
        children: [
          // Profile picture with status ring if user has status
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: hasMyStatus 
                ? Border.all(
                    color: modernTheme.primaryColor!,
                    width: 2,
                  )
                : null,
            ),
            child: CircleAvatar(
              backgroundColor: modernTheme.primaryColor!.withOpacity(0.2),
              radius: 24,
              backgroundImage: currentUser.image.isNotEmpty
                ? CachedNetworkImageProvider(currentUser.image)
                : null,
              child: currentUser.image.isEmpty
                ? Text(
                    currentUser.name.isNotEmpty
                        ? currentUser.name.substring(0, 1)
                        : '?',
                    style: TextStyle(
                      color: modernTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
            ),
          ),
          
          // Add button
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: modernTheme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: modernTheme.backgroundColor!,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
      title: Text(
        hasMyStatus ? "My Status" : "My Status",
        style: TextStyle(
          color: modernTheme.textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        hasMyStatus 
            ? "Tap to view your status" 
            : "Tap to add status update",
        style: TextStyle(
          color: modernTheme.textSecondaryColor,
        ),
      ),
      onTap: () {
        if (hasMyStatus) {
          // Navigate to view own status
          Navigator.pushNamed(
            context, 
            Constants.myStatusesScreen,
          );
        } else {
          // Navigate to create status
          Navigator.pushNamed(
            context, 
            Constants.createStatusScreen,
          );
        }
      },
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, ModernThemeExtension modernTheme, String title) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        title,
        style: TextStyle(
          color: modernTheme.textSecondaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildContactStatusesList(
    BuildContext context,
    WidgetRef ref,
    ModernThemeExtension modernTheme,
    StatusState statusState,
  ) {
    final statusNotifier = ref.read(statusProvider.notifier);
    final currentUser = ref.read(currentUserProvider);
    
    if (currentUser == null) return const SizedBox.shrink();
    
    final contactsWithStatus = statusNotifier.getContactsWithStatus();
    
    // Filter to only unviewed or partially viewed statuses
    final unviewedContacts = contactsWithStatus.where((contactUid) {
      final statuses = statusState.contactStatuses[contactUid] ?? [];
      if (statuses.isEmpty) return false;
      
      // Check if any status is unviewed
      for (final status in statuses) {
        if (!status.seenBy.contains(currentUser.uid)) {
          return true;
        }
      }
      
      // If all are viewed but were viewed recently, also include
      // This would need time tracking in a real app
      return false;
    }).toList();
    
    return Column(
      children: unviewedContacts.map((contactUid) {
        final statuses = statusState.contactStatuses[contactUid] ?? [];
        if (statuses.isEmpty) return const SizedBox.shrink();
        
        // Get the most recent status
        final latestStatus = statuses.reduce((a, b) {
          final aTime = int.parse(a.timestamp);
          final bTime = int.parse(b.timestamp);
          return aTime > bTime ? a : b;
        });
        
        // Count unviewed statuses
        final unviewedCount = statuses.where((s) => !s.seenBy.contains(currentUser.uid)).length;
        
        return _buildStatusTile(
          context,
          modernTheme,
          latestStatus,
          unviewedCount,
          hasUnviewed: unviewedCount > 0,
        );
      }).toList(),
    );
  }
  
  Widget _buildViewedStatusesList(
    BuildContext context,
    WidgetRef ref,
    ModernThemeExtension modernTheme,
    StatusState statusState,
    String currentUserId,
  ) {
    final statusNotifier = ref.read(statusProvider.notifier);
    final contactsWithStatus = statusNotifier.getContactsWithStatus();
    
    // Filter to only fully viewed statuses
    final viewedContacts = contactsWithStatus.where((contactUid) {
      final statuses = statusState.contactStatuses[contactUid] ?? [];
      if (statuses.isEmpty) return false;
      
      // Check if all statuses are viewed
      bool allViewed = true;
      for (final status in statuses) {
        if (!status.seenBy.contains(currentUserId)) {
          allViewed = false;
          break;
        }
      }
      
      return allViewed;
    }).toList();
    
    return Column(
      children: viewedContacts.map((contactUid) {
        final statuses = statusState.contactStatuses[contactUid] ?? [];
        if (statuses.isEmpty) return const SizedBox.shrink();
        
        // Get the most recent status
        final latestStatus = statuses.reduce((a, b) {
          final aTime = int.parse(a.timestamp);
          final bTime = int.parse(b.timestamp);
          return aTime > bTime ? a : b;
        });
        
        return _buildStatusTile(
          context,
          modernTheme,
          latestStatus,
          statuses.length,
          hasUnviewed: false,
        );
      }).toList(),
    );
  }
  
  Widget _buildStatusTile(
    BuildContext context,
    ModernThemeExtension modernTheme,
    StatusModel status,
    int statusCount,
    {required bool hasUnviewed}
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: hasUnviewed 
                ? modernTheme.primaryColor!
                : modernTheme.textSecondaryColor!,
            width: 2,
          ),
        ),
        child: CircleAvatar(
          backgroundColor: modernTheme.primaryColor!.withOpacity(0.2),
          radius: 24,
          backgroundImage: status.userImage.isNotEmpty
              ? CachedNetworkImageProvider(status.userImage)
              : null,
          child: status.userImage.isEmpty
              ? Text(
                  status.username.isNotEmpty
                      ? status.username.substring(0, 1)
                      : '?',
                  style: TextStyle(
                    color: modernTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
      ),
      title: Text(
        status.username,
        style: TextStyle(
          color: modernTheme.textColor,
          fontWeight: hasUnviewed ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        status.timeAgo,
        style: TextStyle(
          color: modernTheme.textSecondaryColor,
        ),
      ),
      trailing: statusCount > 1 
          ? Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: hasUnviewed ? modernTheme.primaryColor : Colors.grey.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$statusCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: () {
        // Navigate to view status
        Navigator.pushNamed(
          context, 
          Constants.statusViewerScreen,
          arguments: {
            'contactUid': status.uid,
            'initialStatusId': status.statusId,
          },
        );
      },
    );
  }
  
  bool _hasViewedStatuses(StatusState statusState, String currentUserId) {
    for (final contact in statusState.contactStatuses.keys) {
      final statuses = statusState.contactStatuses[contact] ?? [];
      if (statuses.isEmpty) continue;
      
      // Check if all statuses are viewed
      bool allViewed = true;
      for (final status in statuses) {
        if (!status.seenBy.contains(currentUserId)) {
          allViewed = false;
          break;
        }
      }
      
      if (allViewed) return true;
    }
    
    return false;
  }
  
  Widget _buildEmptyState(BuildContext context, ModernThemeExtension modernTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
      child: Center(
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
              "No status updates",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: modernTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "When your contacts post status updates, you'll see them here",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: modernTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
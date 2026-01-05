// lib/features/contacts/widgets/contacts_empty_states_widget.dart
// Extracted empty state widgets for better maintainability
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class ContactsEmptyStatesWidget {
  // Permission request UI with modern design
  static Widget buildPermissionScreen(
      BuildContext context, VoidCallback onRequestPermission) {
    final theme = context.modernTheme;

    return Container(
      color: theme.surfaceColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.dividerColor!.withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor!.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                  spreadRadius: -6,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                  spreadRadius: -3,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.primaryColor!.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.contacts_rounded,
                    size: 60,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Contacts Access Required',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: theme.textColor,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'To sync your contacts and find friends on TexGB, we need access to your contacts.',
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.textSecondaryColor,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: onRequestPermission,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor!.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.security_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Grant Permission',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Empty contacts state
  static Widget buildEmptyContactsState(
      BuildContext context, String searchQuery, VoidCallback onSyncContacts) {
    final theme = context.modernTheme;

    return Container(
      color: theme.surfaceColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.primaryColor!.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.person_2,
                  size: 64,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                searchQuery.isEmpty
                    ? 'No contacts found'
                    : 'No matching contacts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                searchQuery.isEmpty
                    ? 'Your contacts will appear here when synced'
                    : 'Try a different search term',
                style: TextStyle(
                  fontSize: 15,
                  color: theme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (searchQuery.isEmpty)
                ElevatedButton.icon(
                  onPressed: onSyncContacts,
                  icon: const Icon(Icons.sync_rounded),
                  label: const Text('Sync Contacts'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Empty invites state
  static Widget buildEmptyInvitesState(BuildContext context, String searchQuery,
      VoidCallback onRefreshContacts) {
    final theme = context.modernTheme;

    return Container(
      color: theme.surfaceColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.person_badge_plus,
                  size: 64,
                  color: Colors.orange.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                searchQuery.isEmpty
                    ? 'No contacts to invite'
                    : 'No matching contacts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                searchQuery.isEmpty
                    ? 'Contacts not using WemaShop will appear here'
                    : 'Try a different search term',
                style: TextStyle(
                  fontSize: 15,
                  color: theme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (searchQuery.isEmpty)
                ElevatedButton.icon(
                  onPressed: onRefreshContacts,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh Contacts'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Loading state
  static Widget buildLoadingState(BuildContext context, String message) {
    final theme = context.modernTheme;

    return Container(
      color: theme.surfaceColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: theme.primaryColor,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: theme.textSecondaryColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Error state
  static Widget buildErrorState(
      BuildContext context, String error, VoidCallback onRetry) {
    final theme = context.modernTheme;

    return Container(
      color: theme.surfaceColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: theme.textTertiaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load contacts',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(
                  color: theme.textSecondaryColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Sync status indicator
  static Widget buildSyncStatusIndicator(
    BuildContext context,
    DateTime? lastSyncTime,
    SyncStatus syncStatus,
    bool backgroundSyncAvailable,
    VoidCallback onForceSync,
  ) {
    if (lastSyncTime == null) return const SizedBox.shrink();

    final theme = context.modernTheme;
    final formatter = DateFormat('MMM d, h:mm a');
    final syncTime = formatter.format(lastSyncTime);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (syncStatus) {
      case SyncStatus.upToDate:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Up to date';
        break;
      case SyncStatus.stale:
        statusColor = Colors.orange;
        statusIcon = Icons.update_rounded;
        statusText = 'Update available';
        break;
      case SyncStatus.backgroundSyncing:
        statusColor = Colors.blue;
        statusIcon = Icons.sync_rounded;
        statusText = 'Syncing...';
        break;
      case SyncStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error_outline_rounded;
        statusText = 'Sync failed';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline_rounded;
        statusText = 'Unknown';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor!.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 3),
            spreadRadius: -3,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(statusIcon, size: 12, color: statusColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$statusText • Last synced: $syncTime',
              style: TextStyle(
                fontSize: 11,
                color: theme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (backgroundSyncAvailable) ...[
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: onForceSync,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 12,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

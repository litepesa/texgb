import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/features/status/screens/create_status_screen.dart';
import 'package:textgb/features/status/screens/status_viewer_screen.dart';
import 'package:textgb/features/status/widgets/status_circle.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:timeago/timeago.dart' as timeago;

class StatusOverviewScreen extends ConsumerWidget {
  const StatusOverviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myStatusesAsyncValue = ref.watch(myStatusesStreamProvider);
    final contactsStatusesAsyncValue = ref.watch(contactsStatusesStreamProvider);
    final hasActiveStatus = ref.watch(hasActiveStatusProvider);
    final modernTheme = context.modernTheme;

    return Scaffold(
      backgroundColor: modernTheme.surfaceColor, // Use surfaceColor to match seamless design
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(contactsStatusesStreamProvider);
          ref.refresh(myStatusesStreamProvider);
        },
        child: CustomScrollView(
          slivers: [
            // My Status section - exactly like WhatsApp
            SliverToBoxAdapter(
              child: _buildMyStatusSection(context, myStatusesAsyncValue, hasActiveStatus, modernTheme),
            ),

            // Recent updates header - exactly like WhatsApp
            SliverToBoxAdapter(
              child: _buildSectionHeader("Recent updates", modernTheme),
            ),

            // Contact Status List
            if (contactsStatusesAsyncValue.hasValue && contactsStatusesAsyncValue.value!.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final userStatus = contactsStatusesAsyncValue.value![index];
                    final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(
                        int.parse(userStatus.statuses.first.createdAt));
                    final timeAgo = timeago.format(lastUpdateTime, allowFromNow: true);
                    
                    return _buildContactStatusItem(
                      context,
                      userStatus,
                      timeAgo,
                      modernTheme,
                    );
                  },
                  childCount: contactsStatusesAsyncValue.value!.length,
                ),
              ),

            // Empty state
            if (contactsStatusesAsyncValue.hasValue && contactsStatusesAsyncValue.value!.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(modernTheme),
              ),

            // Loading state
            if (contactsStatusesAsyncValue.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),

            // Error state
            if (contactsStatusesAsyncValue.hasError)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Error loading updates",
                      style: TextStyle(color: Colors.red[400]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyStatusSection(
    BuildContext context, 
    AsyncValue<List<StatusModel>> myStatusesAsyncValue, 
    bool hasActiveStatus,
    ModernThemeExtension modernTheme,
  ) {
    return Container(
      color: modernTheme.surfaceColor,
      child: Column(
        children: [
          // My status item
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Stack(
              children: [
                StatusCircle(
                  imageUrl: hasActiveStatus 
                      ? myStatusesAsyncValue.value?.firstOrNull?.userImage ?? ''
                      : '',
                  radius: 28,
                  hasStatus: hasActiveStatus,
                  isMine: true,
                  isViewed: false,
                ),
                if (!hasActiveStatus)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: modernTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: modernTheme.surfaceColor!,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              "My status",
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              hasActiveStatus 
                  ? "Tap to view your status" 
                  : "Tap to add status update",
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
            onTap: () {
              if (hasActiveStatus && myStatusesAsyncValue.hasValue && myStatusesAsyncValue.value!.isNotEmpty) {
                Navigator.pushNamed(
                  context,
                  Constants.myStatusesScreen,
                );
              } else {
                Navigator.pushNamed(context, Constants.createStatusScreen);
              }
            },
          ),
          
          // Divider
          Divider(
            height: 1,
            thickness: 0.5,
            color: modernTheme.dividerColor,
            indent: 72,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ModernThemeExtension modernTheme) {
    return Container(
      color: modernTheme.surfaceColor,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactStatusItem(
    BuildContext context,
    UserStatusSummary userStatus,
    String timeAgo,
    ModernThemeExtension modernTheme,
  ) {
    return Container(
      color: modernTheme.surfaceColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: StatusCircle(
          imageUrl: userStatus.userImage,
          radius: 28,
          hasStatus: true,
          isViewed: !userStatus.hasUnviewed,
        ),
        title: Text(
          userStatus.userName,
          style: TextStyle(
            color: modernTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          timeAgo,
          style: TextStyle(
            color: modernTheme.textSecondaryColor,
            fontSize: 14,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StatusViewerScreen(
                userStatus: userStatus,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ModernThemeExtension modernTheme) {
    return Container(
      color: modernTheme.surfaceColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.update_rounded,
              size: 72,
              color: modernTheme.textSecondaryColor!.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              "No recent updates",
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                "Status updates from your contacts will appear here",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
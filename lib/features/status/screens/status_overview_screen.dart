import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/features/status/screens/create_status_screen.dart';
import 'package:textgb/features/status/screens/status_viewer_screen.dart';
import 'package:textgb/features/status/widgets/status_circle.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';
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
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: modernTheme.backgroundColor,
        elevation: 0,
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Updates',
          style: TextStyle(
            color: modernTheme.textColor,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Add refresh logic here
          ref.refresh(contactsStatusesStreamProvider);
          ref.refresh(myStatusesStreamProvider);
        },
        child: CustomScrollView(
          slivers: [
            // My Status section
            SliverToBoxAdapter(
              child: _buildMyStatusCard(context, myStatusesAsyncValue, hasActiveStatus, modernTheme),
            ),

            // Recent updates header
            SliverPadding(
              padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
              sliver: SliverToBoxAdapter(
                child: Text(
                  "Recent Updates",
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, Constants.createStatusScreen);
        },
        backgroundColor: modernTheme.primaryColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildMyStatusCard(
    BuildContext context, 
    AsyncValue<List<StatusModel>> myStatusesAsyncValue, 
    bool hasActiveStatus,
    ModernThemeExtension modernTheme,
  ) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      color: modernTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              StatusCircle(
                imageUrl: hasActiveStatus 
                    ? myStatusesAsyncValue.value?.firstOrNull?.userImage ?? ''
                    : '',
                radius: 36,
                hasStatus: hasActiveStatus,
                isMine: true,
                isViewed: false,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Your Status",
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasActiveStatus 
                          ? "Tap to view your update" 
                          : "Share what's on your mind",
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: modernTheme.textSecondaryColor,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactStatusItem(
    BuildContext context,
    UserStatusSummary userStatus,
    String timeAgo,
    ModernThemeExtension modernTheme,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: modernTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              StatusCircle(
                imageUrl: userStatus.userImage,
                radius: 32,
                hasStatus: true,
                isViewed: !userStatus.hasUnviewed,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userStatus.userName,
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: !userStatus.hasUnviewed 
                      ? modernTheme.backgroundColor
                      : modernTheme.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  !userStatus.hasUnviewed ? "Viewed" : "New",
                  style: TextStyle(
                    color: !userStatus.hasUnviewed 
                        ? modernTheme.textSecondaryColor
                        : modernTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ModernThemeExtension modernTheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.update_rounded,
          size: 72,
          color: modernTheme.textSecondaryColor!.withOpacity(0.3),
        ),
        const SizedBox(height: 24),
        Text(
          "No updates yet",
          style: TextStyle(
            color: modernTheme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            "Be the first to share an update with your contacts",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            // Handle create status
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: modernTheme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text("Create Update"),
        ),
      ],
    );
  }
}
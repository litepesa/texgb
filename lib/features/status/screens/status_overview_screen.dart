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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // My Status section
          _buildMyStatusSection(context, myStatusesAsyncValue, hasActiveStatus, modernTheme),
          
          // Recent updates
          if (contactsStatusesAsyncValue.hasValue && contactsStatusesAsyncValue.value!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                "Recent Updates",
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          
          // Contact Status List
          _buildContactsStatusesList(context, ref, contactsStatusesAsyncValue, modernTheme),
          
          // No updates message
          if (contactsStatusesAsyncValue.hasValue && contactsStatusesAsyncValue.value!.isEmpty)
            _buildNoUpdatesMessage(modernTheme),
          
          // Loading or error states
          if (contactsStatusesAsyncValue.isLoading)
            const Center(child: CircularProgressIndicator()),
          
          if (contactsStatusesAsyncValue.hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Error loading statuses: ${contactsStatusesAsyncValue.error}",
                  style: TextStyle(color: Colors.red[400]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMyStatusSection(
    BuildContext context, 
    AsyncValue<List<StatusModel>> myStatusesAsyncValue, 
    bool hasActiveStatus,
    ModernThemeExtension modernTheme
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ListTile(
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
            Positioned(
              bottom: 0,
              right: 0,
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(context, Constants.createStatusScreen);
                },
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
            ),
          ],
        ),
        title: Text(
          hasActiveStatus ? "My Status" : "My Status",
          style: TextStyle(
            color: modernTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          hasActiveStatus 
              ? "Tap to view your status"
              : "Tap to add status update",
          style: TextStyle(
            color: modernTheme.textSecondaryColor,
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
    );
  }

  Widget _buildContactsStatusesList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<UserStatusSummary>> contactsStatusesAsyncValue,
    ModernThemeExtension modernTheme
  ) {
    if (!contactsStatusesAsyncValue.hasValue || contactsStatusesAsyncValue.value!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: contactsStatusesAsyncValue.value!.length,
      itemBuilder: (context, index) {
        final userStatus = contactsStatusesAsyncValue.value![index];
        final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(
            int.parse(userStatus.statuses.first.createdAt));
        final timeAgo = timeago.format(lastUpdateTime, allowFromNow: true);
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ListTile(
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
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              timeAgo,
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
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
      },
    );
  }

  Widget _buildNoUpdatesMessage(ModernThemeExtension modernTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: modernTheme.textSecondaryColor!.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "No status updates from your contacts",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Be the first to share a status update!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: modernTheme.textSecondaryColor!.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
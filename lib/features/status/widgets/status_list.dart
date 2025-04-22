import 'package:flutter/material.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/screens/status_detail_screen.dart';
import 'package:textgb/features/status/widgets/status_circle.dart';
import 'package:timeago/timeago.dart' as timeago;

class StatusList extends StatelessWidget {
  final Map<String, List<StatusModel>>? userStatuses;
  final List<StatusModel>? publicStatuses;
  final bool isPrivate;
  final bool isVisible;

  const StatusList({
    Key? key,
    this.userStatuses,
    this.publicStatuses,
    required this.isPrivate,
    required this.isVisible,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    
    // Choose the appropriate data source based on privacy setting
    final sources = isPrivate 
        ? userStatuses?.entries.toList() ?? []
        : publicStatuses?.map((status) => MapEntry(status.uid, [status])).toList() ?? [];
    
    // If no statuses to show
    if (sources.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            isPrivate 
                ? 'No statuses from your contacts'
                : 'No public statuses available',
            style: TextStyle(
              color: themeExtension?.greyColor,
            ),
          ),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sources.length,
      itemBuilder: (context, index) {
        // For private statuses, we group by user
        final entry = sources[index];
        
        // Get user info from first status
        final userId = entry.key;
        final statusList = entry.value;
        final mostRecentStatus = statusList.last; // Assuming sorted by time
        
        return _buildUserStatusItem(
          context, 
          userId, 
          mostRecentStatus, 
          statusList, 
          themeExtension,
        );
      },
    );
  }
  
  Widget _buildUserStatusItem(
    BuildContext context,
    String userId,
    StatusModel latestStatus,
    List<StatusModel> allStatuses,
    WeChatThemeExtension? themeExtension,
  ) {
    // Check if any status is unviewed
    final hasUnviewed = allStatuses.any((status) => !status.isViewedBy(userId));
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      leading: StatusCircle(
        imageUrl: latestStatus.userImage,
        name: latestStatus.userName,
        hasStatus: true,
        isViewed: !hasUnviewed,
        onTap: () => _openStatusDetail(context, latestStatus, allStatuses),
      ),
      title: Text(
        latestStatus.userName,
        style: TextStyle(
          fontWeight: hasUnviewed ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        _getStatusPreview(latestStatus) + ' • ' + timeago.format(latestStatus.createdAt),
        style: TextStyle(
          color: themeExtension?.greyColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _openStatusDetail(context, latestStatus, allStatuses),
    );
  }
  
  String _getStatusPreview(StatusModel status) {
    switch (status.type) {
      case StatusType.text:
        return status.text.length > 30
            ? '${status.text.substring(0, 30)}...'
            : status.text;
      case StatusType.image:
        return 'Photo';
      case StatusType.video:
        return 'Video';
      default:
        return 'Status update';
    }
  }
  
  void _openStatusDetail(
    BuildContext context, 
    StatusModel status, 
    List<StatusModel> allStatuses,
  ) {
    if (!isVisible) return; // Don't open if tab is not visible (prevents media autoplay issues)
    
    // Find index of selected status
    final index = allStatuses.indexWhere((s) => s.statusId == status.statusId);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusDetailScreen(
          status: status,
          statuses: allStatuses,
          initialIndex: index,
        ),
      ),
    );
  }
}
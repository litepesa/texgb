import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/status/status_post_model.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';

class StatusCircle extends StatelessWidget {
  final String userId;
  final String userImage;
  final String userName;
  final List<StatusPostModel> statuses;
  final bool isViewed;
  final bool isMyStatus;
  final VoidCallback onTap;

  const StatusCircle({
    Key? key,
    required this.userId,
    required this.userImage,
    required this.userName,
    required this.statuses,
    required this.isViewed,
    this.isMyStatus = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(3),
            child: Stack(
              children: [
                // Status ring
                Container(
                  padding: EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isViewed
                        ? LinearGradient(
                            colors: [Colors.grey.shade400, Colors.grey.shade700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [Colors.green.shade400, Colors.teal.shade700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: userImage.isNotEmpty
                          ? CachedNetworkImageProvider(userImage)
                          : AssetImage(AssetsManager.userImage) as ImageProvider,
                    ),
                  ),
                ),
                
                // Add button for my status when empty
                if (isMyStatus && statuses.isEmpty)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade700,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  
                // Status segments indicator (optional for advanced implementation)
                if (statuses.length > 1)
                  _buildStatusSegments(statuses.length),
              ],
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          isMyStatus ? 'My Status' : userName,
          style: TextStyle(
            fontSize: 12,
            overflow: TextOverflow.ellipsis,
          ),
          maxLines: 1,
        ),
        if (isMyStatus && statuses.isNotEmpty)
          Text(
            'Tap to view',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
      ],
    );
  }
  
  Widget _buildStatusSegments(int count) {
    // This is a placeholder for a more advanced implementation
    // In WhatsApp, they show tiny segments around the circle representing each status
    // This is a complex UI component that requires custom painting
    return Container();
  }
}

// Extension widget for a list of status circles
class StatusCirclesList extends StatelessWidget {
  final List<StatusUserData> users;
  final String currentUserId;
  final Function(StatusUserData) onUserTap;
  final VoidCallback onMyStatusTap;

  const StatusCirclesList({
    Key? key,
    required this.users,
    required this.currentUserId,
    required this.onUserTap,
    required this.onMyStatusTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final myStatusData = users.firstWhere(
      (user) => user.userId == currentUserId,
      orElse: () => StatusUserData(
        userId: currentUserId,
        userName: 'My Status',
        userImage: '',
        statuses: [],
        hasUnviewedStatus: false,
      ),
    );
    
    final otherUsers = users.where((user) => user.userId != currentUserId).toList();
    
    return Container(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        children: [
          // My Status first
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: StatusCircle(
              userId: myStatusData.userId,
              userName: myStatusData.userName,
              userImage: myStatusData.userImage,
              statuses: myStatusData.statuses,
              isViewed: true, // My status is always considered "viewed"
              isMyStatus: true,
              onTap: onMyStatusTap,
            ),
          ),
          
          // Recent status divider
          if (otherUsers.isNotEmpty)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              width: 1,
              color: Colors.grey.withOpacity(0.3),
            ),
          
          // Other users with status
          ...otherUsers.map((user) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: StatusCircle(
              userId: user.userId,
              userName: user.userName,
              userImage: user.userImage,
              statuses: user.statuses,
              isViewed: !user.hasUnviewedStatus,
              onTap: () => onUserTap(user),
            ),
          )).toList(),
        ],
      ),
    );
  }
}

// Data class for status user info
class StatusUserData {
  final String userId;
  final String userName;
  final String userImage;
  final List<StatusPostModel> statuses;
  final bool hasUnviewedStatus;
  
  StatusUserData({
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.statuses,
    required this.hasUnviewedStatus,
  });
}
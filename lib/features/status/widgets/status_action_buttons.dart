import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/models/status_model.dart';

class StatusActionButtons extends StatelessWidget {
  final StatusModel status;
  final bool isCurrentUser;
  final bool isMuted;
  final VoidCallback? onMuteToggle;
  final VoidCallback? onDelete;

  const StatusActionButtons({
    Key? key,
    required this.status,
    required this.isCurrentUser,
    this.isMuted = false,
    this.onMuteToggle,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Profile button (always shown)
        _buildActionButton(
          icon: Icons.person,
          label: 'Profile',
          onTap: () {
            Navigator.pushNamed(
              context, 
              Constants.profileScreen,
              arguments: status.uid,
            );
          },
        ),
        
        const SizedBox(height: 20),
        
        // Volume control (only for videos)
        if (status.statusType == StatusType.video && onMuteToggle != null)
          _buildActionButton(
            icon: isMuted ? Icons.volume_off : Icons.volume_up,
            label: isMuted ? 'Unmute' : 'Mute',
            onTap: onMuteToggle,
          ),
          
        if (status.statusType == StatusType.video && onMuteToggle != null)
          const SizedBox(height: 20),
        
        // Chat button (to start a conversation)
        if (!isCurrentUser)
          _buildActionButton(
            icon: Icons.chat_bubble,
            label: 'Message',
            onTap: () {
              Navigator.pushNamed(
                context,
                Constants.chatScreen,
                arguments: {
                  Constants.contactUID: status.uid,
                  Constants.contactName: status.userName,
                  Constants.contactImage: status.userImage,
                  Constants.groupId: '',
                },
              );
            },
          ),
          
        if (!isCurrentUser)
          const SizedBox(height: 20),
        
        // Delete button (for user's own status)
        if (isCurrentUser)
          _buildActionButton(
            icon: Icons.delete,
            label: 'Delete',
            onTap: onDelete,
          ),
        
        if (isCurrentUser)
          const SizedBox(height: 20),
          
        // View count
        _buildViewsCounter(context),
      ],
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 2,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildViewsCounter(BuildContext context) {
    final viewCount = status.viewedBy.length;
    
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              viewCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Views',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 2,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
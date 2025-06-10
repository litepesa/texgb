// lib/features/moments/widgets/create_moment_widget.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';

class CreateMomentWidget extends StatelessWidget {
  final UserModel user;

  const CreateMomentWidget({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // User info and create moment input
          Row(
            children: [
              // User avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                backgroundImage: user.image.isNotEmpty
                    ? CachedNetworkImageProvider(user.image)
                    : const AssetImage(AssetsManager.userImage) as ImageProvider,
              ),
              const SizedBox(width: 12),
              
              // Create moment input
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, Constants.createMomentScreen);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'What\'s on your mind, ${user.name.split(' ').first}?',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Divider
          Divider(
            height: 1,
            color: Colors.grey[300],
          ),
          
          const SizedBox(height: 12),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.photo_library,
                  iconColor: Colors.green,
                  label: 'Photo',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Constants.createMomentScreen,
                      arguments: {'type': 'photo'},
                    );
                  },
                ),
              ),
              
              Container(
                width: 1,
                height: 24,
                color: Colors.grey[300],
              ),
              
              Expanded(
                child: _buildActionButton(
                  icon: Icons.videocam,
                  iconColor: Colors.red,
                  label: 'Video',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Constants.createMomentScreen,
                      arguments: {'type': 'video'},
                    );
                  },
                ),
              ),
              
              Container(
                width: 1,
                height: 24,
                color: Colors.grey[300],
              ),
              
              Expanded(
                child: _buildActionButton(
                  icon: Icons.location_on,
                  iconColor: Colors.blue,
                  label: 'Check In',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Constants.createMomentScreen,
                      arguments: {'type': 'location'},
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
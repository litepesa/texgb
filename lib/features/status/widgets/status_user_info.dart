import 'package:flutter/material.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:timeago/timeago.dart' as timeago;

class StatusUserInfo extends StatelessWidget {
  final String userName;
  final String userImage;
  final DateTime createdAt;
  final VoidCallback? onTap;

  const StatusUserInfo({
    Key? key,
    required this.userName,
    required this.userImage,
    required this.createdAt,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          // User avatar
          userImageWidget(
            imageUrl: userImage,
            radius: 18,
            onTap: onTap ?? () {},
          ),
          
          const SizedBox(width: 10),
          
          // User name and time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                ),
                Text(
                  timeago.format(createdAt),
                  style: const TextStyle(
                    color: Colors.white70,
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
            ),
          ),
          
          // Expiration indicator
          _buildExpirationIndicator(context),
        ],
      ),
    );
  }
  
  Widget _buildExpirationIndicator(BuildContext context) {
    // Calculate remaining time
    final now = DateTime.now();
    final expiresAt = createdAt.add(const Duration(hours: 72));
    final remainingDuration = expiresAt.difference(now);
    
    // Remaining hours
    final remainingHours = remainingDuration.inHours;
    
    // Calculate progress (0.0 to 1.0)
    final totalDuration = const Duration(hours: 72);
    final elapsed = totalDuration - remainingDuration;
    final progress = elapsed.inMilliseconds / totalDuration.inMilliseconds;
    
    return Row(
      children: [
        // Hours remaining text
        Text(
          '${remainingHours}h left',
          style: const TextStyle(
            color: Colors.white70,
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
        
        const SizedBox(width: 8),
        
        // Circular progress indicator
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 2,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ],
    );
  }
}
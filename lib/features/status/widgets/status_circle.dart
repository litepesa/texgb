import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';

class StatusCircle extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final bool hasStatus;
  final bool isViewed;
  final bool isMine;
  final VoidCallback? onTap;

  const StatusCircle({
    Key? key,
    required this.imageUrl,
    required this.radius,
    this.hasStatus = false,
    this.isViewed = false,
    this.isMine = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Choose border color based on status
    Color borderColor = Theme.of(context).primaryColor;
    
    if (isViewed) {
      borderColor = Colors.grey.shade400;  // Viewed status - gray border
    } else if (isMine && !hasStatus) {
      borderColor = Colors.transparent;  // My circle with no status - no border
    }
    
    // Determine the border style
    Border? border = hasStatus 
        ? Border.all(
            color: borderColor,
            width: 2.5,
          ) 
        : null;
    
    // Create the profile image
    Widget profileImage = CircleAvatar(
      radius: radius - (hasStatus ? 3 : 0), // Adjust for border width
      backgroundColor: Colors.grey.shade300,
      backgroundImage: imageUrl.isNotEmpty
          ? CachedNetworkImageProvider(imageUrl) as ImageProvider
          : const AssetImage(AssetsManager.userImage),
      child: imageUrl.isEmpty
          ? Icon(
              Icons.person,
              size: radius * 0.8,
              color: Colors.grey.shade700,
            )
          : null,
    );
    
    // If need to add animation or segmented border for multiple statuses
    if (hasStatus) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: border,
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: profileImage,
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: onTap,
        child: profileImage,
      );
    }
  }
}
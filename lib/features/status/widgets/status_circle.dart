import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/shared/theme/wechat_theme_extension.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';

class StatusCircle extends StatelessWidget {
  const StatusCircle({
    Key? key,
    required this.imageUrl,
    required this.name,
    this.radius = 30,
    this.hasStatus = false,
    this.isViewed = false,
    this.isMyStatus = false,
    required this.onTap,
  }) : super(key: key);

  final String imageUrl;
  final String name;
  final double radius;
  final bool hasStatus;
  final bool isViewed;
  final bool isMyStatus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final statusCircleColor = themeExtension?.accentColor ?? const Color(0xFF07C160);
    final greyColor = themeExtension?.greyColor ?? Colors.grey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              // Base circle with border if hasStatus
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: hasStatus
                      ? Border.all(
                          color: isViewed 
                              ? greyColor.withOpacity(0.5) 
                              : statusCircleColor,
                          width: 2.5,
                        )
                      : null,
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: radius - (hasStatus ? 3 : 0),
                    backgroundColor: Colors.grey[300],
                    backgroundImage: imageUrl.isNotEmpty
                        ? CachedNetworkImageProvider(imageUrl)
                        : const AssetImage(AssetsManager.userImage) as ImageProvider,
                  ),
                ),
              ),
              
              // Add button for "My Status" when it's the user's status
              if (isMyStatus)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: statusCircleColor,
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          // Optional name below the circle
          if (name.isNotEmpty && !isMyStatus)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: themeExtension?.textColor ?? Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
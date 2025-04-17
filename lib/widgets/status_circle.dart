import 'package:flutter/material.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/utilities/global_methods.dart';

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
    final statusCircleColor = themeExtension?.statusCircleColor ?? const Color(0xFF07C160);
    final accentColor = themeExtension?.accentColor ?? const Color(0xFF07C160);
    final greyColor = themeExtension?.greyColor ?? Colors.grey;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius + 3),
          child: Stack(
            children: [
              if (hasStatus && !isMyStatus)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isViewed ? greyColor.withOpacity(0.5) : statusCircleColor,
                      width: 2.5,
                    ),
                  ),
                  child: _buildUserImage(),
                )
              else if (isMyStatus)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: statusCircleColor,
                      width: 2.5,
                    ),
                  ),
                  child: _buildUserImage(),
                )
              else
                _buildUserImage(),

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
                      backgroundColor: accentColor,
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
        ),
        if (isMyStatus) ...[
          const SizedBox(height: 5),
          SizedBox(
            width: radius * 2,
            child: Text(
              "My Status",
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUserImage() {
    return CircleAvatar(
      radius: radius,
      backgroundImage: imageUrl.isNotEmpty
          ? NetworkImage(imageUrl) as ImageProvider
          : const AssetImage("assets/images/user_icon.png"),
      backgroundColor: Colors.grey[300],
    );
  }
}

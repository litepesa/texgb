import 'package:flutter/material.dart';
import 'package:textgb/common/extension/custom_theme_extension.dart';
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Stack(
            children: [
              // Border for status indicators
              if (hasStatus && !isMyStatus)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isViewed
                          ? Colors.grey.withOpacity(0.5)
                          : context.theme.circleImageColor!,
                      width: 3,
                    ),
                  ),
                  child: userImageWidget(
                    imageUrl: imageUrl,
                    radius: radius,
                    onTap: () {},
                  ),
                )
              // Add status circle 
              else if (isMyStatus)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.theme.circleImageColor!,
                      width: 3,
                    ),
                  ),
                  child: userImageWidget(
                    imageUrl: imageUrl,
                    radius: radius,
                    onTap: () {},
                  ),
                )
              // No border for users without status
              else
                userImageWidget(
                  imageUrl: imageUrl,
                  radius: radius,
                  onTap: () {},
                ),

              // Add button for "My Status"
              if (isMyStatus)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        // Status owner name
        SizedBox(
          width: radius * 2,
          child: Text(
            isMyStatus ? "My Status" : name,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isMyStatus ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
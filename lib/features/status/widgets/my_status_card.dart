import 'package:flutter/material.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/screens/my_status_screen.dart';
import 'package:textgb/features/status/screens/status_detail_screen.dart';
import 'package:textgb/features/status/widgets/status_circle.dart';
import 'package:textgb/models/user_model.dart';

class MyStatusCard extends StatelessWidget {
  final UserModel currentUser;
  final List<StatusModel> statuses;
  final bool isPrivate;

  const MyStatusCard({
    Key? key,
    required this.currentUser,
    required this.statuses,
    required this.isPrivate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    
    return Container(
      decoration: BoxDecoration(
        color: themeExtension?.receiverBubbleColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToMyStatusScreen(context),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Status circle
                StatusCircle(
                  imageUrl: currentUser.image,
                  name: currentUser.name,
                  hasStatus: statuses.isNotEmpty,
                  isMyStatus: true,
                  onTap: statuses.isEmpty
                      ? () => _navigateToCreateStatus(context)
                      : () => _navigateToMyStatusDetail(context),
                ),
                const SizedBox(width: 16),
                
                // Status info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statuses.isEmpty
                            ? 'Tap to add status update'
                            : 'Tap to view your ${isPrivate ? 'private' : 'public'} status updates (${statuses.length})',
                        style: TextStyle(
                          fontSize: 14,
                          color: themeExtension?.greyColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status count badge
                if (statuses.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: themeExtension?.accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statuses.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                
                // Add button
                IconButton(
                  icon: Icon(
                    Icons.add_circle,
                    color: themeExtension?.accentColor,
                    size: 28,
                  ),
                  onPressed: () => _navigateToCreateStatus(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _navigateToMyStatusScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyStatusScreen(
          isPrivate: isPrivate,
        ),
      ),
    );
  }
  
  void _navigateToCreateStatus(BuildContext context) {
    Navigator.pushNamed(context, Constants.createStatusScreen);
  }
  
  void _navigateToMyStatusDetail(BuildContext context) {
    if (statuses.isEmpty) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusDetailScreen(
          status: statuses.first,
          statuses: statuses,
          initialIndex: 0,
        ),
      ),
    );
  }
}
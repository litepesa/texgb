import 'package:flutter/material.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/constants.dart';

class NoStatusPlaceholder extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const NoStatusPlaceholder({
    Key? key,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? const Color(0xFF07C160);
    
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        // Using ListView for RefreshIndicator to work
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Icon(
                    Icons.video_library_outlined,
                    size: 80,
                    color: Colors.grey.withOpacity(0.7),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  const Text(
                    'No statuses yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Be the first to share a status with your contacts. Statuses disappear after 72 hours.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Create status button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, Constants.createStatusScreen);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Status'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Pull to refresh hint
                  Text(
                    'Pull down to refresh',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
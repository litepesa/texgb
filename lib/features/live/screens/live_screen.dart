import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key});

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: modernTheme.surfaceColor, // Use surfaceColor for seamless look
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              
              // Live icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: modernTheme.primaryColor?.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.radio_button_checked,
                  size: 60,
                  color: modernTheme.primaryColor,
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Title
              Text(
                'Live Streams',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Description
              Text(
                'Watch live streams from your friends and discover new content in real-time.',
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Live streams list placeholder
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: modernTheme.backgroundColor, // Use backgroundColor for contrast
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: modernTheme.dividerColor?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.live_tv_outlined,
                        size: 48,
                        color: modernTheme.textSecondaryColor?.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No live streams available',
                        style: TextStyle(
                          color: modernTheme.textSecondaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check back later for live content',
                        style: TextStyle(
                          color: modernTheme.textSecondaryColor?.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement refresh functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Refreshing live streams...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: modernTheme.backgroundColor, // Use backgroundColor for contrast
                        foregroundColor: modernTheme.textColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: modernTheme.dividerColor?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement explore functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Explore feature coming soon...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.explore),
                      label: const Text('Explore'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: modernTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
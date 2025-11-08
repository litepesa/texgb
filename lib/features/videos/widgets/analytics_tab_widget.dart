// lib/features/videos/widgets/analytics_tab_widget.dart
import 'package:flutter/material.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class AnalyticsTabWidget extends StatelessWidget {
  final VideoModel video;

  const AnalyticsTabWidget({
    super.key,
    required this.video,
  });

  String _formatViewCount(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final engagementRate = video.views > 0
        ? ((video.likes + video.comments + video.shares) / video.views * 100)
        : 0.0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Overview
          Text(
            'Performance Overview',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Analytics Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildAnalyticsCard(
                'Total Views',
                _formatViewCount(video.views),
                Icons.visibility,
                video.isFeatured ? '⭐ Featured' : '↗ Growing',
                Colors.green,
                modernTheme,
              ),
              _buildAnalyticsCard(
                'Likes',
                _formatViewCount(video.likes),
                Icons.favorite,
                '${(video.likes / (video.views > 0 ? video.views : 1) * 100).toStringAsFixed(1)}% rate',
                Colors.red,
                modernTheme,
              ),
              _buildAnalyticsCard(
                'Comments',
                _formatViewCount(video.comments),
                Icons.comment,
                '${(video.comments / (video.views > 0 ? video.views : 1) * 100).toStringAsFixed(1)}% rate',
                Colors.blue,
                modernTheme,
              ),
              _buildAnalyticsCard(
                'Engagement',
                '${engagementRate.toStringAsFixed(1)}%',
                Icons.trending_up,
                engagementRate > 10 ? 'Excellent' : 'Good',
                Colors.orange,
                modernTheme,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Post Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: video.isActive
                    ? Colors.green.withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  video.isActive ? Icons.check_circle : Icons.pause_circle,
                  color: video.isActive ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Post Status',
                        style: TextStyle(
                          color: modernTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        video.isActive ? 'Active' : 'Paused',
                        style: TextStyle(
                          color: modernTheme.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (video.isFeatured)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Featured',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Performance Graph Placeholder
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart,
                    color: modernTheme.primaryColor,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Performance graph coming soon',
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 14,
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

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    String trend,
    Color iconColor,
    ModernThemeExtension modernTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            trend,
            style: TextStyle(
              color: trend.contains('↗') || trend.contains('Excellent') || trend.contains('Featured')
                  ? Colors.green
                  : modernTheme.textSecondaryColor,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
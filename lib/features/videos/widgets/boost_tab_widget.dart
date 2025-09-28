// lib/features/videos/widgets/boost_tab_widget.dart
import 'package:flutter/material.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class BoostTabWidget extends StatelessWidget {
  final AnimationController rocketAnimationController;
  final Animation<double> rocketAnimation;
  final VoidCallback onBoostPost;

  const BoostTabWidget({
    super.key,
    required this.rocketAnimationController,
    required this.rocketAnimation,
    required this.onBoostPost,
  });

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Boost Header
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  modernTheme.primaryColor!,
                  modernTheme.primaryColor!.withOpacity(0.7),
                  modernTheme.primaryColor!.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: modernTheme.primaryColor!.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: rocketAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, -rocketAnimation.value * 30),
                      child: Transform.rotate(
                        angle: rocketAnimation.value * 0.8,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.rocket_launch,
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  '🚀 BOOST POST',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Increase visibility and reach more audience',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Up to 10x more views',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Special Offer Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade400,
                  Colors.orange.shade600,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_offer,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LIMITED TIME OFFER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'Get 20% off on all boost packages',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Choose Your Boost Package',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Boost Options with enhanced styling
          _buildBoostOption(
            'Quick Boost',
            '24 hours',
            'KES 599',
            'Get 2x more views for 24 hours',
            Icons.flash_on,
            Colors.orange,
            modernTheme,
            isPopular: false,
          ),
          _buildBoostOption(
            'Power Boost',
            '7 days',
            'KES 1,999',
            'Get 5x more views for a week',
            Icons.rocket_launch,
            Colors.red,
            modernTheme,
            isPopular: true,
          ),
          _buildBoostOption(
            'Mega Boost',
            '30 days',
            'KES 4,999',
            'Get 10x more views for a month',
            Icons.star,
            Colors.purple,
            modernTheme,
            isPopular: false,
          ),
          
          const SizedBox(height: 24),
          
          // Benefits Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: modernTheme.primaryColor!.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: modernTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Why Boost Your Post?',
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildBenefitItem(
                  'Reach more viewers instantly',
                  Icons.visibility,
                  modernTheme,
                ),
                _buildBenefitItem(
                  'Get featured on explore page',
                  Icons.explore,
                  modernTheme,
                ),
                _buildBenefitItem(
                  'Increase engagement & followers',
                  Icons.people,
                  modernTheme,
                ),
                _buildBenefitItem(
                  'Priority in search results',
                  Icons.search,
                  modernTheme,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Current Boost Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: modernTheme.primaryColor!.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: modernTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Current Status',
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'No active boost',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start boosting now to maximize your post\'s potential!',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(
    String text,
    IconData icon,
    ModernThemeExtension modernTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: modernTheme.primaryColor!.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: modernTheme.primaryColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoostOption(
    String title,
    String duration,
    String price,
    String description,
    IconData icon,
    Color color,
    ModernThemeExtension modernTheme,
    {bool isPopular = false}
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPopular ? color.withOpacity(0.5) : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isPopular 
                      ? color.withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: isPopular ? 15 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    
                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and Price
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    color: modernTheme.textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Text(
                                price,
                                style: TextStyle(
                                  color: modernTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Description
                          Text(
                            description,
                            style: TextStyle(
                              color: modernTheme.textColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Duration
                          Text(
                            'Duration: $duration',
                            style: TextStyle(
                              color: modernTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Select button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onBoostPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Select'),
                  ),
                ),
              ],
            ),
          ),
          
          // Popular badge
          if (isPopular)
            Positioned(
              top: -5,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'MOST POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
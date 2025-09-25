// lib/features/discover/screens/discover_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/videos/screens/videos_feed_screen.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper method to get safe theme with fallback
  ModernThemeExtension _getSafeTheme(BuildContext context) {
    return Theme.of(context).extension<ModernThemeExtension>() ?? 
        ModernThemeExtension(
          primaryColor: const Color(0xFFFE2C55),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceColor: Theme.of(context).cardColor,
          textColor: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
          textSecondaryColor: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey[600],
          dividerColor: Theme.of(context).dividerColor,
          textTertiaryColor: Colors.grey[400],
          surfaceVariantColor: Colors.grey[100],
        );
  }

  void _navigateToVideosFeed() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VideosFeedScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getSafeTheme(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: theme.surfaceColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      // Enhanced Custom App Bar (now part of scrollable content)
                      Container(
                        margin: const EdgeInsets.only(bottom: 32),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (theme.dividerColor ?? Colors.grey[300]!).withOpacity(0.15),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                              spreadRadius: -4,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Discover',
                                    style: TextStyle(
                                      color: theme.textColor ?? Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  Text(
                                    'Amazing Airbnb experiences await',
                                    style: TextStyle(
                                      color: theme.textSecondaryColor ?? Colors.grey[600],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Main Content Area
                      _buildMainContent(theme, screenHeight, screenWidth),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(ModernThemeExtension theme, double screenHeight, double screenWidth) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Hero Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.1),
                Colors.transparent,
                (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (theme.dividerColor ?? Colors.grey[300]!).withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Main Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.2),
                      (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.home_work_rounded,
                  size: 60,
                  color: theme.primaryColor ?? const Color(0xFFFE2C55),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Explore Unique Stays',
                style: TextStyle(
                  color: theme.textColor ?? Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'Discover amazing Airbnb properties through\nshort video experiences',
                style: TextStyle(
                  color: theme.textSecondaryColor ?? Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Feature Cards
              Row(
                children: [
                  Expanded(
                    child: _buildFeatureCard(
                      icon: Icons.video_library_rounded,
                      title: 'Video Tours',
                      description: 'Immersive property showcases',
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFeatureCard(
                      icon: Icons.location_on_rounded,
                      title: 'Prime Locations',
                      description: 'Handpicked destinations',
                      theme: theme,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildFeatureCard(
                      icon: Icons.verified_rounded,
                      title: 'Verified Hosts',
                      description: 'Trusted accommodations',
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFeatureCard(
                      icon: Icons.book_online_rounded,
                      title: 'Direct Booking',
                      description: 'Book instantly from videos',
                      theme: theme,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 48),
        
        // Call to Action Button
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: _navigateToVideosFeed,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    theme.primaryColor ?? const Color(0xFFFE2C55),
                    (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Start Exploring',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Additional Info
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: (theme.surfaceVariantColor ?? Colors.grey[100]!).withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (theme.dividerColor ?? Colors.grey[300]!).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Swipe through video feeds',
                      style: TextStyle(
                        color: theme.textColor ?? Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Each video showcases a unique Airbnb property you can book directly',
                      style: TextStyle(
                        color: theme.textSecondaryColor ?? Colors.grey[600],
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required ModernThemeExtension theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (theme.dividerColor ?? Colors.grey[300]!).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (theme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: theme.primaryColor ?? const Color(0xFFFE2C55),
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: theme.textColor ?? Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: theme.textSecondaryColor ?? Colors.grey[600],
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
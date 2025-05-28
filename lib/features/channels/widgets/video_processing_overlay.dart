// lib/features/channels/widgets/video_processing_overlay.dart
import 'package:flutter/material.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/services/video_processing_service.dart';

class VideoProcessingOverlay extends StatefulWidget {
  final VideoProcessingService service;
  final VoidCallback? onCancel;

  const VideoProcessingOverlay({
    Key? key,
    required this.service,
    this.onCancel,
  }) : super(key: key);

  @override
  State<VideoProcessingOverlay> createState() => _VideoProcessingOverlayState();
}

class _VideoProcessingOverlayState extends State<VideoProcessingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.14159,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
    
    _animationController.repeat();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final size = MediaQuery.of(context).size;
    
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          width: size.width * 0.85,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: modernTheme.backgroundColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: modernTheme.primaryColor!.withOpacity(0.3),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotateAnimation.value,
                    child: Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              modernTheme.primaryColor!,
                              modernTheme.primaryColor!.withOpacity(0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_fix_high,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Processing Video',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Current operation
              AnimatedBuilder(
                animation: widget.service,
                builder: (context, child) {
                  return Text(
                    widget.service.currentOperation,
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Progress bar
              AnimatedBuilder(
                animation: widget.service,
                builder: (context, child) {
                  return Column(
                    children: [
                      // Progress percentage
                      Text(
                        '${(widget.service.progress * 100).toInt()}%',
                        style: TextStyle(
                          color: modernTheme.primaryColor,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Progress bar
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: modernTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Stack(
                            children: [
                              // Progress fill
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: (size.width * 0.85 - 64) * widget.service.progress,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      modernTheme.primaryColor!,
                                      modernTheme.primaryColor!.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                              ),
                              
                              // Animated shine effect
                              if (widget.service.progress > 0 && widget.service.progress < 1)
                                Positioned.fill(
                                  child: AnimatedBuilder(
                                    animation: _animationController,
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: Offset(
                                          (size.width * 0.85 - 64) * _animationController.value - 50,
                                          0,
                                        ),
                                        child: Container(
                                          width: 50,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.transparent,
                                                Colors.white.withOpacity(0.3),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Processing benefits
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: modernTheme.primaryColor!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: modernTheme.primaryColor!.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    _buildBenefitRow(
                      Icons.compress,
                      'Reducing file size by up to 80%',
                      modernTheme,
                    ),
                    const SizedBox(height: 8),
                    _buildBenefitRow(
                      Icons.high_quality,
                      'Maintaining video quality',
                      modernTheme,
                    ),
                    const SizedBox(height: 8),
                    _buildBenefitRow(
                      Icons.speed,
                      'Optimizing for fast uploads',
                      modernTheme,
                    ),
                  ],
                ),
              ),
              
              // Cancel button
              if (widget.onCancel != null) ...[
                const SizedBox(height: 24),
                TextButton(
                  onPressed: widget.onCancel,
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text, ModernThemeExtension modernTheme) {
    return Row(
      children: [
        Icon(
          icon,
          color: modernTheme.primaryColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
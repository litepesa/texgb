// lib/features/users/screens/live_users_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'dart:math' as math;

class LiveUsersScreen extends ConsumerStatefulWidget {
  const LiveUsersScreen({super.key});

  @override
  ConsumerState<LiveUsersScreen> createState() => _LiveUsersScreenState();
}

class _LiveUsersScreenState extends ConsumerState<LiveUsersScreen>
    with TickerProviderStateMixin {
  bool _isInitialized = false;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _shimmerController;
  late AnimationController _orbitController;
  late AnimationController _floatController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();
    
    _orbitController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _shimmerController.dispose();
    _orbitController.dispose();
    _floatController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _initializeScreen() {
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: theme.surfaceColor,
      body: !_isInitialized 
        ? _buildLoadingView(theme)
        : _buildAntAIScreen(theme),
    );
  }

  Widget _buildLoadingView(ModernThemeExtension theme) {
    return Container(
      color: theme.surfaceColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 120 + (40 * _pulseController.value),
                      height: 120 + (40 * _pulseController.value),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            theme.primaryColor!.withOpacity(0.4 * (1 - _pulseController.value)),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.primaryColor!,
                        theme.primaryColor!.withOpacity(0.7),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor!.withOpacity(0.5),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.ant,
                    color: Colors.white,
                    size: 45,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  theme.primaryColor!,
                  theme.primaryColor!.withOpacity(0.6),
                ],
              ).createShader(bounds),
              child: Text(
                'Initializing AI',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAntAIScreen(ModernThemeExtension theme) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  theme.primaryColor!.withOpacity(0.25),
                  theme.primaryColor!.withOpacity(0.12),
                  theme.surfaceColor!.withOpacity(0.95),
                  theme.surfaceColor!,
                ],
                stops: const [0.0, 0.25, 0.6, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Animated particles background
                _buildAnimatedParticles(theme),
                
                // Main content
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 120),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Main futuristic AI icon
                      _buildFuturisticAIIcon(theme),
                      
                      const SizedBox(height: 56),
                      
                      // Title with glitch effect
                      _buildGlitchTitle(theme),
                      
                      const SizedBox(height: 24),
                      
                      // Status badge
                      _buildStatusBadge(theme),
                      
                      const SizedBox(height: 16),
                      
                      // Description
                      _buildDescription(theme),
                      
                      const SizedBox(height: 56),
                      
                      // Feature showcase
                      _buildFeatureShowcase(theme),
                      
                      const SizedBox(height: 40),
                      
                      // Coming soon indicator
                      _buildComingSoonIndicator(theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedParticles(ModernThemeExtension theme) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Stack(
          children: List.generate(20, (index) {
            final angle = (index / 20) * 2 * math.pi;
            final distance = 100 + (index * 15);
            final x = MediaQuery.of(context).size.width / 2 + 
                     math.cos(angle + _particleController.value * 2 * math.pi) * distance;
            final y = MediaQuery.of(context).size.height / 2 + 
                     math.sin(angle + _particleController.value * 2 * math.pi) * distance;
            
            return Positioned(
              left: x,
              top: y,
              child: Container(
                width: 3 + (index % 3),
                height: 3 + (index % 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primaryColor!.withOpacity(0.3),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor!.withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildFuturisticAIIcon(ModernThemeExtension theme) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _orbitController, _floatController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -15 * _floatController.value),
          child: SizedBox(
            width: 280,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer rotating ring
                Transform.rotate(
                  angle: _rotationController.value * 2 * math.pi,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 2,
                        color: theme.primaryColor!.withOpacity(0.3),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Orbiting nodes
                        for (int i = 0; i < 4; i++)
                          Transform.rotate(
                            angle: (i * math.pi / 2) + (_orbitController.value * 2 * math.pi),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.primaryColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primaryColor!,
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Middle ring
                Transform.rotate(
                  angle: -_rotationController.value * 1.5 * math.pi,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          theme.primaryColor!.withOpacity(0.5),
                          Colors.transparent,
                          theme.primaryColor!.withOpacity(0.3),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.3, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                
                // Pulsing inner glow
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 150 + (25 * _pulseController.value),
                      height: 150 + (25 * _pulseController.value),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            theme.primaryColor!.withOpacity(0.4 * (1 - _pulseController.value)),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                // Central AI core
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.primaryColor!,
                        theme.primaryColor!.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor!.withOpacity(0.6),
                        blurRadius: 50,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Neural network pattern
                      CustomPaint(
                        size: const Size(130, 130),
                        painter: NeuralNetworkPainter(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      // Ant icon
                      const Icon(
                        CupertinoIcons.ant,
                        color: Colors.white,
                        size: 60,
                      ),
                    ],
                  ),
                ),
                
                // Corner accents
                for (int i = 0; i < 4; i++)
                  Transform.rotate(
                    angle: (i * math.pi / 2),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Transform.translate(
                        offset: const Offset(0, -140),
                        child: Container(
                          width: 3,
                          height: 20,
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: theme.primaryColor!,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlitchTitle(ModernThemeExtension theme) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor!,
              Colors.white,
              theme.primaryColor!,
            ],
            stops: [
              _shimmerController.value - 0.3,
              _shimmerController.value,
              _shimmerController.value + 0.3,
            ],
          ).createShader(bounds),
          child: const Text(
            'ANT AI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(ModernThemeExtension theme) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: theme.primaryColor!.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor!.withOpacity(0.3 * _pulseController.value),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor!,
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'GENERATIVE SOCIAL ENGINE',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDescription(ModernThemeExtension theme) {
    return Column(
      children: [
        Text(
          'Where AI Meets Viral Content Creation',
          style: TextStyle(
            color: theme.textColor!.withOpacity(0.9),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.4,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Available for verified selected users only',
          style: TextStyle(
            color: theme.textSecondaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.5,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.surfaceColor!.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.sparkles,
                color: theme.textSecondaryColor,
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                'Next-Gen Creator Tools',
                style: TextStyle(
                  color: theme.textSecondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureShowcase(ModernThemeExtension theme) {
    return Column(
      children: [
        _buildFeatureItem(
          icon: CupertinoIcons.film_fill,
          title: 'AI Video Generator',
          description: 'Text-to-video magic. Describe it, AI creates it in HD',
          theme: theme,
          delay: 0,
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          icon: CupertinoIcons.scissors,
          title: 'Smart Edit Assistant',
          description: 'Auto-cuts, transitions, effects - viral-ready in seconds',
          theme: theme,
          delay: 200,
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          icon: CupertinoIcons.wand_stars_inverse,
          title: 'Remix & Transform',
          description: 'AI reimagines any video in different styles & scenarios',
          theme: theme,
          delay: 400,
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          icon: CupertinoIcons.chat_bubble_text_fill,
          title: 'Conversational Creator',
          description: 'Chat with AI to refine your content until it\'s perfect',
          theme: theme,
          delay: 600,
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          icon: CupertinoIcons.flame_fill,
          title: 'Viral Optimization',
          description: 'AI analyzes trends and optimizes for maximum engagement',
          theme: theme,
          delay: 800,
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required ModernThemeExtension theme,
    required int delay,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surfaceColor!.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.primaryColor!.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor!.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primaryColor!,
                  theme.primaryColor!.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor!.withOpacity(0.4),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: theme.textSecondaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonIndicator(ModernThemeExtension theme) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.primaryColor!.withOpacity(0.2),
                theme.primaryColor!.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.primaryColor!.withOpacity(0.4),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.rocket_fill,
                color: theme.primaryColor,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                'THE FUTURE OF CONTENT IS HERE',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Custom painter for neural network pattern
class NeuralNetworkPainter extends CustomPainter {
  final Color color;

  NeuralNetworkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // Draw interconnected nodes
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3);
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      
      // Draw line from center
      canvas.drawLine(center, point, paint);
      
      // Draw node
      canvas.drawCircle(point, 3, Paint()..color = color..style = PaintingStyle.fill);
    }
    
    // Draw center node
    canvas.drawCircle(center, 4, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
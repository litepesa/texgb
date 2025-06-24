// lib/features/moments/widgets/my_moments_header.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/providers/moments_provider.dart';
import 'package:textgb/features/moments/screens/create_moment_screen.dart';
import 'package:textgb/features/moments/screens/my_moments_screen.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class MyMomentHeader extends ConsumerStatefulWidget {
  final UserModel user;

  const MyMomentHeader({super.key, required this.user});

  @override
  ConsumerState<MyMomentHeader> createState() => _MyMomentHeaderState();
}

class _MyMomentHeaderState extends ConsumerState<MyMomentHeader>
    with SingleTickerProviderStateMixin {
  List<MomentModel> _myMoments = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Premium color palette - Sophisticated blues and greens
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF7F8FC);
  static const Color softGray = Color(0xFFEFF1F6);
  static const Color textPrimary = Color(0xFF1A1D29);
  static const Color textSecondary = Color(0xFF5A6175);
  static const Color textTertiary = Color(0xFF9BA3B4);
  static const Color premiumBlue = Color(0xFF2563EB);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color premiumGreen = Color(0xFF059669);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color shadowColor = Color(0x08000000);

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _loadMyMoments();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMyMoments() async {
    try {
      final moments = await ref.read(momentsNotifierProvider.notifier)
          .getUserMoments(widget.user.uid);
      
      if (mounted) {
        setState(() {
          _myMoments = moments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              color: primaryWhite,
              child: Column(
                children: [
                  _buildCoverSection(),
                  _buildStatsSection(),
                  _buildDivider(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoverSection() {
    final latestMoment = _myMoments.isNotEmpty ? _myMoments.first : null;
    final hasMedia = latestMoment?.hasMedia ?? false;
    final mediaUrl = hasMedia ? latestMoment!.mediaUrls.first : '';

    return Container(
      height: 240,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            softGray,
            softGray.withOpacity(0.5),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern or image
          if (hasMedia && latestMoment!.hasImages)
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(mediaUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    primaryWhite.withOpacity(0.85),
                    BlendMode.overlay,
                  ),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    premiumBlue.withOpacity(0.06),
                    premiumGreen.withOpacity(0.06),
                  ],
                ),
              ),
              child: CustomPaint(
                painter: _ModernPatternPainter(),
                size: Size.infinite,
              ),
            ),
          
          // Content overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.1),
                ],
              ),
            ),
          ),
          
          // Profile content
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Row(
              children: [
                _buildProfileImage(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_isLoading)
                        Container(
                          width: 20,
                          height: 20,
                          padding: const EdgeInsets.all(2),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: textSecondary,
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryWhite,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: shadowColor,
                                offset: const Offset(0, 2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            _myMoments.isEmpty 
                                ? 'Share your first moment'
                                : '${_myMoments.length} moment${_myMoments.length != 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _buildActionButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: () => _navigateToMyMoments(),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: primaryWhite,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: userImageWidget(
          imageUrl: widget.user.image,
          radius: 32,
          onTap: () => _navigateToMyMoments(),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _navigateToCreateMoment();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [premiumBlue, accentBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: premiumBlue.withOpacity(0.4),
              offset: const Offset(0, 4),
              blurRadius: 16,
            ),
            BoxShadow(
              color: premiumBlue.withOpacity(0.1),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              color: primaryWhite,
              size: 18,
            ),
            SizedBox(width: 6),
            Text(
              'Share',
              style: TextStyle(
                color: primaryWhite,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          Expanded(
            child:             _buildStatsItem(
              'Moments',
              _myMoments.length.toString(),
              Icons.photo_camera_rounded,
              premiumBlue,
              () => _navigateToMyMoments(),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: softGray,
          ),
          Expanded(
            child:             _buildStatsItem(
              'Views',
              _getTotalViews().toString(),
              Icons.visibility_rounded,
              premiumGreen,
              () => _navigateToMyMoments(),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: softGray,
          ),
          Expanded(
            child: _buildStatsItem(
              'Likes',
              _getTotalLikes().toString(),
              Icons.favorite_rounded,
              const Color(0xFFEF4444),
              () => _navigateToMyMoments(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsItem(
    String label,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 8,
      color: backgroundGray,
    );
  }

  int _getTotalViews() {
    return _myMoments.fold(0, (total, moment) => total + moment.viewsCount);
  }

  int _getTotalLikes() {
    return _myMoments.fold(0, (total, moment) => total + moment.likesCount);
  }

  void _navigateToCreateMoment() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const CreateMomentScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ).then((_) => _loadMyMoments());
  }

  void _navigateToMyMoments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyMomentsScreen(user: widget.user),
      ),
    );
  }
}

// Modern pattern painter for background
class _ModernPatternPainter extends CustomPainter {
  get premiumGreen => null;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4F46E5).withOpacity(0.03)
      ..style = PaintingStyle.fill;

    // Draw modern geometric patterns
    final patterns = [
      _Pattern(0.15, 0.25, 25, PatternType.circle),
      _Pattern(0.75, 0.15, 30, PatternType.circle),
      _Pattern(0.25, 0.65, 20, PatternType.circle),
      _Pattern(0.85, 0.75, 35, PatternType.circle),
      _Pattern(0.45, 0.45, 15, PatternType.circle),
    ];
    
    for (final pattern in patterns) {
      final x = size.width * pattern.x;
      final y = size.height * pattern.y;
      
      switch (pattern.type) {
        case PatternType.circle:
          canvas.drawCircle(
            Offset(x, y),
            pattern.size,
            paint,
          );
          break;
        case PatternType.square:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(x, y),
                width: pattern.size * 2,
                height: pattern.size * 2,
              ),
              Radius.circular(pattern.size * 0.3),
            ),
            paint,
          );
          break;
      }
    }

    // Add some subtle lines
    final linePaint = Paint()
      ..color = premiumGreen.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.1,
      size.width,
      size.height * 0.4,
    );
    canvas.drawPath(path, linePaint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.7);
    path2.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.9,
      size.width,
      size.height * 0.6,
    );
    canvas.drawPath(path2, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Pattern {
  final double x;
  final double y;
  final double size;
  final PatternType type;

  _Pattern(this.x, this.y, this.size, this.type);
}

enum PatternType { circle, square }
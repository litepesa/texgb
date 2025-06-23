// lib/features/moments/widgets/my_moment_header.dart
import 'package:flutter/material.dart';
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

class _MyMomentHeaderState extends ConsumerState<MyMomentHeader> {
  List<MomentModel> _myMoments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyMoments();
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
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildCoverPhoto(),
          _buildProfileSection(),
          _buildDivider(),
        ],
      ),
    );
  }

  Widget _buildCoverPhoto() {
    final latestMoment = _myMoments.isNotEmpty ? _myMoments.first : null;
    final hasMedia = latestMoment?.hasMedia ?? false;
    final mediaUrl = hasMedia ? latestMoment!.mediaUrls.first : '';

    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF8F8F8),
            const Color(0xFFF8F8F8).withOpacity(0.8),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background image or pattern
          if (hasMedia && latestMoment!.hasImages)
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(mediaUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.white.withOpacity(0.8),
                    BlendMode.overlay,
                  ),
                ),
              ),
            )
          else
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8F8F8),
              ),
              child: CustomPaint(
                painter: _GeometricPatternPainter(),
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
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
          
          // Profile content
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                  child: userImageWidget(
                    imageUrl: widget.user.image,
                    radius: 30,
                    onTap: () => _navigateToMyMoments(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D1D1D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_isLoading)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1D1D1D),
                          ),
                        )
                      else
                        Text(
                          _myMoments.isEmpty 
                              ? 'Share your first moment'
                              : '${_myMoments.length} moment${_myMoments.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1D1D1D),
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

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatsItem(
              'Moments',
              _myMoments.length.toString(),
              () => _navigateToMyMoments(),
            ),
          ),
          Expanded(
            child: _buildStatsItem(
              'Views',
              _getTotalViews().toString(),
              () => _navigateToMyMoments(),
            ),
          ),
          Expanded(
            child: _buildStatsItem(
              'Likes',
              _getTotalLikes().toString(),
              () => _navigateToMyMoments(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsItem(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1D),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return GestureDetector(
      onTap: () => _navigateToCreateMoment(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1D1D),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Share',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 8,
      color: const Color(0xFFF8F8F8),
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
      MaterialPageRoute(
        builder: (context) => const CreateMomentScreen(),
      ),
    ).then((_) => _loadMyMoments()); // Refresh moments after creating
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

// Custom painter for geometric background pattern
class _GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1D1D1D).withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw some geometric shapes for a modern pattern
    final random = [0.2, 0.4, 0.6, 0.8, 0.3, 0.7, 0.1, 0.9, 0.5];
    
    for (int i = 0; i < 6; i++) {
      final x = size.width * random[i];
      final y = size.height * random[i + 1];
      final radius = 20 + (random[i + 2] * 30);
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint,
      );
    }

    // Draw some triangular shapes
    final trianglePaint = Paint()
      ..color = const Color(0xFF1D1D1D).withOpacity(0.03)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final path = Path();
      final centerX = size.width * random[i * 2];
      final centerY = size.height * random[i * 2 + 1];
      final size1 = 15 + (random[i] * 25);

      path.moveTo(centerX, centerY - size1);
      path.lineTo(centerX - size1, centerY + size1);
      path.lineTo(centerX + size1, centerY + size1);
      path.close();

      canvas.drawPath(path, trianglePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
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

  // Modern Facebook-inspired color palette 2025
  static const Color fbPrimary = Color(0xFF1877F2);
  static const Color fbSecondary = Color(0xFF42A5F5);
  static const Color fbSuccess = Color(0xFF00C851);
  static const Color fbDanger = Color(0xFFFF3547);
  static const Color fbWarning = Color(0xFFFF8C00);
  
  // Neutral colors
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceGray = Color(0xFFF8F9FA);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE4E6EA);
  static const Color borderMedium = Color(0xFFCED0D4);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1C1E21);
  static const Color textSecondary = Color(0xFF65676B);
  static const Color textTertiary = Color(0xFF8A8D91);
  static const Color textDisabled = Color(0xFFBCC0C4);
  
  // Shadows
  static const Color shadowColor = Color(0x08000000);
  static const Color shadowMedium = Color(0x12000000);

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
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
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: surfaceCard,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildHeaderSection(),
                  const Divider(color: borderLight, height: 1),
                  _buildCreateMomentSection(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildProfileImage(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
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
                  Text(
                    _myMoments.isEmpty 
                        ? 'Share your first moment'
                        : '${_myMoments.length} moment${_myMoments.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          _buildStatsSection(),
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
            color: fbPrimary.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: userImageWidget(
          imageUrl: widget.user.image,
          radius: 24,
          onTap: () => _navigateToMyMoments(),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: fbPrimary,
        ),
      );
    }

    return Row(
      children: [
        _buildStatItem(
          'Moments',
          _myMoments.length.toString(),
          fbPrimary,
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          'Likes',
          _getTotalLikes().toString(),
          fbDanger,
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          'Views',
          _getTotalViews().toString(),
          fbSuccess,
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return GestureDetector(
      onTap: () => _navigateToMyMoments(),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateMomentSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          userImageWidget(
            imageUrl: widget.user.image,
            radius: 18,
            onTap: () {},
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToCreateMoment(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: surfaceGray,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: borderLight),
                ),
                child: const Text(
                  "What's on your mind?",
                  style: TextStyle(
                    fontSize: 15,
                    color: textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _navigateToCreateMoment(),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: fbSuccess.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.photo_library_rounded,
              color: fbSuccess,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _navigateToCreateMoment(),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: fbDanger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.videocam_rounded,
              color: fbDanger,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  int _getTotalViews() {
    return _myMoments.fold(0, (total, moment) => total + moment.viewsCount);
  }

  int _getTotalLikes() {
    return _myMoments.fold(0, (total, moment) => total + moment.likesCount);
  }

  void _navigateToCreateMoment() {
    HapticFeedback.lightImpact();
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
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((_) => _loadMyMoments());
  }

  void _navigateToMyMoments() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyMomentsScreen(user: widget.user),
      ),
    );
  }
}
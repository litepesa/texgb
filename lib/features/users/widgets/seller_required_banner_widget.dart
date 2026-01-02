// lib/features/users/widgets/seller_required_banner_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/users/widgets/seller_upgrade_widget.dart';

class SellerRequiredBannerWidget extends ConsumerStatefulWidget {
  /// Whether to show the banner even if user is a seller
  final bool forceShow;

  /// Custom vertical position (0.0 to 1.0 of screen height)
  final double? verticalPosition;

  /// Horizontal margin
  final double horizontalMargin;

  /// Custom callback when banner is tapped (optional)
  final VoidCallback? onTap;

  const SellerRequiredBannerWidget({
    super.key,
    this.forceShow = false,
    this.verticalPosition,
    this.horizontalMargin = 16,
    this.onTap,
  });

  @override
  ConsumerState<SellerRequiredBannerWidget> createState() => _SellerRequiredBannerWidgetState();
}

class _SellerRequiredBannerWidgetState extends ConsumerState<SellerRequiredBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _bannerAnimationController;
  late Animation<double> _bannerAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize banner animation
    _bannerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bannerAnimation = CurvedAnimation(
      parent: _bannerAnimationController,
      curve: Curves.elasticOut,
    );

    // Animate banner on appear
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bannerAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _bannerAnimationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      // Show the seller upgrade modal
      SellerUpgradeWidget.show(context);
    }
  }

  void _handleRefresh() {
    HapticFeedback.lightImpact();
    ref.invalidate(authenticationProvider);
  }

  @override
  Widget build(BuildContext context) {
    // Watch the current user's seller status
    final currentUser = ref.watch(currentUserProvider);
    final isSeller = currentUser?.isSeller ?? false;

    // Only show if user is NOT a seller (or forceShow is true)
    if (!widget.forceShow && isSeller) {
      return const SizedBox.shrink();
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final topPosition = widget.verticalPosition != null
        ? screenHeight * widget.verticalPosition!
        : screenHeight * 0.35;

    return Positioned(
      top: topPosition,
      left: widget.horizontalMargin,
      right: widget.horizontalMargin,
      child: ScaleTransition(
        scale: _bannerAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1B5E20),
                Color(0xFF2E7D32),
                Color(0xFF4CAF50),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.4),
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    // Refresh button
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _handleRefresh,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Banner content
                    Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: Row(
                        children: [
                          // Animated icon
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(seconds: 2),
                            builder: (context, value, child) {
                              return Transform.rotate(
                                angle: value * 0.1,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.3),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.store_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(width: 16),

                          // Text content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      '🏪 Become a Seller!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'REQUIRED',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Upgrade to seller account to list products',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Upgrade to Seller',
                                        style: TextStyle(
                                          color: Color(0xFF2E7D32),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward,
                                        color: Color(0xFF2E7D32),
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Non-positioned version for use in regular widget trees
class SellerRequiredBannerCard extends ConsumerStatefulWidget {
  /// Whether to show the banner even if user is a seller
  final bool forceShow;

  /// Custom callback when banner is tapped (optional)
  final VoidCallback? onTap;

  const SellerRequiredBannerCard({
    super.key,
    this.forceShow = false,
    this.onTap,
  });

  @override
  ConsumerState<SellerRequiredBannerCard> createState() => _SellerRequiredBannerCardState();
}

class _SellerRequiredBannerCardState extends ConsumerState<SellerRequiredBannerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _bannerAnimationController;
  late Animation<double> _bannerAnimation;

  @override
  void initState() {
    super.initState();

    _bannerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bannerAnimation = CurvedAnimation(
      parent: _bannerAnimationController,
      curve: Curves.elasticOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bannerAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _bannerAnimationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      SellerUpgradeWidget.show(context);
    }
  }

  void _handleRefresh() {
    HapticFeedback.lightImpact();
    ref.invalidate(authenticationProvider);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isSeller = currentUser?.isSeller ?? false;

    if (!widget.forceShow && isSeller) {
      return const SizedBox.shrink();
    }

    return ScaleTransition(
      scale: _bannerAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B5E20),
              Color(0xFF2E7D32),
              Color(0xFF4CAF50),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.4),
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _handleRefresh,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Row(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(seconds: 2),
                          builder: (context, value, child) {
                            return Transform.rotate(
                              angle: value * 0.1,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.store_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    '🏪 Become a Seller!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'REQUIRED',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Upgrade to seller account to list products',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Upgrade to Seller',
                                      style: TextStyle(
                                        color: Color(0xFF2E7D32),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Color(0xFF2E7D32),
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

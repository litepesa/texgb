// lib/features/series/widgets/paywall_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/series/models/series_model.dart';
import 'package:textgb/features/series/models/series_episode_model.dart';
import 'package:textgb/features/series/providers/series_provider.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';

class PaywallBottomSheet extends ConsumerStatefulWidget {
  final SeriesModel series;
  final SeriesEpisodeModel lockedEpisode;
  final VoidCallback? onPurchaseSuccess;

  const PaywallBottomSheet({
    Key? key,
    required this.series,
    required this.lockedEpisode,
    this.onPurchaseSuccess,
  }) : super(key: key);

  @override
  ConsumerState<PaywallBottomSheet> createState() => _PaywallBottomSheetState();
}

class _PaywallBottomSheetState extends ConsumerState<PaywallBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isPurchasing = false;
  String? _purchaseError;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handlePurchase() async {
    final currentUser = ref.read(authenticationProvider).valueOrNull?.userModel;
    if (currentUser == null) {
      setState(() {
        _purchaseError = 'Please log in to purchase this series';
      });
      return;
    }

    setState(() {
      _isPurchasing = true;
      _purchaseError = null;
    });

    try {
      // Add haptic feedback
      HapticFeedback.mediumImpact();
      
      // TODO: Implement actual payment processing
      // For now, we'll simulate a purchase with a delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate payment processing
      final transactionId = 'txn_${DateTime.now().millisecondsSinceEpoch}';
      
      await ref.read(seriesProvider.notifier).purchaseSeries(
        seriesId: widget.series.id,
        amount: widget.series.seriesPrice,
        paymentMethod: 'mobile_money', // TODO: Get from payment method selection
        transactionId: transactionId,
        onSuccess: (message) {
          HapticFeedback.lightImpact();
          
          if (mounted) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            
            // Close the bottom sheet
            Navigator.of(context).pop();
            
            // Notify parent about successful purchase
            widget.onPurchaseSuccess?.call();
          }
        },
        onError: (error) {
          HapticFeedback.heavyImpact();
          
          if (mounted) {
            setState(() {
              _purchaseError = error;
              _isPurchasing = false;
            });
          }
        },
      );
    } catch (e) {
      HapticFeedback.heavyImpact();
      
      if (mounted) {
        setState(() {
          _purchaseError = 'Purchase failed: ${e.toString()}';
          _isPurchasing = false;
        });
      }
    }
  }

  void _closeBottomSheet() {
    _animationController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, screenHeight * 0.3 * _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              height: screenHeight * 0.7,
              decoration: BoxDecoration(
                color: modernTheme.backgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: modernTheme.textSecondaryColor?.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Unlock Full Series',
                            style: TextStyle(
                              color: modernTheme.textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _closeBottomSheet,
                          icon: Icon(
                            Icons.close,
                            color: modernTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Series info card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: modernTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: modernTheme.borderColor!,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Series thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: widget.series.thumbnailImage.isNotEmpty
                                      ? Image.network(
                                          widget.series.thumbnailImage,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 60,
                                              height: 60,
                                              color: modernTheme.primaryColor?.withOpacity(0.2),
                                              child: Icon(
                                                Icons.play_circle_outline,
                                                color: modernTheme.primaryColor,
                                                size: 30,
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: modernTheme.primaryColor?.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.play_circle_outline,
                                            color: modernTheme.primaryColor,
                                            size: 30,
                                          ),
                                        ),
                                ),
                                
                                const SizedBox(width: 12),
                                
                                // Series info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.series.title,
                                        style: TextStyle(
                                          color: modernTheme.textColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${widget.series.episodeCount} episodes • ${widget.series.formattedTotalDuration}',
                                        style: TextStyle(
                                          color: modernTheme.textSecondaryColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'By ${widget.series.creatorName}',
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
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Locked episode info
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.amber.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lock,
                                  color: Colors.amber[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Episode ${widget.lockedEpisode.episodeNumber} is locked',
                                        style: TextStyle(
                                          color: Colors.amber[700],
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.lockedEpisode.title,
                                        style: TextStyle(
                                          color: modernTheme.textSecondaryColor,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // What you get
                          Text(
                            'What You Get',
                            style: TextStyle(
                              color: modernTheme.textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Benefits list
                          ..._buildBenefitsList(modernTheme),
                          
                          const SizedBox(height: 24),
                          
                          // Pricing info
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  modernTheme.primaryColor!.withOpacity(0.1),
                                  modernTheme.primaryColor!.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: modernTheme.primaryColor!.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'One-time payment',
                                      style: TextStyle(
                                        color: modernTheme.textColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      widget.series.formattedPrice,
                                      style: TextStyle(
                                        color: modernTheme.primaryColor,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Unlock all ${widget.series.paidEpisodeCount} premium episodes forever',
                                  style: TextStyle(
                                    color: modernTheme.textSecondaryColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Error message
                          if (_purchaseError != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red[700],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _purchaseError!,
                                      style: TextStyle(
                                        color: Colors.red[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom action area
                  Container(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 16,
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                    ),
                    decoration: BoxDecoration(
                      color: modernTheme.backgroundColor,
                      border: Border(
                        top: BorderSide(
                          color: modernTheme.borderColor!,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Purchase button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isPurchasing ? null : _handlePurchase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: modernTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              disabledBackgroundColor: modernTheme.primaryColor?.withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isPurchasing
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white.withOpacity(0.8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('Processing...'),
                                    ],
                                  )
                                : Text(
                                    'Unlock Series - ${widget.series.formattedPrice}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Terms text
                        Text(
                          'Secure payment • One-time purchase • Instant access',
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildBenefitsList(ModernThemeExtension modernTheme) {
    final benefits = [
      {
        'icon': Icons.lock_open,
        'title': 'Unlock All Episodes',
        'description': 'Access all ${widget.series.paidEpisodeCount} premium episodes'
      },
      {
        'icon': Icons.download,
        'title': 'Offline Access',
        'description': 'Watch episodes anytime, even without internet'
      },
      {
        'icon': Icons.hd,
        'title': 'High Quality',
        'description': 'Stream in the highest available quality'
      },
      {
        'icon': Icons.support,
        'title': 'Support Creator',
        'description': 'Help ${widget.series.creatorName} create more content'
      },
    ];

    return benefits.map((benefit) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: modernTheme.primaryColor?.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                benefit['icon'] as IconData,
                color: modernTheme.primaryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    benefit['title'] as String,
                    style: TextStyle(
                      color: modernTheme.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    benefit['description'] as String,
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
      );
    }).toList();
  }
}
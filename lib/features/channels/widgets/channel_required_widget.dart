// lib/features/channels/widgets/channel_required_widget.dart (Fixed for correct auth flow)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/constants.dart';

class ChannelRequiredWidget extends ConsumerWidget {
  final String title;
  final String subtitle;
  final String actionText;
  final IconData icon;
  final bool showContinueBrowsing;
  final VoidCallback? onContinueBrowsing;

  const ChannelRequiredWidget({
    Key? key,
    this.title = 'Sign In Required',
    this.subtitle = 'Please sign in to access this feature and unlock the full WeiBao experience.',
    this.actionText = 'Sign In',
    this.icon = Icons.login,
    this.showContinueBrowsing = true,
    this.onContinueBrowsing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modernTheme = context.modernTheme;
    
    // Watch authentication state
    final authState = ref.watch(authenticationProvider);
    final isLoggedIn = authState.value?.isSuccessful ?? false;
    final isAuthLoading = authState.isLoading;
    
    // Show loading if authentication is loading
    if (isAuthLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    // If user is logged in (which means they have a channel), allow access
    if (isLoggedIn) {
      return const SizedBox.shrink();
    }
    
    // User is not logged in, show login prompt
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: modernTheme.primaryColor?.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: modernTheme.primaryColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: modernTheme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: modernTheme.textSecondaryColor,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _navigateToLogin(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: modernTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  actionText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Show benefits for unauthenticated users
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: modernTheme.surfaceColor?.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: modernTheme.primaryColor?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Join WeiBao to:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: modernTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitItem(
                    modernTheme,
                    Icons.favorite,
                    'Like and react to videos',
                  ),
                  _buildBenefitItem(
                    modernTheme,
                    Icons.comment,
                    'Comment and connect with creators',
                  ),
                  _buildBenefitItem(
                    modernTheme,
                    Icons.video_call,
                    'Create and share your own content',
                  ),
                  _buildBenefitItem(
                    modernTheme,
                    Icons.card_giftcard,
                    'Send virtual gifts to support creators',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Continue browsing option for unauthenticated users
            if (showContinueBrowsing) ...[
              TextButton(
                onPressed: onContinueBrowsing ?? () => Navigator.of(context).pop(),
                child: Text(
                  'Continue browsing as guest',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ] else ...[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
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
    );
  }

  Widget _buildBenefitItem(ModernThemeExtension modernTheme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: modernTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: modernTheme.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).pushNamed(Constants.landingScreen);
  }
}

// Simplified utility function to check authentication
Future<bool> requireAuthentication(
  BuildContext context,
  WidgetRef ref, {
  String? customTitle,
  String? customSubtitle,
  String? customActionText,
  IconData? customIcon,
  bool showContinueBrowsing = true,
  VoidCallback? onContinueBrowsing,
}) async {
  final authState = ref.read(authenticationProvider).value ?? const AuthenticationState();
  final isLoggedIn = authState.isSuccessful;
  
  // User is authenticated (and by extension has a channel)
  if (isLoggedIn) {
    return true;
  }
  
  // User is not authenticated, show dialog
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: showContinueBrowsing,
    builder: (context) => AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: ChannelRequiredWidget(
          title: customTitle ?? 'Sign In Required',
          subtitle: customSubtitle ?? 'Please sign in to access this feature.',
          actionText: customActionText ?? 'Sign In',
          icon: customIcon ?? Icons.login,
          showContinueBrowsing: showContinueBrowsing,
          onContinueBrowsing: onContinueBrowsing,
        ),
      ),
    ),
  );
  
  return result ?? false;
}

// Legacy function for backward compatibility - now just checks authentication
Future<bool> requireUserChannel(
  BuildContext context,
  WidgetRef ref, {
  String? customTitle,
  String? customSubtitle,
  String? customActionText,
  IconData? customIcon,
  bool showContinueBrowsing = false,
}) async {
  return requireAuthentication(
    context,
    ref,
    customTitle: customTitle ?? 'Sign In Required',
    customSubtitle: customSubtitle ?? 'Please sign in to access this feature.',
    customActionText: customActionText ?? 'Sign In',
    customIcon: customIcon ?? Icons.login,
    showContinueBrowsing: showContinueBrowsing,
  );
}

// Alternative: Inline widget for embedding in screens with auth checking
class InlineChannelRequiredWidget extends ConsumerWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onSignIn;
  final bool showGuestMode;

  const InlineChannelRequiredWidget({
    Key? key,
    this.title = 'Get Started',
    this.subtitle = 'Sign in to start sharing content and connect with the community.',
    this.onSignIn,
    this.showGuestMode = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modernTheme = context.modernTheme;
    final authState = ref.watch(authenticationProvider).value ?? const AuthenticationState();
    final isLoggedIn = authState.isSuccessful;
    
    // Don't show if user is authenticated (and has channel)
    if (isLoggedIn) {
      return const SizedBox.shrink();
    }
    
    // Not logged in
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: modernTheme.primaryColor?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.login,
            size: 48,
            color: modernTheme.primaryColor,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: modernTheme.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: modernTheme.textSecondaryColor,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSignIn ?? () => Navigator.of(context).pushNamed(Constants.landingScreen),
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          if (showGuestMode) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                // Can be used to dismiss this widget or navigate back
              },
              child: Text(
                'Continue as guest',
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Simple banner widget to encourage sign-up for unauthenticated users
class GuestModeBanner extends ConsumerWidget {
  final VoidCallback? onDismiss;
  final VoidCallback? onSignIn;

  const GuestModeBanner({
    Key? key,
    this.onDismiss,
    this.onSignIn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modernTheme = context.modernTheme;
    final authState = ref.watch(authenticationProvider).value ?? const AuthenticationState();
    final isLoggedIn = authState.isSuccessful;
    
    // Don't show banner if user is already logged in (and has channel)
    if (isLoggedIn) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            modernTheme.primaryColor?.withOpacity(0.8) ?? Colors.blue.shade600,
            modernTheme.primaryColor ?? Colors.purple.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Join WeiBao!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Like, comment, and create your own content',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: onSignIn ?? () {
                    Navigator.pushNamed(context, Constants.landingScreen);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: modernTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(
                Icons.close,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
// lib/features/channels/widgets/channel_required_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/screens/create_channel_screen.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/constants.dart';

enum RequirementType {
  authentication,
  channel,
  both,
}

class ChannelRequiredWidget extends ConsumerWidget {
  final String title;
  final String subtitle;
  final String actionText;
  final IconData icon;
  final RequirementType requirementType;
  final String? loginActionText;
  final String? channelActionText;

  const ChannelRequiredWidget({
    Key? key,
    this.title = 'Access Required',
    this.subtitle = 'You need to be logged in and have a channel to perform this action.',
    this.actionText = 'Get Started',
    this.icon = Icons.video_call,
    this.requirementType = RequirementType.both,
    this.loginActionText = 'Sign In',
    this.channelActionText = 'Create Channel',
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modernTheme = context.modernTheme;
    
    // Watch authentication state using new channel-based providers
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final isAuthLoading = ref.watch(isAuthLoadingProvider);
    final currentChannel = ref.watch(currentChannelProvider);
    
    // Watch channels state
    final channelsState = ref.watch(channelsProvider);
    
    // Determine what's missing
    final needsAuth = !isLoggedIn;
    final needsChannel = isLoggedIn && currentChannel == null;
    
    // Show loading if authentication is loading
    if (isAuthLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    // Determine the appropriate message and action based on what's missing
    String displayTitle;
    String displaySubtitle;
    String displayActionText;
    IconData displayIcon;
    VoidCallback? primaryAction;
    
    if (needsAuth) {
      displayTitle = 'Sign In Required';
      displaySubtitle = 'Please sign in to access this feature.';
      displayActionText = loginActionText ?? 'Sign In';
      displayIcon = Icons.login;
      primaryAction = () => _navigateToLogin(context);
    } else if (needsChannel) {
      displayTitle = 'Channel Required';
      displaySubtitle = 'You need to create a channel to perform this action.';
      displayActionText = channelActionText ?? 'Create Channel';
      displayIcon = Icons.video_call;
      primaryAction = () => _navigateToCreateChannel(context);
    } else {
      // This shouldn't normally be shown if both requirements are met
      displayTitle = title;
      displaySubtitle = subtitle;
      displayActionText = actionText;
      displayIcon = icon;
      primaryAction = null;
    }
    
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
                displayIcon,
                size: 40,
                color: modernTheme.primaryColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              displayTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: modernTheme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Text(
              displaySubtitle,
              style: TextStyle(
                fontSize: 16,
                color: modernTheme.textSecondaryColor,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            if (isLoggedIn && currentChannel != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: modernTheme.primaryColor?.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Signed in as ${currentChannel.name}',
                  style: TextStyle(
                    fontSize: 14,
                    color: modernTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            if (primaryAction != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: primaryAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: modernTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    displayActionText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              // Show additional actions if both auth and channel are needed
              if (needsAuth && requirementType == RequirementType.both) ...[
                const SizedBox(height: 12),
                Text(
                  'After signing in, you\'ll be able to create a channel',
                  style: TextStyle(
                    fontSize: 14,
                    color: modernTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
            
            const SizedBox(height: 16),
            
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
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).pushNamed(Constants.landingScreen);
  }

  void _navigateToCreateChannel(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateChannelScreen(),
      ),
    );
    
    // If channel was created successfully, pop this screen too
    if (result == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

// Enhanced utility function to check requirements and show dialog if not met
Future<bool> requireUserAccess(
  BuildContext context,
  WidgetRef ref, {
  RequirementType requirementType = RequirementType.both,
  String? customTitle,
  String? customSubtitle,
  String? customActionText,
  IconData? customIcon,
  String? loginActionText,
  String? channelActionText,
}) async {
  final isLoggedIn = ref.read(isLoggedInProvider);
  final currentChannel = ref.read(currentChannelProvider);
  
  // Check what's required vs what user has
  final hasAuth = isLoggedIn;
  final hasChannel = currentChannel != null;
  
  bool shouldProceed = false;
  
  switch (requirementType) {
    case RequirementType.authentication:
      shouldProceed = hasAuth;
      break;
    case RequirementType.channel:
      shouldProceed = hasChannel;
      break;
    case RequirementType.both:
      shouldProceed = hasAuth && hasChannel;
      break;
  }
  
  if (shouldProceed) {
    return true; // User meets requirements, proceed
  }
  
  // User doesn't meet requirements, show dialog
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: ChannelRequiredWidget(
          title: customTitle ?? 'Access Required',
          subtitle: customSubtitle ?? _getDefaultSubtitle(requirementType, hasAuth, hasChannel),
          actionText: customActionText ?? _getDefaultActionText(requirementType, hasAuth, hasChannel),
          icon: customIcon ?? _getDefaultIcon(requirementType, hasAuth, hasChannel),
          requirementType: requirementType,
          loginActionText: loginActionText,
          channelActionText: channelActionText,
        ),
      ),
    ),
  );
  
  return result ?? false;
}

// Legacy function for backward compatibility
Future<bool> requireUserChannel(
  BuildContext context,
  WidgetRef ref, {
  String? customTitle,
  String? customSubtitle,
  String? customActionText,
  IconData? customIcon,
}) async {
  return requireUserAccess(
    context,
    ref,
    requirementType: RequirementType.channel,
    customTitle: customTitle,
    customSubtitle: customSubtitle,
    customActionText: customActionText,
    customIcon: customIcon,
  );
}

// Helper functions for default messages
String _getDefaultSubtitle(RequirementType type, bool hasAuth, bool hasChannel) {
  if (!hasAuth) {
    return type == RequirementType.both 
      ? 'Please sign in and create a channel to access this feature.'
      : 'Please sign in to access this feature.';
  } else if (!hasChannel) {
    return 'You need to create a channel to perform this action.';
  }
  return 'You need to meet the requirements to perform this action.';
}

String _getDefaultActionText(RequirementType type, bool hasAuth, bool hasChannel) {
  if (!hasAuth) {
    return 'Sign In';
  } else if (!hasChannel) {
    return 'Create Channel';
  }
  return 'Get Started';
}

IconData _getDefaultIcon(RequirementType type, bool hasAuth, bool hasChannel) {
  if (!hasAuth) {
    return Icons.login;
  } else if (!hasChannel) {
    return Icons.video_call;
  }
  return Icons.security;
}

// Alternative: Inline widget for embedding in screens with auth checking
class InlineChannelRequiredWidget extends ConsumerWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onCreateChannel;
  final VoidCallback? onSignIn;
  final RequirementType requirementType;

  const InlineChannelRequiredWidget({
    Key? key,
    this.title = 'Get Started',
    this.subtitle = 'Sign in and create your channel to start sharing content.',
    this.onCreateChannel,
    this.onSignIn,
    this.requirementType = RequirementType.both,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modernTheme = context.modernTheme;
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final currentChannel = ref.watch(currentChannelProvider);
    final channelsState = ref.watch(channelsProvider);
    
    // Determine what actions to show
    final needsAuth = !isLoggedIn;
    final needsChannel = isLoggedIn && currentChannel == null;
    
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
            needsAuth ? Icons.login : Icons.video_call,
            size: 48,
            color: modernTheme.primaryColor,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            needsAuth ? 'Sign In Required' : (needsChannel ? 'Create Your Channel' : title),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: modernTheme.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            needsAuth 
              ? 'Please sign in to access this feature.'
              : (needsChannel 
                ? 'Start sharing your content by creating a channel.'
                : subtitle),
            style: TextStyle(
              fontSize: 14,
              color: modernTheme.textSecondaryColor,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (isLoggedIn && currentChannel != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: modernTheme.primaryColor?.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Signed in as ${currentChannel.name}',
                style: TextStyle(
                  fontSize: 12,
                  color: modernTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          
          if (needsAuth) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSignIn ?? () => _navigateToLogin(context),
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
          ] else if (needsChannel) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onCreateChannel ?? () => _navigateToCreateChannel(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: modernTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Create Channel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).pushNamed(Constants.landingScreen);
  }

  void _navigateToCreateChannel(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateChannelScreen(),
      ),
    );
  }
}
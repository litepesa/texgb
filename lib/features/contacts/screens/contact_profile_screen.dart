// lib/features/contacts/screens/contact_profile_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:cached_network_image/cached_network_image.dart';


class ContactProfileScreen extends ConsumerStatefulWidget {
  final UserModel contact;

  const ContactProfileScreen({
    super.key,
    required this.contact,
  });

  @override
  ConsumerState<ContactProfileScreen> createState() => _ContactProfileScreenState();
}

class _ContactProfileScreenState extends ConsumerState<ContactProfileScreen>
    with TickerProviderStateMixin {
  late UserModel _contact;
  bool _isLoading = false;
  final bool _isCreatingChat = false;
  bool _isBlocked = false;
  
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _contact = widget.contact;
    _setupAnimations();
    _checkBlockedStatus();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutQuart),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    _fadeController.forward();
    _scaleController.forward();
  }

  void _checkBlockedStatus() {
    final blockedContacts = ref.read(blockedContactsProvider);
    _isBlocked = blockedContacts.any((contact) => contact.uid == _contact.uid);
  }

  Future<void> _blockContact() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(contactsNotifierProvider.notifier).blockContact(_contact);
      if (mounted) {
        _showSuccessSnackBar('${_contact.name} blocked successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to block contact: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _unblockContact() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(contactsNotifierProvider.notifier).unblockContact(_contact);
      if (mounted) {
        setState(() {
          _isBlocked = false;
        });
        _showSuccessSnackBar('${_contact.name} unblocked successfully');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to unblock contact: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Updated navigation to chat - simplified for now until chat system is integrated
  /*Future<void> _navigateToChat() async {
  final currentUser = ref.read(currentUserProvider);
  if (currentUser == null) {
    _showErrorSnackBar('User not authenticated');
    return;
  }

  setState(() {
    _isCreatingChat = true;
  });

  try {
    // Generate a chat ID (you might want to use a different strategy)
    final chatId = '${currentUser.uid}_${_contact.uid}';
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            contact: _contact,
          ),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      _showErrorSnackBar('Failed to start chat: $e');
    }
  } finally {
    if (mounted) {
      setState(() {
        _isCreatingChat = false;
      });
    }
  }
}*/

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    final primaryColor = theme.primaryColor!;
    
    return Scaffold(
      backgroundColor: theme.surfaceColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // Enhanced App Bar with Hero Image
            SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              backgroundColor: theme.surfaceColor,
              elevation: 0,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.surfaceColor!.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: theme.textColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        primaryColor.withOpacity(0.1),
                        theme.surfaceColor!,
                      ],
                    ),
                  ),
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60), // Account for app bar
                        
                        // Enhanced Profile Image
                        Hero(
                          tag: 'contact-${_contact.uid}',
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isBlocked 
                                    ? Colors.red.withOpacity(0.5)
                                    : primaryColor.withOpacity(0.3),
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isBlocked ? Colors.red : primaryColor).withOpacity(0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _buildProfileImage(),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Contact Name with Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isBlocked) ...[
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.block_rounded,
                                  color: Colors.red,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Text(
                                _contact.name,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textColor,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Phone Number Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.phone_rounded,
                                  color: primaryColor,
                                  size: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _contact.phoneNumber,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Bio Preview if available
                        if (_contact.bio.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 32),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: theme.surfaceVariantColor!.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.dividerColor!.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _contact.bio,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textSecondaryColor,
                                fontStyle: FontStyle.italic,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Action Buttons
                    if (!_isBlocked) ...[
                      Row(
                        children: [
                          // Message Button
                          Expanded(
                            child: _buildActionButton(
                              onPressed: (){},
                              icon: _isCreatingChat
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.bubble_left_bubble_right,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                              label: _isCreatingChat ? 'Starting Chat...' : 'Message',
                              backgroundColor: primaryColor,
                              textColor: Colors.white,
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Block Button
                          Expanded(
                            child: _buildActionButton(
                              onPressed: _isLoading ? null : _showBlockConfirmationDialog,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.red,
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(
                                        Icons.block_rounded,
                                        color: Colors.red,
                                        size: 16,
                                      ),
                                    ),
                              label: _isLoading ? 'Blocking...' : 'Block',
                              backgroundColor: Colors.red.withOpacity(0.1),
                              textColor: Colors.red,
                              borderColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Unblock Button (when contact is blocked)
                      SizedBox(
                        width: double.infinity,
                        child: _buildActionButton(
                          onPressed: _isLoading ? null : _showUnblockConfirmationDialog,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                          label: _isLoading ? 'Unblocking...' : 'Unblock Contact',
                          backgroundColor: Colors.green,
                          textColor: Colors.white,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Contact Information Card
                    _buildContactInfoCard(),
                    
                    // Statistics Card (if not blocked)
                    if (!_isBlocked && _hasStatistics()) ...[
                      const SizedBox(height: 16),
                      _buildStatisticsCard(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    final theme = context.modernTheme;
    
    if (_contact.profileImage.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: _contact.profileImage,
        imageBuilder: (context, imageProvider) => Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        placeholder: (context, url) => Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.surfaceVariantColor,
          ),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.primaryColor,
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildFallbackAvatar(),
      );
    }
    
    return _buildFallbackAvatar();
  }

  Widget _buildFallbackAvatar() {
    final theme = context.modernTheme;
    final color = _isBlocked ? Colors.red : theme.primaryColor!;
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Text(
          _contact.name.isNotEmpty ? _contact.name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required Widget icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed == null ? null : () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: borderColor != null 
                ? Border.all(color: borderColor, width: 1.5)
                : null,
            boxShadow: onPressed != null ? [
              BoxShadow(
                color: backgroundColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfoCard() {
    final theme = context.modernTheme;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor!.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor!.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
            spreadRadius: -6,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: theme.primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.textColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Phone Number
          _buildInfoRow(
            icon: Icons.phone_rounded,
            label: 'Phone',
            value: _contact.phoneNumber,
            theme: theme,
          ),
          
          // Bio (if available)
          if (_contact.bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.description_outlined,
              label: 'Bio',
              value: _contact.bio,
              theme: theme,
              maxLines: 3,
            ),
          ],
          
          // Account Status
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: _isBlocked ? Icons.block_rounded : Icons.check_circle_outline_rounded,
            label: 'Status',
            value: _isBlocked ? 'Blocked' : 'Active',
            theme: theme,
            valueColor: _isBlocked ? Colors.red : Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required theme,
    Color? valueColor,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.surfaceVariantColor!.withOpacity(0.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: valueColor ?? theme.textSecondaryColor,
            size: 14,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTertiaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: valueColor ?? theme.textColor,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _hasStatistics() {
    return _contact.followers > 0 || 
           _contact.following > 0 || 
           _contact.videosCount > 0;
  }

  Widget _buildStatisticsCard() {
    final theme = context.modernTheme;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor!.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor!.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
            spreadRadius: -6,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: theme.primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.textColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Statistics Row
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Videos',
                  _contact.videosCount.toString(),
                  Icons.video_library_outlined,
                  theme,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Followers',
                  _formatNumber(_contact.followers),
                  Icons.people_outline_rounded,
                  theme,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Following',
                  _formatNumber(_contact.following),
                  Icons.person_add_outlined,
                  theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.surfaceVariantColor!.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: theme.primaryColor,
            size: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.textTertiaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  void _showBlockConfirmationDialog() {
    showMyAnimatedDialog(
      context: context,
      title: 'Block Contact',
      content: 'Are you sure you want to block ${_contact.name}?\n\nThey won\'t be able to message or call you.',
      textAction: 'Block',
      onActionTap: (confirmed) {
        if (confirmed) {
          _blockContact();
        }
      },
    );
  }

  void _showUnblockConfirmationDialog() {
    showMyAnimatedDialog(
      context: context,
      title: 'Unblock Contact',
      content: 'Are you sure you want to unblock ${_contact.name}?\n\nThey will be able to message and call you again.',
      textAction: 'Unblock',
      onActionTap: (confirmed) {
        if (confirmed) {
          _unblockContact();
        }
      },
    );
  }

  // Helper methods for notifications
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.modernTheme.primaryColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
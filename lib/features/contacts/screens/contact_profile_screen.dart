// lib/features/contacts/screens/contact_profile_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/chat/screens/chat_screen.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class ContactProfileScreen extends ConsumerStatefulWidget {
  final UserModel contact;

  const ContactProfileScreen({
    Key? key,
    required this.contact,
  }) : super(key: key);

  @override
  ConsumerState<ContactProfileScreen> createState() => _ContactProfileScreenState();
}

class _ContactProfileScreenState extends ConsumerState<ContactProfileScreen> {
  late UserModel _contact;
  bool _isLoading = false;
  bool _isCreatingChat = false;

  @override
  void initState() {
    super.initState();
    _contact = widget.contact;
  }

  Future<void> _blockContact() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(contactsNotifierProvider.notifier).blockContact(_contact);
      if (mounted) {
        showSnackBar(context, 'Contact blocked successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to block contact: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Navigate to chat screen - Updated to use chat provider
  Future<void> _navigateToChat() async {
    setState(() {
      _isCreatingChat = true;
    });

    try {
      // Create or get existing chat
      final chatListNotifier = ref.read(chatListProvider.notifier);
      final chatId = await chatListNotifier.createChat(_contact.uid);
      
      if (chatId != null && mounted) {
        // Navigate to chat screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              contact: _contact,
            ),
          ),
        );
      } else if (mounted) {
        showSnackBar(context, 'Failed to create chat');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to start chat: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingChat = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modernTheme = context.modernTheme;
    final primaryColor = modernTheme.primaryColor!;
    
    return Scaffold(
      backgroundColor: modernTheme.surfaceColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: modernTheme.surfaceColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      primaryColor.withOpacity(0.1),
                      modernTheme.surfaceColor!,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80), // Account for app bar
                    
                    // Profile Image
                    Hero(
                      tag: 'contact-${_contact.uid}',
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primaryColor.withOpacity(0.3),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: _contact.image.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  _contact.image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => 
                                      _buildFallbackAvatar(),
                                ),
                              )
                            : _buildFallbackAvatar(),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Name
                    Text(
                      _contact.name,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: modernTheme.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          _contact.aboutMe,
                          style: TextStyle(
                            fontSize: 14,
                            color: modernTheme.textSecondaryColor,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
                  Row(
                    children: [
                      // Message Button - Navigate to Chat
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (_isLoading || _isCreatingChat) ? null : _navigateToChat,
                          icon: _isCreatingChat
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  CupertinoIcons.bubble_left_bubble_right,
                                  color: Colors.white,
                                ),
                          label: Text(_isCreatingChat ? 'Starting Chat...' : 'Message'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Block Button
                      Expanded(
                        child: OutlinedButton.icon(
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
                              : const Icon(Icons.block),
                          label: Text(_isLoading ? 'Blocking...' : 'Block'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Additional Info Card (Optional - minimal info)
                  if (_contact.lastSeen.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: modernTheme.surfaceVariantColor?.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: modernTheme.dividerColor!.withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.access_time,
                            color: modernTheme.textSecondaryColor,
                            size: 20,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Last seen',
                            style: TextStyle(
                              fontSize: 12,
                              color: modernTheme.textSecondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatLastSeen(_contact.lastSeen),
                            style: TextStyle(
                              fontSize: 14,
                              color: modernTheme.textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    final modernTheme = context.modernTheme;
    final primaryColor = modernTheme.primaryColor!;
    
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Text(
          _contact.name.isNotEmpty ? _contact.name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _formatLastSeen(String lastSeenTimestamp) {
    try {
      final lastSeen = DateTime.fromMicrosecondsSinceEpoch(
          int.parse(lastSeenTimestamp));
      final now = DateTime.now();
      final difference = now.difference(lastSeen);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else {
        // Format date for older timestamps
        return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showBlockConfirmationDialog() {
    showMyAnimatedDialog(
      context: context,
      title: 'Block Contact',
      content: 'Are you sure you want to block ${_contact.name}? They won\'t be able to message or call you.',
      textAction: 'Block',
      onActionTap: (confirmed) {
        if (confirmed) {
          _blockContact();
        }
      },
    );
  }
}
// Create a new file: lib/features/groups/screens/join_group_by_code_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/groups/providers/group_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class JoinGroupByCodeScreen extends ConsumerStatefulWidget {
  const JoinGroupByCodeScreen({super.key, String? initialCode});

  @override
  ConsumerState<JoinGroupByCodeScreen> createState() => _JoinGroupByCodeScreenState();
}

class _JoinGroupByCodeScreenState extends ConsumerState<JoinGroupByCodeScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _joinGroup() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorText = 'Please enter a group code';
      });
      return;
    }

    if (code.length < 8) {
      setState(() {
        _errorText = 'Invalid group code format';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final group = await ref.read(groupProvider.notifier).joinGroupByCode(code);
      
      if (mounted) {
        // Show success message
        showSnackBar(context, 'Successfully joined group "${group.groupName}"');
        
        // Return to previous screen
        Navigator.pop(context);
        
        // If it's a private group that requires approval
        if (group.isPrivate && group.approveMembers) {
          showSnackBar(context, 'Your request is pending admin approval');
        } else {
          // Open the group chat
          ref.read(groupProvider.notifier).openGroupChat(group, context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        title: Text(
          'Join Group by Code',
          style: TextStyle(color: theme.textColor),
        ),
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Illustration
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Icon(
                Icons.group_add,
                size: 80,
                color: theme.primaryColor,
              ),
            ),
            
            Text(
              'Enter the 8-character group code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ask the group creator or an admin for the code',
              style: TextStyle(
                color: theme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Code input field
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Group Code',
                hintText: 'Enter 8-character code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(
                  Icons.vpn_key,
                  color: theme.primaryColor,
                ),
                errorText: _errorText,
              ),
              maxLength: 8,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: const TextStyle(
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 24),
            
            // Join button
            ElevatedButton(
              onPressed: _isLoading ? null : _joinGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.0,
                      ),
                    )
                  : const Text(
                      'Join Group',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
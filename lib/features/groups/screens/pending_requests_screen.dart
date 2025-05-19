// lib/features/groups/screens/pending_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/groups/providers/group_provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class PendingRequestsScreen extends ConsumerStatefulWidget {
  final GroupModel group;

  const PendingRequestsScreen({
    super.key,
    required this.group,
  });

  @override
  ConsumerState<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends ConsumerState<PendingRequestsScreen> {
  List<UserModel> _pendingUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingUsers();
  }

  Future<void> _loadPendingUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pendingUserIds = widget.group.awaitingApprovalUIDs;
      final pendingUsers = <UserModel>[];

      // Load user data for each pending user ID
      for (final userId in pendingUserIds) {
        final user = await ref.read(authenticationProvider.notifier).getUserDataById(userId);
        if (user != null) {
          pendingUsers.add(user);
        }
      }

      setState(() {
        _pendingUsers = pendingUsers;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error loading pending requests: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _approveRequest(UserModel user) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(groupProvider.notifier).approveJoinRequest(
        widget.group.groupId,
        user.uid,
      );

      // Update the local list
      setState(() {
        _pendingUsers.removeWhere((u) => u.uid == user.uid);
      });

      if (mounted) {
        showSnackBar(context, '${user.name} has been approved to join the group');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error approving request: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _rejectRequest(UserModel user) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(groupProvider.notifier).rejectJoinRequest(
        widget.group.groupId,
        user.uid,
      );

      // Update the local list
      setState(() {
        _pendingUsers.removeWhere((u) => u.uid == user.uid);
      });

      if (mounted) {
        showSnackBar(context, '${user.name}\'s request has been rejected');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error rejecting request: $e');
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
          'Pending Requests',
          style: TextStyle(color: theme.textColor),
        ),
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : _pendingUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 80,
                        color: theme.textSecondaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pending requests',
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All requests have been handled',
                        style: TextStyle(
                          color: theme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _pendingUsers.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final user = _pendingUsers[index];
                    return Card(
                      elevation: 0,
                      color: theme.surfaceColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.borderColor!.withOpacity(0.2),
                        ),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            // User image
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: user.image.isNotEmpty
                                  ? NetworkImage(user.image)
                                  : null,
                              backgroundColor: theme.primaryColor!.withOpacity(0.2),
                              child: user.image.isEmpty
                                  ? Text(
                                      user.name[0].toUpperCase(),
                                      style: TextStyle(
                                        color: theme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            // User info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textColor,
                                    ),
                                  ),
                                  Text(
                                    user.phoneNumber,
                                    style: TextStyle(
                                      color: theme.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Action buttons
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.green,
                                    size: 28,
                                  ),
                                  onPressed: () => _approveRequest(user),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.cancel_outlined,
                                    color: Colors.red,
                                    size: 28,
                                  ),
                                  onPressed: () => _rejectRequest(user),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
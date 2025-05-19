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
  Map<String, bool> _processingStatus = {}; // Track approval/rejection status

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
    // Check member limit before approving
    final remainingSlots = widget.group.getRemainingMemberSlots();
    if (remainingSlots <= 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Member Limit Reached'),
          content: Text(
            'This group has reached the maximum limit of ${GroupModel.MAX_MEMBERS} members. '
            'You need to remove some members before approving new requests.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Set processing status for this user
    setState(() {
      _processingStatus[user.uid] = true;
    });

    try {
      await ref.read(groupProvider.notifier).approveJoinRequest(
        widget.group.groupId,
        user.uid,
      );

      // Update the local list
      setState(() {
        _pendingUsers.removeWhere((u) => u.uid == user.uid);
        _processingStatus.remove(user.uid);
      });

      if (mounted) {
        showSnackBar(context, '${user.name} has been approved to join the group');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error approving request: $e');
        // Reset processing status
        setState(() {
          _processingStatus[user.uid] = false;
        });
      }
    }
  }

  Future<void> _rejectRequest(UserModel user) async {
    // Set processing status for this user
    setState(() {
      _processingStatus[user.uid] = true;
    });

    try {
      await ref.read(groupProvider.notifier).rejectJoinRequest(
        widget.group.groupId,
        user.uid,
      );

      // Update the local list
      setState(() {
        _pendingUsers.removeWhere((u) => u.uid == user.uid);
        _processingStatus.remove(user.uid);
      });

      if (mounted) {
        showSnackBar(context, '${user.name}\'s request has been rejected');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error rejecting request: $e');
        // Reset processing status
        setState(() {
          _processingStatus[user.uid] = false;
        });
      }
    }
  }

  Future<void> _approveAllRequests() async {
    // Check member limit before approving all
    final remainingSlots = widget.group.getRemainingMemberSlots();
    final pendingCount = _pendingUsers.length;
    
    if (remainingSlots < pendingCount) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Approve All Requests'),
          content: Text(
            'You have $pendingCount pending requests but only $remainingSlots ${remainingSlots == 1 ? 'slot' : 'slots'} available. '
            'Please approve requests individually or remove some members to make space.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Confirm before approving all
    final shouldApproveAll = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve All Requests'),
        content: Text(
          'Are you sure you want to approve all ${_pendingUsers.length} pending requests?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve All'),
          ),
        ],
      ),
    );

    if (shouldApproveAll != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Approve each request individually
      for (final user in _pendingUsers) {
        await ref.read(groupProvider.notifier).approveJoinRequest(
          widget.group.groupId,
          user.uid,
        );
      }

      // Clear the list
      setState(() {
        _pendingUsers = [];
        _isLoading = false;
      });

      if (mounted) {
        showSnackBar(context, 'All pending requests have been approved');
        // Return to previous screen
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error approving all requests: $e');
        setState(() {
          _isLoading = false;
        });
        // Refresh the list to show current state
        _loadPendingUsers();
      }
    }
  }

  Future<void> _rejectAllRequests() async {
    // Confirm before rejecting all
    final shouldRejectAll = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject All Requests'),
        content: Text(
          'Are you sure you want to reject all ${_pendingUsers.length} pending requests? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Reject All'),
          ),
        ],
      ),
    );

    if (shouldRejectAll != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Reject each request individually
      for (final user in _pendingUsers) {
        await ref.read(groupProvider.notifier).rejectJoinRequest(
          widget.group.groupId,
          user.uid,
        );
      }

      // Clear the list
      setState(() {
        _pendingUsers = [];
        _isLoading = false;
      });

      if (mounted) {
        showSnackBar(context, 'All pending requests have been rejected');
        // Return to previous screen
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error rejecting all requests: $e');
        setState(() {
          _isLoading = false;
        });
        // Refresh the list to show current state
        _loadPendingUsers();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    final remainingSlots = widget.group.getRemainingMemberSlots();
    final canApproveAll = remainingSlots >= _pendingUsers.length;
    final isAtCapacity = remainingSlots <= 0;

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
        actions: [
          // Show bulk actions menu if there are pending requests
          if (_pendingUsers.isNotEmpty && !_isLoading)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'approve_all') {
                  _approveAllRequests();
                } else if (value == 'reject_all') {
                  _rejectAllRequests();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'approve_all',
                  enabled: canApproveAll,
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: canApproveAll ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Approve All',
                        style: TextStyle(
                          color: canApproveAll ? null : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reject_all',
                  child: Row(
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        color: Colors.red,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text('Reject All'),
                    ],
                  ),
                ),
              ],
            ),
        ],
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : Column(
              children: [
                // Member capacity status
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isAtCapacity
                        ? Colors.red.shade50
                        : (canApproveAll
                            ? Colors.green.shade50
                            : Colors.orange.shade50),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAtCapacity
                          ? Colors.red.shade200
                          : (canApproveAll
                              ? Colors.green.shade200
                              : Colors.orange.shade200),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isAtCapacity
                                ? Icons.error_outline
                                : (canApproveAll
                                    ? Icons.check_circle_outline
                                    : Icons.warning_amber_rounded),
                            color: isAtCapacity
                                ? Colors.red
                                : (canApproveAll ? Colors.green : Colors.orange),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isAtCapacity
                                  ? 'Group is Full'
                                  : (canApproveAll
                                      ? 'Sufficient Capacity'
                                      : 'Limited Capacity'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isAtCapacity
                                    ? Colors.red
                                    : (canApproveAll
                                        ? Colors.green
                                        : Colors.orange),
                              ),
                            ),
                          ),
                          Text(
                            '${widget.group.membersUIDs.length}/${GroupModel.MAX_MEMBERS}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isAtCapacity
                                  ? Colors.red
                                  : (canApproveAll
                                      ? Colors.green
                                      : Colors.orange),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: widget.group.getMemberCapacityPercentage(),
                          backgroundColor: theme.surfaceVariantColor,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isAtCapacity
                                ? Colors.red
                                : (canApproveAll ? Colors.green : Colors.orange),
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAtCapacity
                            ? 'The group has reached its maximum member limit of ${GroupModel.MAX_MEMBERS}. You need to remove some members before approving new requests.'
                            : (canApproveAll
                                ? 'You have enough space for all ${_pendingUsers.length} pending requests. $remainingSlots ${remainingSlots == 1 ? 'slot' : 'slots'} will remain after approval.'
                                : 'You have ${_pendingUsers.length} pending requests but only $remainingSlots ${remainingSlots == 1 ? 'slot' : 'slots'} available. Please approve selectively.'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isAtCapacity
                              ? Colors.red.shade700
                              : (canApproveAll
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                ),

                // Pending requests list or empty message
                Expanded(
                  child: _pendingUsers.isEmpty
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
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final user = _pendingUsers[index];
                            final isProcessing = _processingStatus[user.uid] == true;
                            
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
                                        if (isProcessing) 
                                          const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        else ...[
                                          IconButton(
                                            icon: const Icon(
                                              Icons.check_circle_outline,
                                              color: Colors.green,
                                              size: 28,
                                            ),
                                            tooltip: 'Approve',
                                            onPressed: isAtCapacity 
                                                ? null // Disable if at capacity
                                                : () => _approveRequest(user),
                                            color: isAtCapacity ? Colors.grey : null,
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.cancel_outlined,
                                              color: Colors.red,
                                              size: 28,
                                            ),
                                            tooltip: 'Reject',
                                            onPressed: () => _rejectRequest(user),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
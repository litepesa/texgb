import 'package:flutter/material.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/providers/group_provider.dart';
import 'package:textgb/utilities/global_methods.dart';

class GroupStatusWidget extends StatelessWidget {
  const GroupStatusWidget({
    Key? key,
    required this.isAdmin,
    required this.groupProvider,
  }) : super(key: key);

  final bool isAdmin;
  final GroupProvider groupProvider;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Group Type Indicator (Private/Public)
        _buildGroupTypeIndicator(context),
        const SizedBox(width: 10),
        // Pending Request Indicator (if admin and there are pending requests)
        if (isAdmin && groupProvider.groupModel.awaitingApprovalUIDs.isNotEmpty)
          _buildPendingRequestsButton(context),
      ],
    );
  }

  Widget _buildGroupTypeIndicator(BuildContext context) {
    final bool isPrivate = groupProvider.groupModel.isPrivate;
    final String typeText = isPrivate ? 'Private' : 'Public';
    final Color typeColor = isPrivate ? Colors.deepPurple : Colors.blue;
    final Color disabledColor = Colors.grey;

    return InkWell(
      onTap: !isAdmin
          ? null
          : () => _showChangeTypeDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isAdmin ? typeColor : disabledColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPrivate ? Icons.lock : Icons.public,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              typeText,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequestsButton(BuildContext context) {
    final int pendingCount = groupProvider.groupModel.awaitingApprovalUIDs.length;

    return InkWell(
      onTap: () => _navigateToPendingRequests(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
        ),
        child: Stack(
          children: [
            const Icon(
              Icons.person_add,
              color: Colors.white,
              size: 18,
            ),
            if (pendingCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    pendingCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showChangeTypeDialog(BuildContext context) {
    showMyAnimatedDialog(
      context: context,
      title: 'Change Group Type',
      content: groupProvider.groupModel.isPrivate
          ? 'Change this group to Public? Anyone will be able to find and join this group.'
          : 'Change this group to Private? Only people you add or approve will be able to join.',
      textAction: 'Change',
      onActionTap: (value) {
        if (value) {
          groupProvider.changeGroupType();
        }
      },
    );
  }

  void _navigateToPendingRequests(BuildContext context) {
    Navigator.pushNamed(
      context,
      Constants.groupMemberRequestsScreen,
      arguments: {
        'groupId': groupProvider.groupModel.groupId,
      },
    );
  }
}
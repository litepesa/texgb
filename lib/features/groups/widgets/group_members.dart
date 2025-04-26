import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/groups/group_provider.dart';

class GroupMembers extends StatelessWidget {
  const GroupMembers({
    super.key,
    required this.membersUIDs,
  });

  final List<String> membersUIDs;

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthenticationProvider>().userModel!.uid;
    
    return StreamBuilder(
      stream: context
          .read<GroupProvider>()
          .streamGroupMembersData(membersUIDs: membersUIDs),
      builder: (context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading members',
              style: TextStyle(fontSize: 12, color: Colors.grey));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading members...',
              style: TextStyle(fontSize: 12, color: Colors.grey));
        }

        final members = snapshot.data;
        if (members == null || members.isEmpty) {
          return const Text('No members',
              style: TextStyle(fontSize: 12, color: Colors.grey));
        }

        // Get a list of names
        final List<String> names = [];
        // Loop through the members
        for (var member in members) {
          if (member.data() == null) continue;
          
          final Map<String, dynamic> memberData = member.data() as Map<String, dynamic>;
          final String memberName = memberData[Constants.name] ?? 'Unknown';
          final String memberId = memberData[Constants.uid] ?? '';
          
          // Replace current user's name with "You"
          names.add(memberId == currentUserId ? 'You' : memberName);
        }

        return Text(
          _formatMemberNames(names),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        );
      },
    );
  }
  
  String _formatMemberNames(List<String> names) {
    if (names.isEmpty) return 'No members';
    if (names.length == 1) return names.first;
    if (names.length == 2) return '${names[0]} and ${names[1]}';
    
    return '${names[0]}, ${names[1]} and ${names.length - 2} more';
  }
}
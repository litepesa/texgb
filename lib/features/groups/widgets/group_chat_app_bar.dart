import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/groups/group_model.dart';
import 'package:textgb/features/groups/group_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/features/groups/widgets/group_members.dart';

class GroupChatAppBar extends StatelessWidget {
  const GroupChatAppBar({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: context.read<GroupProvider>().groupStream(groupId: groupId),
      builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final groupModel = GroupModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);

        return GestureDetector(
          onTap: () {
            // Navigate to group information screen
            context.read<GroupProvider>()
                .setGroupModel(groupModel: groupModel)
                .whenComplete(() {
              context.read<GroupProvider>().updateGroupMembersList();
              context.read<GroupProvider>().updateGroupAdminsList();
              Navigator.pushNamed(context, Constants.groupInformationScreen);
            });
          },
          child: Row(
            children: [
              userImageWidget(
                imageUrl: groupModel.groupImage,
                radius: 20,
                onTap: () {
                  // Navigate to group information screen
                  context.read<GroupProvider>()
                      .setGroupModel(groupModel: groupModel)
                      .whenComplete(() {
                    context.read<GroupProvider>().updateGroupMembersList();
                    context.read<GroupProvider>().updateGroupAdminsList();
                    Navigator.pushNamed(context, Constants.groupInformationScreen);
                  });
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupModel.groupName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    GroupMembers(membersUIDs: groupModel.membersUIDs),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
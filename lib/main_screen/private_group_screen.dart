import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/group_model.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/providers/group_provider.dart';
import 'package:textgb/widgets/chat_widget.dart';

class PrivateGroupScreen extends StatefulWidget {
  const PrivateGroupScreen({super.key});

  @override
  State<PrivateGroupScreen> createState() => _PrivateGroupScreenState();
}

class _PrivateGroupScreenState extends State<PrivateGroupScreen> {
  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthenticationProvider>().userModel!.uid;
    return SafeArea(
        child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CupertinoSearchTextField(
            onChanged: (value) {},
          ),
        ),

        // stream builder for private groups
        StreamBuilder<List<GroupModel>>(
          stream:
              context.read<GroupProvider>().getPrivateGroupsStream(userId: uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return const Center(
                child: Text('Something went wrong'),
              );
            }
            if (snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No private groups'),
              );
            }
            return Expanded(
              child: ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final groupModel = snapshot.data![index];
                  return ChatWidget(
                      group: groupModel,
                      isGroup: true,
                      onTap: () {
                        context
                            .read<GroupProvider>()
                            .setGroupModel(groupModel: groupModel)
                            .whenComplete(() {
                          Navigator.pushNamed(
                            context,
                            Constants.chatScreen,
                            arguments: {
                              Constants.contactUID: groupModel.groupId,
                              Constants.contactName: groupModel.groupName,
                              Constants.contactImage: groupModel.groupImage,
                              Constants.groupId: groupModel.groupId,
                            },
                          );
                        });
                      });
                },
              ),
            );
          },
        )
      ],
    ));
  }
}

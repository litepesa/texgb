import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/groups/group_model.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/groups/group_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';
import 'package:textgb/features/contacts/widgets/contact_list.dart';
import 'package:textgb/widgets/display_user_image.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  // group name controller
  final TextEditingController groupNameController = TextEditingController();
  // group description controller
  final TextEditingController groupDescriptionController =
      TextEditingController();
  File? finalFileImage;
  String _searchQuery = '';

  void selectImage(bool fromCamera) async {
    finalFileImage = await pickImage(
      fromCamera: fromCamera,
      onFail: (String message) {
        showSnackBar(context, message);
      },
    );

    // crop image
    await cropImage(finalFileImage?.path);

    popContext();
  }

  popContext() {
    Navigator.pop(context);
  }

  Future<void> cropImage(filePath) async {
    if (filePath != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: filePath,
        maxHeight: 800,
        maxWidth: 800,
        compressQuality: 90,
      );

      if (croppedFile != null) {
        setState(() {
          finalFileImage = File(croppedFile.path);
        });
      }
    }
  }

  void showBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              onTap: () {
                selectImage(true);
              },
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
            ),
            ListTile(
              onTap: () {
                selectImage(false);
              },
              leading: const Icon(Icons.image),
              title: const Text('Gallery'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    groupNameController.dispose();
    groupDescriptionController.dispose();
    super.dispose();
  }

  // create group
  void createGroup() {
    final uid = context.read<AuthenticationProvider>().userModel!.uid;
    final groupProvider = context.read<GroupProvider>();
    
    // check if the group name is empty
    if (groupNameController.text.isEmpty) {
      showSnackBar(context, 'Please enter group name');
      return;
    }

    // name is less than 3 characters
    if (groupNameController.text.length < 3) {
      showSnackBar(context, 'Group name must be at least 3 characters');
      return;
    }

    // check if the group description is empty
    if (groupDescriptionController.text.isEmpty) {
      showSnackBar(context, 'Please enter group description');
      return;
    }
    
    // Check if any members are selected
    if (groupProvider.getGroupMembersUIDs().isEmpty) {
      showSnackBar(context, 'Please add at least one member to the group');
      return;
    }

    GroupModel groupModel = GroupModel(
      creatorUID: uid,
      groupName: groupNameController.text,
      groupDescription: groupDescriptionController.text,
      groupImage: '',
      groupId: '',
      lastMessage: '',
      senderUID: '',
      messageType: MessageEnum.text,
      messageId: '',
      timeSent: DateTime.now(),
      createdAt: DateTime.now(),
      onlyAdminsCanSendMessages: false,
      onlyAdminsCanEditInfo: true,
      membersUIDs: [],
      adminsUIDs: [],
    );

    // create group
    groupProvider.createGroup(
      newGroupModel: groupModel,
      fileImage: finalFileImage,
      onSuccess: () {
        showSnackBar(context, 'Group created successfully');
        Navigator.pop(context);
      },
      onFail: (error) {
        showSnackBar(context, error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<GroupProvider>().isLoading;
    
    return Scaffold(
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Group'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: isLoading
                ? const CircularProgressIndicator()
                : IconButton(
                    onPressed: createGroup,
                    icon: const Icon(Icons.check),
                  ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group image and basic info
              Center(
                child: Column(
                  children: [
                    DisplayUserImage(
                      finalFileImage: finalFileImage,
                      radius: 60,
                      onPressed: showBottomSheet,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tap to add a group icon',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Group name field
              TextField(
                controller: groupNameController,
                maxLength: 25,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Group Name',
                  label: Text('Group Name'),
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Group description field
              TextField(
                controller: groupDescriptionController,
                maxLength: 100,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'Group Description',
                  label: Text('Group Description'),
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              
              // Participants section
              const Text(
                'Add Participants',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Search bar for filtering contacts
              CupertinoSearchTextField(
                placeholder: 'Search contacts',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.black,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Selected participants count
              Consumer<GroupProvider>(
                builder: (context, provider, _) {
                  final count = provider.groupMembersList.length;
                  return count > 0
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Selected participants: $count',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.blue,
                            ),
                          ),
                        )
                      : const SizedBox.shrink();
                },
              ),
              
              // List of contacts to add to the group
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ContactList(
                  viewType: ContactViewType.groupView,
                  searchQuery: _searchQuery,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/groups/group_provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';
import 'package:image_cropper/image_cropper.dart';

class GroupInformationScreen extends StatefulWidget {
  const GroupInformationScreen({super.key});

  @override
  State<GroupInformationScreen> createState() => _GroupInformationScreenState();
}

class _GroupInformationScreenState extends State<GroupInformationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? finalFileImage;
  bool _isEditingName = false;
  bool _isEditingDescription = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize controllers with current group data
      final groupModel = context.read<GroupProvider>().groupModel;
      _nameController.text = groupModel.groupName;
      _descriptionController.text = groupModel.groupDescription;
      
      // Fetch group members and admins data
      context.read<GroupProvider>().updateGroupMembersList();
      context.read<GroupProvider>().updateGroupAdminsList();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void selectImage(bool fromCamera) async {
    finalFileImage = await pickImage(
      fromCamera: fromCamera,
      onFail: (String message) {
        showSnackBar(context, message);
      },
    );

    // crop image
    if (finalFileImage != null) {
      await cropImage(finalFileImage?.path);
      
      // Update group image
      if (finalFileImage != null) {
        setState(() {
          _isUpdating = true;
        });
        
        try {
          await context.read<GroupProvider>().updateGroupInfo(
            groupImage: finalFileImage,
          );
          if (mounted) {
            showSnackBar(context, 'Group image updated successfully');
          }
        } catch (e) {
          if (mounted) {
            showSnackBar(context, 'Failed to update group image: $e');
          }
        } finally {
          setState(() {
            _isUpdating = false;
          });
        }
      }
    }

    popContext();
  }

  popContext() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
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

  void showImageBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserUid = context.read<AuthenticationProvider>().userModel!.uid;

    return Consumer<GroupProvider>(
      builder: (context, groupProvider, child) {
        final group = groupProvider.groupModel;
        final bool isAdmin = group.adminsUIDs.contains(currentUserUid);
        final bool isCreator = group.creatorUID == currentUserUid;
        final bool canEditInfo = isAdmin && (group.onlyAdminsCanEditInfo ? true : !group.onlyAdminsCanEditInfo);
        
        return Scaffold(
          appBar: AppBar(
            leading: AppBarBackButton(onPressed: () => Navigator.pop(context)),
            title: const Text('Group Info'),
            centerTitle: true,
            actions: [
              if (isAdmin)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'settings') {
                      Navigator.pushNamed(context, Constants.groupSettingsScreen);
                    } else if (value == 'delete' && isCreator) {
                      _showDeleteGroupDialog();
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings),
                          SizedBox(width: 8),
                          Text('Group settings'),
                        ],
                      ),
                    ),
                    if (isCreator)
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete group', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
          body: groupProvider.isLoading || _isUpdating
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group image
                      GestureDetector(
                        onTap: canEditInfo ? showImageBottomSheet : null,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey.shade200,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (group.groupImage.isNotEmpty)
                                Image.network(
                                  group.groupImage,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              if (canEditInfo)
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Group name
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _isEditingName && canEditInfo
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Group Name',
                                      border: OutlineInputBorder(),
                                    ),
                                    maxLength: 25,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _nameController.text = group.groupName;
                                            _isEditingName = false;
                                          });
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          if (_nameController.text.trim().isEmpty) {
                                            showSnackBar(context, 'Group name cannot be empty');
                                            return;
                                          }
                                          
                                          setState(() {
                                            _isUpdating = true;
                                          });
                                          
                                          try {
                                            await groupProvider.updateGroupInfo(
                                              groupName: _nameController.text.trim(),
                                            );
                                            if (mounted) {
                                              setState(() {
                                                _isEditingName = false;
                                                _isUpdating = false;
                                              });
                                            }
                                          } catch (e) {
                                            showSnackBar(context, 'Failed to update group name: $e');
                                            setState(() {
                                              _isUpdating = false;
                                            });
                                          }
                                        },
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      group.groupName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (canEditInfo)
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        setState(() {
                                          _isEditingName = true;
                                        });
                                      },
                                    ),
                                ],
                              ),
                      ),
                      
                      // Group description
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _isEditingDescription && canEditInfo
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: _descriptionController,
                                    decoration: const InputDecoration(
                                      labelText: 'Group Description',
                                      border: OutlineInputBorder(),
                                    ),
                                    maxLength: 100,
                                    maxLines: 3,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _descriptionController.text = group.groupDescription;
                                            _isEditingDescription = false;
                                          });
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          setState(() {
                                            _isUpdating = true;
                                          });
                                          
                                          try {
                                            await groupProvider.updateGroupInfo(
                                              groupDescription: _descriptionController.text.trim(),
                                            );
                                            if (mounted) {
                                              setState(() {
                                                _isEditingDescription = false;
                                                _isUpdating = false;
                                              });
                                            }
                                          } catch (e) {
                                            showSnackBar(context, 'Failed to update description: $e');
                                            setState(() {
                                              _isUpdating = false;
                                            });
                                          }
                                        },
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      group.groupDescription,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  if (canEditInfo)
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        setState(() {
                                          _isEditingDescription = true;
                                        });
                                      },
                                    ),
                                ],
                              ),
                      ),
                      
                      const Divider(height: 32),
                      
                      // Group Members
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${group.membersUIDs.length} ${group.membersUIDs.length == 1 ? 'member' : 'members'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (isAdmin)
                              TextButton.icon(
                                onPressed: () {
                                  showAddMembersBottomSheet(
                                    context: context,
                                    groupMembersUIDs: group.membersUIDs,
                                  );
                                },
                                icon: const Icon(Icons.person_add_alt_1, size: 16),
                                label: const Text('Add'),
                              ),
                          ],
                        ),
                      ),
                      
                      // List of members
                      FutureBuilder<List<UserModel>>(
                        future: groupProvider.getGroupMembersDataFromFirestore(isAdmin: false),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          final members = snapshot.data ?? [];
                          
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: members.length,
                            itemBuilder: (context, index) {
                              final member = members[index];
                              final bool isMemberAdmin = group.adminsUIDs.contains(member.uid);
                              final bool isSelf = member.uid == currentUserUid;
                              
                              return ListTile(
                                leading: userImageWidget(
                                  imageUrl: member.image,
                                  radius: 20,
                                  onTap: () {},
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isSelf ? 'You' : member.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (member.uid == group.creatorUID)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          'Creator',
                                          style: TextStyle(color: Colors.white, fontSize: 10),
                                        ),
                                      )
                                    else if (isMemberAdmin)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          'Admin',
                                          style: TextStyle(color: Colors.white, fontSize: 10),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text(member.phoneNumber),
                                trailing: isAdmin && !isSelf
                                    ? PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'remove') {
                                            _showRemoveMemberDialog(member);
                                          } else if (value == 'make_admin') {
                                            _showMakeAdminDialog(member);
                                          } else if (value == 'remove_admin') {
                                            _showRemoveAdminDialog(member);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          if (isAdmin && !isMemberAdmin)
                                            const PopupMenuItem(
                                              value: 'make_admin',
                                              child: Text('Make admin'),
                                            ),
                                          if (isAdmin && isMemberAdmin && member.uid != group.creatorUID)
                                            const PopupMenuItem(
                                              value: 'remove_admin',
                                              child: Text('Remove as admin'),
                                            ),
                                          const PopupMenuItem(
                                            value: 'remove',
                                            child: Text('Remove from group', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      )
                                    : null,
                              );
                            },
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Exit Group button
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: ElevatedButton.icon(
                            onPressed: _showExitGroupDialog,
                            icon: const Icon(Icons.exit_to_app, color: Colors.red),
                            label: const Text('Exit Group', style: TextStyle(color: Colors.red)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 0,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        );
      },
    );
  }
  
  void _showDeleteGroupDialog() {
    showMyAnimatedDialog(
      context: context,
      title: 'Delete Group',
      content: 'Are you sure you want to delete this group? This action cannot be undone.',
      textAction: 'Delete',
      onActionTap: (value) async {
        if (value) {
          try {
            final groupId = context.read<GroupProvider>().groupModel.groupId;
            await context.read<GroupProvider>().deleteGroup(groupId: groupId);
            if (mounted) {
              Navigator.popUntil(context, (route) => route.isFirst);
              showSnackBar(context, 'Group deleted successfully');
            }
          } catch (e) {
            if (mounted) {
              showSnackBar(context, 'Failed to delete group: $e');
            }
          }
        }
      },
    );
  }
  
  void _showRemoveMemberDialog(UserModel member) {
    showMyAnimatedDialog(
      context: context,
      title: 'Remove Member',
      content: 'Are you sure you want to remove ${member.name} from the group?',
      textAction: 'Remove',
      onActionTap: (value) async {
        if (value) {
          try {
            await context.read<GroupProvider>().removeGroupMember(groupMember: member);
            if (mounted) {
              showSnackBar(context, '${member.name} removed from the group');
            }
          } catch (e) {
            if (mounted) {
              showSnackBar(context, 'Failed to remove member: $e');
            }
          }
        }
      },
    );
  }
  
  void _showMakeAdminDialog(UserModel member) {
    showMyAnimatedDialog(
      context: context,
      title: 'Make Admin',
      content: 'Make ${member.name} an admin? Admins can add or remove members, change group info, and more.',
      textAction: 'Make Admin',
      onActionTap: (value) async {
        if (value) {
          try {
            context.read<GroupProvider>().addMemberToAdmins(groupAdmin: member);
            if (mounted) {
              showSnackBar(context, '${member.name} is now an admin');
            }
          } catch (e) {
            if (mounted) {
              showSnackBar(context, 'Failed to make admin: $e');
            }
          }
        }
      },
    );
  }
  
  void _showRemoveAdminDialog(UserModel member) {
    showMyAnimatedDialog(
      context: context,
      title: 'Remove Admin',
      content: 'Remove ${member.name} as an admin? They will still be a member of the group.',
      textAction: 'Remove as Admin',
      onActionTap: (value) async {
        if (value) {
          try {
            context.read<GroupProvider>().removeGroupAdmin(groupAdmin: member);
            if (mounted) {
              showSnackBar(context, '${member.name} is no longer an admin');
            }
          } catch (e) {
            if (mounted) {
              showSnackBar(context, 'Failed to remove admin: $e');
            }
          }
        }
      },
    );
  }
  
  void _showExitGroupDialog() {
    final uid = context.read<AuthenticationProvider>().userModel!.uid;
    final isCreator = context.read<GroupProvider>().groupModel.creatorUID == uid;
    
    showMyAnimatedDialog(
      context: context,
      title: 'Exit Group',
      content: isCreator 
          ? 'You are the creator of this group. If you exit, admin permissions will be transferred to another member.'
          : 'Are you sure you want to exit this group?',
      textAction: 'Exit',
      onActionTap: (value) async {
        if (value) {
          try {
            await context.read<GroupProvider>().exitGroup(uid: uid);
            if (mounted) {
              Navigator.popUntil(context, (route) => route.isFirst);
              showSnackBar(context, 'You have left the group');
            }
          } catch (e) {
            if (mounted) {
              showSnackBar(context, 'Failed to exit group: $e');
            }
          }
        }
      },
    );
  }
}
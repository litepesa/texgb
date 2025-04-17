import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/group_model.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/providers/group_provider.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:textgb/widgets/chat_widget.dart';
import 'package:textgb/widgets/group_search_bar.dart';

class PublicGroupScreen extends StatefulWidget {
  const PublicGroupScreen({super.key});

  @override
  State<PublicGroupScreen> createState() => _PublicGroupScreenState();
}

class _PublicGroupScreenState extends State<PublicGroupScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthenticationProvider>().userModel!.uid;
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    
    return SafeArea(
      child: Column(
        children: [
          // Enhanced search bar component
          GroupSearchBar(
            controller: _searchController,
            placeholder: 'Search public groups',
            showResults: _isSearching,
            searchQuery: _searchQuery,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _isSearching = value.isNotEmpty;
              });
            },
            onClear: () {
              setState(() {
                _searchQuery = '';
                _isSearching = false;
              });
            },
          ),

          // Stream builder for public groups
          StreamBuilder<List<GroupModel>>(
            stream: context.read<GroupProvider>().getPublicGroupsStream(userId: uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              if (snapshot.hasError) {
                return Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: TextStyle(
                            fontSize: 16,
                            color: themeExtension?.greyColor ?? Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              // Filter groups based on search query
              final groups = snapshot.data ?? [];
              final filteredGroups = _searchQuery.isEmpty 
                  ? groups 
                  : groups.where((group) => 
                      group.groupName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      group.groupDescription.toLowerCase().contains(_searchQuery.toLowerCase())
                    ).toList();
              
              if (filteredGroups.isEmpty) {
                return Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty ? Icons.public : Icons.search_off,
                          size: 64,
                          color: themeExtension?.greyColor?.withOpacity(0.5) ?? Colors.grey.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty 
                              ? 'No public groups' 
                              : 'No matches found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: themeExtension?.greyColor ?? Colors.grey,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Try a different search term',
                              style: TextStyle(
                                fontSize: 14,
                                color: themeExtension?.greyColor ?? Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }
              
              // List of groups
              return Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    // Implement refresh logic if needed
                    await Future.delayed(const Duration(milliseconds: 800));
                  },
                  child: ListView.builder(
                    itemCount: filteredGroups.length,
                    itemBuilder: (context, index) {
                      final groupModel = filteredGroups[index];
                      return ChatWidget(
                        group: groupModel,
                        isGroup: true,
                        onTap: () {
                          // Check if user is already a member of the group
                          if (groupModel.membersUIDs.contains(uid)) {
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
                            return;
                          }

                          // Check if request to join settings is enabled
                          if (groupModel.requestToJoing) {
                            // Check if user has already requested to join the group
                            if (groupModel.awaitingApprovalUIDs.contains(uid)) {
                              showSnackBar(context, 'Request already sent');
                              return;
                            }

                            // Show animation to join group to request to join
                            showMyAnimatedDialog(
                              context: context,
                              title: 'Request to join',
                              content:
                                  'You need to request to join this group, before you can view the group content',
                              textAction: 'Request to join',
                              onActionTap: (value) async {
                                // Send request to join group
                                if (value) {
                                  await context
                                      .read<GroupProvider>()
                                      .sendRequestToJoinGroup(
                                        groupId: groupModel.groupId,
                                        uid: uid,
                                        groupName: groupModel.groupName,
                                        groupImage: groupModel.groupImage,
                                      )
                                      .whenComplete(() {
                                    showSnackBar(context, 'Request sent');
                                  });
                                }
                              },
                            );
                            return;
                          }

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
                        },
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
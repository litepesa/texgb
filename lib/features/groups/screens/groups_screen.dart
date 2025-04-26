import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/groups/group_model.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/groups/group_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/features/chat/widgets/chat_widget.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
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
    try {
      final uid = context.read<AuthenticationProvider>().userModel?.uid;
      
      // If user is not logged in or no UID, show a message
      if (uid == null) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Unable to load user data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      // Refresh the screen
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }
      
      final modernTheme = context.modernTheme;
      
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Search bar (when searching)
              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search groups',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                            _isSearching = false;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),

              // Groups list
              Expanded(
                child: FutureBuilder<bool>(
                  // A simple future to check if we can proceed
                  future: Future.value(true),
                  builder: (context, connectionSnapshot) {
                    if (!connectionSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    return StreamBuilder<List<GroupModel>>(
                      stream: context.read<GroupProvider>().getUserGroupsStream(userId: uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'Error: ${snapshot.error}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: modernTheme.textSecondaryColor ?? Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      // Refresh the screen
                                    });
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
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
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchQuery.isEmpty ? Icons.group : Icons.search_off,
                                  size: 64,
                                  color: modernTheme.textSecondaryColor?.withOpacity(0.5) ?? Colors.grey.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty 
                                      ? 'No groups yet' 
                                      : 'No matches found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: modernTheme.textSecondaryColor ?? Colors.grey,
                                  ),
                                ),
                                if (_searchQuery.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12.0),
                                    child: TextButton.icon(
                                      onPressed: () {
                                        context.read<GroupProvider>().clearGroupData();
                                        Navigator.pushNamed(
                                          context,
                                          Constants.createGroupScreen,
                                        );
                                      },
                                      icon: const Icon(Icons.add_circle),
                                      label: const Text('Create a new group'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.blue,
                                      ),
                                    ),
                                  ),
                                if (_searchQuery.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'Try a different search term',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: modernTheme.textSecondaryColor ?? Colors.grey,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }
                        
                        // List of groups
                        return ListView.builder(
                          itemCount: filteredGroups.length,
                          itemBuilder: (context, index) {
                            final groupModel = filteredGroups[index];
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
                              },
                            );
                          },
                        );
                      },
                    );
                  }
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.read<GroupProvider>().clearGroupData();
            Navigator.pushNamed(
              context,
              Constants.createGroupScreen,
            );
          },
          child: const Icon(Icons.group_add),
        ),
      );
    } catch (e, stackTrace) {
      // Fallback error handler - if anything fails, show error info
      return Scaffold(
        appBar: AppBar(
          title: const Text("Groups"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Error: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    // Refresh the screen
                  });
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
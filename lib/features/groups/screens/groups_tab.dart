// lib/features/groups/screens/groups_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/groups/providers/group_provider.dart';
import 'package:textgb/features/groups/widgets/group_tile.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class GroupsTab extends ConsumerStatefulWidget {
  const GroupsTab({super.key});

  @override
  ConsumerState<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends ConsumerState<GroupsTab> {
  final TextEditingController _searchController = TextEditingController();
  List<GroupModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Perform search
  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final results = await ref.read(groupProvider.notifier).searchGroups(query);
    
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  // Calculate total unread count for groups tab badge
  int _calculateTotalUnreadCount(List<GroupModel> groups) {
    final currentUserUid = ref.read(groupProvider.notifier).getCurrentUserUid();
    if (currentUserUid == null) return 0;
    
    return groups.fold<int>(
      0, 
      (sum, group) => sum + group.getUnreadCountForUser(currentUserUid)
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    final userGroupsAsync = ref.watch(userGroupsStreamProvider);
    
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search groups...',
                prefixIcon: Icon(Icons.search, color: theme.textSecondaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.borderColor!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.borderColor!),
                ),
                filled: true,
                fillColor: theme.surfaceColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: _performSearch,
            ),
          ),
          
          // Main content
          Expanded(
            child: _searchController.text.isNotEmpty
                ? _buildSearchResults()
                : _buildUserGroups(userGroupsAsync),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.pushNamed(context, Constants.createGroupScreen);
        },
        child: const Icon(Icons.group_add),
      ),
    );
  }

  Widget _buildUserGroups(AsyncValue<List<GroupModel>> userGroupsAsync) {
    return userGroupsAsync.when(
      data: (userGroups) {
        if (userGroups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.group_outlined, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No groups yet',
                  style: TextStyle(
                    color: context.modernTheme.textColor,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a new group or join an existing one',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.modernTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, Constants.createGroupScreen);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Group'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.modernTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: userGroups.length,
          itemBuilder: (context, index) {
            final group = userGroups[index];
            return GroupTile(
              group: group,
              onTap: () {
                // Open group chat instead of group info
                ref.read(groupProvider.notifier).openGroupChat(group, context);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Text(
          'Error loading groups: $e',
          style: TextStyle(color: context.modernTheme.textColor),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          'No groups found',
          style: TextStyle(color: context.modernTheme.textColor),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final group = _searchResults[index];
        return GroupTile(
          group: group,
          onTap: () {
            // Open group chat instead of group info
            ref.read(groupProvider.notifier).openGroupChat(group, context);
          },
        );
      },
    );
  }
}
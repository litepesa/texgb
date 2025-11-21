// lib/features/groups/screens/groups_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/groups/providers/groups_providers.dart';
import 'package:textgb/features/groups/widgets/group_tile.dart';
import 'package:textgb/features/groups/screens/create_group_screen.dart';
import 'package:textgb/features/groups/screens/group_chat_screen.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class GroupsListScreen extends ConsumerStatefulWidget {
  const GroupsListScreen({super.key});

  @override
  ConsumerState<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends ConsumerState<GroupsListScreen>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();

    // Listen to search focus changes
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearching = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final modernTheme = context.modernTheme;
    final groupsAsync = ref.watch(groupsListProvider);

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
          _clearSearch();
        }
      },
      child: Scaffold(
        backgroundColor: modernTheme.surfaceColor,
        body: Column(
          children: [
            // Search bar
            _buildSearchBar(modernTheme),

            // Groups list
            Expanded(
              child: groupsAsync.when(
        data: (groups) {
          // Filter groups based on search
          final filteredGroups = _searchController.text.isEmpty
              ? groups
              : groups
                  .where((g) =>
                      g.name
                          .toLowerCase()
                          .contains(_searchController.text.toLowerCase()) ||
                      g.description
                          .toLowerCase()
                          .contains(_searchController.text.toLowerCase()))
                  .toList();

          if (filteredGroups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: (modernTheme.primaryColor ?? const Color(0xFF07C160)).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.group_solid,
                      size: 64,
                      color: modernTheme.primaryColor ?? const Color(0xFF07C160),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _searchController.text.isEmpty
                        ? 'No Groups'
                        : 'No Results',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: modernTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchController.text.isEmpty
                        ? 'Create your first group to get started'
                        : 'No groups match "${_searchController.text}"',
                    style: TextStyle(
                      fontSize: 14,
                      color: modernTheme.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(groupsListProvider.notifier).refresh();
            },
            color: modernTheme.primaryColor ?? const Color(0xFF07C160),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 0, bottom: 100),
              itemCount: filteredGroups.length,
              itemBuilder: (context, index) {
                final group = filteredGroups[index];
                return GroupTile(
                  group: group,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupChatScreen(groupId: group.id),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              modernTheme.primaryColor ?? const Color(0xFF07C160),
            ),
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 64,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Failed to load groups',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: modernTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Please check your internet connection',
                  style: TextStyle(
                    fontSize: 14,
                    color: modernTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(groupsListProvider);
                },
                icon: const Icon(CupertinoIcons.refresh, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: modernTheme.primaryColor ?? const Color(0xFF07C160),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: modernTheme.backgroundColor?.withOpacity(0.6),
        border: Border(
          bottom: BorderSide(
            color: (modernTheme.dividerColor ?? Colors.grey).withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: TextStyle(color: modernTheme.textColor),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: modernTheme.textSecondaryColor),
                prefixIcon: Icon(
                  CupertinoIcons.search,
                  color: modernTheme.textSecondaryColor,
                  size: 20,
                ),
                filled: true,
                fillColor: modernTheme.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onChanged: (query) => setState(() {}),
            ),
          ),
          if (_isSearching) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: _clearSearch,
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: modernTheme.primaryColor ?? const Color(0xFF07C160),
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
// ===============================
// Contact Selector Screen
// Select contacts for custom privacy
// Uses GoRouter for navigation
// ===============================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/features/moments/theme/moments_theme.dart';

enum ContactSelectorMode {
  visibleTo, // Select who can see
  hiddenFrom, // Select who cannot see
}

class ContactSelectorScreen extends ConsumerStatefulWidget {
  final ContactSelectorMode mode;
  final List<String> initialSelectedIds;

  const ContactSelectorScreen({
    super.key,
    required this.mode,
    this.initialSelectedIds = const [],
  });

  @override
  ConsumerState<ContactSelectorScreen> createState() => _ContactSelectorScreenState();
}

class _ContactSelectorScreenState extends ConsumerState<ContactSelectorScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  List<UserModel> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _selectedUserIds.addAll(widget.initialSelectedIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authenticationProvider);
    final users = authState.value?.users ?? [];

    // Filter users based on search
    _filteredUsers = users.where((user) {
      final query = _searchController.text.toLowerCase();
      if (query.isEmpty) return true;
      return user.name.toLowerCase().contains(query) ||
          user.phoneNumber.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mode == ContactSelectorMode.visibleTo
              ? 'Who can see this'
              : 'Who cannot see this',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(_selectedUserIds.toList()),
            child: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Selected count
          if (_selectedUserIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: MomentsTheme.primaryBlue.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: MomentsTheme.primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedUserIds.length} selected',
                    style: TextStyle(
                      color: MomentsTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _selectedUserIds.clear()),
                    child: const Text('Clear all'),
                  ),
                ],
              ),
            ),

          // User list
          Expanded(
            child: _filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'No contacts found'
                              : 'No results for "${_searchController.text}"',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final isSelected = _selectedUserIds.contains(user.uid);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: CachedNetworkImageProvider(user.profileImage),
                          radius: 24,
                        ),
                        title: Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(user.phoneNumber),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedUserIds.add(user.uid);
                              } else {
                                _selectedUserIds.remove(user.uid);
                              }
                            });
                          },
                          activeColor: MomentsTheme.primaryBlue,
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedUserIds.remove(user.uid);
                            } else {
                              _selectedUserIds.add(user.uid);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

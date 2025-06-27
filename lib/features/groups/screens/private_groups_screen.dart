// lib/features/groups/screens/private_groups_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/groups/providers/group_provider.dart';
import 'package:textgb/features/groups/widgets/group_tile.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/models/user_model.dart';

// Provider to filter only group chats from the chat stream
final groupChatStreamProvider = Provider<AsyncValue<List<ChatModel>>>((ref) {
  final allChats = ref.watch(chatStreamProvider);
  
  return allChats.when(
    data: (chats) => AsyncValue.data(chats.where((chat) => chat.isGroup).toList()),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

class PrivateGroupsScreen extends ConsumerStatefulWidget {
  const PrivateGroupsScreen({super.key});

  @override
  ConsumerState<PrivateGroupsScreen> createState() => _PrivateGroupsScreenState();
}

class _PrivateGroupsScreenState extends ConsumerState<PrivateGroupsScreen>
    with AutomaticKeepAliveClientMixin {
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchActive = false;
  List<GroupModel> _searchResults = [];
  bool _isSearching = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (!_isSearchActive) {
        _searchController.clear();
        _searchQuery = '';
        _searchResults = [];
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await ref.read(groupProvider.notifier).searchGroups(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        showSnackBar(context, 'Search error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final theme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: theme.backgroundColor,
              elevation: 0,
              floating: true,
              pinned: true,
              expandedHeight: _isSearchActive ? 140 : 100,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    color: theme.backgroundColor,
                    border: Border(
                      bottom: BorderSide(
                        color: theme.dividerColor!.withOpacity(0.1),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Header Row
                          Row(
                            children: [
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: _isSearchActive
                                      ? _buildSearchField(theme)
                                      : _buildTitle(theme),
                                ),
                              ),
                              const SizedBox(width: 16),
                              _buildActionButtons(theme),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: _isSearchActive
            ? _buildSearchResults(theme)
            : _buildPrivateGroupsList(theme),
      ),
      floatingActionButton: _buildFloatingActionButton(theme),
    );
  }

  Widget _buildTitle(ModernThemeExtension theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Private Groups',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Chat with your groups',
          style: TextStyle(
            fontSize: 15,
            color: theme.textSecondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(ModernThemeExtension theme) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: theme.surfaceVariantColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search groups...',
          hintStyle: TextStyle(
            color: theme.textSecondaryColor,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: theme.textSecondaryColor,
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: TextStyle(
          color: theme.textColor,
          fontSize: 16,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _performSearch(value);
        },
      ),
    );
  }

  Widget _buildActionButtons(ModernThemeExtension theme) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.surfaceVariantColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: _toggleSearch,
            icon: Icon(
              _isSearchActive ? Icons.close_rounded : Icons.search_rounded,
              color: theme.textColor,
              size: 22,
            ),
            padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () {
              Navigator.pushNamed(context, Constants.createGroupScreen);
            },
            icon: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 22,
            ),
            padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivateGroupsList(ModernThemeExtension theme) {
    final groupChatsAsync = ref.watch(groupChatStreamProvider);
    final userGroupsAsync = ref.watch(userGroupsStreamProvider);
    
    return userGroupsAsync.when(
      data: (userGroups) {
        return groupChatsAsync.when(
          data: (groupChats) {
            final privateGroups = _combinePrivateGroups(userGroups, groupChats);
            
            if (privateGroups.isEmpty) {
              return _buildEmptyState(theme);
            }
            
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(userGroupsStreamProvider);
                ref.invalidate(groupChatStreamProvider);
              },
              color: theme.primaryColor,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                itemCount: privateGroups.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final group = privateGroups[index];
                  return GroupTile(
                    group: group,
                    onTap: () => _openGroup(group),
                  );
                },
              ),
            );
          },
          loading: () => _buildLoadingState(theme),
          error: (e, s) => _buildErrorState('Error loading group chats: $e', theme),
        );
      },
      loading: () => _buildLoadingState(theme),
      error: (e, s) => _buildErrorState('Error loading groups: $e', theme),
    );
  }

  Widget _buildSearchResults(ModernThemeExtension theme) {
    if (_isSearching) {
      return _buildLoadingState(theme);
    }

    if (_searchQuery.isEmpty) {
      return Center(
        child: Text(
          'Search for groups',
          style: TextStyle(
            color: theme.textSecondaryColor,
            fontSize: 16,
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No groups found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                color: theme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final group = _searchResults[index];
        return GroupTile(
          group: group,
          onTap: () => _openGroup(group),
        );
      },
    );
  }

  Widget _buildEmptyState(ModernThemeExtension theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.surfaceVariantColor,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.group_outlined,
                size: 56,
                color: theme.textSecondaryColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'No private groups yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Create a private group to start chatting with friends and family',
              style: TextStyle(
                fontSize: 16,
                color: theme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor!,
                    theme.primaryColor!.withOpacity(0.8),
                  ],
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, Constants.createGroupScreen);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Create Private Group',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ModernThemeExtension theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.primaryColor),
          const SizedBox(height: 16),
          Text(
            'Loading groups...',
            style: TextStyle(
              color: theme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, ModernThemeExtension theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: theme.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(userGroupsStreamProvider);
                ref.invalidate(groupChatStreamProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(ModernThemeExtension theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            theme.primaryColor!,
            theme.primaryColor!.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor!.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, Constants.createGroupScreen);
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(
          Icons.add_rounded,
          color: Colors.white,
        ),
        label: const Text(
          'Create Group',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Helper methods
  List<GroupModel> _combinePrivateGroups(
    List<GroupModel> userGroups,
    List<ChatModel> groupChats,
  ) {
    final allGroups = List<GroupModel>.from(userGroups);
    final groupIds = <String>{};
    
    for (final group in userGroups) {
      groupIds.add(group.groupId);
    }
    
    for (final chat in groupChats) {
      if (!groupIds.contains(chat.id)) {
        final group = GroupModel(
          groupId: chat.id,
          groupName: chat.contactName,
          groupDescription: '',
          groupImage: chat.contactImage,
          creatorUID: '',
          isPrivate: true,
          editSettings: false,
          approveMembers: false,
          lockMessages: false,
          requestToJoin: false,
          membersUIDs: const [],
          adminsUIDs: const [],
          awaitingApprovalUIDs: const [],
          lastMessage: chat.lastMessage,
          lastMessageSender: chat.lastMessageSender,
          lastMessageTime: chat.lastMessageTime,
          unreadCount: chat.unreadCount,
          unreadCountByUser: Map<String, int>.from(chat.unreadCountByUser),
          createdAt: '',
        );
        allGroups.add(group);
      }
    }
    
    allGroups.sort((a, b) {
      if (a.lastMessageTime.isEmpty) return 1;
      if (b.lastMessageTime.isEmpty) return -1;
      return int.parse(b.lastMessageTime).compareTo(int.parse(a.lastMessageTime));
    });
    
    return allGroups;
  }

  void _openGroup(GroupModel group) {
    ref.read(groupProvider.notifier).openGroupChat(group, context);
  }
}
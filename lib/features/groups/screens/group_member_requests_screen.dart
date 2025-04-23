import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/groups/group_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class GroupMemberRequestsScreen extends StatefulWidget {
  const GroupMemberRequestsScreen({super.key, this.groupId = ''});

  final String groupId;

  @override
  State<GroupMemberRequestsScreen> createState() => _GroupMemberRequestsScreenState();
}

class _GroupMemberRequestsScreenState extends State<GroupMemberRequestsScreen> {
  bool _isLoading = true;
  List<UserModel> _pendingRequests = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    setState(() {
      _isLoading = true;
    });

    // Get group ID from route arguments or widget
    final Map<String, dynamic> args = 
        (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ?? {};
    final String groupId = args['groupId'] ?? widget.groupId;

    if (groupId.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final groupProvider = context.read<GroupProvider>();
      final group = await groupProvider.getGroupById(groupId);
      
      if (group == null || group.awaitingApprovalUIDs.isEmpty) {
        setState(() {
          _isLoading = false;
          _pendingRequests = [];
        });
        return;
      }

      final List<UserModel> pendingUsers = [];
      for (final uid in group.awaitingApprovalUIDs) {
        final user = await _getUserById(uid);
        if (user != null) {
          pendingUsers.add(user);
        }
      }

      setState(() {
        _pendingRequests = pendingUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showSnackBar(context, 'Error loading requests: $e');
      }
    }
  }

  Future<UserModel?> _getUserById(String uid) async {
    try {
      final snapshot = await context
          .read<AuthenticationProvider>()
          .userStream(userID: uid)
          .first;
      return UserModel.fromMap(snapshot.data() as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  List<UserModel> get _filteredRequests {
    if (_searchQuery.isEmpty) return _pendingRequests;
    
    return _pendingRequests.where((user) {
      return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             user.phoneNumber.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Get group ID from route arguments or widget
    final Map<String, dynamic> args = 
        (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ?? {};
    final String groupId = args['groupId'] ?? widget.groupId;

    return Scaffold(
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text('Pending Member Requests'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Search bar
            CupertinoSearchTextField(
              placeholder: 'Search',
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

            // Request list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _pendingRequests.isEmpty
                      ? _buildEmptyState()
                      : _buildRequestList(groupId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add_disabled,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No pending requests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When people request to join this group,\nthey will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList(String groupId) {
    final filteredList = _filteredRequests;
    
    if (filteredList.isEmpty) {
      return Center(
        child: Text(
          'No results matching "$_searchQuery"',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final request = filteredList[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: ListTile(
            leading: userImageWidget(
              imageUrl: request.image,
              radius: 24,
              onTap: () {},
            ),
            title: Text(request.name),
            subtitle: Text(
              request.phoneNumber,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => _rejectRequest(groupId, request),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _approveRequest(groupId, request),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Approve'),
                ),
              ],
            ),
            onTap: () {
              // View profile
              Navigator.pushNamed(
                context,
                '/profileScreen',
                arguments: request.uid,
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _approveRequest(String groupId, UserModel user) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final groupProvider = context.read<GroupProvider>();
      await groupProvider.acceptRequestToJoinGroup(
        groupId: groupId,
        friendID: user.uid,
      );
      
      setState(() {
        _pendingRequests.removeWhere((request) => request.uid == user.uid);
        _isLoading = false;
      });
      
      if (mounted) {
        showSnackBar(context, '${user.name} has been added to the group');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showSnackBar(context, 'Error approving request: $e');
      }
    }
  }

  Future<void> _rejectRequest(String groupId, UserModel user) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final groupProvider = context.read<GroupProvider>();
      await groupProvider.rejectRequestToJoinGroup(
        groupId: groupId,
        userId: user.uid,
      );
      
      setState(() {
        _pendingRequests.removeWhere((request) => request.uid == user.uid);
        _isLoading = false;
      });
      
      if (mounted) {
        showSnackBar(context, 'Request from ${user.name} has been rejected');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showSnackBar(context, 'Error rejecting request: $e');
      }
    }
  }
}
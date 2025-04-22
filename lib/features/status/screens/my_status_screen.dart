import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/features/status/screens/status_detail_screen.dart';
import 'package:textgb/features/status/widgets/status_preview_card.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/utilities/global_methods.dart';

class MyStatusScreen extends StatefulWidget {
  final bool isPrivate;
  
  const MyStatusScreen({
    Key? key,
    required this.isPrivate,
  }) : super(key: key);

  @override
  State<MyStatusScreen> createState() => _MyStatusScreenState();
}

class _MyStatusScreenState extends State<MyStatusScreen> {
  bool _isRefreshing = false;
  
  Future<void> _refreshStatuses() async {
    setState(() {
      _isRefreshing = true;
    });
    
    final currentUserId = context.read<AuthenticationProvider>().userModel!.uid;
    final contactIds = context.read<AuthenticationProvider>().userModel!.contactsUIDs;
    
    await context.read<StatusProvider>().fetchStatuses(
      currentUserId: currentUserId,
      contactIds: contactIds,
    );
    
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }
  
  void _navigateToStatusDetail(StatusModel status, int index, List<StatusModel> statuses) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusDetailScreen(
          status: status,
          statuses: statuses,
          initialIndex: index,
        ),
      ),
    );
  }
  
  void _confirmDeleteStatus(StatusModel status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Status'),
        content: const Text('Are you sure you want to delete this status?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.read<StatusProvider>().deleteStatus(status);
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final statusProvider = context.watch<StatusProvider>();
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    
    // Get the appropriate list based on privacy
    final statuses = widget.isPrivate 
        ? statusProvider.myPrivateStatuses 
        : statusProvider.myPublicStatuses;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeExtension?.appBarColor,
        elevation: 0,
        title: Text(widget.isPrivate ? 'My Private Status' : 'My Public Status'),
        actions: [
          IconButton(
            icon: Icon(_isRefreshing 
              ? Icons.sync 
              : Icons.refresh,
              color: _isRefreshing ? themeExtension?.accentColor : null,
            ),
            onPressed: _isRefreshing ? null : _refreshStatuses,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, Constants.createStatusScreen);
            },
          ),
        ],
      ),
      backgroundColor: themeExtension?.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _refreshStatuses,
        child: statuses.isEmpty
            ? _buildEmptyState(themeExtension)
            : _buildStatusList(statuses, themeExtension),
      ),
    );
  }
  
  Widget _buildEmptyState(WeChatThemeExtension? themeExtension) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.isPrivate ? Icons.lock_outline : Icons.public,
            size: 64,
            color: themeExtension?.greyColor?.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No ${widget.isPrivate ? 'private' : 'public'} status updates',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeExtension?.greyColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your ${widget.isPrivate ? 'private' : 'public'} status updates will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: themeExtension?.greyColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, Constants.createStatusScreen);
            },
            icon: const Icon(Icons.add),
            label: Text('Create ${widget.isPrivate ? 'Private' : 'Public'} Status'),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeExtension?.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusList(List<StatusModel> statuses, WeChatThemeExtension? themeExtension) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: statuses.length,
      itemBuilder: (context, index) {
        final status = statuses[index];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: GestureDetector(
            onTap: () => _navigateToStatusDetail(status, index, statuses),
            child: StatusPreviewCard(
              status: status,
              onDelete: () => _confirmDeleteStatus(status),
              showDeleteButton: true,
              showMetrics: true,
            ),
          ),
        );
      },
    );
  }
}
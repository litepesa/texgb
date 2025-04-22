import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/features/status/widgets/my_status_card.dart';
import 'package:textgb/features/status/widgets/status_list.dart';
import 'package:textgb/providers/authentication_provider.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({Key? key}) : super(key: key);

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Fetch statuses when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeStatusFeeds();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeStatusFeeds() async {
    final currentUserId = context.read<AuthenticationProvider>().userModel!.uid;
    final contactIds = context.read<AuthenticationProvider>().userModel!.contactsUIDs;
    
    context.read<StatusProvider>().fetchStatuses(
      currentUserId: currentUserId,
      contactIds: contactIds,
    );
  }
  
  Future<void> _refreshStatuses() async {
    setState(() {
      _isRefreshing = true;
    });
    
    await _initializeStatusFeeds();
    
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    final statusProvider = context.watch<StatusProvider>();
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    
    // Check if status tab is visible for video playback management
    final isTabVisible = statusProvider.statusTabVisible && !statusProvider.appInFreshStart;
    
    return Scaffold(
      backgroundColor: themeExtension?.backgroundColor,
      appBar: AppBar(
        backgroundColor: themeExtension?.appBarColor,
        elevation: 0,
        title: const Text('Status'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'PRIVATE'),
            Tab(text: 'PUBLIC'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isRefreshing 
              ? Icons.sync 
              : Icons.refresh,
              color: _isRefreshing ? themeExtension?.accentColor : null,
            ),
            onPressed: _isRefreshing ? null : _refreshStatuses,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Private tab
          RefreshIndicator(
            onRefresh: _refreshStatuses,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // My status section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: MyStatusCard(
                      currentUser: currentUser,
                      statuses: statusProvider.myPrivateStatuses,
                      isPrivate: true,
                    ),
                  ),
                  
                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(
                      color: themeExtension?.dividerColor,
                      height: 1,
                    ),
                  ),
                  
                  // Recent updates text
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Recent Updates',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeExtension?.greyColor,
                      ),
                    ),
                  ),
                  
                  // Contacts' status list
                  StatusList(
                    userStatuses: statusProvider.userStatuses,
                    isPrivate: true,
                    isVisible: isTabVisible && _tabController.index == 0,
                  ),
                  
                  // Empty state if no statuses
                  if (statusProvider.userStatuses.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.nights_stay_outlined,
                              size: 64,
                              color: themeExtension?.greyColor?.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No private status updates',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: themeExtension?.greyColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'When your contacts post status updates, they will appear here',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: themeExtension?.greyColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Public tab
          RefreshIndicator(
            onRefresh: _refreshStatuses,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // My status section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: MyStatusCard(
                      currentUser: currentUser,
                      statuses: statusProvider.myPublicStatuses,
                      isPrivate: false,
                    ),
                  ),
                  
                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(
                      color: themeExtension?.dividerColor,
                      height: 1,
                    ),
                  ),
                  
                  // Recent updates text
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Public Updates',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeExtension?.greyColor,
                      ),
                    ),
                  ),
                  
                  // Public status list
                  StatusList(
                    publicStatuses: statusProvider.publicStatuses,
                    isPrivate: false,
                    isVisible: isTabVisible && _tabController.index == 1,
                  ),
                  
                  // Empty state if no statuses
                  if (statusProvider.publicStatuses.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.public_outlined,
                              size: 64,
                              color: themeExtension?.greyColor?.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No public status updates',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: themeExtension?.greyColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Public status updates from all users will appear here',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: themeExtension?.greyColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
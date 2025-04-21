import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/features/status/widgets/status_feed_item.dart';
import 'package:textgb/features/status/widgets/feed_loading_indicator.dart';
import 'package:textgb/features/status/widgets/no_status_placeholder.dart';
import 'package:textgb/models/status_model.dart';
import 'package:textgb/providers/authentication_provider.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({Key? key}) : super(key: key);

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final PageController _pageController = PageController();
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Delay loading to ensure the widget is fully initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStatusFeed();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This triggers when the tab becomes visible again
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      _loadStatusFeed();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reload statuses when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _loadStatusFeed();
    }
  }

  Future<void> _loadStatusFeed() async {
    setState(() {
      _isLoading = true;
    });

    final currentUserId = context.read<AuthenticationProvider>().userModel!.uid;
    final contactIds = context.read<AuthenticationProvider>().userModel!.contactsUIDs;

    // Initialize the status provider and fetch status posts
    await context.read<StatusProvider>().fetchStatuses(
      currentUserId: currentUserId,
      contactIds: contactIds,
    );

    setState(() {
      _isLoading = false;
    });
  }

  // Handle page change when swiping through statuses
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Mark status as viewed
    final statusList = context.read<StatusProvider>().statusList;
    if (statusList.isNotEmpty && index < statusList.length) {
      final status = statusList[index];
      context.read<StatusProvider>().markStatusAsViewed(status.statusId);
    }
  }

  // Pull to refresh implementation
  Future<void> _refreshFeed() async {
    await _loadStatusFeed();
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final backgroundColor = themeExtension?.chatBackgroundColor ?? Colors.black;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      // No app bar for a more immersive experience
      body: _isLoading 
          ? FeedLoadingIndicator()
          : Consumer<StatusProvider>(
              builder: (context, statusProvider, _) {
                final statusList = statusProvider.statusList;
                
                if (statusList.isEmpty) {
                  return NoStatusPlaceholder(
                    onRefresh: _refreshFeed,
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: _refreshFeed,
                  child: PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    onPageChanged: _onPageChanged,
                    itemCount: statusList.length,
                    itemBuilder: (context, index) {
                      final status = statusList[index];
                      return StatusFeedItem(
                        status: status,
                        isCurrentUser: status.uid == context.read<AuthenticationProvider>().userModel!.uid,
                        currentIndex: _currentIndex,
                        index: index,
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
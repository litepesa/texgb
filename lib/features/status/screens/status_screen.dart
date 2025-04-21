import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/features/status/widgets/feed_loading_indicator.dart';
import 'package:textgb/features/status/widgets/lazy_status_item.dart';
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
  List<StatusModel> _statusList = []; // Local cache of status list

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Delay loading to ensure the widget is fully initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStatusFeed();
      
      // Set the status tab as visible when it's initialized
      context.read<StatusProvider>().setStatusTabVisible(true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This triggers when the tab becomes visible again
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      _loadStatusFeed();
      
      // Mark the status tab as visible
      if (mounted) {
        context.read<StatusProvider>().setStatusTabVisible(true);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reload statuses when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _loadStatusFeed();
      
      // Mark the status tab as visible when app resumes
      if (mounted) {
        context.read<StatusProvider>().setStatusTabVisible(true);
      }
    } else if (state == AppLifecycleState.paused || 
              state == AppLifecycleState.inactive ||
              state == AppLifecycleState.detached) {
      // Mark tab as invisible when app goes to background
      if (mounted) {
        context.read<StatusProvider>().setStatusTabVisible(false);
      }
    }
  }

  // Optimized status loading
  Future<void> _loadStatusFeed() async {
    // Only show loading indicator if the list is empty
    if (_statusList.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    final currentUserId = context.read<AuthenticationProvider>().userModel!.uid;
    final contactIds = context.read<AuthenticationProvider>().userModel!.contactsUIDs;

    try {
      // Initialize the status provider and fetch status posts
      await context.read<StatusProvider>().fetchStatuses(
        currentUserId: currentUserId,
        contactIds: contactIds,
      );
      
      // Update local cache
      if (mounted) {
        setState(() {
          _statusList = context.read<StatusProvider>().statusList;
        });
      }
    } catch (e) {
      debugPrint('Error loading status feed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Handle page change when swiping through statuses
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Mark status as viewed
    if (_statusList.isNotEmpty && index < _statusList.length) {
      final status = _statusList[index];
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
          : Consumer2<StatusProvider, AuthenticationProvider>(
              builder: (context, statusProvider, authProvider, _) {
                final statusList = statusProvider.statusList;
                final isTabVisible = statusProvider.isStatusTabVisible;
                
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
                    physics: const BouncingScrollPhysics(), // Smoother scrolling
                    pageSnapping: true, // Ensure proper snapping
                    itemBuilder: (context, index) {
                      final status = statusList[index];
                      // Use LazyStatusItem instead of StatusFeedItem directly
                      return LazyStatusItem(
                        key: ValueKey(status.statusId),
                        status: status,
                        isCurrentUser: status.uid == authProvider.userModel!.uid,
                        currentIndex: _currentIndex,
                        index: index,
                        isVisible: isTabVisible,
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
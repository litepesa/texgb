// lib/features/status/presentation/screens/status_feed_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/status/models/status_post_model.dart';
import 'package:textgb/features/status/widgets/status_post_card.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class StatusFeedScreen extends StatefulWidget {
  const StatusFeedScreen({Key? key}) : super(key: key);

  @override
  State<StatusFeedScreen> createState() => _StatusFeedScreenState();
}

class _StatusFeedScreenState extends State<StatusFeedScreen> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadStatusFeed();
  }

  Future<void> _loadStatusFeed() async {
    final authProvider = context.read<AuthenticationProvider>();
    final statusProvider = context.read<StatusProvider>();
    
    if (authProvider.userModel != null) {
      await statusProvider.fetchAllStatuses(
        currentUserId: authProvider.userModel!.uid,
        contactIds: authProvider.userModel!.contactsUIDs,
      );
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    
    await _loadStatusFeed();
    
    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final modernTheme = context.modernTheme;
    final statusProvider = context.watch<StatusProvider>();
    final currentUser = context.watch<AuthenticationProvider>().userModel;
    final statusList = statusProvider.allStatusPosts;
    final bool isLoading = statusProvider.isLoading;
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: modernTheme.primaryColor,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Filter options
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFilterChip(
                      label: 'Latest',
                      isSelected: statusProvider.currentFilter == FeedFilterType.latest,
                      onTap: () => context.read<StatusProvider>().setFeedFilter(FeedFilterType.latest),
                    ),
                    _buildFilterChip(
                      label: 'Trending',
                      isSelected: statusProvider.currentFilter == FeedFilterType.trending,
                      onTap: () => context.read<StatusProvider>().setFeedFilter(FeedFilterType.trending),
                    ),
                    _buildFilterChip(
                      label: 'Friends',
                      isSelected: statusProvider.currentFilter == FeedFilterType.friends,
                      onTap: () => context.read<StatusProvider>().setFeedFilter(FeedFilterType.friends),
                    ),
                  ],
                ),
              ),
            ),
            
            // Status posts list
            if (isLoading && statusList.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (statusList.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.photo_on_rectangle,
                        size: 64,
                        color: modernTheme.textSecondaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No status updates yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: modernTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to share a moment!',
                        style: TextStyle(
                          fontSize: 14,
                          color: modernTheme.textTertiaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context, 
                            Constants.createStatusScreen,
                          ).then((_) => _loadStatusFeed());
                        },
                        icon: const Icon(CupertinoIcons.camera),
                        label: const Text('Create Status'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: modernTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final StatusPost post = statusList[index];
                    return StatusPostCard(
                      post: post,
                      currentUserId: currentUser?.uid ?? '',
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          Constants.statusDetailScreen,
                          arguments: post.id,
                        );
                      },
                    );
                  },
                  childCount: statusList.length,
                ),
              ),
              
            // Bottom padding for FAB
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final modernTheme = context.modernTheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? modernTheme.primaryColor
              : modernTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? modernTheme.primaryColor!
                : modernTheme.dividerColor!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? Colors.white
                : modernTheme.textColor,
            fontWeight: isSelected 
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
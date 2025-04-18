import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/moments/screens/create_moment_screen.dart';
import 'package:textgb/features/moments/screens/user_moments_screen.dart';
import 'package:textgb/features/moments/widgets/moment_card.dart';
import 'package:textgb/models/moment_model.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/providers/moments_provider.dart';
import 'package:textgb/utilities/global_methods.dart';

class MomentsScreen extends StatefulWidget {
  const MomentsScreen({Key? key}) : super(key: key);

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _isAppBarVisible = true;
  bool _isRefreshing = false;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    
    // Load moments when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMoments();
    });
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollListener() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isAppBarVisible) {
        setState(() {
          _isAppBarVisible = false;
        });
      }
    }
    
    if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isAppBarVisible) {
        setState(() {
          _isAppBarVisible = true;
        });
      }
    }
    
    // Load more moments when reaching the bottom of the list
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Implement pagination logic here if needed
    }
  }

  Future<void> _loadMoments() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      final authProvider = context.read<AuthenticationProvider>();
      final momentsProvider = context.read<MomentsProvider>();
      
      final currentUser = authProvider.userModel!;
      final contactIds = currentUser.contactsUIDs;
      
      await momentsProvider.fetchMoments(
        currentUserId: currentUser.uid,
        contactIds: contactIds,
      );
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error loading moments: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final backgroundColor = themeExtension?.backgroundColor ?? Colors.white;
    final accentColor = themeExtension?.accentColor ?? Colors.green;
    
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text(
                'Moments',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: false,
              floating: true,
              snap: true,
              elevation: 0,
              forceElevated: innerBoxIsScrolled,
              backgroundColor: backgroundColor.withOpacity(0.95),
              actions: [
                // Search button
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Search moments',
                  onPressed: () {
                    // TODO: Implement moments search
                    showSnackBar(context, 'Search feature coming soon');
                  },
                ),
                // My moments button
                IconButton(
                  icon: const Icon(Icons.person),
                  tooltip: 'My moments',
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/userMomentsScreen',
                      arguments: currentUser.uid,
                    );
                  },
                ),
              ],
            ),
          ];
        },
        body: Consumer<MomentsProvider>(
          builder: (context, momentsProvider, child) {
            if (momentsProvider.isLoading && !_isRefreshing) {
              return Center(
                child: CircularProgressIndicator(color: accentColor),
              );
            }
            
            final moments = [
              ...momentsProvider.userMoments,
              ...momentsProvider.contactsMoments,
            ]..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Ensure chronological order
            
            if (moments.isEmpty) {
              return _buildEmptyState(accentColor);
            }
            
            return RefreshIndicator(
              onRefresh: _loadMoments,
              color: accentColor,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: moments.length,
                itemBuilder: (context, index) {
                  final moment = moments[index];
                  
                  // Mark moment as viewed if it's not the current user's
                  if (moment.uid != currentUser.uid && !moment.viewedBy.contains(currentUser.uid)) {
                    momentsProvider.markMomentAsViewed(
                      momentId: moment.momentId,
                      userId: currentUser.uid,
                    );
                  }
                  
                  return MomentCard(
                    moment: moment,
                    currentUserId: currentUser.uid,
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _isAppBarVisible ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _isAppBarVisible ? 1.0 : 0.0,
          child: FloatingActionButton(
            onPressed: () => _navigateToCreateMoment(),
            backgroundColor: accentColor,
            elevation: 4,
            tooltip: 'Create new moment',
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color accentColor) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_album_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'No moments yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Share your first moment or add more contacts to see their moments',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _navigateToCreateMoment(),
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Create Moment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, Constants.contactsScreen);
                },
                icon: const Icon(Icons.people),
                label: const Text('Manage Contacts'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCreateMoment() {
    Navigator.pushNamed(
      context,
      Constants.createMomentScreen,
    ).then((_) => _loadMoments());
  }
}
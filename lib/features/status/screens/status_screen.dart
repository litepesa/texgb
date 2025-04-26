import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/status_post_model.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/status/widgets/status_video_player.dart';
import 'package:textgb/features/status/widgets/status_comments_sheet.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({Key? key}) : super(key: key);

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late TabController _tabController;
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Listen to tab changes to update filter
    _tabController.addListener(_handleTabChange);
    
    // Set system UI overlay style for immersive experience
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    
    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchStatuses();
    });
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) return;
    
    final StatusProvider provider = Provider.of<StatusProvider>(context, listen: false);
    switch (_tabController.index) {
      case 0:
        provider.setFeedFilter(FeedFilterType.latest);
        break;
      case 1:
        provider.setFeedFilter(FeedFilterType.trending);
        break;
      case 2:
        provider.setFeedFilter(FeedFilterType.contacts);
        break;
    }
  }
  
  void _fetchStatuses() {
    final currentUser = Provider.of<AuthenticationProvider>(context, listen: false).userModel;
    if (currentUser != null) {
      Provider.of<StatusProvider>(context, listen: false).fetchStatuses(
        currentUserId: currentUser.uid,
        contactIds: currentUser.contactsUIDs,
      );
    }
  }
  
  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        Provider.of<StatusProvider>(context, listen: false).setSearchQuery('');
      }
    });
  }
  
  void _handleSearch(String query) {
    Provider.of<StatusProvider>(context, listen: false).setSearchQuery(query);
  }
  
  void _handleCreatePost() async {
    final currentUser = Provider.of<AuthenticationProvider>(context, listen: false).userModel;
    if (currentUser == null) return;
    
    final statusProvider = Provider.of<StatusProvider>(context, listen: false);
    final hasPostedToday = await statusProvider.hasUserPostedToday(currentUser.uid);
    
    if (hasPostedToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can only post once per day'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    Navigator.pushNamed(context, Constants.createStatusScreen);
  }
  
  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final statusProvider = Provider.of<StatusProvider>(context);
    final authProvider = Provider.of<AuthenticationProvider>(context);
    final currentUser = authProvider.userModel;
    
    final posts = statusProvider.filteredStatusPosts;
    final isLoading = statusProvider.isLoading;
    
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      floatingActionButton: null, // Explicitly setting to null to ensure it's not displayed
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: _isSearchVisible 
            ? Container(
                color: Colors.black54,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _toggleSearch,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search status posts...',
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(color: Colors.white),
                        cursorColor: Colors.white,
                        onChanged: _handleSearch,
                        autofocus: true,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.clear, color: Colors.white),
                      onPressed: _toggleSearch,
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tab buttons in a row
                    Row(
                      children: [
                        _buildTabButton(0, 'Latest'),
                        _buildTabButton(1, 'Trending'),
                        _buildTabButton(2, 'Contacts'),
                      ],
                    ),
                    // Search icon
                    IconButton(
                      icon: Icon(Icons.search, color: Colors.white),
                      onPressed: _toggleSearch,
                    ),
                  ],
                ),
              ),
        ),
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator(color: modernTheme.primaryColor))
        : posts.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library_outlined, size: 64, color: Colors.white54),
                  SizedBox(height: 16),
                  Text(
                    'No status posts found',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create a new post or check back later',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            )
          : PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: posts.length,
              onPageChanged: (index) {
                if (currentUser != null) {
                  statusProvider.viewStatusPost(
                    statusId: posts[index].statusId,
                    viewerUid: currentUser.uid,
                  );
                }
              },
              itemBuilder: (context, index) {
                final post = posts[index];
                return StatusPostView(
                  post: post,
                  currentUserId: currentUser?.uid ?? '',
                  onCreatePost: _handleCreatePost,
                );
              },
            ),
    );
  }
  
  Widget _buildTabButton(int index, String label) {
  final isSelected = _tabController.index == index;
  final modernTheme = context.modernTheme;
  
  return GestureDetector(
    onTap: () {
      _tabController.animateTo(index);
    },
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      // Removed the border decoration
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ),
  );
 }
}

class StatusPostView extends StatefulWidget {
  final StatusPostModel post;
  final String currentUserId;
  final VoidCallback onCreatePost;
  
  const StatusPostView({
    Key? key,
    required this.post,
    required this.currentUserId,
    required this.onCreatePost,
  }) : super(key: key);

  @override
  State<StatusPostView> createState() => _StatusPostViewState();
}

class _StatusPostViewState extends State<StatusPostView> with AutomaticKeepAliveClientMixin {
  bool _isLiked = false;
  
  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.likeUIDs.contains(widget.currentUserId);
  }
  
  @override
  void didUpdateWidget(covariant StatusPostView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.statusId != widget.post.statusId) {
      _isLiked = widget.post.likeUIDs.contains(widget.currentUserId);
    }
  }
  
  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
    });
    
    Provider.of<StatusProvider>(context, listen: false).toggleLikeStatusPost(
      statusId: widget.post.statusId,
      userUid: widget.currentUserId,
    );
  }
  
  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatusCommentsSheet(
        statusId: widget.post.statusId,
        currentUserId: widget.currentUserId,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final modernTheme = context.modernTheme;
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Content - Video or Image(s)
        widget.post.type == StatusType.video 
            ? StatusVideoPlayer(
                videoUrl: widget.post.mediaUrls.first,
                autoPlay: true,
              )
            : widget.post.mediaUrls.length > 1 
                ? _buildImageCarousel(widget.post.mediaUrls)
                : CachedNetworkImage(
                    imageUrl: widget.post.mediaUrls.first,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.black,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: modernTheme.primaryColor,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.black,
                      child: Icon(Icons.error, color: Colors.white),
                    ),
                  ),
        
        // Gradient overlay for better text visibility
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
              stops: const [0.0, 0.2, 0.8, 1.0],
            ),
          ),
        ),
        
        // User info and caption
        Positioned(
          left: 16,
          right: 100,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: widget.post.userImage.isNotEmpty
                        ? CachedNetworkImageProvider(widget.post.userImage)
                        : AssetImage(AssetsManager.userImage) as ImageProvider,
                  ),
                  SizedBox(width: 10),
                  Text(
                    widget.post.username,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 10),
              
              // Caption
              if (widget.post.caption.isNotEmpty)
                Text(
                  widget.post.caption,
                  style: TextStyle(color: Colors.white),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              
              SizedBox(height: 6),
              
              // Time ago only
              Text(
                _timeAgo(widget.post.createdAt),
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        
        // Action buttons - ONLY 3 elements: Like, Comment, Post
        Positioned(
          right: 16,
          bottom: 60,
          child: Column(
            children: [
              // Like button
              IconButton(
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.white,
                  size: 30,
                ),
                onPressed: _toggleLike,
              ),
              Text(
                '${widget.post.likeUIDs.length}',
                style: TextStyle(color: Colors.white),
              ),
              
              SizedBox(height: 20),
              
              // Comment button
              IconButton(
                icon: Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: _showComments,
              ),
              Text(
                'Comment',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              
              SizedBox(height: 20),
              
              // Post button (formerly FAB)
              IconButton(
                icon: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: widget.onCreatePost,
              ),
              Text(
                'Post',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildImageCarousel(List<String> imageUrls) {
    return PageView.builder(
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            CachedNetworkImage(
              imageUrl: imageUrls[index],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => Container(
                color: Colors.black,
                child: Center(
                  child: CircularProgressIndicator(
                    color: context.modernTheme.primaryColor,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.black,
                child: Icon(Icons.error, color: Colors.white),
              ),
            ),
            
            // Image counter indicator
            Positioned(
              top: 60,
              right: 10,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${index + 1}/${imageUrls.length}',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
  
  String _timeLeft(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now);
    
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    
    return '$hours:${minutes.toString().padLeft(2, '0')}';
  }
  
  @override
  bool get wantKeepAlive => true;
}
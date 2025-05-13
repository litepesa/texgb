import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/marketplace/models/marketplace_video_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/marketplace/providers/marketplace_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/models/user_model.dart';

class MarketplaceVideoDetailScreen extends ConsumerStatefulWidget {
  final String videoId;
  
  const MarketplaceVideoDetailScreen({
    Key? key,
    required this.videoId,
  }) : super(key: key);

  @override
  ConsumerState<MarketplaceVideoDetailScreen> createState() => _MarketplaceVideoDetailScreenState();
}

class _MarketplaceVideoDetailScreenState extends ConsumerState<MarketplaceVideoDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late VideoPlayerController _videoPlayerController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  MarketplaceVideoModel? _video;
  UserModel? _seller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVideoData();
  }

  Future<void> _loadVideoData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get video data
      final videoDoc = await _firestore
          .collection(Constants.marketplaceVideos)
          .doc(widget.videoId)
          .get();
      
      if (!videoDoc.exists) {
        throw Exception('Video not found');
      }
      
      final videoData = videoDoc.data()!;
      final sellerId = videoData['userId'] as String;
      
      // Check if video is liked by current user
      bool isLiked = false;
      if (_auth.currentUser != null) {
        final userDoc = await _firestore
            .collection(Constants.users)
            .doc(_auth.currentUser!.uid)
            .get();
        
        if (userDoc.exists && userDoc.data()!.containsKey('likedMarketplaceVideos')) {
          final likedVideos = List<String>.from(
              userDoc.data()!['likedMarketplaceVideos'] ?? []);
          isLiked = likedVideos.contains(widget.videoId);
        }
      }
      
      _video = MarketplaceVideoModel.fromMap(videoData, isLiked: isLiked);
      
      // Get seller data
      final sellerDoc = await _firestore
          .collection(Constants.users)
          .doc(sellerId)
          .get();
      
      if (sellerDoc.exists) {
        _seller = UserModel.fromMap(sellerDoc.data()!);
      }
      
      // Initialize video player
      _videoPlayerController = VideoPlayerController.network(_video!.videoUrl);
      await _videoPlayerController.initialize();
      _videoPlayerController.setLooping(true);
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _isLoading = false;
        });
        
        // Auto-play video
        _videoPlayerController.play();
        setState(() {
          _isPlaying = true;
        });
        
        // Increment view count
        ref.read(marketplaceProvider.notifier).incrementViewCount(widget.videoId);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    if (_isVideoInitialized) {
      _videoPlayerController.dispose();
    }
    super.dispose();
  }

  void _togglePlayPause() {
    if (!_isVideoInitialized) return;
    
    setState(() {
      if (_isPlaying) {
        _videoPlayerController.pause();
      } else {
        _videoPlayerController.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: modernTheme.primaryColor,
              ),
            )
          : _error != null
              ? _buildErrorView(modernTheme)
              : _buildVideoDetailView(modernTheme),
    );
  }

  Widget _buildErrorView(ModernThemeExtension modernTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: modernTheme.primaryColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading video',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoDetailView(ModernThemeExtension modernTheme) {
    return CustomScrollView(
      slivers: [
        // App bar
        SliverAppBar(
          backgroundColor: Colors.black,
          expandedHeight: 0,
          pinned: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.share,
                color: Colors.white,
              ),
              onPressed: () {
                // Share functionality
              },
            ),
          ],
        ),
        
        // Video content
        SliverToBoxAdapter(
          child: AspectRatio(
            aspectRatio: _videoPlayerController.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Video player
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: VideoPlayer(_videoPlayerController),
                ),
                
                // Play/pause button overlay
                if (!_isPlaying)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Video details
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name and price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _video!.productName,
                        style: TextStyle(
                          color: modernTheme.textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: modernTheme.primaryColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _video!.price,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Category and location
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _video!.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (_video!.location.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.location_on,
                        color: modernTheme.textSecondaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _video!.location,
                        style: TextStyle(
                          color: modernTheme.textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Seller info
                if (_seller != null)
                  GestureDetector(
                    onTap: () {
                      // Navigate to seller profile
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: modernTheme.primaryColor!.withOpacity(0.2),
                          backgroundImage: _seller!.image.isNotEmpty
                              ? NetworkImage(_seller!.image)
                              : null,
                          child: _seller!.image.isEmpty
                              ? Text(
                                  _seller!.name.isNotEmpty
                                      ? _seller!.name[0].toUpperCase()
                                      : "S",
                                  style: TextStyle(
                                    color: modernTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _seller!.name,
                                style: TextStyle(
                                  color: modernTheme.textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (_video!.businessName.isNotEmpty)
                                Text(
                                  _video!.businessName,
                                  style: TextStyle(
                                    color: modernTheme.textSecondaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: modernTheme.primaryColor!,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'View Profile',
                            style: TextStyle(
                              color: modernTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Description
                Text(
                  'Description',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _video!.description,
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 16,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Tags
                if (_video!.tags.isNotEmpty) ...[
                  Text(
                    'Tags',
                    style: TextStyle(
                      color: modernTheme.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _video!.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: modernTheme.textSecondaryColor!.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Icons.favorite,
                      count: _video!.likes,
                      label: 'Likes',
                      color: _video!.isLiked ? Colors.red : modernTheme.textSecondaryColor!,
                      onTap: () {
                        ref.read(marketplaceProvider.notifier).likeVideo(widget.videoId);
                      },
                    ),
                    _buildStatItem(
                      icon: Icons.comment,
                      count: _video!.comments,
                      label: 'Comments',
                      color: modernTheme.textSecondaryColor!,
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          Constants.marketplaceCommentsScreen,
                          arguments: widget.videoId,
                        );
                      },
                    ),
                    _buildStatItem(
                      icon: Icons.visibility,
                      count: _video!.views,
                      label: 'Views',
                      color: modernTheme.textSecondaryColor!,
                      onTap: () {},
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.message),
                        label: const Text('Contact Seller'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: modernTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          // Contact seller
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(
                        Icons.share,
                        color: modernTheme.primaryColor,
                      ),
                      onPressed: () {
                        // Share functionality
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Similar products (placeholder)
                Text(
                  'Similar Products',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 150,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade700,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.shopping_bag,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Product ${index + 1}',
                                    style: TextStyle(
                                      color: modernTheme.textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${(index + 1) * 10 + 99}.99',
                                    style: TextStyle(
                                      color: modernTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
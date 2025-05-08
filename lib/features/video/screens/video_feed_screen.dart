import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/video/video_provider.dart';
import 'package:textgb/features/video/widgets/video_player_item.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';

class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({Key? key}) : super(key: key);

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  final PageController _pageController = PageController();
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    if (_isFirstLoad) {
      await context.read<VideoProvider>().fetchFeedVideos();
      setState(() {
        _isFirstLoad = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoProvider = Provider.of<VideoProvider>(context);
    final authProvider = Provider.of<AuthenticationProvider>(context);
    final UserModel currentUser = authProvider.userModel!;
    final modernTheme = context.modernTheme;
    
    // Get accent color from ModernThemeExtension
    final accentColor = modernTheme.primaryColor!;

    if (videoProvider.isLoading && _isFirstLoad) {
      return Center(
        child: CircularProgressIndicator(
          color: accentColor,
        ),
      );
    }

    if (videoProvider.feedVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.videocam_circle,
              size: 80,
              color: accentColor,
            ),
            const SizedBox(height: 20),
            Text(
              'No Videos Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Be the first to post a video!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Video Feed
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: videoProvider.feedVideos.length,
          onPageChanged: (index) {
            videoProvider.setCurrentVideoIndex(index);
          },
          itemBuilder: (context, index) {
            final video = videoProvider.feedVideos[index];
            return Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Video Player
                VideoPlayerItem(
                  videoUrl: video.videoUrl,
                  isPlaying: videoProvider.currentVideoIndex == index,
                ),
                
                // Video Info Overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username and caption
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: video.userImage.isNotEmpty
                                  ? CachedNetworkImageProvider(video.userImage)
                                  : const AssetImage(AssetsManager.userImage) as ImageProvider,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '@${video.userName}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        if (video.caption.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0, left: 48.0, right: 48.0),
                            child: Text(
                              video.caption,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (video.songName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 48.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  video.songName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Right side action buttons
                Positioned(
                  right: 16,
                  bottom: 100,
                  child: Column(
                    children: [
                      // Like button
                      _buildActionButton(
                        icon: video.likedBy.contains(currentUser.uid)
                            ? CupertinoIcons.heart_fill
                            : CupertinoIcons.heart,
                        count: video.likesCount,
                        color: video.likedBy.contains(currentUser.uid)
                            ? Colors.red
                            : Colors.white,
                        onTap: () {
                          videoProvider.toggleLikeVideo(video.id, currentUser.uid);
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Comment button
                      _buildActionButton(
                        icon: CupertinoIcons.chat_bubble_text,
                        count: video.commentsCount,
                        onTap: () {
                          // Navigate to comments
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Share button
                      _buildActionButton(
                        icon: CupertinoIcons.share,
                        count: video.sharesCount,
                        onTap: () {
                          // Handle share
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Profile button
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.black,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: video.userImage.isNotEmpty
                              ? CachedNetworkImageProvider(video.userImage)
                              : const AssetImage(AssetsManager.userImage) as ImageProvider,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        
        // For You / Following toggle
        Positioned(
          top: 50,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTabButton(
                title: 'Following',
                isSelected: false,
                onTap: () {
                  // Switch to following feed
                },
              ),
              const SizedBox(width: 20),
              _buildTabButton(
                title: 'For You',
                isSelected: true,
                onTap: () {
                  // Switch to for you feed
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    Color color = Colors.white,
    required Function() onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Icon(
            icon,
            color: color,
            size: 32,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              height: 3,
              width: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}
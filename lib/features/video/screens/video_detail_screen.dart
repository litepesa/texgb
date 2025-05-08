import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/video/video_provider.dart';
import 'package:textgb/features/video/widgets/video_player_item.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/models/video_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class VideoDetailScreen extends StatefulWidget {
  final String videoId;

  const VideoDetailScreen({
    Key? key,
    required this.videoId,
  }) : super(key: key);

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  late VideoModel? _video;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    
    // Find the video in the feed videos
    _video = videoProvider.feedVideos.firstWhere(
      (video) => video.id == widget.videoId,
      orElse: () => null as VideoModel,
    );
    
    // If not found, fetch videos if list is empty
    if (_video == null && videoProvider.feedVideos.isEmpty) {
      await videoProvider.fetchFeedVideos();
      _video = videoProvider.feedVideos.firstWhere(
        (video) => video.id == widget.videoId,
        orElse: () => null as VideoModel,
      );
    }
    
    setState(() {
      _isLoading = false;
    });
    
    // Increment view count
    if (_video != null) {
      videoProvider.incrementViewCount(_video!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoProvider = Provider.of<VideoProvider>(context);
    final authProvider = Provider.of<AuthenticationProvider>(context);
    final UserModel currentUser = authProvider.userModel!;
    final modernTheme = context.modernTheme;
    
    // Get accent color from ModernThemeExtension
    final accentColor = modernTheme.primaryColor!;
    final textColor = modernTheme.textColor!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Video',
            style: TextStyle(color: textColor),
          ),
          backgroundColor: modernTheme.appBarColor,
          iconTheme: IconThemeData(color: textColor),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: accentColor,
          ),
        ),
      );
    }

    if (_video == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Video Not Found',
            style: TextStyle(color: textColor),
          ),
          backgroundColor: modernTheme.appBarColor,
          iconTheme: IconThemeData(color: textColor),
        ),
        body: Center(
          child: Text(
            'The video you are looking for does not exist or has been removed.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '@${_video!.userName}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Video Player
          Expanded(
            child: VideoPlayerItem(
              videoUrl: _video!.videoUrl,
              isPlaying: true,
            ),
          ),
          
          // Video Info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Caption
                Text(
                  _video!.caption,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Song name
                if (_video!.songName.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _video!.songName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                
                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(
                      icon: Icons.favorite,
                      count: _video!.likesCount.toString(),
                      label: 'Likes',
                      color: _video!.likedBy.contains(currentUser.uid)
                          ? Colors.red
                          : Colors.white,
                      onTap: () {
                        videoProvider.toggleLikeVideo(_video!.id, currentUser.uid);
                      },
                    ),
                    _buildStat(
                      icon: Icons.comment,
                      count: _video!.commentsCount.toString(),
                      label: 'Comments',
                      onTap: () {
                        // Navigate to comments
                      },
                    ),
                    _buildStat(
                      icon: Icons.share,
                      count: _video!.sharesCount.toString(),
                      label: 'Shares',
                      onTap: () {
                        // Handle share
                      },
                    ),
                    _buildStat(
                      icon: Icons.remove_red_eye,
                      count: _video!.viewCount.toString(),
                      label: 'Views',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String count,
    required String label,
    Color color = Colors.white,
    required Function() onTap,
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
            count,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
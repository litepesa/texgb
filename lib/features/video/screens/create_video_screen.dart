import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/video/video_provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:video_player/video_player.dart';

class CreateVideoScreen extends StatefulWidget {
  const CreateVideoScreen({Key? key}) : super(key: key);

  @override
  State<CreateVideoScreen> createState() => _CreateVideoScreenState();
}

class _CreateVideoScreenState extends State<CreateVideoScreen> {
  File? _videoFile;
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _songNameController = TextEditingController();
  VideoPlayerController? _videoPlayerController;
  bool _isVideoLoaded = false;
  bool _isPlaying = false;

  @override
  void dispose() {
    _captionController.dispose();
    _songNameController.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  // Pick video from gallery or camera
  void _pickVideo(bool fromCamera) async {
    File? pickedVideo;
    
    if (fromCamera) {
      pickedVideo = await pickVideoFromCamera(
        onFail: (error) {
          showSnackBar(context, error);
        },
        maxDuration: const Duration(seconds: 90),
      );
    } else {
      pickedVideo = await pickVideo(
        onFail: (error) {
          showSnackBar(context, error);
        },
        maxDuration: const Duration(seconds: 90),
      );
    }
    
    if (pickedVideo != null) {
      setState(() {
        _videoFile = pickedVideo;
      });
      _initializeVideoPlayer();
    }
  }

  // Initialize video player
  void _initializeVideoPlayer() async {
    if (_videoFile != null) {
      _videoPlayerController = VideoPlayerController.file(_videoFile!);
      await _videoPlayerController!.initialize();
      await _videoPlayerController!.setLooping(true);
      setState(() {
        _isVideoLoaded = true;
        _isPlaying = true;
      });
      _videoPlayerController!.play();
    }
  }

  // Toggle play/pause
  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    
    if (_isPlaying) {
      _videoPlayerController!.play();
    } else {
      _videoPlayerController!.pause();
    }
  }

  // Upload video
  void _uploadVideo() async {
    if (_videoFile == null) {
      showSnackBar(context, 'Please select a video first');
      return;
    }

    // Validate caption
    if (_captionController.text.trim().isEmpty) {
      showSnackBar(context, 'Please add a caption');
      return;
    }

    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);
    final UserModel currentUser = authProvider.userModel!;

    final bool success = await videoProvider.uploadVideo(
      videoFile: _videoFile!,
      user: currentUser,
      caption: _captionController.text.trim(),
      songName: _songNameController.text.trim().isEmpty 
          ? 'Original Audio' 
          : _songNameController.text.trim(),
      onFail: (error) {
        showSnackBar(context, error);
      },
    );

    if (success && mounted) {
      showSnackBar(context, 'Video uploaded successfully!');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoProvider = Provider.of<VideoProvider>(context);
    final modernTheme = context.modernTheme;
    final accentColor = modernTheme.primaryColor!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final surfaceColor = modernTheme.surfaceColor!;
    final textColor = modernTheme.textColor!;
    final textSecondaryColor = modernTheme.textSecondaryColor!;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        title: Text(
          'Create Video',
          style: TextStyle(
            color: textColor,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: textColor,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          if (_videoFile != null)
            TextButton(
              onPressed: videoProvider.isUploading ? null : _uploadVideo,
              child: Text(
                'Post',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: _videoFile == null
          ? _buildVideoPickerUI(accentColor, textColor)
          : _buildVideoEditUI(videoProvider, accentColor, textColor, textSecondaryColor),
    );
  }

  Widget _buildVideoPickerUI(Color accentColor, Color textColor) {
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
            'Create a New Video',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Upload a video from your gallery or record a new one',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: textColor.withOpacity(0.8),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Upload from gallery
              _buildOptionButton(
                icon: CupertinoIcons.photo,
                label: 'Gallery',
                color: accentColor,
                onTap: () => _pickVideo(false),
              ),
              const SizedBox(width: 30),
              
              // Record new video
              _buildOptionButton(
                icon: CupertinoIcons.camera,
                label: 'Camera',
                color: accentColor,
                onTap: () => _pickVideo(true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoEditUI(
    VideoProvider videoProvider, 
    Color accentColor, 
    Color textColor,
    Color textSecondaryColor,
  ) {
    return Column(
      children: [
        // Upload progress indicator
        if (videoProvider.isUploading)
          LinearProgressIndicator(
            value: videoProvider.uploadProgress,
            backgroundColor: accentColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),
          
        // Video preview
        Expanded(
          flex: 5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isVideoLoaded)
                AspectRatio(
                  aspectRatio: _videoPlayerController!.value.aspectRatio,
                  child: VideoPlayer(_videoPlayerController!),
                ),
              
              // Play/Pause button
              if (_isVideoLoaded)
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Video details form
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Caption',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _captionController,
                  maxLength: 150,
                  maxLines: 2,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Write a caption...',
                    hintStyle: TextStyle(color: textSecondaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: accentColor, width: 2),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Music',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _songNameController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Add song or leave empty for original audio',
                    hintStyle: TextStyle(color: textSecondaryColor),
                    prefixIcon: Icon(
                      Icons.music_note,
                      color: textSecondaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: accentColor, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(
              icon,
              color: color,
              size: 40,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
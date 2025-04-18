import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/providers/moments_provider.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:video_player/video_player.dart';

class CreateMomentScreen extends StatefulWidget {
  const CreateMomentScreen({Key? key}) : super(key: key);

  @override
  State<CreateMomentScreen> createState() => _CreateMomentScreenState();
}

class _CreateMomentScreenState extends State<CreateMomentScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<File> _selectedMedia = [];
  final List<bool> _isVideoList = [];
  final List<VideoPlayerController?> _videoControllers = [];
  String _location = '';
  bool _isVideo = false;
  final int _maxMediaCount = 9; // Maximum 9 photos per post

  @override
  void dispose() {
    _textController.dispose();
    // Dispose video controllers
    for (final controller in _videoControllers) {
      controller?.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      
      if (pickedFile != null) {
        if (_selectedMedia.length >= _maxMediaCount) {
          showSnackBar(context, 'Maximum ${_isVideo ? '1 video' : '$_maxMediaCount photos'} allowed');
          return;
        }
        
        // If we already have a video, don't allow adding photos
        if (_isVideo) {
          showSnackBar(context, 'You can\'t mix photos and videos in one post');
          return;
        }
        
        setState(() {
          _selectedMedia.add(File(pickedFile.path));
          _isVideoList.add(false);
          _videoControllers.add(null);
        });
      }
    } catch (e) {
      showSnackBar(context, 'Error picking image: $e');
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      
      if (pickedFile != null) {
        // If we already have photos, don't allow adding a video
        if (_selectedMedia.isNotEmpty && !_isVideo) {
          showSnackBar(context, 'You can\'t mix photos and videos in one post');
          return;
        }
        
        // Only one video per post
        if (_isVideo) {
          showSnackBar(context, 'Only one video per post is allowed');
          return;
        }
        
        final videoFile = File(pickedFile.path);
        final videoController = VideoPlayerController.file(videoFile);
        await videoController.initialize();
        
        setState(() {
          _selectedMedia.add(videoFile);
          _isVideoList.add(true);
          _videoControllers.add(videoController);
          _isVideo = true;
        });
        
        videoController.setLooping(true);
        videoController.play();
      }
    } catch (e) {
      showSnackBar(context, 'Error picking video: $e');
    }
  }

  void _removeMedia(int index) {
    setState(() {
      // Dispose video controller if needed
      if (_isVideoList[index] && _videoControllers[index] != null) {
        _videoControllers[index]!.dispose();
      }
      
      _selectedMedia.removeAt(index);
      _isVideoList.removeAt(index);
      _videoControllers.removeAt(index);
      
      // Reset video flag if we removed a video
      if (_isVideo && !_isVideoList.contains(true)) {
        _isVideo = false;
      }
    });
  }

  Future<void> _publishMoment() async {
    if (_selectedMedia.isEmpty && _textController.text.trim().isEmpty) {
      showSnackBar(context, 'Please add photos/video or text to your moment');
      return;
    }
    
    final momentsProvider = context.read<MomentsProvider>();
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    
    await momentsProvider.uploadMoment(
      currentUser: currentUser,
      text: _textController.text.trim(),
      mediaFiles: _selectedMedia,
      isVideo: _isVideo,
      location: _location,
      onSuccess: () {
        Navigator.pop(context);
        showSnackBar(context, 'Moment posted successfully');
      },
      onError: (error) {
        showSnackBar(context, 'Error posting moment: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? Colors.green;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Moment'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: context.watch<MomentsProvider>().isUploading 
                ? null 
                : _publishMoment,
            child: const Text('Post'),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Privacy message
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.privacy_tip_outlined, color: accentColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Only your contacts can view your moments',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Text input
                TextField(
                  controller: _textController,
                  maxLines: 5,
                  minLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'What\'s on your mind?',
                    border: InputBorder.none,
                  ),
                ),
                
                const Divider(),
                
                // Selected media preview
                if (_selectedMedia.isNotEmpty)
                  _buildMediaPreview(),
                
                const SizedBox(height: 16),
                
                // Media selection buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMediaButton(
                      icon: Icons.photo_library,
                      label: 'Photos',
                      onTap: () => _pickImage(ImageSource.gallery),
                      color: Colors.blue,
                    ),
                    _buildMediaButton(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () => _pickImage(ImageSource.camera),
                      color: Colors.green,
                    ),
                    _buildMediaButton(
                      icon: Icons.videocam,
                      label: 'Video',
                      onTap: _pickVideo,
                      color: Colors.red,
                    ),
                    _buildMediaButton(
                      icon: Icons.location_on,
                      label: 'Location',
                      onTap: () {
                        // TODO: Implement location picker
                        showSnackBar(context, 'Location feature coming soon');
                      },
                      color: Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Loading overlay
          if (context.watch<MomentsProvider>().isUploading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: accentColor),
                      const SizedBox(height: 16),
                      const Text(
                        'Posting moment...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        _isVideo
            ? _buildVideoPreview()
            : _buildPhotosGrid(),
      ],
    );
  }

  Widget _buildVideoPreview() {
    if (_selectedMedia.isEmpty || _videoControllers.isEmpty || _videoControllers[0] == null) {
      return const SizedBox();
    }
    
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: _videoControllers[0]!.value.aspectRatio,
          child: VideoPlayer(_videoControllers[0]!),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: _buildRemoveButton(0),
        ),
      ],
    );
  }

  Widget _buildPhotosGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _selectedMedia.length,
      itemBuilder: (context, index) {
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _selectedMedia[index],
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: _buildRemoveButton(index),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRemoveButton(int index) {
    return GestureDetector(
      onTap: () => _removeMedia(index),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }
}
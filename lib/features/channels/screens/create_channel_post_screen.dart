import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/channels/channel_provider.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:video_player/video_player.dart';

class CreateChannelPostScreen extends StatefulWidget {
  final String channelId;

  const CreateChannelPostScreen({
    Key? key,
    required this.channelId,
  }) : super(key: key);

  @override
  State<CreateChannelPostScreen> createState() => _CreateChannelPostScreenState();
}

class _CreateChannelPostScreenState extends State<CreateChannelPostScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  File? _mediaFile;
  MessageEnum _messageType = MessageEnum.text;
  
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void dispose() {
    _messageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final image = await pickImage(
        fromCamera: result,
        onFail: (error) => showSnackBar(context, error),
      );

      if (image != null && mounted) {
        setState(() {
          _mediaFile = image;
          _messageType = MessageEnum.image;
          
          // Clear any existing video controller
          _videoController?.dispose();
          _videoController = null;
          _isVideoInitialized = false;
        });
      }
    }
  }

  Future<void> _pickVideo() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Video Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final video = result
          ? await pickVideoFromCamera(
              onFail: (error) => showSnackBar(context, error),
              maxDuration: const Duration(minutes: 5),
            )
          : await pickVideo(
              onFail: (error) => showSnackBar(context, error),
              maxDuration: const Duration(minutes: 5),
            );

      if (video != null && mounted) {
        setState(() {
          _mediaFile = video;
          _messageType = MessageEnum.video;
        });
        
        // Initialize video player
        _initializeVideoPlayer(video);
      }
    }
  }

  Future<void> _initializeVideoPlayer(File videoFile) async {
    _videoController = VideoPlayerController.file(videoFile);
    await _videoController!.initialize();
    
    if (mounted) {
      setState(() {
        _isVideoInitialized = true;
      });
    }
  }

  void _removeMedia() {
    setState(() {
      _mediaFile = null;
      _messageType = MessageEnum.text;
      
      // Dispose video controller if exists
      _videoController?.dispose();
      _videoController = null;
      _isVideoInitialized = false;
    });
  }

  Future<void> _createPost() async {
    // Validate input
    final message = _messageController.text.trim();
    
    if (message.isEmpty && _mediaFile == null) {
      showSnackBar(context, 'Please add text or media to your post');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userId = context.read<AuthenticationProvider>().userModel!.uid;

    try {
      await context.read<ChannelProvider>().createChannelPost(
        channelId: widget.channelId,
        creatorUID: userId,
        message: message,
        messageType: _messageType,
        mediaFile: _mediaFile,
        onSuccess: () {
          Navigator.pop(context);
          showSnackBar(context, 'Post created successfully');
        },
        onFail: (error) {
          showSnackBar(context, 'Error creating post: $error');
          setState(() {
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      showSnackBar(context, 'Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final accentColor = modernTheme.primaryColor!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Post',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: modernTheme.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPost,
            child: Text(
              'Post',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _isLoading ? modernTheme.textSecondaryColor : accentColor,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text input
                  TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Write something...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: modernTheme.textSecondaryColor!.withOpacity(0.7),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 18,
                      color: modernTheme.textColor,
                    ),
                    maxLines: 10,
                    minLines: 3,
                  ),
                  
                  // Media preview
                  if (_mediaFile != null) ...[
                    const SizedBox(height: 16),
                    Stack(
                      children: [
                        Container(
                          constraints: const BoxConstraints(
                            maxHeight: 300,
                          ),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: modernTheme.dividerColor!,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _messageType == MessageEnum.image
                                ? Image.file(
                                    _mediaFile!,
                                    fit: BoxFit.cover,
                                  )
                                : _isVideoInitialized && _videoController != null
                                    ? Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          AspectRatio(
                                            aspectRatio: _videoController!.value.aspectRatio,
                                            child: VideoPlayer(_videoController!),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              _videoController!.value.isPlaying
                                                  ? Icons.pause_circle
                                                  : Icons.play_circle,
                                              size: 60,
                                              color: Colors.white.withOpacity(0.8),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                if (_videoController!.value.isPlaying) {
                                                  _videoController!.pause();
                                                } else {
                                                  _videoController!.play();
                                                }
                                              });
                                            },
                                          ),
                                        ],
                                      )
                                    : const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _removeMedia,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: _isLoading
          ? null
          : Container(
              decoration: BoxDecoration(
                color: modernTheme.surfaceColor,
                border: Border(
                  top: BorderSide(
                    color: modernTheme.dividerColor!,
                    width: 0.5,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 16,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      CupertinoIcons.photo,
                      color: modernTheme.textSecondaryColor,
                    ),
                    onPressed: _pickImage,
                  ),
                  IconButton(
                    icon: Icon(
                      CupertinoIcons.video_camera,
                      color: modernTheme.textSecondaryColor,
                    ),
                    onPressed: _pickVideo,
                  ),
                  const Spacer(),
                  Text(
                    'Add to your post',
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
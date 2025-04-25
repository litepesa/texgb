// lib/features/status/screens/create_status_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class CreateStatusScreen extends StatefulWidget {
  const CreateStatusScreen({Key? key}) : super(key: key);

  @override
  State<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends State<CreateStatusScreen> {
  final TextEditingController _captionController = TextEditingController();
  
  List<File> _selectedMedia = [];
  List<AssetEntity> _recentMedia = [];
  StatusType _mediaType = StatusType.image;
  bool _isPrivate = false;
  bool _isContactsOnly = true;
  List<String> _allowedContactUIDs = [];
  
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _loadRecentMedia();
    
    // Set system overlay style for clean UI
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }
  
  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }
  
  // Load recent media from device gallery
  Future<void> _loadRecentMedia() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Request permission
      final result = await PhotoManager.requestPermissionExtend();
      if (result.isAuth) {
        // Get recent media (both images and videos)
        final albums = await PhotoManager.getAssetPathList(
          type: RequestType.common,
          hasAll: true,
        );
        
        if (albums.isNotEmpty) {
          final recentAlbum = albums.first;
          final media = await recentAlbum.getAssetListRange(
            start: 0,
            end: 60, // Get 60 recent media files
          );
          
          setState(() {
            _recentMedia = media;
          });
        }
      } else {
        // Handle denied permission
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permission to access gallery was denied'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading media: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Select media from gallery
  Future<void> _selectFromGallery(AssetEntity asset) async {
    try {
      final file = await asset.file;
      if (file == null) return;
      
      // Check file size (10MB limit for images, 50MB for videos)
      final sizeInMB = await file.length() / (1024 * 1024);
      final isVideo = asset.type == AssetType.video;
      
      if (isVideo && sizeInMB > 50) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video size too large. Maximum allowed is 50MB.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      } else if (!isVideo && sizeInMB > 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image size too large. Maximum allowed is 10MB.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Check video duration (60 seconds limit)
      if (isVideo && asset.duration > 60) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video too long. Maximum duration is 60 seconds.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Initialize video controller if needed
      if (isVideo) {
        await _initializeVideoController(file);
        setState(() {
          _mediaType = StatusType.video;
        });
      } else {
        setState(() {
          _mediaType = StatusType.image;
        });
      }
      
      // Images allow up to 9 files, but videos only allow 1
      if (isVideo) {
        setState(() {
          _selectedMedia = [file];
        });
      } else {
        // For images, append unless we already have 9
        if (_selectedMedia.length < 9) {
          setState(() {
            _selectedMedia.add(file);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maximum 9 images allowed'),
              backgroundColor: Colors.amber,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting media: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Initialize video controller
  Future<void> _initializeVideoController(File file) async {
    if (_videoController != null) {
      await _videoController!.dispose();
    }
    
    _videoController = VideoPlayerController.file(file);
    await _videoController!.initialize();
    await _videoController!.setLooping(true);
    await _videoController!.play();
    
    setState(() {
      _isVideoInitialized = true;
    });
  }
  
  // Take new photo with camera
  Future<void> _takePhoto() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 90, // High quality
      );
      
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        
        // Check file size
        final sizeInMB = await file.length() / (1024 * 1024);
        if (sizeInMB > 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image size too large. Maximum allowed is 10MB.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        setState(() {
          _mediaType = StatusType.image;
          
          // Add to selected media if less than 9
          if (_selectedMedia.length < 9) {
            _selectedMedia.add(file);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Maximum 9 images allowed'),
                backgroundColor: Colors.amber,
              ),
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking photo: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Record new video with camera
  Future<void> _recordVideo() async {
    try {
      final pickedFile = await ImagePicker().pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 60),
      );
      
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        
        // Check file size
        final sizeInMB = await file.length() / (1024 * 1024);
        if (sizeInMB > 50) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video size too large. Maximum allowed is 50MB.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        await _initializeVideoController(file);
        
        setState(() {
          _mediaType = StatusType.video;
          _selectedMedia = [file]; // For video, replace any existing media
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error recording video: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Remove media from selection
  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
      
      // If all media removed, reset video controller
      if (_selectedMedia.isEmpty && _isVideoInitialized) {
        _videoController?.pause();
        _videoController?.dispose();
        _videoController = null;
        _isVideoInitialized = false;
      }
    });
  }
  
  // Upload status post
  Future<void> _uploadStatus() async {
    // Validate input
    if (_selectedMedia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one media file'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final currentUser = Provider.of<AuthenticationProvider>(context, listen: false).userModel;
    if (currentUser == null) return;
    
    // Begin upload
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });
    
    try {
      await Provider.of<StatusProvider>(context, listen: false).createStatusPost(
        uid: currentUser.uid,
        username: currentUser.name,
        userImage: currentUser.image,
        mediaFiles: _selectedMedia,
        caption: _captionController.text.trim(),
        type: _mediaType,
        isPrivate: _isPrivate,
        isContactsOnly: _isContactsOnly,
        allowedContactUIDs: _allowedContactUIDs,
      );
      
      // Success - go back
      Navigator.pop(context);
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
  
  // Toggle privacy settings
  void _showPrivacyOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 16),
            // Public/Private toggle
            SwitchListTile(
              title: Text('Private'),
              subtitle: Text('Only specific people can see this post'),
              value: _isPrivate,
              onChanged: (value) {
                Navigator.pop(context);
                setState(() {
                  _isPrivate = value;
                  if (!value) {
                    // If not private, reset contacts-only and allowed contacts
                    _isContactsOnly = true;
                    _allowedContactUIDs = [];
                  }
                });
              },
            ),
            
            if (_isPrivate) ...[
              Divider(),
              // Contacts-only toggle
              SwitchListTile(
                title: Text('All Contacts'),
                subtitle: Text('All your contacts can see this post'),
                value: _isContactsOnly,
                onChanged: (value) {
                  Navigator.pop(context);
                  setState(() {
                    _isContactsOnly = value;
                    if (value) {
                      // If contacts-only, clear allowed contacts list
                      _allowedContactUIDs = [];
                    } else {
                      // TODO: Show contact selector to choose specific contacts
                      // For now, we'll just set a placeholder message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Select specific contacts feature will be implemented soon'),
                          backgroundColor: Colors.amber,
                        ),
                      );
                    }
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Post'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Privacy settings button
          IconButton(
            icon: Icon(
              _isPrivate ? Icons.lock_outline : Icons.public,
            ),
            onPressed: _showPrivacyOptions,
          ),
          
          // Upload button
          TextButton(
            onPressed: _isUploading ? null : _uploadStatus,
            child: _isUploading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                      value: _uploadProgress > 0 ? _uploadProgress : null,
                    ),
                  )
                : Text(
                    'Post',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected media preview
            if (_selectedMedia.isNotEmpty) ...[
              Container(
                height: 300,
                width: double.infinity,
                child: _mediaType == StatusType.video && _isVideoInitialized
                    ? VideoPreview(controller: _videoController!)
                    : ImagePreview(
                        images: _selectedMedia,
                        onRemove: _removeMedia,
                      ),
              ),
              Divider(),
            ],
            
            // Caption input
            Padding(
              padding: EdgeInsets.all(16),
              child: TextField(
                controller: _captionController,
                decoration: InputDecoration(
                  hintText: 'Write a caption...',
                  border: InputBorder.none,
                ),
                maxLines: 5,
                minLines: 1,
              ),
            ),
            
            Divider(),
            
            // Media picker header
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Media',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      // Camera button for photos
                      IconButton(
                        icon: Icon(Icons.camera_alt),
                        onPressed: _takePhoto,
                      ),
                      // Video camera button
                      IconButton(
                        icon: Icon(Icons.videocam),
                        onPressed: _recordVideo,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Media gallery grid
            _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: modernTheme.primaryColor,
                    ),
                  )
                : Container(
                    height: 300,
                    child: GridView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: _recentMedia.length,
                      itemBuilder: (context, index) {
                        final asset = _recentMedia[index];
                        return GestureDetector(
                          onTap: () => _selectFromGallery(asset),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Thumbnail
                              AssetThumbnail(asset: asset),
                              
                              // Video indicator
                              if (asset.type == AssetType.video)
                                Positioned(
                                  right: 5,
                                  bottom: 5,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _formatDuration(asset.duration),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
  
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

// Asset thumbnail widget
class AssetThumbnail extends StatelessWidget {
  final AssetEntity asset;
  
  const AssetThumbnail({Key? key, required this.asset}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
          );
        }
        return Container(
          color: Colors.grey[300],
          child: Center(
            child: CircularProgressIndicator(
              color: context.modernTheme.primaryColor,
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }
}

// Video preview widget
class VideoPreview extends StatelessWidget {
  final VideoPlayerController controller;
  
  const VideoPreview({Key? key, required this.controller}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Video player
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
        
        // Playback controls
        GestureDetector(
          onTap: () {
            if (controller.value.isPlaying) {
              controller.pause();
            } else {
              controller.play();
            }
          },
          child: Container(
            color: Colors.transparent,
            child: Center(
              child: Icon(
                controller.value.isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline,
                color: Colors.white.withOpacity(0.7),
                size: 64,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Image preview widget
class ImagePreview extends StatelessWidget {
  final List<File> images;
  final Function(int) onRemove;
  
  const ImagePreview({
    Key? key,
    required this.images,
    required this.onRemove,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return images.length == 1
        ? Stack(
            fit: StackFit.expand,
            children: [
              // Single image
              Image.file(
                images.first,
                fit: BoxFit.contain,
              ),
              
              // Remove button
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => onRemove(0),
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          )
        : PageView.builder(
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  Image.file(
                    images[index],
                    fit: BoxFit.contain,
                  ),
                  
                  // Remove button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => onRemove(index),
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  
                  // Page indicator
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                        (i) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == index ? Colors.white : Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
  }
}
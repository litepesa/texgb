import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/features/status/widgets/text_status_creator.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:video_player/video_player.dart';

class CreateStatusScreen extends StatefulWidget {
  const CreateStatusScreen({Key? key}) : super(key: key);

  @override
  State<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends State<CreateStatusScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _captionController = TextEditingController();
  
  File? _selectedMedia;
  StatusType _selectedType = StatusType.text;
  bool _isPrivate = true;
  bool _isSubmitting = false;
  bool _isProcessingMedia = false;
  
  // For video preview
  VideoPlayerController? _videoController;
  double _videoAspectRatio = 9/16; // Default TikTok-style aspect ratio
  
  // For text status
  String _statusText = '';
  Map<String, String> _backgroundInfo = {
    'color': '0xFF09BB07', // Default green color
    'fontFamily': 'Roboto',
    'alignment': 'center',
  };

  @override
  void dispose() {
    _captionController.dispose();
    _disposeVideoController();
    super.dispose();
  }
  
  void _disposeVideoController() {
    if (_videoController != null) {
      _videoController!.dispose();
      _videoController = null;
    }
  }
  
  // Pick image for status
  Future<void> _pickImage(bool fromCamera) async {
    try {
      setState(() {
        _isProcessingMedia = true;
      });
      
      final File? image = await pickImage(
        fromCamera: fromCamera, 
        onFail: (error) {
          showSnackBar(context, error);
        }
      );
      
      if (image == null) {
        setState(() {
          _isProcessingMedia = false;
        });
        return;
      }
      
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16), // TikTok-style ratio
        compressQuality: 90,
        maxHeight: 1920,
        maxWidth: 1080,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: true,
          ),
        ],
      );
      
      if (croppedFile == null) {
        setState(() {
          _isProcessingMedia = false;
        });
        return;
      }
      
      // Clear any existing video controller
      _disposeVideoController();
      
      setState(() {
        _selectedMedia = File(croppedFile.path);
        _selectedType = StatusType.image;
        _isProcessingMedia = false;
      });
      
    } catch (e) {
      setState(() {
        _isProcessingMedia = false;
      });
      showSnackBar(context, 'Error picking image: $e');
    }
  }
  
  // Pick video for status - Improved to enforce limits without processing
  Future<void> _pickVideo() async {
    try {
      // First dispose any existing video controller
      _disposeVideoController();
      
      setState(() {
        _isProcessingMedia = true;
      });
      
      final File? video = await pickVideo(
        onFail: (error) {
          showSnackBar(context, error);
        },
        maxDuration: const Duration(seconds: 90), // 90 second limit
      );
      
      if (video == null) {
        setState(() {
          _isProcessingMedia = false;
        });
        return;
      }
      
      // Get file size
      final fileSize = await video.length();
      final fileSizeInMB = fileSize / (1024 * 1024);
      
      // Check size limit directly instead of processing
      if (fileSizeInMB > 50) {
        showSnackBar(context, 'Video is too large. Maximum size is 50MB.');
        setState(() {
          _isProcessingMedia = false;
        });
        return;
      }
      
      // Initialize video player
      _videoController = VideoPlayerController.file(video);
      
      await _videoController!.initialize();
      
      // Check video duration
      if (_videoController!.value.duration.inSeconds > 90) {
        showSnackBar(context, 'Video is too long. Maximum duration is 90 seconds.');
        _disposeVideoController();
        setState(() {
          _isProcessingMedia = false;
        });
        return;
      }
      
      // Set aspect ratio for TikTok-style preview
      setState(() {
        final videoAspectRatio = _videoController!.value.aspectRatio;
        
        // If the video is landscape, we'll force it into a portrait frame
        if (videoAspectRatio > 1.0) {
          _videoAspectRatio = 9/16; // Default TikTok style
        } else {
          // Already portrait - use actual ratio but cap at 9:16
          _videoAspectRatio = videoAspectRatio < (9/16) ? videoAspectRatio : (9/16);
        }
      });
      
      _videoController!.setLooping(true);
      _videoController!.play();
      
      setState(() {
        _selectedMedia = video;
        _selectedType = StatusType.video;
        _isProcessingMedia = false;
      });
      
    } catch (e) {
      setState(() {
        _isProcessingMedia = false;
      });
      showSnackBar(context, 'Error picking video: $e');
    }
  }
  
  // Save text status
  void _saveTextStatus(String text, Map<String, String> backgroundInfo) {
    setState(() {
      _statusText = text;
      _backgroundInfo = backgroundInfo;
      _selectedType = StatusType.text;
    });
    
    _submitStatus();
  }
  
  // Submit status - Improved to ensure visibility in My Status
  Future<void> _submitStatus() async {
    // Validate
    if (_selectedType == StatusType.text && _statusText.trim().isEmpty) {
      showSnackBar(context, 'Please enter some text for your status');
      return;
    }
    
    if ((_selectedType == StatusType.image || _selectedType == StatusType.video) && 
        _selectedMedia == null) {
      showSnackBar(context, 'Please select media for your status');
      return;
    }
    
    // Check public status limit
    if (!_isPrivate) {
      final statusProvider = context.read<StatusProvider>();
      if (statusProvider.remainingPublicStatusToday <= 0) {
        showSnackBar(
          context, 
          'You have reached your daily limit for public statuses (${statusProvider.maxPublicStatusPerDay}). '
          'Try again tomorrow or post a private status.'
        );
        return;
      }
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final currentUser = context.read<AuthenticationProvider>().userModel!;
      final statusProvider = context.read<StatusProvider>();
      
      // Get text - either from status text (for text type) or caption (for media)
      final text = _selectedType == StatusType.text 
          ? _statusText 
          : _captionController.text;
      
      await statusProvider.createStatus(
        userId: currentUser.uid,
        userName: currentUser.name,
        userImage: currentUser.image,
        text: text,
        mediaFile: _selectedMedia,
        type: _selectedType,
        isPrivate: _isPrivate,
        backgroundInfo: _backgroundInfo,
        onSuccess: () {
          // Improved success handling to ensure status appears in My Status
          // Force refresh status list
          statusProvider.fetchStatuses(
            currentUserId: currentUser.uid,
            contactIds: currentUser.contactsUIDs,
          ).then((_) {
            // Show success message and navigate back
            showSnackBar(context, 'Status created successfully');
            
            // Check if we're on the home screen to navigate to status screen
            if (Navigator.canPop(context)) {
              // We're on the status screen, so just pop back
              Navigator.pop(context);
            } else {
              // We're on the home screen from bottom nav, navigate to status screen
              Navigator.pushReplacementNamed(context, Constants.statusScreen);
            }
          });
        },
        onError: (error) {
          showSnackBar(context, error);
          setState(() {
            _isSubmitting = false;
          });
        },
      );
    } catch (e) {
      showSnackBar(context, 'Error creating status: $e');
      setState(() {
        _isSubmitting = false;
      });
    }
  }
  
  // Remove selected media
  void _removeMedia() {
    _disposeVideoController();
    setState(() {
      _selectedMedia = null;
      _selectedType = StatusType.text;
    });
  }
  
  // Show bottom sheet with options (camera, gallery, video)
  void _showMediaOptions() {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: themeExtension?.receiverBubbleColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Create Status',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              
              // Text option
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.withOpacity(0.1),
                  child: const Icon(Icons.text_fields, color: Colors.purple),
                ),
                title: const Text('Text Status'),
                subtitle: const Text('Share your thoughts'),
                onTap: () {
                  Navigator.pop(context);
                  _showTextStatusCreator();
                },
              ),
              
              // Camera option
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withOpacity(0.1),
                  child: const Icon(Icons.camera_alt, color: Colors.green),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Capture a moment'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(true);
                },
              ),
              
              // Gallery option
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: const Icon(Icons.photo_library, color: Colors.blue),
                ),
                title: const Text('Photo from Gallery'),
                subtitle: const Text('Share an existing photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(false);
                },
              ),
              
              // Video option
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  child: const Icon(Icons.videocam, color: Colors.red),
                ),
                title: const Text('Video'),
                subtitle: const Text('Share a video clip (max 90s, 50MB)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Show text status creator
  void _showTextStatusCreator() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TextStatusCreator(
        onSave: _saveTextStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final statusProvider = context.watch<StatusProvider>();
    
    // Get remaining public status info
    final remainingPublic = statusProvider.remainingPublicStatusToday;
    final maxPublic = statusProvider.maxPublicStatusPerDay;
    
    // If we have selected media to show
    final bool hasMedia = _selectedMedia != null && (_selectedType == StatusType.image || _selectedType == StatusType.video);
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: themeExtension?.backgroundColor,
      appBar: AppBar(
        backgroundColor: themeExtension?.appBarColor,
        elevation: 0,
        title: const Text('Create Status'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // If submitting, don't allow exit
            if (_isSubmitting) return;
            
            // If has media or text selected, confirm exit
            if (hasMedia || _statusText.isNotEmpty) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Discard Status?'),
                  content: const Text('The current status will be lost if you exit now.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back to previous screen
                      },
                      child: const Text('DISCARD'),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (hasMedia)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeExtension?.accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('POST'),
              ),
            ),
        ],
      ),
      body: _isSubmitting
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: themeExtension?.accentColor,
                  ),
                  const SizedBox(height: 16),
                  const Text('Creating your status...'),
                ],
              ),
            )
          : _isProcessingMedia
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: themeExtension?.accentColor,
                      ),
                      const SizedBox(height: 16),
                      const Text('Processing media...'),
                    ],
                  ),
                )
              : hasMedia
                  ? _buildMediaPreview()
                  : _buildSelectMediaPrompt(remainingPublic, maxPublic),
    );
  }
  
  // Build the media preview once selected - Improved for TikTok-style video
  Widget _buildMediaPreview() {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    
    return Container(
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Media preview
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Media content - Improved for TikTok-style aspect ratio
                _selectedType == StatusType.image
                    ? Image.file(
                        _selectedMedia!,
                        fit: BoxFit.contain,
                      )
                    : _videoController != null && _videoController!.value.isInitialized
                        ? Center(
                            child: AspectRatio(
                              aspectRatio: _videoAspectRatio,
                              child: VideoPlayer(_videoController!),
                            ),
                          )
                        : const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                
                // Remove button
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: _removeMedia,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                
                // Play/Pause button for video
                if (_selectedType == StatusType.video && _videoController != null)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_videoController!.value.isPlaying) {
                            _videoController!.pause();
                          } else {
                            _videoController!.play();
                          }
                        });
                      },
                      child: Center(
                        child: _videoController!.value.isPlaying
                            ? Container() // Hide when playing
                            : Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Caption input
          Container(
            padding: const EdgeInsets.all(16),
            color: themeExtension?.appBarColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Caption field
                TextField(
                  controller: _captionController,
                  maxLength: 200,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Add a caption...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: themeExtension?.dividerColor ?? Colors.grey,
                      ),
                    ),
                    filled: true,
                    fillColor: themeExtension?.backgroundColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Privacy selector
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: themeExtension?.backgroundColor,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Text('Status privacy:'),
                      const Spacer(),
                      ChoiceChip(
                        label: const Text('Private'),
                        selected: _isPrivate,
                        onSelected: (selected) {
                          setState(() {
                            _isPrivate = true;
                          });
                        },
                        selectedColor: themeExtension?.accentColor?.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: _isPrivate
                              ? themeExtension?.accentColor
                              : null,
                          fontWeight: _isPrivate ? FontWeight.bold : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Public'),
                        selected: !_isPrivate,
                        onSelected: (selected) {
                          setState(() {
                            _isPrivate = false;
                          });
                        },
                        selectedColor: themeExtension?.accentColor?.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: !_isPrivate
                              ? themeExtension?.accentColor
                              : null,
                          fontWeight: !_isPrivate ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Build the initial screen when no media is selected
  Widget _buildSelectMediaPrompt(int remainingPublic, int maxPublic) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo,
              size: 80,
              color: themeExtension?.greyColor?.withOpacity(0.5),
            ),
            const SizedBox(height: 32),
            Text(
              'Create Status',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeExtension?.textColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Share a text, photo, or video status with your contacts or publicly',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: themeExtension?.greyColor,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showMediaOptions,
              icon: const Icon(Icons.add),
              label: const Text('CREATE STATUS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeExtension?.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeExtension?.receiverBubbleColor?.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: themeExtension?.dividerColor ?? Colors.grey.withOpacity(0.5),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: themeExtension?.greyColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Public Status Limit',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: themeExtension?.greyColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can post $remainingPublic more public statuses today (limit: $maxPublic per day)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: themeExtension?.greyColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Private statuses shared only with your contacts have no limit',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: themeExtension?.greyColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
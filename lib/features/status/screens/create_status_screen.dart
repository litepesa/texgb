import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/theme/modern_colors.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:video_player/video_player.dart';

class CreateStatusScreen extends StatefulWidget {
  const CreateStatusScreen({Key? key}) : super(key: key);

  @override
  State<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends State<CreateStatusScreen> {
  final TextEditingController _captionController = TextEditingController();
  File? _selectedMedia;
  StatusType _selectedType = StatusType.image;
  bool _isProcessing = false;
  bool _isCreating = false;
  VideoPlayerController? _videoController;
  bool _isVideoReady = false;
  String? _videoDuration;
  
  @override
  void initState() {
    super.initState();
    // Show the media picker automatically on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showMediaPicker();
    });
  }
  
  @override
  void dispose() {
    _captionController.dispose();
    _disposeVideo();
    super.dispose();
  }
  
  void _disposeVideo() {
    if (_videoController != null) {
      _videoController!.dispose();
      _videoController = null;
      _isVideoReady = false;
    }
  }
  
  Future<void> _pickImage(bool fromCamera) async {
    try {
      final File? pickedImage = await pickImage(
        fromCamera: fromCamera,
        onFail: (String message) {
          showSnackBar(context, message);
        },
      );
      
      if (pickedImage == null) return;
      
      // Crop the image
      await _cropImage(pickedImage.path);
    } catch (e) {
      showSnackBar(context, 'Error selecting image: $e');
    }
  }
  
  Future<void> _pickVideo([bool fromCamera = false]) async {
    try {
      setState(() {
        _isProcessing = true;
      });
      
      final File? pickedVideo = fromCamera
          ? await pickVideoFromCamera(
              onFail: (String message) {
                showSnackBar(context, message);
              },
              maxDuration: const Duration(seconds: 30), // Limit to 30 seconds for status
            )
          : await pickVideo(
              onFail: (String message) {
                showSnackBar(context, message);
              },
              maxDuration: const Duration(seconds: 30), // Limit to 30 seconds for status
            );
      
      setState(() {
        _isProcessing = false;
      });
      
      if (pickedVideo == null) return;
      
      setState(() {
        // Dispose old video controller if needed
        _disposeVideo();
        
        _selectedMedia = pickedVideo;
        _selectedType = StatusType.video;
        
        // Initialize video controller for preview
        _initializeVideoPreview(pickedVideo);
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      showSnackBar(context, 'Error selecting video: $e');
    }
  }
  
  Future<void> _initializeVideoPreview(File videoFile) async {
    try {
      _videoController = VideoPlayerController.file(videoFile);
      await _videoController!.initialize();
      
      // Format duration for display
      final duration = _videoController!.value.duration;
      _videoDuration = _formatDuration(duration);
      
      setState(() {
        _isVideoReady = true;
      });
    } catch (e) {
      debugPrint('Error initializing video preview: $e');
    }
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    return '$minutes:$seconds';
  }
  
  Future<void> _cropImage(String filePath) async {
    try {
      setState(() {
        _isProcessing = true;
      });
      
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: filePath,
        aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16), // Portrait aspect ratio for status
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
      
      setState(() {
        _isProcessing = false;
      });
      
      if (croppedFile != null) {
        // Dispose any existing video controller
        _disposeVideo();
        
        setState(() {
          _selectedMedia = File(croppedFile.path);
          _selectedType = StatusType.image;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      showSnackBar(context, 'Error cropping image: $e');
    }
  }
  
  void _createTextStatus() {
    final text = _captionController.text.trim();
    if (text.isEmpty) {
      showSnackBar(context, 'Please enter some text for your status');
      return;
    }
    
    // Create a text status
    _createStatus(text, null, StatusType.text);
  }
  
  void _createStatus([String? textContent, File? mediaFile, StatusType? type]) async {
    // Use parameters if provided, otherwise use state variables
    final content = textContent ?? _captionController.text.trim();
    final media = mediaFile ?? _selectedMedia;
    final statusType = type ?? _selectedType;
    
    // For media statuses, ensure we have media
    if (statusType != StatusType.text && media == null) {
      showSnackBar(context, 'Please select an image or video');
      return;
    }
    
    setState(() {
      _isCreating = true;
    });
    
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    final statusProvider = context.read<StatusProvider>();
    
    if (statusType == StatusType.text) {
      // For text status, we don't need a file
      await statusProvider.createTextStatus(
        currentUser: currentUser,
        text: content,
        onSuccess: () {
          Navigator.of(context).pop(); // Return to the status screen
          showSnackBar(context, 'Status created successfully');
        },
        onError: (error) {
          setState(() {
            _isCreating = false;
          });
          showSnackBar(context, 'Error creating status: $error');
        },
      );
    } else {
      // For media status
      await statusProvider.createStatus(
        currentUser: currentUser,
        mediaFile: media!,
        type: statusType,
        caption: content.isNotEmpty ? content : null,
        onSuccess: () {
          Navigator.of(context).pop(); // Return to the status screen
          showSnackBar(context, 'Status created successfully');
        },
        onError: (error) {
          setState(() {
            _isCreating = false;
          });
          showSnackBar(context, 'Error creating status: $error');
        },
      );
    }
  }
  
  void _showMediaPicker() {
    final modernTheme = context.modernTheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: modernTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: modernTheme.textSecondaryColor!.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Create Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: modernTheme.textColor,
                ),
              ),
            ),
            
            // Camera option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ModernColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt, color: ModernColors.primaryBlue),
              ),
              title: Text(
                'Take a photo',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.mediumImpact();
                _pickImage(true);
              },
            ),
            
            // Gallery option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ModernColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library, color: ModernColors.success),
              ),
              title: Text(
                'Choose from gallery',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.mediumImpact();
                _pickImage(false);
              },
            ),
            
            // Video camera option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ModernColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.videocam, color: ModernColors.warning),
              ),
              title: Text(
                'Record video',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.mediumImpact();
                _pickVideo(true); // true for camera
              },
            ),
            
            // Video gallery option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ModernColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.video_library, color: ModernColors.error),
              ),
              title: Text(
                'Select video from gallery',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.mediumImpact();
                _pickVideo(false); // false for gallery
              },
            ),
            
            // Text option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ModernColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.text_fields, color: ModernColors.primaryPurple),
              ),
              title: Text(
                'Text status',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.mediumImpact();
                _showTextStatusEditor();
              },
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  void _showTextStatusEditor() {
    final modernTheme = context.modernTheme;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: modernTheme.surfaceColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Text(
                'Create Text Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: modernTheme.textColor,
                ),
              ),
              const SizedBox(height: 20),
              
              // Text input
              TextField(
                controller: _captionController,
                maxLength: 100,
                maxLines: 3,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter your status text...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_captionController.text.trim().isEmpty) {
                        showSnackBar(context, 'Please enter some text');
                        return;
                      }
                      Navigator.pop(context);
                      _createTextStatus();
                    },
                    child: const Text('Post'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final primaryColor = modernTheme.primaryColor!;
    final textColor = modernTheme.textColor!;
    final textSecondaryColor = modernTheme.textSecondaryColor!;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Status'),
        actions: [
          if (_selectedMedia != null || _selectedType == StatusType.text)
            TextButton(
              onPressed: (_selectedMedia != null || _selectedType == StatusType.text) && !_isProcessing && !_isCreating
                  ? () => _createStatus()
                  : null,
              child: _isCreating
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Post',
                      style: TextStyle(
                        color: (_selectedMedia != null || _selectedType == StatusType.text) && !_isProcessing && !_isCreating
                            ? primaryColor
                            : textSecondaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
        ],
      ),
      body: _isProcessing
          ? _buildLoadingView()
          : _selectedMedia != null || _selectedType == StatusType.text
              ? _buildPreviewView()
              : _buildInitialView(),
    );
  }
  
  Widget _buildLoadingView() {
    final modernTheme = context.modernTheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: modernTheme.primaryColor),
          const SizedBox(height: 16),
          Text(
            'Processing media...',
            style: TextStyle(
              fontSize: 16,
              color: modernTheme.textColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInitialView() {
    final modernTheme = context.modernTheme;
    final primaryColor = modernTheme.primaryColor!;
    final textColor = modernTheme.textColor!;
    final textSecondaryColor = modernTheme.textSecondaryColor!;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo,
            size: 80,
            color: primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Share a moment with your contacts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your status will be visible for 24 hours',
            style: TextStyle(
              fontSize: 14,
              color: textSecondaryColor,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showMediaPicker,
            icon: const Icon(Icons.add),
            label: const Text('Add Status'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPreviewView() {
    final modernTheme = context.modernTheme;
    final primaryColor = modernTheme.primaryColor!;
    final surfaceColor = modernTheme.surfaceColor!;
    
    return Column(
      children: [
        // Media preview
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Media preview - based on selected type
                if (_selectedType == StatusType.image)
                  Image.file(
                    _selectedMedia!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  )
                else if (_selectedType == StatusType.video)
                  _buildVideoPreview()
                else if (_selectedType == StatusType.text)
                  _buildTextPreview(),
                
                // Caption input
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _captionController,
                    maxLength: 100,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Add a caption...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      filled: true,
                      fillColor: modernTheme.surfaceVariantColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Bottom toolbar
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: surfaceColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _showMediaPicker,
                icon: const Icon(Icons.refresh),
                label: const Text('Change Media'),
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                ),
              ),
              ElevatedButton(
                onPressed: _isCreating ? null : () => _createStatus(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isCreating
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Post Status'),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildVideoPreview() {
    if (!_isVideoReady || _videoController == null) {
      return Container(
        height: 400,
        width: double.infinity,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    
    return Container(
      height: 400,
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video preview
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          
          // Play button overlay
          IconButton(
            icon: Icon(
              _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 50,
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
          
          // Duration indicator
          if (_videoDuration != null)
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _videoDuration!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildTextPreview() {
    final text = _captionController.text.isEmpty 
        ? 'Enter your text status...'
        : _captionController.text;
    
    return Container(
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade800,
            Colors.purple.shade500,
            Colors.indigo.shade500,
          ],
        ),
      ),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black,
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
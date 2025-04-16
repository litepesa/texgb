import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/widgets/text_status_editor.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/providers/status_provider.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:textgb/widgets/app_bar_back_button.dart';
import 'package:video_player/video_player.dart';

class StatusCreateScreen extends StatefulWidget {
  const StatusCreateScreen({Key? key}) : super(key: key);

  @override
  State<StatusCreateScreen> createState() => _StatusCreateScreenState();
}

class _StatusCreateScreenState extends State<StatusCreateScreen> {
  File? _mediaFile;
  bool _isVideo = false;
  String _caption = '';
  final TextEditingController _captionController = TextEditingController();
  VideoPlayerController? _videoController;
  bool _isInitialized = false;

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Show the media picker options when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showMediaOptions();
    });
  }

  // Show bottom sheet with options to pick media
  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Create Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Camera option
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.camera_alt, color: Colors.white),
              ),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            
            // Gallery option
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.purple,
                child: Icon(Icons.photo_library, color: Colors.white),
              ),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            
            // Video option
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(Icons.videocam, color: Colors.white),
              ),
              title: const Text('Video'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo();
              },
            ),
            
            // Text status option
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.text_fields, color: Colors.white),
              ),
              title: const Text('Text'),
              onTap: () {
                Navigator.pop(context);
                _createTextStatus();
              },
            ),
          ],
        ),
      ),
    ).then((value) {
      // If no media is selected, go back
      if (_mediaFile == null && !mounted) {
        Navigator.pop(context);
      }
    });
  }

  // Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 70,
      );
      
      if (pickedFile != null) {
        // Crop the image
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16),
          compressQuality: 70,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: Theme.of(context).primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              title: 'Crop Image',
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            _mediaFile = File(croppedFile.path);
            _isVideo = false;
          });
        }
      } else {
        // User canceled picking image, go back to options
        _showMediaOptions();
      }
    } catch (e) {
      showSnackBar(context, 'Error picking image: $e');
      _showMediaOptions();
    }
  }

  // Pick video from gallery
  Future<void> _pickVideo() async {
    try {
      final pickedFile = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );
      
      if (pickedFile != null) {
        setState(() {
          _mediaFile = File(pickedFile.path);
          _isVideo = true;
        });
        
        // Initialize video controller
        _videoController = VideoPlayerController.file(_mediaFile!);
        await _videoController!.initialize();
        
        setState(() {
          _isInitialized = true;
        });
        
        // Start playing with volume off
        _videoController!.setVolume(0);
        _videoController!.play();
        _videoController!.setLooping(true);
      } else {
        // User canceled picking video, go back to options
        _showMediaOptions();
      }
    } catch (e) {
      showSnackBar(context, 'Error picking video: $e');
      _showMediaOptions();
    }
  }

  // Navigate to text status editor
  void _createTextStatus() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TextStatusEditor(),
      ),
    ).then((value) {
      if (value == null) {
        Navigator.pop(context);
      }
    });
  }

  // Upload status to Firebase
  Future<void> _uploadStatus() async {
    if (_mediaFile == null) return;
    
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    final statusProvider = context.read<StatusProvider>();
    
    try {
      await statusProvider.uploadMediaStatus(
        currentUser: currentUser,
        file: _mediaFile!,
        statusType: _isVideo ? StatusType.video : StatusType.image,
        caption: _caption,
        onSuccess: () {
          Navigator.pop(context);
          showSnackBar(context, 'Status uploaded successfully');
        },
        onError: (error) {
          showSnackBar(context, 'Error uploading status: $error');
        },
      );
    } catch (e) {
      showSnackBar(context, 'Error uploading status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusProvider = context.watch<StatusProvider>();
    
    // If no media file is selected yet, show loading
    if (_mediaFile == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: AppBarBackButton(
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Display selected media
          _isVideo
              ? _isInitialized
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator())
              : Image.file(
                  _mediaFile!,
                  fit: BoxFit.cover,
                ),
          
          // Caption input at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _captionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Add a caption...',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _caption = value;
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                    onPressed: statusProvider.isUploading
                        ? null
                        : _uploadStatus,
                  ),
                ],
              ),
            ),
          ),
          
          // Loading overlay
          if (statusProvider.isUploading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Uploading status...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
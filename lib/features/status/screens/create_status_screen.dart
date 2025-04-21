import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/features/status/widgets/color_picker_row.dart';
import 'package:textgb/features/status/widgets/font_style_picker.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:video_player/video_player.dart';

class CreateStatusScreen extends StatefulWidget {
  const CreateStatusScreen({Key? key}) : super(key: key);

  @override
  State<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends State<CreateStatusScreen> {
  final TextEditingController _captionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  StatusType _selectedType = StatusType.text;
  List<File> _mediaFiles = []; // Updated to list for multiple files
  VideoPlayerController? _videoController;
  bool _isLoading = false;
  
  // For multi-image selection
  int _currentMediaIndex = 0;
  PageController? _mediaPageController;
  
  // Styling options for text status
  String _backgroundColor = '#000000';
  String _textColor = '#FFFFFF';
  String _fontStyle = 'normal';
  
  @override
  void initState() {
    super.initState();
    _mediaPageController = PageController(initialPage: 0);
  }
  
  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    _mediaPageController?.dispose();
    super.dispose();
  }
  
  // Select image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      
      if (source == ImageSource.gallery) {
        // For gallery, allow multi-selection
        final List<XFile> images = await picker.pickMultiImage(
          maxWidth: 1800,
          maxHeight: 1800,
          imageQuality: 85,
        );
        
        if (images.isEmpty) return;
        
        // Limit to 9 images
        final List<XFile> limitedImages = images.length > 9 ? images.sublist(0, 9) : images;
        
        setState(() {
          _mediaFiles = limitedImages.map((xFile) => File(xFile.path)).toList();
          _selectedType = StatusType.image;
          _currentMediaIndex = 0;
          _mediaPageController?.jumpToPage(0);
        });
        
        if (images.length > 9) {
          showSnackBar(context, 'Maximum 9 images allowed. Only the first 9 were selected.');
        }
      } else {
        // For camera, add to existing selection if under 9 images
        if (_mediaFiles.length >= 9) {
          showSnackBar(context, 'Maximum 9 images allowed');
          return;
        }
        
        final XFile? image = await picker.pickImage(
          source: source,
          maxWidth: 1800,
          maxHeight: 1800,
          imageQuality: 85,
        );
        
        if (image == null) return;
        
        setState(() {
          _mediaFiles.add(File(image.path));
          _selectedType = StatusType.image;
          _currentMediaIndex = _mediaFiles.length - 1;
          _mediaPageController?.jumpToPage(_currentMediaIndex);
        });
      }
    } catch (e) {
      showSnackBar(context, 'Error picking image: $e');
    }
  }
  
  // Select video from gallery or camera
  Future<void> _pickVideo(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 60), // Limit to 60 seconds
      );
      
      if (video == null) return;
      
      final videoFile = File(video.path);
      
      // Initialize video controller to check duration and preview
      _videoController = VideoPlayerController.file(videoFile);
      await _videoController!.initialize();
      
      // Check if video is too long (over 60 seconds)
      if (_videoController!.value.duration.inSeconds > 60) {
        showSnackBar(context, 'Video must be 60 seconds or less');
        _videoController!.dispose();
        _videoController = null;
        return;
      }
      
      setState(() {
        _mediaFiles = [videoFile]; // Videos replace all existing media
        _selectedType = StatusType.video;
        _currentMediaIndex = 0;
        _mediaPageController?.jumpToPage(0);
      });
      
      // Start playing preview
      _videoController!.play();
      _videoController!.setLooping(true);
    } catch (e) {
      showSnackBar(context, 'Error picking video: $e');
    }
  }
  
  // Show media picker bottom sheet
  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              subtitle: Text('Select up to 9 images'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Record video'),
              onTap: () {
                Navigator.of(context).pop();
                _pickVideo(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Choose video from gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickVideo(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // Change status type
  void _setStatusType(StatusType type) {
    setState(() {
      _selectedType = type;
      
      // Clear media file if switching to text
      if (type == StatusType.text) {
        _mediaFiles = [];
        _videoController?.dispose();
        _videoController = null;
      } else if (_mediaFiles.isEmpty) {
        // If switching to media type but no media selected, show picker
        _showMediaPicker();
      }
    });
  }

  // Navigate to previous media in preview
  void _previousMedia() {
    if (_currentMediaIndex > 0) {
      setState(() {
        _currentMediaIndex--;
      });
      _mediaPageController?.animateToPage(
        _currentMediaIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Navigate to next media in preview
  void _nextMedia() {
    if (_currentMediaIndex < _mediaFiles.length - 1) {
      setState(() {
        _currentMediaIndex++;
      });
      _mediaPageController?.animateToPage(
        _currentMediaIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Handle page change in PageView
  void _onMediaPageChanged(int page) {
    setState(() {
      _currentMediaIndex = page;
    });
  }
  
  // Remove current media item
  void _removeCurrentMedia() {
    if (_mediaFiles.isEmpty) return;
    
    setState(() {
      _mediaFiles.removeAt(_currentMediaIndex);
      
      if (_mediaFiles.isEmpty) {
        // No more media
        _currentMediaIndex = 0;
      } else if (_currentMediaIndex >= _mediaFiles.length) {
        // If current index is now out of bounds, adjust it
        _currentMediaIndex = _mediaFiles.length - 1;
      }
      
      // Update page controller
      if (_mediaFiles.isNotEmpty) {
        _mediaPageController?.jumpToPage(_currentMediaIndex);
      }
    });
  }
  
  // Add more images
  void _addMoreImages() {
    if (_mediaFiles.length >= 9) {
      showSnackBar(context, 'Maximum 9 images allowed');
      return;
    }
    
    _pickImage(ImageSource.gallery);
  }
  
  // Create and post the status
  Future<void> _postStatus() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    if (_selectedType != StatusType.text && _mediaFiles.isEmpty) {
      showSnackBar(context, 'Please select a media file');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userModel = context.read<AuthenticationProvider>().userModel!;
      final statusProvider = context.read<StatusProvider>();
      
      final statusModel = await statusProvider.createStatus(
        user: userModel,
        caption: _captionController.text.trim(),
        statusType: _selectedType,
        mediaFile: _mediaFiles.isNotEmpty ? _mediaFiles.first : null, // For backward compatibility
        mediaFiles: _mediaFiles,
        backgroundColor: _backgroundColor,
        textColor: _textColor,
        fontStyle: _fontStyle,
      );
      
      if (statusModel != null) {
        if (mounted) {
          showSnackBar(context, 'Status posted successfully!');
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          showSnackBar(context, 'Failed to post status. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error posting status: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? const Color(0xFF07C160);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Status'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isLoading
              ? Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _postStatus,
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF07C160),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  child: const Text('Post'),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Type selection tabs
            Container(
              color: themeExtension?.appBarColor,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTypeTab(StatusType.text, 'Text'),
                  _buildTypeTab(StatusType.image, 'Photo'),
                  _buildTypeTab(StatusType.video, 'Video'),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Media preview or text style options
                    if (_selectedType != StatusType.text) ...[
                      _buildMediaPreview(),
                    ] else ...[
                      _buildTextStyleOptions(),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Caption field
                    TextFormField(
                      controller: _captionController,
                      decoration: InputDecoration(
                        hintText: _selectedType == StatusType.text 
                            ? 'What\'s on your mind?' 
                            : 'Add a caption...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: _selectedType == StatusType.text ? 8 : 3,
                      minLines: _selectedType == StatusType.text ? 5 : 1,
                      validator: (value) {
                        if (_selectedType == StatusType.text && 
                            (value == null || value.trim().isEmpty)) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                      style: TextStyle(
                        fontSize: _selectedType == StatusType.text ? 18 : 16,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Status expiration info card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, color: accentColor),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    '72-hour expiration',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'This status will automatically disappear after 72 hours.',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTypeTab(StatusType type, String label) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? const Color(0xFF07C160);
    final isSelected = _selectedType == type;
    
    return GestureDetector(
      onTap: () => _setStatusType(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  Widget _buildMediaPreview() {
    if (_mediaFiles.isEmpty) {
      // Empty state - prompt to add media
      return GestureDetector(
        onTap: _showMediaPicker,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _selectedType == StatusType.image 
                      ? Icons.add_photo_alternate 
                      : Icons.videocam,
                  size: 48,
                  color: Colors.grey[700],
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedType == StatusType.image 
                      ? 'Add Photos (up to 9)' 
                      : 'Add Video',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (_selectedType == StatusType.image) {
      // Image preview with multi-image support
      return Column(
        children: [
          // Media preview area with PageView for swiping
          Stack(
            children: [
              // Main preview with PageView for swiping
              Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: PageView.builder(
                    controller: _mediaPageController,
                    onPageChanged: _onMediaPageChanged,
                    itemCount: _mediaFiles.length,
                    itemBuilder: (context, index) {
                      return Image.file(
                        _mediaFiles[index],
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
              ),
              
              // Delete button
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _removeCurrentMedia,
                  child: Container(
                    padding: const EdgeInsets.all(4),
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
              
              // Add more button (if less than 9 images)
              if (_mediaFiles.length < 9)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _addMoreImages,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              
              // Page indicator dots (only if multiple images)
              if (_mediaFiles.length > 1)
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _mediaFiles.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentMediaIndex
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Navigation arrows (only if multiple images)
              if (_mediaFiles.length > 1) ...[
                // Left arrow (only if not on first image)
                if (_currentMediaIndex > 0)
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _previousMedia,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                
                // Right arrow (only if not on last image)
                if (_currentMediaIndex < _mediaFiles.length - 1)
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _nextMedia,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
          
          // Image counter text
          if (_mediaFiles.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '${_currentMediaIndex + 1}/${_mediaFiles.length} photos',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          
          // Thumbnail row for quick navigation between images
          if (_mediaFiles.length > 1)
            Container(
              height: 60,
              margin: const EdgeInsets.only(top: 8.0),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _mediaFiles.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentMediaIndex = index;
                      });
                      _mediaPageController?.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: index == _currentMediaIndex
                            ? Border.all(color: Colors.blue, width: 2)
                            : null,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.file(
                          _mediaFiles[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      );
    } else if (_selectedType == StatusType.video && _videoController != null) {
      // Video preview
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _mediaFiles = [];
                  _videoController?.dispose();
                  _videoController = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
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
        ],
      );
    } else {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('Error loading media'),
        ),
      );
    }
  }
  
  Widget _buildTextStyleOptions() {
    // Preview area with selected styles applied
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: _parseColor(_backgroundColor),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              _captionController.text.isEmpty 
                  ? 'Your text will appear here' 
                  : _captionController.text,
              style: TextStyle(
                color: _parseColor(_textColor),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: _fontStyle == 'normal' ? null : _fontStyle,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Background color selection
        const Text(
          'Background Color',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ColorPickerRow(
          selectedColor: _backgroundColor,
          onColorSelected: (color) {
            setState(() {
              _backgroundColor = color;
            });
          },
          colors: const [
            '#000000', '#FFFFFF', '#FF5733', '#33FF57', 
            '#3357FF', '#F033FF', '#FF3380', '#33FFF9'
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Text color selection
        const Text(
          'Text Color',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ColorPickerRow(
          selectedColor: _textColor,
          onColorSelected: (color) {
            setState(() {
              _textColor = color;
            });
          },
          colors: const [
            '#FFFFFF', '#000000', '#FF5733', '#33FF57', 
            '#3357FF', '#F033FF', '#FF3380', '#33FFF9'
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Font style selection
        const Text(
          'Font Style',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        FontStylePicker(
          selectedStyle: _fontStyle,
          onStyleSelected: (style) {
            setState(() {
              _fontStyle = style;
            });
          },
        ),
      ],
    );
  }
  
  // Helper function to parse hex color
  Color _parseColor(String hexCode) {
    try {
      hexCode = hexCode.replaceAll('#', '');
      if (hexCode.length == 6) {
        hexCode = 'FF$hexCode';
      }
      return Color(int.parse(hexCode, radix: 16));
    } catch (e) {
      return hexCode.toLowerCase() == '#ffffff' ? Colors.white : Colors.black;
    }
  }
}
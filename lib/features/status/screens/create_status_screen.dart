// lib/features/status/screens/create_status_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/features/status/utils/video_processor.dart';
import 'package:textgb/features/status/widgets/video_status_widget.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class CreateStatusScreen extends ConsumerStatefulWidget {
  final StatusType? initialType;
  final File? initialFile;

  const CreateStatusScreen({
    super.key,
    this.initialType,
    this.initialFile,
});

  @override
  ConsumerState<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends ConsumerState<CreateStatusScreen>
    with TickerProviderStateMixin {
  StatusType _selectedType = StatusType.text;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  
  File? _selectedFile;
  File? _processedFile; // Processed video file
  VideoPlayerController? _videoController;
  VideoInfo? _videoInfo;
  String? _videoThumbnail;
  bool _isVideoInitialized = false;
  bool _isProcessingVideo = false;
  double _processingProgress = 0.0;
  
  String _backgroundColor = '#000000';
  String _fontColor = '#FFFFFF';
  String _fontFamily = 'default';
  
  final List<String> _backgroundColors = [
    '#000000', '#1A1A1A', '#333333', '#666666',
    '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4',
    '#FFEAA7', '#DDA0DD', '#98D8C8', '#F7DC6F',
    '#BB8FCE', '#85C1E9', '#F8C471', '#82E0AA',
  ];

  final List<String> _fontFamilies = [
    'default', 'serif', 'monospace', 'cursive'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
    if (widget.initialFile != null) {
      _selectedFile = widget.initialFile;
      if (_selectedType == StatusType.video) {
        _processVideoFile(widget.initialFile!);
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _processVideoFile(File videoFile) async {
    // Just initialize the video player without processing
    // Processing will happen when user clicks share
    setState(() {
      _selectedFile = videoFile;
    });
    
    try {
      // Get basic video info for display
      final videoInfo = await VideoProcessor.getVideoInfo(videoFile.path);
      if (videoInfo != null) {
        setState(() {
          _videoInfo = videoInfo;
        });
      }
      
      // Initialize video player for preview
      await _initializeVideo();
      await _generateVideoThumbnail();
    } catch (e) {
      debugPrint('Error getting video info: $e');
      // Continue anyway, just won't show video info
    }
  }

  void _showProcessingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = context.modernTheme;
        return AlertDialog(
          backgroundColor: theme.surfaceColor,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                value: _processingProgress > 0 ? _processingProgress : null,
                color: theme.primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(color: theme.textColor),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _processingProgress > 0 ? _processingProgress : null,
                backgroundColor: theme.dividerColor,
                valueColor: AlwaysStoppedAnimation(theme.primaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                _processingProgress > 0 ? '${(_processingProgress * 100).toInt()}%' : '',
                style: TextStyle(
                  color: theme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _initializeVideo() async {
    final videoFile = _selectedFile; // Use selected file, not processed
    if (videoFile != null && _selectedType == StatusType.video) {
      try {
        _videoController = VideoPlayerController.file(videoFile);
        await _videoController!.initialize();
        
        setState(() {
          _isVideoInitialized = true;
        });
      } catch (e) {
        debugPrint('Error initializing video: $e');
        if (mounted) {
          showSnackBar(context, 'Error loading video: $e');
        }
      }
    }
  }

  Future<void> _generateVideoThumbnail() async {
    final videoFile = _selectedFile; // Use selected file, not processed
    if (videoFile != null) {
      try {
        final thumbnail = await VideoThumbnail.thumbnailFile(
          video: videoFile.path,
          thumbnailPath: (await getTemporaryDirectory()).path,
          imageFormat: ImageFormat.JPEG,
          maxHeight: 400,
          quality: 75,
        );
        
        if (mounted) {
          setState(() {
            _videoThumbnail = thumbnail;
          });
        }
      } catch (e) {
        debugPrint('Error generating thumbnail: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    final statusNotifier = ref.watch(statusNotifierProvider);
    
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.surfaceColor,
        title: Text(
          'Create Status',
          style: TextStyle(color: theme.textColor),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: statusNotifier.when(
              data: (state) => state.isCreating || _isProcessingVideo ? null : _createStatus,
              loading: () => null,
              error: (_, __) => _createStatus,
            ),
            child: statusNotifier.when(
              data: (state) => state.isCreating || _isProcessingVideo
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.primaryColor,
                      ),
                    )
                  : Text(
                      'Share',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              loading: () => Text(
                'Share',
                style: TextStyle(color: theme.textSecondaryColor),
              ),
              error: (_, __) => Text(
                'Share',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Type selector
          _buildTypeSelector(theme),
          
          // Content area
          Expanded(
            child: _buildContentArea(theme),
          ),
          
          // Privacy info panel (read-only)
          _buildPrivacyInfoPanel(theme),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(ModernThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor!, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildTypeOption(StatusType.text, Icons.text_fields, 'Text', theme),
          _buildTypeOption(StatusType.image, Icons.image, 'Photo', theme),
          _buildTypeOption(StatusType.video, Icons.videocam, 'Video', theme),
        ],
      ),
    );
  }

  Widget _buildTypeOption(StatusType type, IconData icon, String label, ModernThemeExtension theme) {
    final isSelected = _selectedType == type;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (type != _selectedType && !_isProcessingVideo) {
            setState(() => _selectedType = type);
            if (type != StatusType.video) {
              _videoController?.dispose();
              _videoController = null;
              setState(() {
                _isVideoInitialized = false;
                _videoThumbnail = null;
                _processedFile = null;
                _videoInfo = null;
              });
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.primaryColor!.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? theme.primaryColor : theme.textSecondaryColor,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? theme.primaryColor : theme.textSecondaryColor,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea(ModernThemeExtension theme) {
    switch (_selectedType) {
      case StatusType.text:
        return _buildTextStatus(theme);
      case StatusType.image:
        return _buildImageStatus(theme);
      case StatusType.video:
        return _buildVideoStatus(theme);
      default:
        return _buildTextStatus(theme);
    }
  }

  Widget _buildVideoStatus(ModernThemeExtension theme) {
    return Column(
      children: [
        // Video preview
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surfaceVariantColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: (_processedFile ?? _selectedFile) != null
                ? _buildVideoPreview(theme)
                : _buildMediaPicker(theme),
          ),
        ),
        
        // Video info and caption
        if ((_processedFile ?? _selectedFile) != null) ...[
          // Video info with enhanced features indicator
          if (_videoInfo != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.videocam, color: theme.textSecondaryColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Duration: ${_videoInfo!.durationText}',
                    style: TextStyle(
                      color: theme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.graphic_eq, color: theme.primaryColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Enhanced Audio',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_videoInfo!.fileSize != (_selectedFile?.lengthSync() ?? 0))
                    Expanded(
                      child: Text(
                        ' • Optimized ${_videoInfo!.fileSizeText}',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          
          // Caption input
          _buildCaptionInput(theme),
          const SizedBox(height: 16), // Bottom padding
        ],
      ],
    );
  }

  Widget _buildVideoPreview(ModernThemeExtension theme) {
    return Stack(
      children: [
        // Video preview with enhanced controls
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: VideoStatusWidget(
              videoFile: _selectedFile, // Use selected file for preview
              autoPlay: false,
              showControls: true,
            ),
          ),
        ),
        
        // Remove button
        Positioned(
          top: 16,
          right: 16,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedFile = null;
                _processedFile = null;
                _videoController?.dispose();
                _videoController = null;
                _isVideoInitialized = false;
                _videoThumbnail = null;
                _videoInfo = null;
              });
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.black54,
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
  }

  Widget _buildTextStatus(ModernThemeExtension theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(int.parse(_backgroundColor.substring(1, 7), radix: 16) + 0xFF000000),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Text input
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: TextField(
                controller: _textController,
                style: TextStyle(
                  color: Color(int.parse(_fontColor.substring(1, 7), radix: 16) + 0xFF000000),
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  fontFamily: _fontFamily == 'default' ? null : _fontFamily,
                ),
                maxLines: null,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Type your status...',
                  hintStyle: TextStyle(
                    color: theme.textColor,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
          ),
          
          // Background color selector
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: _showBackgroundColorPicker,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.palette,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageStatus(ModernThemeExtension theme) {
    return Column(
      children: [
        // Image preview
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surfaceVariantColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _selectedFile != null
                ? _buildImagePreview(theme)
                : _buildMediaPicker(theme),
          ),
        ),
        
        // Caption input
        if (_selectedFile != null) ...[
          _buildCaptionInput(theme),
          const SizedBox(height: 16), // Bottom padding
        ],
      ],
    );
  }

  Widget _buildImagePreview(ModernThemeExtension theme) {
    return Stack(
      children: [
        // Image preview
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_selectedFile!, fit: BoxFit.cover),
          ),
        ),
        
        // Remove button
        Positioned(
          top: 16,
          right: 16,
          child: GestureDetector(
            onTap: () => setState(() => _selectedFile = null),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.black54,
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
  }

  Widget _buildMediaPicker(ModernThemeExtension theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedType == StatusType.image ? Icons.add_photo_alternate : Icons.videocam,
            size: 64,
            color: theme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedType == StatusType.image ? 'Add a photo' : 'Record a video',
            style: TextStyle(
              color: theme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          if (_selectedType == StatusType.video)
            Text(
              'Videos will be enhanced with crisp audio\nand optimized for sharing',
              style: TextStyle(
                color: theme.textSecondaryColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMediaButton(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: _pickFromGallery,
                theme: theme,
              ),
              _buildMediaButton(
                icon: Icons.camera_alt,
                label: 'Camera',
                onTap: _pickFromCamera,
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCaptionInput(ModernThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _captionController,
        style: TextStyle(color: theme.textColor),
        decoration: InputDecoration(
          hintText: 'Add a caption...',
          hintStyle: TextStyle(color: theme.textSecondaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: theme.dividerColor!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: theme.dividerColor!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: theme.primaryColor!),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ModernThemeExtension theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: theme.primaryColor,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBackgroundColorPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final theme = context.modernTheme;
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose Background Color',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _backgroundColors.length,
                itemBuilder: (context, index) {
                  final color = _backgroundColors[index];
                  final isSelected = _backgroundColor == color;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() => _backgroundColor = color);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(int.parse(color.substring(1, 7), radix: 16) + 0xFF000000),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: theme.primaryColor!, width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _pickFromGallery() async {
    try {
      if (_selectedType == StatusType.image) {
        final file = await pickImage(
          fromCamera: false,
          onFail: (error) => showSnackBar(context, error),
        );
        if (file != null) {
          setState(() => _selectedFile = file);
        }
      } else {
        final file = await pickVideo(
          onFail: (error) => showSnackBar(context, error),
          maxDuration: const Duration(minutes: 10), // Allow longer videos, will be processed
        );
        if (file != null) {
          setState(() => _selectedFile = file);
          await _processVideoFile(file);
        }
      }
    } catch (e) {
      showSnackBar(context, 'Error picking file: $e');
    }
  }

  void _pickFromCamera() async {
    try {
      if (_selectedType == StatusType.image) {
        final file = await pickImage(
          fromCamera: true,
          onFail: (error) => showSnackBar(context, error),
        );
        if (file != null) {
          setState(() => _selectedFile = file);
        }
      } else {
        final file = await pickVideoFromCamera(
          onFail: (error) => showSnackBar(context, error),
          maxDuration: const Duration(minutes: 10), // Allow longer videos, will be processed
        );
        if (file != null) {
          setState(() => _selectedFile = file);
          await _processVideoFile(file);
        }
      }
    } catch (e) {
      showSnackBar(context, 'Error using camera: $e');
    }
  }

  void _createStatus() async {
    if (_isProcessingVideo) {
      showSnackBar(context, 'Please wait for video processing to complete');
      return;
    }

    String content = '';
    String? caption;

    // Validate content
    if (_selectedType == StatusType.text) {
      content = _textController.text.trim();
      if (content.isEmpty) {
        showSnackBar(context, 'Please enter some text');
        return;
      }
    } else {
      final fileToUse = _processedFile ?? _selectedFile;
      if (fileToUse == null) {
        showSnackBar(context, 'Please select a file');
        return;
      }
      
      content = ''; // Will be filled by repository with uploaded URL
      caption = _captionController.text.trim();
      if (caption.isEmpty) caption = null;
    }

    try {
      final fileToUpload = _processedFile ?? _selectedFile;
      
      // Privacy settings will be determined by the global defaults in the status provider
      final statusId = await ref.read(statusNotifierProvider.notifier).createStatus(
        type: _selectedType,
        content: content,
        caption: caption,
        backgroundColor: _selectedType == StatusType.text ? _backgroundColor : null,
        fontColor: _selectedType == StatusType.text ? _fontColor : null,
        fontFamily: _selectedType == StatusType.text ? _fontFamily : null,
        mediaFile: fileToUpload,
        // Removed privacyType parameter - will use global defaults
      );

      if (statusId != null) {
        if (mounted) {
          Navigator.pop(context);
          showSnackBar(context, _selectedType == StatusType.video 
              ? 'Status shared with enhanced audio!' 
              : 'Status shared successfully!');
        }
      } else {
        showSnackBar(context, 'Failed to share status');
      }
    } catch (e) {
      showSnackBar(context, 'Error sharing status: $e');
    }
  }

  Widget _buildPrivacyInfoPanel(ModernThemeExtension theme) {
    final privacySettingsAsync = ref.watch(statusPrivacySettingsProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor!, width: 1),
        ),
      ),
      child: privacySettingsAsync.when(
        data: (settings) {
          final privacyType = StatusPrivacyTypeExtension.fromString(
            settings['defaultPrivacy']?.toString() ?? 'all_contacts'
          );
          final allowedViewers = List<String>.from(settings['allowedViewers'] ?? []);
          final excludedViewers = List<String>.from(settings['excludedViewers'] ?? []);
          
          return Row(
            children: [
              Icon(
                Icons.visibility,
                color: theme.textSecondaryColor,
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status visibility',
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getPrivacyDisplayText(privacyType, allowedViewers, excludedViewers),
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Change in settings',
                style: TextStyle(
                  color: theme.textSecondaryColor,
                  fontSize: 11,
                ),
              ),
            ],
          );
        },
        loading: () => Row(
          children: [
            Icon(
              Icons.visibility,
              color: theme.textSecondaryColor,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status visibility',
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: 100,
                    height: 12,
                    child: LinearProgressIndicator(
                      backgroundColor: theme.dividerColor,
                      valueColor: AlwaysStoppedAnimation(theme.primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        error: (error, stack) => Row(
          children: [
            Icon(
              Icons.visibility,
              color: theme.textSecondaryColor,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status visibility',
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'All contacts (default)',
                    style: TextStyle(
                      color: theme.textSecondaryColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Change in settings',
              style: TextStyle(
                color: theme.textSecondaryColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPrivacyDisplayText(StatusPrivacyType privacyType, List<String> allowedViewers, List<String> excludedViewers) {
    switch (privacyType) {
      case StatusPrivacyType.all_contacts:
        return 'All contacts';
      case StatusPrivacyType.except:
        final count = excludedViewers.length;
        if (count == 0) {
          return 'All contacts';
        } else if (count == 1) {
          return '1 contact excluded';
        } else {
          return '$count contacts excluded';
        }
      case StatusPrivacyType.only:
        final count = allowedViewers.length;
        if (count == 0) {
          return 'No one selected';
        } else if (count == 1) {
          return 'Only 1 contact';
        } else {
          return 'Only $count contacts';
        }
    }
  }
}
// ===============================
// Create Status Screen
// WhatsApp-style status creation
// ===============================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/models/status_constants.dart';
import 'package:textgb/features/status/providers/status_providers.dart';
import 'package:textgb/features/status/theme/status_theme.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class CreateStatusScreen extends ConsumerStatefulWidget {
  const CreateStatusScreen({super.key});

  @override
  ConsumerState<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends ConsumerState<CreateStatusScreen> {
  // Creation modes
  CreateMode _mode = CreateMode.select;

  // Text status state
  final TextEditingController _textController = TextEditingController();
  TextStatusBackground _selectedBackground = TextStatusBackground.gradient1;
  int _backgroundIndex = 0;

  // Media status state
  File? _selectedMedia;
  StatusMediaType? _mediaType;
  final TextEditingController _captionController = TextEditingController();

  // Video player state
  VideoPlayerController? _videoPlayerController;
  bool _isVideoPlaying = false;

  // Privacy settings
  StatusVisibility _visibility = StatusVisibility.all;

  // Creation state
  bool _isCreating = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _textController.dispose();
    _captionController.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;

    // Different screens based on mode
    switch (_mode) {
      case CreateMode.select:
        return _buildSelectionScreen(context, modernTheme);
      case CreateMode.text:
        return _buildTextStatusScreen(context, modernTheme);
      case CreateMode.media:
        return _buildMediaPreviewScreen(context, modernTheme);
    }
  }

  // ===============================
  // SELECTION SCREEN (WhatsApp style)
  // ===============================

  Widget _buildSelectionScreen(BuildContext context, dynamic modernTheme) {
    return Scaffold(
      backgroundColor: modernTheme.surfaceColor ?? Colors.white,
      appBar: AppBar(
        title: const Text('Create Status'),
        backgroundColor: modernTheme.surfaceColor ?? Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Instructions
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 64,
                  color: StatusTheme.primaryBlue.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Share your moments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: modernTheme.textColor ?? Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose how you want to create your status',
                  style: TextStyle(
                    fontSize: 14,
                    color: modernTheme.textSecondaryColor ?? Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Options (WhatsApp style)
          Expanded(
            child: Column(
              children: [
                // Text Status
                _buildOptionTile(
                  context,
                  icon: Icons.text_fields_rounded,
                  title: 'Text',
                  subtitle: 'Share text with colorful backgrounds',
                  color: StatusTheme.primaryBlue,
                  onTap: () {
                    setState(() => _mode = CreateMode.text);
                  },
                ),

                const SizedBox(height: 12),

                // Photo Status
                _buildOptionTile(
                  context,
                  icon: Icons.photo_camera,
                  title: 'Photo',
                  subtitle: 'Take a photo or choose from gallery',
                  color: const Color(0xFF10B981),
                  onTap: _showPhotoOptions,
                ),

                const SizedBox(height: 12),

                // Video Status
                _buildOptionTile(
                  context,
                  icon: Icons.videocam,
                  title: 'Video',
                  subtitle: 'Record a video or choose from gallery',
                  color: const Color(0xFFF59E0B),
                  onTap: _showVideoOptions,
                ),
              ],
            ),
          ),

          // Privacy info at bottom
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: StatusTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: StatusTheme.primaryBlue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your status will disappear after 24 hours',
                    style: TextStyle(
                      fontSize: 13,
                      color: modernTheme.textColor ?? Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final modernTheme = context.modernTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: modernTheme.surfaceColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: modernTheme.dividerColor ?? Colors.grey[300]!,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: modernTheme.textColor ?? Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: modernTheme.textSecondaryColor ?? Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: modernTheme.textSecondaryColor ?? Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===============================
  // TEXT STATUS SCREEN (WhatsApp style)
  // ===============================

  Widget _buildTextStatusScreen(BuildContext context, dynamic modernTheme) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          // Cycle through backgrounds on tap (WhatsApp behavior)
          setState(() {
            _backgroundIndex = (_backgroundIndex + 1) % TextStatusBackground.values.length;
            _selectedBackground = TextStatusBackground.values[_backgroundIndex];
          });
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: StatusTheme.getTextBackgroundGradient(
              _selectedBackground.colors,
            ),
          ),
          child: Stack(
            children: [
              // Main text input area
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: TextField(
                    controller: _textController,
                    maxLength: StatusConstants.textStatusMaxLength,
                    maxLines: null,
                    textAlign: TextAlign.center,
                    autofocus: true,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Type a status',
                      hintStyle: TextStyle(
                        color: Colors.white70,
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      counterText: '',
                    ),
                  ),
                ),
              ),

              // Top bar with back and privacy buttons
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        // Back button
                        IconButton(
                          onPressed: () {
                            setState(() => _mode = CreateMode.select);
                          },
                          icon: const Icon(Icons.close, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black26,
                          ),
                        ),
                        const Spacer(),
                        // Privacy button
                        IconButton(
                          onPressed: _showPrivacyOptions,
                          icon: const Icon(Icons.lock_outline, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black26,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom bar with background selector and send button
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Background color selector
                      Container(
                        height: 60,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: TextStatusBackground.values.length,
                          itemBuilder: (context, index) {
                            final bg = TextStatusBackground.values[index];
                            final isSelected = _selectedBackground == bg;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedBackground = bg;
                                  _backgroundIndex = index;
                                });
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  gradient: StatusTheme.getTextBackgroundGradient(bg.colors),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.white : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.white.withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          )
                                        ]
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Send button
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Privacy info
                            Expanded(
                              child: Text(
                                'Visible to ${_visibility.displayName.toLowerCase()}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            // Send button
                            FloatingActionButton(
                              onPressed: _canCreateText ? _handleCreateText : null,
                              backgroundColor: _canCreateText
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.3),
                              elevation: 0,
                              child: _isCreating
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: StatusTheme.primaryBlue,
                                      ),
                                    )
                                  : Icon(
                                      Icons.send,
                                      color: _canCreateText
                                          ? StatusTheme.primaryBlue
                                          : Colors.white,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tap hint in the center (shows briefly)
              if (_textController.text.isEmpty)
                Positioned(
                  bottom: 140,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Tap to change background',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================
  // VIDEO PLAYER MANAGEMENT
  // ===============================

  Future<void> _initializeVideoPlayer() async {
    if (_selectedMedia == null || _mediaType != StatusMediaType.video) return;

    try {
      _videoPlayerController?.dispose();
      _videoPlayerController = VideoPlayerController.file(_selectedMedia!);

      await _videoPlayerController!.initialize();
      _videoPlayerController!.setLooping(true);

      setState(() {});
    } catch (e) {
      _showSnackBar('Failed to initialize video player');
    }
  }

  void _togglePlayPause() {
    if (_videoPlayerController == null) return;

    setState(() {
      if (_isVideoPlaying) {
        _videoPlayerController!.pause();
      } else {
        _videoPlayerController!.play();
      }
      _isVideoPlaying = !_isVideoPlaying;
    });
  }

  // ===============================
  // MEDIA PREVIEW SCREEN
  // ===============================

  Widget _buildMediaPreviewScreen(BuildContext context, dynamic modernTheme) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Media preview
          Center(
            child: _selectedMedia != null
                ? (_mediaType == StatusMediaType.image
                    ? Image.file(_selectedMedia!, fit: BoxFit.contain)
                    : (_videoPlayerController != null &&
                            _videoPlayerController!.value.isInitialized
                        ? GestureDetector(
                            onTap: _togglePlayPause,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                AspectRatio(
                                  aspectRatio:
                                      _videoPlayerController!.value.aspectRatio,
                                  child: VideoPlayer(_videoPlayerController!),
                                ),
                                if (!_isVideoPlaying)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : Container(
                            color: Colors.grey[900],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          )))
                : const SizedBox.shrink(),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _mode = CreateMode.select;
                          _selectedMedia = null;
                          _mediaType = null;
                          _captionController.clear();
                          _videoPlayerController?.dispose();
                          _videoPlayerController = null;
                        });
                      },
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black26,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _showPrivacyOptions,
                      icon: const Icon(Icons.lock_outline, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black26,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom bar with caption and send button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Caption input
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _captionController,
                        style: const TextStyle(color: Colors.white),
                        maxLength: 200,
                        maxLines: 3,
                        minLines: 1,
                        decoration: const InputDecoration(
                          hintText: 'Add a caption...',
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Upload progress or send button
                    if (_isCreating)
                      Column(
                        children: [
                          LinearProgressIndicator(
                            value: _uploadProgress > 0 ? _uploadProgress : null,
                            backgroundColor: Colors.white24,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _uploadProgress > 0
                                ? 'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%'
                                : 'Processing...',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Visible to ${_visibility.displayName.toLowerCase()}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          FloatingActionButton(
                            onPressed: _handleCreateMedia,
                            backgroundColor: StatusTheme.primaryBlue,
                            child: const Icon(Icons.send, color: Colors.white),
                          ),
                        ],
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

  // ===============================
  // MEDIA SELECTION
  // ===============================

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final modernTheme = context.modernTheme;
        return Container(
          color: modernTheme.surfaceColor ?? Colors.white,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showVideoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final modernTheme = context.modernTheme;
        return Container(
          color: modernTheme.surfaceColor ?? Colors.white,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.videocam),
                  title: const Text('Record Video'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickVideoFromCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.video_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickVideoFromGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPrivacyOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final modernTheme = context.modernTheme;
        return Container(
          color: modernTheme.surfaceColor ?? Colors.white,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Status Privacy',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: modernTheme.textColor ?? Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                ...StatusVisibility.values.map((visibility) {
                  return RadioListTile<StatusVisibility>(
                    title: Text(visibility.displayName),
                    subtitle: Text(
                      visibility.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: modernTheme.textSecondaryColor ?? Colors.grey[600],
                      ),
                    ),
                    value: visibility,
                    groupValue: _visibility,
                    activeColor: StatusTheme.primaryBlue,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _visibility = value);
                        Navigator.pop(context);
                      }
                    },
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===============================
  // MEDIA PICKING
  // ===============================

  Future<void> _pickImageFromCamera() async {
    final uploadService = ref.read(statusUploadServiceProvider);
    final file = await uploadService.pickImageFromCamera();
    if (file != null && mounted) {
      setState(() {
        _selectedMedia = file;
        _mediaType = StatusMediaType.image;
        _mode = CreateMode.media;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final uploadService = ref.read(statusUploadServiceProvider);
    final file = await uploadService.pickImageFromGallery();
    if (file != null && mounted) {
      setState(() {
        _selectedMedia = file;
        _mediaType = StatusMediaType.image;
        _mode = CreateMode.media;
      });
    }
  }

  Future<void> _pickVideoFromCamera() async {
    final uploadService = ref.read(statusUploadServiceProvider);
    final file = await uploadService.pickVideoFromCamera();
    if (file != null && mounted) {
      setState(() {
        _selectedMedia = file;
        _mediaType = StatusMediaType.video;
        _mode = CreateMode.media;
      });
      await _initializeVideoPlayer();
    }
  }

  Future<void> _pickVideoFromGallery() async {
    final uploadService = ref.read(statusUploadServiceProvider);
    final file = await uploadService.pickVideoFromGallery();
    if (file != null && mounted) {
      setState(() {
        _selectedMedia = file;
        _mediaType = StatusMediaType.video;
        _mode = CreateMode.media;
      });
      await _initializeVideoPlayer();
    }
  }

  // ===============================
  // CREATE STATUS
  // ===============================

  bool get _canCreateText => _textController.text.trim().isNotEmpty;

  Future<void> _handleCreateText() async {
    if (!_canCreateText || _isCreating) return;

    setState(() => _isCreating = true);

    try {
      final creationProvider = ref.read(statusCreationProvider.notifier);
      await creationProvider.createStatus(
        CreateStatusRequest(
          content: _textController.text.trim(),
          mediaType: StatusMediaType.text,
          textBackground: _selectedBackground,
          visibility: _visibility,
        ),
      );

      if (mounted) {
        _showSnackBar(StatusConstants.successUploaded);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to create status: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _handleCreateMedia() async {
    if (_selectedMedia == null || _isCreating) return;

    setState(() {
      _isCreating = true;
      _uploadProgress = 0.0;
    });

    try {
      final creationProvider = ref.read(statusCreationProvider.notifier);
      final caption = _captionController.text.trim();

      if (_mediaType == StatusMediaType.image) {
        // Simulate progress for image upload
        setState(() => _uploadProgress = 0.5);

        await creationProvider.createImageStatus(
          imagePath: _selectedMedia!.path,
          request: CreateStatusRequest(
            content: caption.isNotEmpty ? caption : null,
            mediaType: StatusMediaType.image,
            visibility: _visibility,
          ),
        );
      } else if (_mediaType == StatusMediaType.video) {
        // Simulate progress for video upload
        setState(() => _uploadProgress = 0.3);

        await creationProvider.createVideoStatus(
          videoPath: _selectedMedia!.path,
          request: CreateStatusRequest(
            content: caption.isNotEmpty ? caption : null,
            mediaType: StatusMediaType.video,
            visibility: _visibility,
          ),
        );
      }

      setState(() => _uploadProgress = 1.0);

      if (mounted) {
        _showSnackBar(StatusConstants.successUploaded);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        _showSnackBar('Failed to create status: $errorMessage');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

// ===============================
// ENUMS
// ===============================

enum CreateMode {
  select,
  text,
  media,
}

// lib/features/moments/screens/create_moment_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/providers/moments_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class CreateMomentScreen extends ConsumerStatefulWidget {
  const CreateMomentScreen({super.key});

  @override
  ConsumerState<CreateMomentScreen> createState() => _CreateMomentScreenState();
}

class _CreateMomentScreenState extends ConsumerState<CreateMomentScreen> 
    with SingleTickerProviderStateMixin {
  final TextEditingController _contentController = TextEditingController();
  final List<File> _selectedFiles = [];
  MessageEnum _mediaType = MessageEnum.text;
  MomentPrivacy _selectedPrivacy = MomentPrivacy.allContacts;
  bool _isPosting = false;
  int _selectedBackgroundIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Beautiful color palette
  static const Color appleBlue = Color(0xFF007AFF);
  static const Color appleBlueLight = Color(0xFF5AC8FA);
  static const Color wechatGreen = Color(0xFF25D366);
  static const Color whatsappTeal = Color(0xFF128C7E);
  static const Color backgroundWhite = Color(0xFFFAFAFA);
  static const Color cardWhite = Colors.white;
  static const Color textPrimary = Color(0xFF1D1D1D);
  static const Color textSecondary = Color(0xFF8E8E93);

  // WhatsApp-style text backgrounds with more variety
  final List<Map<String, dynamic>> _textBackgrounds = [
    {
      'gradient': [Color(0xFF25D366), Color(0xFF128C7E)],
      'name': 'WhatsApp Green'
    },
    {
      'gradient': [Color(0xFF007AFF), Color(0xFF5AC8FA)],
      'name': 'Ocean Blue'
    },
    {
      'gradient': [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
      'name': 'Sunset Orange'
    },
    {
      'gradient': [Color(0xFF6C5CE7), Color(0xFDA085F)],
      'name': 'Purple Dream'
    },
    {
      'gradient': [Color(0xFFFF7675), Color(0xFFE84393)],
      'name': 'Pink Rose'
    },
    {
      'gradient': [Color(0xFF00B894), Color(0xFF00CEC9)],
      'name': 'Mint Fresh'
    },
    {
      'gradient': [Color(0xFFE17055), Color(0xFFFDCB6E)],
      'name': 'Warm Sunset'
    },
    {
      'gradient': [Color(0xFF2D3436), Color(0xFF636E72)],
      'name': 'Dark Storm'
    },
    {
      'gradient': [Color(0xFFFF9A9E), Color(0xFFFECACA)],
      'name': 'Soft Pink'
    },
    {
      'gradient': [Color(0xFFA8EDEA), Color(0xFFFED6E3)],
      'name': 'Cotton Candy'
    },
    {
      'gradient': [Color(0xFFFA709A), Color(0xFFFEE140)],
      'name': 'Vibrant Sunrise'
    },
    {
      'gradient': [Color(0xFF667EEA), Color(0xFF764BA2)],
      'name': 'Royal Purple'
    },
    {
      'gradient': [Color(0xFFF093FB), Color(0xFFF5576C)],
      'name': 'Magenta Burst'
    },
    {
      'gradient': [Color(0xFF4FACFE), Color(0xFF00F2FE)],
      'name': 'Sky Blue'
    },
    {
      'gradient': [Color(0xFF43E97B), Color(0xFF38F9D7)],
      'name': 'Green Paradise'
    },
    {
      'gradient': [Color(0xFFFA8BFF), Color(0xFF2BD2FF), Color(0xFF2BFF88)],
      'name': 'Rainbow Glow'
    },
    {
      'gradient': [Color(0xFFFF512F), Color(0xFFDD2476)],
      'name': 'Fire Red'
    },
    {
      'gradient': [Color(0xFF11998E), Color(0xFF38EF7D)],
      'name': 'Emerald Ocean'
    },
    {
      'gradient': [Color(0xFF654EA3), Color(0xFFEAAFC8)],
      'name': 'Lavender Dreams'
    },
    {
      'gradient': [Color(0xFFFFE000), Color(0xFF799F0C)],
      'name': 'Golden Green'
    },
    {
      'gradient': [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
      'name': 'Deep Purple'
    },
    {
      'gradient': [Color(0xFFFF6A00), Color(0xFFEE0979)],
      'name': 'Electric Orange'
    },
    {
      'gradient': [Color(0xFF00C9FF), Color(0xFF92FE9D)],
      'name': 'Cool Mint'
    },
    {
      'gradient': [Color(0xFFFC466B), Color(0xFF3F5EFB)],
      'name': 'Neon Nights'
    },
    {
      'gradient': [Color(0xFF3F2B96), Color(0xFFA8C0FF)],
      'name': 'Midnight Blue'
    },
    {
      'gradient': [Color(0xFF1A2980), Color(0xFF26D0CE)],
      'name': 'Dark Teal'
    },
    {
      'gradient': [Color(0xFFFF8008), Color(0xFFFFC837)],
      'name': 'Sunny Day'
    },
    {
      'gradient': [Color(0xFF40E0D0), Color(0xFFFF8C00), Color(0xFFFF0080)],
      'name': 'Tropical Sunset'
    },
    {
      'gradient': [Color(0xFF834D9B), Color(0xFFD04ED6)],
      'name': 'Purple Haze'
    },
    {
      'gradient': [Color(0xFF000428), Color(0xFF004E92)],
      'name': 'Deep Ocean'
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'SF Pro Display',
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: _buildContent(),
                ),
                _buildBottomActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Create Moment',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.4,
              ),
            ),
          ),
          if (_canPost())
            GestureDetector(
              onTap: _isPosting ? null : _postMoment,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: wechatGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _isPosting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Share',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            )
          else
            const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedFiles.isNotEmpty) {
      return _buildMediaContent();
    }
    return _buildTextContent();
  }

  Widget _buildTextContent() {
    final selectedBg = _textBackgrounds[_selectedBackgroundIndex];
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: selectedBg['gradient'],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Background pattern
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Background selector
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _textBackgrounds.length,
                    itemBuilder: (context, index) {
                      final bg = _textBackgrounds[index];
                      final isSelected = index == _selectedBackgroundIndex;
                      
                      return GestureDetector(
                        onTap: () => setState(() => _selectedBackgroundIndex = index),
                        child: Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: bg['gradient'],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(25),
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Text input
                Expanded(
                  child: Center(
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                ),
                
                // Text formatting options
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTextFormatButton(Icons.format_bold, 'Bold'),
                    const SizedBox(width: 16),
                    _buildTextFormatButton(Icons.format_italic, 'Italic'),
                    const SizedBox(width: 16),
                    _buildTextFormatButton(Icons.text_fields, 'Size'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormatButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildMediaContent() {
    if (_mediaType == MessageEnum.image) {
      return _buildImageContent();
    } else if (_mediaType == MessageEnum.video) {
      return _buildVideoContent();
    }
    return const SizedBox.shrink();
  }

  Widget _buildImageContent() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _selectedFiles.length == 1 ? 1 : 2,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: _selectedFiles.length,
              itemBuilder: (context, index) {
                final file = _selectedFiles[index];
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(file),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _removeFile(index),
                        child: Container(
                          padding: const EdgeInsets.all(6),
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
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Caption overlay
          if (_contentController.text.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text(
                  _contentController.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoContent() {
    final videoFile = _selectedFiles.first;
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 400,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade800,
                  Colors.grey.shade900,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.play_circle_fill,
                size: 80,
                color: Colors.white,
              ),
            ),
          ),
          
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => _removeFile(0),
              child: Container(
                padding: const EdgeInsets.all(6),
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
            ),
          ),
          
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getVideoFileName(videoFile),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Caption input for media
          if (_selectedFiles.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              child: TextField(
                controller: _contentController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                decoration: const InputDecoration(
                  hintText: 'Add a caption...',
                  hintStyle: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          
          // Media selection buttons
          Row(
            children: [
              _buildMediaActionButton(
                icon: Icons.text_fields,
                label: 'Text',
                color: wechatGreen,
                isSelected: _selectedFiles.isEmpty,
                onTap: () => _selectTextMode(),
              ),
              const SizedBox(width: 12),
              _buildMediaActionButton(
                icon: Icons.photo_library,
                label: 'Photos',
                color: appleBlue,
                isSelected: _mediaType == MessageEnum.image,
                onTap: _pickImages,
              ),
              const SizedBox(width: 12),
              _buildMediaActionButton(
                icon: Icons.videocam,
                label: 'Video',
                color: Colors.purple,
                isSelected: _mediaType == MessageEnum.video,
                onTap: _pickVideo,
              ),
              const SizedBox(width: 12),
              _buildMediaActionButton(
                icon: Icons.camera_alt,
                label: 'Camera',
                color: Colors.orange,
                isSelected: false,
                onTap: _pickFromCamera,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected 
                ? color.withOpacity(0.8)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: Colors.white, width: 2)
                : Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectTextMode() {
    setState(() {
      _selectedFiles.clear();
      _mediaType = MessageEnum.text;
    });
  }

  void _pickImages() async {
    final images = await _pickMultipleImages();
    if (images.isNotEmpty) {
      setState(() {
        _selectedFiles.clear();
        _selectedFiles.addAll(images);
        _mediaType = MessageEnum.image;
      });
    }
  }

  void _pickVideo() async {
    final video = await pickVideo(
      onFail: (error) => showSnackBar(context, error),
      maxDuration: const Duration(minutes: 1),
    );

    if (video != null) {
      setState(() {
        _selectedFiles.clear();
        _selectedFiles.add(video);
        _mediaType = MessageEnum.video;
      });
    }
  }

  void _pickFromCamera() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _buildCameraOption(
              icon: Icons.photo_camera,
              title: 'Take Photo',
              color: appleBlue,
              onTap: () async {
                Navigator.pop(context);
                await _takePhoto();
              },
            ),
            const SizedBox(height: 12),
            _buildCameraOption(
              icon: Icons.videocam,
              title: 'Record Video',
              color: Colors.purple,
              onTap: () async {
                Navigator.pop(context);
                await _recordVideo();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    final image = await pickImage(
      fromCamera: true,
      onFail: (error) => showSnackBar(context, error),
    );

    if (image != null) {
      setState(() {
        _selectedFiles.clear();
        _selectedFiles.add(image);
        _mediaType = MessageEnum.image;
      });
    }
  }

  Future<void> _recordVideo() async {
    final video = await pickVideoFromCamera(
      onFail: (error) => showSnackBar(context, error),
      maxDuration: const Duration(minutes: 1),
    );

    if (video != null) {
      setState(() {
        _selectedFiles.clear();
        _selectedFiles.add(video);
        _mediaType = MessageEnum.video;
      });
    }
  }

  Future<List<File>> _pickMultipleImages() async {
    if (_selectedFiles.length >= 9) {
      showSnackBar(context, 'Maximum 9 images allowed');
      return [];
    }

    final image = await pickImage(
      fromCamera: false,
      onFail: (error) => showSnackBar(context, error),
    );

    return image != null ? [image] : [];
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
      if (_selectedFiles.isEmpty) {
        _mediaType = MessageEnum.text;
      }
    });
  }

  String _getVideoFileName(File videoFile) {
    return videoFile.path.split('/').last;
  }

  bool _canPost() {
    return _contentController.text.trim().isNotEmpty || _selectedFiles.isNotEmpty;
  }

  Future<void> _postMoment() async {
    if (_isPosting || !_canPost()) return;

    setState(() => _isPosting = true);

    try {
      await ref.read(momentsNotifierProvider.notifier).createMoment(
        content: _contentController.text.trim(),
        mediaFiles: _selectedFiles,
        mediaType: _selectedFiles.isEmpty ? MessageEnum.text : _mediaType,
        privacy: _selectedPrivacy,
      );

      if (mounted) {
        Navigator.pop(context);
        showSnackBar(context, 'Moment shared successfully!');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to share moment: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }
}
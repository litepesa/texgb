import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class MediaSelectorWidget extends StatefulWidget {
  final Function(File file, bool isVideo) onMediaSelected;

  const MediaSelectorWidget({
    Key? key,
    required this.onMediaSelected,
  }) : super(key: key);

  @override
  State<MediaSelectorWidget> createState() => _MediaSelectorWidgetState();
}

class _MediaSelectorWidgetState extends State<MediaSelectorWidget> {
  bool _isVideoMode = true;
  final ImagePicker _picker = ImagePicker();

  Future<void> _selectVideo() async {
    final video = await pickVideo(
      onFail: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
      maxDuration: const Duration(minutes: 1),
    );
    
    if (video != null) {
      widget.onMediaSelected(video, true);
    }
  }

  Future<void> _selectImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    
    if (image != null) {
      widget.onMediaSelected(File(image.path), false);
    }
  }

  Future<void> _captureVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 1),
    );
    
    if (video != null) {
      widget.onMediaSelected(File(video.path), true);
    }
  }

  Future<void> _captureImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );
    
    if (image != null) {
      widget.onMediaSelected(File(image.path), false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            modernTheme.primaryColor!.withOpacity(0.1),
            modernTheme.primaryColor!.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: modernTheme.primaryColor!.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Media type selector
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor ?? modernTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isVideoMode = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isVideoMode 
                            ? modernTheme.primaryColor 
                            : Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.videocam,
                            color: _isVideoMode 
                                ? Colors.white 
                                : modernTheme.textSecondaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Video',
                            style: TextStyle(
                              color: _isVideoMode 
                                  ? Colors.white 
                                  : modernTheme.textSecondaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isVideoMode = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isVideoMode 
                            ? modernTheme.primaryColor 
                            : Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo,
                            color: !_isVideoMode 
                                ? Colors.white 
                                : modernTheme.textSecondaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Photo',
                            style: TextStyle(
                              color: !_isVideoMode 
                                  ? Colors.white 
                                  : modernTheme.textSecondaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Media selection options
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: modernTheme.primaryColor!.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isVideoMode ? Icons.video_library : Icons.photo_library,
                    color: modernTheme.primaryColor,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  _isVideoMode ? 'Create a Video' : 'Share a Photo',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  _isVideoMode 
                      ? 'Record or upload a video up to 60 seconds'
                      : 'Capture or select a photo to share',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Action buttons
                Row(
                  children: [
                    // Gallery button
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.photo_library_outlined,
                        label: 'Gallery',
                        onTap: _isVideoMode ? _selectVideo : _selectImage,
                        isPrimary: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Camera button
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.camera_alt_outlined,
                        label: 'Camera',
                        onTap: _isVideoMode ? _captureVideo : _captureImage,
                        isPrimary: false,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Features list
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: modernTheme.primaryColor!.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Editing Features:',
                        style: TextStyle(
                          color: modernTheme.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureRow(Icons.text_fields, 'Add animated text & captions'),
                      _buildFeatureRow(Icons.music_note, 'Add background music'),
                      _buildFeatureRow(Icons.face_retouching_natural, 'Beauty filters & effects'),
                      _buildFeatureRow(Icons.emoji_emotions, 'Stickers & animations'),
                      _buildFeatureRow(Icons.filter, 'Professional filters'),
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    final modernTheme = context.modernTheme;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isPrimary 
                ? modernTheme.primaryColor 
                : modernTheme.primaryColor!.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary 
                  ? modernTheme.primaryColor! 
                  : modernTheme.primaryColor!.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : modernTheme.primaryColor,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : modernTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    final modernTheme = context.modernTheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            color: modernTheme.primaryColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
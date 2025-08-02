// lib/features/status/screens/create_status_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
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

class _CreateStatusScreenState extends ConsumerState<CreateStatusScreen> {
  StatusType _selectedType = StatusType.text;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  
  File? _selectedFile;
  String _backgroundColor = '#000000';
  String _fontColor = '#FFFFFF';
  String _fontFamily = 'default';
  StatusPrivacyType _privacyType = StatusPrivacyType.all_contacts;
  
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
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _captionController.dispose();
    super.dispose();
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
              data: (state) => state.isCreating ? null : _createStatus,
              loading: () => null,
              error: (_, __) => _createStatus,
            ),
            child: statusNotifier.when(
              data: (state) => state.isCreating
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
          
          // Options panel
          _buildOptionsPanel(theme),
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
        onTap: () => setState(() => _selectedType = type),
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
      case StatusType.video:
        return _buildMediaStatus(theme);
      default:
        return _buildTextStatus(theme);
    }
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
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Type your status...',
                  hintStyle: TextStyle(
                    color: Colors.white54,
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

  Widget _buildMediaStatus(ModernThemeExtension theme) {
    return Column(
      children: [
        // Media preview
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surfaceVariantColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _selectedFile != null
                ? _buildFilePreview(theme)
                : _buildMediaPicker(theme),
          ),
        ),
        
        // Caption input
        if (_selectedFile != null)
          Container(
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
          ),
      ],
    );
  }

  Widget _buildFilePreview(ModernThemeExtension theme) {
    return Stack(
      children: [
        // File preview
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _selectedType == StatusType.image
                ? Image.file(_selectedFile!, fit: BoxFit.cover)
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  ),
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

  Widget _buildOptionsPanel(ModernThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Privacy settings
          Row(
            children: [
              Icon(Icons.visibility, color: theme.textSecondaryColor, size: 20),
              const SizedBox(width: 12),
              Text(
                'Status privacy',
                style: TextStyle(color: theme.textColor, fontSize: 16),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showPrivacySettings,
                child: Row(
                  children: [
                    Text(
                      _privacyType.displayName,
                      style: TextStyle(color: theme.primaryColor),
                    ),
                    Icon(Icons.chevron_right, color: theme.primaryColor),
                  ],
                ),
              ),
            ],
          ),
        ],
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

  void _showPrivacySettings() {
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
                'Status Privacy',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...StatusPrivacyType.values.map((type) {
                return ListTile(
                  leading: Radio<StatusPrivacyType>(
                    value: type,
                    groupValue: _privacyType,
                    activeColor: theme.primaryColor,
                    onChanged: (value) {
                      setState(() => _privacyType = value!);
                      Navigator.pop(context);
                    },
                  ),
                  title: Text(
                    type.displayName,
                    style: TextStyle(color: theme.textColor),
                  ),
                  onTap: () {
                    setState(() => _privacyType = type);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
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
          maxDuration: const Duration(minutes: 1),
        );
        if (file != null) {
          setState(() => _selectedFile = file);
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
          maxDuration: const Duration(minutes: 1),
        );
        if (file != null) {
          setState(() => _selectedFile = file);
        }
      }
    } catch (e) {
      showSnackBar(context, 'Error using camera: $e');
    }
  }

  void _createStatus() async {
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
      if (_selectedFile == null) {
        showSnackBar(context, 'Please select a file');
        return;
      }
      content = ''; // Will be filled by repository with uploaded URL
      caption = _captionController.text.trim();
      if (caption.isEmpty) caption = null;
    }

    try {
      final statusId = await ref.read(statusNotifierProvider.notifier).createStatus(
        type: _selectedType,
        content: content,
        caption: caption,
        backgroundColor: _selectedType == StatusType.text ? _backgroundColor : null,
        fontColor: _selectedType == StatusType.text ? _fontColor : null,
        fontFamily: _selectedType == StatusType.text ? _fontFamily : null,
        privacyType: _privacyType,
        mediaFile: _selectedFile,
      );

      if (statusId != null) {
        if (mounted) {
          Navigator.pop(context);
          showSnackBar(context, 'Status shared successfully!');
        }
      } else {
        showSnackBar(context, 'Failed to share status');
      }
    } catch (e) {
      showSnackBar(context, 'Error sharing status: $e');
    }
  }
}
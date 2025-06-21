// lib/features/moments/screens/create_moment_screen.dart
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/providers/moments_provider.dart';
import 'package:textgb/features/moments/widgets/privacy_selector.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class CreateMomentScreen extends ConsumerStatefulWidget {
  const CreateMomentScreen({super.key});

  @override
  ConsumerState<CreateMomentScreen> createState() => _CreateMomentScreenState();
}

class _CreateMomentScreenState extends ConsumerState<CreateMomentScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  
  List<File> _selectedMedia = [];
  MomentPrivacy _selectedPrivacy = MomentPrivacy.allContacts;
  List<String> _visibleTo = [];
  List<String> _hiddenFrom = [];
  bool _showLocationField = false;

  @override
  void dispose() {
    _contentController.dispose();
    _locationController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final momentsState = ref.watch(momentsNotifierProvider);
    final isPosting = momentsState.value?.isPosting ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context, isPosting),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content input
                  _buildContentInput(),
                  
                  const SizedBox(height: 16),
                  
                  // Media preview
                  if (_selectedMedia.isNotEmpty) ...[
                    _buildMediaPreview(),
                    const SizedBox(height: 16),
                  ],
                  
                  // Location input
                  if (_showLocationField) ...[
                    _buildLocationInput(),
                    const SizedBox(height: 16),
                  ],
                  
                  // Privacy selector
                  _buildPrivacySection(),
                ],
              ),
            ),
          ),
          
          // Bottom toolbar
          _buildBottomToolbar(context),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isPosting) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      leading: TextButton(
        onPressed: isPosting ? null : () => Navigator.pop(context),
        child: const Text(
          'Cancel',
          style: TextStyle(
            color: Color(0xFF007AFF),
            fontSize: 16,
          ),
        ),
      ),
      title: const Text(
        'New Moment',
        style: TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        TextButton(
          onPressed: isPosting ? null : _canPost() ? _postMoment : null,
          child: isPosting
              ? const CupertinoActivityIndicator()
              : Text(
                  'Post',
                  style: TextStyle(
                    color: _canPost() ? const Color(0xFF007AFF) : const Color(0xFF8E8E93),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildContentInput() {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      child: TextField(
        controller: _contentController,
        focusNode: _contentFocusNode,
        maxLines: null,
        maxLength: 1000,
        style: const TextStyle(
          fontSize: 18,
          color: Color(0xFF1A1A1A),
          height: 1.4,
        ),
        decoration: const InputDecoration(
          hintText: 'What\'s on your mind?',
          hintStyle: TextStyle(
            fontSize: 18,
            color: Color(0xFF8E8E93),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          counterStyle: TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 12,
          ),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Container(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedMedia.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final file = _selectedMedia[index];
          return Stack(
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFF2F2F7),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    file,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _removeMedia(index),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.xmark,
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
    );
  }

  Widget _buildLocationInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.location,
            color: Color(0xFF007AFF),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _locationController,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1A1A1A),
              ),
              decoration: const InputDecoration(
                hintText: 'Add location',
                hintStyle: TextStyle(
                  color: Color(0xFF8E8E93),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _showLocationField = false;
              _locationController.clear();
            }),
            child: const Icon(
              CupertinoIcons.xmark_circle_fill,
              color: Color(0xFF8E8E93),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Who can see this?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        PrivacySelector(
          selectedPrivacy: _selectedPrivacy,
          visibleTo: _visibleTo,
          hiddenFrom: _hiddenFrom,
          onPrivacyChanged: (privacy, visibleTo, hiddenFrom) {
            setState(() {
              _selectedPrivacy = privacy;
              _visibleTo = visibleTo;
              _hiddenFrom = hiddenFrom;
            });
          },
        ),
      ],
    );
  }

  Widget _buildBottomToolbar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Simple photo/video button
          _buildToolbarButton(
            icon: CupertinoIcons.photo_on_rectangle,
            label: 'Add Photo/Video',
            color: const Color(0xFF007AFF),
            onTap: _selectMedia,
          ),
          const SizedBox(width: 16),
          _buildToolbarButton(
            icon: CupertinoIcons.location,
            label: 'Location',
            color: _showLocationField ? const Color(0xFF007AFF) : const Color(0xFF8E8E93),
            onTap: () => setState(() {
              _showLocationField = !_showLocationField;
              if (_showLocationField) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  // Auto-focus location field if needed
                });
              }
            }),
          ),
          const Spacer(),
          Text(
            '${_contentController.text.length}/1000',
            style: TextStyle(
              fontSize: 12,
              color: _contentController.text.length > 900 
                  ? const Color(0xFFFF3B30) 
                  : const Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canPost() {
    return _contentController.text.trim().isNotEmpty || _selectedMedia.isNotEmpty;
  }

  void _selectMedia() async {
    try {
      // Show simple gallery picker for images and videos
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('Add Media'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(context);
                final file = await pickImage(
                  fromCamera: false,
                  onFail: (error) => showSnackBar(context, error),
                );
                if (file != null) {
                  setState(() {
                    _selectedMedia.add(file);
                  });
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.photo, color: Color(0xFF007AFF)),
                  SizedBox(width: 8),
                  Text('Choose Photo'),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(context);
                final file = await pickVideo(
                  onFail: (error) => showSnackBar(context, error),
                  maxDuration: const Duration(minutes: 5),
                );
                if (file != null) {
                  setState(() {
                    _selectedMedia.add(file);
                  });
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.videocam, color: Color(0xFF007AFF)),
                  SizedBox(width: 8),
                  Text('Choose Video'),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
      );
    } catch (e) {
      showSnackBar(context, 'Error selecting media: $e');
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
    });
  }

  void _postMoment() async {
    if (!_canPost()) return;

    try {
      await ref.read(momentsNotifierProvider.notifier).postMoment(
        content: _contentController.text.trim(),
        mediaFiles: _selectedMedia,
        privacy: _selectedPrivacy,
        visibleTo: _visibleTo,
        hiddenFrom: _hiddenFrom,
        location: _locationController.text.trim().isEmpty 
            ? null 
            : _locationController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        showSnackBar(context, 'Moment posted successfully!');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to post moment: $e');
      }
    }
  }
}
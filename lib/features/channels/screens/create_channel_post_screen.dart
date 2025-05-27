// lib/features/channels/screens/create_channel_post_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/widgets/video_trimmer_widget.dart';
import 'package:textgb/features/channels/widgets/media_gallery_selector.dart';
import 'package:textgb/features/channels/widgets/camera_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:camera/camera.dart';

class CreateChannelPostScreen extends ConsumerStatefulWidget {
  const CreateChannelPostScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateChannelPostScreen> createState() => _CreateChannelPostScreenState();
}

class _CreateChannelPostScreenState extends ConsumerState<CreateChannelPostScreen> 
    with TickerProviderStateMixin {
  
  // Controllers
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Media selection state
  List<File> _selectedImages = [];
  File? _selectedVideo;
  VideoPlayerController? _videoController;
  bool _isVideoMode = true;
  
  // Video trimming state
  Duration _videoDuration = Duration.zero;
  Duration _startTime = Duration.zero;
  Duration _endTime = Duration.zero;
  
  // UI state
  bool _isProcessing = false;
  bool _isLoading = false;
  String _processingMessage = '';
  
  // Camera state
  bool _useTimer = false;
  int _timerDuration = 3;
  bool _showGrid = false;
  bool _flashOn = false;
  
  // Cache manager
  final DefaultCacheManager _cacheManager = DefaultCacheManager();
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkPermissions();
  }
  
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }
  
  Future<void> _checkPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.photos,
    ].request();
    
    if (statuses.values.any((status) => !status.isGranted)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please grant all permissions to use this feature'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: openAppSettings,
            ),
          ),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _captionController.dispose();
    _tagsController.dispose();
    _animationController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  modernTheme.primaryColor!.withOpacity(0.05),
                  modernTheme.backgroundColor,
                  modernTheme.primaryColor!.withOpacity(0.03),
                ],
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Custom app bar
                  _buildAppBar(modernTheme),
                  
                  // Content area
                  Expanded(
                    child: _selectedImages.isEmpty && _selectedVideo == null
                        ? _buildMediaSelector(modernTheme, screenSize)
                        : _buildMediaPreview(modernTheme, screenSize),
                  ),
                ],
              ),
            ),
          ),
          
          // Processing overlay
          if (_isProcessing)
            _buildProcessingOverlay(modernTheme),
        ],
      ),
    );
  }

  Widget _buildAppBar(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: modernTheme.backgroundColor.withOpacity(0.95),
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
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: modernTheme.textColor),
          ),
          
          // Title
          Expanded(
            child: Text(
              'Create Post',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Next/Post button
          if (_selectedImages.isNotEmpty || _selectedVideo != null)
            TextButton(
              onPressed: _isProcessing ? null : _handleNext,
              child: Text(
                'Next',
                style: TextStyle(
                  color: modernTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMediaSelector(ModernThemeExtension modernTheme, Size screenSize) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Media type toggle
            _buildMediaTypeToggle(modernTheme),
            
            const SizedBox(height: 32),
            
            // Main action buttons
            _buildMainActions(modernTheme),
            
            const SizedBox(height: 24),
            
            // Camera settings (if applicable)
            if (_isVideoMode)
              _buildCameraSettings(modernTheme),
            
            const SizedBox(height: 32),
            
            // Recent media preview
            _buildRecentMedia(modernTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaTypeToggle(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor ?? modernTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: modernTheme.primaryColor!.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              'Video',
              Icons.videocam_rounded,
              _isVideoMode,
              () => setState(() => _isVideoMode = true),
              modernTheme,
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              'Photos',
              Icons.photo_library_rounded,
              !_isVideoMode,
              () => setState(() => _isVideoMode = false),
              modernTheme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
    ModernThemeExtension modernTheme,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? modernTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : modernTheme.textSecondaryColor,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : modernTheme.textSecondaryColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActions(ModernThemeExtension modernTheme) {
    return Row(
      children: [
        // Gallery button
        Expanded(
          child: _buildActionCard(
            icon: Icons.photo_library_outlined,
            title: 'Gallery',
            subtitle: _isVideoMode ? 'Up to 5 minutes' : 'Up to 10 photos',
            onTap: _selectFromGallery,
            modernTheme: modernTheme,
            isPrimary: true,
          ),
        ),
        const SizedBox(width: 16),
        // Camera button
        Expanded(
          child: _buildActionCard(
            icon: Icons.camera_alt_outlined,
            title: 'Camera',
            subtitle: _isVideoMode ? 'Record video' : 'Take photo',
            onTap: _openCamera,
            modernTheme: modernTheme,
            isPrimary: false,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ModernThemeExtension modernTheme,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
                  colors: [
                    modernTheme.primaryColor!,
                    modernTheme.primaryColor!.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isPrimary ? null : modernTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: isPrimary
              ? null
              : Border.all(
                  color: modernTheme.borderColor ?? modernTheme.primaryColor!.withOpacity(0.2),
                ),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? modernTheme.primaryColor!.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isPrimary
                    ? Colors.white.withOpacity(0.2)
                    : modernTheme.primaryColor!.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isPrimary ? Colors.white : modernTheme.primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isPrimary ? Colors.white : modernTheme.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isPrimary
                    ? Colors.white.withOpacity(0.9)
                    : modernTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraSettings(ModernThemeExtension modernTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Camera Settings',
          style: TextStyle(
            color: modernTheme.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildSettingChip(
              icon: Icons.timer,
              label: 'Timer: ${_useTimer ? "${_timerDuration}s" : "Off"}',
              isActive: _useTimer,
              onTap: _toggleTimer,
              modernTheme: modernTheme,
            ),
            _buildSettingChip(
              icon: Icons.grid_on,
              label: 'Grid',
              isActive: _showGrid,
              onTap: () => setState(() => _showGrid = !_showGrid),
              modernTheme: modernTheme,
            ),
            _buildSettingChip(
              icon: Icons.flash_on,
              label: 'Flash',
              isActive: _flashOn,
              onTap: () => setState(() => _flashOn = !_flashOn),
              modernTheme: modernTheme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required ModernThemeExtension modernTheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? modernTheme.primaryColor!.withOpacity(0.1)
              : modernTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? modernTheme.primaryColor!
                : modernTheme.borderColor ?? Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? modernTheme.primaryColor : modernTheme.textSecondaryColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? modernTheme.primaryColor : modernTheme.textSecondaryColor,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMedia(ModernThemeExtension modernTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Media',
              style: TextStyle(
                color: modernTheme.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            TextButton(
              onPressed: _selectFromGallery,
              child: Text(
                'See all',
                style: TextStyle(
                  color: modernTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: FutureBuilder<List<AssetEntity>>(
            future: _loadRecentMedia(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              
              final assets = snapshot.data!;
              if (assets.isEmpty) {
                return Center(
                  child: Text(
                    'No recent media',
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                    ),
                  ),
                );
              }
              
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: assets.length,
                itemBuilder: (context, index) {
                  return _buildRecentMediaItem(assets[index], modernTheme);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentMediaItem(AssetEntity asset, ModernThemeExtension modernTheme) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
      builder: (context, snapshot) {
        Widget content;
        if (snapshot.hasData && snapshot.data != null) {
          content = Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
          );
        } else {
          content = Container(
            color: modernTheme.surfaceColor,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        return GestureDetector(
          onTap: () => _handleAssetSelection(asset),
          child: Container(
            width: 100,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              overflow: 'hidden',
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                content,
                if (asset.type == AssetType.video)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatDuration(asset.duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMediaPreview(ModernThemeExtension modernTheme, Size screenSize) {
    return Column(
      children: [
        // Preview area
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _selectedVideo != null
                  ? _buildVideoPreview()
                  : _buildImageCarouselPreview(),
            ),
          ),
        ),
        
        // Details input
        _buildDetailsInput(modernTheme),
      ],
    );
  }

  Widget _buildVideoPreview() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
        ),
        
        // Play/pause overlay
        Center(
          child: GestureDetector(
            onTap: _toggleVideoPlayback,
            child: AnimatedOpacity(
              opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
        ),
        
        // Video controls and trimmer button
        if (_videoDuration > const Duration(minutes: 5))
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Video exceeds 5 minutes. Trim required.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showVideoTrimmer,
                      icon: const Icon(Icons.content_cut),
                      label: const Text('Trim Video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showVideoTrimmer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VideoTrimmerWidget(
        videoFile: _selectedVideo!,
        videoDuration: _videoDuration,
        onTrimComplete: (start, end) {
          setState(() {
            _startTime = start;
            _endTime = end;
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Video will be trimmed to ${_formatDuration(end - start)}',
              ),
            ),
          );
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildImageCarouselPreview() {
    if (_selectedImages.isEmpty) {
      return const Center(
        child: Text(
          'No images selected',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    
    return PageView.builder(
      itemCount: _selectedImages.length,
      itemBuilder: (context, index) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              _selectedImages[index],
              fit: BoxFit.contain,
            ),
            
            // Remove button
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
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
            
            // Page indicator
            if (_selectedImages.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _selectedImages.length,
                    (i) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetailsInput(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Caption input
          Container(
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: modernTheme.borderColor ?? Colors.grey.withOpacity(0.2),
              ),
            ),
            child: TextField(
              controller: _captionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Write a caption...',
                hintStyle: TextStyle(
                  color: modernTheme.textSecondaryColor,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              style: TextStyle(
                color: modernTheme.textColor,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Tags input
          Container(
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: modernTheme.borderColor ?? Colors.grey.withOpacity(0.2),
              ),
            ),
            child: TextField(
              controller: _tagsController,
              decoration: InputDecoration(
                hintText: 'Add tags (comma separated)',
                hintStyle: TextStyle(
                  color: modernTheme.textSecondaryColor,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                prefixIcon: Icon(
                  Icons.tag,
                  color: modernTheme.primaryColor,
                ),
              ),
              style: TextStyle(
                color: modernTheme.textColor,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Post button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handlePost,
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Post',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay(ModernThemeExtension modernTheme) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: modernTheme.primaryColor,
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              _processingMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  
  void _toggleTimer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final modernTheme = context.modernTheme;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: modernTheme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Set Timer',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                children: [0, 3, 5, 10].map((seconds) {
                  return ChoiceChip(
                    label: Text(seconds == 0 ? 'Off' : '${seconds}s'),
                    selected: (_useTimer && _timerDuration == seconds) || (!_useTimer && seconds == 0),
                    onSelected: (selected) {
                      setState(() {
                        _useTimer = seconds > 0;
                        _timerDuration = seconds;
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectFromGallery() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => MediaGallerySelector(
          isVideoMode: _isVideoMode,
          onFilesSelected: (files) async {
            if (_isVideoMode && files.isNotEmpty) {
              await _processSelectedVideo(files.first);
            } else {
              setState(() {
                _selectedImages = files;
              });
            }
          },
        ),
      ),
    );
  }

  Future<void> _openCamera() async {
    // Check for camera availability
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No camera available')),
      );
      return;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => CameraScreen(
          cameras: cameras,
          isVideoMode: _isVideoMode,
          showGrid: _showGrid,
          flashOn: _flashOn,
          useTimer: _useTimer,
          timerDuration: _timerDuration,
          onMediaCaptured: (file) async {
            if (_isVideoMode) {
              await _processSelectedVideo(file);
            } else {
              setState(() {
                _selectedImages = [file];
              });
            }
          },
        ),
      ),
    );
  }

  Future<void> _processSelectedVideo(File videoFile) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      _videoController = VideoPlayerController.file(videoFile);
      await _videoController!.initialize();
      
      _videoDuration = _videoController!.value.duration;
      _endTime = _videoDuration;
      
      setState(() {
        _selectedVideo = videoFile;
        _isLoading = false;
      });
      
      _videoController!.play();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading video: $e')),
        );
      }
    }
  }

  Future<List<AssetEntity>> _loadRecentMedia() async {
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: _isVideoMode ? RequestType.video : RequestType.image,
    );
    
    if (albums.isEmpty) return [];
    
    final recentAlbum = albums.first;
    final List<AssetEntity> assets = await recentAlbum.getAssetListRange(
      start: 0,
      end: 20,
    );
    
    return assets;
  }

  Future<void> _handleAssetSelection(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) return;
    
    if (asset.type == AssetType.video) {
      // Check duration
      if (asset.duration > 300) { // 5 minutes in seconds
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video must be less than 5 minutes'),
            ),
          );
        }
        return;
      }
      await _processSelectedVideo(file);
    } else {
      setState(() {
        if (_selectedImages.length < 10) {
          _selectedImages.add(file);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 10 images allowed'),
            ),
          );
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _toggleVideoPlayback() {
    if (_videoController == null) return;
    
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    });
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _handleNext() {
    // Navigate to details screen or show details input
    setState(() {
      // Show details input is already shown in the preview
    });
  }

  Future<void> _handlePost() async {
    if (_captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a caption')),
      );
      return;
    }
    
    final channelVideosNotifier = ref.read(channelVideosProvider.notifier);
    final userChannel = ref.read(channelsProvider).userChannel;
    
    if (userChannel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to create a channel first')),
      );
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Preparing your post...';
    });
    
    try {
      // Parse tags
      List<String> tags = [];
      if (_tagsController.text.isNotEmpty) {
        tags = _tagsController.text.split(',').map((tag) => tag.trim()).toList();
      }
      
      if (_selectedVideo != null) {
        // Process and upload video
        setState(() {
          _processingMessage = 'Uploading video...';
        });
        
        // TODO: If video needs trimming, process it first
        File videoToUpload = _selectedVideo!;
        if (_videoDuration > const Duration(minutes: 5)) {
          // Trim video
          videoToUpload = await _trimVideo(_selectedVideo!);
        }
        
        await channelVideosNotifier.uploadVideo(
          channel: userChannel,
          videoFile: videoToUpload,
          caption: _captionController.text,
          tags: tags,
          onSuccess: (message) {
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
          onError: (error) {
            setState(() {
              _isProcessing = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error)),
            );
          },
        );
      } else if (_selectedImages.isNotEmpty) {
        // Upload images
        setState(() {
          _processingMessage = 'Uploading images...';
        });
        
        await channelVideosNotifier.uploadImages(
          channel: userChannel,
          imageFiles: _selectedImages,
          caption: _captionController.text,
          tags: tags,
          onSuccess: (message) {
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
          onError: (error) {
            setState(() {
              _isProcessing = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error)),
            );
          },
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<File> _trimVideo(File videoFile) async {
    // TODO: Implement video trimming
    // For now, return the original file
    return videoFile;
  }
}
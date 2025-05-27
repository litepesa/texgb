// lib/features/channels/screens/create_channel_post_screen.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:camera/camera.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/services/post_creation_service.dart';
import 'package:textgb/features/channels/services/draft_service.dart';
import 'package:textgb/features/channels/widgets/media_gallery_selector.dart';
import 'package:textgb/features/channels/widgets/camera_screen.dart';
import 'package:textgb/features/channels/widgets/enhanced_media_preview.dart';
import 'package:textgb/features/channels/widgets/enhanced_post_form.dart';
import 'package:textgb/features/channels/widgets/upload_progress_widget.dart';
import 'package:textgb/features/channels/widgets/drafts_sheet_widget.dart';
import 'package:textgb/features/channels/widgets/video_trimmer_widget.dart';

class CreateChannelPostScreen extends ConsumerStatefulWidget {
  const CreateChannelPostScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateChannelPostScreen> createState() => 
      _CreateChannelPostScreenState();
}

class _CreateChannelPostScreenState 
    extends ConsumerState<CreateChannelPostScreen>
    with TickerProviderStateMixin {
  
  // Services
  late PostCreationService _postService;
  late DraftService _draftService;
  
  // Controllers
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  late AnimationController _pageAnimationController;
  late Animation<double> _pageAnimation;
  VideoPlayerController? _videoController;
  
  // State
  List<File> _selectedImages = [];
  File? _selectedVideo;
  bool _isVideoMode = true;
  PageController _pageController = PageController();
  int _currentStep = 0; // 0: selection, 1: preview, 2: details
  
  // Camera settings
  bool _useTimer = false;
  int _timerDuration = 3;
  bool _showGrid = false;
  bool _flashOn = false;
  
  // Auto-save timer
  Timer? _autoSaveTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _checkPermissions();
    _loadDraftIfAvailable();
    _setupAutoSave();
  }

  void _initializeServices() {
    _postService = PostCreationService();
    _draftService = DraftService();
    _draftService.initialize();
  }

  void _initializeAnimations() {
    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pageAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _pageAnimationController.forward();
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

  void _loadDraftIfAvailable() {
    if (_draftService.hasDrafts) {
      // Show option to load recent draft
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLoadDraftDialog();
      });
    } else {
      // Create new draft
      _draftService.createDraft();
    }
  }

  void _setupAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _autoSaveDraft();
    });
    
    // Listen to text changes for immediate auto-save
    _captionController.addListener(_onFormChanged);
    _tagsController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    // Debounce auto-save
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _autoSaveDraft);
  }

  Future<void> _autoSaveDraft() async {
    if (_captionController.text.isNotEmpty || 
        _tagsController.text.isNotEmpty ||
        _selectedImages.isNotEmpty ||
        _selectedVideo != null) {
      
      List<String> mediaPaths = [];
      if (_selectedVideo != null) {
        mediaPaths = [_selectedVideo!.path];
      } else {
        mediaPaths = _selectedImages.map((img) => img.path).toList();
      }
      
      await _draftService.autoSaveDraft(
        caption: _captionController.text,
        tags: _tagsController.text.split(',').map((t) => t.trim()).toList(),
        mediaPaths: mediaPaths,
        isVideo: _selectedVideo != null,
      );
    }
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    _captionController.dispose();
    _tagsController.dispose();
    _pageController.dispose();
    _videoController?.dispose();
    _autoSaveTimer?.cancel();
    _postService.dispose();
    _draftService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {
          _autoSaveDraft();
        }
      },
      child: Scaffold(
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
                    modernTheme.backgroundColor!,
                    modernTheme.primaryColor!.withOpacity(0.02),
                  ],
                ),
              ),
            ),
            
            // Main content
            SafeArea(
              child: FadeTransition(
                opacity: _pageAnimation,
                child: Column(
                  children: [
                    _buildAppBar(modernTheme),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentStep = index;
                          });
                        },
                        children: [
                          _buildMediaSelectionStep(modernTheme),
                          _buildPreviewStep(modernTheme),
                          _buildDetailsStep(modernTheme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Upload progress overlay
            if (_postService.isUploading || _postService.isProcessing)
              Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: UploadProgressWidget(
                    service: _postService,
                    onCancel: _postService.canCancel ? _postService.cancelUpload : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: modernTheme.backgroundColor!.withOpacity(0.95),
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
          // Back/Close button
          IconButton(
            onPressed: _handleBackPress,
            icon: Icon(
              _currentStep > 0 ? Icons.arrow_back : Icons.close,
              color: modernTheme.textColor,
            ),
          ),
          
          // Title and progress
          Expanded(
            child: Column(
              children: [
                Text(
                  _getStepTitle(),
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                _buildProgressIndicator(modernTheme),
              ],
            ),
          ),
          
          // Action buttons
          Row(
            children: [
              // Drafts button
              if (_currentStep == 0 && _draftService.hasDrafts)
                IconButton(
                  onPressed: _showDraftsSheet,
                  icon: Icon(
                    Icons.drafts_outlined,
                    color: modernTheme.primaryColor,
                  ),
                ),
              
              // Next/Post button
              if (_canProceed())
                TextButton(
                  onPressed: _handleNextStep,
                  child: Text(
                    _getActionButtonText(),
                    style: TextStyle(
                      color: modernTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ModernThemeExtension modernTheme) {
    return Container(
      width: 120,
      height: 4,
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: (_currentStep + 1) / 3,
        child: Container(
          decoration: BoxDecoration(
            color: modernTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaSelectionStep(ModernThemeExtension modernTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Media type toggle
          _buildMediaTypeToggle(modernTheme),
          const SizedBox(height: 32),
          
          // Main action buttons
          _buildMainActions(modernTheme),
          const SizedBox(height: 24),
          
          // Camera settings (if video mode)
          if (_isVideoMode)
            _buildCameraSettings(modernTheme),
          
          const SizedBox(height: 32),
          
          // Recent media grid
          _buildRecentMediaGrid(modernTheme),
        ],
      ),
    );
  }

  Widget _buildPreviewStep(ModernThemeExtension modernTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Media preview
          EnhancedMediaPreview(
            images: _selectedImages,
            video: _selectedVideo,
            onImageRemove: (index) {
              setState(() {
                _selectedImages.removeAt(index);
              });
              if (_selectedImages.isEmpty) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            onVideoRemove: () {
              setState(() {
                _selectedVideo = null;
                _videoController?.dispose();
                _videoController = null;
              });
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            onVideoTrim: _showVideoTrimmer,
          ),
          
          const SizedBox(height: 24),
          
          // Quick actions
          _buildPreviewActions(modernTheme),
        ],
      ),
    );
  }

  Widget _buildDetailsStep(ModernThemeExtension modernTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: EnhancedPostForm(
        captionController: _captionController,
        tagsController: _tagsController,
        isEnabled: !_postService.isUploading && !_postService.isProcessing,
        onCaptionChanged: (caption) => _onFormChanged(),
        onTagsChanged: (tags) => _onFormChanged(),
      ),
    );
  }

  Widget _buildMediaTypeToggle(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
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

  Widget _buildRecentMediaGrid(ModernThemeExtension modernTheme) {
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
                return const Center(child: CircularProgressIndicator());
              }
              
              final assets = snapshot.data!;
              if (assets.isEmpty) {
                return Center(
                  child: Text(
                    'No recent media',
                    style: TextStyle(color: modernTheme.textSecondaryColor),
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
          content = Image.memory(snapshot.data!, fit: BoxFit.cover);
        } else {
          content = Container(
            color: modernTheme.surfaceColor,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        
        return GestureDetector(
          onTap: () => _handleAssetSelection(asset),
          child: Container(
            width: 100,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.hardEdge,
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
                        style: const TextStyle(color: Colors.white, fontSize: 10),
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

  Widget _buildPreviewActions(ModernThemeExtension modernTheme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Media'),
            style: OutlinedButton.styleFrom(
              foregroundColor: modernTheme.primaryColor,
              side: BorderSide(color: modernTheme.primaryColor!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Add Details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: modernTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods
  
  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Select Media';
      case 1:
        return 'Preview';
      case 2:
        return 'Add Details';
      default:
        return 'Create Post';
    }
  }

  String _getActionButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Next';
      case 1:
        return 'Next';
      case 2:
        return 'Post';
      default:
        return 'Post';
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedImages.isNotEmpty || _selectedVideo != null;
      case 1:
        return true;
      case 2:
        return _captionController.text.trim().isNotEmpty && 
               !_postService.isUploading && 
               !_postService.isProcessing;
      default:
        return false;
    }
  }

  void _handleBackPress() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _autoSaveDraft();
      Navigator.of(context).pop();
    }
  }

  void _handleNextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _handlePost();
    }
  }

  Future<void> _selectFromGallery() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => MediaGallerySelector(
          isVideoMode: _isVideoMode,
          onFilesSelected: (files) {
            if (_isVideoMode && files.isNotEmpty) {
              _processSelectedVideo(files.first);
            } else {
              setState(() {
                _selectedImages = files;
              });
            }
          },
        ),
      ),
    );
    
    if (result != null && (_selectedImages.isNotEmpty || _selectedVideo != null)) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _openCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No camera available')),
      );
      return;
    }
    
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => CameraScreen(
          cameras: cameras,
          isVideoMode: _isVideoMode,
          showGrid: _showGrid,
          flashOn: _flashOn,
          useTimer: _useTimer,
          timerDuration: _timerDuration,
          onMediaCaptured: (file) {
            if (_isVideoMode) {
              _processSelectedVideo(file);
            } else {
              setState(() {
                _selectedImages = [file];
              });
            }
          },
        ),
      ),
    );
    
    if (result != null && (_selectedImages.isNotEmpty || _selectedVideo != null)) {    
     _pageController.nextPage(
       duration: const Duration(milliseconds: 300),
       curve: Curves.easeInOut,
     );
   }
 }

 Future<void> _processSelectedVideo(File videoFile) async {
   // Validate file
   final validation = _postService.validateMediaFile(videoFile, true);
   if (!validation.isValid) {
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text(validation.message)),
     );
     return;
   }
   
   try {
     _videoController = VideoPlayerController.file(videoFile);
     await _videoController!.initialize();
     
     setState(() {
       _selectedVideo = videoFile;
     });
     
     _videoController!.play();
   } catch (e) {
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('Error loading video: $e')),
     );
   }
 }

 Future<List<AssetEntity>> _loadRecentMedia() async {
   final albums = await PhotoManager.getAssetPathList(
     type: _isVideoMode ? RequestType.video : RequestType.image,
   );
   
   if (albums.isEmpty) return [];
   
   return albums.first.getAssetListRange(start: 0, end: 20);
 }

 Future<void> _handleAssetSelection(AssetEntity asset) async {
   final file = await asset.file;
   if (file == null) return;
   
   if (asset.type == AssetType.video) {
     if (asset.duration > 300) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Video must be less than 5 minutes')),
       );
       return;
     }
     await _processSelectedVideo(file);
   } else {
     setState(() {
       if (_selectedImages.length < 10) {
         _selectedImages.add(file);
       } else {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Maximum 10 images allowed')),
         );
       }
     });
   }
   
   if (_selectedImages.isNotEmpty || _selectedVideo != null) {
     _pageController.nextPage(
       duration: const Duration(milliseconds: 300),
       curve: Curves.easeInOut,
     );
   }
 }

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

 void _showVideoTrimmer(Duration start, Duration end) {
   if (_selectedVideo == null) return;
   
   showModalBottomSheet(
     context: context,
     isScrollControlled: true,
     backgroundColor: Colors.transparent,
     builder: (context) => VideoTrimmerWidget(
       videoFile: _selectedVideo!,
       videoDuration: _videoController?.value.duration ?? Duration.zero,
       onTrimComplete: (startTime, endTime) async {
         Navigator.pop(context);
         
         try {
           final trimmedVideo = await _postService.trimVideo(
             _selectedVideo!,
             startTime,
             endTime,
           );
           
           setState(() {
             _selectedVideo = trimmedVideo;
           });
           
           // Reinitialize video controller with trimmed video
           _videoController?.dispose();
           _videoController = VideoPlayerController.file(trimmedVideo);
           await _videoController!.initialize();
           
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Video trimmed successfully')),
           );
         } catch (e) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error trimming video: $e')),
           );
         }
       },
       onCancel: () => Navigator.pop(context),
     ),
   );
 }

 void _showDraftsSheet() {
   showModalBottomSheet(
     context: context,
     isScrollControlled: true,
     backgroundColor: Colors.transparent,
     builder: (context) => DraftsSheetWidget(
       draftService: _draftService,
       onDraftSelected: _loadDraft,
       onCreateNew: () {
         Navigator.pop(context);
         _draftService.createDraft();
       },
     ),
   );
 }

 void _loadDraft(PostDraft draft) {
   _draftService.loadDraft(draft);
   
   setState(() {
     _captionController.text = draft.caption;
     _tagsController.text = draft.tags.join(', ');
     _isVideoMode = draft.isVideo;
     
     // Load media files
     if (draft.isVideo && draft.mediaPaths.isNotEmpty) {
       _processSelectedVideo(File(draft.mediaPaths.first));
     } else {
       _selectedImages = draft.mediaPaths.map((path) => File(path)).toList();
     }
   });
   
   // Navigate to appropriate step
   if (draft.mediaPaths.isNotEmpty) {
     if (draft.caption.isNotEmpty || draft.tags.isNotEmpty) {
       _pageController.animateToPage(
         2,
         duration: const Duration(milliseconds: 300),
         curve: Curves.easeInOut,
       );
     } else {
       _pageController.animateToPage(
         1,
         duration: const Duration(milliseconds: 300),
         curve: Curves.easeInOut,
       );
     }
   }
 }

 void _showLoadDraftDialog() {
   final recentDraft = _draftService.drafts.first;
   
   showDialog(
     context: context,
     builder: (context) {
       final modernTheme = context.modernTheme;
       return AlertDialog(
         backgroundColor: modernTheme.backgroundColor,
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(16),
         ),
         title: Text(
           'Continue Draft?',
           style: TextStyle(color: modernTheme.textColor),
         ),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(
               'You have an unsaved draft:',
               style: TextStyle(color: modernTheme.textSecondaryColor),
             ),
             const SizedBox(height: 8),
             Text(
               recentDraft.previewText,
               style: TextStyle(
                 color: modernTheme.textColor,
                 fontWeight: FontWeight.w500,
               ),
             ),
             const SizedBox(height: 4),
             Text(
               recentDraft.timeAgo,
               style: TextStyle(
                 color: modernTheme.textSecondaryColor,
                 fontSize: 12,
               ),
             ),
           ],
         ),
         actions: [
           TextButton(
             onPressed: () {
               Navigator.pop(context);
               _draftService.createDraft();
             },
             child: Text(
               'Start New',
               style: TextStyle(color: modernTheme.textSecondaryColor),
             ),
           ),
           TextButton(
             onPressed: () {
               Navigator.pop(context);
               _loadDraft(recentDraft);
             },
             child: Text(
               'Continue',
               style: TextStyle(color: modernTheme.primaryColor),
             ),
           ),
         ],
       );
     },
   );
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
   
   try {
     _postService.startUpload();
     
     // Parse tags
     List<String> tags = [];
     if (_tagsController.text.isNotEmpty) {
       tags = _tagsController.text
           .split(',')
           .map((tag) => tag.trim())
           .where((tag) => tag.isNotEmpty)
           .toList();
     }
     
     if (_selectedVideo != null) {
       // Process video
       File videoToUpload = _selectedVideo!;
       
       // Compress if needed
       if (await _selectedVideo!.length() > 100 * 1024 * 1024) { // 100MB
         videoToUpload = await _postService.compressVideo(_selectedVideo!);
       }
       
       // Upload video
       await channelVideosNotifier.uploadVideo(
         channel: userChannel,
         videoFile: videoToUpload,
         caption: _captionController.text,
         tags: tags,
         onSuccess: (message) {
           _postService.completeUpload();
           _draftService.completeDraft();
           Navigator.of(context).pop(true);
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(message)),
           );
         },
         onError: (error) {
           _postService.resetUpload();
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(error)),
           );
         },
       );
     } else if (_selectedImages.isNotEmpty) {
       // Process images
       List<File> imagesToUpload = [];
       for (final image in _selectedImages) {
         final optimized = await _postService.optimizeImage(image);
         imagesToUpload.add(optimized);
       }
       
       // Upload images
       await channelVideosNotifier.uploadImages(
         channel: userChannel,
         imageFiles: imagesToUpload,
         caption: _captionController.text,
         tags: tags,
         onSuccess: (message) {
           _postService.completeUpload();
           _draftService.completeDraft();
           Navigator.of(context).pop(true);
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(message)),
           );
         },
         onError: (error) {
           _postService.resetUpload();
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(error)),
           );
         },
       );
     }
   } catch (e) {
     _postService.resetUpload();
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('Error: $e')),
     );
   }
 }

 String _formatDuration(int seconds) {
   final duration = Duration(seconds: seconds);
   final minutes = duration.inMinutes;
   final remainingSeconds = duration.inSeconds % 60;
   return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
 }
}
// lib/features/moments/screens/create_moment_screen.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:ffmpeg_kit_flutter_new_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_gpl/return_code.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as path;
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/providers/moments_provider.dart';
import 'package:textgb/features/moments/widgets/privacy_selector.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

// Video info class for analysis
class VideoInfo {
  final Duration duration;
  final Size resolution;
  final double fileSizeMB;
  final int? currentBitrate;
  final double frameRate;
  
  VideoInfo({
    required this.duration,
    required this.resolution,
    required this.fileSizeMB,
    this.currentBitrate,
    required this.frameRate,
  });
}

class CreateMomentScreen extends ConsumerStatefulWidget {
  const CreateMomentScreen({super.key});

  @override
  ConsumerState<CreateMomentScreen> createState() => _CreateMomentScreenState();
}

class _CreateMomentScreenState extends ConsumerState<CreateMomentScreen> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  // Cache manager for efficient file handling
  static final CacheManager _cacheManager = CacheManager(
    Config(
      'moment_video_cache',
      stalePeriod: const Duration(days: 3),
      maxNrOfCacheObjects: 10,
    ),
  );
  
  // Default to video as primary content type
  MomentType _selectedType = MomentType.video;
  MomentPrivacy _selectedPrivacy = MomentPrivacy.public;
  List<String> _selectedContacts = [];
  
  File? _videoFile;
  VideoInfo? _videoInfo;
  List<File> _imageFiles = [];
  VideoPlayerController? _videoController;
  
  // Processing and upload state
  bool _isProcessing = false;
  bool _isUploading = false;
  double _processingProgress = 0.0;
  double _uploadProgress = 0.0;
  String _processingStatus = '';
  
  // Wakelock state tracking
  bool _wakelockActive = false;

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    _cacheManager.emptyCache();
    _disableWakelock();
    super.dispose();
  }

  // Wakelock management methods
  Future<void> _enableWakelock() async {
    if (!_wakelockActive) {
      try {
        await WakelockPlus.enable();
        _wakelockActive = true;
      } catch (e) {
        // Silent failure
      }
    }
  }

  Future<void> _disableWakelock() async {
    if (_wakelockActive) {
      try {
        await WakelockPlus.disable();
        _wakelockActive = false;
      } catch (e) {
        // Silent failure
      }
    }
  }

  // Video analysis method
  Future<VideoInfo> _analyzeVideo(File videoFile) async {
    try {
      final controller = VideoPlayerController.file(videoFile);
      await controller.initialize();
      
      final duration = controller.value.duration;
      final size = controller.value.size;
      final fileSizeBytes = await videoFile.length();
      final fileSizeMB = fileSizeBytes / (1024 * 1024);
      
      // Calculate current bitrate
      int? currentBitrate;
      if (duration.inSeconds > 0) {
        currentBitrate = ((fileSizeBytes * 8) / duration.inSeconds / 1000).round();
      }
      
      await controller.dispose();
      
      return VideoInfo(
        duration: duration,
        resolution: size,
        fileSizeMB: fileSizeMB,
        currentBitrate: currentBitrate,
        frameRate: 30.0, // Default assumption
      );
    } catch (e) {
      final fileSizeBytes = await videoFile.length();
      return VideoInfo(
        duration: const Duration(seconds: 60),
        resolution: const Size(1920, 1080),
        fileSizeMB: fileSizeBytes / (1024 * 1024),
        frameRate: 30.0,
      );
    }
  }

  // Audio processing method for moments (similar to create post)
  Future<File?> _processVideoAudio(File inputFile, VideoInfo info) async {
    try {
      final tempDir = Directory.systemTemp;
      final outputPath = '${tempDir.path}/moment_audio_processed_${DateTime.now().millisecondsSinceEpoch}.mp4';
      
      await _enableWakelock();
      
      setState(() {
        _isProcessing = true;
        _processingProgress = 0.0;
      });

      // Audio-only processing command (keeping video as-is)
      final audioCommand = '-y -i "${inputFile.path}" '
          // Copy video stream without processing
          '-c:v copy '
          // Premium audio processing - same as create post
          '-c:a aac '
          '-b:a 128k '
          '-ar 48000 '
          '-ac 2 '
          '-af "volume=2.2,equalizer=f=60:width_type=h:width=2:g=3,equalizer=f=150:width_type=h:width=2:g=2,equalizer=f=8000:width_type=h:width=2:g=1,compand=attacks=0.2:decays=0.4:points=-80/-80|-50/-20|-30/-15|-20/-10|-5/-5|0/-2|20/-2,highpass=f=40,lowpass=f=15000,loudnorm=I=-10:TP=-1.5:LRA=7:linear=true" '
          '-movflags +faststart '
          '-f mp4 "$outputPath"';

      setState(() {
        _processingProgress = 0.3;
      });

      final videoDurationMs = info.duration.inMilliseconds;
      final Completer<void> processingCompleter = Completer<void>();
      
      FFmpegKit.executeAsync(
        audioCommand,
        (session) async {
          final returnCode = await session.getReturnCode();
          
          if (mounted) {
            setState(() {
              _isProcessing = false;
              _processingProgress = 1.0;
            });
          }
          
          if (!processingCompleter.isCompleted) {
            processingCompleter.complete();
          }
        },
        (log) {
          // Silent logging
        },
        (statistics) {
          if (mounted && _isProcessing && statistics.getTime() > 0 && videoDurationMs > 0) {
            final baseProgress = 0.3;
            final encodingProgress = (statistics.getTime() / videoDurationMs).clamp(0.0, 1.0);
            final totalProgress = baseProgress + (encodingProgress * 0.7);
            
            setState(() {
              _processingProgress = totalProgress.clamp(0.0, 1.0);
            });
          }
        },
      );
      
      await processingCompleter.future;
      
      final outputFile = File(outputPath);
      if (await outputFile.exists()) {
        // Hide processing status after delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _processingStatus = '';
              _processingProgress = 0.0;
            });
          }
        });
        
        return outputFile;
      }
      
      await _disableWakelock();
      return null;
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingProgress = 0.0;
        });
      }
      await _disableWakelock();
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.modernTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.modernTheme.appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.modernTheme.textColor),
          onPressed: () {
            _disableWakelock();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Create Moment',
          style: TextStyle(
            color: context.modernTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_hasContent())
            TextButton(
              onPressed: (_isUploading || _isProcessing) ? null : _createMoment,
              child: _isProcessing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          context.modernTheme.primaryColor!,
                        ),
                      ),
                    )
                  : (_isUploading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              context.modernTheme.primaryColor!,
                            ),
                          ),
                        )
                      : Text(
                          'Share',
                          style: TextStyle(
                            color: context.modernTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )),
            ),
        ],
      ),
      body: Column(
        children: [
          // Content type selector - more subtle design
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: context.modernTheme.surfaceVariantColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildCompactTypeOption(
                    icon: Icons.videocam,
                    label: 'Video',
                    isSelected: _selectedType == MomentType.video,
                    onTap: () => setState(() => _selectedType = MomentType.video),
                    enabled: !_isProcessing && !_isUploading,
                  ),
                ),
                Expanded(
                  child: _buildCompactTypeOption(
                    icon: Icons.photo_library,
                    label: 'Photos',
                    isSelected: _selectedType == MomentType.images,
                    onTap: () => setState(() => _selectedType = MomentType.images),
                    enabled: !_isProcessing && !_isUploading,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Media content area - optimized for vertical video
                  _buildMediaContent(),
                  
                  const SizedBox(height: 20),

                  // Caption input - more prominent
                  _buildCaptionInput(),
                  
                  const SizedBox(height: 20),

                  // Privacy settings - simplified
                  _buildPrivacySettings(),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Action buttons - cleaner design
          if (!_hasContent() || _selectedType == MomentType.video && _videoFile == null || 
              _selectedType == MomentType.images && _imageFiles.isEmpty)
            _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildCompactTypeOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? context.modernTheme.primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? Colors.white
                  : context.modernTheme.textSecondaryColor,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? Colors.white
                    : context.modernTheme.textSecondaryColor,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent() {
    if (_selectedType == MomentType.video) {
      return _buildVideoContent();
    } else {
      return _buildImageContent();
    }
  }

  Widget _buildVideoContent() {
    // Use 9:16 aspect ratio for TikTok-style vertical video
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _videoFile == null
              ? _buildMediaPlaceholder(
                  icon: Icons.videocam_outlined,
                  title: 'Add Video',
                  subtitle: 'Select video 1 Minute Max',
                  onTap: _selectVideo,
                )
              : _buildVideoPreview(),
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 300),
      decoration: BoxDecoration(
        color: context.modernTheme.surfaceVariantColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.modernTheme.borderColor!.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: _imageFiles.isEmpty
          ? _buildMediaPlaceholder(
              icon: Icons.photo_library_outlined,
              title: 'Add Photos',
              subtitle: 'Select up to 9 photos',
              onTap: _selectImages,
            )
          : _buildImageGrid(),
    );
  }

  Widget _buildMediaPlaceholder({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isEnabled = !_isProcessing && !_isUploading;
    
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.modernTheme.primaryColor!.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: context.modernTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                color: isEnabled 
                    ? context.modernTheme.textColor
                    : context.modernTheme.textColor!.withOpacity(0.5),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: context.modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video player - fills the entire 9:16 container
        if (_videoController != null && _videoController!.value.isInitialized)
          FittedBox(
            fit: BoxFit.cover, // Cover ensures no black bars
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          )
        else
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),

        // Gradient overlay for better UI
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.4),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.6),
              ],
              stops: const [0.0, 0.2, 0.8, 1.0],
            ),
          ),
        ),

        // Top controls
        Positioned(
          top: 12,
          right: 12,
          child: Row(
            children: [
              // Duration badge
              if (_videoInfo != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_videoInfo!.duration.inSeconds}s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              // Remove button
              GestureDetector(
                onTap: (!_isProcessing && !_isUploading) ? _removeVideo : null,
                child: Container(
                  padding: const EdgeInsets.all(8),
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
            ],
          ),
        ),

        // Play/pause button - centered
        Center(
          child: GestureDetector(
            onTap: (!_isProcessing && !_isUploading) ? _toggleVideoPlayback : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _videoController?.value.isPlaying == true
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),

        // Bottom action to change video
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: GestureDetector(
            onTap: (!_isProcessing && !_isUploading) ? _selectVideo : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.refresh,
                    color: context.modernTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Change Video',
                    style: TextStyle(
                      color: context.modernTheme.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _imageFiles.length + (_imageFiles.length < 9 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _imageFiles.length) {
                return _buildAddImageTile();
              }
              return _buildImageTile(_imageFiles[index], index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageTile() {
    final isEnabled = !_isProcessing && !_isUploading;
    
    return GestureDetector(
      onTap: isEnabled ? _selectImages : null,
      child: Container(
        decoration: BoxDecoration(
          color: context.modernTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.modernTheme.borderColor!.withOpacity(0.3),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.add_rounded,
          color: context.modernTheme.primaryColor,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildImageTile(File imageFile, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: FileImage(imageFile),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: (!_isProcessing && !_isUploading) ? () => _removeImage(index) : null,
            child: Container(
              padding: const EdgeInsets.all(4),
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
  }

  Widget _buildCaptionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _captionController,
          maxLines: 3,
          maxLength: 500,
          enabled: !_isProcessing && !_isUploading,
          decoration: InputDecoration(
            hintText: 'Add a caption...',
            hintStyle: TextStyle(
              color: context.modernTheme.textSecondaryColor,
              fontSize: 16,
            ),
            filled: true,
            fillColor: context.modernTheme.surfaceVariantColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: context.modernTheme.primaryColor!,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
            counterText: '',
          ),
          style: TextStyle(
            color: context.modernTheme.textColor,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.modernTheme.surfaceVariantColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                color: context.modernTheme.textSecondaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Privacy',
                style: TextStyle(
                  color: context.modernTheme.textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrivacySelector(
            selectedPrivacy: _selectedPrivacy,
            selectedContacts: _selectedContacts,
            enabled: !_isProcessing && !_isUploading,
            onPrivacyChanged: (privacy) {
              setState(() {
                _selectedPrivacy = privacy;
                if (privacy == MomentPrivacy.public || privacy == MomentPrivacy.contacts) {
                  _selectedContacts.clear();
                }
              });
            },
            onContactsChanged: (contacts) {
              setState(() {
                _selectedContacts = contacts;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isProcessingOrUploading = _isProcessing || _isUploading;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.modernTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: !isProcessingOrUploading 
              ? (_selectedType == MomentType.video ? _selectVideo : _selectImages)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.modernTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_selectedType == MomentType.video ? Icons.videocam : Icons.photo_library),
              const SizedBox(width: 8),
              Text(
                _selectedType == MomentType.video ? 'Select a Video' : 'Select Photos',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasContent() {
    return (_selectedType == MomentType.video && _videoFile != null) ||
           (_selectedType == MomentType.images && _imageFiles.isNotEmpty);
  }

  Future<void> _selectVideo() async {
    if (_isProcessing || _isUploading) return;
    
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 1),
      );

      if (video != null) {
        final videoFile = File(video.path);
        
        if (await videoFile.exists()) {
          // Analyze video immediately for info display
          final videoInfo = await _analyzeVideo(videoFile);
          
          setState(() {
            _videoFile = videoFile;
            _videoInfo = videoInfo;
            _selectedType = MomentType.video;
            _imageFiles.clear(); // Clear images when selecting video
          });
          
          _initializeVideoController();
        } else {
          showSnackBar(context, 'Selected video file not found');
        }
      }
    } catch (e) {
      showSnackBar(context, 'Failed to select video');
    }
  }

  Future<void> _selectImages() async {
    if (_isProcessing || _isUploading) return;
    
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        final totalImages = _imageFiles.length + images.length;
        if (totalImages > 9) {
          showSnackBar(context, 'You can only select up to 9 images');
          return;
        }

        setState(() {
          _imageFiles.addAll(images.map((image) => File(image.path)));
          _selectedType = MomentType.images;
          // Clear video when selecting images
          _videoFile = null;
          _videoInfo = null;
        });
        
        _videoController?.dispose();
        _videoController = null;
      }
    } catch (e) {
      showSnackBar(context, 'Failed to select images');
    }
  }

  void _initializeVideoController() {
    if (_videoFile == null) return;

    _videoController?.dispose();
    _videoController = VideoPlayerController.file(_videoFile!);
    _videoController!.initialize().then((_) {
      if (mounted) {
        setState(() {});
        _videoController!.setLooping(true);
      }
    }).catchError((error) {
      showSnackBar(context, 'Failed to initialize video player');
    });
  }

  void _toggleVideoPlayback() {
    if (_videoController == null || _isProcessing || _isUploading) return;

    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
    setState(() {});
  }

  void _removeVideo() {
    if (_isProcessing || _isUploading) return;
    
    setState(() {
      _videoFile = null;
      _videoInfo = null;
    });
    _videoController?.dispose();
    _videoController = null;
  }

  void _removeImage(int index) {
    if (_isProcessing || _isUploading) return;
    
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  Future<void> _createMoment() async {
    if (!_hasContent() || _isProcessing || _isUploading) return;

    try {
      // Enable wakelock for the entire process
      await _enableWakelock();
      
      File? finalVideoFile = _videoFile;
      
      // Process video audio if we have a video
      if (_selectedType == MomentType.video && _videoFile != null && _videoInfo != null) {
        final processedVideo = await _processVideoAudio(_videoFile!, _videoInfo!);
        
        if (processedVideo != null) {
          finalVideoFile = processedVideo;
        }
      }

      // Start upload process
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      // Simulate upload progress
      _simulateUploadProgress();

      final momentId = await ref.read(momentsProvider.notifier).createMoment(
        content: _captionController.text.trim(),
        type: _selectedType,
        privacy: _selectedPrivacy,
        selectedContacts: _selectedContacts,
        videoFile: finalVideoFile,
        imageFiles: _imageFiles.isNotEmpty ? _imageFiles : null,
      );

      if (momentId != null) {
        setState(() {
          _uploadProgress = 1.0;
        });
        
        // Show success message
        showSnackBar(context, 'Moment shared successfully!');
        
        // Small delay to show completion, then navigate back
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          await _disableWakelock();
          Navigator.pop(context);
        }
      } else {
        final momentsState = ref.read(momentsProvider);
        throw Exception(momentsState.error ?? 'Failed to create moment');
      }
    } catch (e) {
      showSnackBar(context, 'Failed to share moment');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
      await _disableWakelock();
    }
  }

  // Simulate upload progress
  void _simulateUploadProgress() {
    const totalSteps = 20;
    int currentStep = 0;
    
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isUploading || !mounted) {
        timer.cancel();
        return;
      }
      
      currentStep++;
      final progress = (currentStep / totalSteps).clamp(0.0, 0.95);
      
      setState(() {
        _uploadProgress = progress;
      });
      
      if (currentStep >= totalSteps) {
        timer.cancel();
      }
    });
  }
}
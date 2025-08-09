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
  
  @override
  String toString() {
    return 'Duration: ${duration.inSeconds}s, Resolution: ${resolution.width}x${resolution.height}, '
           'Size: ${fileSizeMB.toStringAsFixed(1)}MB, Bitrate: ${currentBitrate ?? 'unknown'}kbps, '
           'FPS: ${frameRate.toStringAsFixed(1)}';
  }
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
  
  MomentType _selectedType = MomentType.images;
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
        print('DEBUG: Wakelock enabled for moment creation');
      } catch (e) {
        print('DEBUG: Failed to enable wakelock: $e');
      }
    }
  }

  Future<void> _disableWakelock() async {
    if (_wakelockActive) {
      try {
        await WakelockPlus.disable();
        _wakelockActive = false;
        print('DEBUG: Wakelock disabled');
      } catch (e) {
        print('DEBUG: Failed to disable wakelock: $e');
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
      print('DEBUG: Video analysis error: $e');
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
        _processingStatus = 'Enhancing audio quality...';
        _processingProgress = 0.0;
      });

      print('DEBUG: Starting audio processing for moment video');

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

      print('DEBUG: Audio processing command: ffmpeg $audioCommand');

      setState(() {
        _processingStatus = 'Processing audio enhancement...';
        _processingProgress = 0.3;
      });

      final videoDurationMs = info.duration.inMilliseconds;
      final Completer<void> processingCompleter = Completer<void>();
      
      FFmpegKit.executeAsync(
        audioCommand,
        (session) async {
          print('DEBUG: Audio processing completed for moment');
          final returnCode = await session.getReturnCode();
          
          if (mounted) {
            setState(() {
              _isProcessing = false;
              _processingProgress = 1.0;
              _processingStatus = ReturnCode.isSuccess(returnCode) 
                  ? 'Audio enhanced successfully!'
                  : 'Audio processing failed';
            });
          }
          
          if (!processingCompleter.isCompleted) {
            processingCompleter.complete();
          }
        },
        (log) {
          // Optional logging
        },
        (statistics) {
          if (mounted && _isProcessing && statistics.getTime() > 0 && videoDurationMs > 0) {
            final baseProgress = 0.3;
            final encodingProgress = (statistics.getTime() / videoDurationMs).clamp(0.0, 1.0);
            final totalProgress = baseProgress + (encodingProgress * 0.7);
            
            setState(() {
              _processingProgress = totalProgress.clamp(0.0, 1.0);
            });
            print('DEBUG: Audio processing progress: ${(totalProgress * 100).toStringAsFixed(1)}%');
          }
        },
      );
      
      await processingCompleter.future;
      
      final outputFile = File(outputPath);
      if (await outputFile.exists()) {
        final originalSizeMB = info.fileSizeMB;
        final newSizeMB = await outputFile.length() / (1024 * 1024);
        
        print('DEBUG: Audio processing successful for moment!');
        print('DEBUG: Original: ${originalSizeMB.toStringAsFixed(1)}MB → New: ${newSizeMB.toStringAsFixed(1)}MB');
        
        // Hide processing status after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _processingStatus = '';
              _processingProgress = 0.0;
            });
          }
        });
        
        return outputFile;
      }
      
      print('DEBUG: Audio processing failed - output file not found');
      await _disableWakelock();
      return null;
      
    } catch (e) {
      print('DEBUG: Audio processing error: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingProgress = 0.0;
          _processingStatus = 'Audio processing failed';
        });
        
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _processingStatus = '';
            });
          }
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
                  ? const Text('Processing...')
                  : (_isUploading
                      ? const Text('Sharing...')
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content type selector
                  _buildTypeSelector(),
                  const SizedBox(height: 24),

                  // Duration tip for videos
                  if (_selectedType == MomentType.video)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: context.modernTheme.primaryColor!.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.modernTheme.primaryColor!.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: context.modernTheme.primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Max 1 minute • Audio will be enhanced automatically',
                              style: TextStyle(
                                color: context.modernTheme.textSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Media content area
                  _buildMediaContent(),
                  const SizedBox(height: 24),

                  // Processing progress indicator
                  if (_isProcessing)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.modernTheme.primaryColor!.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.modernTheme.primaryColor!.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.audiotrack,
                                    color: context.modernTheme.primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _processingStatus.isEmpty 
                                          ? 'Processing audio...'
                                          : _processingStatus,
                                      style: TextStyle(
                                        color: context.modernTheme.textColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: _processingProgress,
                                backgroundColor: context.modernTheme.borderColor,
                                valueColor: AlwaysStoppedAnimation<Color>(context.modernTheme.primaryColor!),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(_processingProgress * 100).toStringAsFixed(0)}% complete',
                                style: TextStyle(
                                  color: context.modernTheme.textSecondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  // Upload progress indicator
                  if (_isUploading)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.modernTheme.primaryColor!.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.modernTheme.primaryColor!.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.cloud_upload,
                                    color: context.modernTheme.primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Uploading moment...',
                                      style: TextStyle(
                                        color: context.modernTheme.textColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: _uploadProgress,
                                backgroundColor: context.modernTheme.borderColor,
                                valueColor: AlwaysStoppedAnimation<Color>(context.modernTheme.primaryColor!),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(_uploadProgress * 100).toStringAsFixed(0)}% uploaded',
                                style: TextStyle(
                                  color: context.modernTheme.textSecondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  // Caption input
                  _buildCaptionInput(),
                  const SizedBox(height: 24),

                  // Privacy settings
                  _buildPrivacySettings(),
                ],
              ),
            ),
          ),

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content Type',
          style: TextStyle(
            color: context.modernTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TypeOption(
                icon: Icons.photo_library,
                label: 'Photos',
                isSelected: _selectedType == MomentType.images,
                onTap: () => setState(() => _selectedType = MomentType.images),
                enabled: !_isProcessing && !_isUploading,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TypeOption(
                icon: Icons.videocam,
                label: 'Video',
                isSelected: _selectedType == MomentType.video,
                onTap: () => setState(() => _selectedType = MomentType.video),
                enabled: !_isProcessing && !_isUploading,
              ),
            ),
          ],
        ),
      ],
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
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: context.modernTheme.surfaceVariantColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.modernTheme.borderColor!,
          width: 1,
        ),
      ),
      child: _videoFile == null
          ? _buildMediaPlaceholder(
              icon: Icons.videocam,
              title: 'Add Video',
              subtitle: 'Tap to select a video (max 1 minute)',
              onTap: _selectVideo,
            )
          : _buildVideoPreview(),
    );
  }

  Widget _buildImageContent() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        color: context.modernTheme.surfaceVariantColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.modernTheme.borderColor!,
          width: 1,
        ),
      ),
      child: _imageFiles.isEmpty
          ? _buildMediaPlaceholder(
              icon: Icons.photo_library,
              title: 'Add Photos',
              subtitle: 'Tap to select photos (max 9)',
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: isEnabled 
                  ? context.modernTheme.textSecondaryColor
                  : context.modernTheme.textSecondaryColor!.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: isEnabled 
                    ? context.modernTheme.textColor
                    : context.modernTheme.textColor!.withOpacity(0.5),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: isEnabled 
                    ? context.modernTheme.textSecondaryColor
                    : context.modernTheme.textSecondaryColor!.withOpacity(0.5),
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
      children: [
        if (_videoController != null && _videoController!.value.isInitialized)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          )
        else
          const Center(
            child: CircularProgressIndicator(),
          ),

        // Controls overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ),

        // Remove button
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: (!_isProcessing && !_isUploading) ? _removeVideo : null,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: (!_isProcessing && !_isUploading) ? Colors.white : Colors.grey,
                size: 20,
              ),
            ),
          ),
        ),

        // Play/pause button
        Positioned.fill(
          child: Center(
            child: GestureDetector(
              onTap: (!_isProcessing && !_isUploading) ? _toggleVideoPlayback : null,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _videoController?.value.isPlaying == true
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: (!_isProcessing && !_isUploading) ? Colors.white : Colors.grey,
                  size: 32,
                ),
              ),
            ),
          ),
        ),

        // Video info overlay (shows processing will be applied)
        if (_videoInfo != null)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_videoInfo!.duration.inSeconds}s • Audio will be enhanced',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
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
            color: context.modernTheme.borderColor!,
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.add,
          color: isEnabled 
              ? context.modernTheme.textSecondaryColor
              : context.modernTheme.textSecondaryColor!.withOpacity(0.5),
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
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: (!_isProcessing && !_isUploading) ? Colors.white : Colors.grey,
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
        Text(
          'Caption',
          style: TextStyle(
            color: context.modernTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _captionController,
          maxLines: 3,
          maxLength: 500,
          enabled: !_isProcessing && !_isUploading,
          decoration: InputDecoration(
            hintText: 'Write a caption...',
            hintStyle: TextStyle(color: context.modernTheme.textSecondaryColor),
            filled: true,
            fillColor: context.modernTheme.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.modernTheme.borderColor!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.modernTheme.primaryColor!),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.modernTheme.borderColor!.withOpacity(0.5)),
            ),
          ),
          style: TextStyle(
            color: (_isProcessing || _isUploading) 
                ? context.modernTheme.textColor!.withOpacity(0.5)
                : context.modernTheme.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy',
          style: TextStyle(
            color: context.modernTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
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
    );
  }

  Widget _buildActionButtons() {
    final isProcessingOrUploading = _isProcessing || _isUploading;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.modernTheme.surfaceColor,
        border: Border(
          top: BorderSide(
            color: context.modernTheme.borderColor!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: !isProcessingOrUploading 
                  ? (_selectedType == MomentType.video ? _selectVideo : _selectImages)
                  : null,
              icon: Icon(_selectedType == MomentType.video ? Icons.videocam : Icons.photo_library),
              label: Text(_selectedType == MomentType.video ? 'Select Video' : 'Select Photos'),
              style: OutlinedButton.styleFrom(
                foregroundColor: !isProcessingOrUploading 
                    ? context.modernTheme.textColor 
                    : context.modernTheme.textColor!.withOpacity(0.5),
                side: BorderSide(
                  color: !isProcessingOrUploading 
                      ? context.modernTheme.borderColor! 
                      : context.modernTheme.borderColor!.withOpacity(0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (_hasContent()) ...[
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: !isProcessingOrUploading ? _createMoment : null,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : (_isUploading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send)),
                label: Text(_isProcessing 
                    ? 'Processing...' 
                    : (_isUploading ? 'Sharing...' : 'Share Moment')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: !isProcessingOrUploading 
                      ? context.modernTheme.primaryColor 
                      : context.modernTheme.primaryColor!.withOpacity(0.5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _hasContent() {
    return (_selectedType == MomentType.video && _videoFile != null) ||
           (_selectedType == MomentType.images && _imageFiles.isNotEmpty) ||
           _captionController.text.trim().isNotEmpty;
  }

  Future<void> _selectVideo() async {
    if (_isProcessing || _isUploading) return;
    
    try {
      print('DEBUG: Starting video selection for moment...');
      
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 1),
      );

      if (video != null) {
        print('DEBUG: Video selected for moment: ${video.path}');
        final videoFile = File(video.path);
        
        if (await videoFile.exists()) {
          // Analyze video immediately for info display
          final videoInfo = await _analyzeVideo(videoFile);
          print('DEBUG: Moment video analysis - ${videoInfo.toString()}');
          
          setState(() {
            _videoFile = videoFile;
            _videoInfo = videoInfo;
            _selectedType = MomentType.video;
            _imageFiles.clear(); // Clear images when selecting video
          });
          
          _initializeVideoController();
          print('DEBUG: Moment video set successfully');
        } else {
          showSnackBar(context, 'Selected video file not found');
        }
      }
    } catch (e) {
      print('DEBUG: Video selection error: $e');
      showSnackBar(context, 'Failed to select video: ${e.toString()}');
    }
  }

  Future<void> _selectImages() async {
    if (_isProcessing || _isUploading) return;
    
    try {
      print('DEBUG: Starting image selection for moment...');
      
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
        
        print('DEBUG: ${images.length} images selected for moment');
      }
    } catch (e) {
      print('DEBUG: Image selection error: $e');
      showSnackBar(context, 'Failed to select images: ${e.toString()}');
    }
  }

  void _initializeVideoController() {
    if (_videoFile == null) return;

    print('DEBUG: Initializing video controller for moment');
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(_videoFile!);
    _videoController!.initialize().then((_) {
      if (mounted) {
        setState(() {});
        _videoController!.setLooping(true);
        print('DEBUG: Moment video controller initialized');
      }
    }).catchError((error) {
      print('DEBUG: Video controller initialization failed: $error');
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
    
    print('DEBUG: Removing moment video');
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
    print('DEBUG: Removed image at index $index');
  }

  Future<void> _createMoment() async {
    if (!_hasContent() || _isProcessing || _isUploading) return;

    print('DEBUG: Starting moment creation process');

    try {
      // Enable wakelock for the entire process
      await _enableWakelock();
      
      File? finalVideoFile = _videoFile;
      
      // Process video audio if we have a video
      if (_selectedType == MomentType.video && _videoFile != null && _videoInfo != null) {
        print('DEBUG: Processing video audio before upload...');
        
        final processedVideo = await _processVideoAudio(_videoFile!, _videoInfo!);
        
        if (processedVideo != null) {
          finalVideoFile = processedVideo;
          print('DEBUG: Using audio-processed video for moment upload');
        } else {
          print('DEBUG: Using original video for moment upload');
          // Continue with original video even if processing failed
        }
      }

      // Start upload process
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      print('DEBUG: Uploading moment to server...');

      // Simulate upload progress (replace with actual upload progress tracking)
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
        print('DEBUG: Moment created successfully with ID: $momentId');
        setState(() {
          _uploadProgress = 1.0;
        });
        
        // Show success message
        showSnackBar(context, 'Moment created successfully!');
        
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
      print('DEBUG: Moment creation error: $e');
      showSnackBar(context, 'Failed to create moment: ${e.toString()}');
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

  // Simulate upload progress (replace with actual progress tracking from your upload service)
  void _simulateUploadProgress() {
    const totalSteps = 20;
    int currentStep = 0;
    
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isUploading || !mounted) {
        timer.cancel();
        return;
      }
      
      currentStep++;
      final progress = (currentStep / totalSteps).clamp(0.0, 0.95); // Stop at 95%, let actual completion set to 100%
      
      setState(() {
        _uploadProgress = progress;
      });
      
      if (currentStep >= totalSteps) {
        timer.cancel();
      }
    });
  }

  void _showError(String message) {
    print('DEBUG: Showing error: $message');
    showSnackBar(context, message);
  }

  void _showSuccess(String message) {
    print('DEBUG: Showing success: $message');
    showSnackBar(context, message);
  }
}

class _TypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool enabled;

  const _TypeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? (enabled 
                  ? context.modernTheme.primaryColor?.withOpacity(0.1)
                  : context.modernTheme.primaryColor?.withOpacity(0.05))
              : (enabled 
                  ? context.modernTheme.surfaceColor
                  : context.modernTheme.surfaceColor!.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? (enabled 
                    ? context.modernTheme.primaryColor!
                    : context.modernTheme.primaryColor!.withOpacity(0.5))
                : (enabled 
                    ? context.modernTheme.borderColor!
                    : context.modernTheme.borderColor!.withOpacity(0.5)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? (enabled 
                      ? context.modernTheme.primaryColor
                      : context.modernTheme.primaryColor!.withOpacity(0.5))
                  : (enabled 
                      ? context.modernTheme.textSecondaryColor
                      : context.modernTheme.textSecondaryColor!.withOpacity(0.5)),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? (enabled 
                        ? context.modernTheme.primaryColor
                        : context.modernTheme.primaryColor!.withOpacity(0.5))
                    : (enabled 
                        ? context.modernTheme.textColor
                        : context.modernTheme.textColor!.withOpacity(0.5)),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }}
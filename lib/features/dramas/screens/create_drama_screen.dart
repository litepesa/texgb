// lib/features/dramas/screens/create_drama_screen.dart - UPLOAD-AS-YOU-ADD VERSION
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/dramas/models/drama_model.dart';
import 'package:textgb/features/dramas/providers/drama_providers.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class CreateDramaScreen extends ConsumerStatefulWidget {
  const CreateDramaScreen({super.key});

  @override
  ConsumerState<CreateDramaScreen> createState() => _CreateDramaScreenState();
}

class _CreateDramaScreenState extends ConsumerState<CreateDramaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _freeEpisodesController = TextEditingController();

  bool _isPremium = false;
  bool _isFeatured = false;
  bool _isActive = true;
  bool _isCreating = false;
  
  File? _bannerImage;
  List<EpisodeUploadItem> _episodes = [];
  bool _isAddingEpisode = false;
  
  // Upload progress tracking
  double _overallProgress = 0.0;
  String _currentUploadStatus = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isVerified = ref.read(isVerifiedProvider);
      if (!isVerified) {
        showSnackBar(context, Constants.verifiedOnly);
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _freeEpisodesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null || !currentUser.isVerified) {
      return _buildAccessDenied(modernTheme);
    }

    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: _buildAppBar(modernTheme),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressIndicator(modernTheme),
              const SizedBox(height: 16),
              _buildDramaInfoSection(modernTheme),
              const SizedBox(height: 24),
              _buildEpisodesSection(modernTheme),
              const SizedBox(height: 24),
              _buildPremiumSection(modernTheme),
              const SizedBox(height: 24),
              _buildSettingsSection(modernTheme),
              const SizedBox(height: 32),
              _buildCreateButton(modernTheme),
              if (_isCreating) ...[
                const SizedBox(height: 16),
                _buildUploadProgress(modernTheme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodesSection(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _episodes.isNotEmpty 
              ? const Color(0xFFFE2C55).withOpacity(0.3)
              : modernTheme.textSecondaryColor?.withOpacity(0.2) ?? Colors.grey,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.video_library,
                color: _episodes.isNotEmpty 
                    ? const Color(0xFFFE2C55) 
                    : modernTheme.textColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Step 2: Add Episodes (${_episodes.length}/100)',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_episodes.isNotEmpty)
                TextButton.icon(
                  onPressed: _clearAllEpisodes,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear All'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Episode list area
          if (_episodes.isEmpty)
            _buildEmptyEpisodesArea(modernTheme)
          else
            _buildEpisodesList(modernTheme),
          
          const SizedBox(height: 16),
          
          // Add episode button
          if (_episodes.length < 100)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAddingEpisode || _isCreating ? null : _addSingleEpisode,
                icon: _isAddingEpisode
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.add_circle_outline),
                label: Text(_isAddingEpisode 
                    ? 'Selecting Video...' 
                    : _episodes.isEmpty 
                        ? 'Add First Episode' 
                        : 'Add Episode ${_episodes.length + 1}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFE2C55),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            
          // Batch actions
          if (_episodes.isNotEmpty && _episodes.length < 95 && !_isCreating)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isAddingEpisode ? null : _addMultipleEpisodes,
                      icon: const Icon(Icons.playlist_add, size: 16),
                      label: const Text('Add Multiple'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFE2C55),
                        side: const BorderSide(color: Color(0xFFFE2C55)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _reorderEpisodes,
                      icon: const Icon(Icons.reorder, size: 16),
                      label: const Text('Reorder'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: modernTheme.textColor,
                        side: BorderSide(color: modernTheme.textSecondaryColor!),
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

  Widget _buildEpisodesList(ModernThemeExtension modernTheme) {
    return Column(
      children: [
        // Episodes list with upload status
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _episodes.length,
          itemBuilder: (context, index) {
            return _buildEpisodeListItem(modernTheme, index);
          },
        ),
        
        // Episode summary
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFE2C55).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFFFE2C55),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_episodes.length} episode${_episodes.length != 1 ? 's' : ''} added. '
                  'Uploaded: ${_episodes.where((e) => e.isUploaded).length}, '
                  'Uploading: ${_episodes.where((e) => e.isUploading).length}, '
                  'Failed: ${_episodes.where((e) => e.uploadError != null).length}',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEpisodeListItem(ModernThemeExtension modernTheme, int index) {
    final episode = _episodes[index];
    final fileName = episode.file.path.split('/').last;
    final fileSize = episode.fileSizeInMB;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (episode.uploadError != null) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = 'Failed';
    } else if (episode.isUploaded) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Uploaded';
    } else if (episode.isUploading) {
      statusColor = const Color(0xFFFE2C55);
      statusIcon = Icons.cloud_upload;
      statusText = 'Uploading...';
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
      statusText = 'Ready to upload';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: modernTheme.surfaceVariantColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFE2C55),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          fileName.length > 25 ? '${fileName.substring(0, 22)}...' : fileName,
          style: TextStyle(
            color: modernTheme.textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${fileSize.toStringAsFixed(1)} MB • $statusText',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
            if (episode.isUploading && episode.uploadProgress != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: LinearProgressIndicator(
                  value: episode.uploadProgress! / 100,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            if (episode.uploadError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Error: ${episode.uploadError}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: 8),
            if (episode.uploadError != null)
              // Retry button for failed uploads
              IconButton(
                onPressed: () => _retryEpisodeUpload(index),
                icon: const Icon(Icons.refresh, color: Colors.blue, size: 20),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                tooltip: 'Retry upload',
              )
            else if (!_isCreating && !episode.isUploading)
              // Delete button (only when not creating drama and not uploading)
              IconButton(
                onPressed: () => _removeEpisode(index),
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadProgress(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFE2C55).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFE2C55).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_upload, color: Color(0xFFFE2C55), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentUploadStatus.isNotEmpty 
                      ? _currentUploadStatus
                      : 'Creating Drama with ${_episodes.length} Episodes...',
                  style: const TextStyle(
                    color: Color(0xFFFE2C55),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${(_overallProgress * 100).toInt()}%',
                style: const TextStyle(
                  color: Color(0xFFFE2C55),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _overallProgress,
            backgroundColor: Colors.grey.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFE2C55)),
          ),
          const SizedBox(height: 8),
          Text(
            'Please keep this screen open during creation.',
            style: TextStyle(
              fontSize: 12, 
              color: modernTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // UPLOAD-AS-YOU-ADD EPISODE MANAGEMENT
  // ===============================
  
  Future<void> _addSingleEpisode() async {
    if (_episodes.length >= 100) {
      showSnackBar(context, 'Maximum 100 episodes allowed');
      return;
    }

    setState(() => _isAddingEpisode = true);

    try {
      final picker = ImagePicker();
      
      // Show loading message
      showSnackBar(context, 'Opening video gallery...');

      final pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 120), // 2 hour max
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        
        // Check if file exists
        if (!await file.exists()) {
          showSnackBar(context, 'Selected video file does not exist');
          return;
        }

        // Check file size (1GB limit)
        final fileSizeInBytes = await file.length();
        final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
        
        if (fileSizeInMB > 1000) {
          showSnackBar(context, 'Video file is too large (max 1GB, current: ${fileSizeInMB.toStringAsFixed(1)}MB)');
          return;
        }

        // Add to episodes list as "pending upload"
        final episodeItem = EpisodeUploadItem(
          file: file,
          fileSizeInMB: fileSizeInMB,
        );

        setState(() {
          _episodes.add(episodeItem);
        });
        
        final fileName = pickedFile.path.split('/').last;
        showSnackBar(context, 'Episode ${_episodes.length} selected: $fileName (${fileSizeInMB.toStringAsFixed(1)}MB)');

        // IMMEDIATELY UPLOAD the episode (like add_episode_screen does)
        await _uploadSingleEpisode(_episodes.length - 1);

        // Auto-update free episodes if premium
        if (_isPremium && _freeEpisodesController.text.isEmpty) {
          final suggested = (_episodes.length * 0.3).ceil().clamp(1, 5);
          _freeEpisodesController.text = suggested.toString();
        }
      } else {
        showSnackBar(context, 'No video selected');
      }
    } catch (e) {
      showSnackBar(context, 'Error selecting video: $e');
    } finally {
      setState(() => _isAddingEpisode = false);
    }
  }

  // Upload a single episode immediately (like add_episode_screen does)
  Future<void> _uploadSingleEpisode(int index) async {
    if (index >= _episodes.length) return;

    try {
      // Mark as uploading
      setState(() {
        _episodes[index] = _episodes[index].copyWith(
          isUploading: true,
          uploadProgress: 0,
        );
      });

      final repository = ref.read(dramaRepositoryProvider);
      
      // Simulate upload progress (like add_episode_screen)
      for (double progress = 10; progress <= 95; progress += 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          setState(() {
            _episodes[index] = _episodes[index].copyWith(uploadProgress: progress);
          });
        }
      }

      // Actually upload the video
      final videoUrl = await repository.uploadVideo(
        _episodes[index].file, 
        'episode_${index + 1}',
      );

      // Mark as uploaded successfully
      setState(() {
        _episodes[index] = _episodes[index].copyWith(
          isUploading: false,
          isUploaded: true,
          videoUrl: videoUrl,
          uploadProgress: 100,
        );
      });

      showSnackBar(context, '✓ Episode ${index + 1} uploaded successfully!');

    } catch (e) {
      // Mark as failed
      setState(() {
        _episodes[index] = _episodes[index].copyWith(
          isUploading: false,
          uploadError: e.toString(),
        );
      });
      
      showSnackBar(context, '✗ Episode ${index + 1} upload failed: $e');
    }
  }

  // Retry failed upload
  Future<void> _retryEpisodeUpload(int index) async {
    if (index >= _episodes.length) return;
    
    // Clear error and retry
    setState(() {
      _episodes[index] = _episodes[index].copyWith(uploadError: null);
    });
    
    await _uploadSingleEpisode(index);
  }

  Future<void> _addMultipleEpisodes() async {
    if (_episodes.length >= 100) {
      showSnackBar(context, 'Maximum 100 episodes allowed');
      return;
    }

    setState(() => _isAddingEpisode = true);

    try {
      final picker = ImagePicker();
      showSnackBar(context, 'Opening gallery...');

      final remainingSlots = 100 - _episodes.length;
      
      // Use pickMultipleMedia for multiple video selection
      final List<XFile> pickedFiles = await picker.pickMultipleMedia(
        limit: remainingSlots.clamp(1, 20), // Limit to prevent too many at once
      );

      if (pickedFiles.isEmpty) {
        showSnackBar(context, 'No files selected');
        return;
      }

      final List<File> validVideos = [];
      final List<String> skippedFiles = [];
      
      showSnackBar(context, 'Processing ${pickedFiles.length} selected files...');
      
      for (final file in pickedFiles) {
        try {
          // Check if it's a video file using simple extension check
          if (!_isVideoFile(file)) {
            skippedFiles.add('${_getFileName(file.path)} (not a video file)');
            continue;
          }
          
          final videoFile = File(file.path);
          
          // Verify file exists and is accessible
          if (!await videoFile.exists()) {
            skippedFiles.add('${_getFileName(file.path)} (file not accessible)');
            continue;
          }
          
          final fileSizeInBytes = await videoFile.length();
          final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
          
          if (fileSizeInMB <= 1000) { // 1GB limit
            validVideos.add(videoFile);
          } else {
            skippedFiles.add('${_getFileName(file.path)} (${fileSizeInMB.toStringAsFixed(1)}MB - too large)');
          }
          
        } catch (e) {
          skippedFiles.add('${_getFileName(file.path)} (error processing file)');
        }
      }

      if (validVideos.isNotEmpty) {
        // Add all valid videos to the list first
        final startingIndex = _episodes.length;
        for (int i = 0; i < validVideos.length; i++) {
          final file = validVideos[i];
          final fileSizeInBytes = await file.length();
          final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
          
          setState(() {
            _episodes.add(EpisodeUploadItem(
              file: file,
              fileSizeInMB: fileSizeInMB,
            ));
          });
        }
        
        String message = 'Added ${validVideos.length} episodes, starting uploads...';
        if (skippedFiles.isNotEmpty) {
          message += ' (${skippedFiles.length} files skipped)';
        }
        showSnackBar(context, message);
        
        // Upload each video one by one
        for (int i = 0; i < validVideos.length; i++) {
          await _uploadSingleEpisode(startingIndex + i);
        }

        // Auto-update free episodes if premium
        if (_isPremium && _freeEpisodesController.text.isEmpty) {
          final suggested = (_episodes.length * 0.3).ceil().clamp(1, 5);
          _freeEpisodesController.text = suggested.toString();
        }
        
        // Show details of skipped files if not too many
        if (skippedFiles.isNotEmpty && skippedFiles.length <= 5) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              showSnackBar(context, 'Skipped: ${skippedFiles.join(', ')}');
            }
          });
        }
      } else {
        String message = 'No valid video files found';
        if (skippedFiles.isNotEmpty) {
          message += '. ${skippedFiles.length} files were incompatible';
        }
        showSnackBar(context, '$message\n\nSupported: MP4, MOV, AVI, TS, WEBM, MKV (max 1GB each)');
      }
    } catch (e) {
      showSnackBar(context, 'Error selecting videos: $e');
    } finally {
      setState(() => _isAddingEpisode = false);
    }
  }

  // Simple video file detection (simplified from add_episode_screen approach)
  bool _isVideoFile(XFile file) {
    final fileName = file.path.toLowerCase();
    final mimeType = file.mimeType?.toLowerCase() ?? '';
    
    // Check by file extension (most reliable)
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.ts', '.webm', '.m4v', '.3gp'];
    final hasVideoExtension = videoExtensions.any((ext) => fileName.endsWith(ext));
    
    // Check by MIME type as backup
    final hasVideoMimeType = mimeType.startsWith('video/');
    
    return hasVideoExtension || hasVideoMimeType;
  }

  // Helper method to get filename from path
  String _getFileName(String path) {
    return path.split('/').last;
  }

  void _removeEpisode(int index) {
    setState(() {
      _episodes.removeAt(index);
      // Update free episodes count if needed
      if (_isPremium) {
        final currentFree = int.tryParse(_freeEpisodesController.text) ?? 0;
        if (currentFree > _episodes.length) {
          _freeEpisodesController.text = _episodes.length.toString();
        }
      }
    });
    showSnackBar(context, 'Episode removed. Episodes renumbered automatically.');
  }

  void _clearAllEpisodes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Episodes'),
        content: Text('Are you sure you want to remove all ${_episodes.length} episodes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _episodes.clear();
                _freeEpisodesController.clear();
              });
              Navigator.pop(context);
              showSnackBar(context, 'All episodes cleared');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _reorderEpisodes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reorder Episodes'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ReorderableListView.builder(
            itemCount: _episodes.length,
            onReorder: (oldIndex, newIndex) {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              setState(() {
                final item = _episodes.removeAt(oldIndex);
                _episodes.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final fileName = _episodes[index].file.path.split('/').last;
              return ListTile(
                key: Key('$index'),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFE2C55),
                  child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                ),
                title: Text(fileName.length > 30 ? '${fileName.substring(0, 27)}...' : fileName),
                trailing: const Icon(Icons.drag_handle),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickBannerImage() async {
    try {
      final picker = ImagePicker();
      showSnackBar(context, 'Opening image gallery...');
      
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        
        // Check if file exists
        if (!await imageFile.exists()) {
          showSnackBar(context, 'Selected image file does not exist');
          return;
        }
        
        final fileSizeInBytes = await imageFile.length();
        final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
        
        if (fileSizeInMB <= 10) {
          setState(() {
            _bannerImage = imageFile;
          });
          showSnackBar(context, 'Banner image added successfully!');
        } else {
          showSnackBar(context, 'Image too large! Maximum size is 10MB (current: ${fileSizeInMB.toStringAsFixed(1)}MB)');
        }
      } else {
        showSnackBar(context, 'No image selected');
      }
    } catch (e) {
      showSnackBar(context, 'Error selecting image: $e');
    }
  }

  // ===============================
  // SIMPLIFIED DRAMA CREATION (episodes already uploaded)
  // ===============================
  
  Future<void> _createDrama() async {
    if (!_formKey.currentState!.validate()) return;
    if (_episodes.isEmpty) {
      showSnackBar(context, 'Please add at least one episode');
      return;
    }

    // Check if all episodes are uploaded
    final uploadedEpisodes = _episodes.where((e) => e.isUploaded).length;
    final failedEpisodes = _episodes.where((e) => e.uploadError != null).length;
    final uploadingEpisodes = _episodes.where((e) => e.isUploading).length;

    if (uploadingEpisodes > 0) {
      showSnackBar(context, 'Please wait for all episodes to finish uploading');
      return;
    }

    if (failedEpisodes > 0) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Some Episodes Failed'),
          content: Text('$failedEpisodes episode(s) failed to upload. Do you want to create the drama with only the successfully uploaded episodes ($uploadedEpisodes episodes)?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFE2C55)),
              child: const Text('Create Drama'),
            ),
          ],
        ),
      ) ?? false;

      if (!shouldContinue) return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || !currentUser.isVerified) {
      showSnackBar(context, Constants.verifiedOnly);
      return;
    }

    // Final confirmation dialog
    final confirmed = await _showCreateConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      _isCreating = true;
      _overallProgress = 0.1;
      _currentUploadStatus = 'Creating drama record...';
    });

    try {
      final repository = ref.read(dramaRepositoryProvider);
      
      // Step 1: Upload banner image if needed (10% - 20%)
      String bannerUrl = '';
      if (_bannerImage != null) {
        setState(() {
          _overallProgress = 0.15;
          _currentUploadStatus = 'Uploading banner image...';
        });
        
        bannerUrl = await repository.uploadBannerImage(_bannerImage!, '');
        
        setState(() => _overallProgress = 0.2);
      }

      // Step 2: Collect all uploaded video URLs (20% - 80%)
      setState(() {
        _overallProgress = 0.5;
        _currentUploadStatus = 'Preparing episode list...';
      });

      final episodeUrls = _episodes
          .where((e) => e.isUploaded && e.videoUrl != null)
          .map((e) => e.videoUrl!)
          .toList();

      if (episodeUrls.isEmpty) {
        throw Exception('No successfully uploaded episodes found');
      }

      // Step 3: Create drama record (80% - 100%)
      setState(() {
        _overallProgress = 0.8;
        _currentUploadStatus = 'Creating drama with ${episodeUrls.length} episodes...';
      });

      final drama = DramaModel.create(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        createdBy: currentUser.uid,
        episodeVideos: episodeUrls,
        bannerImage: bannerUrl,
        isPremium: _isPremium,
        freeEpisodesCount: _isPremium 
            ? int.tryParse(_freeEpisodesController.text.trim()) ?? 0 
            : 0,
        isFeatured: _isFeatured,
        isActive: _isActive,
      );

      final dramaId = await repository.createDramaWithEpisodes(drama);

      setState(() {
        _overallProgress = 1.0;
        _currentUploadStatus = 'Drama created successfully!';
      });

      if (mounted) {
        // Refresh providers
        ref.invalidate(adminDramasProvider);
        ref.invalidate(allDramasProvider);
        if (_isFeatured) ref.invalidate(featuredDramasProvider);
        
        await Future.delayed(const Duration(milliseconds: 1000));
        
        showSnackBar(context, 'Drama "${_titleController.text.trim()}" created with ${episodeUrls.length} episodes!');
        Navigator.of(context).pop();
        
        // Navigate to the drama details
        Navigator.pushNamed(
          context,
          Constants.dramaDetailsScreen,
          arguments: {'dramaId': dramaId},
        );
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _currentUploadStatus = 'Creation failed: $e';
        });
        showSnackBar(context, 'Failed to create drama: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
          _overallProgress = 0.0;
        });
      }
    }
  }

  // ===============================
  // UI COMPONENTS
  // ===============================

  Widget _buildProgressIndicator(ModernThemeExtension modernTheme) {
    final hasBasicInfo = _titleController.text.isNotEmpty && 
                        _descriptionController.text.isNotEmpty;
    final hasEpisodes = _episodes.isNotEmpty;
    final hasSettings = true;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildStepIndicator(1, 'Info', hasBasicInfo, modernTheme),
          Expanded(child: _buildConnector(hasBasicInfo, modernTheme)),
          _buildStepIndicator(2, 'Episodes', hasEpisodes, modernTheme),
          Expanded(child: _buildConnector(hasEpisodes, modernTheme)),
          _buildStepIndicator(3, 'Settings', hasSettings, modernTheme),
          Expanded(child: _buildConnector(hasSettings, modernTheme)),
          _buildStepIndicator(4, 'Publish', false, modernTheme),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isComplete, ModernThemeExtension modernTheme) {
    final color = isComplete ? const Color(0xFFFE2C55) : modernTheme.textSecondaryColor!;
    
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isComplete ? const Color(0xFFFE2C55) : Colors.transparent,
            border: Border.all(color: color),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isComplete
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(bool isActive, ModernThemeExtension modernTheme) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isActive 
            ? const Color(0xFFFE2C55)
            : modernTheme.textSecondaryColor?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  AppBar _buildAppBar(ModernThemeExtension modernTheme) {
    return AppBar(
      backgroundColor: modernTheme.surfaceColor,
      elevation: 0,
      title: Text(
        'Create New Drama',
        style: TextStyle(
          color: modernTheme.textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: modernTheme.textColor),
        onPressed: _isCreating ? null : () => Navigator.pop(context),
      ),
      actions: [
        if (_isCreating)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: _overallProgress,
                color: const Color(0xFFFE2C55),
                strokeWidth: 2,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDramaInfoSection(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tv, color: modernTheme.textColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Step 1: Drama Information',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Banner image
          _buildBannerImagePicker(modernTheme),
          
          const SizedBox(height: 20),
          
          // Title field
          TextFormField(
            controller: _titleController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Drama Title',
              hintText: 'Enter an engaging drama title',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: modernTheme.surfaceVariantColor,
            ),
            style: TextStyle(color: modernTheme.textColor),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a drama title';
              }
              if (value.trim().length < 3) {
                return 'Title must be at least 3 characters';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Description field
          TextFormField(
            controller: _descriptionController,
            onChanged: (_) => setState(() {}),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Describe what your drama is about...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: modernTheme.surfaceVariantColor,
            ),
            style: TextStyle(color: modernTheme.textColor),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a description';
              }
              if (value.trim().length < 10) {
                return 'Description must be at least 10 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBannerImagePicker(ModernThemeExtension modernTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Banner Image',
          style: TextStyle(
            color: modernTheme.textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isCreating ? null : _pickBannerImage,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: modernTheme.surfaceVariantColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _bannerImage != null 
                    ? const Color(0xFFFE2C55)
                    : modernTheme.textSecondaryColor?.withOpacity(0.3) ?? Colors.grey,
                width: 2,
              ),
            ),
            child: _bannerImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_bannerImage!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 32,
                        color: modernTheme.textSecondaryColor,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to add banner',
                        style: TextStyle(
                          color: modernTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyEpisodesArea(ModernThemeExtension modernTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: modernTheme.surfaceVariantColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: modernTheme.textSecondaryColor?.withOpacity(0.2) ?? Colors.grey,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.video_call,
            size: 48,
            color: modernTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Ready to Add Episodes',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add video files one by one to build your drama series\nSupported formats: MP4, MOV, AVI, TS, WEBM\nEpisodes will be uploaded sequentially when you publish',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSection(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isPremium 
              ? const Color(0xFFFFD700).withOpacity(0.3)
              : modernTheme.textSecondaryColor?.withOpacity(0.1) ?? Colors.grey,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium,
                color: _isPremium ? const Color(0xFFFFD700) : modernTheme.textSecondaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Step 3: Monetization Settings',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isPremium 
                  ? const Color(0xFFFFD700).withOpacity(0.1)
                  : modernTheme.surfaceVariantColor,
              borderRadius: BorderRadius.circular(8),
              border: _isPremium 
                  ? Border.all(color: const Color(0xFFFFD700).withOpacity(0.3))
                  : null,
            ),
            child: SwitchListTile(
              title: Text('Premium Drama', style: TextStyle(color: modernTheme.textColor)),
              subtitle: Text(
                'Users pay coins to unlock episodes beyond the free ones',
                style: TextStyle(color: modernTheme.textSecondaryColor),
              ),
              value: _isPremium,
              onChanged: _isCreating ? null : (value) {
                setState(() {
                  _isPremium = value;
                  if (value && _episodes.isNotEmpty && _freeEpisodesController.text.isEmpty) {
                    final suggested = (_episodes.length * 0.3).ceil().clamp(1, 5);
                    _freeEpisodesController.text = suggested.toString();
                  }
                });
              },
              activeColor: const Color(0xFFFFD700),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          
          if (_isPremium && _episodes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _freeEpisodesController,
                    enabled: !_isCreating,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Free Episodes',
                      hintText: '1-${_episodes.length}',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: modernTheme.surfaceVariantColor,
                      isDense: true,
                    ),
                    style: TextStyle(color: modernTheme.textColor),
                    validator: (value) {
                      if (_isPremium) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final number = int.tryParse(value.trim());
                        if (number == null || number < 0 || number > _episodes.length) {
                          return '1-${_episodes.length}';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: Color(0xFFFFD700),
                          size: 18,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${Constants.dramaUnlockCost}',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'coins/unlock',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsSection(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: modernTheme.textSecondaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Publication Settings',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isFeatured 
                  ? const Color(0xFFFE2C55).withOpacity(0.1)
                  : modernTheme.surfaceVariantColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SwitchListTile(
              title: Text('Featured Drama', style: TextStyle(color: modernTheme.textColor)),
              subtitle: Text(
                'Show prominently on home page',
                style: TextStyle(color: modernTheme.textSecondaryColor),
              ),
              value: _isFeatured,
              onChanged: _isCreating ? null : (value) => setState(() => _isFeatured = value),
              activeColor: const Color(0xFFFE2C55),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isActive 
                  ? Colors.green.shade50
                  : modernTheme.surfaceVariantColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SwitchListTile(
              title: Text('Publish Immediately', style: TextStyle(color: modernTheme.textColor)),
              subtitle: Text(
                'Make drama visible to users right away',
                style: TextStyle(color: modernTheme.textSecondaryColor),
              ),
              value: _isActive,
              onChanged: _isCreating ? null : (value) => setState(() => _isActive = value),
              activeColor: Colors.green.shade400,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton(ModernThemeExtension modernTheme) {
    final canCreate = _episodes.isNotEmpty && 
                     _titleController.text.trim().isNotEmpty && 
                     _descriptionController.text.trim().isNotEmpty;
                     
    final uploadedCount = _episodes.where((e) => e.isUploaded).length;
    final uploadingCount = _episodes.where((e) => e.isUploading).length;
    final failedCount = _episodes.where((e) => e.uploadError != null).length;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (_isCreating || !canCreate) ? null : _createDrama,
        icon: _isCreating
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.publish),
        label: Text(
          _isCreating
              ? 'Creating Drama...'
              : uploadingCount > 0
                  ? 'Creating Drama (${uploadingCount} uploading...)'
                  : failedCount > 0
                      ? 'Create Drama (${uploadedCount} episodes, ${failedCount} failed)'
                      : 'Create Drama (${uploadedCount} episodes ready)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canCreate && !_isCreating ? const Color(0xFFFE2C55) : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<bool> _showCreateConfirmationDialog() async {
    final uploadedCount = _episodes.where((e) => e.isUploaded).length;
    final failedCount = _episodes.where((e) => e.uploadError != null).length;
    final uploadingCount = _episodes.where((e) => e.isUploading).length;
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Drama'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${_titleController.text.trim()}'),
            const SizedBox(height: 8),
            Text('Episodes Ready: $uploadedCount'),
            if (uploadingCount > 0) Text('Still Uploading: $uploadingCount'),
            if (failedCount > 0) Text('Failed Uploads: $failedCount'),
            if (_isPremium) ...[
              const SizedBox(height: 8),
              Text('Free Episodes: ${_freeEpisodesController.text}'),
              Text('Premium Episodes: ${uploadedCount - (int.tryParse(_freeEpisodesController.text) ?? 0)}'),
            ],
            const SizedBox(height: 8),
            Text('Featured: ${_isFeatured ? "Yes" : "No"}'),
            Text('Publish Immediately: ${_isActive ? "Yes" : "No"}'),
            if (failedCount > 0) ...[
              const SizedBox(height: 16),
              const Text(
                'Note: Only successfully uploaded episodes will be included in the drama.',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: uploadingCount > 0 ? null : () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFE2C55)),
            child: Text(uploadingCount > 0 ? 'Wait for uploads...' : 'Create Drama'),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildAccessDenied(ModernThemeExtension modernTheme) {
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings_outlined,
              size: 64,
              color: modernTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Admin Access Required',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFE2C55)),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================
// EPISODE UPLOAD ITEM CLASS
// ===============================

class EpisodeUploadItem {
  final File file;
  final double fileSizeInMB;
  final bool isUploaded;
  final bool isUploading;
  final double? uploadProgress;
  final String? videoUrl;
  final String? uploadError;

  const EpisodeUploadItem({
    required this.file,
    required this.fileSizeInMB,
    this.isUploaded = false,
    this.isUploading = false,
    this.uploadProgress,
    this.videoUrl,
    this.uploadError,
  });

  EpisodeUploadItem copyWith({
    File? file,
    double? fileSizeInMB,
    bool? isUploaded,
    bool? isUploading,
    double? uploadProgress,
    String? videoUrl,
    String? uploadError,
  }) {
    return EpisodeUploadItem(
      file: file ?? this.file,
      fileSizeInMB: fileSizeInMB ?? this.fileSizeInMB,
      isUploaded: isUploaded ?? this.isUploaded,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      videoUrl: videoUrl ?? this.videoUrl,
      uploadError: uploadError ?? this.uploadError,
    );
  }
}
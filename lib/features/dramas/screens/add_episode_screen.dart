// lib/features/dramas/screens/add_episode_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/dramas/providers/drama_providers.dart';
import 'package:textgb/models/drama_model.dart';
import 'package:textgb/models/episode_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class AddEpisodeScreen extends ConsumerStatefulWidget {
  final String dramaId;

  const AddEpisodeScreen({
    super.key,
    required this.dramaId,
  });

  @override
  ConsumerState<AddEpisodeScreen> createState() => _AddEpisodeScreenState();
}

class _AddEpisodeScreenState extends ConsumerState<AddEpisodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _episodeTitleController = TextEditingController();
  final _episodeNumberController = TextEditingController();
  final _videoDurationController = TextEditingController();

  File? _thumbnailImage;
  File? _videoFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    // Check admin access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isAdmin = ref.read(isAdminProvider);
      if (!isAdmin) {
        showSnackBar(context, Constants.adminOnly);
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _episodeTitleController.dispose();
    _episodeNumberController.dispose();
    _videoDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final currentUser = ref.watch(currentUserProvider);
    final dramaAsync = ref.watch(dramaProvider(widget.dramaId));
    final episodesAsync = ref.watch(dramaEpisodesProvider(widget.dramaId));

    if (currentUser == null || !currentUser.isAdmin) {
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFE2C55),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return dramaAsync.when(
      data: (drama) {
        if (drama == null) {
          return _buildNotFound(modernTheme);
        }

        return episodesAsync.when(
          data: (episodes) {
            // Auto-set next episode number
            if (_episodeNumberController.text.isEmpty && episodes.isNotEmpty) {
              final nextEpisodeNumber = episodes.length + 1;
              _episodeNumberController.text = nextEpisodeNumber.toString();
            }

            return _buildAddEpisodeForm(modernTheme, drama, episodes);
          },
          loading: () => _buildLoading(modernTheme),
          error: (error, stack) => _buildError(modernTheme, error.toString()),
        );
      },
      loading: () => _buildLoading(modernTheme),
      error: (error, stack) => _buildError(modernTheme, error.toString()),
    );
  }

  Widget _buildAddEpisodeForm(
    ModernThemeExtension modernTheme,
    DramaModel drama,
    List<EpisodeModel> episodes,
  ) {
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: modernTheme.surfaceColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Episode',
              style: TextStyle(
                color: modernTheme.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              drama.title,
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: modernTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: _uploadProgress,
                  color: const Color(0xFFFE2C55),
                  strokeWidth: 2,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _addEpisode,
              child: const Text(
                'Add',
                style: TextStyle(
                  color: Color(0xFFFE2C55),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (episodes.isNotEmpty) _buildExistingEpisodes(modernTheme, episodes),
              const SizedBox(height: 24),
              _buildEpisodeInfoSection(modernTheme),
              const SizedBox(height: 24),
              _buildThumbnailSection(modernTheme),
              const SizedBox(height: 24),
              _buildVideoSection(modernTheme),
              const SizedBox(height: 32),
              _buildAddButton(),
              if (_isUploading) ...[
                const SizedBox(height: 16),
                _buildUploadProgress(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExistingEpisodes(
    ModernThemeExtension modernTheme,
    List<EpisodeModel> episodes,
  ) {
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
              Icon(
                Icons.video_library,
                color: modernTheme.textSecondaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Existing Episodes (${episodes.length})',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: episodes.length,
              itemBuilder: (context, index) {
                final episode = episodes[index];
                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: modernTheme.surfaceVariantColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: modernTheme.textSecondaryColor?.withOpacity(0.2) ?? Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ep ${episode.episodeNumber}',
                        style: TextStyle(
                          color: modernTheme.textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        episode.formattedDuration,
                        style: TextStyle(
                          color: modernTheme.textSecondaryColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeInfoSection(ModernThemeExtension modernTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Episode Information',
          style: TextStyle(
            color: modernTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Episode number and title row
        Row(
          children: [
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _episodeNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Episode #',
                  hintText: 'e.g. 1',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: modernTheme.surfaceColor,
                ),
                style: TextStyle(color: modernTheme.textColor),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  final number = int.tryParse(value.trim());
                  if (number == null || number <= 0) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _episodeTitleController,
                decoration: InputDecoration(
                  labelText: 'Episode Title (Optional)',
                  hintText: 'Enter episode title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: modernTheme.surfaceColor,
                ),
                style: TextStyle(color: modernTheme.textColor),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (value.trim().length > Constants.maxEpisodeTitleLength) {
                      return 'Too long (max ${Constants.maxEpisodeTitleLength})';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Video duration
        TextFormField(
          controller: _videoDurationController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Video Duration (seconds)',
            hintText: 'e.g. 300 for 5 minutes',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: modernTheme.surfaceColor,
            suffixIcon: Icon(
              Icons.timer,
              color: modernTheme.textSecondaryColor,
            ),
          ),
          style: TextStyle(color: modernTheme.textColor),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter video duration in seconds';
            }
            final duration = int.tryParse(value.trim());
            if (duration == null || duration <= 0) {
              return 'Please enter a valid duration';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildThumbnailSection(ModernThemeExtension modernTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Episode Thumbnail',
          style: TextStyle(
            color: modernTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickThumbnailImage,
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: modernTheme.surfaceVariantColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: modernTheme.textSecondaryColor?.withOpacity(0.3) ?? Colors.grey,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: _thumbnailImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _thumbnailImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 40,
                        color: modernTheme.textSecondaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add thumbnail',
                        style: TextStyle(
                          color: modernTheme.textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Recommended: 16:9 aspect ratio',
                        style: TextStyle(
                          color: modernTheme.textSecondaryColor?.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (_thumbnailImage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _pickThumbnailImage,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Change'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFE2C55),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _thumbnailImage = null),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Remove'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildVideoSection(ModernThemeExtension modernTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Episode Video',
          style: TextStyle(
            color: modernTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickVideoFile,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: modernTheme.surfaceVariantColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _videoFile != null 
                    ? Colors.green.shade400 
                    : modernTheme.textSecondaryColor?.withOpacity(0.3) ?? Colors.grey,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: _videoFile != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_file,
                        size: 40,
                        color: Colors.green.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Video Selected',
                        style: TextStyle(
                          color: modernTheme.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getFileName(_videoFile!.path),
                        style: TextStyle(
                          color: modernTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_call,
                        size: 40,
                        color: modernTheme.textSecondaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to select video',
                        style: TextStyle(
                          color: modernTheme.textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Supported: ${Constants.supportedVideoFormats.join(', ')}',
                        style: TextStyle(
                          color: modernTheme.textSecondaryColor?.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (_videoFile != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _pickVideoFile,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Change Video'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFE2C55),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _videoFile = null),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Remove'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isUploading || _videoFile == null) ? null : _addEpisode,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFE2C55),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isUploading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      value: _uploadProgress,
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Uploading ${(_uploadProgress * 100).toInt()}%'),
                ],
              )
            : Text(
                _videoFile != null ? 'Add Episode' : 'Select Video First',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFE2C55).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFE2C55).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.upload,
                color: Color(0xFFFE2C55),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Uploading Episode...',
                style: TextStyle(
                  color: Color(0xFFFE2C55),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${(_uploadProgress * 100).toInt()}%',
                style: const TextStyle(
                  color: Color(0xFFFE2C55),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.grey.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFE2C55)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please do not close this screen while uploading.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(ModernThemeExtension modernTheme) {
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      body: const Center(
        child: CircularProgressIndicator(color: Color(0xFFFE2C55)),
      ),
    );
  }

  Widget _buildError(ModernThemeExtension modernTheme, String error) {
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load drama',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: modernTheme.surfaceVariantColor,
                      foregroundColor: modernTheme.textColor,
                    ),
                    child: const Text('Go Back'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => ref.refresh(dramaProvider(widget.dramaId)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFE2C55),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFound(ModernThemeExtension modernTheme) {
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.tv_off,
                size: 64,
                color: modernTheme.textSecondaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Drama not found',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This drama may have been removed or is no longer available.',
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFE2C55),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickThumbnailImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _thumbnailImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickVideoFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowedExtensions: Constants.supportedVideoFormats,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      
      // Check file size (optional - you might want to set a limit)
      final fileSizeInMB = await file.length() / (1024 * 1024);
      if (fileSizeInMB > 500) { // 500MB limit
        if (mounted) {
          showSnackBar(context, 'Video file is too large (max 500MB)');
        }
        return;
      }

      setState(() {
        _videoFile = file;
      });
    }
  }

  Future<void> _addEpisode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_videoFile == null) {
      showSnackBar(context, 'Please select a video file');
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || !currentUser.isAdmin) {
      showSnackBar(context, Constants.adminOnly);
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final now = DateTime.now().microsecondsSinceEpoch.toString();
      
      final episode = EpisodeModel(
        episodeId: '', // Will be set by repository
        dramaId: widget.dramaId,
        episodeNumber: int.parse(_episodeNumberController.text.trim()),
        episodeTitle: _episodeTitleController.text.trim(),
        videoDuration: int.parse(_videoDurationController.text.trim()),
        releasedAt: now,
        uploadedBy: currentUser.uid,
        createdAt: now,
        updatedAt: now,
      );

      final repository = ref.read(dramaRepositoryProvider);
      
      // Upload with progress tracking
      final episodeId = await repository.addEpisode(
        episode,
        thumbnailImage: _thumbnailImage,
        videoFile: _videoFile,
      );

      if (mounted) {
        // Refresh episodes list and drama
        ref.invalidate(dramaEpisodesProvider(widget.dramaId));
        ref.invalidate(dramaProvider(widget.dramaId));
        
        showSnackBar(context, Constants.episodeAdded);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to add episode: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  String _getFileName(String path) {
    return path.split('/').last;
  }
}
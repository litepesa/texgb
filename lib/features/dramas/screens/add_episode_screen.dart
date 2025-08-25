// lib/features/dramas/screens/add_episode_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
  final _episodeNumberController = TextEditingController();

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
    _episodeNumberController.dispose();
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
            if (_episodeNumberController.text.isEmpty) {
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
                'Upload',
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
              _buildSimpleUploadSection(modernTheme),
              const SizedBox(height: 32),
              _buildUploadButton(),
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
          if (episodes.length <= 5)
            // Show list for few episodes
            Column(
              children: episodes.map((episode) => 
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: modernTheme.surfaceVariantColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFE2C55),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Ep ${episode.episodeNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          episode.formattedDuration,
                          style: TextStyle(
                            color: modernTheme.textColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade400,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ).toList(),
            )
          else
            // Show horizontal scroll for many episodes
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
                        const SizedBox(height: 4),
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade400,
                          size: 16,
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

  Widget _buildSimpleUploadSection(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _videoFile != null 
              ? const Color(0xFFFE2C55).withOpacity(0.3)
              : modernTheme.textSecondaryColor?.withOpacity(0.2) ?? Colors.grey,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Episode Number Input
          Row(
            children: [
              Icon(
                Icons.numbers,
                color: modernTheme.textSecondaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _episodeNumberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Episode Number',
                    hintText: 'Enter episode number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: modernTheme.surfaceVariantColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter episode number';
                    }
                    final number = int.tryParse(value.trim());
                    if (number == null || number <= 0) {
                      return 'Please enter a valid episode number';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Video Upload Section
          _videoFile != null 
              ? GestureDetector(
                  onTap: _pickVideoFile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.shade300,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.video_file,
                            size: 32,
                            color: Colors.green.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Video Selected',
                          style: TextStyle(
                            color: modernTheme.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getFileName(_videoFile!.path),
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: _pickVideoFile,
                              icon: const Icon(Icons.swap_horiz, size: 16),
                              label: const Text('Change'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFFE2C55),
                              ),
                            ),
                            const SizedBox(width: 8),
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
                      ],
                    ),
                  ),
                )
              : _buildDashedBorder(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _pickVideoFile,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFE2C55).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.video_call,
                                size: 40,
                                color: Color(0xFFFE2C55),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Select Video File',
                              style: TextStyle(
                                color: modernTheme.textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap here to choose video from gallery',
                              style: TextStyle(
                                color: modernTheme.textSecondaryColor,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFE2C55).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFFE2C55).withOpacity(0.3),
                                ),
                              ),
                              child: const Text(
                                'MP4, MOV, AVI videos supported',
                                style: TextStyle(
                                  color: Color(0xFFFE2C55),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (_isUploading || _videoFile == null) ? null : _addEpisode,
        icon: _isUploading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  value: _uploadProgress,
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.upload),
        label: Text(
          _isUploading
              ? 'Uploading ${(_uploadProgress * 100).toInt()}%'
              : _videoFile != null 
                  ? 'Upload Episode' 
                  : 'Select Video First',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFE2C55),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
            'Please keep this screen open while uploading.',
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

  Future<void> _pickVideoFile() async {
    try {
      final picker = ImagePicker();
      
      // Show loading message
      if (mounted) {
        showSnackBar(context, 'Opening video gallery...');
      }

      final pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 60), // 1 hour max
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        
        // Check if file exists
        if (!await file.exists()) {
          if (mounted) {
            showSnackBar(context, 'Selected video file does not exist');
          }
          return;
        }

        // Check file size (500MB limit)
        final fileSizeInMB = await file.length() / (1024 * 1024);
        
        if (fileSizeInMB > 500) {
          if (mounted) {
            showSnackBar(context, 'Video file is too large (max 500MB)');
          }
          return;
        }

        // Get file name from path
        final fileName = pickedFile.path.split('/').last;

        if (mounted) {
          setState(() {
            _videoFile = file;
          });
          showSnackBar(context, 'Video selected: ${fileName}');
        }
      } else {
        if (mounted) {
          showSnackBar(context, 'No video selected');
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error selecting video: $e');
      }
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
      final episodeNumber = int.parse(_episodeNumberController.text.trim());
      
      // Get video duration (you'll need to implement this)
      final videoDurationSeconds = await _getVideoDuration(_videoFile!);
      
      final episode = EpisodeModel(
        episodeId: '', // Will be set by repository
        dramaId: widget.dramaId,
        episodeNumber: episodeNumber,
        episodeTitle: '', // Auto-generated or empty
        videoDuration: videoDurationSeconds,
        releasedAt: now,
        uploadedBy: currentUser.uid,
        createdAt: now,
        updatedAt: now,
      );

      // Simulate upload progress
      for (double progress = 0.1; progress <= 1.0; progress += 0.1) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          setState(() {
            _uploadProgress = progress;
          });
        }
      }

      final repository = ref.read(dramaRepositoryProvider);
      
      // Upload episode (simplified - only video file, no thumbnail)
      final episodeId = await repository.addEpisode(
        episode,
        videoFile: _videoFile,
        // No thumbnail parameter
      );

      if (mounted) {
        // Refresh episodes list and drama
        ref.invalidate(dramaEpisodesProvider(widget.dramaId));
        ref.invalidate(dramaProvider(widget.dramaId));
        
        showSnackBar(context, 'Episode uploaded successfully!');
        
        // Reset form for next episode
        _episodeNumberController.text = (episodeNumber + 1).toString();
        setState(() {
          _videoFile = null;
        });
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to upload episode: $e');
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

  // Simple duration estimation - replace with actual video duration detection
  Future<int> _getVideoDuration(File videoFile) async {
    // For now, return a default duration
    // In production, you'd use a package like video_player or ffmpeg to get actual duration
    return 300; // 5 minutes default
  }

  // Custom dashed border widget
  Widget _buildDashedBorder({required Widget child}) {
    return CustomPaint(
      painter: DashedBorderPainter(),
      child: Container(
        decoration: BoxDecoration(
          color: context.modernTheme.surfaceVariantColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }
}

// Custom painter for dashed border
class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 4.0;
    
    final path = Path();
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    ));
    
    _drawDashedPath(canvas, path, paint, dashWidth, dashSpace);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double dashWidth, double dashSpace) {
    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final nextDistance = distance + dashWidth;
        final dashedPath = pathMetric.extractPath(distance, nextDistance.clamp(0.0, pathMetric.length));
        canvas.drawPath(dashedPath, paint);
        distance = nextDistance + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
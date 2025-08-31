// lib/features/dramas/screens/add_episodes_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/dramas/providers/drama_providers.dart';
import 'package:textgb/models/drama_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class AddEpisodesScreen extends ConsumerStatefulWidget {
  final String dramaId;

  const AddEpisodesScreen({
    super.key,
    required this.dramaId,
  });

  @override
  ConsumerState<AddEpisodesScreen> createState() => _AddEpisodesScreenState();
}

class _AddEpisodesScreenState extends ConsumerState<AddEpisodesScreen> {
  File? _newEpisode;
  bool _isAddingEpisode = false;
  bool _isSelectingVideo = false;
  double _uploadProgress = 0.0;
  DramaModel? _drama;

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
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final currentUser = ref.watch(currentUserProvider);
    final dramaAsync = ref.watch(dramaProvider(widget.dramaId));

    if (currentUser == null || !currentUser.isAdmin) {
      return _buildAccessDenied(modernTheme);
    }

    return dramaAsync.when(
      data: (drama) {
        if (drama == null) {
          return _buildNotFound(modernTheme);
        }

        _drama = drama;
        return _buildAddEpisodesScreen(modernTheme, drama);
      },
      loading: () => _buildLoading(modernTheme),
      error: (error, stack) => _buildError(modernTheme, error.toString()),
    );
  }

  Widget _buildAddEpisodesScreen(ModernThemeExtension modernTheme, DramaModel drama) {
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: _buildAppBar(modernTheme, drama),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDramaInfoCard(modernTheme, drama),
            const SizedBox(height: 24),
            _buildCurrentEpisodesSection(modernTheme, drama),
            const SizedBox(height: 24),
            _buildNewEpisodeSection(modernTheme),
            const SizedBox(height: 32),
            if (_newEpisode != null) _buildAddEpisodeButton(modernTheme),
            if (_isAddingEpisode) ...[
              const SizedBox(height: 16),
              _buildUploadProgress(modernTheme),
            ],
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(ModernThemeExtension modernTheme, DramaModel drama) {
    return AppBar(
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: modernTheme.textColor),
        onPressed: _isAddingEpisode ? null : () => Navigator.pop(context),
      ),
      actions: [
        if (_isAddingEpisode)
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
          ),
      ],
    );
  }

  Widget _buildDramaInfoCard(ModernThemeExtension modernTheme, DramaModel drama) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Drama banner
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 80,
              height: 60,
              child: drama.bannerImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: drama.bannerImage,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: modernTheme.surfaceVariantColor,
                        child: const Center(
                          child: CircularProgressIndicator(color: Color(0xFFFE2C55)),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: modernTheme.surfaceVariantColor,
                        child: Icon(
                          Icons.tv,
                          size: 24,
                          color: modernTheme.textSecondaryColor,
                        ),
                      ),
                    )
                  : Container(
                      color: modernTheme.surfaceVariantColor,
                      child: Icon(
                        Icons.tv,
                        size: 24,
                        color: modernTheme.textSecondaryColor,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Drama info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drama.title,
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      size: 16,
                      color: modernTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${drama.totalEpisodes} episodes',
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                    if (drama.isPremium) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Premium',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      drama.isActive ? Icons.visibility : Icons.visibility_off,
                      size: 16,
                      color: drama.isActive ? Colors.green.shade400 : Colors.red.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      drama.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: drama.isActive ? Colors.green.shade400 : Colors.red.shade400,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentEpisodesSection(ModernThemeExtension modernTheme, DramaModel drama) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.video_library,
              color: modernTheme.textColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Current Episodes (${drama.totalEpisodes})',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        if (drama.totalEpisodes == 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: modernTheme.surfaceVariantColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.video_call_outlined,
                  size: 48,
                  color: modernTheme.textSecondaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Episodes Yet',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This drama doesn\'t have any episodes yet.\nAdd your first episode below.',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: drama.totalEpisodes,
              itemBuilder: (context, index) {
                final episodeNumber = index + 1;
                return Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: modernTheme.surfaceVariantColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFFE2C55).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: drama.bannerImage.isNotEmpty
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: drama.bannerImage,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) => Container(
                                          color: modernTheme.surfaceVariantColor,
                                          child: Center(
                                            child: Text(
                                              '$episodeNumber',
                                              style: TextStyle(
                                                color: modernTheme.textColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.7),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 4,
                                        left: 4,
                                        child: Text(
                                          '$episodeNumber',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Center(
                                    child: Text(
                                      '$episodeNumber',
                                      style: TextStyle(
                                        color: modernTheme.textColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Episode $episodeNumber',
                        style: TextStyle(
                          color: modernTheme.textColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildNewEpisodeSection(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _newEpisode != null 
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
                Icons.add_circle,
                color: _newEpisode != null 
                    ? const Color(0xFFFE2C55) 
                    : modernTheme.textColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _newEpisode != null ? 'New Episode Ready' : 'Add New Episode',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_newEpisode != null)
                TextButton.icon(
                  onPressed: _clearNewEpisode,
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // New episode area
          if (_newEpisode == null)
            _buildEmptyNewEpisodeArea(modernTheme)
          else
            _buildNewEpisodeItem(modernTheme),
          
          const SizedBox(height: 16),
          
          // Add episode button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSelectingVideo ? null : _addEpisode,
              icon: _isSelectingVideo
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.add),
              label: Text(_isSelectingVideo 
                  ? 'Selecting Video...' 
                  : _newEpisode == null 
                      ? (_drama?.totalEpisodes == 0 ? 'Add First Episode' : 'Add Episode ${(_drama?.totalEpisodes ?? 0) + 1}')
                      : 'Replace Episode ${(_drama?.totalEpisodes ?? 0) + 1}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFE2C55),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNewEpisodeArea(ModernThemeExtension modernTheme) {
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
            'Ready to Add New Episode',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a video file to extend this drama series\nNew episode will be numbered automatically',
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

  Widget _buildNewEpisodeItem(ModernThemeExtension modernTheme) {
    final file = _newEpisode!;
    final fileName = file.path.split('/').last;
    final episodeNumber = (_drama?.totalEpisodes ?? 0) + 1;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceVariantColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFE2C55).withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Episode indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFE2C55),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'EP $episodeNumber',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Video icon and file info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.play_circle_filled,
                      color: Color(0xFFFE2C55),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fileName,
                        style: TextStyle(
                          color: modernTheme.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'READY TO ADD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Remove button
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _clearNewEpisode,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddEpisodeButton(ModernThemeExtension modernTheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isAddingEpisode ? null : _addEpisodeToDrama,
        icon: _isAddingEpisode
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.add_to_photos),
        label: Text(
          _isAddingEpisode
              ? 'Adding Episode...'
              : 'Add Episode ${(_drama?.totalEpisodes ?? 0) + 1} to Drama',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFE2C55),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              const Text(
                'Adding Episode...',
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
            'Please keep this screen open while adding the episode.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
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

  // ===============================
  // EPISODE MANAGEMENT METHODS
  // ===============================
  
  Future<void> _addEpisode() async {
    setState(() => _isSelectingVideo = true);

    try {
      final picker = ImagePicker();
      
      final XFile? pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 60),
      );

      if (pickedFile != null) {
        final videoFile = File(pickedFile.path);
        
        final fileSizeInBytes = await videoFile.length();
        final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
        
        if (fileSizeInMB <= 500) {
          setState(() {
            _newEpisode = videoFile;
          });
          
          showSnackBar(context, 'Episode selected successfully!');
        } else {
          showSnackBar(context, 'Video too large! Maximum size is 500MB (current: ${fileSizeInMB.toStringAsFixed(1)}MB)');
        }
      }
    } catch (e) {
      showSnackBar(context, 'Error selecting video: $e');
    } finally {
      setState(() => _isSelectingVideo = false);
    }
  }

  void _clearNewEpisode() {
    setState(() {
      _newEpisode = null;
    });
    showSnackBar(context, 'Episode cleared');
  }

  Future<void> _addEpisodeToDrama() async {
    if (_newEpisode == null) {
      showSnackBar(context, 'No episode to add');
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || !currentUser.isAdmin) {
      showSnackBar(context, Constants.adminOnly);
      return;
    }

    final drama = _drama;
    if (drama == null) return;

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Episode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Drama: ${drama.title}'),
            const SizedBox(height: 8),
            Text('Current episodes: ${drama.totalEpisodes}'),
            Text('Episode to add: Episode ${drama.totalEpisodes + 1}'),
            const SizedBox(height: 16),
            const Text('This will upload the video and add it to the drama. Continue?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFE2C55)),
            child: const Text('Add Episode'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isAddingEpisode = true;
      _uploadProgress = 0.0;
    });

    try {
      // Upload the new episode video
      final repository = ref.read(dramaRepositoryProvider);
      final episodeNumber = drama.totalEpisodes + 1;
      final videoUrl = await repository.uploadVideo(
        _newEpisode!, 
        'episode_$episodeNumber',
      );
      
      setState(() => _uploadProgress = 1.0);

      // Update drama with new episode
      final updatedEpisodeVideos = [...drama.episodeVideos, videoUrl];
      final updatedDrama = drama.copyWith(
        episodeVideos: updatedEpisodeVideos,
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );

      await repository.updateDrama(updatedDrama);

      if (mounted) {
        // Refresh drama data
        ref.invalidate(dramaProvider(widget.dramaId));
        ref.invalidate(adminDramasProvider);
        
        showSnackBar(context, 'Successfully added Episode ${episodeNumber}!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to add episode: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingEpisode = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }
}
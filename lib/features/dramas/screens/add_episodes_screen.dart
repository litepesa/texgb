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
  List<File> _newEpisodes = [];
  bool _isAddingEpisodes = false;
  bool _isSelectingVideos = false;
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
            _buildNewEpisodesSection(modernTheme),
            const SizedBox(height: 32),
            if (_newEpisodes.isNotEmpty) _buildAddEpisodesButton(modernTheme),
            if (_isAddingEpisodes) ...[
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
            'Add Episodes',
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
        onPressed: _isAddingEpisodes ? null : () => Navigator.pop(context),
      ),
      actions: [
        if (_isAddingEpisodes)
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

  Widget _buildNewEpisodesSection(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _newEpisodes.isNotEmpty 
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
                color: _newEpisodes.isNotEmpty 
                    ? const Color(0xFFFE2C55) 
                    : modernTheme.textColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'New Episodes (${_newEpisodes.length})',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_newEpisodes.isNotEmpty)
                TextButton.icon(
                  onPressed: _clearAllNewEpisodes,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear All'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // New episodes area
          if (_newEpisodes.isEmpty)
            _buildEmptyNewEpisodesArea(modernTheme)
          else
            _buildNewEpisodesGrid(modernTheme),
          
          const SizedBox(height: 16),
          
          // Add episode buttons
          if (_newEpisodes.length < 50) // Reasonable limit for adding episodes at once
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSelectingVideos ? null : _addSingleEpisode,
                    icon: _isSelectingVideos
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.add),
                    label: Text(_isSelectingVideos 
                        ? 'Selecting Video...' 
                        : _newEpisodes.isEmpty 
                            ? 'Add First Episode' 
                            : 'Add Episode ${(_drama?.totalEpisodes ?? 0) + _newEpisodes.length + 1}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFE2C55),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                
                if (_newEpisodes.isNotEmpty && _newEpisodes.length < 45)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isSelectingVideos ? null : _addMultipleEpisodes,
                        icon: const Icon(Icons.playlist_add, size: 16),
                        label: const Text('Add Multiple Episodes'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFE2C55),
                          side: const BorderSide(color: Color(0xFFFE2C55)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyNewEpisodesArea(ModernThemeExtension modernTheme) {
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
            'Ready to Add New Episodes',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add video files to extend this drama series\nNew episodes will be numbered automatically',
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

  Widget _buildNewEpisodesGrid(ModernThemeExtension modernTheme) {
    final currentEpisodeCount = _drama?.totalEpisodes ?? 0;
    
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: _newEpisodes.length,
          itemBuilder: (context, index) {
            return _buildNewEpisodeItem(modernTheme, index, currentEpisodeCount);
          },
        ),
        
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
                  '${_newEpisodes.length} new episode${_newEpisodes.length != 1 ? 's' : ''} ready to add. '
                  'Episodes will be numbered ${currentEpisodeCount + 1}-${currentEpisodeCount + _newEpisodes.length}.',
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

  Widget _buildNewEpisodeItem(ModernThemeExtension modernTheme, int index, int currentEpisodeCount) {
    final file = _newEpisodes[index];
    final fileName = file.path.split('/').last;
    final episodeNumber = currentEpisodeCount + index + 1;
    
    return Container(
      decoration: BoxDecoration(
        color: modernTheme.surfaceVariantColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFE2C55).withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFE2C55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'EP $episodeNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                const Icon(
                  Icons.play_circle_filled,
                  color: Color(0xFFFE2C55),
                  size: 24,
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  fileName.length > 15 
                      ? '${fileName.substring(0, 12)}...' 
                      : fileName,
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 2),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeNewEpisode(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddEpisodesButton(ModernThemeExtension modernTheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isAddingEpisodes ? null : _addEpisodesToDrama,
        icon: _isAddingEpisodes
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
          _isAddingEpisodes
              ? 'Adding Episodes...'
              : 'Add ${_newEpisodes.length} Episode${_newEpisodes.length != 1 ? 's' : ''} to Drama',
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
              Text(
                'Adding ${_newEpisodes.length} Episodes...',
                style: const TextStyle(
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
            'Please keep this screen open while adding episodes.',
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
  
  Future<void> _addSingleEpisode() async {
    if (_newEpisodes.length >= 50) {
      showSnackBar(context, 'Maximum 50 episodes can be added at once');
      return;
    }

    setState(() => _isSelectingVideos = true);

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
            _newEpisodes.add(videoFile);
          });
          
          showSnackBar(context, 'Episode added successfully!');
        } else {
          showSnackBar(context, 'Video too large! Maximum size is 500MB (current: ${fileSizeInMB.toStringAsFixed(1)}MB)');
        }
      }
    } catch (e) {
      showSnackBar(context, 'Error selecting video: $e');
    } finally {
      setState(() => _isSelectingVideos = false);
    }
  }

  Future<void> _addMultipleEpisodes() async {
    if (_newEpisodes.length >= 50) {
      showSnackBar(context, 'Maximum 50 episodes can be added at once');
      return;
    }

    setState(() => _isSelectingVideos = true);

    try {
      final picker = ImagePicker();
      
      showSnackBar(context, 'Opening video gallery...');

      final remainingSlots = 50 - _newEpisodes.length;
      
      final List<XFile> pickedFiles = await picker.pickMultipleMedia(
        limit: remainingSlots,
      );

      final List<File> validVideoFiles = [];
      final List<String> skippedFiles = [];
      
      for (final file in pickedFiles) {
        final fileName = file.path.toLowerCase();
        if (fileName.endsWith('.mp4') || 
            fileName.endsWith('.mov') || 
            fileName.endsWith('.avi') || 
            fileName.endsWith('.mkv') ||
            file.mimeType?.startsWith('video/') == true) {
          
          final videoFile = File(file.path);
          
          final fileSizeInBytes = await videoFile.length();
          final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
          
          if (fileSizeInMB <= 500) {
            validVideoFiles.add(videoFile);
          } else {
            skippedFiles.add('${file.name} (${fileSizeInMB.toStringAsFixed(1)}MB - too large)');
          }
        } else {
          skippedFiles.add('${file.name} (not a video file)');
        }
      }

      if (validVideoFiles.isNotEmpty) {
        setState(() {
          _newEpisodes.addAll(validVideoFiles);
        });
        
        String message = 'Added ${validVideoFiles.length} episodes';
        if (skippedFiles.isNotEmpty) {
          message += ' (${skippedFiles.length} files skipped)';
        }
        showSnackBar(context, message);
        
        if (skippedFiles.isNotEmpty && skippedFiles.length <= 3) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              showSnackBar(context, 'Skipped: ${skippedFiles.join(', ')}');
            }
          });
        }
      } else {
        showSnackBar(context, 'No valid video files selected (max 500MB each)');
      }
    } catch (e) {
      showSnackBar(context, 'Error selecting videos: $e');
    } finally {
      setState(() => _isSelectingVideos = false);
    }
  }

  void _removeNewEpisode(int index) {
    setState(() {
      _newEpisodes.removeAt(index);
    });
    showSnackBar(context, 'Episode removed');
  }

  void _clearAllNewEpisodes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All New Episodes'),
        content: Text('Are you sure you want to remove all ${_newEpisodes.length} new episodes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _newEpisodes.clear();
              });
              Navigator.pop(context);
              showSnackBar(context, 'All new episodes cleared');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _addEpisodesToDrama() async {
    if (_newEpisodes.isEmpty) {
      showSnackBar(context, 'No episodes to add');
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
        title: const Text('Add Episodes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Drama: ${drama.title}'),
            const SizedBox(height: 8),
            Text('Current episodes: ${drama.totalEpisodes}'),
            Text('New episodes: ${_newEpisodes.length}'),
            Text('Total after adding: ${drama.totalEpisodes + _newEpisodes.length}'),
            const SizedBox(height: 16),
            const Text('This will upload all videos and add them to the drama. Continue?'),
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
            child: const Text('Add Episodes'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isAddingEpisodes = true;
      _uploadProgress = 0.0;
    });

    try {
      final repository = ref.read(dramaRepositoryProvider);
      
      // Step 1: Upload all new episode videos (0% - 80% progress)
      final newEpisodeUrls = <String>[];
      for (int i = 0; i < _newEpisodes.length; i++) {
        final episodeNumber = drama.totalEpisodes + i + 1;
        final videoUrl = await repository.uploadVideo(
          _newEpisodes[i], 
          'episode_${episodeNumber}_${drama.dramaId}', // More specific episode ID
          onProgress: (fileProgress) {
            // Calculate overall progress: each video gets 80% / total videos
            final baseProgress = (i / _newEpisodes.length) * 0.8;
            final fileProgressContribution = (fileProgress / _newEpisodes.length) * 0.8;
            setState(() => _uploadProgress = baseProgress + fileProgressContribution);
          },
        );
        newEpisodeUrls.add(videoUrl);
        
        // Update progress after each complete upload
        final progress = ((i + 1) / _newEpisodes.length) * 0.8;
        setState(() => _uploadProgress = progress);
      }

      // Step 2: Add episodes to drama via repository method (80% - 95% progress)
      setState(() => _uploadProgress = 0.85);
      
      await repository.addEpisodesToDrama(drama.dramaId, newEpisodeUrls);

      // Step 3: Refresh data (95% - 100% progress)
      setState(() => _uploadProgress = 0.95);
      
      if (mounted) {
        // Refresh drama data to get updated episode count
        ref.invalidate(dramaProvider(widget.dramaId));
        ref.invalidate(adminDramasProvider);
        ref.invalidate(allDramasProvider); // Also refresh all dramas list
        
        setState(() => _uploadProgress = 1.0);
        
        showSnackBar(context, 'Successfully added ${_newEpisodes.length} episodes!');
        
        // Small delay to show 100% progress
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to add episodes: $e');
        debugPrint('Error adding episodes: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingEpisodes = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }
}
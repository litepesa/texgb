// lib/features/dramas/screens/create_drama_screen.dart - IMPROVED INTUITIVE VERSION with TS support
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/dramas/providers/drama_providers.dart';
import 'package:textgb/models/drama_model.dart';
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
  double _uploadProgress = 0.0;
  
  File? _bannerImage;
  List<File> _episodeVideos = []; // Up to 100 episodes
  bool _isAddingEpisode = false;

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
    _titleController.dispose();
    _descriptionController.dispose();
    _freeEpisodesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null || !currentUser.isAdmin) {
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

  Widget _buildProgressIndicator(ModernThemeExtension modernTheme) {
    final hasBasicInfo = _titleController.text.isNotEmpty && 
                        _descriptionController.text.isNotEmpty;
    final hasEpisodes = _episodeVideos.isNotEmpty;
    final hasSettings = true; // Always true as they have defaults
    
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
                value: _uploadProgress,
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
            onChanged: (_) => setState(() {}), // Trigger rebuild for progress
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
            onChanged: (_) => setState(() {}), // Trigger rebuild for progress
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
          onTap: _pickBannerImage,
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

  Widget _buildEpisodesSection(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _episodeVideos.isNotEmpty 
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
                color: _episodeVideos.isNotEmpty 
                    ? const Color(0xFFFE2C55) 
                    : modernTheme.textColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Step 2: Add Episodes (${_episodeVideos.length}/100)',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_episodeVideos.isNotEmpty)
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
          
          // Episode upload area
          if (_episodeVideos.isEmpty)
            _buildEmptyEpisodesArea(modernTheme)
          else
            _buildEpisodesGrid(modernTheme),
          
          const SizedBox(height: 16),
          
          // Add episode button - one at a time
          if (_episodeVideos.length < 100)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAddingEpisode ? null : _addSingleEpisode,
                icon: _isAddingEpisode
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(_isAddingEpisode 
                    ? 'Selecting Video...' 
                    : _episodeVideos.isEmpty 
                        ? 'Add First Episode' 
                        : 'Add Episode ${_episodeVideos.length + 1}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFE2C55),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            
          // Quick actions for multiple episodes
          if (_episodeVideos.isNotEmpty && _episodeVideos.length < 95)
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
            'Add video files one by one to build your drama series\nSupported formats: MP4, MOV, AVI, TS, WEBM\nEpisodes will be numbered automatically (1, 2, 3...)',
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

  Widget _buildEpisodesGrid(ModernThemeExtension modernTheme) {
    return Column(
      children: [
        // Episodes grid with improved layout
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: _episodeVideos.length,
          itemBuilder: (context, index) {
            return _buildEpisodeItem(modernTheme, index);
          },
        ),
        
        // Episode count info
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
                  '${_episodeVideos.length} episode${_episodeVideos.length != 1 ? 's' : ''} ready. Episodes are numbered automatically in order.',
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

  Widget _buildEpisodeItem(ModernThemeExtension modernTheme, int index) {
    final file = _episodeVideos[index];
    final fileName = file.path.split('/').last;
    
    return Container(
      decoration: BoxDecoration(
        color: modernTheme.surfaceVariantColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFE2C55).withOpacity(0.3),
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
                // Episode number badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFE2C55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'EP ${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Video icon
                const Icon(
                  Icons.play_circle_filled,
                  color: Color(0xFFFE2C55),
                  size: 24,
                ),
                
                const SizedBox(height: 4),
                
                // File name
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
              ],
            ),
          ),
          
          // Remove button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeEpisode(index),
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
          
          // Premium toggle
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
              onChanged: (value) {
                setState(() {
                  _isPremium = value;
                  if (value && _episodeVideos.isNotEmpty && _freeEpisodesController.text.isEmpty) {
                    // Auto-suggest free episodes count
                    final suggested = (_episodeVideos.length * 0.3).ceil().clamp(1, 5);
                    _freeEpisodesController.text = suggested.toString();
                  }
                });
              },
              activeColor: const Color(0xFFFFD700),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          
          if (_isPremium && _episodeVideos.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _freeEpisodesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Free Episodes',
                      hintText: '1-${_episodeVideos.length}',
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
                        if (number == null || number < 0 || number > _episodeVideos.length) {
                          return '1-${_episodeVideos.length}';
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
                          'coins/episode',
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
          
          // Featured toggle
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
              onChanged: (value) => setState(() => _isFeatured = value),
              activeColor: const Color(0xFFFE2C55),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Active toggle
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
              onChanged: (value) => setState(() => _isActive = value),
              activeColor: Colors.green.shade400,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton(ModernThemeExtension modernTheme) {
    final canCreate = _episodeVideos.isNotEmpty && 
                     _titleController.text.trim().isNotEmpty && 
                     _descriptionController.text.trim().isNotEmpty;
    
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
              : 'Create Drama (${_episodeVideos.length} episodes)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canCreate ? const Color(0xFFFE2C55) : Colors.grey,
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
                'Creating Drama with ${_episodeVideos.length} Episodes...',
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
            'Please keep this screen open while creating.',
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

  // ===============================
  // IMPROVED EPISODE MANAGEMENT METHODS - UPDATED WITH TS SUPPORT
  // ===============================
  
  Future<void> _addSingleEpisode() async {
    if (_episodeVideos.length >= 100) {
      showSnackBar(context, 'Maximum 100 episodes allowed');
      return;
    }

    setState(() => _isAddingEpisode = true);

    try {
      final picker = ImagePicker();
      
      // Pick single video with proper type specification
      final XFile? pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 60), // 60 min max per episode
      );

      if (pickedFile != null) {
        final videoFile = File(pickedFile.path);
        
        // Check file size (500MB limit per video)
        final fileSizeInBytes = await videoFile.length();
        final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
        
        if (fileSizeInMB <= 500) {
          setState(() {
            _episodeVideos.add(videoFile);
            // Auto-update free episodes if premium and not manually set
            if (_isPremium && _freeEpisodesController.text.isEmpty) {
              final suggested = (_episodeVideos.length * 0.3).ceil().clamp(1, 5);
              _freeEpisodesController.text = suggested.toString();
            }
          });
          
          showSnackBar(context, 'Episode ${_episodeVideos.length} added successfully!');
        } else {
          showSnackBar(context, 'Video too large! Maximum size is 500MB (current: ${fileSizeInMB.toStringAsFixed(1)}MB)');
        }
      }
    } catch (e) {
      showSnackBar(context, 'Error selecting video: $e');
    } finally {
      setState(() => _isAddingEpisode = false);
    }
  }

  Future<void> _addMultipleEpisodes() async {
    if (_episodeVideos.length >= 100) {
      showSnackBar(context, 'Maximum 100 episodes allowed');
      return;
    }

    setState(() => _isAddingEpisode = true);

    try {
      final picker = ImagePicker();
      
      // Show loading
      showSnackBar(context, 'Opening video gallery...');

      // Pick multiple videos (limited to remaining slots)
      final remainingSlots = 100 - _episodeVideos.length;
      
      // Use pickMultipleMedia but filter for videos only
      final List<XFile> pickedFiles = await picker.pickMultipleMedia(
        limit: remainingSlots,
      );

      // Filter and process video files - Updated to include TS format
      final List<File> validVideoFiles = [];
      final List<String> skippedFiles = [];
      
      for (final file in pickedFiles) {
        // Check if it's a video file - Added TS support
        final fileName = file.path.toLowerCase();
        if (fileName.endsWith('.mp4') || 
            fileName.endsWith('.mov') || 
            fileName.endsWith('.avi') || 
            fileName.endsWith('.mkv') ||
            fileName.endsWith('.ts') ||    // Added TS support
            fileName.endsWith('.webm') ||
            file.mimeType?.startsWith('video/') == true) {
          
          final videoFile = File(file.path);
          
          // Check file size (500MB limit per video)
          final fileSizeInBytes = await videoFile.length();
          final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
          
          if (fileSizeInMB <= 500) {
            validVideoFiles.add(videoFile);
          } else {
            skippedFiles.add('${file.name} (${fileSizeInMB.toStringAsFixed(1)}MB - too large)');
          }
        } else {
          skippedFiles.add('${file.name} (not a supported video file)');
        }
      }

      if (validVideoFiles.isNotEmpty) {
        setState(() {
          _episodeVideos.addAll(validVideoFiles);
          // Auto-update free episodes if premium
          if (_isPremium && _freeEpisodesController.text.isEmpty) {
            final suggested = (_episodeVideos.length * 0.3).ceil().clamp(1, 5);
            _freeEpisodesController.text = suggested.toString();
          }
        });
        
        String message = 'Added ${validVideoFiles.length} episodes';
        if (skippedFiles.isNotEmpty) {
          message += ' (${skippedFiles.length} files skipped)';
        }
        showSnackBar(context, message);
        
        // Show skipped files if any
        if (skippedFiles.isNotEmpty && skippedFiles.length <= 3) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              showSnackBar(context, 'Skipped: ${skippedFiles.join(', ')}');
            }
          });
        }
      } else {
        showSnackBar(context, 'No valid video files selected (supported: MP4, MOV, AVI, TS, WEBM - max 500MB each)');
      }
    } catch (e) {
      showSnackBar(context, 'Error selecting videos: $e');
    } finally {
      setState(() => _isAddingEpisode = false);
    }
  }

  void _removeEpisode(int index) {
    setState(() {
      _episodeVideos.removeAt(index);
      // Update free episodes count if needed
      if (_isPremium) {
        final currentFree = int.tryParse(_freeEpisodesController.text) ?? 0;
        if (currentFree > _episodeVideos.length) {
          _freeEpisodesController.text = _episodeVideos.length.toString();
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
        content: Text('Are you sure you want to remove all ${_episodeVideos.length} episodes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _episodeVideos.clear();
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
            itemCount: _episodeVideos.length,
            onReorder: (oldIndex, newIndex) {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              setState(() {
                final item = _episodeVideos.removeAt(oldIndex);
                _episodeVideos.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final fileName = _episodeVideos[index].path.split('/').last;
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
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1080,
    );

    if (pickedFile != null) {
      // Check file size (10MB limit for banner)
      final imageFile = File(pickedFile.path);
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
    }
  }

  // ===============================
  // UNIFIED DRAMA CREATION
  // ===============================
  
  Future<void> _createDrama() async {
    if (!_formKey.currentState!.validate()) return;
    if (_episodeVideos.isEmpty) {
      showSnackBar(context, 'Please add at least one episode');
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || !currentUser.isAdmin) {
      showSnackBar(context, Constants.adminOnly);
      return;
    }

    // Final validation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Drama'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${_titleController.text.trim()}'),
            const SizedBox(height: 8),
            Text('Episodes: ${_episodeVideos.length}'),
            if (_isPremium) ...[
              const SizedBox(height: 8),
              Text('Free Episodes: ${_freeEpisodesController.text}'),
              Text('Premium Episodes: ${_episodeVideos.length - (int.tryParse(_freeEpisodesController.text) ?? 0)}'),
            ],
            const SizedBox(height: 8),
            Text('Featured: ${_isFeatured ? "Yes" : "No"}'),
            Text('Publish Immediately: ${_isActive ? "Yes" : "No"}'),
            const SizedBox(height: 16),
            const Text('This will upload all videos and create your drama. Continue?'),
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
            child: const Text('Create Drama'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isCreating = true;
      _uploadProgress = 0.0;
    });

    try {
      // Step 1: Upload banner image (10% progress)
      String bannerUrl = '';
      if (_bannerImage != null) {
        setState(() => _uploadProgress = 0.05);
        final repository = ref.read(dramaRepositoryProvider);
        bannerUrl = await repository.uploadBannerImage(_bannerImage!, '');
        setState(() => _uploadProgress = 0.1);
      }

      // Step 2: Upload all episode videos (10% - 90% progress)
      final episodeUrls = <String>[];
      for (int i = 0; i < _episodeVideos.length; i++) {
        final repository = ref.read(dramaRepositoryProvider);
        final videoUrl = await repository.uploadVideo(_episodeVideos[i], 'episode_${i + 1}');
        episodeUrls.add(videoUrl);
        
        // Update progress (10% + 80% for videos)
        final videoProgress = 0.1 + (0.8 * (i + 1) / _episodeVideos.length);
        setState(() => _uploadProgress = videoProgress);
      }

      // Step 3: Create drama with all episodes (90% - 100%)
      setState(() => _uploadProgress = 0.95);
      
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

      final repository = ref.read(dramaRepositoryProvider);
      final dramaId = await repository.createDramaWithEpisodes(drama);

      setState(() => _uploadProgress = 1.0);

      if (mounted) {
        // Refresh all relevant providers
        ref.invalidate(adminDramasProvider);
        ref.invalidate(allDramasProvider);
        if (_isFeatured) ref.invalidate(featuredDramasProvider);
        
        showSnackBar(context, 'Drama created successfully with ${episodeUrls.length} episodes!');
        Navigator.of(context).pop();
        
        // Navigate to the new drama
        Navigator.pushNamed(
          context,
          Constants.dramaDetailsScreen,
          arguments: {'dramaId': dramaId},
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to create drama: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }
}
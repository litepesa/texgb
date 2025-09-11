// lib/features/dramas/screens/edit_drama_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/dramas/models/drama_model.dart';
import 'package:textgb/features/dramas/providers/drama_providers.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class EditDramaScreen extends ConsumerStatefulWidget {
  final String dramaId;

  const EditDramaScreen({
    super.key,
    required this.dramaId,
  });

  @override
  ConsumerState<EditDramaScreen> createState() => _EditDramaScreenState();
}

class _EditDramaScreenState extends ConsumerState<EditDramaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _freeEpisodesController = TextEditingController();

  bool _isPremium = false;
  bool _isFeatured = false;
  bool _isActive = true;
  bool _isUpdating = false;
  File? _newBannerImage;
  DramaModel? _originalDrama;

  @override
  void initState() {
    super.initState();
    // Check verification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider);
      final isVerified = currentUser?.isVerified ?? false;
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

  void _loadDramaData(DramaModel drama) {
    if (_originalDrama?.dramaId == drama.dramaId) return; // Already loaded
    
    _originalDrama = drama;
    _titleController.text = drama.title;
    _descriptionController.text = drama.description;
    _freeEpisodesController.text = drama.freeEpisodesCount.toString();
    _isPremium = drama.isPremium;
    _isFeatured = drama.isFeatured;
    _isActive = drama.isActive;
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final currentUser = ref.watch(currentUserProvider);
    final dramaAsync = ref.watch(dramaProvider(widget.dramaId));

    if (currentUser == null || !currentUser.isVerified) {
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

        // Load drama data into form
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadDramaData(drama);
        });

        return _buildEditForm(modernTheme, drama);
      },
      loading: () => _buildLoading(modernTheme),
      error: (error, stack) => _buildError(modernTheme, error.toString()),
    );
  }

  Widget _buildEditForm(ModernThemeExtension modernTheme, DramaModel drama) {
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: modernTheme.surfaceColor,
        elevation: 0,
        title: Text(
          'Edit Drama',
          style: TextStyle(
            color: modernTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: modernTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isUpdating)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Color(0xFFFE2C55),
                  strokeWidth: 2,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _updateDrama,
              child: const Text(
                'Save',
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
              _buildBannerImageSection(modernTheme, drama),
              const SizedBox(height: 24),
              _buildBasicInfoSection(modernTheme),
              const SizedBox(height: 24),
              _buildPremiumSection(modernTheme),
              const SizedBox(height: 24),
              _buildSettingsSection(modernTheme),
              const SizedBox(height: 24),
              _buildStatsSection(modernTheme, drama),
              const SizedBox(height: 32),
              _buildActionButtons(modernTheme, drama),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerImageSection(ModernThemeExtension modernTheme, DramaModel drama) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Banner Image',
          style: TextStyle(
            color: modernTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickBannerImage,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: modernTheme.surfaceVariantColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: modernTheme.textSecondaryColor?.withOpacity(0.3) ?? Colors.grey,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: _newBannerImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _newBannerImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : drama.bannerImage.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: drama.bannerImage,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: modernTheme.surfaceVariantColor,
                            child: const Center(
                              child: CircularProgressIndicator(color: Color(0xFFFE2C55)),
                            ),
                          ),
                          errorWidget: (context, url, error) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 48,
                                color: modernTheme.textSecondaryColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to change banner',
                                style: TextStyle(
                                  color: modernTheme.textSecondaryColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 48,
                            color: modernTheme.textSecondaryColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to add banner image',
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
        if (_newBannerImage != null || drama.bannerImage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _pickBannerImage,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Change Image'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFE2C55),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _newBannerImage = null),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Remove New'),
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

  Widget _buildBasicInfoSection(ModernThemeExtension modernTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: TextStyle(
            color: modernTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Title field
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Drama Title',
            hintText: 'Enter the drama title',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: modernTheme.surfaceColor,
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
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Enter drama description',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: modernTheme.surfaceColor,
          ),
          style: TextStyle(color: modernTheme.textColor),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a description';
            }
            if (value.trim().length < 10) {
              return 'Description must be at least 10 characters';
            }
            if (value.trim().length > Constants.maxDramaDescriptionLength) {
              return 'Description is too long (max ${Constants.maxDramaDescriptionLength} characters)';
            }
            return null;
          },
        ),
      ],
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
                'Premium Settings',
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
          SwitchListTile(
            title: Text(
              'Premium Drama',
              style: TextStyle(color: modernTheme.textColor),
            ),
            subtitle: Text(
              'Users need to pay coins to unlock all episodes',
              style: TextStyle(color: modernTheme.textSecondaryColor),
            ),
            value: _isPremium,
            onChanged: (value) => setState(() => _isPremium = value),
            activeColor: const Color(0xFFFFD700),
            contentPadding: EdgeInsets.zero,
          ),
          
          if (_isPremium) ...[
            const SizedBox(height: 16),
            Text(
              'Free Episodes Count',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _freeEpisodesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Number of free episodes (0-${Constants.maxFreeEpisodes})',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: modernTheme.surfaceVariantColor,
                isDense: true,
              ),
              style: TextStyle(color: modernTheme.textColor),
              validator: (value) {
                if (_isPremium) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter number of free episodes';
                  }
                  final number = int.tryParse(value.trim());
                  if (number == null) {
                    return 'Please enter a valid number';
                  }
                  if (number < 0 || number > Constants.maxFreeEpisodes) {
                    return 'Free episodes must be between 0 and ${Constants.maxFreeEpisodes}';
                  }
                }
                return null;
              },
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
              Icon(
                Icons.settings,
                color: modernTheme.textSecondaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Drama Settings',
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
          SwitchListTile(
            title: Text(
              'Featured Drama',
              style: TextStyle(color: modernTheme.textColor),
            ),
            subtitle: Text(
              'Show in featured section on home page',
              style: TextStyle(color: modernTheme.textSecondaryColor),
            ),
            value: _isFeatured,
            onChanged: (value) => setState(() => _isFeatured = value),
            activeColor: const Color(0xFFFE2C55),
            contentPadding: EdgeInsets.zero,
          ),
          
          // Active toggle
          SwitchListTile(
            title: Text(
              'Active Drama',
              style: TextStyle(color: modernTheme.textColor),
            ),
            subtitle: Text(
              'Visible to users in the app',
              style: TextStyle(color: modernTheme.textSecondaryColor),
            ),
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            activeColor: Colors.green.shade400,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(ModernThemeExtension modernTheme, DramaModel drama) {
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
                Icons.analytics,
                color: modernTheme.textSecondaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Drama Statistics',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  modernTheme,
                  'Episodes',
                  drama.totalEpisodes.toString(),
                  Icons.play_circle_outline,
                  Colors.blue.shade400,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  modernTheme,
                  'Views',
                  _formatCount(drama.viewCount),
                  Icons.visibility,
                  Colors.purple.shade400,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  modernTheme,
                  'Favorites',
                  _formatCount(drama.favoriteCount),
                  Icons.favorite,
                  Colors.red.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ModernThemeExtension modernTheme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ModernThemeExtension modernTheme, DramaModel drama) {
    return Column(
      children: [
        // Save button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isUpdating ? null : _updateDrama,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFE2C55),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isUpdating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Secondary actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  Constants.addEpisodeScreen,
                  arguments: {'dramaId': drama.dramaId},
                ),
                icon: const Icon(Icons.video_library, size: 18),
                label: const Text('Episodes'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFE2C55),
                  side: const BorderSide(color: Color(0xFFFE2C55)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  Constants.dramaDetailsScreen,
                  arguments: {'dramaId': drama.dramaId},
                ),
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('Preview'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: modernTheme.textColor,
                  side: BorderSide(color: modernTheme.textSecondaryColor ?? Colors.grey),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
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

  Future<void> _pickBannerImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _newBannerImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateDrama() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || !currentUser.isVerified) {
      showSnackBar(context, Constants.verifiedOnly);
      return;
    }

    final originalDrama = _originalDrama;
    if (originalDrama == null) return;

    setState(() => _isUpdating = true);

    try {
      final updatedDrama = originalDrama.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        isPremium: _isPremium,
        freeEpisodesCount: _isPremium 
            ? int.tryParse(_freeEpisodesController.text.trim()) ?? 0 
            : 0,
        isFeatured: _isFeatured,
        isActive: _isActive,
        updatedAt: DateTime.now().microsecondsSinceEpoch.toString(),
      );

      final repository = ref.read(dramaRepositoryProvider);
      await repository.updateDrama(updatedDrama, bannerImage: _newBannerImage);

      if (mounted) {
        // Refresh drama data
        ref.invalidate(dramaProvider(widget.dramaId));
        ref.invalidate(userDramasProvider);
        
        showSnackBar(context, 'Drama updated successfully');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to update drama: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}
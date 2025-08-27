// lib/features/dramas/screens/create_drama_screen.dart
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
  File? _bannerImage;

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

    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: modernTheme.surfaceColor,
        elevation: 0,
        title: Text(
          'Create Drama',
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
          if (_isCreating)
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
              onPressed: _createDrama,
              child: const Text(
                'Create',
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
              _buildBannerImageSection(modernTheme),
              const SizedBox(height: 24),
              _buildBasicInfoSection(modernTheme),
              const SizedBox(height: 24),
              _buildPremiumSection(modernTheme),
              const SizedBox(height: 24),
              _buildSettingsSection(modernTheme),
              const SizedBox(height: 32),
              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerImageSection(ModernThemeExtension modernTheme) {
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
            child: _bannerImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _bannerImage!,
                      fit: BoxFit.cover,
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
        if (_bannerImage != null)
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
                  onPressed: () => setState(() => _bannerImage = null),
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
            if (value.trim().length > 100) {
              return 'Title is too long (max 100 characters)';
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
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFFFD700),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Users will pay ${Constants.dramaUnlockCost} coins to unlock all episodes after watching the free ones.',
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

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isCreating ? null : _createDrama,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFE2C55),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isCreating
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Create Drama',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
        _bannerImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _createDrama() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || !currentUser.isAdmin) {
      showSnackBar(context, Constants.adminOnly);
      return;
    }

    setState(() => _isCreating = true);

    try {
      // Validate inputs before creating drama
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      
      if (title.isEmpty || description.isEmpty) {
        throw Exception('Title and description are required');
      }

      // Use the new factory constructor with RFC3339 timestamps
      final drama = DramaModel.create(
        title: title,
        description: description,
        createdBy: currentUser.uid,
        isPremium: _isPremium,
        freeEpisodesCount: _isPremium 
            ? int.tryParse(_freeEpisodesController.text.trim()) ?? 0 
            : 0,
        isFeatured: _isFeatured,
        isActive: _isActive,
        bannerImage: '', // Will be set by repository after upload
      );

      // Validate the drama before sending
      if (!drama.isValidForCreation) {
        final errors = drama.validationErrors.join(', ');
        throw Exception('Drama validation failed: $errors');
      }

      debugPrint('Creating drama with data: $drama');

      final repository = ref.read(dramaRepositoryProvider);
      final dramaId = await repository.createDrama(drama, bannerImage: _bannerImage);

      if (mounted) {
        // Refresh admin dramas list
        ref.invalidate(adminDramasProvider);
        
        showSnackBar(context, Constants.dramaCreated);
        Navigator.of(context).pop();
        
        // Navigate to the created drama details
        Navigator.pushNamed(
          context,
          Constants.dramaDetailsScreen,
          arguments: {'dramaId': dramaId},
        );
      }
    } catch (e) {
      debugPrint('Drama creation failed: $e');
      if (mounted) {
        showSnackBar(context, 'Failed to create drama: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}
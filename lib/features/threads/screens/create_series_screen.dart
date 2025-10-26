// lib/features/threads/screens/create_series_screen.dart
// Comprehensive Series Creation Screen
// Features: Multi-episode upload, pricing, affiliate settings, preview

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/authentication/widgets/login_required_widget.dart';

class EpisodeData {
  final File videoFile;
  final File? thumbnail;
  final int duration; // in seconds
  final String title;
  VideoPlayerController? controller;

  EpisodeData({
    required this.videoFile,
    this.thumbnail,
    required this.duration,
    required this.title,
    this.controller,
  });

  void dispose() {
    controller?.dispose();
  }
}

class CreateSeriesScreen extends ConsumerStatefulWidget {
  const CreateSeriesScreen({super.key});

  @override
  ConsumerState<CreateSeriesScreen> createState() => _CreateSeriesScreenState();
}

class _CreateSeriesScreenState extends ConsumerState<CreateSeriesScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _freeEpisodesController = TextEditingController(text: '1');
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _affiliateCommissionController = TextEditingController(text: '0');

  // Series data
  File? _bannerImage;
  final List<EpisodeData> _episodes = [];
  int _currentPreviewEpisode = 0;

  // Settings
  bool _allowReposts = true;
  bool _hasAffiliateProgram = false;

  // Processing states
  bool _isProcessing = false;
  double _processingProgress = 0.0;
  String _processingStatus = '';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _freeEpisodesController.dispose();
    _tagsController.dispose();
    _affiliateCommissionController.dispose();
    
    for (var episode in _episodes) {
      episode.dispose();
    }
    
    super.dispose();
  }

  Future<void> _pickBannerImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _bannerImage = File(image.path);
        });
      }
    } catch (e) {
      _showError('Failed to pick banner image');
    }
  }

  Future<void> _pickEpisodeVideos() async {
    try {
      final videos = await _picker.pickMultipleMedia(
        limit: 100,
      );

      if (videos.isEmpty) return;

      setState(() {
        _isProcessing = true;
        _processingStatus = 'Processing episodes...';
        _processingProgress = 0.0;
      });

      for (int i = 0; i < videos.length; i++) {
        final videoPath = videos[i].path;
        
        // Check if it's a video
        if (!videoPath.toLowerCase().endsWith('.mp4') &&
            !videoPath.toLowerCase().endsWith('.mov') &&
            !videoPath.toLowerCase().endsWith('.avi')) {
          continue;
        }

        final videoFile = File(videoPath);
        
        // Get video duration
        final controller = VideoPlayerController.file(videoFile);
        await controller.initialize();
        final duration = controller.value.duration.inSeconds;
        
        // Check duration limit (2 minutes = 120 seconds)
        if (duration > 120) {
          await controller.dispose();
          _showError('Episode ${i + 1} exceeds 2 minutes limit');
          continue;
        }

        final episodeData = EpisodeData(
          videoFile: videoFile,
          duration: duration,
          title: 'Episode ${_episodes.length + 1}',
          controller: controller,
        );

        setState(() {
          _episodes.add(episodeData);
          _processingProgress = (i + 1) / videos.length;
        });
      }

      setState(() {
        _isProcessing = false;
        _processingStatus = '';
      });

      if (_episodes.isEmpty) {
        _showError('No valid video episodes found');
      } else {
        _showSuccess('Added ${_episodes.length} episodes');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _processingStatus = '';
      });
      _showError('Failed to pick episodes: $e');
    }
  }

  void _removeEpisode(int index) {
    setState(() {
      final episode = _episodes[index];
      episode.dispose();
      _episodes.removeAt(index);
      
      // Update episode titles
      for (int i = 0; i < _episodes.length; i++) {
        _episodes[i] = EpisodeData(
          videoFile: _episodes[i].videoFile,
          thumbnail: _episodes[i].thumbnail,
          duration: _episodes[i].duration,
          title: 'Episode ${i + 1}',
          controller: _episodes[i].controller,
        );
      }
    });
  }

  Future<bool> _checkUserAuthentication() async {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    
    if (isAuthenticated) {
      return true;
    }
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: const LoginRequiredWidget(
            title: 'Sign In Required',
            subtitle: 'You need to sign in before you can create a series.',
            actionText: 'Sign In',
            icon: Icons.playlist_play,
          ),
        ),
      ),
    );
    
    return result ?? false;
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final isAuthenticated = await _checkUserAuthentication();
      if (!isAuthenticated) {
        return;
      }

      final authProvider = ref.read(authenticationProvider.notifier);
      final currentUser = ref.read(currentUserProvider);

      if (currentUser == null) {
        _showError('User not found. Please try again.');
        return;
      }

      if (_bannerImage == null) {
        _showError('Please select a banner image');
        return;
      }

      if (_episodes.isEmpty) {
        _showError('Please add at least one episode');
        return;
      }

      // Validate pricing
      final price = double.tryParse(_priceController.text) ?? 0.0;
      if (price < 10 || price > 1000) {
        _showError('Price must be between 10 and 1,000 KES');
        return;
      }

      // Validate free episodes count
      final freeEpisodes = int.tryParse(_freeEpisodesController.text) ?? 1;
      if (freeEpisodes < 1 || freeEpisodes > 20) {
        _showError('Free episodes must be between 1 and 20');
        return;
      }

      if (freeEpisodes >= _episodes.length) {
        _showError('Free episodes must be less than total episodes');
        return;
      }

      // Validate affiliate commission
      double affiliateCommission = 0.0;
      if (_hasAffiliateProgram) {
        affiliateCommission = double.tryParse(_affiliateCommissionController.text) ?? 0.0;
        if (affiliateCommission < 0.01 || affiliateCommission > 0.15) {
          _showError('Affiliate commission must be between 1% and 15%');
          return;
        }
      }

      // Parse tags
      List<String> tags = [];
      if (_tagsController.text.isNotEmpty) {
        tags = _tagsController.text.split(',').map((tag) => tag.trim()).toList();
      }

      setState(() {
        _isProcessing = true;
        _processingStatus = 'Creating series...';
        _processingProgress = 0.0;
      });

      // Extract episode data
      final episodeFiles = _episodes.map((e) => e.videoFile).toList();
      final episodeThumbnails = _episodes
          .map((e) => e.thumbnail)
          .where((thumbnail) => thumbnail != null)
          .cast<File>()
          .toList();
      final episodeDurations = _episodes.map((e) => e.duration).toList();

      authProvider.createSeries(
        title: _titleController.text,
        description: _descriptionController.text,
        bannerImage: _bannerImage!,
        episodeVideos: episodeFiles,
        episodeThumbnails: episodeThumbnails.isNotEmpty ? episodeThumbnails : null,
        episodeDurations: episodeDurations,
        unlockPrice: price,
        freeEpisodesCount: freeEpisodes,
        allowReposts: _allowReposts,
        hasAffiliateProgram: _hasAffiliateProgram,
        affiliateCommission: affiliateCommission,
        tags: tags,
        onSuccess: (message) {
          setState(() {
            _isProcessing = false;
            _processingStatus = '';
          });
          _showSuccess(message);
          Navigator.of(context).pop(true);
        },
        onError: (error) {
          setState(() {
            _isProcessing = false;
            _processingStatus = '';
          });
          _showError(error);
        },
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final isUploading = ref.watch(isUploadingProvider);

    if (!isAuthenticated) {
      return Scaffold(
        backgroundColor: modernTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: modernTheme.backgroundColor,
          elevation: 0,
          title: Text(
            'Create Series',
            style: TextStyle(
              color: modernTheme.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: modernTheme.textColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const InlineLoginRequiredWidget(
          title: 'Sign In to Create Series',
          subtitle: 'You need to sign in before you can create a premium series. Join to share your content!',
        ),
      );
    }

    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: modernTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Create Series',
          style: TextStyle(
            color: modernTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: modernTheme.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: (_isProcessing || isUploading) ? null : _submitForm,
            child: Text(
              _isProcessing ? 'Creating...' : 'Create',
              style: TextStyle(
                color: (_isProcessing || isUploading)
                    ? modernTheme.textSecondaryColor
                    : modernTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isProcessing
          ? _buildProcessingOverlay(modernTheme)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Image Section
                    _buildBannerSection(modernTheme),
                    
                    const SizedBox(height: 24),
                    
                    // Episodes Section
                    _buildEpisodesSection(modernTheme),
                    
                    const SizedBox(height: 24),
                    
                    // Basic Info Section
                    _buildBasicInfoSection(modernTheme),
                    
                    const SizedBox(height: 24),
                    
                    // Pricing Section
                    _buildPricingSection(modernTheme),
                    
                    const SizedBox(height: 24),
                    
                    // Settings Section
                    _buildSettingsSection(modernTheme),
                    
                    const SizedBox(height: 24),
                    
                    // Tags Section
                    _buildTagsSection(modernTheme),
                    
                    const SizedBox(height: 32),
                    
                    // Create Button
                    _buildCreateButton(modernTheme, isUploading),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProcessingOverlay(ModernThemeExtension modernTheme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: modernTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              value: _processingProgress,
              color: modernTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              _processingStatus,
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_processingProgress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerSection(ModernThemeExtension modernTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Series Banner *',
          style: TextStyle(
            color: modernTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickBannerImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: modernTheme.borderColor ?? Colors.grey,
              ),
            ),
            child: _bannerImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _bannerImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image,
                        size: 48,
                        color: modernTheme.textSecondaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add banner image',
                        style: TextStyle(
                          color: modernTheme.textSecondaryColor,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Episodes * (${_episodes.length}/100)',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _episodes.length < 100 ? _pickEpisodeVideos : null,
              icon: const Icon(Icons.add),
              label: const Text('Add Episodes'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_episodes.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: modernTheme.borderColor ?? Colors.grey,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.video_library,
                  size: 48,
                  color: modernTheme.textSecondaryColor,
                ),
                const SizedBox(height: 8),
                Text(
                  'No episodes added yet',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Max 2 minutes per episode • 1-100 episodes',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _episodes.length,
            itemBuilder: (context, index) {
              final episode = _episodes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: episode.controller != null &&
                          episode.controller!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: 16 / 9,
                          child: VideoPlayer(episode.controller!),
                        )
                      : Container(
                          width: 80,
                          height: 45,
                          color: Colors.grey,
                          child: const Icon(Icons.video_library),
                        ),
                  title: Text(episode.title),
                  subtitle: Text(
                    '${episode.duration ~/ 60}:${(episode.duration % 60).toString().padLeft(2, '0')}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeEpisode(index),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildBasicInfoSection(ModernThemeExtension modernTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Series Title *',
            labelStyle: TextStyle(color: modernTheme.textSecondaryColor),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: modernTheme.textSecondaryColor!.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: modernTheme.primaryColor!),
            ),
            filled: true,
            fillColor: modernTheme.surfaceColor?.withOpacity(0.3),
          ),
          style: TextStyle(color: modernTheme.textColor),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a title';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Description *',
            labelStyle: TextStyle(color: modernTheme.textSecondaryColor),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: modernTheme.textSecondaryColor!.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: modernTheme.primaryColor!),
            ),
            filled: true,
            fillColor: modernTheme.surfaceColor?.withOpacity(0.3),
          ),
          style: TextStyle(color: modernTheme.textColor),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPricingSection(ModernThemeExtension modernTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pricing',
          style: TextStyle(
            color: modernTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _priceController,
          decoration: InputDecoration(
            labelText: 'Unlock Price (KES) *',
            labelStyle: TextStyle(color: modernTheme.textSecondaryColor),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: modernTheme.textSecondaryColor!.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: modernTheme.primaryColor!),
            ),
            filled: true,
            fillColor: modernTheme.surfaceColor?.withOpacity(0.3),
            hintText: '10 - 1,000 KES',
            prefixIcon: Icon(
              Icons.attach_money,
              color: modernTheme.textSecondaryColor,
            ),
          ),
          style: TextStyle(color: modernTheme.textColor),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a price';
            }
            final price = double.tryParse(value);
            if (price == null || price < 10 || price > 1000) {
              return 'Price must be between 10 and 1,000 KES';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _freeEpisodesController,
          decoration: InputDecoration(
            labelText: 'Free Episodes Count *',
            labelStyle: TextStyle(color: modernTheme.textSecondaryColor),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: modernTheme.textSecondaryColor!.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: modernTheme.primaryColor!),
            ),
            filled: true,
            fillColor: modernTheme.surfaceColor?.withOpacity(0.3),
            hintText: '1 - 20',
            helperText: 'Number of episodes users can watch for free',
          ),
          style: TextStyle(color: modernTheme.textColor),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter free episodes count';
            }
            final count = int.tryParse(value);
            if (count == null || count < 1 || count > 20) {
              return 'Free episodes must be between 1 and 20';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSettingsSection(ModernThemeExtension modernTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: TextStyle(
            color: modernTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: Text(
            'Allow Reposts',
            style: TextStyle(color: modernTheme.textColor),
          ),
          subtitle: Text(
            'Allow users to share your series',
            style: TextStyle(color: modernTheme.textSecondaryColor),
          ),
          value: _allowReposts,
          onChanged: (value) {
            setState(() {
              _allowReposts = value;
              if (!value) {
                _hasAffiliateProgram = false;
              }
            });
          },
        ),
        SwitchListTile(
          title: Text(
            'Enable Affiliate Program',
            style: TextStyle(color: modernTheme.textColor),
          ),
          subtitle: Text(
            'Pay commission to users who promote your series',
            style: TextStyle(color: modernTheme.textSecondaryColor),
          ),
          value: _hasAffiliateProgram,
          onChanged: _allowReposts
              ? (value) {
                  setState(() {
                    _hasAffiliateProgram = value;
                  });
                }
              : null,
        ),
        if (_hasAffiliateProgram) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _affiliateCommissionController,
            decoration: InputDecoration(
              labelText: 'Affiliate Commission (%)',
              labelStyle: TextStyle(color: modernTheme.textSecondaryColor),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: modernTheme.textSecondaryColor!.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: modernTheme.primaryColor!),
              ),
              filled: true,
              fillColor: modernTheme.surfaceColor?.withOpacity(0.3),
              hintText: '1 - 15%',
              helperText: 'Percentage of unlock price paid to affiliates',
            ),
            style: TextStyle(color: modernTheme.textColor),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter commission percentage';
              }
              final commission = double.tryParse(value);
              if (commission == null || commission < 1 || commission > 15) {
                return 'Commission must be between 1% and 15%';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildTagsSection(ModernThemeExtension modernTheme) {
    return TextFormField(
      controller: _tagsController,
      decoration: InputDecoration(
        labelText: 'Tags (Comma separated, Optional)',
        labelStyle: TextStyle(color: modernTheme.textSecondaryColor),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: modernTheme.textSecondaryColor!.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: modernTheme.primaryColor!),
        ),
        filled: true,
        fillColor: modernTheme.surfaceColor?.withOpacity(0.3),
        hintText: 'e.g. drama, comedy, action',
      ),
      style: TextStyle(color: modernTheme.textColor),
    );
  }

  Widget _buildCreateButton(ModernThemeExtension modernTheme, bool isUploading) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isProcessing || isUploading) ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: modernTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          disabledBackgroundColor: modernTheme.primaryColor!.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _isProcessing ? 'Creating Series...' : 'Create Series',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
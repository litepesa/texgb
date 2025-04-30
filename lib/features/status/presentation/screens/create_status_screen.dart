import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import '../../domain/models/status_privacy.dart';
import '../../application/providers/status_providers.dart';
import '../widgets/status_privacy_selector.dart';
import '../widgets/media_grid_view.dart';
import '../../../../shared/utilities/global_methods.dart';

class CreateStatusScreen extends ConsumerStatefulWidget {
  const CreateStatusScreen({Key? key}) : super(key: key);
  
  @override
  ConsumerState<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends ConsumerState<CreateStatusScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  bool _isLoading = false;
  
  // Media state
  final List<AssetEntity> _recentMedia = [];
  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _requestPermissionsAndLoadMedia();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _contentController.dispose();
    _linkController.dispose();
    if (_videoController != null) {
      _videoController!.dispose();
    }
    super.dispose();
  }
  
  Future<void> _requestPermissionsAndLoadMedia() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Request permissions
      final permissionStatus = await Permission.photos.request();
      
      if (permissionStatus.isGranted) {
        // Load recent media
        await _loadRecentMedia();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permission to access media was denied.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: openAppSettings,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading media: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadRecentMedia() async {
    try {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.all,
        hasAll: true,
      );
      
      if (albums.isNotEmpty) {
        final recentAlbum = albums.first;
        final media = await recentAlbum.getAssetListRange(
          start: 0,
          end: 100,
        );
        
        if (mounted) {
          setState(() {
            _recentMedia.addAll(media);
          });
        }
      }
    } catch (e) {
      print('Error loading recent media: $e');
    }
  }
  
  Future<void> _selectImageFromCamera() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      ref.read(selectedMediaProvider.notifier).setMedia([file]);
    }
  }
  
  Future<void> _selectVideoFromCamera() async {
    final pickedFile = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 60),
    );
    
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      
      // Check file size
      final fileSize = await file.length();
      final fileSizeInMB = fileSize / (1024 * 1024);
      
      if (fileSizeInMB > 100) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video size too large. Maximum allowed is 100MB.'),
            ),
          );
        }
        return;
      }
      
      ref.read(selectedMediaProvider.notifier).setMedia([file]);
      
      // Preview the video
      await _initializeVideoController(file);
    }
  }
  
  Future<void> _selectMediaFromGallery(AssetEntity asset) async {
    try {
      final file = await asset.file;
      if (file == null) return;
      
      // Check file size
      final fileSize = await file.length();
      final fileSizeInMB = fileSize / (1024 * 1024);
      
      if (asset.type == AssetType.video) {
        if (fileSizeInMB > 100) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video size too large. Maximum allowed is 100MB.'),
              ),
            );
          }
          return;
        }
        
        if (asset.duration > 60) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video too long. Maximum duration is 60 seconds.'),
              ),
            );
          }
          return;
        }
      } else if (fileSizeInMB > 20) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image size too large. Maximum allowed is 20MB.'),
            ),
          );
        }
        return;
      }
      
      ref.read(selectedMediaProvider.notifier).setMedia([file]);
      
      // Preview the video if it's a video
      if (asset.type == AssetType.video) {
        await _initializeVideoController(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting media: $e')),
        );
      }
    }
  }
  
  Future<void> _initializeVideoController(File file) async {
    if (_videoController != null) {
      await _videoController!.dispose();
      _videoController = null;
      _isVideoInitialized = false;
    }
    
    _videoController = VideoPlayerController.file(file);
    
    try {
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
    }
  }
  
  Future<void> _createStatus() async {
    final currentUser = await ref.read(userProvider.future);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to create a status'),
        ),
      );
      return;
    }
    
    // Check if content is empty on Text tab
    if (_tabController.index == 1 && _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some text content'),
        ),
      );
      return;
    }
    
    // Check if link is empty on Link tab
    if (_tabController.index == 2 && _linkController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid URL'),
        ),
      );
      return;
    }
    
    // Check if user has posted today
    final hasPostedResult = await ref.read(statusControllerProvider)
        .hasUserPostedRecently(currentUser.uid);
    
    final hasPosted = hasPostedResult.fold(
      (failure) => false,
      (result) => result,
    );
    
    if (hasPosted) {
      if (!mounted) return;
      
      // Allow but warn user
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Post Another Status?'),
          content: const Text(
            'You have already posted a status today. Posting multiple statuses '
            'in one day may reduce their visibility in your contacts\' feeds.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Post Anyway'),
            ),
          ],
        ),
      ) ?? false;
      
      if (!shouldContinue) return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get the privacy settings
      final privacy = ref.read(statusPrivacyProvider);
      
      // Handle based on the active tab
      if (_tabController.index == 0) {
        // Media tab
        final mediaFiles = ref.read(selectedMediaProvider);
        if (mediaFiles.isEmpty) {
          throw Exception('Please select at least one photo or video');
        }
        
        await ref.read(statusControllerProvider).createStatusPost(
          authorId: currentUser.uid,
          authorName: currentUser.name,
          authorImage: currentUser.image,
          content: _contentController.text.trim(),
          privacy: privacy,
          mediaFiles: mediaFiles,
        );
      } else if (_tabController.index == 1) {
        // Text tab
        await ref.read(statusControllerProvider).createStatusPost(
          authorId: currentUser.uid,
          authorName: currentUser.name,
          authorImage: currentUser.image,
          content: _contentController.text.trim(),
          privacy: privacy,
        );
      } else if (_tabController.index == 2) {
        // Link tab
        final linkUrl = _linkController.text.trim();
        
        // Ensure URL has a protocol
        final url = linkUrl.startsWith('http://') || linkUrl.startsWith('https://') 
            ? linkUrl 
            : 'https://$linkUrl';
            
        await ref.read(statusControllerProvider).createStatusPost(
          authorId: currentUser.uid,
          authorName: currentUser.name,
          authorImage: currentUser.image,
          content: _contentController.text.trim(),
          privacy: privacy,
          linkUrl: url,
        );
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _showPrivacySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const StatusPrivacySelector(),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedMedia = ref.watch(selectedMediaProvider);
    final privacySettings = ref.watch(statusPrivacyProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Status'),
        actions: [
          // Privacy selector button
          TextButton.icon(
            onPressed: _showPrivacySelector,
            icon: Icon(_getPrivacyIcon(privacySettings.type)),
            label: Text(
              _getPrivacyLabel(privacySettings),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.photo_library), text: 'Media'),
            Tab(icon: Icon(Icons.text_fields), text: 'Text'),
            Tab(icon: Icon(Icons.link), text: 'Link'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMediaTab(selectedMedia),
                _buildTextTab(),
                _buildLinkTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _createStatus,
        icon: const Icon(Icons.send),
        label: const Text('Post Status'),
      ),
    );
  }
  
  Widget _buildMediaTab(List<File> selectedMedia) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Camera buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _selectImageFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _selectVideoFromCamera,
                icon: const Icon(Icons.videocam),
                label: const Text('Record Video'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        
        // Selected media preview
        if (selectedMedia.isNotEmpty) ...[
          _buildSelectedMediaPreview(selectedMedia.first),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'Add a caption...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ),
        ],
        
        // Recent media grid
        if (selectedMedia.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Recent Media',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          Expanded(
            child: _recentMedia.isEmpty
                ? const Center(child: Text('No recent media found'))
                : MediaGridView(
                    mediaItems: _recentMedia,
                    onTap: _selectMediaFromGallery,
                  ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildSelectedMediaPreview(File file) {
    final isVideo = file.path.toLowerCase().endsWith('.mp4') || 
                    file.path.toLowerCase().endsWith('.mov');
    
    return Container(
      height: 300,
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: isVideo && _isVideoInitialized && _videoController != null
                ? AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  )
                : Image.file(
                    file,
                    fit: BoxFit.contain,
                  ),
          ),
          
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                ref.read(selectedMediaProvider.notifier).clearMedia();
                
                if (_videoController != null) {
                  _videoController!.pause();
                  _videoController!.dispose();
                  _videoController = null;
                  _isVideoInitialized = false;
                }
              },
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
              ),
            ),
          ),
          
          if (isVideo && _isVideoInitialized && _videoController != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: IconButton(
                icon: Icon(
                  _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                  setState(() {});
                },
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildTextTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
              hintText: 'What\'s on your mind?',
              border: InputBorder.none,
            ),
            maxLines: 10,
            maxLength: 500,
            autofocus: true,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Your text status will be visible to ${_getPrivacyLabel(ref.read(statusPrivacyProvider))}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLinkTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _linkController,
            decoration: const InputDecoration(
              labelText: 'Link URL',
              hintText: 'https://example.com',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
            keyboardType: TextInputType.url,
          ),
          
          const SizedBox(height: 24),
          
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: 'Add a comment (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          
          const SizedBox(height: 24),
          
          if (_linkController.text.isNotEmpty)
            _buildLinkPreview(_linkController.text),
        ],
      ),
    );
  }
  
  Widget _buildLinkPreview(String url) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Link Preview',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            url,
            style: const TextStyle(color: Colors.blue),
          ),
          const SizedBox(height: 16),
          const Text(
            'Link preview will be generated when you post.',
            style: TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getPrivacyIcon(PrivacyType type) {
    switch (type) {
      case PrivacyType.allContacts:
        return Icons.people;
      case PrivacyType.except:
        return Icons.people_outline;
      case PrivacyType.onlySpecific:
        return Icons.person;
    }
  }
  
  String _getPrivacyLabel(StatusPrivacy privacy) {
    switch (privacy.type) {
      case PrivacyType.allContacts:
        return 'All Contacts';
      case PrivacyType.except:
        final count = privacy.excludedUserIds.length;
        return count > 0
            ? 'All contacts except $count ${count == 1 ? 'person' : 'people'}'
            : 'All Contacts';
      case PrivacyType.onlySpecific:
        final count = privacy.includedUserIds.length;
        return count > 0
            ? 'Only $count ${count == 1 ? 'person' : 'people'}'
            : 'Only Specific Contacts';
    }
  }
}
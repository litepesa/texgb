// lib/features/status/screens/create_status_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/features/status/widgets/privacy_selector.dart';

class CreateStatusScreen extends StatefulWidget {
  const CreateStatusScreen({Key? key}) : super(key: key);

  @override
  State<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends State<CreateStatusScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Shared state
  final TextEditingController _captionController = TextEditingController();
  StatusPrivacyType _privacyType = StatusPrivacyType.all_contacts;
  List<String> _includedContactUIDs = [];
  List<String> _excludedContactUIDs = [];
  bool _isLoading = false;
  bool _isFullscreenPreview = false;
  
  // Media tab state
  File? _selectedMedia;
  List<AssetEntity> _recentMedia = [];
  List<AssetEntity> _filteredMedia = [];
  StatusType _mediaType = StatusType.image;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  MediaFilter _currentMediaFilter = MediaFilter.all;
  
  // Text tab state
  Color _selectedColor = Colors.blue;
  String? _selectedFont;
  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];
  
  final List<String?> _fontOptions = [
    null, // Default
    'Roboto',
    'OpenSans',
    'Lato',
    'Montserrat',
  ];
  
  // Link tab state
  final TextEditingController _linkController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _requestPermissionsAndLoadMedia();
  }
  
  @override
  void dispose() {
    _captionController.dispose();
    _linkController.dispose();
    if (_videoController != null) {
      _videoController!.pause();
      _videoController!.dispose();
    }
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _requestPermissionsAndLoadMedia() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.photos,
        Permission.videos,
        Permission.mediaLibrary, // iOS
      ].request();

      bool hasMediaPermission = statuses[Permission.photos]?.isGranted == true ||
                                 statuses[Permission.videos]?.isGranted == true ||
                                 statuses[Permission.mediaLibrary]?.isGranted == true;

      if (hasMediaPermission) {
        await _loadRecentMedia();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission to access media was denied. Please enable in settings.'),
              duration: Duration(seconds: 3),
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
          SnackBar(
            content: Text('Error requesting permissions: ${e.toString()}'),
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
            _recentMedia = media;
            _applyMediaFilter(_currentMediaFilter);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading media: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _applyMediaFilter(MediaFilter filter) {
    setState(() {
      _currentMediaFilter = filter;
      
      switch (filter) {
        case MediaFilter.photos:
          _filteredMedia = _recentMedia.where((asset) => asset.type == AssetType.image).toList();
          break;
        case MediaFilter.videos:
          _filteredMedia = _recentMedia.where((asset) => asset.type == AssetType.video).toList();
          break;
        case MediaFilter.all:
        default:
          _filteredMedia = _recentMedia;
          break;
      }
    });
  }
  
  Future<void> _selectFromGallery(AssetEntity asset) async {
    try {
      final file = await asset.file;
      if (file == null) return;
      
      final sizeInMB = await file.length() / (1024 * 1024);
      final isVideo = asset.type == AssetType.video;
      
      if (isVideo && sizeInMB > 30) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video size too large. Maximum allowed is 30MB.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      } else if (!isVideo && sizeInMB > 10) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image size too large. Maximum allowed is 10MB.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      if (isVideo && asset.duration > 60) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video too long. Maximum duration is 60 seconds.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      if (_selectedMedia != null || _videoController != null) {
        _removeMedia();
      }
      
      if (isVideo) {
        await _initializeVideoController(file);
        setState(() {
          _mediaType = StatusType.video;
          _selectedMedia = file;
          _isFullscreenPreview = true;
        });
      } else {
        setState(() {
          _mediaType = StatusType.image;
          _selectedMedia = file;
          _isFullscreenPreview = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting media: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
      await _videoController!.play();
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing video: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _removeMedia() {
    if (_videoController != null) {
      _videoController!.pause();
      _videoController!.dispose();
      _videoController = null;
      _isVideoInitialized = false;
    }
    
    setState(() {
      _selectedMedia = null;
      _isFullscreenPreview = false;
    });
  }
  
  void _toggleFullscreenPreview() {
    if (_selectedMedia != null) {
      setState(() {
        _isFullscreenPreview = !_isFullscreenPreview;
      });
    }
  }
  
  void _showPrivacyOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PrivacySelector(
        initialPrivacyType: _privacyType,
        includedContactUIDs: _includedContactUIDs,
        excludedContactUIDs: _excludedContactUIDs,
        onSaved: (privacyType, includedUIDs, excludedUIDs) {
          setState(() {
            _privacyType = privacyType;
            _includedContactUIDs = includedUIDs;
            _excludedContactUIDs = excludedUIDs;
          });
        },
      ),
    );
  }
  
  Future<void> _createStatus() async {
    final currentUser = Provider.of<AuthenticationProvider>(context, listen: false).userModel;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to create a status'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final statusProvider = Provider.of<StatusProvider>(context, listen: false);
    
    final hasPostedToday = await statusProvider.hasUserPostedToday(currentUser.uid);
    
    if (hasPostedToday) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only post one status per day'),
          backgroundColor: Colors.amber,
        ),
      );
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final activeTab = _tabController.index;
      
      if (activeTab == 0) {
        if (_selectedMedia == null) {
          throw Exception('Please select a photo or video');
        }
        
        await statusProvider.createMediaStatus(
          uid: currentUser.uid,
          username: currentUser.name,
          userImage: currentUser.image,
          mediaFiles: [_selectedMedia!],
          type: _mediaType,
          caption: _captionController.text.trim(),
          privacyType: _privacyType,
          includedContactUIDs: _includedContactUIDs,
          excludedContactUIDs: _excludedContactUIDs,
        );
      } else if (activeTab == 1) {
        if (_captionController.text.trim().isEmpty) {
          throw Exception('Please enter some text');
        }
        
        await statusProvider.createTextStatus(
          uid: currentUser.uid,
          username: currentUser.name,
          userImage: currentUser.image,
          text: _captionController.text.trim(),
          backgroundColor: _selectedColor,
          fontName: _selectedFont,
          privacyType: _privacyType,
          includedContactUIDs: _includedContactUIDs,
          excludedContactUIDs: _excludedContactUIDs,
        );
      } else if (activeTab == 2) {
        if (_linkController.text.trim().isEmpty) {
          throw Exception('Please enter a valid URL');
        }
        
        final url = _linkController.text.trim();
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          throw Exception('Please enter a valid URL starting with http:// or https://');
        }
        
        await statusProvider.createLinkStatus(
          uid: currentUser.uid,
          username: currentUser.name,
          userImage: currentUser.image,
          linkUrl: url,
          caption: _captionController.text.trim(),
          privacyType: _privacyType,
          includedContactUIDs: _includedContactUIDs,
          excludedContactUIDs: _excludedContactUIDs,
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
            content: Text('Error creating status: ${e.toString()}'),
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
  
  String _getPrivacyText() {
    switch (_privacyType) {
      case StatusPrivacyType.except:
        final count = _excludedContactUIDs.length;
        return 'My contacts except $count ${count == 1 ? 'person' : 'people'}';
      case StatusPrivacyType.only:
        final count = _includedContactUIDs.length;
        return 'Only $count ${count == 1 ? 'person' : 'people'}';
      case StatusPrivacyType.all_contacts:
      default:
        return 'Privacy';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Status'),
        actions: [
          TextButton.icon(
            onPressed: _showPrivacyOptions,
            icon: Icon(
              _privacyType == StatusPrivacyType.all_contacts ? Icons.people : 
              _privacyType == StatusPrivacyType.except ? Icons.person_remove :
              Icons.person_add,
            ),
            label: Text(_getPrivacyText()),
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
          ? Center(child: CircularProgressIndicator(color: modernTheme.primaryColor))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMediaTab(),
                _buildTextTab(),
                _buildLinkTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 0 && _selectedMedia != null && !_isFullscreenPreview
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : _createStatus,
              icon: const Icon(Icons.send),
              label: const Text('Post Status'),
            )
          : _tabController.index != 0
              ? FloatingActionButton.extended(
                  onPressed: _isLoading ? null : _createStatus,
                  icon: const Icon(Icons.send),
                  label: const Text('Post Status'),
                )
              : null,
    );
  }
  
  Widget _buildMediaTab() {
    if (_isFullscreenPreview && _selectedMedia != null) {
      return _buildFullscreenPreview();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterButton(
                    label: "All",
                    icon: Icons.perm_media,
                    filter: MediaFilter.all,
                  ),
                ),
                Expanded(
                  child: _buildFilterButton(
                    label: "Photos",
                    icon: Icons.photo,
                    filter: MediaFilter.photos,
                  ),
                ),
                Expanded(
                  child: _buildFilterButton(
                    label: "Videos",
                    icon: Icons.videocam,
                    filter: MediaFilter.videos,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        if (_selectedMedia != null) ...[
          GestureDetector(
            onTap: _toggleFullscreenPreview,
            child: Container(
              height: 300,
              width: double.infinity,
              color: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: _mediaType == StatusType.video && _isVideoInitialized && _videoController != null
                        ? AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          )
                        : Image.file(
                            _selectedMedia!,
                            fit: BoxFit.contain,
                          ),
                  ),
                  
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _removeMedia,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ),
                  
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.fullscreen, color: Colors.white),
                      onPressed: _toggleFullscreenPreview,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                hintText: 'Add a caption...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ),
        ],
        
        Expanded(
          child: _filteredMedia.isEmpty
              ? Center(
                  child: Text(
                    'No ${_currentMediaFilter == MediaFilter.photos ? 'photos' : _currentMediaFilter == MediaFilter.videos ? 'videos' : 'media'} found',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _filteredMedia.length,
                  itemBuilder: (context, index) {
                    final asset = _filteredMedia[index];
                    return GestureDetector(
                      onTap: () => _selectFromGallery(asset),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          FutureBuilder<Uint8List?>(
                            future: asset.thumbnailData,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                );
                              }
                              return Container(
                                color: Colors.grey[300],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: context.modernTheme.primaryColor,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          if (asset.type == AssetType.video)
                            Positioned(
                              right: 5,
                              bottom: 5,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _formatDuration(asset.duration),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
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
  
  Widget _buildFullscreenPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: Colors.black,
          child: _mediaType == StatusType.video && _isVideoInitialized && _videoController != null
              ? Center(
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                )
              : Center(
                  child: Image.file(
                    _selectedMedia!,
                    fit: BoxFit.contain,
                  ),
                ),
        ),
        
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black54,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => setState(() {
                    _isFullscreenPreview = false;
                  }),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: _removeMedia,
                    ),
                    if (_mediaType == StatusType.video && _videoController != null)
                      IconButton(
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
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black54,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _captionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Add a caption...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white24,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _createStatus,
                  icon: const Icon(Icons.send),
                  label: const Text('Post Status'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.modernTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFilterButton({
    required String label,
    required IconData icon,
    required MediaFilter filter,
  }) {
    final isSelected = _currentMediaFilter == filter;
    final modernTheme = context.modernTheme;
    
    return GestureDetector(
      onTap: () => _applyMediaFilter(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? modernTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black54,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTextTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 300,
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _selectedColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: TextField(
                controller: _captionController,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: _selectedFont,
                ),
                decoration: InputDecoration(
                  hintText: 'Type your status here...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: _selectedFont,
                  ),
                  border: InputBorder.none,
                ),
                maxLines: 6,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Background Color',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _colorOptions.map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == color 
                            ? Colors.white 
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Font Style',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _fontOptions.map((font) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFont = font;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedFont == font 
                          ? context.modernTheme.primaryColor 
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      font ?? 'Default',
                      style: TextStyle(
                        fontFamily: font,
                        fontWeight: FontWeight.bold,
                        color: _selectedFont == font ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
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
              labelText: 'Enter URL',
              hintText: 'https://example.com',
              prefixIcon: Icon(Icons.link),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          
          const SizedBox(height: 24),
          
          TextField(
            controller: _captionController,
            decoration: const InputDecoration(
              labelText: 'Add a caption (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          
          const SizedBox(height: 24),
          
          if (_linkController.text.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
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
                    _linkController.text,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preview will be generated when you post the status',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

enum MediaFilter {
  all,
  photos,
  videos,
}
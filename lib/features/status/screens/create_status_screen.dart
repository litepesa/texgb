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
  
  // Media tab state
  File? _selectedMedia;
  List<AssetEntity> _recentMedia = [];
  StatusType _mediaType = StatusType.image;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  
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
  
  // Request permissions and load media
  Future<void> _requestPermissionsAndLoadMedia() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Request storage permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.photos,
        Permission.videos,
      ].request();
      
      // Check if we have permission to access photos and videos
      bool hasMediaPermission = statuses[Permission.photos]!.isGranted || 
                              statuses[Permission.storage]!.isGranted ||
                              statuses[Permission.videos]!.isGranted;
      
      if (hasMediaPermission) {
        // Load media using photo_manager
        await _loadRecentMedia();
      } else {
        // Show instructions if permissions were denied
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
  
  // Load recent media from device gallery
  Future<void> _loadRecentMedia() async {
    try {
      // Get recent media (both images and videos)
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        hasAll: true,
      );
      
      if (albums.isNotEmpty) {
        final recentAlbum = albums.first;
        final media = await recentAlbum.getAssetListRange(
          start: 0,
          end: 50, // Get 50 recent media files
        );
        
        if (mounted) {
          setState(() {
            _recentMedia = media;
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
  
  // Select media from gallery
  Future<void> _selectFromGallery(AssetEntity asset) async {
    try {
      final file = await asset.file;
      if (file == null) return;
      
      // Check file size (10MB limit for images, 30MB for videos)
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
      
      // Check video duration (60 seconds limit)
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
      
      // Clear previous media selection
      if (_selectedMedia != null || _videoController != null) {
        _removeMedia();
      }
      
      // Initialize video controller if needed
      if (isVideo) {
        await _initializeVideoController(file);
        setState(() {
          _mediaType = StatusType.video;
          _selectedMedia = file;
        });
      } else {
        setState(() {
          _mediaType = StatusType.image;
          _selectedMedia = file;
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
  
  // Initialize video controller
  Future<void> _initializeVideoController(File file) async {
    // Reset any existing controller
    if (_videoController != null) {
      await _videoController!.dispose();
      _videoController = null;
      _isVideoInitialized = false;
    }
    
    // Create new controller
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
  
  // Remove media from selection
  void _removeMedia() {
    if (_videoController != null) {
      _videoController!.pause();
      _videoController!.dispose();
      _videoController = null;
      _isVideoInitialized = false;
    }
    
    setState(() {
      _selectedMedia = null;
    });
  }
  
  // Toggle privacy settings
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
  
  // Upload status
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
    
    // Check if user can post today
    final hasPostedToday = await statusProvider.hasUserPostedToday(currentUser.uid);
    
    if (hasPostedToday) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only post one status per day'),
          backgroundColor: Colors.amber,
        ),
      );
      // Continue anyway for demo purposes
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Determine which tab is active
      final activeTab = _tabController.index;
      
      if (activeTab == 0) {
        // Media tab
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
        // Text tab
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
        // Link tab
        if (_linkController.text.trim().isEmpty) {
          throw Exception('Please enter a valid URL');
        }
        
        // Basic URL validation
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
        return 'My contacts';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Status'),
        actions: [
          // Privacy settings button
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
                // Media tab
                _buildMediaTab(),
                
                // Text tab
                _buildTextTab(),
                
                // Link tab
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
  
  Widget _buildMediaTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Media preview section
        if (_selectedMedia != null) ...[
          Container(
            height: 300,
            width: double.infinity,
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Media preview
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
                
                // Remove button
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
              ],
            ),
          ),
          
          // Caption input
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
        
        // Gallery section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Select from Gallery',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              
              // Grid of recent media
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _recentMedia.length,
                  itemBuilder: (context, index) {
                    final asset = _recentMedia[index];
                    return GestureDetector(
                      onTap: () => _selectFromGallery(asset),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Thumbnail
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
                          
                          // Video indicator
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
          ),
        ),
      ],
    );
  }
  
  Widget _buildTextTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text preview section
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
          
          // Color options
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
          
          // Font options
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
          // Link URL input
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
          
          // Caption input
          TextField(
            controller: _captionController,
            decoration: const InputDecoration(
              labelText: 'Add a caption (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          
          const SizedBox(height: 24),
          
          // Link preview
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
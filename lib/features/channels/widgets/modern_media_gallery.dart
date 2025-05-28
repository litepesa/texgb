// lib/features/channels/widgets/modern_media_gallery.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/screens/create_channel_post_screen.dart';

class ModernMediaGallery extends StatefulWidget {
  const ModernMediaGallery({Key? key}) : super(key: key);

  @override
  State<ModernMediaGallery> createState() => _ModernMediaGalleryState();
}

class _ModernMediaGalleryState extends State<ModernMediaGallery>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _gridAnimController;
  late AnimationController _selectionAnimController;
  
  // Gallery state
  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _currentAlbum;
  List<AssetEntity> _mediaAssets = [];
  Set<String> _selectedAssets = {};
  bool _isLoading = true;
  int _currentPage = 0;
  final int _pageSize = 30;
  bool _hasMore = true;
  
  // UI state
  final ScrollController _scrollController = ScrollController();
  MediaType _filterType = MediaType.none; // all, image, video
  bool _isSelectionMode = false;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAlbums();
    _scrollController.addListener(_scrollListener);
  }
  
  void _initializeAnimations() {
    _gridAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _selectionAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _gridAnimController.forward();
  }
  
  Future<void> _loadAlbums() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      Navigator.of(context).pop();
      return;
    }
    
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
    );
    
    setState(() {
      _albums = albums;
      if (albums.isNotEmpty) {
        _currentAlbum = albums.first;
        _loadAssets();
      }
    });
  }
  
  Future<void> _loadAssets({bool refresh = false}) async {
    if (_currentAlbum == null) return;
    
    if (refresh) {
      _currentPage = 0;
      _mediaAssets.clear();
      _hasMore = true;
    }
    
    setState(() => _isLoading = true);
    
    RequestType requestType = RequestType.common;
    if (_filterType == MediaType.image) {
      requestType = RequestType.image;
    } else if (_filterType == MediaType.video) {
      requestType = RequestType.video;
    }
    
    final assets = await _currentAlbum!.getAssetListPaged(
      page: _currentPage,
      size: _pageSize,
    );
    
    setState(() {
      _mediaAssets.addAll(assets);
      _currentPage++;
      _hasMore = assets.length == _pageSize;
      _isLoading = false;
    });
  }
  
  void _scrollListener() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadAssets();
      }
    }
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    _gridAnimController.dispose();
    _selectionAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(modernTheme),
                
                // Filter tabs
                _buildFilterTabs(modernTheme),
                
                // Media grid
                Expanded(
                  child: _buildMediaGrid(modernTheme),
                ),
              ],
            ),
          ),
          
          // Selection bar
          if (_selectedAssets.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildSelectionBar(modernTheme),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, color: modernTheme.textColor),
          ),
          
          // Album selector
          Expanded(
            child: GestureDetector(
              onTap: _showAlbumPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: modernTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.photo_album,
                      color: modernTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentAlbum?.name ?? 'All Photos',
                        style: TextStyle(
                          color: modernTheme.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: modernTheme.textSecondaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Selection mode toggle
          if (_filterType == MediaType.image)
            IconButton(
              onPressed: () {
                setState(() {
                  _isSelectionMode = !_isSelectionMode;
                  if (!_isSelectionMode) {
                    _selectedAssets.clear();
                  }
                });
                _selectionAnimController.forward();
              },
              icon: Icon(
                _isSelectionMode ? Icons.close : Icons.check_circle_outline,
                color: modernTheme.primaryColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterTab('All', MediaType.none, modernTheme),
          const SizedBox(width: 12),
          _buildFilterTab('Photos', MediaType.image, modernTheme),
          const SizedBox(width: 12),
          _buildFilterTab('Videos', MediaType.video, modernTheme),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, MediaType type, ModernThemeExtension modernTheme) {
    final isSelected = _filterType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterType = type;
          _selectedAssets.clear();
          _isSelectionMode = false;
        });
        _loadAssets(refresh: true);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? modernTheme.primaryColor : modernTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : modernTheme.textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMediaGrid(ModernThemeExtension modernTheme) {
    if (_mediaAssets.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: modernTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No media found',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _mediaAssets.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _mediaAssets.length) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        return _buildMediaItem(_mediaAssets[index], index, modernTheme);
      },
    );
  }

  Widget _buildMediaItem(AssetEntity asset, int index, ModernThemeExtension modernTheme) {
    final isSelected = _selectedAssets.contains(asset.id);
    final selectionIndex = _selectedAssets.toList().indexOf(asset.id);
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index % 10) * 50),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: GestureDetector(
              onTap: () => _handleAssetTap(asset),
              onLongPress: () => _handleAssetLongPress(asset),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Thumbnail
                  Hero(
                    tag: 'media_${asset.id}',
                    child: FutureBuilder<Uint8List?>(
                      future: asset.thumbnailDataWithSize(
                        const ThumbnailSize(400, 400),
                        quality: 95,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                          );
                        }
                        return Container(
                          color: modernTheme.surfaceColor,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Selection overlay
                  if (isSelected)
                    Container(
                      color: modernTheme.primaryColor!.withOpacity(0.3),
                      child: Center(
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: modernTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${selectionIndex + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Media type indicator
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        asset.type == AssetType.video ? Icons.videocam : Icons.photo,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  
                  // Duration for videos
                  if (asset.type == AssetType.video)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatDuration(asset.duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectionBar(ModernThemeExtension modernTheme) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: modernTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '${_selectedAssets.length} selected',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedAssets.clear();
              });
            },
            child: Text(
              'Clear',
              style: TextStyle(color: modernTheme.textSecondaryColor),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _handleSelection,
            style: ElevatedButton.styleFrom(
              backgroundColor: modernTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Select',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  
  void _showAlbumPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final modernTheme = context.modernTheme;
        return Container(
          decoration: BoxDecoration(
            color: modernTheme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: modernTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _albums.length,
                  itemBuilder: (context, index) {
                    final album = _albums[index];
                    return ListTile(
                      leading: FutureBuilder<int>(
                        future: album.assetCountAsync,
                        builder: (context, snapshot) {
                          return Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: modernTheme.primaryColor!.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.photo_album,
                              color: modernTheme.primaryColor,
                            ),
                          );
                        },
                      ),
                      title: Text(
                        album.name,
                        style: TextStyle(color: modernTheme.textColor),
                      ),
                      subtitle: FutureBuilder<int>(
                        future: album.assetCountAsync,
                        builder: (context, snapshot) {
                          return Text(
                            '${snapshot.data ?? 0} items',
                            style: TextStyle(color: modernTheme.textSecondaryColor),
                          );
                        },
                      ),
                      selected: album == _currentAlbum,
                      onTap: () {
                        setState(() {
                          _currentAlbum = album;
                        });
                        Navigator.pop(context);
                        _loadAssets(refresh: true);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _handleAssetTap(AssetEntity asset) async {
    if (_isSelectionMode) {
      // Multi-selection mode for images
      if (asset.type == AssetType.image) {
        setState(() {
          if (_selectedAssets.contains(asset.id)) {
            _selectedAssets.remove(asset.id);
          } else if (_selectedAssets.length < 10) {
            _selectedAssets.add(asset.id);
          } else {
            _showError('Maximum 10 images allowed');
          }
        });
      }
    } else {
      // Single selection
      final file = await asset.file;
      if (file == null) return;
      
      if (asset.type == AssetType.video) {
        // Check video duration
        if (asset.duration > 300) { // 5 minutes
          _showError('Please select a video less than 5 minutes');
          return;
        }
        
        Navigator.of(context).pop(
          MediaResult(
            file: file,
            isVideo: true,
          ),
        );
      } else {
        // Single image selection
        Navigator.of(context).pop(
          MediaResult(
            file: file,
            isVideo: false,
            images: [file],
          ),
        );
      }
    }
  }
  
  void _handleAssetLongPress(AssetEntity asset) {
    if (asset.type == AssetType.image && !_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedAssets.add(asset.id);
      });
      HapticFeedback.mediumImpact();
    }
  }
  
  Future<void> _handleSelection() async {
    if (_selectedAssets.isEmpty) return;
    
    final List<File> files = [];
    for (final assetId in _selectedAssets) {
      final asset = _mediaAssets.firstWhere((a) => a.id == assetId);
      final file = await asset.file;
      if (file != null) {
        files.add(file);
      }
    }
    
    Navigator.of(context).pop(
      MediaResult(
        file: files.first,
        isVideo: false,
        images: files,
      ),
    );
  }
  
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
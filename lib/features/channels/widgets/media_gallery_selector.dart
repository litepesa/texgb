// lib/features/channels/widgets/media_gallery_selector.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class MediaGallerySelector extends StatefulWidget {
  final bool isVideoMode;
  final Function(List<File> files) onFilesSelected;
  final int maxImages;
  final Duration maxVideoDuration;

  const MediaGallerySelector({
    Key? key,
    required this.isVideoMode,
    required this.onFilesSelected,
    this.maxImages = 10,
    this.maxVideoDuration = const Duration(minutes: 5),
  }) : super(key: key);

  @override
  State<MediaGallerySelector> createState() => _MediaGallerySelectorState();
}

class _MediaGallerySelectorState extends State<MediaGallerySelector>
    with SingleTickerProviderStateMixin {
  // Controllers
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  // Gallery state
  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _currentAlbum;
  List<AssetEntity> _assets = [];
  Map<String, File> _cachedFiles = {};
  Set<String> _selectedAssets = {};
  bool _isLoading = true;
  int _currentPage = 0;
  final int _pageSize = 50;
  bool _hasMore = true;
  
  // UI state
  final ScrollController _scrollController = ScrollController();
  bool _isMultiSelectMode = false;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _loadAlbums();
    _scrollController.addListener(_scrollListener);
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  Future<void> _loadAlbums() async {
    final permitted = await PhotoManager.requestPermissionExtend();
    if (!permitted.isAuth) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }
    
    final albums = await PhotoManager.getAssetPathList(
      type: widget.isVideoMode ? RequestType.video : RequestType.common,
      filterOption: FilterOptionGroup(
        videoOption: const FilterOption(
          durationConstraint: DurationConstraint(
            max: Duration(minutes: 5),
          ),
        ),
      ),
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
      _assets.clear();
      _hasMore = true;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    final assets = await _currentAlbum!.getAssetListPaged(
      page: _currentPage,
      size: _pageSize,
    );
    
    setState(() {
      _assets.addAll(assets);
      _currentPage++;
      _hasMore = assets.length == _pageSize;
      _isLoading = false;
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadAssets();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(modernTheme),
            
            // Album selector
            if (_albums.length > 1)
              _buildAlbumSelector(modernTheme),
            
            // Selected items bar
            if (_selectedAssets.isNotEmpty)
              _buildSelectedBar(modernTheme),
            
            // Media grid
            Expanded(
              child: AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * _slideAnimation.value),
                    child: Opacity(
                      opacity: 1 - _slideAnimation.value,
                      child: _buildMediaGrid(modernTheme),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: modernTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: modernTheme.textColor),
          ),
          
          Expanded(
            child: Text(
              widget.isVideoMode ? 'Select Video' : 'Select Photos',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          if (!widget.isVideoMode)
            TextButton(
              onPressed: _selectedAssets.isEmpty ? null : _handleSelection,
              child: Text(
                'Done${_selectedAssets.isNotEmpty ? ' (${_selectedAssets.length})' : ''}',
                style: TextStyle(
                  color: _selectedAssets.isEmpty
                      ? modernTheme.textSecondaryColor
                      : modernTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildAlbumSelector(ModernThemeExtension modernTheme) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: modernTheme.dividerColor ?? Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showAlbumPicker,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
    );
  }

  Widget _buildSelectedBar(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: modernTheme.primaryColor!.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: modernTheme.primaryColor!.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: modernTheme.primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_selectedAssets.length} selected',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
              style: TextStyle(
                color: modernTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid(ModernThemeExtension modernTheme) {
    if (_assets.isEmpty && !_isLoading) {
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
      itemCount: _assets.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _assets.length) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        final asset = _assets[index];
        return _buildMediaItem(asset, modernTheme);
      },
    );
  }

  Widget _buildMediaItem(AssetEntity asset, ModernThemeExtension modernTheme) {
    final isSelected = _selectedAssets.contains(asset.id);
    final selectionIndex = _selectedAssets.toList().indexOf(asset.id);
    
    return GestureDetector(
      onTap: () => _handleAssetTap(asset),
      onLongPress: !widget.isVideoMode ? () => _startMultiSelect(asset) : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail
          FutureBuilder<Uint8List?>(
            future: asset.thumbnailDataWithSize(
              const ThumbnailSize(400, 400),
              quality: 95,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return Hero(
                  tag: 'media_${asset.id}',
                  child: Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                  ),
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
          
          // Selection overlay
          if (isSelected || _isMultiSelectMode)
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                color: isSelected
                    ? modernTheme.primaryColor!.withOpacity(0.3)
                    : Colors.transparent,
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: modernTheme.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${selectionIndex + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          
          // Video duration
          if (asset.type == AssetType.video)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.videocam,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(asset.duration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Quick preview button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _showPreview(asset),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.remove_red_eye,
                  color: Colors.white,
                  size: 16,
                ),
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
              Text(
                'Select Album',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _albums.length,
                  itemBuilder: (context, index) {
                    final album = _albums[index];
                    return ListTile(
                      leading: Icon(
                        _getAlbumIcon(album.name),
                        color: modernTheme.primaryColor,
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
                          _loadAssets(refresh: true);
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  IconData _getAlbumIcon(String albumName) {
    final name = albumName.toLowerCase();
    if (name.contains('camera')) return Icons.camera;
    if (name.contains('screenshot')) return Icons.screenshot;
    if (name.contains('download')) return Icons.download;
    if (name.contains('favorite')) return Icons.favorite;
    if (name.contains('video')) return Icons.video_library;
    return Icons.photo_album;
  }

  void _handleAssetTap(AssetEntity asset) async {
    if (widget.isVideoMode) {
      // For video mode, select immediately
      if (asset.duration > widget.maxVideoDuration.inSeconds) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Video must be less than ${widget.maxVideoDuration.inMinutes} minutes',
            ),
          ),
        );
        return;
      }
      
      final file = await asset.file;
      if (file != null) {
        widget.onFilesSelected([file]);
        Navigator.of(context).pop();
      }
    } else {
      // For image mode, toggle selection
      setState(() {
        if (_selectedAssets.contains(asset.id)) {
          _selectedAssets.remove(asset.id);
        } else {
          if (_selectedAssets.length < widget.maxImages) {
            _selectedAssets.add(asset.id);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Maximum ${widget.maxImages} images allowed'),
              ),
            );
          }
        }
      });
    }
  }

  void _startMultiSelect(AssetEntity asset) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isMultiSelectMode = true;
      _selectedAssets.add(asset.id);
    });
  }

  Future<void> _handleSelection() async {
    final List<File> files = [];
    
    for (final assetId in _selectedAssets) {
      final asset = _assets.firstWhere((a) => a.id == assetId);
      final file = await asset.file;
      if (file != null) {
        files.add(file);
      }
    }
    
    widget.onFilesSelected(files);
    Navigator.of(context).pop();
  }

  void _showPreview(AssetEntity asset) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaPreviewScreen(asset: asset),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}

// Simple preview screen
class MediaPreviewScreen extends StatelessWidget {
  final AssetEntity asset;
  
  const MediaPreviewScreen({Key? key, required this.asset}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Hero(
          tag: 'media_${asset.id}',
          child: FutureBuilder<File?>(
            future: asset.file,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }
              
              if (asset.type == AssetType.image) {
                return InteractiveViewer(
                  child: Image.file(snapshot.data!),
                );
              } else {
                return const Center(
                  child: Text(
                    'Video preview not available',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
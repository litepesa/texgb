import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:textgb/features/channels/widgets/audio_selector_widget.dart';
import 'package:textgb/features/channels/widgets/beauty_filter_widget.dart';
import 'package:textgb/features/channels/widgets/filter_selector_widget.dart';
import 'package:textgb/features/channels/widgets/media_preview_widget.dart';
import 'package:textgb/features/channels/widgets/sticker_overlay_editor.dart';
import 'package:textgb/features/channels/widgets/text_overlay_editor.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/models/edited_media_model.dart';
import 'package:video_player/video_player.dart';

class MediaEditorScreen extends StatefulWidget {
  final File mediaFile;
  final bool isVideo;
  final EditedMediaModel? existingEdits;

  const MediaEditorScreen({
    Key? key,
    required this.mediaFile,
    required this.isVideo,
    this.existingEdits,
  }) : super(key: key);

  @override
  State<MediaEditorScreen> createState() => _MediaEditorScreenState();
}

class _MediaEditorScreenState extends State<MediaEditorScreen> {
  late EditedMediaModel _editedMedia;
  VideoPlayerController? _videoController;
  
  // Editor states
  EditorMode _currentMode = EditorMode.none;
  bool _isProcessing = false;
  
  // Undo/Redo stacks
  final List<EditedMediaModel> _undoStack = [];
  final List<EditedMediaModel> _redoStack = [];

  @override
  void initState() {
    super.initState();
    
    // Initialize with existing edits or create new
    _editedMedia = widget.existingEdits ?? EditedMediaModel(
      originalFile: widget.mediaFile,
      processedFile: widget.mediaFile,
      textOverlays: [],
      stickerOverlays: [],
      audioTrack: null,
      filterType: null,
      beautyLevel: 0.0,
      brightness: 0.0,
      contrast: 1.0,
      saturation: 1.0,
    );
    
    if (widget.isVideo) {
      _initializeVideoPlayer();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    _videoController = VideoPlayerController.file(_editedMedia.processedFile ?? widget.mediaFile);
    await _videoController!.initialize();
    _videoController!.setLooping(true);
    _videoController!.play();
    setState(() {});
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _saveState() {
    _undoStack.add(_editedMedia.copyWith());
    _redoStack.clear();
    if (_undoStack.length > 20) {
      _undoStack.removeAt(0);
    }
  }

  void _undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(_editedMedia.copyWith());
      _editedMedia = _undoStack.removeLast();
      setState(() {});
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(_editedMedia.copyWith());
      _editedMedia = _redoStack.removeLast();
      setState(() {});
    }
  }

  void _setEditorMode(EditorMode mode) {
    setState(() {
      _currentMode = _currentMode == mode ? EditorMode.none : mode;
    });
  }

  Future<void> _saveAndExit() async {
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Process the media with all applied effects
      final processedFile = await _processMedia();
      
      final finalEdit = _editedMedia.copyWith(
        processedFile: processedFile,
      );
      
      Navigator.pop(context, finalEdit);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing media: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<File> _processMedia() async {
    // In a real implementation, this would use FFmpeg or similar
    // to apply all the effects and generate the final file
    // For now, we'll return the original file
    // TODO: Implement actual media processing
    return widget.mediaFile;
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text('Are you sure you want to discard all changes?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Media preview
            MediaPreviewWidget(
              mediaFile: _editedMedia.processedFile ?? widget.mediaFile,
              isVideo: widget.isVideo,
              videoController: _videoController,
              editedMedia: _editedMedia,
            ),
            
            // Top toolbar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    
                    // Undo/Redo buttons
                    Row(
                      children: [
                        IconButton(
                          onPressed: _undoStack.isNotEmpty ? _undo : null,
                          icon: Icon(
                            Icons.undo,
                            color: _undoStack.isNotEmpty ? Colors.white : Colors.white30,
                          ),
                        ),
                        IconButton(
                          onPressed: _redoStack.isNotEmpty ? _redo : null,
                          icon: Icon(
                            Icons.redo,
                            color: _redoStack.isNotEmpty ? Colors.white : Colors.white30,
                          ),
                        ),
                      ],
                    ),
                    
                    // Save button
                    _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : TextButton(
                            onPressed: _saveAndExit,
                            child: const Text(
                              'Next',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
            
            // Bottom editor panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Active editor widget
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: _currentMode != EditorMode.none ? 200 : 0,
                        child: _buildActiveEditor(),
                      ),
                      
                      // Editor mode buttons
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildEditorButton(
                              icon: Icons.text_fields,
                              label: 'Text',
                              mode: EditorMode.text,
                            ),
                            _buildEditorButton(
                              icon: Icons.emoji_emotions,
                              label: 'Stickers',
                              mode: EditorMode.sticker,
                            ),
                            _buildEditorButton(
                              icon: Icons.music_note,
                              label: 'Music',
                              mode: EditorMode.audio,
                            ),
                            _buildEditorButton(
                              icon: Icons.filter,
                              label: 'Filters',
                              mode: EditorMode.filter,
                            ),
                            _buildEditorButton(
                              icon: Icons.face_retouching_natural,
                              label: 'Beauty',
                              mode: EditorMode.beauty,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorButton({
    required IconData icon,
    required String label,
    required EditorMode mode,
  }) {
    final isActive = _currentMode == mode;
    
    return GestureDetector(
      onTap: () => _setEditorMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.white70,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveEditor() {
    switch (_currentMode) {
      case EditorMode.text:
        return TextOverlayEditor(
          onTextAdded: (textOverlay) {
            _saveState();
            setState(() {
              _editedMedia.textOverlays.add(textOverlay);
            });
          },
          onTextUpdated: (index, textOverlay) {
            _saveState();
            setState(() {
              _editedMedia.textOverlays[index] = textOverlay;
            });
          },
          onTextDeleted: (index) {
            _saveState();
            setState(() {
              _editedMedia.textOverlays.removeAt(index);
            });
          },
          existingTexts: _editedMedia.textOverlays,
        );
        
      case EditorMode.sticker:
        return StickerOverlayEditor(
          onStickerAdded: (stickerOverlay) {
            _saveState();
            setState(() {
              _editedMedia.stickerOverlays.add(stickerOverlay);
            });
          },
          onStickerUpdated: (index, stickerOverlay) {
            _saveState();
            setState(() {
              _editedMedia.stickerOverlays[index] = stickerOverlay;
            });
          },
          onStickerDeleted: (index) {
            _saveState();
            setState(() {
              _editedMedia.stickerOverlays.removeAt(index);
            });
          },
          existingStickers: _editedMedia.stickerOverlays,
        );
        
      case EditorMode.audio:
        return AudioSelectorWidget(
          selectedAudio: _editedMedia.audioTrack,
          onAudioSelected: (audioTrack) {
            _saveState();
            setState(() {
              _editedMedia = _editedMedia.copyWith(audioTrack: audioTrack);
            });
          },
          onAudioRemoved: () {
            _saveState();
            setState(() {
              _editedMedia = _editedMedia.copyWith(audioTrack: null);
            });
          },
        );
        
      case EditorMode.filter:
        return FilterSelectorWidget(
          selectedFilter: _editedMedia.filterType,
          brightness: _editedMedia.brightness,
          contrast: _editedMedia.contrast,
          saturation: _editedMedia.saturation,
          onFilterChanged: (filterType) {
            _saveState();
            setState(() {
              _editedMedia = _editedMedia.copyWith(filterType: filterType);
            });
          },
          onAdjustmentChanged: ({
            double? brightness,
            double? contrast,
            double? saturation,
          }) {
            _saveState();
            setState(() {
              _editedMedia = _editedMedia.copyWith(
                brightness: brightness ?? _editedMedia.brightness,
                contrast: contrast ?? _editedMedia.contrast,
                saturation: saturation ?? _editedMedia.saturation,
              );
            });
          },
        );
        
      case EditorMode.beauty:
        return BeautyFilterWidget(
          beautyLevel: _editedMedia.beautyLevel,
          onBeautyChanged: (level) {
            _saveState();
            setState(() {
              _editedMedia = _editedMedia.copyWith(beautyLevel: level);
            });
          },
        );
        
      case EditorMode.none:
        return const SizedBox.shrink();
    }
  }
}

enum EditorMode {
  none,
  text,
  sticker,
  audio,
  filter,
  beauty,
}
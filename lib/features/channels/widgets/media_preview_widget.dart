import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/features/channels/models/edited_media_model.dart';

class MediaPreviewWidget extends StatefulWidget {
  final File mediaFile;
  final bool isVideo;
  final VideoPlayerController? videoController;
  final EditedMediaModel editedMedia;

  const MediaPreviewWidget({
    Key? key,
    required this.mediaFile,
    required this.isVideo,
    this.videoController,
    required this.editedMedia,
  }) : super(key: key);

  @override
  State<MediaPreviewWidget> createState() => _MediaPreviewWidgetState();
}

class _MediaPreviewWidgetState extends State<MediaPreviewWidget>
    with TickerProviderStateMixin {
  final List<AnimationController> _textAnimControllers = [];
  final List<AnimationController> _stickerAnimControllers = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Initialize text animations
    for (var i = 0; i < widget.editedMedia.textOverlays.length; i++) {
      final controller = AnimationController(
        duration: const Duration(seconds: 1),
        vsync: this,
      );
      _textAnimControllers.add(controller);
      
      if (widget.editedMedia.textOverlays[i].animation != null) {
        controller.repeat();
      }
    }
    
    // Initialize sticker animations
    for (var i = 0; i < widget.editedMedia.stickerOverlays.length; i++) {
      final controller = AnimationController(
        duration: const Duration(seconds: 1),
        vsync: this,
      );
      _stickerAnimControllers.add(controller);
      
      if (widget.editedMedia.stickerOverlays[i].animation != null) {
        controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _textAnimControllers) {
      controller.dispose();
    }
    for (var controller in _stickerAnimControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Base media
              _buildBaseMedia(),
              
              // Filter overlay
              if (widget.editedMedia.filterType != null)
                _buildFilterOverlay(),
              
              // Beauty filter effect
              if (widget.editedMedia.beautyLevel > 0)
                _buildBeautyOverlay(),
              
              // Text overlays
              ..._buildTextOverlays(),
              
              // Sticker overlays
              ..._buildStickerOverlays(),
              
              // Audio indicator
              if (widget.editedMedia.audioTrack != null)
                _buildAudioIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBaseMedia() {
    if (widget.isVideo && widget.videoController != null) {
      return ColorFiltered(
        colorFilter: ColorFilter.matrix(_getColorMatrix()),
        child: VideoPlayer(widget.videoController!),
      );
    } else {
      return ColorFiltered(
        colorFilter: ColorFilter.matrix(_getColorMatrix()),
        child: Image.file(
          widget.mediaFile,
          fit: BoxFit.cover,
        ),
      );
    }
  }

  List<double> _getColorMatrix() {
    final brightness = widget.editedMedia.brightness;
    final contrast = widget.editedMedia.contrast;
    final saturation = widget.editedMedia.saturation;
    
    // Basic color matrix with adjustments
    return [
      contrast * saturation, 0, 0, 0, brightness,
      0, contrast * saturation, 0, 0, brightness,
      0, 0, contrast * saturation, 0, brightness,
      0, 0, 0, 1, 0,
    ];
  }

  Widget _buildFilterOverlay() {
    Color filterColor = Colors.transparent;
    
    switch (widget.editedMedia.filterType) {
      case 'Vintage':
        filterColor = Colors.orange.withOpacity(0.2);
        break;
      case 'Cool':
        filterColor = Colors.blue.withOpacity(0.1);
        break;
      case 'Warm':
        filterColor = Colors.amber.withOpacity(0.15);
        break;
      case 'Black & White':
        return ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Colors.grey,
            BlendMode.saturation,
          ),
          child: Container(),
        );
      case 'Dramatic':
        filterColor = Colors.deepPurple.withOpacity(0.2);
        break;
      default:
        filterColor = Colors.transparent;
    }
    
    return Container(
      color: filterColor,
    );
  }

  Widget _buildBeautyOverlay() {
    // Simulated beauty filter with blur effect
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(widget.editedMedia.beautyLevel * 0.1),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTextOverlays() {
    final List<Widget> textWidgets = [];
    
    for (var i = 0; i < widget.editedMedia.textOverlays.length; i++) {
      final textOverlay = widget.editedMedia.textOverlays[i];
      final controller = i < _textAnimControllers.length 
          ? _textAnimControllers[i] 
          : null;
      
      textWidgets.add(
        Positioned(
          left: textOverlay.position.dx,
          top: textOverlay.position.dy,
          child: GestureDetector(
            onTap: () {
              // Handle text editing
            },
            child: Transform.rotate(
              angle: textOverlay.rotation,
              child: Transform.scale(
                scale: textOverlay.scale,
                child: _buildAnimatedText(textOverlay, controller),
              ),
            ),
          ),
        ),
      );
    }
    
    return textWidgets;
  }

  Widget _buildAnimatedText(TextOverlay textOverlay, AnimationController? controller) {
    Widget textWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: textOverlay.style.backgroundColor ?? Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        textOverlay.text,
        style: textOverlay.style,
      ),
    );
    
    if (controller == null || textOverlay.animation == null) {
      return textWidget;
    }
    
    switch (textOverlay.animation) {
      case TextAnimation.fadeIn:
        return FadeTransition(
          opacity: controller,
          child: textWidget,
        );
      case TextAnimation.slideIn:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(controller),
          child: textWidget,
        );
      case TextAnimation.bounce:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.2,
          ).animate(CurvedAnimation(
            parent: controller,
            curve: Curves.elasticOut,
          )),
          child: textWidget,
        );
      case TextAnimation.scale:
        return ScaleTransition(
          scale: controller,
          child: textWidget,
        );
      case TextAnimation.rotate:
        return RotationTransition(
          turns: controller,
          child: textWidget,
        );
      default:
        return textWidget;
    }
  }

  List<Widget> _buildStickerOverlays() {
    final List<Widget> stickerWidgets = [];
    
    for (var i = 0; i < widget.editedMedia.stickerOverlays.length; i++) {
      final stickerOverlay = widget.editedMedia.stickerOverlays[i];
      final controller = i < _stickerAnimControllers.length 
          ? _stickerAnimControllers[i] 
          : null;
      
      stickerWidgets.add(
        Positioned(
          left: stickerOverlay.position.dx,
          top: stickerOverlay.position.dy,
          child: GestureDetector(
            onTap: () {
              // Handle sticker editing
            },
            child: Transform.rotate(
              angle: stickerOverlay.rotation,
              child: Transform.scale(
                scale: stickerOverlay.scale,
                child: _buildAnimatedSticker(stickerOverlay, controller),
              ),
            ),
          ),
        ),
      );
    }
    
    return stickerWidgets;
  }

  Widget _buildAnimatedSticker(StickerOverlay stickerOverlay, AnimationController? controller) {
    Widget stickerWidget = Image.asset(
      stickerOverlay.stickerPath,
      width: 100,
      height: 100,
    );
    
    if (controller == null || stickerOverlay.animation == null) {
      return stickerWidget;
    }
    
    switch (stickerOverlay.animation) {
      case StickerAnimation.fadeIn:
        return FadeTransition(
          opacity: controller,
          child: stickerWidget,
        );
      case StickerAnimation.bounce:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.2,
          ).animate(CurvedAnimation(
            parent: controller,
            curve: Curves.elasticOut,
          )),
          child: stickerWidget,
        );
      case StickerAnimation.rotate:
        return RotationTransition(
          turns: controller,
          child: stickerWidget,
        );
      case StickerAnimation.scale:
        return ScaleTransition(
          scale: controller,
          child: stickerWidget,
        );
      case StickerAnimation.shake:
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 100),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(5 * (0.5 - value), 0),
              child: stickerWidget,
            );
          },
        );
      default:
        return stickerWidget;
    }
  }

  Widget _buildAudioIndicator() {
    return Positioned(
      bottom: 20,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.music_note,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              widget.editedMedia.audioTrack!.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
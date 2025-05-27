import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final bool isVideoMode;
  final bool showGrid;
  final bool flashOn;
  final bool useTimer;
  final int timerDuration;
  final Function(File) onMediaCaptured;

  const CameraScreen({
    Key? key,
    required this.cameras,
    required this.isVideoMode,
    required this.showGrid,
    required this.flashOn,
    required this.useTimer,
    required this.timerDuration,
    required this.onMediaCaptured,
  }) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  
  // Camera controllers
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  
  // Animation controllers
  late AnimationController _focusAnimationController;
  late AnimationController _shutterAnimationController;
  late AnimationController _recordAnimationController;
  late Animation<double> _focusAnimation;
  late Animation<double> _shutterAnimation;
  late Animation<double> _recordAnimation;
  
  // Camera state
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isTakingPicture = false;
  bool _showFocusCircle = false;
  Offset _focusPoint = Offset.zero;
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  
  // Timer state
  int _timerCountdown = 0;
  Timer? _timer;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  
  // UI state
  bool _showSettings = false;
  FlashMode _flashMode = FlashMode.off;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _initializeCamera();
  }

  void _initializeAnimations() {
    // Focus animation
    _focusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _focusAnimation = Tween<double>(
      begin: 1.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _focusAnimationController,
      curve: Curves.easeOutBack,
    ));
    
    // Shutter animation
    _shutterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _shutterAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_shutterAnimationController);
    
    // Record animation
    _recordAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _recordAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _recordAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) return;
    
    _controller = CameraController(
      widget.cameras[_selectedCameraIndex],
      ResolutionPreset.max,
      enableAudio: widget.isVideoMode,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    
    try {
      await _controller!.initialize();
      
      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();
      
      // Set initial flash mode
      if (widget.flashOn) {
        await _controller!.setFlashMode(FlashMode.torch);
        _flashMode = FlashMode.torch;
      }
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized || _controller == null) return;
    
    if (state == AppLifecycleState.inactive) {
      _controller!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _focusAnimationController.dispose();
    _shutterAnimationController.dispose();
    _recordAnimationController.dispose();
    _timer?.cancel();
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_isInitialized && _controller != null)
            _buildCameraPreview()
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          
          // Grid overlay
          if (widget.showGrid && _isInitialized)
            _buildGridOverlay(),
          
          // Focus indicator
          if (_showFocusCircle)
            _buildFocusIndicator(),
          
          // Timer countdown
          if (_timerCountdown > 0)
            _buildTimerCountdown(modernTheme),
          
          // Recording indicator
          if (_isRecording)
            _buildRecordingIndicator(modernTheme),
          
          // Shutter flash effect
          AnimatedBuilder(
            animation: _shutterAnimation,
            builder: (context, child) {
              return Container(
                color: Colors.white.withOpacity(_shutterAnimation.value * 0.8),
              );
            },
          ),
          
          // Controls
          SafeArea(
            child: Column(
              children: [
                _buildTopControls(modernTheme),
                const Spacer(),
                _buildBottomControls(modernTheme),
              ],
            ),
          ),
          
          // Settings panel
          if (_showSettings)
            _buildSettingsPanel(modernTheme),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return GestureDetector(
      onTapDown: (details) => _handleTapToFocus(details),
      onScaleUpdate: (details) => _handlePinchToZoom(details),
      child: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: ClipRect(
            child: Transform.scale(
              scale: _currentZoom,
              child: CameraPreview(_controller!),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridOverlay() {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: CustomPaint(
        painter: GridPainter(),
      ),
    );
  }

  Widget _buildFocusIndicator() {
    return Positioned(
      left: _focusPoint.dx - 40,
      top: _focusPoint.dy - 40,
      child: AnimatedBuilder(
        animation: _focusAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _focusAnimation.value,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.yellow,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimerCountdown(ModernThemeExtension modernTheme) {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: child,
          );
        },
        child: Container(
          key: ValueKey(_timerCountdown),
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _timerCountdown.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 60,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator(ModernThemeExtension modernTheme) {
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _recordAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _recordAnimation.value,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(_recordingDuration),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
          ),
          
          // Flash control
          IconButton(
            onPressed: _toggleFlash,
            icon: Icon(
              _getFlashIcon(),
              color: Colors.white,
              size: 24,
            ),
          ),
          
          // Settings
          IconButton(
            onPressed: () => setState(() => _showSettings = !_showSettings),
            icon: const Icon(Icons.tune, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery button
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FutureBuilder<List<AssetEntity>>(
              future: _getRecentMedia(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return FutureBuilder<Uint8List?>(
                    future: snapshot.data!.first.thumbnailDataWithSize(
                      const ThumbnailSize(200, 200),
                    ),
                    builder: (context, thumbSnapshot) {
                      if (thumbSnapshot.hasData) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            thumbSnapshot.data!,
                            fit: BoxFit.cover,
                          ),
                        );
                      }
                      return const Icon(Icons.photo, color: Colors.white);
                    },
                  );
                }
                return const Icon(Icons.photo, color: Colors.white);
              },
            ),
          ),
          
          // Capture button
          GestureDetector(
            onTap: _handleCapture,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _isRecording ? 30 : 64,
                  height: _isRecording ? 30 : 64,
                  decoration: BoxDecoration(
                    color: widget.isVideoMode ? Colors.red : Colors.white,
                    shape: _isRecording ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: _isRecording ? BorderRadius.circular(8) : null,
                  ),
                ),
              ],
            ),
          ),
          
          // Switch camera
          IconButton(
            onPressed: _switchCamera,
            icon: const Icon(
              Icons.flip_camera_ios,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel(ModernThemeExtension modernTheme) {
    return Positioned(
      top: 100,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timer setting
            _buildSettingItem(
              'Timer',
              widget.useTimer ? '${widget.timerDuration}s' : 'Off',
              Icons.timer,
              () {
                Navigator.of(context).pop();
                // Parent will handle timer setting
              },
            ),
            const SizedBox(height: 12),
            
            // Grid setting
            _buildSettingItem(
              'Grid',
              widget.showGrid ? 'On' : 'Off',
              Icons.grid_on,
              () {
                Navigator.of(context).pop();
                // Parent will handle grid setting
              },
            ),
            
            if (widget.isVideoMode) ...[
              const SizedBox(height: 12),
              // Video quality
              _buildSettingItem(
                'Quality',
                'HD',
                Icons.hd,
                () {},
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(width: 20),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  
  Future<List<AssetEntity>> _getRecentMedia() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
    );
    if (albums.isEmpty) return [];
    
    return albums.first.getAssetListRange(start: 0, end: 1);
  }

  void _handleTapToFocus(TapDownDetails details) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset tapPosition = box.globalToLocal(details.globalPosition);
    final Size size = box.size;
    
    final double x = tapPosition.dx / size.width;
    final double y = tapPosition.dy / size.height;
    
    _controller!.setExposurePoint(Offset(x, y));
    _controller!.setFocusPoint(Offset(x, y));
    
    setState(() {
      _focusPoint = tapPosition;
      _showFocusCircle = true;
    });
    
    _focusAnimationController.forward(from: 0);
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showFocusCircle = false;
        });
      }
    });
  }

  void _handlePinchToZoom(ScaleUpdateDetails details) {
    final double zoom = (_currentZoom * details.scale).clamp(_minZoom, _maxZoom);
    
    setState(() {
      _currentZoom = zoom;
    });
    
    _controller!.setZoomLevel(zoom);
  }

  void _toggleFlash() async {
    if (_controller == null) return;
    
    setState(() {
      switch (_flashMode) {
        case FlashMode.off:
          _flashMode = FlashMode.auto;
          break;
        case FlashMode.auto:
          _flashMode = FlashMode.always;
          break;
        case FlashMode.always:
          _flashMode = FlashMode.torch;
          break;
        case FlashMode.torch:
          _flashMode = FlashMode.off;
          break;
      }
    });
    
    await _controller!.setFlashMode(_flashMode);
  }

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.flashlight_on;
    }
  }

  void _switchCamera() async {
    if (widget.cameras.length <= 1) return;
    
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
    });
    
    await _initializeCamera();
  }

  void _handleCapture() {
    if (widget.useTimer && !_isRecording) {
      _startTimer();
    } else {
      if (widget.isVideoMode) {
        if (_isRecording) {
          _stopRecording();
        } else {
          _startRecording();
        }
      } else {
        _takePicture();
      }
    }
  }

  void _startTimer() {
    setState(() {
      _timerCountdown = widget.timerDuration;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timerCountdown--;
      });
      
      if (_timerCountdown <= 0) {
        timer.cancel();
        if (widget.isVideoMode) {
          _startRecording();
        } else {
          _takePicture();
        }
      }
    });
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPicture) {
      return;
    }
    
    setState(() {
      _isTakingPicture = true;
    });
    
    try {
      // Play shutter animation
      await _shutterAnimationController.forward();
      _shutterAnimationController.reset();
      
      // Haptic feedback
      HapticFeedback.mediumImpact();
      
      final XFile photo = await _controller!.takePicture();
      final File file = File(photo.path);
      
      widget.onMediaCaptured(file);
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error taking picture: $e');
    } finally {
      setState(() {
        _isTakingPicture = false;
      });
    }
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized || _isRecording) {
      return;
    }
    
    try {
      await _controller!.startVideoRecording();
      
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });
      
      // Start recording animation
      _recordAnimationController.repeat(reverse: true);
      
      // Start recording timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration = Duration(seconds: timer.tick);
        });
        
        // Auto stop at 5 minutes
        if (_recordingDuration >= const Duration(minutes: 5)) {
          _stopRecording();
        }
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_isRecording) return;
    
    try {
      final XFile video = await _controller!.stopVideoRecording();
      
      _recordingTimer?.cancel();
      _recordAnimationController.stop();
      _recordAnimationController.reset();
      
      setState(() {
        _isRecording = false;
      });
      
      final File file = File(video.path);
      widget.onMediaCaptured(file);
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

// Grid painter for camera grid
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 0.5;
    
    // Draw vertical lines
    final verticalSpacing = size.width / 3;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(verticalSpacing * i, 0),
        Offset(verticalSpacing * i, size.height),
        paint,
      );
    }
    
    // Draw horizontal lines
    final horizontalSpacing = size.height / 3;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(0, horizontalSpacing * i),
        Offset(size.width, horizontalSpacing * i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
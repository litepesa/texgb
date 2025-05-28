// lib/features/channels/widgets/modern_camera_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/screens/create_post_screen.dart';

class ModernCameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ModernCameraScreen({
    Key? key,
    required this.cameras,
  }) : super(key: key);

  @override
  State<ModernCameraScreen> createState() => _ModernCameraScreenState();
}

class _ModernCameraScreenState extends State<ModernCameraScreen>
    with TickerProviderStateMixin {
  // Camera
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  bool _isRecording = false;
  bool _isTakingPhoto = false;
  
  // Animations
  late AnimationController _recordButtonController;
  late AnimationController _timerController;
  late AnimationController _flashController;
  late Animation<double> _recordAnimation;
  late Animation<double> _timerAnimation;
  
  // Recording
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  int _selectedDuration = 30; // Default 30 seconds
  
  // UI State
  bool _showDurationSelector = false;
  FlashMode _flashMode = FlashMode.off;
  double _zoomLevel = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  bool _isVideoMode = true;
  
  // Duration presets
  final List<int> _durationPresets = [15, 30, 60, 120, 300]; // seconds
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCamera();
  }
  
  void _initializeAnimations() {
    _recordButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _timerController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _recordAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _recordButtonController,
      curve: Curves.elasticOut,
    ));
    
    _timerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_timerController);
  }
  
  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) return;
    
    _controller = CameraController(
      widget.cameras[_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: true,
    );
    
    try {
      await _controller!.initialize();
      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();
      setState(() {});
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    _recordButtonController.dispose();
    _timerController.dispose();
    _flashController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          if (_controller != null && _controller!.value.isInitialized)
            GestureDetector(
              onScaleUpdate: (details) {
                final zoom = (_zoomLevel * details.scale).clamp(_minZoom, _maxZoom);
                _controller!.setZoomLevel(zoom);
                setState(() => _zoomLevel = zoom);
              },
              child: CameraPreview(_controller!),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          
          // Gradient overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // Top controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Close button
                      _buildControlButton(
                        icon: Icons.close,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      
                      // Mode toggle
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            _buildModeButton(
                              'Photo',
                              !_isVideoMode,
                              () => setState(() => _isVideoMode = false),
                            ),
                            _buildModeButton(
                              'Video',
                              _isVideoMode,
                              () => setState(() => _isVideoMode = true),
                            ),
                          ],
                        ),
                      ),
                      
                      // Settings
                      _buildControlButton(
                        icon: Icons.tune,
                        onTap: _showSettings,
                      ),
                    ],
                  ),
                  
                  // Recording indicator
                  if (_isRecording)
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDuration(_recordingSeconds),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' / ${_formatDuration(_selectedDuration)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Duration selector for video mode
                  if (_isVideoMode && !_isRecording)
                    _buildDurationSelector(),
                  
                  const SizedBox(height: 20),
                  
                  // Main controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Flash button
                      _buildControlButton(
                        icon: _getFlashIcon(),
                        onTap: _toggleFlash,
                      ),
                      
                      // Capture button
                      GestureDetector(
                        onTap: _handleCapture,
                        child: AnimatedBuilder(
                          animation: _recordAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _isRecording ? _recordAnimation.value : 1.0,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: _isRecording && _isVideoMode 
                                        ? BoxShape.rectangle 
                                        : BoxShape.circle,
                                    color: _isVideoMode ? Colors.red : Colors.white,
                                    borderRadius: _isRecording && _isVideoMode
                                        ? BorderRadius.circular(8)
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Switch camera
                      _buildControlButton(
                        icon: Icons.flip_camera_ios,
                        onTap: _switchCamera,
                      ),
                    ],
                  ),
                  
                  // Zoom slider
                  if (_maxZoom > _minZoom)
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.zoom_out,
                            color: Colors.white.withOpacity(0.7),
                            size: 20,
                          ),
                          Expanded(
                            child: Slider(
                              value: _zoomLevel,
                              min: _minZoom,
                              max: _maxZoom,
                              onChanged: (value) {
                                _controller!.setZoomLevel(value);
                                setState(() => _zoomLevel = value);
                              },
                              activeColor: Colors.white,
                              inactiveColor: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          Icon(
                            Icons.zoom_in,
                            color: Colors.white.withOpacity(0.7),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Duration selector overlay
          if (_showDurationSelector)
            _buildDurationSelectorOverlay(modernTheme),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildModeButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _durationPresets.length,
        itemBuilder: (context, index) {
          final duration = _durationPresets[index];
          final isSelected = _selectedDuration == duration;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedDuration = duration),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatDurationLabel(duration),
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (duration == 300)
                    Text(
                      'MAX',
                      style: TextStyle(
                        color: isSelected ? Colors.red : Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDurationSelectorOverlay(ModernThemeExtension modernTheme) {
    return GestureDetector(
      onTap: () => setState(() => _showDurationSelector = false),
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: modernTheme.backgroundColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Duration',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ..._durationPresets.map((duration) {
                  return ListTile(
                    title: Text(
                      _formatDurationLabel(duration),
                      style: TextStyle(color: modernTheme.textColor),
                    ),
                    trailing: duration == _selectedDuration
                        ? Icon(Icons.check, color: modernTheme.primaryColor)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedDuration = duration;
                        _showDurationSelector = false;
                      });
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Camera functionality
  
  Future<void> _switchCamera() async {
    if (widget.cameras.length <= 1) return;
    
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
    });
    
    await _initializeCamera();
  }
  
  void _toggleFlash() {
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
    
    _controller?.setFlashMode(_flashMode);
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
  
  void _showSettings() {
    // Implement settings sheet
  }
  
  Future<void> _handleCapture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    if (_isVideoMode) {
      if (_isRecording) {
        await _stopRecording();
      } else {
        await _startRecording();
      }
    } else {
      await _takePicture();
    }
  }
  
  Future<void> _takePicture() async {
    if (_isTakingPhoto) return;
    
    setState(() => _isTakingPhoto = true);
    
    try {
      final image = await _controller!.takePicture();
      
      HapticFeedback.mediumImpact();
      _flashController.forward().then((_) {
        _flashController.reverse();
      });
      
      Navigator.of(context).pop(
        MediaResult(
          file: File(image.path),
          isVideo: false,
        ),
      );
    } catch (e) {
      debugPrint('Error taking picture: $e');
    } finally {
      setState(() => _isTakingPhoto = false);
    }
  }
  
  Future<void> _startRecording() async {
    try {
      await _controller!.startVideoRecording();
      
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });
      
      _recordButtonController.forward();
      
      // Start timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds++;
        });
        
        // Auto stop at selected duration
        if (_recordingSeconds >= _selectedDuration) {
          _stopRecording();
        }
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }
  
  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    _recordButtonController.reverse();
    
    try {
      final video = await _controller!.stopVideoRecording();
      
      setState(() => _isRecording = false);
      
      Navigator.of(context).pop(
        MediaResult(
          file: File(video.path),
          isVideo: true,
        ),
      );
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }
  
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  
  String _formatDurationLabel(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else {
      final minutes = seconds ~/ 60;
      return '${minutes} min';
    }
  }
}
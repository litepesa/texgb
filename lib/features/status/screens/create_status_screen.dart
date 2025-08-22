// lib/features/status/screens/create_status_screen.dart (Complete Enhanced Version)
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:ffmpeg_kit_flutter_new_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_gpl/return_code.dart';
import 'package:path/path.dart' as path;

class CreateStatusScreen extends ConsumerStatefulWidget {
  final StatusType type;
  final File? mediaFile;
  final String? initialText;

  const CreateStatusScreen({
    super.key,
    required this.type,
    this.mediaFile,
    this.initialText,
  });

  @override
  ConsumerState<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends ConsumerState<CreateStatusScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  
  Color _selectedBackgroundColor = Colors.blue;
  String? _selectedFontFamily;
  StatusPrivacyType _selectedPrivacy = StatusPrivacyType.all_contacts;
  
  // Audio processing state
  bool _isProcessingAudio = false;
  double _audioProcessingProgress = 0.0;
  String _audioProcessingStatus = '';
  bool _wakelockActive = false;
  File? _processedMediaFile;
  
  final List<Color> _backgroundColors = [
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.green,
    Colors.teal,
    Colors.indigo,
    Colors.brown,
    Colors.grey,
    Colors.black,
  ];

  final List<String> _fontFamilies = [
    'Default',
    'Roboto',
    'OpenSans',
    'Lato',
    'Montserrat',
    'Oswald',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null) {
      _textController.text = widget.initialText!;
    }
    
    // Auto-focus for text status
    if (widget.type == StatusType.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _textFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    _disableWakelock();
    
    // Clean up processed file if it exists
    if (_processedMediaFile != null && _processedMediaFile != widget.mediaFile) {
      try {
        _processedMediaFile!.delete();
      } catch (e) {
        debugPrint('Error cleaning up processed file: $e');
      }
    }
    
    super.dispose();
  }

  // Wakelock management methods
  Future<void> _enableWakelock() async {
    if (!_wakelockActive) {
      try {
        await WakelockPlus.enable();
        _wakelockActive = true;
        debugPrint('Wakelock enabled for status creation');
      } catch (e) {
        debugPrint('Failed to enable wakelock: $e');
      }
    }
  }

  Future<void> _disableWakelock() async {
    if (_wakelockActive) {
      try {
        await WakelockPlus.disable();
        _wakelockActive = false;
        debugPrint('Wakelock disabled');
      } catch (e) {
        debugPrint('Failed to disable wakelock: $e');
      }
    }
  }

  // Get video duration in milliseconds for progress calculation
  Future<int> _getVideoDurationMs(File videoFile) async {
    try {
      // For status videos, assume 30 seconds max duration
      // In a real implementation, you could use video_player to get actual duration
      return 30000; // 30 seconds in milliseconds
    } catch (e) {
      debugPrint('Error getting video duration: $e');
      return 30000; // Fallback to 30 seconds
    }
  }

  // Audio processing for video status (EXACT same as create_post_screen.dart)
  Future<File?> _processVideoAudio(File inputFile) async {
    if (widget.type != StatusType.video) return inputFile;
    
    try {
      final tempDir = Directory.systemTemp;
      final outputPath = '${tempDir.path}/status_audio_processed_${DateTime.now().millisecondsSinceEpoch}.mp4';
      
      // Enable wakelock during processing
      await _enableWakelock();
      
      setState(() {
        _isProcessingAudio = true;
        _audioProcessingStatus = 'Processing audio...';
        _audioProcessingProgress = 0.0;
      });

      debugPrint('Processing audio for status video');

      setState(() {
        _audioProcessingStatus = 'Enhancing audio quality...';
        _audioProcessingProgress = 0.3;
      });

      // EXACT same audio processing command from create_post_screen.dart
      final audioProcessingCommand = '-y -i "${inputFile.path}" '
          // Copy video stream without processing (temporary change from original)
          '-c:v copy '
          
          // Premium loud audio processing - exactly as original
          '-c:a aac '                    // AAC audio
          '-b:a 128k '                   // High quality audio
          '-ar 48000 '                   // 48kHz sample rate
          '-ac 2 '                       // Stereo
          '-af "volume=2.2,equalizer=f=60:width_type=h:width=2:g=3,equalizer=f=150:width_type=h:width=2:g=2,equalizer=f=8000:width_type=h:width=2:g=1,compand=attacks=0.2:decays=0.4:points=-80/-80|-50/-20|-30/-15|-20/-10|-5/-5|0/-2|20/-2,highpass=f=40,lowpass=f=15000,loudnorm=I=-10:TP=-1.5:LRA=7:linear=true" '
          '-movflags +faststart '        // Optimize for streaming
          '-f mp4 "$outputPath"';

      debugPrint('Status audio processing command: ffmpeg $audioProcessingCommand');

      // Get video duration for progress calculation
      final videoDurationMs = await _getVideoDurationMs(inputFile);
      debugPrint('Video duration: ${videoDurationMs}ms for progress calculation');
      
      // Create a completer to properly wait for async completion
      final Completer<void> processingCompleter = Completer<void>();
      
      // Execute with real progress tracking using async
      FFmpegKit.executeAsync(
        audioProcessingCommand,
        (session) async {
          // Completion callback - this is when processing actually finishes
          debugPrint('Status audio processing completed');
          final returnCode = await session.getReturnCode();
          
          if (mounted) {
            setState(() {
              _isProcessingAudio = false;
              _audioProcessingProgress = 1.0;
              _audioProcessingStatus = ReturnCode.isSuccess(returnCode) 
                  ? 'Audio enhanced!'
                  : 'Audio processing failed';
            });
          }
          
          // Disable wakelock after processing unless status creation is in progress
          if (!ref.read(statusNotifierProvider).valueOrNull!.isCreatingStatus == true) {
            await _disableWakelock();
          }
          
          // Complete the future when processing is actually done
          if (!processingCompleter.isCompleted) {
            processingCompleter.complete();
          }
        },
        (log) {
          // Log callback (optional for debugging)
          // debugPrint('FFmpeg log: ${log.getMessage()}');
        },
        (statistics) {
          // Real progress statistics callback
          if (mounted && _isProcessingAudio && statistics.getTime() > 0 && videoDurationMs > 0) {
            final baseProgress = 0.3; // Start from 30%
            final encodingProgress = (statistics.getTime() / videoDurationMs).clamp(0.0, 1.0);
            final totalProgress = baseProgress + (encodingProgress * 0.7); // Remaining 70%
            
            setState(() {
              _audioProcessingProgress = totalProgress.clamp(0.0, 1.0);
            });
            debugPrint('Status audio processing progress: ${(totalProgress * 100).toStringAsFixed(1)}%');
          }
        },
      );
      
      // Wait for the actual processing to complete
      await processingCompleter.future;
      
      // Check the results after processing is truly complete
      final outputFile = File(outputPath);
      if (await outputFile.exists()) {
        final originalSizeMB = await inputFile.length() / (1024 * 1024);
        final newSizeMB = await outputFile.length() / (1024 * 1024);
        
        debugPrint('Status audio processing successful!');
        debugPrint('Original: ${originalSizeMB.toStringAsFixed(1)}MB → New: ${newSizeMB.toStringAsFixed(1)}MB');
        debugPrint('Video copied as-is, audio enhanced');
        
        // Hide processing status after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _audioProcessingStatus = '';
              _audioProcessingProgress = 0.0;
            });
          }
        });
        
        return outputFile;
      }
      
      debugPrint('Status audio processing failed - output file not found');
      await _disableWakelock();
      return null;
      
    } catch (e) {
      debugPrint('Status audio processing error: $e');
      if (mounted) {
        setState(() {
          _isProcessingAudio = false;
          _audioProcessingProgress = 0.0;
          _audioProcessingStatus = 'Audio processing failed';
        });
        
        // Hide error status after a delay
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _audioProcessingStatus = '';
            });
          }
        });
      }
      await _disableWakelock();
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final isCreating = ref.watch(statusNotifierProvider.select((state) => 
        state.valueOrNull?.isCreatingStatus ?? false));

    return Scaffold(
      backgroundColor: widget.type == StatusType.text 
          ? _selectedBackgroundColor 
          : modernTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.xmark,
            color: widget.type == StatusType.text ? Colors.white : modernTheme.textColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getAppBarTitle(),
          style: TextStyle(
            color: widget.type == StatusType.text ? Colors.white : modernTheme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (widget.type == StatusType.text) _buildTextStatusActions(),
          _buildPrivacyButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (isCreating || _isProcessingAudio) _buildLoadingOverlay(),
        ],
      ),
      floatingActionButton: _buildSendButton(),
    );
  }

  String _getAppBarTitle() {
    switch (widget.type) {
      case StatusType.text:
        return 'Text Status';
      case StatusType.image:
        return 'Image Status';
      case StatusType.video:
        return 'Video Status';
      default:
        return 'Create Status';
    }
  }

  Widget _buildBody() {
    switch (widget.type) {
      case StatusType.text:
        return _buildTextStatusBody();
      case StatusType.image:
        return _buildImageStatusBody();
      case StatusType.video:
        return _buildVideoStatusBody();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextStatusBody() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: TextField(
            controller: _textController,
            focusNode: _textFocusNode,
            maxLines: null,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
              fontFamily: _selectedFontFamily == 'Default' ? null : _selectedFontFamily,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Type a status...',
              hintStyle: TextStyle(
                color: Colors.white70,
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageStatusBody() {
    final modernTheme = context.modernTheme;
    
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: widget.mediaFile != null
                    ? Image.file(
                        widget.mediaFile!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        color: modernTheme.surfaceColor,
                        child: Center(
                          child: Icon(
                            CupertinoIcons.photo,
                            size: 64,
                            color: modernTheme.textSecondaryColor,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _textController,
              maxLines: 3,
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Add a caption...',
                hintStyle: TextStyle(
                  color: modernTheme.textSecondaryColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: modernTheme.dividerColor!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: modernTheme.primaryColor!),
                ),
                filled: true,
                fillColor: modernTheme.surfaceColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoStatusBody() {
    final modernTheme = context.modernTheme;
    
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (widget.mediaFile != null)
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.black,
                        child: const Center(
                          child: Icon(
                            CupertinoIcons.play_circle,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      Container(
                        color: modernTheme.surfaceColor,
                        child: Center(
                          child: Icon(
                            CupertinoIcons.videocam,
                            size: 64,
                            color: modernTheme.textSecondaryColor,
                          ),
                        ),
                      ),
                    
                    // Audio processing indicator overlay
                    if (_isProcessingAudio)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.waveform,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _audioProcessingStatus,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // Audio processing progress indicator
          if (_isProcessingAudio)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: modernTheme.primaryColor!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: modernTheme.primaryColor!.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.waveform,
                        color: modernTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _audioProcessingStatus.isEmpty 
                              ? 'Processing audio...'
                              : _audioProcessingStatus,
                          style: TextStyle(
                            color: modernTheme.textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _audioProcessingProgress,
                    backgroundColor: modernTheme.borderColor,
                    valueColor: AlwaysStoppedAnimation<Color>(modernTheme.primaryColor!),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_audioProcessingProgress * 100).toStringAsFixed(0)}% complete',
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          
          // Caption input
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _textController,
              maxLines: 3,
              enabled: !_isProcessingAudio, // Disable during processing
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Add a caption...',
                hintStyle: TextStyle(
                  color: modernTheme.textSecondaryColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: modernTheme.dividerColor!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: modernTheme.primaryColor!),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: modernTheme.dividerColor!.withOpacity(0.5)),
                ),
                filled: true,
                fillColor: _isProcessingAudio 
                    ? modernTheme.surfaceColor!.withOpacity(0.5)
                    : modernTheme.surfaceColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextStatusActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(CupertinoIcons.textformat, color: Colors.white),
          onPressed: _showFontOptions,
        ),
        IconButton(
          icon: const Icon(CupertinoIcons.color_filter, color: Colors.white),
          onPressed: _showColorOptions,
        ),
      ],
    );
  }

  Widget _buildPrivacyButton() {
    return IconButton(
      icon: Icon(
        _getPrivacyIcon(),
        color: widget.type == StatusType.text ? Colors.white : context.modernTheme.textColor,
      ),
      onPressed: _showPrivacyOptions,
    );
  }

  IconData _getPrivacyIcon() {
    switch (_selectedPrivacy) {
      case StatusPrivacyType.all_contacts:
        return CupertinoIcons.person_2;
      case StatusPrivacyType.except:
        return CupertinoIcons.minus_circle;
      case StatusPrivacyType.only:
        return CupertinoIcons.person_circle;
    }
  }

  Widget _buildSendButton() {
    final modernTheme = context.modernTheme;
    final canSend = _canSend() && !_isProcessingAudio;
    
    return FloatingActionButton(
      onPressed: canSend ? _sendStatus : null,
      backgroundColor: canSend 
          ? modernTheme.primaryColor 
          : modernTheme.primaryColor!.withOpacity(0.5),
      child: _isProcessingAudio
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(
              CupertinoIcons.paperplane_fill,
              color: Colors.white,
            ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              _isProcessingAudio ? 'Processing audio...' : 'Creating status...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_isProcessingAudio) ...[
              const SizedBox(height: 8),
              Text(
                'Enhancing audio quality for better experience',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _canSend() {
    switch (widget.type) {
      case StatusType.text:
        return _textController.text.trim().isNotEmpty;
      case StatusType.image:
      case StatusType.video:
        return widget.mediaFile != null;
      default:
        return false;
    }
  }

  void _showColorOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Background Color',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _backgroundColors.map((color) {
                final isSelected = color == _selectedBackgroundColor;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedBackgroundColor = color;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showFontOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Font',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            ...(_fontFamilies.map((font) {
              final isSelected = font == _selectedFontFamily || 
                  (font == 'Default' && _selectedFontFamily == null);
              return ListTile(
                title: Text(
                  'Sample Text',
                  style: TextStyle(
                    fontFamily: font == 'Default' ? null : font,
                    fontSize: 18,
                  ),
                ),
                subtitle: Text(font),
                leading: Radio<String?>(
                  value: font == 'Default' ? null : font,
                  groupValue: _selectedFontFamily,
                  onChanged: (value) {
                    setState(() {
                      _selectedFontFamily = value;
                    });
                    Navigator.pop(context);
                  },
                ),
                selected: isSelected,
              );
            }).toList()),
          ],
        ),
      ),
    );
  }

  void _showPrivacyOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Who can see your status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(CupertinoIcons.person_2),
              title: const Text('My contacts'),
              subtitle: const Text('Share with all your contacts'),
              trailing: Radio<StatusPrivacyType>(
                value: StatusPrivacyType.all_contacts,
                groupValue: _selectedPrivacy,
                onChanged: (value) {
                  setState(() {
                    _selectedPrivacy = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.minus_circle),
              title: const Text('My contacts except...'),
              subtitle: const Text('Share with all contacts except specific ones'),
              trailing: Radio<StatusPrivacyType>(
                value: StatusPrivacyType.except,
                groupValue: _selectedPrivacy,
                onChanged: (value) {
                  setState(() {
                    _selectedPrivacy = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.person_circle),
              title: const Text('Only share with...'),
              subtitle: const Text('Only share with specific contacts'),
              trailing: Radio<StatusPrivacyType>(
                value: StatusPrivacyType.only,
                groupValue: _selectedPrivacy,
                onChanged: (value) {
                  setState(() {
                    _selectedPrivacy = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendStatus() async {
    if (!_canSend() || _isProcessingAudio) return;

    try {
      final statusNotifier = ref.read(statusNotifierProvider.notifier);
      File? finalMediaFile = widget.mediaFile;

      // Enable wakelock during status creation
      await _enableWakelock();

      // Process audio for video status
      if (widget.type == StatusType.video && widget.mediaFile != null) {
        final processedFile = await _processVideoAudio(widget.mediaFile!);
        if (processedFile != null) {
          finalMediaFile = processedFile;
          _processedMediaFile = processedFile;
          debugPrint('Using audio-processed video for status');
        } else {
          debugPrint('Using original video for status');
        }
      }

      switch (widget.type) {
        case StatusType.text:
          await statusNotifier.createTextStatus(
            content: _textController.text.trim(),
            backgroundColor: _selectedBackgroundColor,
            fontFamily: _selectedFontFamily,
            privacy: _selectedPrivacy,
          );
          break;

        case StatusType.image:
          if (finalMediaFile != null) {
            await statusNotifier.createImageStatus(
              imageFile: finalMediaFile,
              content: _textController.text.trim(),
              privacy: _selectedPrivacy,
            );
          }
          break;

        case StatusType.video:
          if (finalMediaFile != null) {
            await statusNotifier.createVideoStatus(
              videoFile: finalMediaFile,
              content: _textController.text.trim(),
              privacy: _selectedPrivacy,
            );
          }
          break;

        default:
          break;
      }

      if (mounted) {
        Navigator.pop(context);
        showSnackBar(context, 'Status posted successfully!');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to post status: $e');
      }
    } finally {
      // Disable wakelock after status creation
      await _disableWakelock();
      
      // Clean up processed file if created and different from original
      if (_processedMediaFile != null && _processedMediaFile != widget.mediaFile) {
        try {
          await _processedMediaFile!.delete();
          debugPrint('Cleaned up processed video file');
        } catch (e) {
          debugPrint('Error cleaning up processed file: $e');
        }
      }
    }
  }
}

// Status type selection screen with enhanced video option
class StatusTypeSelectionScreen extends StatelessWidget {
  const StatusTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;

    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: modernTheme.appBarColor,
        title: Text(
          'Create Status',
          style: TextStyle(
            color: modernTheme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(CupertinoIcons.xmark, color: modernTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Enhanced tip for video with audio processing
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: modernTheme.primaryColor!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: modernTheme.primaryColor!.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.waveform,
                      color: modernTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enhanced Audio for Videos',
                            style: TextStyle(
                              color: modernTheme.textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Video status now includes automatic audio enhancement for crystal clear sound',
                            style: TextStyle(
                              color: modernTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              _buildOptionCard(
                context: context,
                icon: CupertinoIcons.textformat,
                title: 'Text',
                subtitle: 'Share your thoughts with text',
                color: Colors.blue,
                onTap: () => _navigateToCreateStatus(context, StatusType.text),
              ),
              const SizedBox(height: 16),
              _buildOptionCard(
                context: context,
                icon: CupertinoIcons.camera,
                title: 'Camera',
                subtitle: 'Take a photo to share',
                color: Colors.green,
                onTap: () => _pickImageFromCamera(context),
              ),
              const SizedBox(height: 16),
              _buildOptionCard(
                context: context,
                icon: CupertinoIcons.photo,
                title: 'Photo',
                subtitle: 'Choose a photo from gallery',
                color: Colors.purple,
                onTap: () => _pickImageFromGallery(context),
              ),
              const SizedBox(height: 16),
              _buildOptionCard(
                context: context,
                icon: CupertinoIcons.videocam,
                title: 'Video',
                subtitle: 'Choose a video with enhanced audio',
                color: Colors.orange,
                onTap: () => _pickVideoFromGallery(context),
                badge: 'Enhanced',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    final modernTheme = context.modernTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: modernTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: modernTheme.dividerColor!,
            width: 0.5,
          ),
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
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: modernTheme.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (title == 'Video') ...[
                        const SizedBox(width: 8),
                        Icon(
                          CupertinoIcons.waveform,
                          size: 16,
                          color: color,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: modernTheme.textSecondaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateStatus(BuildContext context, StatusType type, {File? mediaFile}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateStatusScreen(
          type: type,
          mediaFile: mediaFile,
        ),
      ),
    );
  }

  void _pickImageFromCamera(BuildContext context) async {
    final imageFile = await pickImage(
      fromCamera: true,
      onFail: (error) => showSnackBar(context, error),
    );

    if (imageFile != null) {
      _navigateToCreateStatus(context, StatusType.image, mediaFile: imageFile);
    }
  }

  void _pickImageFromGallery(BuildContext context) async {
    final imageFile = await pickImage(
      fromCamera: false,
      onFail: (error) => showSnackBar(context, error),
    );

    if (imageFile != null) {
      _navigateToCreateStatus(context, StatusType.image, mediaFile: imageFile);
    }
  }

  void _pickVideoFromGallery(BuildContext context) async {
    final videoFile = await pickVideo(
      onFail: (error) => showSnackBar(context, error),
      maxDuration: const Duration(seconds: 30), // Status video limit (WhatsApp-like)
    );

    if (videoFile != null) {
      _navigateToCreateStatus(context, StatusType.video, mediaFile: videoFile);
    }
  }
}
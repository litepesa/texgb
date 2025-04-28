import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound_record/flutter_sound_record.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/chat/chat_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/features/chat/widgets/message_reply_preview.dart';

part 'recording_indicator.dart';
part 'more_options_grid.dart';

class BottomChatField extends StatefulWidget {
  const BottomChatField({
    super.key,
    required this.contactUID,
    required this.contactName,
    required this.contactImage,
    required this.groupId,
  });

  final String contactUID;
  final String contactName;
  final String contactImage;
  final String groupId;

  @override
  State<BottomChatField> createState() => _BottomChatFieldState();
}

class _BottomChatFieldState extends State<BottomChatField> with SingleTickerProviderStateMixin {
  // Animation controller for transitions
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  // Input controllers
  late final TextEditingController _textEditingController;
  late final FocusNode _focusNode;
  
  // Audio recording
  late final FlutterSoundRecord _soundRecord;
  
  // File handling
  File? _finalFileImage;
  String _filePath = '';

  // UI state
  bool _isRecording = false;
  bool _isShowSendButton = false;
  bool _isSendingAudio = false;
  bool _isShowEmojiPicker = false;
  bool _isShowMoreOptions = false;
  bool _isVoiceMode = false;
  bool _isSendingFile = false;

  // Recording state
  double _recordingPosition = 0.0;
  int _recordingDuration = 0;
  DateTime? _recordingStartTime;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _soundRecord = FlutterSoundRecord();
    _focusNode = FocusNode();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _soundRecord.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Hides the emoji picker container
  void _hideEmojiContainer() {
    if (mounted) {
      setState(() => _isShowEmojiPicker = false);
    }
  }

  /// Shows the emoji picker container with animation
  void _showEmojiContainer() {
    if (mounted) {
      setState(() {
        _isShowEmojiPicker = true;
        _isShowMoreOptions = false;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  /// Toggles the more options panel with animation
  void _toggleMoreOptions() {
    if (mounted) {
      setState(() {
        _isShowMoreOptions = !_isShowMoreOptions;
        if (_isShowMoreOptions) {
          _isShowEmojiPicker = false;
          _hideKeyboard();
          _animationController.reset();
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      });
    }
  }

  /// Toggles between voice and text input modes
  void _toggleVoiceTextMode() {
    HapticFeedback.lightImpact();
    if (mounted) {
      setState(() {
        _isVoiceMode = !_isVoiceMode;
        if (_isVoiceMode) {
          _hideKeyboard();
          _hideEmojiContainer();
        }
      });
    }
  }

  /// Shows the keyboard
  void _showKeyboard() => _focusNode.requestFocus();

  /// Hides the keyboard
  void _hideKeyboard() => _focusNode.unfocus();

  /// Toggles between emoji picker and keyboard
  void _toggleEmojiKeyboardContainer() {
    HapticFeedback.lightImpact();
    if (_isShowEmojiPicker) {
      _showKeyboard();
      _hideEmojiContainer();
    } else {
      _hideKeyboard();
      _showEmojiContainer();
    }
  }

  /// Starts the recording timer
  void _startRecordingTimer() {
    _recordingStartTime = DateTime.now();
    Future.doWhile(() async {
      if (!_isRecording || !mounted) return false;
      final now = DateTime.now();
      final difference = now.difference(_recordingStartTime!);
      if (mounted) {
        setState(() => _recordingDuration = difference.inSeconds);
      }
      await Future.delayed(const Duration(seconds: 1));
      return _isRecording && mounted;
    });
  }

  /// Formats duration into MM:SS format
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Checks and requests microphone permission
  Future<bool> _checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      if (!status.isGranted) {
        final result = await Permission.microphone.request();
        return result.isGranted;
      }
      return true;
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to check microphone permission');
      }
      return false;
    }
  }

  /// Starts audio recording
  Future<void> _startRecording() async {
    final hasPermission = await _checkMicrophonePermission();
    if (!hasPermission) {
      if (mounted) {
        showSnackBar(context, 'Microphone permission denied');
      }
      return;
    }

    HapticFeedback.heavyImpact();
    try {
      final tempDir = await getTemporaryDirectory();
      _filePath = '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';
      await _soundRecord.start(path: _filePath);
      
      setState(() {
        _isRecording = true;
        _recordingPosition = 0.0;
        _recordingDuration = 0;
        _isShowEmojiPicker = false;
        _isShowMoreOptions = false;
      });
      
      _startRecordingTimer();
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to start recording');
      }
    }
  }

  /// Updates recording slide position during drag
  void _updateRecordingPosition(DragUpdateDetails details) {
    if (_isRecording && mounted) {
      setState(() {
        _recordingPosition += details.primaryDelta ?? 0;
        _recordingPosition = _recordingPosition.clamp(-150.0, 0.0);
      });
    }
  }

  /// Handles recording slide end gesture
  void _onRecordingSlideEnd(DragEndDetails details) {
    if (!_isRecording) return;
    
    final shouldCancel = _recordingPosition < -100 || 
        (details.primaryVelocity != null && details.primaryVelocity! < -1000);
    
    if (shouldCancel) {
      _cancelRecording();
    } else {
      _resetRecordingPosition();
    }
  }

  /// Smoothly resets recording position with animation
  void _resetRecordingPosition() {
    final controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    final animation = Tween<double>(
      begin: _recordingPosition,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));
    
    animation.addListener(() {
      if (mounted) {
        setState(() => _recordingPosition = animation.value);
      }
    });
    
    controller.forward();
  }

  /// Cancels the current recording
  Future<void> _cancelRecording() async {
    HapticFeedback.mediumImpact();
    try {
      await _soundRecord.stop();
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingPosition = 0.0;
        });
      }
      
      final file = File(_filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to cancel recording');
      }
    }
  }

  /// Stops recording and sends the audio
  Future<void> _stopRecording() async {
    HapticFeedback.mediumImpact();
    try {
      await _soundRecord.stop();
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isSendingAudio = true;
        });
      }
      await _sendFileMessage(messageType: MessageEnum.audio);
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to stop recording');
        setState(() => _isRecording = false);
      }
    }
  }

  /// Selects an image from camera or gallery
  Future<void> _selectImage(bool fromCamera) async {
    setState(() => _isSendingFile = true);
    
    try {
      _finalFileImage = await pickImage(
        fromCamera: fromCamera,
        onFail: (String message) {
          if (mounted) {
            showSnackBar(context, message);
            setState(() => _isSendingFile = false);
          }
        },
      );

      if (_finalFileImage == null) {
        setState(() => _isSendingFile = false);
        return;
      }

      await _cropImage(_finalFileImage?.path);
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to select image');
        setState(() => _isSendingFile = false);
      }
    }
  }

  /// Selects a video file
  Future<void> _selectVideo() async {
    setState(() {
      _isSendingFile = true;
      _isShowMoreOptions = false;
    });
    
    try {
      final fileVideo = await pickVideo(
        onFail: (String message) {
          if (mounted) {
            showSnackBar(context, message);
            setState(() => _isSendingFile = false);
          }
        },
      );

      if (fileVideo != null) {
        _filePath = fileVideo.path;
        await _sendFileMessage(messageType: MessageEnum.video);
      } else {
        setState(() => _isSendingFile = false);
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to select video');
        setState(() => _isSendingFile = false);
      }
    }
  }

  /// Crops the selected image
  Future<void> _cropImage(String? croppedFilePath) async {
    if (croppedFilePath == null) {
      setState(() => _isSendingFile = false);
      return;
    }

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: croppedFilePath,
        maxHeight: 800,
        maxWidth: 800,
        compressQuality: 90,
      );

      if (croppedFile != null) {
        _filePath = croppedFile.path;
        await _sendFileMessage(messageType: MessageEnum.image);
      } else {
        setState(() => _isSendingFile = false);
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to crop image');
        setState(() => _isSendingFile = false);
      }
    }
  }

  /// Sends a file message (image, video, audio)
  Future<void> _sendFileMessage({
  required MessageEnum messageType,
}) async {
  try {
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    final chatProvider = context.read<ChatProvider>();

    await chatProvider.sendFileMessage(
      sender: currentUser,
      contactUID: widget.contactUID,
      contactName: widget.contactName,
      contactImage: widget.contactImage,
      file: File(_filePath),
      messageType: messageType,
      groupId: widget.groupId,
      onSucess: () {
        if (mounted) {
          _textEditingController.clear();
          _focusNode.unfocus();
          setState(() {
            _isSendingAudio = false;
            _isShowMoreOptions = false;
            _isSendingFile = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          showSnackBar(context, error);
          setState(() {
            _isSendingAudio = false;
            _isShowMoreOptions = false;
            _isSendingFile = false;
          });
        }
      },
    );
  } catch (e) {
    if (mounted) {
      showSnackBar(context, 'Failed to send file message');
      setState(() {
        _isSendingAudio = false;
        _isShowMoreOptions = false;
        _isSendingFile = false;
      });
    }
  }
}

  /// Sends a text message
  void _sendTextMessage() {
  if (_textEditingController.text.trim().isEmpty) return;
  
  HapticFeedback.lightImpact();
  try {
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    final chatProvider = context.read<ChatProvider>();

    // Make this an async call
    chatProvider.sendTextMessage(
      sender: currentUser,
      contactUID: widget.contactUID,
      contactName: widget.contactName,
      contactImage: widget.contactImage,
      message: _textEditingController.text.trim(),
      messageType: MessageEnum.text,
      groupId: widget.groupId,
      onSucess: () {
        if (mounted) {
          _textEditingController.clear();
          setState(() => _isShowSendButton = false);
        }
      },
      onError: (error) {
        if (mounted) {
          showSnackBar(context, error);
        }
      },
    );
  } catch (e) {
    if (mounted) {
      showSnackBar(context, 'Failed to send message');
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<ModernThemeExtension>();
    final backgroundColor = themeExtension?.backgroundColor ?? const Color(0xFFF6F6F6);
    final appBarColor = themeExtension?.appBarColor ?? const Color(0xFFEDEDED);
    final accentColor = themeExtension?.accentColor ?? const Color(0xFF07C160);
    
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: bottomPadding > 0 ? bottomPadding : 0,
        ),
        child: _buildBottomChatField(backgroundColor, appBarColor, accentColor),
      ),
    );
  }

  Widget _buildBottomChatField(Color backgroundColor, Color appBarColor, Color accentColor) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final messageReply = chatProvider.messageReplyModel;
        final isMessageReply = messageReply != null;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Message reply preview
            if (isMessageReply)
              Container(
                padding: const EdgeInsets.all(8.0),
                child: MessageReplyPreview(
                  replyMessageModel: messageReply,
                ),
              ),
            
            // Recording indicator
            if (_isRecording)
              RecordingIndicator(
                recordingPosition: _recordingPosition,
                recordingDuration: _recordingDuration,
                accentColor: accentColor,
                onDragUpdate: _updateRecordingPosition,
                onDragEnd: _onRecordingSlideEnd,
                onStopRecording: _stopRecording,
                formatDuration: _formatDuration,
              ),
                
            // Main input area
            if (!_isRecording)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    // Voice/text toggle button
                    IconButton(
                      icon: Icon(
                        _isVoiceMode ? Icons.keyboard : Icons.keyboard_voice,
                        color: Colors.grey[600],
                      ),
                      onPressed: _toggleVoiceTextMode,
                      tooltip: _isVoiceMode ? 'Switch to keyboard' : 'Switch to voice input',
                    ),
                    
                    // Voice button or text input field
                    if (_isVoiceMode)
                      Expanded(
                        child: GestureDetector(
                          onLongPress: _startRecording,
                          onLongPressEnd: (_) => _stopRecording(),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 15.0),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(18.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.mic_none,
                                  color: Colors.grey[600],
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Hold to record voice message',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 100),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(18.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),)
                              ],
                            ),
                            child: TextField(
                              controller: _textEditingController,
                              focusNode: _focusNode,
                              maxLines: 3,
                              minLines: 1,
                              style: TextStyle(
                                fontSize: 16.0,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Message',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 10.0,
                                ),
                                hintStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              onChanged: (value) {
                                if (mounted) {
                                  setState(() => _isShowSendButton = value.isNotEmpty);
                                }
                              },
                              onTap: () {
                                _hideEmojiContainer();
                                if (mounted) {
                                  setState(() => _isShowMoreOptions = false);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                
                    if (!_isVoiceMode) 
                      IconButton(
                        icon: Icon(
                          _isShowEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                          color: Colors.grey[600],
                        ),
                        onPressed: _toggleEmojiKeyboardContainer,
                        splashRadius: 20,
                        tooltip: _isShowEmojiPicker ? 'Show keyboard' : 'Show emojis',
                      ),
                
                    // Send button or more options
                    if (_isShowSendButton && !_isVoiceMode)
                      chatProvider.isLoading
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: accentColor,
                                ),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Material(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(18.0),
                                child: InkWell(
                                  onTap: _sendTextMessage,
                                  borderRadius: BorderRadius.circular(18.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: const Text(
                                      'Send',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                    else if (!_isVoiceMode)
                      IconButton(
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: Colors.grey[600],
                        ),
                        onPressed: _toggleMoreOptions,
                        splashRadius: 20,
                        tooltip: 'More options',
                      ),
                  ],
                ),
              ),
            
            // File sending indicator
            if (_isSendingFile && !_isRecording)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                margin: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Preparing file...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    )
                  ],
                ),
              ),
            
            // More options grid
            if (_isShowMoreOptions && !_isRecording && !_isSendingFile)
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizeTransition(
                  sizeFactor: _fadeAnimation,
                  axisAlignment: -1.0,
                  child: MoreOptionsGrid(
                    accentColor: accentColor,
                    onSelectImage: _selectImage,
                    onSelectVideo: _selectVideo,
                    onStartRecording: _startRecording,
                  ),
                ),
              ),
            
            // Emoji picker
            if (_isShowEmojiPicker && !_isRecording && !_isSendingFile)
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizeTransition(
                  sizeFactor: _fadeAnimation,
                  axisAlignment: -1.0,
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.3,
                    child: EmojiPicker(
                      onEmojiSelected: (category, Emoji emoji) {
                        _textEditingController.text = _textEditingController.text + emoji.emoji;
                        if (mounted && !_isShowSendButton) {
                          setState(() => _isShowSendButton = true);
                        }
                      },
                      onBackspacePressed: () {
                        _textEditingController.text = _textEditingController
                            .text.characters.skipLast(1).toString();
                        if (mounted && _textEditingController.text.isEmpty) {
                          setState(() => _isShowSendButton = false);
                        }
                      },
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound_record/flutter_sound_record.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/features/chat/widgets/message_reply_preview.dart';

part 'recording_indicator.dart';
part 'more_options_grid.dart';

class BottomChatField extends ConsumerStatefulWidget {
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
  ConsumerState<BottomChatField> createState() => _BottomChatFieldState();
}

class _BottomChatFieldState extends ConsumerState<BottomChatField> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final TextEditingController _textEditingController;
  late final FocusNode _focusNode;
  late final FlutterSoundRecord _soundRecord;

  File? _finalFileImage;
  String _filePath = '';
  bool _isRecording = false;
  bool _isShowSendButton = false;
  bool _isSendingAudio = false;
  bool _isShowMoreOptions = false;
  bool _isVoiceMode = false;
  bool _isSendingFile = false;
  double _recordingPosition = 0.0;
  int _recordingDuration = 0;
  DateTime? _recordingStartTime;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _soundRecord = FlutterSoundRecord();
    _focusNode = FocusNode();
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

  void _toggleMoreOptions() {
    if (mounted) {
      setState(() {
        _isShowMoreOptions = !_isShowMoreOptions;
        if (_isShowMoreOptions) {
          _hideKeyboard();
          _animationController.reset();
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      });
    }
  }

  void _toggleVoiceTextMode() {
    HapticFeedback.lightImpact();
    if (mounted) {
      setState(() {
        _isVoiceMode = !_isVoiceMode;
        if (_isVoiceMode) {
          _hideKeyboard();
        }
      });
    }
  }

  void _showKeyboard() => _focusNode.requestFocus();

  void _hideKeyboard() => _focusNode.unfocus();

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

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

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
        _isShowMoreOptions = false;
      });
      _startRecordingTimer();
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to start recording');
      }
    }
  }

  void _updateRecordingPosition(DragUpdateDetails details) {
    if (_isRecording && mounted) {
      setState(() {
        _recordingPosition += details.primaryDelta ?? 0;
        _recordingPosition = _recordingPosition.clamp(-150.0, 0.0);
      });
    }
  }

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

  Future<void> _sendFileMessage({
    required MessageEnum messageType,
  }) async {
    try {
      final currentUser = ref.read(authenticationProvider).valueOrNull?.userModel;
      if (currentUser == null) return;

      final chatNotifier = ref.read(chatProvider.notifier);
      await chatNotifier.sendFileMessage(
        sender: currentUser,
        contactUID: widget.contactUID,
        contactName: widget.contactName,
        contactImage: widget.contactImage,
        file: File(_filePath),
        messageType: messageType,
        groupId: widget.groupId,
        onSuccess: () {
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

  void _sendTextMessage() {
    if (_textEditingController.text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    try {
      final currentUser = ref.read(authenticationProvider).valueOrNull?.userModel;
      if (currentUser == null) return;

      final chatNotifier = ref.read(chatProvider.notifier);
      chatNotifier.sendTextMessage(
        sender: currentUser,
        contactUID: widget.contactUID,
        contactName: widget.contactName,
        contactImage: widget.contactImage,
        message: _textEditingController.text.trim(),
        messageType: MessageEnum.text,
        groupId: widget.groupId,
        onSuccess: () {
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
    final backgroundColor = themeExtension?.backgroundColor ?? const Color(0xFF131C21);
    final surfaceColor = themeExtension?.surfaceColor ?? const Color(0xFF1F2C34);
    final accentColor = themeExtension?.accentColor ?? const Color(0xFF25D366);
    final textColor = themeExtension?.textColor ?? const Color(0xFFF1F1F2);
    final textSecondaryColor = themeExtension?.textSecondaryColor ?? Colors.grey;
    final inputBackgroundColor = themeExtension?.inputBackgroundColor ?? const Color(0xFF252D31);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final chatState = ref.watch(chatStateProvider);
    final isLoading = ref.watch(chatProvider.select((state) => state.value?.isLoading ?? false));
    final messageReply = ref.watch(messageReplyProvider);

    return SafeArea(
      bottom: true,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding > 0 ? bottomPadding : 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (messageReply != null)
              Container(
                padding: const EdgeInsets.all(8.0),
                color: surfaceColor,
                child: MessageReplyPreview(
                  replyMessageModel: messageReply,
                ),
              ),
            if (_isRecording)
              RecordingIndicator(
                recordingPosition: _recordingPosition,
                recordingDuration: _recordingDuration,
                accentColor: accentColor,
                backgroundColor: surfaceColor,
                textColor: textColor,
                secondaryTextColor: textSecondaryColor,
                onDragUpdate: _updateRecordingPosition,
                onDragEnd: _onRecordingSlideEnd,
                onStopRecording: _stopRecording,
                formatDuration: _formatDuration,
              ),
            if (!_isRecording)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isVoiceMode ? Icons.keyboard : Icons.keyboard_voice,
                        color: textSecondaryColor,
                      ),
                      onPressed: _toggleVoiceTextMode,
                      tooltip: _isVoiceMode ? 'Switch to keyboard' : 'Switch to voice input',
                    ),
                    if (_isVoiceMode)
                      Expanded(
                        child: GestureDetector(
                          onLongPress: _startRecording,
                          onLongPressEnd: (_) => _stopRecording(),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 15.0),
                            decoration: BoxDecoration(
                              color: inputBackgroundColor,
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
                                  color: textSecondaryColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Hold to record voice message',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: textSecondaryColor,
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
                              color: inputBackgroundColor,
                              borderRadius: BorderRadius.circular(18.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                )
                              ],
                            ),
                            child: TextField(
                              controller: _textEditingController,
                              focusNode: _focusNode,
                              maxLines: 3,
                              minLines: 1,
                              style: TextStyle(
                                fontSize: 16.0,
                                color: textColor,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Message',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 10.0,
                                ),
                                hintStyle: TextStyle(
                                  color: textSecondaryColor,
                                  fontSize: 16,
                                ),
                                filled: true,
                                fillColor: inputBackgroundColor,
                              ),
                              onChanged: (value) {
                                if (mounted) {
                                  setState(() => _isShowSendButton = value.isNotEmpty);
                                }
                              },
                              onTap: () {
                                if (mounted) {
                                  setState(() => _isShowMoreOptions = false);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    if (_isShowSendButton && !_isVoiceMode)
                      isLoading
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
                                    child: Text(
                                      'Send',
                                      style: TextStyle(
                                        color: textColor,
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
                          color: textSecondaryColor,
                        ),
                        onPressed: _toggleMoreOptions,
                        splashRadius: 20,
                        tooltip: 'More options',
                      ),
                  ],
                ),
              ),
            if (_isSendingFile && !_isRecording)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                margin: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: surfaceColor,
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
                        color: textColor,
                      ),
                    )
                  ],
                ),
              ),
            if (_isShowMoreOptions && !_isRecording && !_isSendingFile)
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizeTransition(
                  sizeFactor: _fadeAnimation,
                  axisAlignment: -1.0,
                  child: MoreOptionsGrid(
                    backgroundColor: surfaceColor,
                    accentColor: accentColor,
                    textColor: textColor,
                    onSelectImage: _selectImage,
                    onSelectVideo: _selectVideo,
                    onStartRecording: _startRecording,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
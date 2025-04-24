import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound_record/flutter_sound_record.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/chat/chat_provider.dart';
import 'package:textgb/features/groups/group_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/features/chat/widgets/message_reply_preview.dart';

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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  FlutterSoundRecord? _soundRecord;
  late TextEditingController _textEditingController;
  late FocusNode _focusNode;
  File? finalFileImage;
  String filePath = '';

  bool isRecording = false;
  bool isShowSendButton = false;
  bool isSendingAudio = false;
  bool isShowEmojiPicker = false;
  bool isShowMoreOptions = false;
  bool isVoiceMode = false;
  bool isSendingFile = false;

  // Recording variables
  double _recordingPosition = 0.0; // For slide to cancel UI
  int _recordingDuration = 0; // Recording duration in seconds
  DateTime? _recordingStartTime;

  // Hide emoji container
  void hideEmojiContainer() {
    if (mounted) {
      setState(() {
        isShowEmojiPicker = false;
      });
    }
  }

  // Show emoji container with animation
  void showEmojiContainer() {
    if (mounted) {
      setState(() {
        isShowEmojiPicker = true;
        isShowMoreOptions = false;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  // Toggle more options with animation
  void toggleMoreOptions() {
    if (mounted) {
      setState(() {
        isShowMoreOptions = !isShowMoreOptions;
        if (isShowMoreOptions) {
          isShowEmojiPicker = false;
          hideKeyNoard();
          _animationController.reset();
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      });
    }
  }

  // Toggle between voice and text input with haptic feedback
  void toggleVoiceTextMode() {
    HapticFeedback.lightImpact();
    if (mounted) {
      setState(() {
        isVoiceMode = !isVoiceMode;
        if (isVoiceMode) {
          hideKeyNoard();
          hideEmojiContainer();
        }
      });
    }
  }

  // Show keyboard
  void showKeyBoard() {
    _focusNode.requestFocus();
  }

  // Hide keyboard
  void hideKeyNoard() {
    _focusNode.unfocus();
  }

  // Toggle emoji and keyboard container
  void toggleEmojiKeyboardContainer() {
    HapticFeedback.lightImpact();
    if (isShowEmojiPicker) {
      showKeyBoard();
      hideEmojiContainer();
    } else {
      hideKeyNoard();
      showEmojiContainer();
    }
  }

  // Timer for recording duration
  void _startRecordingTimer() {
    _recordingStartTime = DateTime.now();
    Future.doWhile(() async {
      if (!isRecording || !mounted) return false;
      final now = DateTime.now();
      final difference = now.difference(_recordingStartTime!);
      if (mounted) {
        setState(() {
          _recordingDuration = difference.inSeconds;
        });
      }
      await Future.delayed(const Duration(seconds: 1));
      return isRecording && mounted;
    });
  }

  // Format recording time
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    _textEditingController = TextEditingController();
    _soundRecord = FlutterSoundRecord();
    _focusNode = FocusNode();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    super.initState();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _soundRecord?.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Check microphone permission
  Future<bool> checkMicrophonePermission() async {
    bool hasPermission = await Permission.microphone.isGranted;
    final status = await Permission.microphone.request();
    if (status == PermissionStatus.granted) {
      hasPermission = true;
    } else {
      hasPermission = false;
    }

    return hasPermission;
  }

  // Start recording audio
  void startRecording() async {
    final hasPermission = await checkMicrophonePermission();
    if (hasPermission) {
      HapticFeedback.heavyImpact(); // Provide haptic feedback when recording starts
      var tempDir = await getTemporaryDirectory();
      filePath = '${tempDir.path}/flutter_sound.aac';
      await _soundRecord!.start(
        path: filePath,
      );
      setState(() {
        isRecording = true;
        _recordingPosition = 0.0;
        _recordingDuration = 0;
        // Hide other UI elements while recording
        isShowEmojiPicker = false;
        isShowMoreOptions = false;
      });
      _startRecordingTimer();
    } else {
      showSnackBar(context, 'Microphone permission denied');
    }
  }

  // Update recording slide position
  void updateRecordingPosition(DragUpdateDetails details) {
    if (isRecording) {
      setState(() {
        // Limit the slide position to a valid range
        _recordingPosition += details.primaryDelta ?? 0;
        _recordingPosition = _recordingPosition.clamp(-150.0, 0.0);
      });
    }
  }

  // Handle end of recording slide
  void onRecordingSlideEnd(DragEndDetails details) {
    if (isRecording) {
      if (_recordingPosition < -100) {
        // Cancel recording if slide far enough to the left
        cancelRecording();
      } else {
        // Reset position if not canceled
        setState(() {
          _recordingPosition = 0.0;
        });
      }
    }
  }

  // Cancel recording
  void cancelRecording() async {
    HapticFeedback.mediumImpact();
    await _soundRecord!.stop();
    if (mounted) {
      setState(() {
        isRecording = false;
        _recordingPosition = 0.0;
      });
    }
    // Delete the recorded file
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore errors when deleting temp file
    }
  }

  // Stop recording audio
  void stopRecording() async {
    HapticFeedback.mediumImpact();
    await _soundRecord!.stop();
    setState(() {
      isRecording = false;
      isSendingAudio = true;
    });
    // Send audio message to firestore
    sendFileMessage(
      messageType: MessageEnum.audio,
    );
  }

  void selectImage(bool fromCamera) async {
    setState(() {
      isSendingFile = true;
    });
    
    finalFileImage = await pickImage(
      fromCamera: fromCamera,
      onFail: (String message) {
        showSnackBar(context, message);
        setState(() {
          isSendingFile = false;
        });
      },
    );

    // If user canceled the image picking
    if (finalFileImage == null) {
      setState(() {
        isSendingFile = false;
      });
      return;
    }

    // Crop image
    await cropImage(finalFileImage?.path);

    // Close more options panel
    setState(() {
      isShowMoreOptions = false;
    });
  }

  // Select a video file from device
  void selectVideo() async {
    setState(() {
      isSendingFile = true;
      isShowMoreOptions = false;
    });
    
    File? fileVideo = await pickVideo(
      onFail: (String message) {
        showSnackBar(context, message);
        setState(() {
          isSendingFile = false;
        });
      },
    );

    if (fileVideo != null) {
      filePath = fileVideo.path;
      // Send video message to firestore
      sendFileMessage(
        messageType: MessageEnum.video,
      );
    } else {
      setState(() {
        isSendingFile = false;
      });
    }
  }

  Future<void> cropImage(croppedFilePath) async {
    if (croppedFilePath != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: croppedFilePath,
        maxHeight: 800,
        maxWidth: 800,
        compressQuality: 90,
      );

      if (croppedFile != null) {
        filePath = croppedFile.path;
        // Send image message to firestore
        sendFileMessage(
          messageType: MessageEnum.image,
        );
      } else {
        // User canceled cropping
        setState(() {
          isSendingFile = false;
        });
      }
    }
  }

  // Send image message to firestore
  void sendFileMessage({
    required MessageEnum messageType,
  }) {
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    final chatProvider = context.read<ChatProvider>();

    chatProvider.sendFileMessage(
      sender: currentUser,
      contactUID: widget.contactUID,
      contactName: widget.contactName,
      contactImage: widget.contactImage,
      file: File(filePath),
      messageType: messageType,
      groupId: widget.groupId,
      onSucess: () {
        _textEditingController.clear();
        _focusNode.unfocus();
        setState(() {
          isSendingAudio = false;
          isShowMoreOptions = false;
          isSendingFile = false;
        });
      },
      onError: (error) {
        setState(() {
          isSendingAudio = false;
          isShowMoreOptions = false;
          isSendingFile = false;
        });
        showSnackBar(context, error);
      },
    );
  }

  // Send text message to firestore
  void sendTextMessage() {
    if (_textEditingController.text.trim().isEmpty) return;
    
    HapticFeedback.lightImpact(); // Light feedback when sending message
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    final chatProvider = context.read<ChatProvider>();

    chatProvider.sendTextMessage(
        sender: currentUser,
        contactUID: widget.contactUID,
        contactName: widget.contactName,
        contactImage: widget.contactImage,
        message: _textEditingController.text.trim(),
        messageType: MessageEnum.text,
        groupId: widget.groupId,
        onSucess: () {
          _textEditingController.clear();
          setState(() {
            isShowSendButton = false;
          });
        },
        onError: (error) {
          showSnackBar(context, error);
        });
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<ModernThemeExtension>();
    final backgroundColor = themeExtension?.backgroundColor ?? const Color(0xFFF6F6F6);
    final appBarColor = themeExtension?.appBarColor ?? const Color(0xFFEDEDED);
    final accentColor = themeExtension?.accentColor ?? const Color(0xFF07C160);
    
    return widget.groupId.isNotEmpty
        ? buildLoackedMessages()
        : buildBottomChatField(backgroundColor, appBarColor, accentColor);
  }

  Widget buildLoackedMessages() {
    final uid = context.read<AuthenticationProvider>().userModel!.uid;

    final groupProvider = context.read<GroupProvider>();
    // Check if is admin
    final isAdmin = groupProvider.groupModel.adminsUIDs.contains(uid);

    // Check if is member
    final isMember = groupProvider.groupModel.membersUIDs.contains(uid);

    // Check if messages are locked
    final isLocked = groupProvider.groupModel.lockMessages;
    
    final themeExtension = Theme.of(context).extension<ModernThemeExtension>();
    final backgroundColor = themeExtension?.backgroundColor ?? const Color(0xFFF6F6F6);
    final appBarColor = themeExtension?.appBarColor ?? const Color(0xFFEDEDED);
    final accentColor = themeExtension?.accentColor ?? const Color(0xFF07C160);
    
    return isAdmin
        ? buildBottomChatField(backgroundColor, appBarColor, accentColor)
        : isMember
            ? buildisMember(isLocked, backgroundColor, appBarColor, accentColor)
            : Container(
                height: 60,
                decoration: BoxDecoration(
                  color: appBarColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 3,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: Center(
                  child: TextButton(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      // Send request to join group
                      await groupProvider
                          .sendRequestToJoinGroup(
                        groupId: groupProvider.groupModel.groupId,
                        uid: uid,
                        groupName: groupProvider.groupModel.groupName,
                        groupImage: groupProvider.groupModel.groupImage,
                      )
                          .whenComplete(() {
                        showSnackBar(context, 'Request sent');
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      backgroundColor: Colors.red.withOpacity(0.1),
                    ),
                    child: const Text(
                      'Send request to join group',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
  }

  buildisMember(bool isLocked, Color backgroundColor, Color appBarColor, Color accentColor) {
    return isLocked
        ? Container(
            height: 50,
            color: appBarColor,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Only admins can send messages',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
        : buildBottomChatField(backgroundColor, appBarColor, accentColor);
  }

  Widget buildBottomChatField(Color backgroundColor, Color appBarColor, Color accentColor) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final messageReply = chatProvider.messageReplyModel;
        final isMessageReply = messageReply != null;
        
        return Container(
          decoration: BoxDecoration(
            color: appBarColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 3,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Column(
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
              if (isRecording)
                _buildRecordingIndicator(accentColor),
                
              // Normal input area (when not recording)
              if (!isRecording)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      // Voice/text toggle button
                      IconButton(
                        icon: Icon(
                          isVoiceMode ? Icons.keyboard : Icons.keyboard_voice,
                          color: Colors.grey[600],
                        ),
                        onPressed: toggleVoiceTextMode,
                      ),
                      
                      // Voice button or text input field
                      if (isVoiceMode)
                        Expanded(
                          child: GestureDetector(
                            onLongPress: startRecording,
                            onLongPressEnd: (_) => stopRecording(),
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
                            constraints: const BoxConstraints(
                              maxHeight: 100,
                            ),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
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
                                  setState(() {
                                    isShowSendButton = value.isNotEmpty;
                                  });
                                },
                                onTap: () {
                                  hideEmojiContainer();
                                  setState(() {
                                    isShowMoreOptions = false;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                    
                      if (!isVoiceMode) 
                        IconButton(
                          icon: Icon(
                            isShowEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                            color: Colors.grey[600],
                          ),
                          onPressed: toggleEmojiKeyboardContainer,
                          splashRadius: 20,
                        ),
                    
                      // More options or Send button
                      if (isShowSendButton && !isVoiceMode)
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
                                    onTap: sendTextMessage,
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
                      else if (!isVoiceMode)
                        IconButton(
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: Colors.grey[600],
                          ),
                          onPressed: toggleMoreOptions,
                          splashRadius: 20,
                        ),
                    ],
                  ),
                ),
              
              // File sending indicator
              if (isSendingFile && !isRecording)
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
              
              // More options grid with animation
              if (isShowMoreOptions && !isRecording && !isSendingFile)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizeTransition(
                    sizeFactor: _fadeAnimation,
                    axisAlignment: -1.0,
                    child: buildMoreOptionsGrid(context, accentColor),
                  ),
                ),
              
              // Emoji picker with animation
              if (isShowEmojiPicker && !isRecording && !isSendingFile)
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
                          
                          if (!isShowSendButton) {
                            setState(() {
                              isShowSendButton = true;
                            });
                          }
                        },
                        onBackspacePressed: () {
                          _textEditingController.text = _textEditingController
                              .text.characters.skipLast(1).toString();
                              
                          if (_textEditingController.text.isEmpty) {
                            setState(() {
                              isShowSendButton = false;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  // Recording indicator UI with slide to cancel
  Widget _buildRecordingIndicator(Color accentColor) {
    // Calculate the background color based on the slide position
    final cancelOpacity = _recordingPosition < -50 ? (_recordingPosition / -150).clamp(0.0, 1.0) : 0.0;
    final cancelColor = Colors.red.withOpacity(cancelOpacity * 0.3);
    
    return GestureDetector(
      onHorizontalDragUpdate: updateRecordingPosition,
      onHorizontalDragEnd: onRecordingSlideEnd,
      child: Container(
        color: cancelColor,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Row(
          children: [
            // Recording animation
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated circle
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 2),
                    builder: (context, value, child) {
                      return Container(
                        width: 30 + (value * 10),
                        height: 30 + (value * 10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.3 * (1 - value)),
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  ),
                  // Center dot
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Recording info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Recording',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(_recordingDuration),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Transform.translate(
                    offset: Offset(_recordingPosition, 0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_back,
                          size: 14,
                          color: _recordingPosition < -50 ? Colors.red : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Slide left to cancel",
                          style: TextStyle(
                            fontSize: 12,
                            color: _recordingPosition < -50 ? Colors.red : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Send button for audio
            GestureDetector(
              onTap: stopRecording,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget buildMoreOptionsGrid(BuildContext context, Color accentColor) {
    // WeChat-style feature grid
    final items = [
      {
        'icon': Icons.photo_library,
        'color': Colors.green,
        'label': 'Photos',
        'onTap': () => selectImage(false),
      },
      {
        'icon': Icons.camera_alt,
        'color': Colors.blue,
        'label': 'Camera',
        'onTap': () => selectImage(true),
      },
      {
        'icon': Icons.videocam,
        'color': Colors.red,
        'label': 'Video',
        'onTap': selectVideo,
      },
      {
        'icon': Icons.location_on,
        'color': Colors.orange,
        'label': 'Location',
        'onTap': () {},  // Placeholder
      },
      {
        'icon': Icons.mic,
        'color': Colors.purple,
        'label': 'Voice',
        'onTap': startRecording,
      },
      {
        'icon': Icons.insert_drive_file,
        'color': Colors.indigo,
        'label': 'Files',
        'onTap': () {},  // Placeholder
      },
      {
        'icon': Icons.person,
        'color': accentColor,
        'label': 'Contact',
        'onTap': () {},  // Placeholder
      },
      {
        'icon': Icons.sticky_note_2_outlined,
        'color': Colors.amber,
        'label': 'Stickers',
        'onTap': () {},  // Placeholder
      },
    ];
    
    return Container(
      height: 220,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).extension<ModernThemeExtension>()?.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // Handle indicator
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.9,
              ),
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (item['onTap'] != null) {
                        (item['onTap'] as Function)();
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    splashColor: (item['color'] as Color).withOpacity(0.1),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: (item['color'] as Color).withOpacity(0.12),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (item['color'] as Color).withOpacity(0.1),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: item['color'] as Color,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
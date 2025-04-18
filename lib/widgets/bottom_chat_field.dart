import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound_record/flutter_sound_record.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/providers/chat_provider.dart';
import 'package:textgb/providers/group_provider.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:textgb/widgets/message_reply_preview.dart';

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

class _BottomChatFieldState extends State<BottomChatField> {
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
  bool isVoiceMode = false; // Track voice/text input mode
  bool isSendingFile = false; // Track file sending state

  // hide emoji container
  void hideEmojiContainer() {
    setState(() {
      isShowEmojiPicker = false;
    });
  }

  // show emoji container
  void showEmojiContainer() {
    setState(() {
      isShowEmojiPicker = true;
      isShowMoreOptions = false; // Hide more options when showing emoji
    });
  }

  // Toggle more options
  void toggleMoreOptions() {
    setState(() {
      isShowMoreOptions = !isShowMoreOptions;
      if (isShowMoreOptions) {
        isShowEmojiPicker = false; // Hide emoji when showing more options
        hideKeyNoard();
      }
    });
  }

  // Toggle between voice and text input
  void toggleVoiceTextMode() {
    setState(() {
      isVoiceMode = !isVoiceMode;
      if (isVoiceMode) {
        hideKeyNoard();
        hideEmojiContainer();
      }
    });
  }

  // show keyboard
  void showKeyBoard() {
    _focusNode.requestFocus();
  }

  // hide keyboard
  void hideKeyNoard() {
    _focusNode.unfocus();
  }

  // toggle emoji and keyboard container
  void toggleEmojiKeyboardContainer() {
    if (isShowEmojiPicker) {
      showKeyBoard();
      hideEmojiContainer();
    } else {
      hideKeyNoard();
      showEmojiContainer();
    }
  }

  @override
  void initState() {
    _textEditingController = TextEditingController();
    _soundRecord = FlutterSoundRecord();
    _focusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _soundRecord?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // check microphone permission
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

  // start recording audio
  void startRecording() async {
    final hasPermission = await checkMicrophonePermission();
    if (hasPermission) {
      var tempDir = await getTemporaryDirectory();
      filePath = '${tempDir.path}/flutter_sound.aac';
      await _soundRecord!.start(
        path: filePath,
      );
      setState(() {
        isRecording = true;
        // Hide other UI elements while recording
        isShowEmojiPicker = false;
        isShowMoreOptions = false;
      });
    } else {
      showSnackBar(context, 'Microphone permission denied');
    }
  }

  // stop recording audio
  void stopRecording() async {
    await _soundRecord!.stop();
    setState(() {
      isRecording = false;
      isSendingAudio = true;
    });
    // send audio message to firestore
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

    // crop image
    await cropImage(finalFileImage?.path);

    // Close more options panel
    setState(() {
      isShowMoreOptions = false;
    });
  }

  // select a video file from device
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
      // send video message to firestore
      sendFileMessage(
        messageType: MessageEnum.video,
      );
    } else {
      setState(() {
        isSendingFile = false;
      });
    }
  }

  popContext() {
    Navigator.pop(context);
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
        // send image message to firestore
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

  // send image message to firestore
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

  // send text message to firestore
  void sendTextMessage() {
    if (_textEditingController.text.trim().isEmpty) return;
    
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
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
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
    // check if is admin
    final isAdmin = groupProvider.groupModel.adminsUIDs.contains(uid);

    // chec if is member
    final isMember = groupProvider.groupModel.membersUIDs.contains(uid);

    // check is messages are locked
    final isLocked = groupProvider.groupModel.lockMessages;
    
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final backgroundColor = themeExtension?.backgroundColor ?? const Color(0xFFF6F6F6);
    final appBarColor = themeExtension?.appBarColor ?? const Color(0xFFEDEDED);
    final accentColor = themeExtension?.accentColor ?? const Color(0xFF07C160);
    
    return isAdmin
        ? buildBottomChatField(backgroundColor, appBarColor, accentColor)
        : isMember
            ? buildisMember(isLocked, backgroundColor, appBarColor, accentColor)
            : SizedBox(
                height: 60,
                child: Center(
                  child: TextButton(
                    onPressed: () async {
                      // send request to join group
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
                    child: const Text(
                      'You are not a member of this group, \n click here to send request to join',
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
            child: const Center(
              child: Text(
                'Messages are locked, only admins can send messages',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
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
            border: Border(
              top: BorderSide(
                color: Colors.grey.withOpacity(0.2),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ensure the container only takes necessary height
            children: [
              // Message reply preview
              if (isMessageReply)
                Container(
                  padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                  child: MessageReplyPreview(
                    replyMessageModel: messageReply,
                  ),
                ),
              
              // Recording indicator
              if (isRecording)
                _buildRecordingIndicator(accentColor),
                
              // Normal input area (when not recording)
              if (!isRecording)
                Row(
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
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 15.0),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: const Text(
                              'Hold to record voice message',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 100, // Set maximum height
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(4.0),
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
                              decoration: const InputDecoration(
                                hintText: 'Message',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 10.0),
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
                      ),
                    
                    // More options or Send button
                    if (isShowSendButton && !isVoiceMode)
                      chatProvider.isLoading
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: accentColor,
                                ),
                              ),
                            )
                          : TextButton(
                              onPressed: sendTextMessage,
                              style: TextButton.styleFrom(
                                backgroundColor: accentColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                minimumSize: const Size(50, 36),
                              ),
                              child: const Text(
                                'Send',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
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
                      ),
                  ],
                ),
              
              // File sending indicator
              if (isSendingFile && !isRecording)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accentColor,
                      ),
                      const SizedBox(width: 12),
                      const Text('Preparing file...')
                    ],
                  ),
                ),
              
              // More options grid
              if (isShowMoreOptions && !isRecording && !isSendingFile)
                buildMoreOptionsGrid(context),
              
              // Emoji picker
              if (isShowEmojiPicker && !isRecording && !isSendingFile)
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.3, // Responsive height
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
            ],
          ),
        );
      },
    );
  }
  
  // Recording indicator UI
  Widget _buildRecordingIndicator(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(
                Icons.fiber_manual_record,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Recording audio...',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTap: stopRecording,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(20),
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
        ],
      ),
    );
  }
  
  Widget buildMoreOptionsGrid(BuildContext context) {
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
    ];
    
    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 16.0,
        ),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () {
              if (item['onTap'] != null) {
                (item['onTap'] as Function)();
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: (item['color'] as Color).withOpacity(0.1),
                  child: Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
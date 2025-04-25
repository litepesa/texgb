import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/chat/chat_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:textgb/features/chat/widgets/message_reply_preview.dart';

class BottomChatField extends StatefulWidget {
  const BottomChatField({
    Key? key,
    required this.contactUID,
    required this.contactName,
    required this.contactImage,
    required this.groupId,
  }) : super(key: key);

  final String contactUID;
  final String contactName;
  final String contactImage;
  final String groupId;

  @override
  State<BottomChatField> createState() => _BottomChatFieldState();
}

class _BottomChatFieldState extends State<BottomChatField> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  bool _isShowSendButton = false;
  
  // Animation controller for attachment options
  late AnimationController _attachmentController;
  late Animation<double> _attachmentAnimation;
  bool _showAttachments = false;
  
  // Voice recording state
  bool _isRecording = false;
  
  @override
  void initState() {
    super.initState();
    
    // Listen for text changes to toggle send button
    _messageController.addListener(() {
      if (_messageController.text.isNotEmpty) {
        setState(() {
          _isShowSendButton = true;
        });
      } else {
        setState(() {
          _isShowSendButton = false;
        });
      }
    });
    
    // Initialize animations
    _attachmentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    
    _attachmentAnimation = CurvedAnimation(
      parent: _attachmentController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _attachmentController.dispose();
    super.dispose();
  }
  
  // Show the attachment options
  void _toggleAttachmentOptions() {
    setState(() {
      _showAttachments = !_showAttachments;
    });
    
    if (_showAttachments) {
      _attachmentController.forward();
    } else {
      _attachmentController.reverse();
    }
  }
  
  // Handle audio recording functionality
  void _handleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
    
    // TODO: Implement actual recording functionality
    if (_isRecording) {
      // Start recording
      showSnackBar(context, 'Recording started...');
    } else {
      // Stop recording and send
      showSnackBar(context, 'Recording stopped. Sending audio...');
    }
  }
  
  // Send a text message
  void _sendTextMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    
    FocusScope.of(context).unfocus();
    final message = _messageController.text.trim();
    _messageController.clear();
    
    await context.read<ChatProvider>().sendTextMessage(
      sender: currentUser,
      contactUID: widget.contactUID,
      contactName: widget.contactName,
      contactImage: widget.contactImage,
      message: message,
      messageType: MessageEnum.text,
      groupId: widget.groupId,
      onSucess: () {},
      onError: (error) {
        showSnackBar(context, error);
      },
    );
  }
  
  // Pick an image from gallery or camera
  void _selectImage(ImageSource source) async {
    final result = await Permission.storage.request();
    
    if (result.isGranted) {
      try {
        final pickedImage = await ImagePicker().pickImage(source: source);
        
        if (pickedImage != null) {
          final imageFile = File(pickedImage.path);
          
          final currentUser = context.read<AuthenticationProvider>().userModel!;
          
          await context.read<ChatProvider>().sendFileMessage(
            sender: currentUser,
            contactUID: widget.contactUID,
            contactName: widget.contactName,
            contactImage: widget.contactImage,
            file: imageFile,
            messageType: MessageEnum.image,
            groupId: widget.groupId,
            onSucess: () {},
            onError: (error) {
              showSnackBar(context, error);
            },
          );
        }
      } catch (e) {
        showSnackBar(context, e.toString());
      }
    } else {
      showSnackBar(context, 'Permission denied');
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final chatTheme = context.chatTheme;
    final responsiveTheme = context.responsiveTheme;
    final animationTheme = context.animationTheme;
    
    // Get the message reply model
    final messageReply = context.watch<ChatProvider>().messageReplyModel;
    final isReplying = messageReply != null;
    
    // Get loading state
    final isLoading = context.watch<ChatProvider>().isLoading;
    
    return Column(
      children: [
        // Show linear progress indicator when loading
        if (isLoading)
          LinearProgressIndicator(
            color: modernTheme.primaryColor,
            backgroundColor: modernTheme.backgroundColor,
          ),
          
        // Show reply preview if replying
        if (isReplying)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: MessageReplyPreview(
              replyMessageModel: messageReply,
            ),
          ),
        
        // Attachment options container (slides up when toggled)
        SizeTransition(
          sizeFactor: _attachmentAnimation,
          child: Container(
            padding: EdgeInsets.all(responsiveTheme.compactSpacing),
            decoration: BoxDecoration(
              color: chatTheme.inputBackgroundColor,
              borderRadius: BorderRadius.circular(responsiveTheme.compactRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: Colors.purple,
                  onTap: () => _selectImage(ImageSource.gallery),
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: Colors.red,
                  onTap: () => _selectImage(ImageSource.camera),
                ),
                _buildAttachmentOption(
                  icon: Icons.videocam,
                  label: 'Video',
                  color: Colors.blue,
                  onTap: () {
                    // TODO: Implement video recording
                    showSnackBar(context, 'Video recording not implemented yet');
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'Document',
                  color: Colors.orange,
                  onTap: () {
                    // TODO: Implement document picker
                    showSnackBar(context, 'Document picker not implemented yet');
                  },
                ),
              ],
            ),
          ),
        ),
        
        // Main input field container
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: chatTheme.inputBackgroundColor,
            borderRadius: BorderRadius.circular(responsiveTheme.compactRadius * 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Attachment button
              IconButton(
                onPressed: _toggleAttachmentOptions,
                icon: AnimatedRotation(
                  turns: _showAttachments ? 0.125 : 0,
                  duration: animationTheme.shortDuration,
                  child: Icon(
                    Icons.add,
                    color: _showAttachments ? modernTheme.primaryColor : modernTheme.textSecondaryColor,
                    size: 24,
                  ),
                ),
                splashRadius: 20,
              ),
              
              // Text field
              Expanded(
                child: AnimatedContainer(
                  duration: animationTheme.shortDuration,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.black.withOpacity(0.2)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(responsiveTheme.compactRadius * 2.5),
                  ),
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isRecording && !isLoading,
                    decoration: InputDecoration(
                      hintText: _isRecording ? 'Recording...' : 'Message',
                      hintStyle: TextStyle(
                        color: modernTheme.textTertiaryColor,
                        fontSize: 16,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      color: modernTheme.textColor,
                      fontSize: 16,
                    ),
                    maxLines: 5,
                    minLines: 1,
                  ),
                ),
              ),
              
              // Camera shortcut button
              if (!_isShowSendButton && !_isRecording)
                IconButton(
                  onPressed: () => _selectImage(ImageSource.camera),
                  icon: Icon(
                    Icons.camera_alt,
                    color: modernTheme.textSecondaryColor,
                    size: 24,
                  ),
                  splashRadius: 20,
                ),
              
              // Microphone or send button
              AnimatedContainer(
                duration: animationTheme.shortDuration,
                curve: animationTheme.standardCurve,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _isShowSendButton || _isRecording
                      ? modernTheme.primaryColor
                      : chatTheme.inputBackgroundColor,
                  shape: BoxShape.circle,
                  boxShadow: _isShowSendButton || _isRecording 
                      ? [
                          BoxShadow(
                            color: modernTheme.primaryColor!.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: IconButton(
                  onPressed: _isShowSendButton 
                      ? _sendTextMessage 
                      : _handleRecording,
                  icon: AnimatedSwitcher(
                    duration: animationTheme.shortDuration,
                    child: _isShowSendButton
                        ? const Icon(
                            Icons.send,
                            key: ValueKey('send'),
                            color: Colors.white,
                            size: 20,
                          )
                        : Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            key: ValueKey(_isRecording ? 'stop' : 'mic'),
                            color: _isRecording ? Colors.white : modernTheme.textSecondaryColor,
                            size: 24,
                          ),
                  ),
                  splashRadius: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Helper widget for attachment options
  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.modernTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
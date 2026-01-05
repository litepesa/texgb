// lib/features/chat/widgets/message_input.dart - Simplified without video DM context

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/chat/widgets/message_reply_preview.dart';
import 'package:textgb/features/gifts/widgets/virtual_gifts_bottom_sheet.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSendText;
  final Function(File) onSendImage;
  final Function(File, String) onSendFile;
  final Function(VirtualGift)? onSendGift;
  final String? contactId;
  final String? contactName;
  final String? contactImage;
  final MessageModel? replyToMessage;
  final VoidCallback? onCancelReply;

  const MessageInput({
    super.key,
    required this.onSendText,
    required this.onSendImage,
    required this.onSendFile,
    this.onSendGift,
    this.contactId,
    this.contactName,
    this.contactImage,
    this.replyToMessage,
    this.onCancelReply,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSendText() {
    final text = _textController.text.trim();

    if (text.isNotEmpty) {
      widget.onSendText(text);
      _textController.clear();
      setState(() {
        _isComposing = false;
      });
    }
  }

  Future<void> _handleImagePicker() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image != null) {
        widget.onSendImage(File(image.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _handleFilePicker() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final fileName = result.files.first.name;

        final fileSize = await file.length();
        if (fileSize > 50 * 1024 * 1024) {
          _showErrorSnackBar('File size exceeds 50MB limit');
          return;
        }

        widget.onSendFile(file, fileName);
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _getHintText() {
    if (widget.replyToMessage != null) {
      return 'Reply to ${widget.contactName ?? 'contact'}...';
    } else {
      return 'Type a message...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final chatTheme = context.chatTheme;
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply preview above input bar (WhatsApp style)
          if (widget.replyToMessage != null) ...[
            MessageReplyPreview(
              replyToMessage: widget.replyToMessage!,
              contactName: widget.contactName,
              onCancel: widget.onCancelReply,
              viewOnly: false,
            ),
            const SizedBox(height: 4),
          ],

          // Input container
          Container(
            margin: EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: 8 + systemBottomPadding,
            ),
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: modernTheme.dividerColor!.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attachment button
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: modernTheme.primaryColor?.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _showAttachmentOptions,
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.attach_file,
                        color: modernTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Gift button
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF6B35).withOpacity(0.2),
                          const Color(0xFFE91E63).withOpacity(0.2),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _showGiftSelection,
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.card_giftcard,
                        color: Color(0xFFFF6B35),
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Text input
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 36,
                        maxHeight: 120,
                      ),
                      decoration: BoxDecoration(
                        color: chatTheme.inputBackgroundColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: modernTheme.dividerColor!.withOpacity(0.1),
                          width: 0.5,
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.newline,
                        style: TextStyle(
                          color: modernTheme.textColor,
                          fontSize: 15,
                          height: 1.3,
                        ),
                        decoration: InputDecoration(
                          hintText: _getHintText(),
                          hintStyle: TextStyle(
                            color: modernTheme.textSecondaryColor,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        onChanged: (text) {
                          setState(() {
                            _isComposing = text.trim().isNotEmpty;
                          });
                        },
                        onSubmitted: (text) {
                          if (_isComposing) {
                            _handleSendText();
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _isComposing
                          ? modernTheme.primaryColor
                          : modernTheme.primaryColor?.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isComposing ? _handleSendText : null,
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.send,
                        color: _isComposing
                            ? Colors.white
                            : Colors.white.withOpacity(0.7),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    final modernTheme = context.modernTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: modernTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: modernTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AttachmentOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _handleImagePicker();
                    },
                  ),
                  _AttachmentOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _handleCameraPicker();
                    },
                  ),
                  _AttachmentOption(
                    icon: Icons.insert_drive_file,
                    label: 'Document',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _handleFilePicker();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showGiftSelection() {
    // Haptic feedback for button tap
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VirtualGiftsBottomSheet(
        recipientId: widget.contactId,
        recipientName: widget.contactName,
        recipientImage: widget.contactImage,
        onGiftSelected: (gift) {
          // Haptic feedback for gift selection
          HapticFeedback.mediumImpact();

          // Call the onSendGift callback if provided
          widget.onSendGift?.call(gift);
        },
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _handleCameraPicker() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (image != null) {
        widget.onSendImage(File(image.path));
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

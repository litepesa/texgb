// lib/features/chat/widgets/message_input.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/chat/models/message_model.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSendText;
  final Function(File) onSendImage;
  final Function(File, String) onSendFile;
  final MessageModel? replyToMessage;
  final VoidCallback? onCancelReply;
  final String? contactName;

  const MessageInput({
    super.key,
    required this.onSendText,
    required this.onSendImage,
    required this.onSendFile,
    this.replyToMessage,
    this.onCancelReply,
    this.contactName,
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
        imageQuality: 100, // No compression as requested
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
        
        // Check file size (50MB limit)
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

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final chatTheme = context.chatTheme;
    
    return Container(
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        border: Border(
          top: BorderSide(
            color: modernTheme.dividerColor!.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // Reply preview
          if (widget.replyToMessage != null) ...[
            _buildReplyPreview(modernTheme),
          ],
          
          // Input area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Attachment button
                Container(
                  decoration: BoxDecoration(
                    color: modernTheme.primaryColor?.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _showAttachmentOptions,
                    icon: Icon(
                      Icons.attach_file,
                      color: modernTheme.primaryColor,
                      size: 22,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Text input
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: chatTheme.inputBackgroundColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: modernTheme.dividerColor!.withOpacity(0.3),
                      ),
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: 5,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: modernTheme.textSecondaryColor,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (text) {
                        setState(() {
                          _isComposing = text.trim().isNotEmpty;
                        });
                      },
                      onSubmitted: (_) => _handleSendText(),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Send button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _isComposing 
                      ? modernTheme.primaryColor
                      : modernTheme.primaryColor?.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isComposing ? _handleSendText : null,
                    icon: Icon(
                      Icons.send,
                      color: _isComposing 
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: modernTheme.surfaceVariantColor?.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: modernTheme.dividerColor!.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: modernTheme.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${widget.contactName ?? 'contact'}',
                  style: TextStyle(
                    color: modernTheme.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.replyToMessage!.getDisplayContent(),
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onCancelReply,
            icon: Icon(
              Icons.close,
              color: modernTheme.textSecondaryColor,
              size: 20,
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
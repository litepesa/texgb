// lib/features/chat/widgets/chat_input.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttachmentTap;
  final bool isEditing;
  final VoidCallback? onCancelEditing;
  final MessageModel? editingMessage; // Reference to message being edited
  final Function(String)? onTyping; // Callback for typing indicators

  const ChatInput({
    Key? key,
    required this.controller,
    required this.onSend,
    required this.onAttachmentTap,
    this.isEditing = false,
    this.onCancelEditing,
    this.editingMessage,
    this.onTyping,
  }) : super(key: key);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> with SingleTickerProviderStateMixin {
  bool _showSendButton = false;
  bool _hasChanges = false; // Track if edited message has changes
  
  // For typing indicator
  Timer? _typingTimer;
  bool _isTyping = false;
  
  // For animation
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateState);
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    if (widget.isEditing) {
      _animationController.forward();
    }
  }
  
  @override
  void didUpdateWidget(ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Animate when editing mode changes
    if (widget.isEditing != oldWidget.isEditing) {
      if (widget.isEditing) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateState);
    _typingTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _updateState() {
    final shouldShowSend = widget.controller.text.isNotEmpty;
    final hasChanges = widget.isEditing && 
        widget.editingMessage != null && 
        widget.controller.text != widget.editingMessage!.message;
        
    if (shouldShowSend != _showSendButton || hasChanges != _hasChanges) {
      setState(() {
        _showSendButton = shouldShowSend;
        _hasChanges = hasChanges;
      });
    }
    
    // Handle typing indicator
    if (widget.onTyping != null && widget.controller.text.isNotEmpty) {
      _handleTypingIndicator();
    }
  }
  
  void _handleTypingIndicator() {
    if (!_isTyping) {
      _isTyping = true;
      widget.onTyping?.call('typing');
    }
    
    // Reset the timer on each keystroke
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _isTyping = false;
      widget.onTyping?.call('stopped_typing');
    });
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final chatTheme = context.chatTheme;
    final animationTheme = context.animationTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Editing indicator - animated
          SizeTransition(
            sizeFactor: _animation,
            child: widget.isEditing && widget.editingMessage != null
                ? _buildEditingBanner(context)
                : const SizedBox.shrink(),
          ),
          
          // Message input container
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 4,
            ),
            margin: EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: 8 + bottomPadding / 2,
              top: 4,
            ),
            decoration: BoxDecoration(
              color: widget.isEditing 
                  ? modernTheme.primaryColor?.withOpacity(0.1) 
                  : chatTheme.inputBackgroundColor,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: widget.isEditing
                  ? Border.all(color: modernTheme.primaryColor?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3), width: 1.5)
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attachment button (hide when editing)
                if (!widget.isEditing)
                  _buildAttachmentButton(context),
                
                // Cancel edit button (show only when editing)
                if (widget.isEditing)
                  _buildCancelEditButton(context),
                
                // Message input field
                Expanded(
                  child: _buildTextField(context),
                ),
                
                // Send or voice button
                Padding(
                  padding: const EdgeInsets.only(bottom: 2, right: 2),
                  child: _buildSendButton(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEditingBanner(BuildContext context) {
    final modernTheme = context.modernTheme;
    final primaryColor = modernTheme.primaryColor ?? Colors.blue;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Editing message',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  widget.editingMessage?.message ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (_hasChanges)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Modified',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: modernTheme.textSecondaryColor,
              size: 20,
            ),
            onPressed: widget.onCancelEditing,
            tooltip: 'Cancel editing',
          ),
        ],
      ),
    );
  }
  
  Widget _buildAttachmentButton(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Material(
      color: Colors.transparent,
      child: IconButton(
        icon: Icon(
          Icons.attach_file_rounded,
          color: modernTheme.primaryColor?.withOpacity(0.7),
          size: 24,
        ),
        onPressed: widget.onAttachmentTap,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
        splashRadius: 24,
        tooltip: 'Attach files',
      ),
    );
  }
  
  Widget _buildCancelEditButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: IconButton(
        icon: Icon(
          Icons.close,
          color: Colors.red.withOpacity(0.7),
          size: 24,
        ),
        onPressed: widget.onCancelEditing,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
        splashRadius: 24,
        tooltip: 'Cancel editing',
      ),
    );
  }
  
  Widget _buildTextField(BuildContext context) {
    final modernTheme = context.modernTheme;
    final primaryColor = modernTheme.primaryColor ?? Colors.blue;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: TextField(
        controller: widget.controller,
        style: TextStyle(
          color: modernTheme.textColor,
          fontSize: 16,
        ),
        maxLines: 5,
        minLines: 1,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: widget.isEditing 
              ? 'Edit message' 
              : 'Message',
          hintStyle: TextStyle(
            color: modernTheme.textSecondaryColor?.withOpacity(0.7),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          isDense: true,
          alignLabelWithHint: true,
        ),
        textAlignVertical: TextAlignVertical.center,
        cursorColor: widget.isEditing ? primaryColor : modernTheme.primaryColor,
        cursorWidth: 1.5,
        cursorHeight: 20,
        onSubmitted: (_) {
          if (_showSendButton) {
            widget.onSend();
          }
        },
      ),
    );
  }
  
  Widget _buildSendButton(BuildContext context) {
    final modernTheme = context.modernTheme;
    final animationTheme = context.animationTheme;
    final primaryColor = modernTheme.primaryColor ?? Colors.blue;
    
    return AnimatedContainer(
      duration: animationTheme.shortDuration,
      curve: animationTheme.standardCurve,
      width: _showSendButton ? 70 : 40,
      height: 40,
      child: AnimatedSwitcher(
        duration: animationTheme.shortDuration,
        switchInCurve: animationTheme.standardCurve,
        switchOutCurve: animationTheme.standardCurve,
        child: _showSendButton
            ? ElevatedButton(
                key: const ValueKey('send_button'),
                onPressed: widget.onSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isEditing 
                      ? primaryColor 
                      : modernTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: const Size(70, 40),
                ),
                child: Text(
                  widget.isEditing 
                      ? (_hasChanges ? 'Save' : 'Update') 
                      : 'Send',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : Container(
                key: const ValueKey('mic_button'),
                decoration: BoxDecoration(
                  color: modernTheme.surfaceVariantColor?.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Tooltip(
                  message: 'Voice message',
                  child: IconButton(
                    icon: Icon(
                      Icons.mic_rounded,
                      color: modernTheme.primaryColor,
                      size: 22,
                    ),
                    onPressed: () {
                      // TODO: Implement voice recording
                    },
                    padding: EdgeInsets.zero,
                    splashRadius: 24,
                  ),
                ),
              ),
      ),
    );
  }
}
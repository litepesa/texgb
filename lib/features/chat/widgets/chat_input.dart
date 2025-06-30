// lib/features/chat/widgets/chat_input.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttachmentTap;
  final bool isEditing;
  final VoidCallback? onCancelEditing;
  final MessageModel? editingMessage;
  final MessageModel? replyingTo;
  final VoidCallback? onCancelReply;
  final Function(String)? onTyping;
  final bool isRecording;
  final VoidCallback? onStartRecording;
  final VoidCallback? onStopRecording;

  const ChatInput({
    Key? key,
    required this.controller,
    required this.onSend,
    required this.onAttachmentTap,
    this.isEditing = false,
    this.onCancelEditing,
    this.editingMessage,
    this.replyingTo,
    this.onCancelReply,
    this.onTyping,
    this.isRecording = false,
    this.onStartRecording,
    this.onStopRecording,
  }) : super(key: key);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late AnimationController _sendButtonController;
  late AnimationController _attachmentController;
  late AnimationController _replyController;
  late AnimationController _editController;
  late AnimationController _recordingController;

  late Animation<double> _expandAnimation;
  late Animation<double> _sendButtonScaleAnimation;
  late Animation<double> _sendButtonRotationAnimation;
  late Animation<double> _attachmentScaleAnimation;
  late Animation<double> _replySlideAnimation;
  late Animation<double> _editSlideAnimation;
  late Animation<double> _recordingPulseAnimation;

  bool _showSendButton = false;
  bool _hasChanges = false;
  Timer? _typingTimer;
  bool _isTyping = false;
  double _inputHeight = 56.0;
  final double _maxInputHeight = 120.0;
  final double _minInputHeight = 56.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    widget.controller.addListener(_updateState);
    
    // Initialize edit state
    if (widget.isEditing && widget.editingMessage != null) {
      widget.controller.text = widget.editingMessage!.message;
      _editController.forward();
    }
    
    // Initialize reply state
    if (widget.replyingTo != null) {
      _replyController.forward();
    }
  }

  void _initializeAnimations() {
    // Input expansion animation
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    // Send button animations
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _sendButtonScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sendButtonController,
      curve: Curves.elasticOut,
    ));

    _sendButtonRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sendButtonController,
      curve: Curves.easeInOut,
    ));

    // Attachment button animation
    _attachmentController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _attachmentScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _attachmentController,
      curve: Curves.easeInOut,
    ));

    // Reply banner animation
    _replyController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _replySlideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _replyController,
      curve: Curves.elasticOut,
    ));

    // Edit banner animation
    _editController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _editSlideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _editController,
      curve: Curves.elasticOut,
    ));

    // Recording animation
    _recordingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _recordingPulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _recordingController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle editing state changes
    if (widget.isEditing != oldWidget.isEditing) {
      if (widget.isEditing) {
        _editController.forward();
        if (widget.editingMessage != null) {
          widget.controller.text = widget.editingMessage!.message;
        }
      } else {
        _editController.reverse();
      }
    }
    
    // Handle reply state changes
    if (widget.replyingTo != oldWidget.replyingTo) {
      if (widget.replyingTo != null) {
        _replyController.forward();
      } else {
        _replyController.reverse();
      }
    }
    
    // Handle recording state changes
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _recordingController.repeat(reverse: true);
      } else {
        _recordingController.stop();
        _recordingController.reset();
      }
    }
  }

  void _updateState() {
    final shouldShowSend = widget.controller.text.trim().isNotEmpty;
    final hasChanges = widget.isEditing && 
        widget.editingMessage != null && 
        widget.controller.text != widget.editingMessage!.message;

    if (shouldShowSend != _showSendButton) {
      setState(() => _showSendButton = shouldShowSend);
      
      if (shouldShowSend) {
        _sendButtonController.forward();
        _attachmentController.forward();
      } else {
        _sendButtonController.reverse();
        _attachmentController.reverse();
      }
    }

    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }

    // Handle typing indicator
    if (widget.onTyping != null && widget.controller.text.isNotEmpty) {
      _handleTypingIndicator();
    }

    // Auto-resize input field
    _updateInputHeight();
  }

  void _updateInputHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          // Calculate text height (simplified)
          final textLines = widget.controller.text.split('\n').length;
          final newHeight = (textLines * 20.0 + 36.0).clamp(_minInputHeight, _maxInputHeight);
          
          if (newHeight != _inputHeight) {
            setState(() => _inputHeight = newHeight);
          }
        }
      }
    });
  }

  void _handleTypingIndicator() {
    if (!_isTyping) {
      _isTyping = true;
      widget.onTyping?.call('typing');
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isTyping = false;
      widget.onTyping?.call('stopped_typing');
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateState);
    _typingTimer?.cancel();
    _expandController.dispose();
    _sendButtonController.dispose();
    _attachmentController.dispose();
    _replyController.dispose();
    _editController.dispose();
    _recordingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _expandController,
        _replyController,
        _editController,
      ]),
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit banner
            if (widget.isEditing && widget.editingMessage != null)
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(_editSlideAnimation),
                child: _buildEditBanner(modernTheme),
              ),

            // Reply banner
            if (widget.replyingTo != null && !widget.isEditing)
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(_replySlideAnimation),
                child: _buildReplyBanner(modernTheme),
              ),

            // Main input container
            Container(
              margin: EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: 8 + bottomPadding / 2,
                top: 8,
              ),
              child: _buildInputContainer(modernTheme),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditBanner(ModernThemeExtension modernTheme) {
    final primaryColor = modernTheme.primaryColor ?? Colors.blue;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit,
                      size: 16,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Editing message',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    if (_hasChanges) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
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
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.editingMessage?.message ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 14,
                  ),
                ),
              ],
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

  Widget _buildReplyBanner(ModernThemeExtension modernTheme) {
    final primaryColor = modernTheme.primaryColor ?? Colors.blue;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: modernTheme.dividerColor?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.reply,
                      size: 16,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Replying to message',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.replyingTo?.messageType == MessageEnum.text
                      ? widget.replyingTo!.message
                      : '${widget.replyingTo!.messageType.name}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: modernTheme.textSecondaryColor,
              size: 20,
            ),
            onPressed: widget.onCancelReply,
            tooltip: 'Cancel reply',
          ),
        ],
      ),
    );
  }

  Widget _buildInputContainer(ModernThemeExtension modernTheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: _inputHeight,
      decoration: BoxDecoration(
        color: widget.isEditing 
            ? modernTheme.primaryColor?.withOpacity(0.05)
            : modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(28),
        border: widget.isEditing
            ? Border.all(
                color: modernTheme.primaryColor?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment button
          if (!widget.isEditing)
            AnimatedBuilder(
              animation: _attachmentScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _attachmentScaleAnimation.value,
                  child: _buildAttachmentButton(modernTheme),
                );
              },
            ),

          // Cancel edit button (show only when editing)
          if (widget.isEditing)
            _buildCancelEditButton(modernTheme),

          // Text input field
          Expanded(
            child: _buildTextField(modernTheme),
          ),

          // Send/Voice button
          _buildActionButton(modernTheme),
        ],
      ),
    );
  }

  Widget _buildAttachmentButton(ModernThemeExtension modernTheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: widget.onAttachmentTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(
            Icons.attach_file_rounded,
            color: modernTheme.primaryColor?.withOpacity(0.7),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildCancelEditButton(ModernThemeExtension modernTheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: widget.onCancelEditing,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(
            Icons.close,
            color: Colors.red.withOpacity(0.7),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(ModernThemeExtension modernTheme) {
    final primaryColor = modernTheme.primaryColor ?? Colors.blue;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: TextField(
        controller: widget.controller,
        style: TextStyle(
          color: modernTheme.textColor,
          fontSize: 16,
          height: 1.3,
        ),
        maxLines: null,
        minLines: 1,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: widget.isEditing 
              ? 'Edit message...' 
              : widget.replyingTo != null
                  ? 'Reply...'
                  : 'Message',
          hintStyle: TextStyle(
            color: modernTheme.textSecondaryColor?.withOpacity(0.7),
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          isDense: true,
        ),
        textAlignVertical: TextAlignVertical.center,
        cursorColor: widget.isEditing ? primaryColor : modernTheme.primaryColor,
        cursorWidth: 2,
        cursorHeight: 20,
        cursorRadius: const Radius.circular(1),
        onSubmitted: (_) {
          if (_showSendButton) {
            widget.onSend();
          }
        },
      ),
    );
  }

  Widget _buildActionButton(ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.all(4),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _sendButtonController,
          _recordingController,
        ]),
        builder: (context, child) {
          if (_showSendButton) {
            return _buildSendButton(modernTheme);
          } else if (widget.isRecording) {
            return _buildRecordingButton(modernTheme);
          } else {
            return _buildVoiceButton(modernTheme);
          }
        },
      ),
    );
  }

  Widget _buildSendButton(ModernThemeExtension modernTheme) {
    final primaryColor = modernTheme.primaryColor ?? Colors.blue;
    
    return Transform.scale(
      scale: _sendButtonScaleAnimation.value,
      child: Transform.rotate(
        angle: _sendButtonRotationAnimation.value * 0.1,
        child: Material(
          color: widget.isEditing 
              ? primaryColor 
              : primaryColor,
          borderRadius: BorderRadius.circular(24),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onSend();
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor,
                    primaryColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: Icon(
                widget.isEditing
                    ? (_hasChanges ? Icons.check : Icons.edit)
                    : Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceButton(ModernThemeExtension modernTheme) {
    return Material(
      color: modernTheme.surfaceVariantColor?.withOpacity(0.5),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onStartRecording?.call();
        },
        child: Container(
          width: 48,
          height: 48,
          child: Icon(
            Icons.mic_rounded,
            color: modernTheme.primaryColor,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingButton(ModernThemeExtension modernTheme) {
    return AnimatedBuilder(
      animation: _recordingPulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _recordingPulseAnimation.value,
          child: Material(
            color: Colors.red,
            borderRadius: BorderRadius.circular(24),
            elevation: 4,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onStopRecording?.call();
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.red,
                      Colors.redAccent,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.stop_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
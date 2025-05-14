import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/status/status_model.dart';
import 'package:textgb/features/status/status_reply_handler.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class StatusResponseWidget extends ConsumerStatefulWidget {
  final StatusItemModel statusItem;
  final StatusModel status;
  final Function onSuccess;

  const StatusResponseWidget({
    Key? key,
    required this.statusItem,
    required this.status,
    required this.onSuccess,
  }) : super(key: key);

  @override
  ConsumerState<StatusResponseWidget> createState() => _StatusResponseWidgetState();
}

class _StatusResponseWidgetState extends ConsumerState<StatusResponseWidget> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;
  final List<String> _quickResponses = [
    '😍 Amazing!',
    '👍 Nice',
    '❤️ Love it',
    '😮 Wow',
    '🔥 Fire'
  ];

  @override
  void initState() {
    super.initState();
    // Automatically focus the input field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendReply(String message) async {
    if (message.trim().isEmpty) return;
    
    // Provide haptic feedback
    HapticFeedback.lightImpact();
    
    setState(() {
      _isSending = true;
    });
    
    await StatusReplyHandler.replyToStatus(
      context: context,
      ref: ref,
      status: widget.status,
      statusItem: widget.statusItem,
      message: message,
      onSuccess: () {
        setState(() {
          _isSending = false;
        });
        widget.onSuccess();
        Navigator.pop(context);
        
        // Show confirmation
        showSnackBar(context, 'Reply sent to ${widget.status.userName}');
        
        // Optionally navigate to chat
        Future.delayed(const Duration(milliseconds: 500), () {
          StatusReplyHandler.navigateToChatWithStatusOwner(
            context: context,
            status: widget.status,
          );
        });
      },
      onError: (error) {
        setState(() {
          _isSending = false;
        });
        showSnackBar(context, error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.read(currentUserProvider);
    final modernTheme = context.modernTheme;
    final primaryColor = modernTheme.primaryColor!;
    final surfaceColor = modernTheme.surfaceColor!;
    final textColor = modernTheme.textColor!;

    // Safety check for current user
    if (currentUser == null) {
      return Center(
        child: Text('Not logged in', style: TextStyle(color: textColor)),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 8, 
        left: 8, 
        right: 8, 
        top: 8
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Status preview
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: modernTheme.surfaceVariantColor!.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                // Status thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: _buildStatusThumbnail(),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Status info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Replying to ${widget.status.userName}\'s status',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textColor.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (widget.statusItem.caption != null && 
                          widget.statusItem.caption!.isNotEmpty)
                        Text(
                          widget.statusItem.caption!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor.withOpacity(0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Quick responses
          Container(
            height: 44,
            margin: const EdgeInsets.only(top: 4, bottom: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _quickResponses.length,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemBuilder: (context, index) {
                final response = _quickResponses[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: _isSending ? null : () => _sendReply(response),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: modernTheme.surfaceVariantColor!,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        response,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Message input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  enabled: !_isSending,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (_messageController.text.trim().isNotEmpty && !_isSending) {
                      _sendReply(_messageController.text.trim());
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Reply to status...',
                    filled: true,
                    fillColor: modernTheme.surfaceVariantColor!,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: _isSending ? Colors.grey : primaryColor,
                radius: 24,
                child: _isSending 
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          if (_messageController.text.trim().isNotEmpty && !_isSending) {
                            _sendReply(_messageController.text.trim());
                          }
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusThumbnail() {
    switch (widget.statusItem.type) {
      case StatusType.image:
        return CachedNetworkImage(
          imageUrl: widget.statusItem.mediaUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: const Icon(Icons.image, color: Colors.white),
          ),
        );
      case StatusType.video:
        return Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: widget.statusItem.mediaUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.black,
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.black,
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        );
      case StatusType.text:
        return Container(
          color: Colors.purple,
          child: const Center(
            child: Icon(Icons.text_fields, color: Colors.white),
          ),
        );
      default:
        return Container(
          color: Colors.grey[300],
        );
    }
  }
}
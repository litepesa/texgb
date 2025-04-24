import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/status/status_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class StatusResponseWidget extends StatefulWidget {
  final StatusItemModel statusItem;
  final StatusModel status;
  final Function(String) onSend;

  const StatusResponseWidget({
    Key? key,
    required this.statusItem,
    required this.status,
    required this.onSend,
  }) : super(key: key);

  @override
  State<StatusResponseWidget> createState() => _StatusResponseWidgetState();
}

class _StatusResponseWidgetState extends State<StatusResponseWidget> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _quickResponses = [
    '😍 Amazing!',
    '👍 Nice',
    '❤️ Love it',
    '😮 Wow',
    '🔥 Fire'
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    final modernTheme = context.modernTheme;
    final primaryColor = modernTheme.primaryColor!;
    final surfaceColor = modernTheme.surfaceColor!;
    final textColor = modernTheme.textColor!;

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
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: modernTheme.surfaceVariantColor!.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                // Status thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 40,
                    height: 40,
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
                          fontSize: 12,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                      if (widget.statusItem.caption != null && 
                          widget.statusItem.caption!.isNotEmpty)
                        Text(
                          widget.statusItem.caption!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Quick responses
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: _quickResponses.map((response) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      widget.onSend(response);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: modernTheme.surfaceVariantColor!,
                        borderRadius: BorderRadius.circular(20),
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
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Message input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (_messageController.text.trim().isNotEmpty) {
                      widget.onSend(_messageController.text.trim());
                      Navigator.pop(context);
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
                backgroundColor: primaryColor,
                radius: 24,
                child: IconButton(
                  icon: const Icon(
                    Icons.send,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (_messageController.text.trim().isNotEmpty) {
                      widget.onSend(_messageController.text.trim());
                      Navigator.pop(context);
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
        return Container(
          color: Colors.black,
          child: const Center(
            child: Icon(Icons.play_arrow, color: Colors.white),
          ),
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
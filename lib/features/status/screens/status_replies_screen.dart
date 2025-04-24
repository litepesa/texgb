import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:textgb/features/status/status_reply_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class StatusRepliesScreen extends StatefulWidget {
  const StatusRepliesScreen({Key? key}) : super(key: key);

  @override
  State<StatusRepliesScreen> createState() => _StatusRepliesScreenState();
}

class _StatusRepliesScreenState extends State<StatusRepliesScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReplies();
  }

  Future<void> _loadReplies() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final currentUser = context.read<AuthenticationProvider>().userModel;
    if (currentUser != null) {
      await context.read<StatusProvider>().fetchStatusReplies(currentUser.uid);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final primaryColor = modernTheme.primaryColor!;
    final textColor = modernTheme.textColor!;
    final textSecondaryColor = modernTheme.textSecondaryColor!;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Replies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadReplies,
          ),
        ],
      ),
      body: Consumer<StatusProvider>(
        builder: (context, statusProvider, _) {
          final replies = statusProvider.statusReplies;
          
          if (_isLoading) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }
          
          if (replies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: primaryColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No replies to your status yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When someone replies to your status,\nit will appear here',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondaryColor,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: _loadReplies,
            color: primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: replies.length,
              itemBuilder: (context, index) {
                final reply = replies[index];
                return _buildReplyItem(reply, statusProvider);
              },
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildReplyItem(StatusReplyModel reply, StatusProvider statusProvider) {
    final modernTheme = context.modernTheme;
    final surfaceVariantColor = modernTheme.surfaceVariantColor!;
    final textColor = modernTheme.textColor!;
    final textSecondaryColor = modernTheme.textSecondaryColor!;
    
    // Mark as read when viewed
    if (!reply.isRead) {
      statusProvider.markStatusReplyAsRead(reply.replyId);
    }
    
    return Dismissible(
      key: Key(reply.replyId),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        statusProvider.deleteStatusReply(reply.replyId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply deleted'),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sender info
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: CachedNetworkImageProvider(reply.senderImage),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reply.senderName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          _getTimeAgo(reply.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Message
              Text(
                reply.message,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Status reference
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surfaceVariantColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Status thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: _buildStatusThumbnail(reply.statusThumbnailUrl),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Status caption
                    Expanded(
                      child: Text(
                        reply.statusCaption.isNotEmpty 
                            ? reply.statusCaption 
                            : 'Your status',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondaryColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusThumbnail(String url) {
    if (url.isEmpty) {
      return Container(
        color: Colors.grey,
        child: const Icon(Icons.image_not_supported, color: Colors.white),
      );
    }
    
    // Simple check to determine if it's a video (not foolproof)
    final bool isVideo = url.contains('.mp4') || 
                          url.contains('video') ||
                          url.contains('mp4');
    
    if (isVideo) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.play_arrow, color: Colors.white),
        ),
      );
    }
    
    // Assume it's an image
    return CachedNetworkImage(
      imageUrl: url,
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
  }
  
  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return 'Yesterday';
    }
  }
}
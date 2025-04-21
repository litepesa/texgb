import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/features/status/widgets/comment_item.dart';
import 'package:textgb/models/moment_model.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/providers/moments_provider.dart';
import 'package:textgb/utilities/global_methods.dart';

class TikTokCommentsScreen extends StatefulWidget {
  final MomentModel moment;
  final bool isBottomSheet;
  
  const TikTokCommentsScreen({
    Key? key,
    required this.moment,
    this.isBottomSheet = true,
  }) : super(key: key);

  @override
  State<TikTokCommentsScreen> createState() => _TikTokCommentsScreenState();
}

class _TikTokCommentsScreenState extends State<TikTokCommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  bool _isCommenting = false;
  
  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }
  
  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) {
      return;
    }
    
    setState(() {
      _isCommenting = true;
    });
    
    final momentsProvider = context.read<MomentsProvider>();
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    
    await momentsProvider.addComment(
      momentId: widget.moment.momentId,
      currentUser: currentUser,
      commentText: _commentController.text.trim(),
      onSuccess: () {
        _commentController.clear();
        setState(() {
          _isCommenting = false;
        });
        FocusScope.of(context).unfocus();
      },
      onError: (error) {
        setState(() {
          _isCommenting = false;
        });
        showSnackBar(context, 'Error posting comment: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final backgroundColor = themeExtension?.backgroundColor ?? Colors.white;
    final accentColor = themeExtension?.accentColor ?? Colors.green;
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    
    // Get updated moment from provider
    final updatedMoment = context.select<MomentsProvider, MomentModel>(
      (provider) {
        final userMoment = provider.userMoments
            .where((m) => m.momentId == widget.moment.momentId)
            .firstOrNull;
        
        final contactMoment = provider.contactsMoments
            .where((m) => m.momentId == widget.moment.momentId)
            .firstOrNull;
        
        final forYouMoment = provider.forYouMoments
            .where((m) => m.momentId == widget.moment.momentId)
            .firstOrNull;
        
        return userMoment ?? contactMoment ?? forYouMoment ?? widget.moment;
      },
    );
    
    // If this is a bottom sheet, we don't need the scaffold and appbar
    if (widget.isBottomSheet) {
      return _buildCommentsContent(updatedMoment, backgroundColor, accentColor, currentUser);
    }
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('${updatedMoment.comments.length} comments'),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: _buildCommentsContent(updatedMoment, backgroundColor, accentColor, currentUser),
    );
  }
  
  Widget _buildCommentsContent(
    MomentModel moment,
    Color backgroundColor,
    Color accentColor,
    UserModel currentUser,
  ) {
    return Column(
      children: [
        // Comments list
        Expanded(
          child: moment.comments.isEmpty
              ? _buildEmptyCommentsView()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: moment.comments.length,
                  itemBuilder: (context, index) {
                    final comment = moment.comments[index];
                    return CommentItem(
                      comment: comment,
                      isMyComment: comment.uid == currentUser.uid,
                    );
                  },
                ),
        ),
        
        // Comment input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, -1),
                blurRadius: 3,
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                // User avatar
                userImageWidget(
                  imageUrl: currentUser.image,
                  radius: 16,
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                
                // Comment text field
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocus,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.1),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _addComment(),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Post button
                SizedBox(
                  height: 40,
                  width: 40,
                  child: _isCommenting
                      ? CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentColor,
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.send,
                            color: accentColor,
                          ),
                          onPressed: _addComment,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyCommentsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No comments yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Be the first to comment on this post',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
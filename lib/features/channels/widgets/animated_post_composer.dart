// lib/features/channels/widgets/animated_post_composer.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class AnimatedPostComposer extends StatefulWidget {
  final TextEditingController captionController;
  final bool isExpanded;
  final VoidCallback onExpandToggle;
  final VoidCallback onPost;
  final int mediaCount;

  const AnimatedPostComposer({
    Key? key,
    required this.captionController,
    required this.isExpanded,
    required this.onExpandToggle,
    required this.onPost,
    required this.mediaCount,
  }) : super(key: key);

  @override
  State<AnimatedPostComposer> createState() => _AnimatedPostComposerState();
}

class _AnimatedPostComposerState extends State<AnimatedPostComposer>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _shineController;
  late AnimationController _expandController;
  late AnimationController _textFieldController;
  late AnimationController _suggestionController;
  
  late Animation<double> _bounceAnimation;
  late Animation<double> _shineAnimation;
  late Animation<double> _expandAnimation;
  late Animation<double> _textFieldFocusAnimation;
  late Animation<double> _suggestionSlideAnimation;
  late Animation<Offset> _slideUpAnimation;
  
  final FocusNode _captionFocusNode = FocusNode();
  final ScrollController _textScrollController = ScrollController();
  
  final List<String> _trendingTags = [
    'trending', 'viral', 'fyp', 'music', 'dance', 
    'comedy', 'lifestyle', 'fashion', 'food', 'travel',
    'art', 'nature', 'fitness', 'motivation', 'love'
  ];
  
  bool _showHashtagSuggestions = false;
  String _lastWord = '';
  bool _isTextFieldFocused = false;
  int _characterCount = 0;
  List<String> _detectedMentions = [];
  List<String> _detectedHashtags = [];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupListeners();
  }
  
  void _initializeAnimations() {
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _shineController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _textFieldController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _suggestionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticInOut,
    ));
    
    _shineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shineController,
      curve: Curves.easeInOut,
    ));
    
    _expandAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
    ));
    
    _textFieldFocusAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _textFieldController,
      curve: Curves.easeOut,
    ));
    
    _suggestionSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _suggestionController,
      curve: Curves.easeOutBack,
    ));
    
    _slideUpAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
    ));
    
    _bounceController.repeat(reverse: true);
    _shineController.repeat();
  }
  
  void _setupListeners() {
    widget.captionController.addListener(_onCaptionChanged);
    
    _captionFocusNode.addListener(() {
      setState(() {
        _isTextFieldFocused = _captionFocusNode.hasFocus;
      });
      
      if (_isTextFieldFocused) {
        _textFieldController.forward();
        if (!widget.isExpanded) {
          widget.onExpandToggle();
        }
      } else {
        _textFieldController.reverse();
        _hideSuggestions();
      }
    });
  }
  
  void _onCaptionChanged() {
    final text = widget.captionController.text;
    final words = text.split(' ');
    final lastWord = words.isNotEmpty ? words.last : '';
    
    setState(() {
      _lastWord = lastWord;
      _characterCount = text.length;
      
      // Show hashtag suggestions
      _showHashtagSuggestions = lastWord.startsWith('#') && lastWord.length > 1;
      
      // Extract mentions and hashtags
      _detectedMentions = RegExp(r'@(\w+)').allMatches(text)
          .map((match) => match.group(1)!).toList();
      _detectedHashtags = RegExp(r'#(\w+)').allMatches(text)
          .map((match) => match.group(1)!).toList();
    });
    
    if (_showHashtagSuggestions) {
      _suggestionController.forward();
    } else {
      _suggestionController.reverse();
    }
  }
  
  void _hideSuggestions() {
    setState(() {
      _showHashtagSuggestions = false;
    });
    _suggestionController.reverse();
  }
  
  @override
  void didUpdateWidget(AnimatedPostComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
        _captionFocusNode.unfocus();
      }
    }
  }
  
  @override
  void dispose() {
    widget.captionController.removeListener(_onCaptionChanged);
    _captionFocusNode.dispose();
    _textScrollController.dispose();
    _bounceController.dispose();
    _shineController.dispose();
    _expandController.dispose();
    _textFieldController.dispose();
    _suggestionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: modernTheme.backgroundColor,
        borderRadius: BorderRadius.circular(widget.isExpanded ? 24 : 40),
        boxShadow: [
          BoxShadow(
            color: modernTheme.primaryColor!.withOpacity(0.15),
            blurRadius: widget.isExpanded ? 30 : 20,
            spreadRadius: widget.isExpanded ? 8 : 5,
            offset: Offset(0, widget.isExpanded ? -8 : -5),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: widget.isExpanded
            ? _buildExpandedView(modernTheme, keyboardHeight)
            : _buildCollapsedView(modernTheme),
      ),
    );
  }

  Widget _buildCollapsedView(ModernThemeExtension modernTheme) {
    return InkWell(
      onTap: () {
        widget.onExpandToggle();
        HapticFeedback.lightImpact();
      },
      borderRadius: BorderRadius.circular(40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            // Enhanced media count badge
            _buildMediaBadge(modernTheme),
            
            const SizedBox(width: 16),
            
            // Caption preview with better styling
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.captionController.text.isEmpty
                        ? 'Add a caption...'
                        : widget.captionController.text,
                    style: TextStyle(
                      color: widget.captionController.text.isEmpty
                          ? modernTheme.textSecondaryColor
                          : modernTheme.textColor,
                      fontSize: 16,
                      fontWeight: widget.captionController.text.isEmpty 
                          ? FontWeight.normal 
                          : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.captionController.text.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Tap to edit',
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                        if (_characterCount > 0) ...[
                          Text(
                            ' • $_characterCount chars',
                            style: TextStyle(
                              color: modernTheme.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Enhanced post button
            AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _bounceAnimation.value,
                  child: _buildPostButton(modernTheme, isCollapsed: true),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedView(ModernThemeExtension modernTheme, double keyboardHeight) {
    return SlideTransition(
      position: _slideUpAnimation,
      child: Column(
        children: [
          // Enhanced header
          _buildEnhancedHeader(modernTheme),
          
          // Main content area with proper keyboard handling
          Expanded(
            child: Container(
              padding: EdgeInsets.only(bottom: keyboardHeight > 0 ? 8 : 0),
              child: Column(
                children: [
                  // Caption input area
                  Expanded(
                    child: _buildCaptionInputArea(modernTheme),
                  ),
                  
                  // Hashtag suggestions
                  if (_showHashtagSuggestions)
                    _buildHashtagSuggestions(modernTheme),
                  
                  // Enhanced bottom toolbar
                  _buildEnhancedBottomToolbar(modernTheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaBadge(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            modernTheme.primaryColor!,
            modernTheme.primaryColor!.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: modernTheme.primaryColor!.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            widget.mediaCount == 1 
                ? Icons.video_library
                : Icons.collections,
            color: Colors.white,
            size: 20,
          ),
          if (widget.mediaCount > 1)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  '${widget.mediaCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeader(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: modernTheme.dividerColor?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Collapse button
          IconButton(
            onPressed: () {
              widget.onExpandToggle();
              HapticFeedback.lightImpact();
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: modernTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: modernTheme.textColor,
                size: 20,
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Enhanced title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Post',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_detectedHashtags.isNotEmpty || _detectedMentions.isNotEmpty)
                  Text(
                    '${_detectedHashtags.length} tags • ${_detectedMentions.length} mentions',
                    style: TextStyle(
                      color: modernTheme.primaryColor,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          
          // Enhanced character count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getCharacterCountColor(modernTheme).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getCharacterCountColor(modernTheme).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              '$_characterCount/2200',
              style: TextStyle(
                color: _getCharacterCountColor(modernTheme),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptionInputArea(ModernThemeExtension modernTheme) {
    return AnimatedBuilder(
      animation: _textFieldFocusAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _textFieldFocusAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: _isTextFieldFocused ? LinearGradient(
                colors: [
                  modernTheme.primaryColor!.withOpacity(0.1),
                  modernTheme.primaryColor!.withOpacity(0.05),
                ],
              ) : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isTextFieldFocused 
                    ? modernTheme.primaryColor!.withOpacity(0.5)
                    : modernTheme.dividerColor?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2),
                width: _isTextFieldFocused ? 2 : 1,
              ),
            ),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 120,
                maxHeight: 300,
              ),
              child: Scrollbar(
                controller: _textScrollController,
                child: TextField(
                  controller: widget.captionController,
                  focusNode: _captionFocusNode,
                  scrollController: _textScrollController,
                  maxLines: null,
                  maxLength: 2200,
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'What\'s on your mind? Share your story...',
                    hintStyle: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    counterText: '',
                  ),
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  autofocus: false,
                  onChanged: (text) {
                    // Ensure text field scrolls to keep cursor visible
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_textScrollController.hasClients) {
                        _textScrollController.animateTo(
                          _textScrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHashtagSuggestions(ModernThemeExtension modernTheme) {
    final searchTerm = _lastWord.substring(1).toLowerCase();
    final suggestions = _trendingTags
        .where((tag) => tag.toLowerCase().contains(searchTerm))
        .take(8)
        .toList();
    
    if (suggestions.isEmpty) return const SizedBox.shrink();
    
    return AnimatedBuilder(
      animation: _suggestionSlideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _suggestionSlideAnimation.value)),
          child: Opacity(
            opacity: _suggestionSlideAnimation.value,
            child: Container(
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: modernTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: modernTheme.primaryColor!.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final tag = suggestions[index];
                  return _buildHashtagSuggestionChip(tag, modernTheme);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHashtagSuggestionChip(String tag, ModernThemeExtension modernTheme) {
    return GestureDetector(
      onTap: () => _insertHashtag(tag),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              modernTheme.primaryColor!.withOpacity(0.1),
              modernTheme.primaryColor!.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: modernTheme.primaryColor!.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tag,
              color: modernTheme.primaryColor,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              tag,
              style: TextStyle(
                color: modernTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedBottomToolbar(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: modernTheme.dividerColor?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Toolbar buttons
          _buildToolbarButton(
            icon: Icons.emoji_emotions_outlined,
            label: 'Emoji',
            onTap: () {
              // Show emoji picker
              HapticFeedback.lightImpact();
            },
            modernTheme: modernTheme,
          ),
          
          const SizedBox(width: 12),
          
          _buildToolbarButton(
            icon: Icons.alternate_email,
            label: 'Mention',
            onTap: () {
              _insertText('@');
              HapticFeedback.lightImpact();
            },
            modernTheme: modernTheme,
          ),
          
          const SizedBox(width: 12),
          
          _buildToolbarButton(
            icon: Icons.tag,
            label: 'Hashtag',
            onTap: () {
              _insertText('#');
              HapticFeedback.lightImpact();
            },
            modernTheme: modernTheme,
          ),
          
          const Spacer(),
          
          // Enhanced post button
          AnimatedBuilder(
            animation: _shineAnimation,
            builder: (context, child) {
              return _buildPostButton(modernTheme);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ModernThemeExtension modernTheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: modernTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: modernTheme.dividerColor?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: modernTheme.textSecondaryColor,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostButton(ModernThemeExtension modernTheme, {bool isCollapsed = false}) {
    final isEnabled = widget.captionController.text.trim().isNotEmpty;
    
    return GestureDetector(
      onTap: isEnabled ? () {
        widget.onPost();
        HapticFeedback.mediumImpact();
      } : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isCollapsed ? 16 : 32,
          vertical: isCollapsed ? 12 : 14,
        ),
        decoration: BoxDecoration(
          gradient: isEnabled ? LinearGradient(
            colors: [
              modernTheme.primaryColor!,
              modernTheme.primaryColor!.withOpacity(0.8),
              modernTheme.primaryColor!,
            ],
            stops: [
              0.0,
              _shineAnimation.value,
              1.0,
            ],
          ) : null,
          color: isEnabled ? null : modernTheme.surfaceColor,
          borderRadius: BorderRadius.circular(isCollapsed ? 20 : 24),
          boxShadow: isEnabled ? [
            BoxShadow(
              color: modernTheme.primaryColor!.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCollapsed)
              Icon(
                Icons.send,
                color: isEnabled ? Colors.white : modernTheme.textSecondaryColor,
                size: 18,
              )
            else ...[
              Icon(
                Icons.send,
                color: isEnabled ? Colors.white : modernTheme.textSecondaryColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Post',
                style: TextStyle(
                  color: isEnabled ? Colors.white : modernTheme.textSecondaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getCharacterCountColor(ModernThemeExtension modernTheme) {
    if (_characterCount > 2000) return Colors.red;
    if (_characterCount > 1800) return Colors.orange;
    if (_characterCount > 1500) return modernTheme.primaryColor!;
    return modernTheme.textSecondaryColor!;
  }

  void _insertHashtag(String tag) {
    final text = widget.captionController.text;
    final words = text.split(' ');
    words[words.length - 1] = '#$tag';
    widget.captionController.text = '${words.join(' ')} ';
    widget.captionController.selection = TextSelection.fromPosition(
      TextPosition(offset: widget.captionController.text.length),
    );
    
    _captionFocusNode.requestFocus();
    HapticFeedback.lightImpact();
  }

  void _insertText(String text) {
    final currentText = widget.captionController.text;
    final selection = widget.captionController.selection;
    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      text,
    );
    
    widget.captionController.text = newText;
    widget.captionController.selection = TextSelection.fromPosition(
      TextPosition(offset: selection.start + text.length),
    );
    
    _captionFocusNode.requestFocus();
  }
}
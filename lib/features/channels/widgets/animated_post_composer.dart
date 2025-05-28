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
  late Animation<double> _bounceAnimation;
  late Animation<double> _shineAnimation;
  
  final List<String> _trendingTags = [
    'trending', 'viral', 'fyp', 'music', 'dance', 
    'comedy', 'lifestyle', 'fashion', 'food', 'travel'
  ];
  
  bool _showHashtagSuggestions = false;
  String _lastWord = '';
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    widget.captionController.addListener(_onCaptionChanged);
  }
  
  void _initializeAnimations() {
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _shineController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 0.95,
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
    
    _bounceController.repeat(reverse: true);
    _shineController.repeat();
  }
  
  void _onCaptionChanged() {
    final text = widget.captionController.text;
    final words = text.split(' ');
    final lastWord = words.isNotEmpty ? words.last : '';
    
    setState(() {
      _lastWord = lastWord;
      _showHashtagSuggestions = lastWord.startsWith('#') && lastWord.length > 1;
    });
  }
  
  @override
  void dispose() {
    widget.captionController.removeListener(_onCaptionChanged);
    _bounceController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Container(
      decoration: BoxDecoration(
        color: modernTheme.backgroundColor,
        borderRadius: BorderRadius.circular(widget.isExpanded ? 24 : 40),
        boxShadow: [
          BoxShadow(
            color: modernTheme.primaryColor!.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: widget.isExpanded
            ? _buildExpandedView(modernTheme)
            : _buildCollapsedView(modernTheme),
      ),
    );
  }

  Widget _buildCollapsedView(ModernThemeExtension modernTheme) {
    return InkWell(
      onTap: widget.onExpandToggle,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            // Media count badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    modernTheme.primaryColor!,
                    modernTheme.primaryColor!.withOpacity(0.7),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    widget.mediaCount == 1 && widget.captionController.text.isEmpty
                        ? Icons.video_library
                        : Icons.check_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                  if (widget.mediaCount > 1)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${widget.mediaCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Caption preview
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
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.captionController.text.isNotEmpty)
                    Text(
                      'Tap to edit',
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            
            // Post button
            AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _bounceAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          modernTheme.primaryColor!,
                          modernTheme.primaryColor!.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: IconButton(
                      onPressed: widget.captionController.text.isNotEmpty
                          ? widget.onPost
                          : null,
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedView(ModernThemeExtension modernTheme) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: modernTheme.dividerColor ?? Colors.grey.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onExpandToggle,
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
              const SizedBox(width: 8),
              Text(
                'Create Post',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Character count
              Text(
                '${widget.captionController.text.length}/2200',
                style: TextStyle(
                  color: widget.captionController.text.length > 2000
                      ? Colors.orange
                      : modernTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        
        // Caption input
        Expanded(
          child: Stack(
            children: [
              TextField(
                controller: widget.captionController,
                maxLines: null,
                maxLength: 2200,
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 16,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'What\'s on your mind?',
                  hintStyle: TextStyle(
                    color: modernTheme.textSecondaryColor,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                  counterText: '',
                ),
                autofocus: true,
              ),
              
              // Hashtag suggestions
              if (_showHashtagSuggestions)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildHashtagSuggestions(modernTheme),
                ),
            ],
          ),
        ),
        
        // Bottom toolbar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: modernTheme.dividerColor ?? Colors.grey.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              // Emoji button
              IconButton(
                onPressed: () {
                  // Show emoji picker
                },
                icon: Icon(
                  Icons.emoji_emotions_outlined,
                  color: modernTheme.textSecondaryColor,
                ),
              ),
              
              // Mention button
              IconButton(
                onPressed: () {
                  widget.captionController.text += '@';
                  widget.captionController.selection = TextSelection.fromPosition(
                    TextPosition(offset: widget.captionController.text.length),
                  );
                },
                icon: Icon(
                  Icons.alternate_email,
                  color: modernTheme.textSecondaryColor,
                ),
              ),
              
              // Hashtag button
              IconButton(
                onPressed: () {
                  widget.captionController.text += '#';
                  widget.captionController.selection = TextSelection.fromPosition(
                    TextPosition(offset: widget.captionController.text.length),
                  );
                },
                icon: Icon(
                  Icons.tag,
                  color: modernTheme.textSecondaryColor,
                ),
              ),
              
              const Spacer(),
              
              // Post button
              AnimatedBuilder(
                animation: _shineAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
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
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.captionController.text.isNotEmpty
                            ? widget.onPost
                            : null,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          child: const Text(
                            'Post',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHashtagSuggestions(ModernThemeExtension modernTheme) {
    final searchTerm = _lastWord.substring(1).toLowerCase();
    final suggestions = _trendingTags
        .where((tag) => tag.toLowerCase().contains(searchTerm))
        .toList();
    
    if (suggestions.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: modernTheme.backgroundColor,
        border: Border(
          top: BorderSide(
            color: modernTheme.dividerColor ?? Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final tag = suggestions[index];
          return GestureDetector(
            onTap: () => _insertHashtag(tag),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: modernTheme.primaryColor!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: modernTheme.primaryColor!.withOpacity(0.3),
                ),
              ),
              child: Text(
                '#$tag',
                style: TextStyle(
                  color: modernTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _insertHashtag(String tag) {
    final text = widget.captionController.text;
    final words = text.split(' ');
    words[words.length - 1] = '#$tag';
    widget.captionController.text = '${words.join(' ')} ';
    widget.captionController.selection = TextSelection.fromPosition(
      TextPosition(offset: widget.captionController.text.length),
    );
    
    HapticFeedback.lightImpact();
  }
}
// lib/features/channels/widgets/enhanced_post_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class EnhancedPostForm extends StatefulWidget {
  final TextEditingController captionController;
  final TextEditingController tagsController;
  final bool isEnabled;
  final Function(String)? onCaptionChanged;
  final Function(List<String>)? onTagsChanged;
  final int maxCaptionLength;
  final int maxTags;

  const EnhancedPostForm({
    Key? key,
    required this.captionController,
    required this.tagsController,
    required this.isEnabled,
    this.onCaptionChanged,
    this.onTagsChanged,
    this.maxCaptionLength = 2200,
    this.maxTags = 30,
  }) : super(key: key);

  @override
  State<EnhancedPostForm> createState() => _EnhancedPostFormState();
}

class _EnhancedPostFormState extends State<EnhancedPostForm>
    with TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _bounceController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;
  
  // Form state
  List<String> _currentTags = [];
  bool _isTagInputFocused = false;
  bool _isCaptionFocused = false;
  final FocusNode _captionFocusNode = FocusNode();
  final FocusNode _tagsFocusNode = FocusNode();
  
  // Suggested tags
  final List<String> _suggestedTags = [
    'trending', 'viral', 'fyp', 'music', 'dance', 'comedy', 'lifestyle',
    'fashion', 'food', 'travel', 'tech', 'art', 'sports', 'gaming',
    'beauty', 'fitness', 'nature', 'pets', 'family', 'friends'
  ];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeFocusListeners();
    _parseInitialTags();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    _slideController.forward();
    _bounceController.forward();
  }

  void _initializeFocusListeners() {
    _captionFocusNode.addListener(() {
      setState(() {
        _isCaptionFocused = _captionFocusNode.hasFocus;
      });
    });
    
    _tagsFocusNode.addListener(() {
      setState(() {
        _isTagInputFocused = _tagsFocusNode.hasFocus;
      });
    });
  }

  void _parseInitialTags() {
    if (widget.tagsController.text.isNotEmpty) {
      _currentTags = widget.tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _bounceController.dispose();
    _captionFocusNode.dispose();
    _tagsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _bounceAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Caption field
            _buildCaptionField(modernTheme),
            
            const SizedBox(height: 20),
            
            // Tags field
            _buildTagsField(modernTheme),
            
            const SizedBox(height: 16),
            
            // Suggested tags
            if (_isTagInputFocused || _currentTags.isEmpty)
              _buildSuggestedTags(modernTheme),
            
            const SizedBox(height: 20),
            
            // Post settings
            _buildPostSettings(modernTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptionField(ModernThemeExtension modernTheme) {
    final remainingChars = widget.maxCaptionLength - widget.captionController.text.length;
    final isNearLimit = remainingChars < 100;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Caption',
          style: TextStyle(
            color: modernTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: modernTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isCaptionFocused
                  ? modernTheme.primaryColor!
                  : modernTheme.borderColor ?? Colors.grey.withOpacity(0.2),
              width: _isCaptionFocused ? 2 : 1,
            ),
            boxShadow: _isCaptionFocused
                ? [
                    BoxShadow(
                      color: modernTheme.primaryColor!.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              TextFormField(
                controller: widget.captionController,
                focusNode: _captionFocusNode,
                enabled: widget.isEnabled,
                maxLines: 4,
                maxLength: widget.maxCaptionLength,
                onChanged: (value) {
                  setState(() {});
                  widget.onCaptionChanged?.call(value);
                },
                decoration: InputDecoration(
                  hintText: 'Share your story...',
                  hintStyle: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  counterText: '', // Hide default counter
                ),
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              
              // Custom character counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tip: Add hashtags to increase visibility',
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor!.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        color: isNearLimit ? Colors.orange : modernTheme.textSecondaryColor,
                        fontSize: 12,
                        fontWeight: isNearLimit ? FontWeight.bold : FontWeight.normal,
                      ),
                      child: Text('$remainingChars'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTagsField(ModernThemeExtension modernTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tags',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: modernTheme.primaryColor!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentTags.length}/${widget.maxTags}',
                style: TextStyle(
                  color: modernTheme.primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Tags display
        if (_currentTags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _currentTags.map((tag) => _buildTagChip(tag, modernTheme)).toList(),
          ),
          const SizedBox(height: 12),
        ],
        
        // Tags input
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: modernTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isTagInputFocused
                  ? modernTheme.primaryColor!
                  : modernTheme.borderColor ?? Colors.grey.withOpacity(0.2),
              width: _isTagInputFocused ? 2 : 1,
            ),
            boxShadow: _isTagInputFocused
                ? [
                    BoxShadow(
                      color: modernTheme.primaryColor!.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.tagsController,
            focusNode: _tagsFocusNode,
            enabled: widget.isEnabled,
            onChanged: _onTagsChanged,
            onFieldSubmitted: (_) => _addTagFromInput(),
            decoration: InputDecoration(
              hintText: 'Add tags (press Enter to add)',
              hintStyle: TextStyle(
                color: modernTheme.textSecondaryColor,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: Icon(
                Icons.tag,
                color: _isTagInputFocused ? modernTheme.primaryColor : modernTheme.textSecondaryColor,
              ),
              suffixIcon: widget.tagsController.text.isNotEmpty
                  ? IconButton(
                      onPressed: _addTagFromInput,
                      icon: Icon(
                        Icons.add,
                        color: modernTheme.primaryColor,
                      ),
                    )
                  : null,
            ),
            style: TextStyle(
              color: modernTheme.textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagChip(String tag, ModernThemeExtension modernTheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Chip(
        label: Text(
          '#$tag',
          style: TextStyle(
            color: modernTheme.primaryColor,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        backgroundColor: modernTheme.primaryColor!.withOpacity(0.1),
        deleteIcon: Icon(
          Icons.close,
          size: 16,
          color: modernTheme.primaryColor!.withOpacity(0.7),
        ),
        onDeleted: widget.isEnabled ? () => _removeTag(tag) : null,
        side: BorderSide(
          color: modernTheme.primaryColor!.withOpacity(0.3),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildSuggestedTags(ModernThemeExtension modernTheme) {
    final availableTags = _suggestedTags
        .where((tag) => !_currentTags.contains(tag))
        .take(10)
        .toList();
    
    if (availableTags.isEmpty) return Container();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggested',
          style: TextStyle(
            color: modernTheme.textSecondaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableTags.map((tag) {
            return GestureDetector(
              onTap: () => _addTag(tag),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: modernTheme.primaryColor!.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '#$tag',
                  style: TextStyle(
                    color: modernTheme.primaryColor!.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPostSettings(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: modernTheme.borderColor ?? Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Post Settings',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildSettingRow(
            modernTheme,
            icon: Icons.public,
            title: 'Visibility',
            subtitle: 'Who can see this post',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Everyone',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: modernTheme.textSecondaryColor,
                  size: 16,
                ),
              ],
            ),
            onTap: widget.isEnabled ? () {
              // TODO: Implement visibility settings
            } : null,
          ),
          
          const SizedBox(height: 12),
          
          _buildSettingRow(
            modernTheme,
            icon: Icons.comment_outlined,
            title: 'Comments',
            subtitle: 'Allow people to comment',
            trailing: Switch(
              value: true,
              onChanged: widget.isEnabled ? (value) {
                // TODO: Implement comment toggle
              } : null,
              activeColor: modernTheme.primaryColor,
            ),
          ),
          
          const SizedBox(height: 12),
          
          _buildSettingRow(
            modernTheme,
            icon: Icons.download_outlined,
            title: 'Downloads',
            subtitle: 'Allow people to download',
            trailing: Switch(
              value: false,
              onChanged: widget.isEnabled ? (value) {
                // TODO: Implement download toggle
              } : null,
              activeColor: modernTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(
    ModernThemeExtension modernTheme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: modernTheme.primaryColor!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: modernTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  void _onTagsChanged(String value) {
    // Handle comma-separated input
    if (value.endsWith(',') || value.endsWith(' ')) {
      _addTagFromInput();
    }
  }

  void _addTagFromInput() {
    final input = widget.tagsController.text.trim();
    if (input.isEmpty) return;
    
    final newTags = input.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty);
    
    for (final tag in newTags) {
      _addTag(tag);
    }
    
    widget.tagsController.clear();
  }

  void _addTag(String tag) {
    final cleanTag = tag.replaceAll('#', '').trim().toLowerCase();
    
    if (cleanTag.isEmpty || 
        _currentTags.contains(cleanTag) || 
        _currentTags.length >= widget.maxTags) {
      return;
    }
    
    setState(() {
      _currentTags.add(cleanTag);
    });
    
    _updateTagsController();
    widget.onTagsChanged?.call(_currentTags);
    
    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  void _removeTag(String tag) {
    setState(() {
      _currentTags.remove(tag);
    });
    
    _updateTagsController();
    widget.onTagsChanged?.call(_currentTags);
    
    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  void _updateTagsController() {
    widget.tagsController.text = _currentTags.join(', ');
  }
}
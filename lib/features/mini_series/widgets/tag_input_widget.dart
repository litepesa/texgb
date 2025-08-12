// lib/features/mini_series/widgets/tag_input_widget.dart
import 'package:flutter/material.dart';

class TagInputWidget extends StatefulWidget {
  final List<String> tags;
  final Function(List<String>) onTagsChanged;
  final int maxTags;
  final String hintText;
  final bool enabled;
  final InputDecoration? decoration;
  final TextStyle? chipTextStyle;
  final Color? chipBackgroundColor;
  final Color? chipDeleteIconColor;

  const TagInputWidget({
    super.key,
    required this.tags,
    required this.onTagsChanged,
    this.maxTags = 10,
    this.hintText = 'Add tags...',
    this.enabled = true,
    this.decoration,
    this.chipTextStyle,
    this.chipBackgroundColor,
    this.chipDeleteIconColor,
  });

  @override
  State<TagInputWidget> createState() => _TagInputWidgetState();
}

class _TagInputWidgetState extends State<TagInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _currentInput = '';

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tags display
        if (widget.tags.isNotEmpty) ...[
          _buildTagsDisplay(theme),
          const SizedBox(height: 12),
        ],
        
        // Tag input field
        if (widget.tags.length < widget.maxTags && widget.enabled)
          _buildInputField(theme),
          
        // Max tags reached indicator
        if (widget.tags.length >= widget.maxTags)
          _buildMaxTagsIndicator(theme),
          
        // Helper text
        if (widget.tags.length < widget.maxTags && widget.enabled)
          _buildHelperText(theme),
      ],
    );
  }

  Widget _buildTagsDisplay(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.5),
        ),
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surface,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.tags.asMap().entries.map((entry) {
          final index = entry.key;
          final tag = entry.value;
          
          return _buildTagChip(tag, index, theme);
        }).toList(),
      ),
    );
  }

  Widget _buildTagChip(String tag, int index, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: widget.chipBackgroundColor ?? theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: IntrinsicWidth(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
              child: Text(
                tag,
                style: widget.chipTextStyle ?? TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (widget.enabled)
              InkWell(
                onTap: () => _removeTag(index),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, right: 8, top: 6, bottom: 6),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: widget.chipDeleteIconColor ?? 
                           theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(ThemeData theme) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      decoration: widget.decoration ?? InputDecoration(
        hintText: widget.hintText,
        border: const OutlineInputBorder(),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_currentInput.trim().isNotEmpty)
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addTag,
                tooltip: 'Add tag',
              ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _showTagHelp,
              tooltip: 'Tag guidelines',
            ),
          ],
        ),
        helperText: 'Press Enter or tap + to add a tag',
      ),
      onChanged: (value) {
        setState(() {
          _currentInput = value;
        });
      },
      onSubmitted: (_) => _addTag(),
      textInputAction: TextInputAction.done,
      maxLength: 20, // Maximum tag length
      buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
        if (!isFocused) return null;
        return Text(
          '$currentLength/${maxLength ?? 20}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: currentLength > (maxLength ?? 20) * 0.8 
                ? theme.colorScheme.error 
                : theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        );
      },
    );
  }

  Widget _buildMaxTagsIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Maximum ${widget.maxTags} tags reached',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (widget.tags.isNotEmpty && widget.enabled)
            TextButton(
              onPressed: _clearAllTags,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
              child: const Text(
                'Clear All',
                style: TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHelperText(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Tags help others discover your content. Use keywords that describe your series.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  void _addTag() {
    final tag = _controller.text.trim().toLowerCase();
    
    // Validation
    if (tag.isEmpty) {
      _showSnackBar('Tag cannot be empty');
      return;
    }
    
    if (tag.length < 2) {
      _showSnackBar('Tag must be at least 2 characters long');
      return;
    }
    
    if (tag.length > 20) {
      _showSnackBar('Tag cannot exceed 20 characters');
      return;
    }
    
    if (widget.tags.contains(tag)) {
      _showSnackBar('Tag already exists');
      _controller.clear();
      setState(() {
        _currentInput = '';
      });
      return;
    }
    
    if (widget.tags.length >= widget.maxTags) {
      _showSnackBar('Maximum ${widget.maxTags} tags allowed');
      return;
    }
    
    // Check for invalid characters
    if (!_isValidTag(tag)) {
      _showSnackBar('Tag can only contain letters, numbers, and hyphens');
      return;
    }
    
    // Add the tag
    final updatedTags = [...widget.tags, tag];
    widget.onTagsChanged(updatedTags);
    
    _controller.clear();
    setState(() {
      _currentInput = '';
    });
    
    // Show success feedback
    _showSnackBar('Tag "$tag" added', isSuccess: true);
  }

  void _removeTag(int index) {
    if (index >= 0 && index < widget.tags.length) {
      final removedTag = widget.tags[index];
      final updatedTags = List<String>.from(widget.tags);
      updatedTags.removeAt(index);
      widget.onTagsChanged(updatedTags);
      
      // Show feedback
      _showSnackBar('Tag "$removedTag" removed', isSuccess: true);
    }
  }

  void _clearAllTags() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Tags'),
        content: const Text('Are you sure you want to remove all tags?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onTagsChanged([]);
              _showSnackBar('All tags cleared', isSuccess: true);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showTagHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tag Guidelines'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('• Tags help viewers discover your content'),
              SizedBox(height: 8),
              Text('• Use 2-20 characters per tag'),
              SizedBox(height: 8),
              Text('• Only letters, numbers, and hyphens allowed'),
              SizedBox(height: 8),
              Text('• Choose relevant keywords'),
              SizedBox(height: 8),
              Text('• Examples: drama, romance, action, comedy'),
              SizedBox(height: 16),
              Text(
                'Good tags:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• romance'),
              Text('• short-drama'),
              Text('• comedy2024'),
              SizedBox(height: 12),
              Text(
                'Avoid:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Single letters (a, b, c)'),
              Text('• Special characters (@, #, !)'),
              Text('• Very long phrases'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  bool _isValidTag(String tag) {
    // Only allow alphanumeric characters and hyphens
    final validPattern = RegExp(r'^[a-z0-9-]+$');
    return validPattern.hasMatch(tag);
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// Extension to provide common tag validation
extension TagValidation on String {
  bool get isValidTag {
    if (isEmpty || length < 2 || length > 20) return false;
    final validPattern = RegExp(r'^[a-z0-9-]+$');
    return validPattern.hasMatch(toLowerCase());
  }
  
  String get sanitizedTag {
    return toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9-]'), '')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}

// Widget for displaying tags in read-only mode
class TagDisplayWidget extends StatelessWidget {
  final List<String> tags;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final double spacing;
  final double runSpacing;
  final int? maxTags;
  final VoidCallback? onMoreTapped;

  const TagDisplayWidget({
    super.key,
    required this.tags,
    this.textStyle,
    this.backgroundColor,
    this.padding,
    this.spacing = 6.0,
    this.runSpacing = 6.0,
    this.maxTags,
    this.onMoreTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayTags = maxTags != null && tags.length > maxTags!
        ? tags.take(maxTags!).toList()
        : tags;
    final hasMore = maxTags != null && tags.length > maxTags!;

    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: [
        ...displayTags.map((tag) => Container(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor ?? theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: Text(
            tag,
            style: textStyle ?? TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        )),
        if (hasMore)
          GestureDetector(
            onTap: onMoreTapped,
            child: Container(
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Text(
                '+${tags.length - maxTags!}',
                style: textStyle ?? TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
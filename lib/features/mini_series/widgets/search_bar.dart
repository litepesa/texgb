// lib/features/mini_series/widgets/search_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MiniSeriesSearchBar extends StatefulWidget {
  final String? initialQuery;
  final Function(String) onSearchChanged;
  final Function(String)? onSearchSubmitted;
  final VoidCallback? onClearSearch;
  final String hintText;
  final bool enabled;
  final bool autofocus;
  final List<String>? suggestions;
  final Function(String)? onSuggestionTapped;
  final Widget? leadingIcon;
  final List<Widget>? actions;
  final Duration debounceDelay;
  final int? maxLength;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;

  const MiniSeriesSearchBar({
    super.key,
    this.initialQuery,
    required this.onSearchChanged,
    this.onSearchSubmitted,
    this.onClearSearch,
    this.hintText = 'Search mini series...',
    this.enabled = true,
    this.autofocus = false,
    this.suggestions,
    this.onSuggestionTapped,
    this.leadingIcon,
    this.actions,
    this.debounceDelay = const Duration(milliseconds: 500),
    this.maxLength,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<MiniSeriesSearchBar> createState() => _MiniSeriesSearchBarState();
}

class _MiniSeriesSearchBarState extends State<MiniSeriesSearchBar>
    with TickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _showSuggestions = false;
  String _currentQuery = '';
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _focusNode = FocusNode();
    _currentQuery = widget.initialQuery ?? '';
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _focusNode.addListener(_onFocusChanged);
    
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MiniSeriesSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery) {
      _controller.text = widget.initialQuery ?? '';
      _currentQuery = widget.initialQuery ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        _buildSearchField(theme),
        if (_showSuggestions && widget.suggestions != null && widget.suggestions!.isNotEmpty)
          _buildSuggestionsCard(theme),
      ],
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _focusNode.hasFocus 
              ? theme.colorScheme.primary 
              : theme.colorScheme.outline.withOpacity(0.3),
          width: _focusNode.hasFocus ? 2 : 1,
        ),
        boxShadow: _focusNode.hasFocus ? [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        maxLength: widget.maxLength,
        keyboardType: widget.keyboardType,
        textCapitalization: widget.textCapitalization,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          prefixIcon: widget.leadingIcon ?? Icon(
            Icons.search,
            color: _focusNode.hasFocus 
                ? theme.colorScheme.primary 
                : theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          suffixIcon: _buildSuffixActions(theme),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          counterText: '', // Hide character counter
        ),
        onChanged: _onSearchChanged,
        onSubmitted: _onSearchSubmitted,
        textInputAction: TextInputAction.search,
      ),
    );
  }

  Widget? _buildSuffixActions(ThemeData theme) {
    final actions = <Widget>[];
    
    // Clear button
    if (_currentQuery.isNotEmpty) {
      actions.add(
        FadeTransition(
          opacity: _fadeAnimation,
          child: IconButton(
            icon: Icon(
              Icons.clear,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            onPressed: _clearSearch,
            tooltip: 'Clear search',
          ),
        ),
      );
    }
    
    // Voice search button (optional)
    actions.add(
      IconButton(
        icon: Icon(
          Icons.mic,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        onPressed: _startVoiceSearch,
        tooltip: 'Voice search',
      ),
    );
    
    // Custom actions
    if (widget.actions != null) {
      actions.addAll(widget.actions!);
    }
    
    if (actions.isEmpty) return null;
    
    if (actions.length == 1) {
      return actions.first;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions,
    );
  }

  Widget _buildSuggestionsCard(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent searches',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _clearSuggestions,
                  child: Text(
                    'Clear',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...widget.suggestions!.take(5).map((suggestion) => 
            _buildSuggestionItem(suggestion, theme)),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String suggestion, ThemeData theme) {
    return InkWell(
      onTap: () => _selectSuggestion(suggestion),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.search,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                suggestion,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Icon(
              Icons.call_made,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  void _onFocusChanged() {
    setState(() {
      _showSuggestions = _focusNode.hasFocus && 
                       widget.suggestions != null && 
                       widget.suggestions!.isNotEmpty;
    });
    
    if (_focusNode.hasFocus && _currentQuery.isNotEmpty) {
      _animationController.forward();
    } else if (!_focusNode.hasFocus) {
      _animationController.reverse();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _currentQuery = query;
    });
    
    if (query.isNotEmpty && !_animationController.isCompleted) {
      _animationController.forward();
    } else if (query.isEmpty && _animationController.isCompleted) {
      _animationController.reverse();
    }
    
    // Debounced search
    Future.delayed(widget.debounceDelay, () {
      if (_currentQuery == query && mounted) {
        widget.onSearchChanged(query);
      }
    });
  }

  void _onSearchSubmitted(String query) {
    _focusNode.unfocus();
    setState(() {
      _showSuggestions = false;
    });
    
    if (query.trim().isNotEmpty) {
      widget.onSearchSubmitted?.call(query.trim());
      _addToSearchHistory(query.trim());
    }
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _currentQuery = '';
      _showSuggestions = false;
    });
    
    _animationController.reverse();
    widget.onClearSearch?.call();
    widget.onSearchChanged('');
    
    // Provide haptic feedback
    HapticFeedback.lightImpact();
  }

  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    setState(() {
      _currentQuery = suggestion;
      _showSuggestions = false;
    });
    
    _focusNode.unfocus();
    widget.onSuggestionTapped?.call(suggestion);
    widget.onSearchChanged(suggestion);
    
    // Provide haptic feedback
    HapticFeedback.selectionClick();
  }

  void _startVoiceSearch() {
    // Placeholder for voice search implementation
    // You can integrate with speech_to_text package here
    HapticFeedback.mediumImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice search coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearSuggestions() {
    // This would clear the search history in a real implementation
    HapticFeedback.lightImpact();
  }

  void _addToSearchHistory(String query) {
    // This would add the query to search history in a real implementation
    // You could save this to SharedPreferences or a local database
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

// Specialized search bar for mini-series with predefined categories
class MiniSeriesCategorySearchBar extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(String)? onCategorySelected;
  final String? selectedCategory;
  final List<String> categories;

  const MiniSeriesCategorySearchBar({
    super.key,
    required this.onSearchChanged,
    this.onCategorySelected,
    this.selectedCategory,
    this.categories = const [
      'All',
      'Drama',
      'Comedy',
      'Romance',
      'Action',
      'Thriller',
      'Horror',
      'Fantasy',
    ],
  });

  @override
  State<MiniSeriesCategorySearchBar> createState() => _MiniSeriesCategorySearchBarState();
}

class _MiniSeriesCategorySearchBarState extends State<MiniSeriesCategorySearchBar> {
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory ?? 'All';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Search bar
        MiniSeriesSearchBar(
          onSearchChanged: widget.onSearchChanged,
          hintText: 'Search ${_selectedCategory.toLowerCase()} series...',
        ),
        
        const SizedBox(height: 16),
        
        // Category chips
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.categories.length,
            itemBuilder: (context, index) {
              final category = widget.categories[index];
              final isSelected = category == _selectedCategory;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                      widget.onCategorySelected?.call(category);
                    }
                  },
                  backgroundColor: theme.colorScheme.surface,
                  selectedColor: theme.colorScheme.primaryContainer,
                  checkmarkColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected 
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected 
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Search results overlay widget
class SearchResultsOverlay extends StatelessWidget {
  final List<String> results;
  final Function(String) onResultTapped;
  final VoidCallback onDismiss;

  const SearchResultsOverlay({
    super.key,
    required this.results,
    required this.onResultTapped,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Search Results',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: onDismiss,
                        icon: const Icon(Icons.close),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
                
                // Results list
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final result = results[index];
                      return ListTile(
                        title: Text(result),
                        leading: const Icon(Icons.search),
                        onTap: () => onResultTapped(result),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Search history manager (utility class)
class SearchHistoryManager {
  static const String _historyKey = 'mini_series_search_history';
  static const int _maxHistoryItems = 10;
  
  static Future<List<String>> getSearchHistory() async {
    // Implementation would use SharedPreferences
    // For now, return mock data
    return [
      'romantic drama',
      'action series',
      'comedy shorts',
      'thriller episodes',
      'fantasy adventure',
    ];
  }
  
  static Future<void> addToHistory(String query) async {
    // Implementation would save to SharedPreferences
    // For now, this is a placeholder
  }
  
  static Future<void> clearHistory() async {
    // Implementation would clear SharedPreferences
    // For now, this is a placeholder
  }
  
  static Future<void> removeFromHistory(String query) async {
    // Implementation would remove specific item from SharedPreferences
    // For now, this is a placeholder
  }
}
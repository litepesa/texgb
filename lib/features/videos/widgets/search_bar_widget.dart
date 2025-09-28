// ===============================
// lib/features/videos/widgets/search_bar_widget.dart
// Search Bar Widget with Real-time Suggestions and Filters
// ===============================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/videos/models/search_models.dart';

class SearchBarWidget extends StatefulWidget {
  final String? initialQuery;
  final String placeholder;
  final Function(String)? onQueryChanged;
  final Function(String)? onQuerySubmitted;
  final Function()? onClearTapped;
  final Function()? onFilterTapped;
  final List<String> suggestions;
  final List<SearchSuggestion> recentSearches;
  final List<SearchSuggestion> trendingTerms;
  final bool isLoading;
  final bool showSuggestions;
  final bool showFilters;
  final bool hasActiveFilters;
  final SearchFilters? activeFilters;
  final bool autofocus;
  final TextInputAction textInputAction;
  final VoidCallback? onBackPressed;
  final Function(String)? onSuggestionTapped;

  const SearchBarWidget({
    super.key,
    this.initialQuery,
    this.placeholder = 'Search videos and creators...',
    this.onQueryChanged,
    this.onQuerySubmitted,
    this.onClearTapped,
    this.onFilterTapped,
    this.suggestions = const [],
    this.recentSearches = const [],
    this.trendingTerms = const [],
    this.isLoading = false,
    this.showSuggestions = true,
    this.showFilters = false,
    this.hasActiveFilters = false,
    this.activeFilters,
    this.autofocus = false,
    this.textInputAction = TextInputAction.search,
    this.onBackPressed,
    this.onSuggestionTapped,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget>
    with TickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _debounceTimer;
  bool _showClearButton = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _focusNode = FocusNode();
    
    // Animation controller for smooth transitions
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Set initial state
    _showClearButton = _controller.text.isNotEmpty;
    
    // Listen to text changes
    _controller.addListener(_onTextChanged);
    
    // Listen to focus changes
    _focusNode.addListener(_onFocusChanged);
    
    // Auto focus if requested
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update controller text if initial query changed
    if (widget.initialQuery != oldWidget.initialQuery && 
        widget.initialQuery != null &&
        widget.initialQuery != _controller.text) {
      _controller.text = widget.initialQuery!;
    }
  }

  void _onTextChanged() {
    final text = _controller.text;
    final shouldShowClear = text.isNotEmpty;
    
    if (shouldShowClear != _showClearButton) {
      setState(() {
        _showClearButton = shouldShowClear;
      });
    }

    // Debounce the query change callback
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      Duration(milliseconds: Constants.searchDebounceDelayMs),
      () {
        if (mounted) {
          widget.onQueryChanged?.call(text);
        }
      },
    );
  }

  void _onFocusChanged() {
    final focused = _focusNode.hasFocus;
    if (focused != _isFocused) {
      setState(() {
        _isFocused = focused;
      });
      
      if (focused) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _onSubmitted(String value) {
    if (value.trim().isNotEmpty) {
      widget.onQuerySubmitted?.call(value.trim());
      _focusNode.unfocus();
    }
  }

  void _onClearPressed() {
    _controller.clear();
    widget.onClearTapped?.call();
    _focusNode.requestFocus();
    
    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  void _onSuggestionSelected(String suggestion) {
    _controller.text = suggestion;
    widget.onSuggestionTapped?.call(suggestion);
    widget.onQuerySubmitted?.call(suggestion);
    _focusNode.unfocus();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        if (widget.showSuggestions && _isFocused) _buildSuggestions(),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: Constants.searchBarHeight,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(Constants.defaultRadius),
        border: Border.all(
          color: _isFocused ? Colors.white.withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Back button (if provided)
          if (widget.onBackPressed != null) ...[
            IconButton(
              onPressed: widget.onBackPressed,
              icon: const Icon(
                CupertinoIcons.back,
                color: Colors.white70,
                size: 20,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              constraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
            ),
          ] else ...[
            const SizedBox(width: 16),
          ],

          // Search icon
          Icon(
            CupertinoIcons.search,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 12),

          // Text field
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              textInputAction: widget.textInputAction,
              onSubmitted: _onSubmitted,
              maxLength: Constants.maxSearchQueryLength,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
            ),
          ),

          // Loading indicator
          if (widget.isLoading) ...[
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Clear button
          if (_showClearButton && !widget.isLoading) ...[
            GestureDetector(
              onTap: _onClearPressed,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Filter button
          if (widget.showFilters) ...[
            GestureDetector(
              onTap: widget.onFilterTapped,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.hasActiveFilters 
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Icon(
                      CupertinoIcons.slider_horizontal_3,
                      color: widget.hasActiveFilters 
                          ? Colors.blue
                          : Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                    if (widget.hasActiveFilters)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    if (!_isFocused) return const SizedBox.shrink();

    final hasQuery = _controller.text.trim().isNotEmpty;
    final hasRecentSearches = widget.recentSearches.isNotEmpty;
    final hasTrendingTerms = widget.trendingTerms.isNotEmpty;
    final hasSuggestions = widget.suggestions.isNotEmpty;

    if (!hasQuery && !hasRecentSearches && !hasTrendingTerms) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(Constants.defaultRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Real-time suggestions (when typing)
            if (hasQuery && hasSuggestions) ...[
              _buildSuggestionSection(
                title: 'Suggestions',
                items: widget.suggestions.take(5).map((s) => 
                  SearchSuggestion.completion(s, 'suggestion')).toList(),
                icon: CupertinoIcons.lightbulb,
              ),
            ],

            // Recent searches (when no query or short query)
            if (!hasQuery && hasRecentSearches) ...[
              _buildSuggestionSection(
                title: 'Recent Searches',
                items: widget.recentSearches.take(5).toList(),
                icon: CupertinoIcons.clock,
                showClearAll: true,
              ),
            ],

            // Trending terms (when no query)
            if (!hasQuery && hasTrendingTerms) ...[
              if (hasRecentSearches) const Divider(color: Colors.white10, height: 1),
              _buildSuggestionSection(
                title: 'Trending',
                items: widget.trendingTerms.take(5).toList(),
                icon: CupertinoIcons.flame,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionSection({
    required String title,
    required List<SearchSuggestion> items,
    required IconData icon,
    bool showClearAll = false,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.white.withOpacity(0.7),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (showClearAll)
                GestureDetector(
                  onTap: () {
                    // Handle clear all recent searches
                    HapticFeedback.lightImpact();
                  },
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      color: Colors.blue.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Suggestion items
        ...items.map((suggestion) => _buildSuggestionItem(suggestion)),
      ],
    );
  }

  Widget _buildSuggestionItem(SearchSuggestion suggestion) {
    return GestureDetector(
      onTap: () => _onSuggestionSelected(suggestion.text),
      child: Container(
        height: Constants.searchSuggestionItemHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
        ),
        child: Row(
          children: [
            // Suggestion icon
            Icon(
              _getSuggestionIcon(suggestion.type),
              color: Colors.white.withOpacity(0.5),
              size: 16,
            ),
            const SizedBox(width: 12),

            // Suggestion text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    suggestion.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (suggestion.frequency != null && suggestion.frequency! > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      suggestion.displayFrequency,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Arrow icon for navigation
            Icon(
              CupertinoIcons.arrow_up_left,
              color: Colors.white.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSuggestionIcon(String type) {
    switch (type) {
      case Constants.suggestionTypeRecent:
        return CupertinoIcons.clock;
      case Constants.suggestionTypeTrending:
        return CupertinoIcons.flame;
      case Constants.suggestionTypeCompletion:
        return CupertinoIcons.search;
      default:
        return CupertinoIcons.search;
    }
  }
}

// ===============================
// SEARCH FILTER CHIPS WIDGET
// ===============================

class SearchFilterChips extends StatelessWidget {
  final SearchFilters filters;
  final Function(SearchFilters) onFiltersChanged;
  final bool showAllFilters;

  const SearchFilterChips({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
    this.showAllFilters = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Media Type Filter
        _buildFilterChip(
          context: context,
          label: Constants.getSearchFilterDisplayName('mediaType', filters.mediaType),
          isActive: Constants.isSearchFilterActive('mediaType', filters.mediaType),
          onTap: () => _showMediaTypeSelector(context),
        ),

        // Time Range Filter
        _buildFilterChip(
          context: context,
          label: Constants.getSearchFilterDisplayName('timeRange', filters.timeRange),
          isActive: Constants.isSearchFilterActive('timeRange', filters.timeRange),
          onTap: () => _showTimeRangeSelector(context),
        ),

        // Sort By Filter
        _buildFilterChip(
          context: context,
          label: Constants.getSearchFilterDisplayName('sortBy', filters.sortBy),
          isActive: Constants.isSearchFilterActive('sortBy', filters.sortBy),
          onTap: () => _showSortBySelector(context),
        ),

        // Price Filter
        if (showAllFilters || filters.hasPrice != null)
          _buildFilterChip(
            context: context,
            label: filters.hasPrice == true ? 'Paid' : filters.hasPrice == false ? 'Free' : 'All Prices',
            isActive: filters.hasPrice != null,
            onTap: () => _showPriceSelector(context),
          ),

        // Verified Filter
        if (showAllFilters || filters.isVerified != null)
          _buildFilterChip(
            context: context,
            label: filters.isVerified == true ? 'Verified' : 'All Content',
            isActive: filters.isVerified != null,
            onTap: () => _toggleVerifiedFilter(),
          ),

        // Clear All Filters
        if (filters.hasActiveFilters)
          _buildFilterChip(
            context: context,
            label: 'Clear All',
            isActive: false,
            isAction: true,
            onTap: () => onFiltersChanged(const SearchFilters()),
          ),
      ],
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool isAction = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: Constants.searchFilterChipHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? Colors.blue.withOpacity(0.2)
              : isAction 
                  ? Colors.red.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive 
                ? Colors.blue.withOpacity(0.5)
                : isAction
                    ? Colors.red.withOpacity(0.3)
                    : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive 
                    ? Colors.blue
                    : isAction
                        ? Colors.red
                        : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isActive && !isAction) ...[
              const SizedBox(width: 4),
              Icon(
                CupertinoIcons.checkmark,
                color: Colors.blue,
                size: 14,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMediaTypeSelector(BuildContext context) {
    _showFilterBottomSheet(
      context: context,
      title: 'Content Type',
      options: [
        FilterOption('All Content', Constants.filterMediaTypeAll),
        FilterOption('Videos Only', Constants.filterMediaTypeVideo),
        FilterOption('Images Only', Constants.filterMediaTypeImage),
      ],
      currentValue: filters.mediaType,
      onSelected: (value) {
        onFiltersChanged(filters.copyWith(mediaType: value));
      },
    );
  }

  void _showTimeRangeSelector(BuildContext context) {
    _showFilterBottomSheet(
      context: context,
      title: 'Time Range',
      options: [
        FilterOption('All Time', Constants.filterTimeRangeAll),
        FilterOption('Today', Constants.filterTimeRangeDay),
        FilterOption('This Week', Constants.filterTimeRangeWeek),
        FilterOption('This Month', Constants.filterTimeRangeMonth),
      ],
      currentValue: filters.timeRange,
      onSelected: (value) {
        onFiltersChanged(filters.copyWith(timeRange: value));
      },
    );
  }

  void _showSortBySelector(BuildContext context) {
    _showFilterBottomSheet(
      context: context,
      title: 'Sort By',
      options: [
        FilterOption('Most Relevant', Constants.filterSortByRelevance),
        FilterOption('Latest', Constants.filterSortByLatest),
        FilterOption('Most Popular', Constants.filterSortByPopular),
        FilterOption('Most Viewed', Constants.filterSortByViews),
        FilterOption('Most Liked', Constants.filterSortByLikes),
      ],
      currentValue: filters.sortBy,
      onSelected: (value) {
        onFiltersChanged(filters.copyWith(sortBy: value));
      },
    );
  }

  void _showPriceSelector(BuildContext context) {
    _showFilterBottomSheet(
      context: context,
      title: 'Price',
      options: [
        FilterOption('All Prices', null),
        FilterOption('Free Only', false),
        FilterOption('Paid Only', true),
      ],
      currentValue: filters.hasPrice,
      onSelected: (value) {
        onFiltersChanged(filters.copyWith(hasPrice: value));
      },
    );
  }

  void _toggleVerifiedFilter() {
    final newValue = filters.isVerified == true ? null : true;
    onFiltersChanged(filters.copyWith(isVerified: newValue));
  }

  void _showFilterBottomSheet({
    required BuildContext context,
    required String title,
    required List<FilterOption> options,
    required dynamic currentValue,
    required Function(dynamic) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...options.map((option) => ListTile(
              title: Text(
                option.label,
                style: const TextStyle(color: Colors.white),
              ),
              trailing: currentValue == option.value
                  ? const Icon(CupertinoIcons.checkmark, color: Colors.blue)
                  : null,
              onTap: () {
                Navigator.pop(context);
                onSelected(option.value);
              },
            )),
          ],
        ),
      ),
    );
  }
}

class FilterOption {
  final String label;
  final dynamic value;

  FilterOption(this.label, this.value);
}
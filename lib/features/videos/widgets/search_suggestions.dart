// ===============================
// lib/features/videos/widgets/search_suggestions.dart
// Search Suggestions Widget - Trending terms, recent searches, and quick suggestions
// Displays when search is empty or initial state
// ===============================

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/videos/providers/video_search_provider.dart';

class SearchSuggestions extends ConsumerWidget {
  final Function(String) onSuggestionTap;
  final Function(String) onTrendingTap;
  final Function(String) onRecentTap;
  final bool showRecentSearches;
  final bool showTrendingTerms;
  final bool showQuickSuggestions;

  const SearchSuggestions({
    super.key,
    required this.onSuggestionTap,
    required this.onTrendingTap,
    required this.onRecentTap,
    this.showRecentSearches = true,
    this.showTrendingTerms = true,
    this.showQuickSuggestions = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentSearches = ref.watch(recentSearchesProvider);
    final trendingTerms = ref.watch(trendingTermsProvider);
    final suggestions = ref.watch(searchSuggestionsProvider);

    return Container(
      color: Colors.black,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick action suggestions
            if (showQuickSuggestions) ...[
              _buildQuickSuggestions(context),
              const SizedBox(height: 24),
            ],

            // Recent searches
            if (showRecentSearches && recentSearches.isNotEmpty) ...[
              _buildRecentSearches(context, ref, recentSearches),
              const SizedBox(height: 24),
            ],

            // Trending terms
            if (showTrendingTerms && trendingTerms.isNotEmpty) ...[
              _buildTrendingTerms(context, trendingTerms),
              const SizedBox(height: 24),
            ],

            // Real-time suggestions (if user has typed something)
            if (suggestions.isNotEmpty) ...[
              _buildRealTimeSuggestions(context, suggestions),
              const SizedBox(height: 24),
            ],

            // Popular categories
            _buildPopularCategories(context),
          ],
        ),
      ),
    );
  }

  // ===============================
  // QUICK SUGGESTIONS
  // ===============================

  Widget _buildQuickSuggestions(BuildContext context) {
    final quickSuggestions = [
      _QuickSuggestion('Cooking', Icons.restaurant, Colors.orange),
      _QuickSuggestion('Dance', Icons.music_note, Colors.purple),
      _QuickSuggestion('Tutorial', Icons.school, Colors.blue),
      _QuickSuggestion('Comedy', Icons.sentiment_very_satisfied, Colors.yellow),
      _QuickSuggestion('Music', Icons.headphones, Colors.green),
      _QuickSuggestion('Art', Icons.palette, Colors.pink),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Quick Search',
          Icons.flash_on,
          Colors.yellow,
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: quickSuggestions.length,
          itemBuilder: (context, index) {
            final suggestion = quickSuggestions[index];
            return _buildQuickSuggestionCard(suggestion);
          },
        ),
      ],
    );
  }

  Widget _buildQuickSuggestionCard(_QuickSuggestion suggestion) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onSuggestionTap(suggestion.title);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              suggestion.icon,
              color: suggestion.color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                suggestion.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================
  // RECENT SEARCHES
  // ===============================

  Widget _buildRecentSearches(BuildContext context, WidgetRef ref, List<String> recentSearches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionHeader(
              'Recent Searches',
              Icons.history,
              Colors.grey[400]!,
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                _showClearHistoryDialog(context, ref);
              },
              child: Text(
                'Clear',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...recentSearches.take(5).map((search) => 
          _buildRecentSearchItem(context, ref, search)
        ).toList(),
      ],
    );
  }

  Widget _buildRecentSearchItem(BuildContext context, WidgetRef ref, String search) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onRecentTap(search);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey[800]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.history,
                color: Colors.grey[500],
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  search,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(videoSearchProvider.notifier).removeFromHistory(search);
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    color: Colors.grey[500],
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================
  // TRENDING TERMS
  // ===============================

  Widget _buildTrendingTerms(BuildContext context, List<String> trendingTerms) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Trending Now',
          Icons.trending_up,
          Colors.red,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: trendingTerms.take(8).map((term) => 
            _buildTrendingChip(term)
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildTrendingChip(String term) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTrendingTap(term);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.withOpacity(0.1),
              Colors.red.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.trending_up,
              color: Colors.red,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              term,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================
  // REAL-TIME SUGGESTIONS
  // ===============================

  Widget _buildRealTimeSuggestions(BuildContext context, List<String> suggestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Suggestions',
          Icons.lightbulb_outline,
          Colors.amber,
        ),
        const SizedBox(height: 12),
        ...suggestions.take(5).map((suggestion) => 
          _buildSuggestionItem(suggestion)
        ).toList(),
      ],
    );
  }

  Widget _buildSuggestionItem(String suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onSuggestionTap(suggestion);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey[800]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.search,
                color: Colors.grey[500],
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  suggestion,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.north_west,
                color: Colors.grey[600],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================
  // POPULAR CATEGORIES
  // ===============================

  Widget _buildPopularCategories(BuildContext context) {
    final categories = [
      _CategoryItem('Food & Cooking', '🍳', ['cooking', 'recipe', 'food', 'chef']),
      _CategoryItem('Dance & Music', '💃', ['dance', 'music', 'beat', 'rhythm']),
      _CategoryItem('DIY & Crafts', '🎨', ['diy', 'craft', 'handmade', 'tutorial']),
      _CategoryItem('Comedy & Fun', '😄', ['funny', 'comedy', 'laugh', 'humor']),
      _CategoryItem('Education', '📚', ['learn', 'tutorial', 'education', 'tips']),
      _CategoryItem('Sports & Fitness', '⚽', ['sports', 'fitness', 'workout', 'exercise']),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Browse Categories',
          Icons.category,
          Colors.blue,
        ),
        const SizedBox(height: 12),
        ...categories.map((category) => 
          _buildCategoryItem(context, category)
        ).toList(),
      ],
    );
  }

  Widget _buildCategoryItem(BuildContext context, _CategoryItem category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          _showCategoryDialog(context, category);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[800]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    category.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${category.keywords.length} topics',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[600],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================
  // HELPER WIDGETS
  // ===============================

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ===============================
  // DIALOGS
  // ===============================

  void _showClearHistoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Clear Search History?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This will remove all your recent searches. This action cannot be undone.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(videoSearchProvider.notifier).clearSearchHistory();
              Navigator.pop(context);
              HapticFeedback.lightImpact();
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, _CategoryItem category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[800]!, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        category.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Choose a topic to search',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Keywords
            Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: category.keywords.map((keyword) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onSuggestionTap(keyword);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey[700]!,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        keyword,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================
// DATA MODELS
// ===============================

class _QuickSuggestion {
  final String title;
  final IconData icon;
  final Color color;

  const _QuickSuggestion(this.title, this.icon, this.color);
}

class _CategoryItem {
  final String title;
  final String emoji;
  final List<String> keywords;

  const _CategoryItem(this.title, this.emoji, this.keywords);
}

// ===============================
// SEARCH SUGGESTIONS CONTROLLER
// ===============================

class SearchSuggestionsController {
  // Popular search terms that can be used as fallbacks
  static const List<String> fallbackTrendingTerms = [
    'cooking',
    'dance',
    'tutorial',
    'comedy',
    'music',
    'art',
    'fitness',
    'travel',
    'fashion',
    'tech',
  ];

  // Quick category suggestions
  static const List<String> quickCategories = [
    'food',
    'music',
    'dance',
    'comedy',
    'tutorial',
    'art',
    'sports',
    'travel',
  ];

  // Get trending terms with fallbacks
  static List<String> getTrendingTerms(List<String> apiTerms) {
    if (apiTerms.isNotEmpty) {
      return apiTerms;
    }
    return fallbackTrendingTerms.take(6).toList();
  }

  // Generate search suggestions based on partial input
  static List<String> generateSuggestions(String partial) {
    if (partial.length < 2) return [];

    final suggestions = <String>[];
    final lowerPartial = partial.toLowerCase();

    // Add category matches
    for (final category in quickCategories) {
      if (category.startsWith(lowerPartial)) {
        suggestions.add(category);
      }
    }

    // Add trending term matches
    for (final term in fallbackTrendingTerms) {
      if (term.startsWith(lowerPartial) && !suggestions.contains(term)) {
        suggestions.add(term);
      }
    }

    // Add common completions
    final completions = _getCommonCompletions(lowerPartial);
    for (final completion in completions) {
      if (!suggestions.contains(completion)) {
        suggestions.add(completion);
      }
    }

    return suggestions.take(5).toList();
  }

  static List<String> _getCommonCompletions(String partial) {
    final Map<String, List<String>> completions = {
      'coo': ['cooking', 'cool', 'cookies'],
      'dan': ['dance', 'dancing'],
      'tut': ['tutorial', 'tutorials'],
      'fun': ['funny', 'fun'],
      'mus': ['music', 'musical'],
      'art': ['art', 'artist'],
      'spo': ['sports', 'sport'],
      'tra': ['travel', 'training'],
      'fas': ['fashion', 'fast'],
      'tec': ['tech', 'technology'],
    };

    for (final entry in completions.entries) {
      if (partial.startsWith(entry.key)) {
        return entry.value;
      }
    }

    return [];
  }

  // Format search suggestions for display
  static String formatSuggestion(String suggestion) {
    // Capitalize first letter
    if (suggestion.isEmpty) return suggestion;
    return suggestion[0].toUpperCase() + suggestion.substring(1);
  }

  // Check if suggestion is a category
  static bool isCategory(String suggestion) {
    return quickCategories.contains(suggestion.toLowerCase());
  }

  // Get category emoji
  static String getCategoryEmoji(String category) {
    const Map<String, String> categoryEmojis = {
      'food': '🍳',
      'music': '🎵',
      'dance': '💃',
      'comedy': '😄',
      'tutorial': '📚',
      'art': '🎨',
      'sports': '⚽',
      'travel': '✈️',
      'fashion': '👗',
      'tech': '💻',
    };

    return categoryEmojis[category.toLowerCase()] ?? '🔍';
  }
}
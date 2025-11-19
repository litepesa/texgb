// ===============================
// lib/features/marketplace/widgets/marketplace_search_overlay.dart
// SIMPLIFIED Search Overlay - Clean TikTok Style, No Complications
// ===============================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/marketplace/providers/marketplace_search_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MarketplaceSearchOverlay extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final Function(String videoId)? onVideoTap;
  final String? initialQuery;

  const MarketplaceSearchOverlay({
    super.key,
    required this.onClose,
    this.onVideoTap,
    this.initialQuery,
  });

  @override
  ConsumerState<MarketplaceSearchOverlay> createState() => _MarketplaceSearchOverlayState();
}

class _MarketplaceSearchOverlayState extends ConsumerState<MarketplaceSearchOverlay>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  bool _usernameOnly = false;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _focusNode = FocusNode();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animController.forward();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _focusNode.requestFocus();
          if (widget.initialQuery?.isNotEmpty == true) {
            ref.read(marketplaceSearchProvider.notifier).searchNow(widget.initialQuery!);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(marketplaceSearchProvider);
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () => _close(),
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: SlideTransition(
            position: _slideAnimation,
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping inside
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    // Search header
                    Container(
                      padding: EdgeInsets.only(
                        top: topPadding + 8,
                        left: 16,
                        right: 16,
                        bottom: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildSearchHeader(),
                    ),

                    // Filter chip
                    if (_controller.text.isNotEmpty)
                      _buildFilterChip(),

                    // Search results or empty state
                    Expanded(
                      child: _buildContent(searchState, bottomPadding),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===============================
  // SEARCH HEADER
  // ===============================

  Widget _buildSearchHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: _close,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(CupertinoIcons.back, color: Colors.black87, size: 24),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                prefixIcon: Icon(CupertinoIcons.search, color: Colors.grey[500], size: 20),
                suffixIcon: _controller.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _controller.clear();
                          ref.read(marketplaceSearchProvider.notifier).clear();
                          setState(() {});
                        },
                        child: Icon(Icons.cancel, color: Colors.grey[500], size: 20),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {});
                if (value.trim().isNotEmpty) {
                  ref.read(marketplaceSearchProvider.notifier).search(value, usernameOnly: _usernameOnly);
                } else {
                  ref.read(marketplaceSearchProvider.notifier).clear();
                }
              },
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  ref.read(marketplaceSearchProvider.notifier).searchNow(value, usernameOnly: _usernameOnly);
                }
              },
              textInputAction: TextInputAction.search,
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _close,
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // ===============================
  // FILTER CHIP
  // ===============================

  Widget _buildFilterChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() => _usernameOnly = !_usernameOnly);
              ref.read(marketplaceSearchProvider.notifier).toggleUsernameOnly();
              HapticFeedback.lightImpact();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _usernameOnly ? Colors.blue.withOpacity(0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _usernameOnly ? Colors.blue : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.person,
                    size: 14,
                    color: _usernameOnly ? Colors.blue : Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'All Users',
                    style: TextStyle(
                      color: _usernameOnly ? Colors.blue : Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // CONTENT
  // ===============================

  Widget _buildContent(SimpleSearchState state, double bottomPadding) {
    if (_controller.text.trim().isEmpty) {
      return _buildEmptyState('Start typing to search');
    }

    if (state.isLoading && !state.hasResults) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2),
      );
    }

    if (state.isError) {
      return _buildErrorState(state.errorMessage ?? 'Search failed');
    }

    if (state.isEmpty) {
      return _buildEmptyState('No results found');
    }

    if (state.hasResults) {
      return _buildResultsGrid(state, bottomPadding);
    }

    return const SizedBox.shrink();
  }

  Widget _buildResultsGrid(SimpleSearchState state, double bottomPadding) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          final pixels = notification.metrics.pixels;
          final max = notification.metrics.maxScrollExtent;
          if (pixels >= max * 0.8 && state.hasMore && !state.isLoading) {
            ref.read(marketplaceSearchProvider.notifier).loadMore();
          }
        }
        return false;
      },
      child: GridView.builder(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 12,
          bottom: bottomPadding + 12,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.65,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: state.marketplaceItems.length + (state.isLoading && state.hasResults ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.marketplaceItems.length) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2),
            );
          }

          final marketplaceItem = state.marketplaceItems[index];
          return _buildVideoCard(marketplaceItem);
        },
      ),
    );
  }

  Widget _buildVideoCard(marketplaceItem) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _close();
        Future.delayed(const Duration(milliseconds: 300), () {
          widget.onVideoTap?.call(marketplaceItem.id);
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: marketplaceItem.thumbnailUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: marketplaceItem.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.play_circle_outline, color: Colors.grey),
                    ),
            ),

            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),

            // Stats overlay
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Username
                  Text(
                    marketplaceItem.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Views
                  Row(
                    children: [
                      const Icon(CupertinoIcons.eye, color: Colors.white, size: 10),
                      const SizedBox(width: 3),
                      Text(
                        _formatCount(marketplaceItem.views),
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.search, color: Colors.grey[300], size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.grey[400], size: 64),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(color: Colors.grey[800], fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                if (_controller.text.trim().isNotEmpty) {
                  ref.read(marketplaceSearchProvider.notifier).searchNow(
                    _controller.text,
                    usernameOnly: _usernameOnly,
                  );
                }
              },
              child: const Text(
                'Try Again',
                style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================
  // HELPERS
  // ===============================

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  void _close() {
    _focusNode.unfocus();
    _animController.reverse();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) widget.onClose();
    });
  }
}

// ===============================
// OVERLAY CONTROLLER
// ===============================

class MarketplaceSearchOverlayController {
  static OverlayEntry? _entry;
  static bool _isShowing = false;

  static void show(
    BuildContext context, {
    Function(String videoId)? onVideoTap,
    String? initialQuery,
  }) {
    if (_isShowing) return;

    _isShowing = true;
    _entry = OverlayEntry(
      builder: (context) => MarketplaceSearchOverlay(
        onClose: hide,
        onVideoTap: onVideoTap,
        initialQuery: initialQuery,
      ),
    );

    Overlay.of(context).insert(_entry!);
  }

  static void hide() {
    if (!_isShowing || _entry == null) return;
    _entry!.remove();
    _entry = null;
    _isShowing = false;
  }

  static bool get isShowing => _isShowing;
}

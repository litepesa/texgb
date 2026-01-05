// lib/features/channels/screens/channels_explore_screen.dart
// WhatsApp-style Channels Discovery/Explore Screen
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/core/router/app_router.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/widgets/channel_card.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

/// Channels Explore/Discovery screen (WhatsApp-style)
/// Simple searchable list of all channels - no categories
class ChannelsExploreScreen extends ConsumerStatefulWidget {
  const ChannelsExploreScreen({super.key});

  @override
  ConsumerState<ChannelsExploreScreen> createState() =>
      _ChannelsExploreScreenState();
}

class _ChannelsExploreScreenState extends ConsumerState<ChannelsExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ModernThemeExtension _getSafeTheme() {
    if (!mounted) {
      return _getFallbackTheme();
    }

    try {
      final extension = Theme.of(context).extension<ModernThemeExtension>();
      return extension ?? _getFallbackTheme();
    } catch (e) {
      debugPrint('Modern theme error: $e');
      return _getFallbackTheme();
    }
  }

  ModernThemeExtension _getFallbackTheme() {
    final isDark =
        mounted ? Theme.of(context).brightness == Brightness.dark : false;

    return ModernThemeExtension(
      primaryColor: const Color(0xFF07C160), // WeChat green
      surfaceColor: isDark ? Colors.grey[900] : Colors.grey[50],
      textColor: isDark ? Colors.white : Colors.black,
      textSecondaryColor: isDark ? Colors.grey[400] : Colors.grey[600],
      dividerColor: isDark ? Colors.grey[800] : Colors.grey[300],
      textTertiaryColor: isDark ? Colors.grey[500] : Colors.grey[400],
      surfaceVariantColor: isDark ? Colors.grey[800] : Colors.grey[100],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getSafeTheme();

    return Scaffold(
      backgroundColor: theme.surfaceColor,
      appBar: AppBar(
        backgroundColor: theme.surfaceColor,
        elevation: 0,
        title: Text(
          'Find channels',
          style: TextStyle(
            color: theme.textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              border: Border(
                bottom: BorderSide(
                  color: (theme.dividerColor ?? Colors.grey[300]!)
                      .withOpacity(0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: theme.textColor),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: theme.textSecondaryColor),
                prefixIcon: Icon(
                  CupertinoIcons.search,
                  color: theme.textSecondaryColor,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          CupertinoIcons.clear_circled_solid,
                          color: theme.textSecondaryColor,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.surfaceVariantColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),

          // Channels list
          Expanded(
            child: _buildChannelsList(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelsList(ModernThemeExtension theme) {
    final channelsAsync = ref.watch(
      channelsListProvider(
        page: 1,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      ),
    );

    return channelsAsync.when(
      data: (channels) {
        if (channels.isEmpty) {
          return _buildEmptyState(
            icon: Icons.search_off,
            title:
                _searchQuery.isEmpty ? 'No channels yet' : 'No channels found',
            subtitle: _searchQuery.isEmpty
                ? 'Channels will appear here'
                : 'Try a different search term',
            theme: theme,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(channelsListProvider);
          },
          color: theme.primaryColor ?? const Color(0xFF07C160),
          backgroundColor: theme.surfaceColor,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ChannelCard(
                  channel: channel,
                  onTap: () => _navigateToChannelDetail(channel.id),
                  showSubscribeButton: true,
                ),
              );
            },
          ),
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(
          color: theme.primaryColor ?? const Color(0xFF07C160),
          strokeWidth: 3,
        ),
      ),
      error: (error, stack) => _buildErrorState(
        error: error.toString(),
        onRetry: () {
          ref.invalidate(channelsListProvider);
        },
        theme: theme,
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required ModernThemeExtension theme,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (theme.primaryColor ?? const Color(0xFF07C160))
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: theme.textTertiaryColor ?? Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState({
    required String error,
    required VoidCallback onRetry,
    required ModernThemeExtension theme,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor ?? const Color(0xFF07C160),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Try Again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToChannelDetail(String channelId) {
    context.goToChannelDetail(channelId);
  }
}

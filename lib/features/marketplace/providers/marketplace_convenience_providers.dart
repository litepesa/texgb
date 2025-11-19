// lib/features/marketplace/providers/marketplace_convenience_providers.dart
// Convenience providers for marketplace to simplify access to marketplace state
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/marketplace/providers/marketplace_provider.dart';
import 'package:textgb/features/marketplace/models/marketplace_item_model.dart';

part 'marketplace_convenience_providers.g.dart';

// Convenience provider to get marketplace items
@riverpod
List<MarketplaceItemModel> marketplaceItems(MarketplaceItemsRef ref) {
  final marketplaceState = ref.watch(marketplaceProvider);
  return marketplaceState.when(
    data: (data) => data.items,
    loading: () => [], // Return empty list while loading
    error: (_, __) => [],
  );
}

// Convenience provider to get liked marketplace items
@riverpod
List<String> likedMarketplaceItems(LikedMarketplaceItemsRef ref) {
  final marketplaceState = ref.watch(marketplaceProvider);
  return marketplaceState.when(
    data: (data) => data.likedItems,
    loading: () => [], // Return empty list while loading
    error: (_, __) => [],
  );
}

// Convenience provider to check if marketplace is uploading
@riverpod
bool isMarketplaceUploading(IsMarketplaceUploadingRef ref) {
  final marketplaceState = ref.watch(marketplaceProvider);
  return marketplaceState.when(
    data: (data) => data.isUploading,
    loading: () => false, // Default to false while loading
    error: (_, __) => false,
  );
}

// Convenience provider to get marketplace upload progress
@riverpod
double marketplaceUploadProgress(MarketplaceUploadProgressRef ref) {
  final marketplaceState = ref.watch(marketplaceProvider);
  return marketplaceState.when(
    data: (data) => data.uploadProgress,
    loading: () => 0.0, // Default to 0 while loading
    error: (_, __) => 0.0,
  );
}

// Helper method as provider to check if item is liked
@riverpod
bool isMarketplaceItemLiked(IsMarketplaceItemLikedRef ref, String itemId) {
  final likedItems = ref.watch(likedMarketplaceItemsProvider);
  return likedItems.contains(itemId);
}

// Error provider
@riverpod
String? marketplaceError(MarketplaceErrorRef ref) {
  final marketplaceState = ref.watch(marketplaceProvider);
  return marketplaceState.when(
    data: (data) => data.error,
    loading: () => null, // No error while loading
    error: (error, __) => error.toString(), // Return the actual error
  );
}

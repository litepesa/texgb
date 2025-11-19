// lib/features/marketplace/providers/marketplace_progress_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to track current marketplace item playback progress (0.0 to 1.0)
final marketplaceProgressProvider = StateProvider<double>((ref) => 0.0);

/// Provider to track if a marketplace item is currently playing
final isMarketplacePlayingProvider = StateProvider<bool>((ref) => false);

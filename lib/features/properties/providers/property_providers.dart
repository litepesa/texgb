// lib/features/properties/providers/property_providers.dart
import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/properties/models/property_listing_model.dart';
import 'package:textgb/features/properties/models/property_engagement_models.dart';
import 'package:textgb/features/properties/repositories/property_repository.dart';
import 'package:textgb/features/users/models/user_model.dart';

part 'property_providers.g.dart';

// Repository provider
@riverpod
PropertyRepository propertyRepository(PropertyRepositoryRef ref) {
  return HttpPropertyRepository();
}

// Property state classes
class PropertyFeedState {
  final List<PropertyListingModel> properties;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final String? lastPropertyId;

  const PropertyFeedState({
    this.properties = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.lastPropertyId,
  });

  PropertyFeedState copyWith({
    List<PropertyListingModel>? properties,
    bool? isLoading,
    bool? hasMore,
    String? error,
    String? lastPropertyId,
  }) {
    return PropertyFeedState(
      properties: properties ?? this.properties,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      lastPropertyId: lastPropertyId ?? this.lastPropertyId,
    );
  }
}

class HostPropertyState {
  final List<PropertyListingModel> properties;
  final bool isLoading;
  final String? error;

  const HostPropertyState({
    this.properties = const [],
    this.isLoading = false,
    this.error,
  });

  HostPropertyState copyWith({
    List<PropertyListingModel>? properties,
    bool? isLoading,
    String? error,
  }) {
    return HostPropertyState(
      properties: properties ?? this.properties,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ===============================
// PROPERTY FEED PROVIDER (TikTok-style)
// ===============================

@riverpod
class PropertyFeed extends _$PropertyFeed {
  PropertyRepository get _repository => ref.read(propertyRepositoryProvider);

  @override
  FutureOr<PropertyFeedState> build({
    String? city,
    double? maxRate,
    double? minRate,
    PropertyType? propertyType,
  }) async {
    try {
      final properties = await _repository.getActiveProperties(
        limit: 20,
        city: city,
        maxRate: maxRate,
        minRate: minRate,
        propertyType: propertyType,
      );

      return PropertyFeedState(
        properties: properties,
        hasMore: properties.length >= 20,
        lastPropertyId: properties.isNotEmpty ? properties.last.id : null,
      );
    } catch (e) {
      return PropertyFeedState(error: e.toString());
    }
  }

  // Load more properties for infinite scroll
  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || currentState.isLoading || !currentState.hasMore) return;

    try {
      state = AsyncValue.data(currentState.copyWith(isLoading: true));

      final moreProperties = await _repository.getActiveProperties(
        limit: 20,
        lastPropertyId: currentState.lastPropertyId,
        city: city,
        maxRate: maxRate,
        minRate: minRate,
        propertyType: propertyType,
      );

      final allProperties = [...currentState.properties, ...moreProperties];

      state = AsyncValue.data(PropertyFeedState(
        properties: allProperties,
        hasMore: moreProperties.length >= 20,
        lastPropertyId: moreProperties.isNotEmpty ? moreProperties.last.id : currentState.lastPropertyId,
      ));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Refresh properties
  Future<void> refresh() async {
    try {
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Update property in feed after interaction
  void updateProperty(PropertyListingModel updatedProperty) {
    final currentState = state.value;
    if (currentState == null) return;

    final updatedProperties = currentState.properties.map((property) {
      if (property.id == updatedProperty.id) {
        return updatedProperty;
      }
      return property;
    }).toList();

    state = AsyncValue.data(currentState.copyWith(properties: updatedProperties));
  }
}

// NEW: Global property update notifier for cross-provider updates
@riverpod
class GlobalPropertyUpdates extends _$GlobalPropertyUpdates {
  @override
  FutureOr<Map<String, PropertyListingModel>> build() async {
    return <String, PropertyListingModel>{};
  }

  void updateProperty(PropertyListingModel property) {
    final currentState = state.value ?? <String, PropertyListingModel>{};
    state = AsyncValue.data({
      ...currentState,
      property.id: property,
    });
    
    // Invalidate all property-related providers to refresh with new data
    ref.invalidate(propertyFeedProvider);
    ref.invalidate(hostPropertiesProvider);
    ref.invalidate(propertyByIdProvider);
  }

  PropertyListingModel? getProperty(String propertyId) {
    final currentState = state.value;
    return currentState?[propertyId];
  }
}

// ===============================
// HOST PROPERTIES PROVIDER
// ===============================

@riverpod
class HostProperties extends _$HostProperties {
  PropertyRepository get _repository => ref.read(propertyRepositoryProvider);

  @override
  FutureOr<HostPropertyState> build() async {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null || !currentUser.isHost) {
      return const HostPropertyState();
    }

    try {
      final properties = await _repository.getHostProperties(currentUser.uid);
      return HostPropertyState(properties: properties);
    } catch (e) {
      return HostPropertyState(error: e.toString());
    }
  }

  // Create new property listing
  Future<PropertyListingModel?> createProperty({
    required PropertyListingModel property,
    required File videoFile,
    List<File>? imageFiles,
  }) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || !currentUser.isHost) {
      throw Exception('Only hosts can create property listings');
    }

    try {
      final currentState = state.value ?? const HostPropertyState();
      state = AsyncValue.data(currentState.copyWith(isLoading: true));

      final createdProperty = await _repository.createPropertyListing(
        property: property,
        videoFile: videoFile,
        imageFiles: imageFiles,
      );

      // Update state with new property
      final updatedProperties = [...currentState.properties, createdProperty];
      state = AsyncValue.data(HostPropertyState(properties: updatedProperties));

      return createdProperty;
    } catch (e) {
      final currentState = state.value ?? const HostPropertyState();
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  // Update existing property listing
  Future<PropertyListingModel?> updateProperty({
    required PropertyListingModel property,
    File? newVideoFile,
    List<File>? newImageFiles,
  }) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || !currentUser.isHost) {
      throw Exception('Only hosts can update property listings');
    }

    try {
      final currentState = state.value ?? const HostPropertyState();
      state = AsyncValue.data(currentState.copyWith(isLoading: true));

      final updatedProperty = await _repository.updatePropertyListing(
        property: property,
        newVideoFile: newVideoFile,
        newImageFiles: newImageFiles,
      );

      // Update state with updated property
      final updatedProperties = currentState.properties.map((p) {
        if (p.id == updatedProperty.id) {
          return updatedProperty;
        }
        return p;
      }).toList();

      state = AsyncValue.data(HostPropertyState(properties: updatedProperties));

      return updatedProperty;
    } catch (e) {
      final currentState = state.value ?? const HostPropertyState();
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  // Delete property listing
  Future<void> deleteProperty(String propertyId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || !currentUser.isHost) {
      throw Exception('Only hosts can delete property listings');
    }

    try {
      final currentState = state.value ?? const HostPropertyState();
      state = AsyncValue.data(currentState.copyWith(isLoading: true));

      await _repository.deletePropertyListing(propertyId, currentUser.uid);

      // Remove property from state
      final updatedProperties = currentState.properties.where((p) => p.id != propertyId).toList();
      state = AsyncValue.data(HostPropertyState(properties: updatedProperties));
    } catch (e) {
      final currentState = state.value ?? const HostPropertyState();
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  // Submit property for admin review
  Future<void> submitForReview(String propertyId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || !currentUser.isHost) {
      throw Exception('Only hosts can submit properties for review');
    }

    try {
      await _repository.submitPropertyForReview(propertyId, currentUser.uid);

      // Update property status to pending in state
      final currentState = state.value ?? const HostPropertyState();
      final updatedProperties = currentState.properties.map((property) {
        if (property.id == propertyId) {
          return property.copyWith(status: PropertyStatus.pending);
        }
        return property;
      }).toList();

      state = AsyncValue.data(currentState.copyWith(properties: updatedProperties));
    } catch (e) {
      rethrow;
    }
  }

  // Refresh host properties
  Future<void> refresh() async {
    try {
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// ===============================
// PROPERTY ENGAGEMENT PROVIDERS
// ===============================

@riverpod
class PropertyEngagement extends _$PropertyEngagement {
  PropertyRepository get _repository => ref.read(propertyRepositoryProvider);

  @override
  FutureOr<Map<String, dynamic>> build() async {
    // Return empty state initially
    return <String, dynamic>{};
  }

  // Like/Unlike property
  Future<void> togglePropertyLike(PropertyListingModel property) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      throw Exception('Must be logged in to like properties');
    }

    try {
      if (property.isLiked) {
        await _repository.unlikeProperty(property.id, currentUser.uid);
      } else {
        await _repository.likeProperty(
          property.id,
          currentUser.uid,
          currentUser.name,
          currentUser.profileImage,
        );
      }

      // Update property in feed
      final updatedProperty = property.copyWith(
        isLiked: !property.isLiked,
        likesCount: property.isLiked ? property.likesCount - 1 : property.likesCount + 1,
      );

      // Update property globally so all providers get the update
      final globalUpdater = ref.read(globalPropertyUpdatesProvider.notifier);
      globalUpdater.updateProperty(updatedProperty);

    } catch (e) {
      rethrow;
    }
  }

  // Add comment to property
  Future<PropertyCommentModel> addComment({
    required String propertyId,
    required String content,
    String? parentCommentId,
    String? repliedToAuthorName,
  }) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      throw Exception('Must be logged in to comment on properties');
    }

    try {
      final comment = await _repository.addPropertyComment(
        propertyId: propertyId,
        authorId: currentUser.uid,
        authorName: currentUser.name,
        authorImage: currentUser.profileImage,
        content: content,
        parentCommentId: parentCommentId,
        repliedToAuthorName: repliedToAuthorName,
      );

      return comment;
    } catch (e) {
      rethrow;
    }
  }

  // Record property view
  Future<void> recordView(String propertyId, {int durationSeconds = 0}) async {
    final currentUser = ref.read(currentUserProvider);

    try {
      await _repository.recordPropertyView(
        propertyId: propertyId,
        userId: currentUser?.uid,
        userName: currentUser?.name,
        ipAddress: '127.0.0.1', // Will be determined by backend
        durationWatchedSeconds: durationSeconds,
        userAgent: 'Flutter App',
        referrer: 'property_feed',
      );
    } catch (e) {
      // Non-critical, don't throw
      print('Warning: Failed to record property view: $e');
    }
  }

  // Record property inquiry (WhatsApp redirect)
  Future<PropertyInquiryModel> recordInquiry(PropertyListingModel property) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      throw Exception('Must be logged in to inquire about properties');
    }

    try {
      final inquiry = await _repository.recordPropertyInquiry(
        propertyId: property.id,
        inquirerId: currentUser.uid,
        inquirerName: currentUser.name,
        inquirerImage: currentUser.profileImage,
        inquirerPhoneNumber: currentUser.phoneNumber,
        wasRedirectedToWhatsApp: true,
      );

      // Update property inquiry count
      final updatedProperty = property.copyWith(
        inquiriesCount: property.inquiriesCount + 1,
        lastInquiryAt: DateTime.now(),
      );

      // Update property globally so all providers get the update
      final globalUpdater = ref.read(globalPropertyUpdatesProvider.notifier);
      globalUpdater.updateProperty(updatedProperty);

      return inquiry;
    } catch (e) {
      rethrow;
    }
  }
}

// ===============================
// INDIVIDUAL PROPERTY PROVIDERS
// ===============================

@riverpod
FutureOr<PropertyListingModel?> propertyById(PropertyByIdRef ref, String propertyId) async {
  final repository = ref.watch(propertyRepositoryProvider);
  return await repository.getPropertyById(propertyId);
}

@riverpod
FutureOr<List<PropertyCommentModel>> propertyComments(PropertyCommentsRef ref, String propertyId) async {
  final repository = ref.watch(propertyRepositoryProvider);
  return await repository.getPropertyComments(propertyId);
}

@riverpod
FutureOr<List<PropertyLikeModel>> propertyLikes(PropertyLikesRef ref, String propertyId) async {
  final repository = ref.watch(propertyRepositoryProvider);
  return await repository.getPropertyLikes(propertyId);
}

@riverpod
FutureOr<bool> isPropertyLiked(IsPropertyLikedRef ref, String propertyId) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return false;

  final repository = ref.watch(propertyRepositoryProvider);
  return await repository.isPropertyLiked(propertyId, currentUser.uid);
}

// ===============================
// SEARCH AND FILTER PROVIDERS
// ===============================

@riverpod
class PropertySearch extends _$PropertySearch {
  PropertyRepository get _repository => ref.read(propertyRepositoryProvider);

  @override
  FutureOr<List<PropertyListingModel>> build(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      return await _repository.searchProperties(query: query);
    } catch (e) {
      throw Exception('Failed to search properties: $e');
    }
  }

  // Update search with filters
  Future<void> searchWithFilters({
    required String query,
    String? city,
    double? maxRate,
    double? minRate,
    PropertyType? propertyType,
  }) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      state = const AsyncValue.loading();
      final results = await _repository.searchProperties(
        query: query,
        city: city,
        maxRate: maxRate,
        minRate: minRate,
        propertyType: propertyType,
      );
      state = AsyncValue.data(results);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

@riverpod
FutureOr<List<String>> availableCities(AvailableCitiesRef ref) async {
  final repository = ref.watch(propertyRepositoryProvider);
  return await repository.getAvailableCities();
}

@riverpod
FutureOr<List<PropertyListingModel>> propertiesByCity(PropertiesByCityRef ref, String city) async {
  final repository = ref.watch(propertyRepositoryProvider);
  return await repository.getPropertiesByCity(city);
}

@riverpod
FutureOr<List<PropertyListingModel>> trendingProperties(TrendingPropertiesRef ref) async {
  final repository = ref.watch(propertyRepositoryProvider);
  return await repository.getTrendingProperties();
}

@riverpod
FutureOr<List<PropertyListingModel>> featuredProperties(FeaturedPropertiesRef ref) async {
  final repository = ref.watch(propertyRepositoryProvider);
  return await repository.getFeaturedProperties();
}

// ===============================
// ANALYTICS PROVIDERS
// ===============================

@riverpod
FutureOr<Map<String, dynamic>> propertyAnalytics(PropertyAnalyticsRef ref, String propertyId) async {
  final repository = ref.watch(propertyRepositoryProvider);
  return await repository.getPropertyAnalytics(propertyId);
}

@riverpod
FutureOr<Map<String, dynamic>> hostAnalytics(HostAnalyticsRef ref, String hostId) async {
  final repository = ref.watch(propertyRepositoryProvider);
  return await repository.getHostAnalytics(hostId);
}

@riverpod
FutureOr<List<PropertyInquiryModel>> hostInquiries(HostInquiriesRef ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null || !currentUser.isHost) {
    return [];
  }

  final repository = ref.watch(propertyRepositoryProvider);
  return await repository.getHostInquiries(currentUser.uid);
}

// ===============================
// CONVENIENCE PROVIDERS
// ===============================

@riverpod
bool canCreateProperty(CanCreatePropertyRef ref) {
  final currentUser = ref.watch(currentUserProvider);
  return currentUser != null && currentUser.isHost;
}

@riverpod
int hostPropertiesCount(HostPropertiesCountRef ref) {
  final hostProperties = ref.watch(hostPropertiesProvider);
  return hostProperties.value?.properties.length ?? 0;
}

@riverpod
List<PropertyListingModel> activeHostProperties(ActiveHostPropertiesRef ref) {
  final hostProperties = ref.watch(hostPropertiesProvider);
  final properties = hostProperties.value?.properties ?? [];
  return properties.where((property) => property.isActive).toList();
}

@riverpod
List<PropertyListingModel> pendingHostProperties(PendingHostPropertiesRef ref) {
  final hostProperties = ref.watch(hostPropertiesProvider);
  final properties = hostProperties.value?.properties ?? [];
  return properties.where((property) => property.status == PropertyStatus.pending).toList();
}

@riverpod
List<PropertyListingModel> draftHostProperties(DraftHostPropertiesRef ref) {
  final hostProperties = ref.watch(hostPropertiesProvider);
  final properties = hostProperties.value?.properties ?? [];
  return properties.where((property) => property.status == PropertyStatus.draft).toList();
}

// ===============================
// VALIDATION PROVIDERS
// ===============================

@riverpod
FutureOr<bool> isPropertyTitleAvailable(
  IsPropertyTitleAvailableRef ref,
  String title,
  String hostId, {
  String? excludePropertyId,
}) async {
  if (title.trim().isEmpty) return false;

  final repository = ref.watch(propertyRepositoryProvider);
  return await repository.isPropertyTitleAvailable(
    title.trim(),
    hostId,
    excludePropertyId: excludePropertyId,
  );
}

// ===============================
// FILE UPLOAD UTILITY PROVIDERS
// ===============================

@riverpod
class PropertyFileUpload extends _$PropertyFileUpload {
  PropertyRepository get _repository => ref.read(propertyRepositoryProvider);

  @override
  FutureOr<Map<String, dynamic>> build() async {
    return <String, dynamic>{};
  }

  Future<String> uploadVideo(File videoFile, String propertyId) async {
    try {
      return await _repository.uploadPropertyVideo(videoFile, propertyId);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> uploadImages(List<File> imageFiles, String propertyId) async {
    try {
      return await _repository.uploadPropertyImages(imageFiles, propertyId);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> uploadThumbnail(File thumbnailFile, String propertyId) async {
    try {
      return await _repository.uploadPropertyThumbnail(thumbnailFile, propertyId);
    } catch (e) {
      rethrow;
    }
  }
}

// ===============================
// UTILITY FUNCTIONS
// ===============================

// Helper function to generate unique property ID
String generatePropertyId() {
  return 'prop_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000).toString().padLeft(3, '0')}';
}

// Helper function to validate property data
List<String> validateProperty(PropertyListingModel property) {
  return property.validate();
}

// Helper function to check if user can edit property
bool canEditProperty(PropertyListingModel property, UserModel? currentUser) {
  if (currentUser == null || !currentUser.isHost) return false;
  if (property.hostId != currentUser.uid) return false;
  return property.canBeEdited;
}

// Helper function to format property price range
String formatPriceRange(double? minRate, double? maxRate) {
  if (minRate == null && maxRate == null) return 'Any price';
  if (minRate == null) return 'Up to KES ${maxRate!.toStringAsFixed(0)}';
  if (maxRate == null) return 'From KES ${minRate.toStringAsFixed(0)}';
  if (minRate == maxRate) return 'KES ${minRate.toStringAsFixed(0)}';
  return 'KES ${minRate.toStringAsFixed(0)} - ${maxRate.toStringAsFixed(0)}';
}
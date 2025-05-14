// lib/features/marketplace/providers/marketplace_provider.dart - Fixed with Index Issue Handling
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/marketplace/models/marketplace_video_model.dart';
import 'package:uuid/uuid.dart';

// Define the marketplace state
class MarketplaceState {
  final bool isLoading;
  final List<MarketplaceVideoModel> videos;
  final List<String> likedVideos;
  final String? error;
  final List<String> categories;
  final String? selectedCategory;
  final bool isUploading;
  final double uploadProgress;

  const MarketplaceState({
    this.isLoading = false,
    this.videos = const [],
    this.likedVideos = const [],
    this.error,
    this.categories = const [],
    this.selectedCategory,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });

  MarketplaceState copyWith({
    bool? isLoading,
    List<MarketplaceVideoModel>? videos,
    List<String>? likedVideos,
    String? error,
    List<String>? categories,
    String? selectedCategory,
    bool? isUploading,
    double? uploadProgress,
  }) {
    return MarketplaceState(
      isLoading: isLoading ?? this.isLoading,
      videos: videos ?? this.videos,
      likedVideos: likedVideos ?? this.likedVideos,
      error: error,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

// Create the marketplace provider
class MarketplaceNotifier extends StateNotifier<MarketplaceState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  MarketplaceNotifier() : super(const MarketplaceState()) {
    // Initialize with empty state and load data
    loadVideos();
    loadCategories();
    loadLikedVideos();
  }

  // Debug method to help diagnose issues
  Future<void> debugMarketplaceData() async {
    debugPrint('======= DEBUGGING MARKETPLACE DATA =======');
    
    try {
      // 1. Check collection name
      debugPrint('Using collection name: ${Constants.marketplaceVideos}');
      
      // 2. Try to get all documents without any filters
      final allDocsSnap = await _firestore.collection(Constants.marketplaceVideos).get();
      debugPrint('Total documents in collection: ${allDocsSnap.docs.length}');
      
      // Log document details
      int activeCount = 0;
      for (var doc in allDocsSnap.docs) {
        final data = doc.data();
        debugPrint('Document ID: ${doc.id}');
        debugPrint('  isActive: ${data['isActive']} (${data['isActive'].runtimeType})');
        debugPrint('  productName: ${data['productName']}');
        if (data['isActive'] == true) activeCount++;
      }
      debugPrint('Documents with isActive=true: $activeCount');
      
      // 3. Check current state
      debugPrint('Current state - videos count: ${state.videos.length}');
      
      debugPrint('======= END DEBUGGING MARKETPLACE DATA =======');
    } catch (e) {
      debugPrint('Error during debugging: $e');
    }
  }

  // Load videos from Firestore with index error handling
  Future<void> loadVideos({String? category, bool forceRefresh = false}) async {
    debugPrint('loadVideos called - category: $category, forceRefresh: $forceRefresh');
    
    // If not forcing refresh and we already have videos, just return
    if (!forceRefresh && state.videos.isNotEmpty && category == state.selectedCategory) {
      debugPrint('Using cached videos (${state.videos.length} videos)');
      return;
    }
    
    // Set loading state
    state = state.copyWith(isLoading: true, error: null);
    debugPrint('Loading marketplace videos from Firestore...');

    try {
      List<MarketplaceVideoModel> videos = [];
      
      try {
        // First try the query with indexes (may fail if index doesn't exist yet)
        Query query = _firestore
            .collection(Constants.marketplaceVideos)
            .where('isActive', isEqualTo: true);
        
        // Add category filter if provided
        if (category != null && category.isNotEmpty) {
          query = query.where('category', isEqualTo: category);
        }
        
        // Order by creation date
        query = query.orderBy('createdAt', descending: true);
        
        // Execute query
        final QuerySnapshot querySnapshot = await query.get();
        debugPrint('Found ${querySnapshot.docs.length} marketplace videos');
        
        // Process results
        for (var doc in querySnapshot.docs) {
          final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
          
          // Explicitly set the ID in the data
          data['id'] = doc.id;
          
          // Check if user has liked this video
          final isLiked = state.likedVideos.contains(doc.id);
          
          // Add to list
          videos.add(MarketplaceVideoModel.fromMap(data, isLiked: isLiked));
          debugPrint('Added video: ${doc.id}, product: ${data['productName']}');
        }
      } catch (indexError) {
        // If we get an index error, use a fallback approach
        debugPrint('Index error occurred: $indexError');
        debugPrint('Using fallback query without complex ordering...');
        
        // Fallback: Get all documents with simpler query (no compound index needed)
        final QuerySnapshot fallbackSnapshot = await _firestore
            .collection(Constants.marketplaceVideos)
            .get();
        
        // Process and filter manually
        for (var doc in fallbackSnapshot.docs) {
          final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
          
          // Skip inactive videos
          if (data['isActive'] != true) continue;
          
          // Skip if category filter doesn't match
          if (category != null && category.isNotEmpty && data['category'] != category) {
            continue;
          }
          
          // Set document ID and check likes
          data['id'] = doc.id;
          final isLiked = state.likedVideos.contains(doc.id);
          
          // Add to list
          videos.add(MarketplaceVideoModel.fromMap(data, isLiked: isLiked));
          debugPrint('Added video (fallback): ${doc.id}, product: ${data['productName']}');
        }
        
        // Sort manually by creation date (newest first)
        videos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        // Pass the error to state for UI display
        state = state.copyWith(error: indexError.toString());
      }
      
      // Update state with videos and selected category
      state = state.copyWith(
        videos: videos,
        isLoading: false,
        selectedCategory: category,
      );
      
      debugPrint('Updated state with ${videos.length} videos');
    } catch (e) {
      debugPrint('Error loading videos: ${e.toString()}');
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  // Load user's liked videos
  Future<void> loadLikedVideos() async {
    if (_auth.currentUser == null) return;
    
    try {
      final uid = _auth.currentUser!.uid;
      final userDoc = await _firestore.collection(Constants.users).doc(uid).get();
      
      if (userDoc.exists && userDoc.data()!.containsKey('likedMarketplaceVideos')) {
        final likedVideos = List<String>.from(userDoc.data()!['likedMarketplaceVideos'] ?? []);
        state = state.copyWith(likedVideos: likedVideos);
        
        // Update isLiked status for existing videos
        final updatedVideos = state.videos.map((video) {
          return video.copyWith(isLiked: likedVideos.contains(video.id));
        }).toList();
        
        state = state.copyWith(videos: updatedVideos);
      }
    } catch (e) {
      debugPrint('Error loading liked videos: ${e.toString()}');
      state = state.copyWith(error: e.toString());
    }
  }

  // Like or unlike a video
  Future<void> likeVideo(String videoId) async {
    if (_auth.currentUser == null) return;
    
    try {
      final uid = _auth.currentUser!.uid;
      final videoDoc = _firestore.collection(Constants.marketplaceVideos).doc(videoId);
      
      // Get current liked videos
      List<String> likedVideos = List.from(state.likedVideos);
      bool isCurrentlyLiked = likedVideos.contains(videoId);
      
      // Update local state first (optimistic update)
      if (isCurrentlyLiked) {
        likedVideos.remove(videoId);
      } else {
        likedVideos.add(videoId);
      }
      
      // Update videos list with new like status
      final updatedVideos = state.videos.map((video) {
        if (video.id == videoId) {
          return video.copyWith(
            isLiked: !isCurrentlyLiked,
            likes: isCurrentlyLiked ? video.likes - 1 : video.likes + 1,
          );
        }
        return video;
      }).toList();
      
      state = state.copyWith(
        videos: updatedVideos,
        likedVideos: likedVideos,
      );
      
      // Update Firestore
      // 1. Update user's liked videos
      await _firestore.collection(Constants.users).doc(uid).update({
        'likedMarketplaceVideos': isCurrentlyLiked
            ? FieldValue.arrayRemove([videoId])
            : FieldValue.arrayUnion([videoId]),
      });
      
      // 2. Update video's like count
      await videoDoc.update({
        'likes': isCurrentlyLiked
            ? FieldValue.increment(-1)
            : FieldValue.increment(1),
      });
      
    } catch (e) {
      debugPrint('Error toggling like: ${e.toString()}');
      state = state.copyWith(error: e.toString());
      
      // Revert the optimistic update on error
      loadVideos(category: state.selectedCategory);
      loadLikedVideos();
    }
  }

  // Load available categories
  Future<void> loadCategories() async {
    try {
      final categoriesDoc = await _firestore.collection(Constants.marketplaceCategories).doc('categories').get();
      
      if (categoriesDoc.exists) {
        final List<String> categories = List<String>.from(categoriesDoc.data()?['list'] ?? []);
        state = state.copyWith(categories: categories);
      } else {
        // Create default categories if document doesn't exist
        final List<String> defaultCategories = [
          'Electronics',
          'Fashion',
          'Home',
          'Beauty',
          'Services',
          'Food',
          'Education',
          'Other',
        ];
        
        await _firestore.collection(Constants.marketplaceCategories).doc('categories').set({
          'list': defaultCategories,
        });
        
        state = state.copyWith(categories: defaultCategories);
      }
    } catch (e) {
      debugPrint('Error loading categories: ${e.toString()}');
      state = state.copyWith(error: e.toString());
    }
  }

  // Upload a new video to the marketplace
  Future<void> uploadVideo({
    required File videoFile,
    required String productName,
    required String price,
    required String description,
    required String category,
    String? businessName,
    List<String>? tags,
    String? location,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    if (_auth.currentUser == null) {
      onError('User not authenticated');
      return;
    }
    
    try {
      final uid = _auth.currentUser!.uid;
      final videoId = const Uuid().v4();
      
      debugPrint('Starting video upload with ID: $videoId');
      
      // Start uploading state
      state = state.copyWith(
        isUploading: true,
        uploadProgress: 0.0,
      );
      
      // Get user info
      final userDoc = await _firestore.collection(Constants.users).doc(uid).get();
      final userData = userDoc.data();
      
      if (userData == null) {
        throw Exception('User data not found');
      }
      
      final userName = userData[Constants.name] ?? '';
      final userImage = userData[Constants.image] ?? '';
      
      // 1. Upload video to Firebase Storage
      final storageRef = _storage.ref().child('marketplaceVideos/$videoId.mp4');
      final uploadTask = storageRef.putFile(
        videoFile,
        SettableMetadata(contentType: 'video/mp4'),
      );
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        state = state.copyWith(uploadProgress: progress);
        debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(0)}%');
      });
      
      // Wait for upload to complete
      final taskSnapshot = await uploadTask;
      final videoUrl = await taskSnapshot.ref.getDownloadURL();
      debugPrint('Video uploaded successfully, URL: $videoUrl');
      
      // 2. Create marketplace video model
      final MarketplaceVideoModel videoData = MarketplaceVideoModel(
        id: videoId,  // Important: set ID explicitly
        userId: uid,
        userName: userName,
        userImage: userImage,
        businessName: businessName ?? '',
        videoUrl: videoUrl,
        thumbnailUrl: '',  // Would be generated from video
        productName: productName,
        price: price,
        description: description,
        category: category,
        likes: 0,
        comments: 0,
        views: 0,
        isLiked: false,
        tags: tags ?? [],
        location: location ?? '',
        createdAt: Timestamp.now(),
        isActive: true,
        isFeatured: false,
      );
      
      // 3. Save to Firestore - use .set with merge:true to ensure all fields are saved
      await _firestore
          .collection(Constants.marketplaceVideos)
          .doc(videoId)
          .set(videoData.toMap(), SetOptions(merge: true));
      
      debugPrint('Video document saved to Firestore with ID: $videoId');
      
      // 4. Update user's posted videos
      await _firestore.collection(Constants.users).doc(uid).update({
        'postedMarketplaceVideos': FieldValue.arrayUnion([videoId]),
      });
      
      // 5. CRITICAL: Update local state directly with the new video
      // This is what VideoProvider does
      List<MarketplaceVideoModel> updatedVideos = [
        videoData,  // Add new video at the beginning
        ...state.videos,  // Keep existing videos
      ];
      
      // Reset uploading state and update videos
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        videos: updatedVideos,  // Set the updated videos list
      );
      
      debugPrint('Local state updated with new video, now has ${updatedVideos.length} videos');
      
      onSuccess('Video uploaded successfully');
    } catch (e) {
      debugPrint('Error uploading video: ${e.toString()}');
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        error: e.toString(),
      );
      
      onError(e.toString());
    }
  }

  // Filter videos by category
  void filterByCategory(String? category) {
    debugPrint('Filtering by category: $category');
    loadVideos(category: category, forceRefresh: true);
  }

  // Increment view count for a video
  Future<void> incrementViewCount(String videoId) async {
    try {
      await _firestore.collection(Constants.marketplaceVideos).doc(videoId).update({
        'views': FieldValue.increment(1),
      });
      
      // Update local state
      final updatedVideos = state.videos.map((video) {
        if (video.id == videoId) {
          return video.copyWith(views: video.views + 1);
        }
        return video;
      }).toList();
      
      state = state.copyWith(videos: updatedVideos);
    } catch (e) {
      debugPrint('Error incrementing view count: ${e.toString()}');
      state = state.copyWith(error: e.toString());
    }
  }

  // Get user's posted videos
  Future<List<MarketplaceVideoModel>> getUserVideos(String userId) async {
    try {
      // Use simpler query to avoid index issues
      final QuerySnapshot querySnapshot = await _firestore
          .collection(Constants.marketplaceVideos)
          .get();
      
      List<MarketplaceVideoModel> userVideos = [];
      
      for (var doc in querySnapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        
        // Filter manually
        if (data['userId'] != userId || data['isActive'] != true) continue;
        
        // Always add the document ID to the data
        data['id'] = doc.id;
        
        final isLiked = state.likedVideos.contains(doc.id);
        userVideos.add(MarketplaceVideoModel.fromMap(data, isLiked: isLiked));
      }
      
      // Sort manually by createdAt
      userVideos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return userVideos;
    } catch (e) {
      debugPrint('Error getting user videos: ${e.toString()}');
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  // Delete a video
  Future<void> deleteVideo(String videoId, Function(String) onError) async {
    if (_auth.currentUser == null) {
      onError('User not authenticated');
      return;
    }
    
    try {
      final uid = _auth.currentUser!.uid;
      
      // Get the video document
      final videoDoc = await _firestore.collection(Constants.marketplaceVideos).doc(videoId).get();
      final videoData = videoDoc.data();
      
      // Check if the current user is the owner
      if (videoData != null && videoData['userId'] == uid) {
        // Mark as inactive instead of deleting to prevent broken references
        await _firestore.collection(Constants.marketplaceVideos).doc(videoId).update({
          'isActive': false,
        });
        
        // Remove from user's posted videos
        await _firestore.collection(Constants.users).doc(uid).update({
          'postedMarketplaceVideos': FieldValue.arrayRemove([videoId]),
        });
        
        // Update local state
        final updatedVideos = state.videos.where((video) => video.id != videoId).toList();
        state = state.copyWith(videos: updatedVideos);
      } else {
        onError('You can only delete your own videos');
      }
    } catch (e) {
      debugPrint('Error deleting video: ${e.toString()}');
      state = state.copyWith(error: e.toString());
      onError(e.toString());
    }
  }
}

// Provider definition
final marketplaceProvider = StateNotifierProvider<MarketplaceNotifier, MarketplaceState>((ref) {
  return MarketplaceNotifier();
});
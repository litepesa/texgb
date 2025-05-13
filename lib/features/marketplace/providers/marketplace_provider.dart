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
    // Initialize state on creation
    loadVideos();
    loadCategories();
    loadLikedVideos();
  }

  // Load videos from Firestore
  Future<void> loadVideos({String? category}) async {
    state = state.copyWith(isLoading: true);

    try {
      Query query = _firestore
          .collection(Constants.marketplaceVideos)
          .where('isActive', isEqualTo: true);
      
      // Filter by category if provided
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
        state = state.copyWith(selectedCategory: category);
      } else {
        state = state.copyWith(selectedCategory: null);
      }
      
      // Order by creation date (newest first)
      query = query.orderBy('createdAt', descending: true);
      
      final QuerySnapshot querySnapshot = await query.get();
      
      List<MarketplaceVideoModel> videos = [];
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Add ID to data if not present
        if (!data.containsKey('id')) {
          data['id'] = doc.id;
        }
        
        final isLiked = state.likedVideos.contains(doc.id);
        videos.add(MarketplaceVideoModel.fromMap(data, isLiked: isLiked));
      }
      
      state = state.copyWith(
        videos: videos,
        isLoading: false,
      );
    } catch (e) {
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
      
      // Create upload task
      final uploadTask = storageRef.putFile(
        videoFile,
        SettableMetadata(contentType: 'video/mp4'),
      );
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        state = state.copyWith(uploadProgress: progress);
      });
      
      // Wait for upload to complete
      final taskSnapshot = await uploadTask;
      final videoUrl = await taskSnapshot.ref.getDownloadURL();
      
      // 2. Generate thumbnail (in a real app, you might want to generate this server-side)
      String thumbnailUrl = ''; // Would be generated from video
      
      // 3. Create the marketplace video document
      final videoData = MarketplaceVideoModel(
        id: videoId,
        userId: uid,
        userName: userName,
        userImage: userImage,
        businessName: businessName ?? '',
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
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
      
      // 4. Save to Firestore
      await _firestore
          .collection(Constants.marketplaceVideos)
          .doc(videoId)
          .set(videoData.toMap());
      
      // 5. Update user's posted videos
      await _firestore.collection(Constants.users).doc(uid).update({
        'postedMarketplaceVideos': FieldValue.arrayUnion([videoId]),
      });
      
      // Reset uploading state
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
      );
      
      // Reload videos to include the new one
      await loadVideos(category: state.selectedCategory);
      
      onSuccess('Video uploaded successfully');
    } catch (e) {
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
    loadVideos(category: category);
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
      state = state.copyWith(error: e.toString());
    }
  }

  // Get user's posted videos
  Future<List<MarketplaceVideoModel>> getUserVideos(String userId) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(Constants.marketplaceVideos)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      
      List<MarketplaceVideoModel> userVideos = [];
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Add ID to data if not present
        if (!data.containsKey('id')) {
          data['id'] = doc.id;
        }
        
        final isLiked = state.likedVideos.contains(doc.id);
        userVideos.add(MarketplaceVideoModel.fromMap(data, isLiked: isLiked));
      }
      
      return userVideos;
    } catch (e) {
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
      state = state.copyWith(error: e.toString());
      onError(e.toString());
    }
  }
}

// Provider definition
final marketplaceProvider = StateNotifierProvider<MarketplaceNotifier, MarketplaceState>((ref) {
  return MarketplaceNotifier();
});
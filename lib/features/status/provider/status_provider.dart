import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/status_model.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:uuid/uuid.dart';

class StatusProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isUploading = false;
  final List<StatusModel> _statusFeed = [];
  final List<StatusModel> _myStatuses = [];
  bool _initialFeedLoaded = false;

  // Default number of posts to load in feed
  final int _defaultPostLimit = 30;
  
  // Getters
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  List<StatusModel> get statusFeed => _statusFeed;
  List<StatusModel> get myStatuses => _myStatuses;
  bool get initialFeedLoaded => _initialFeedLoaded;
  
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Set loading state
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  // Set uploading state
  void setUploading(bool value) {
    _isUploading = value;
    notifyListeners();
  }
  
  // Clear status lists
  void clearStatuses() {
    _statusFeed.clear();
    _myStatuses.clear();
    _initialFeedLoaded = false;
    notifyListeners();
  }

  // Upload a single image/video status
  Future<void> uploadMediaStatus({
    required UserModel currentUser,
    required File file,
    required StatusType statusType,
    String caption = '',
    String? location,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    setUploading(true);
    
    try {
      // Generate a unique status ID
      final statusId = const Uuid().v4();
      
      // Upload media to Firebase Storage
      final mediaType = statusType == StatusType.image ? 'images' : 'videos';
      final path = 'status/$mediaType/${currentUser.uid}/$statusId';
      final statusUrl = await storeFileToStorage(file: file, reference: path);
      
      // Create a status model
      final statusModel = StatusModel(
        statusId: statusId,
        uid: currentUser.uid,
        userName: currentUser.name,
        userImage: currentUser.image,
        statusUrl: statusUrl,
        caption: caption,
        statusType: statusType,
        createdAt: DateTime.now(),
        likedBy: [],
        viewedBy: [currentUser.uid], // Creator has seen their own status
        comments: [],
        location: location,
      );
      
      // Save status to Firestore
      await _firestore
          .collection('status')
          .doc(statusId)
          .set(statusModel.toMap());
      
      // Add to local lists
      _myStatuses.add(statusModel);
      _statusFeed.insert(0, statusModel); // Add to the top of the feed
      
      setUploading(false);
      onSuccess();
      notifyListeners();
      
    } catch (e) {
      setUploading(false);
      onError(e.toString());
    }
  }
  
  // Upload a multi-image status
  Future<void> uploadMultiImageStatus({
    required UserModel currentUser,
    required List<File> files,
    String caption = '',
    String? location,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    setUploading(true);
    
    try {
      // Generate a unique status ID
      final statusId = const Uuid().v4();
      final List<String> mediaUrls = [];
      
      // Upload each image to Firebase Storage
      for (int i = 0; i < files.length; i++) {
        final File file = files[i];
        final path = 'status/images/${currentUser.uid}/${statusId}_$i';
        final mediaUrl = await storeFileToStorage(file: file, reference: path);
        mediaUrls.add(mediaUrl);
      }
      
      // Create a status model
      final statusModel = StatusModel(
        statusId: statusId,
        uid: currentUser.uid,
        userName: currentUser.name,
        userImage: currentUser.image,
        statusUrl: mediaUrls.first, // Main image is the first one
        mediaUrls: mediaUrls,
        caption: caption,
        statusType: StatusType.multiImage,
        createdAt: DateTime.now(),
        likedBy: [],
        viewedBy: [currentUser.uid], // Creator has seen their own status
        comments: [],
        location: location,
      );
      
      // Save status to Firestore
      await _firestore
          .collection('status')
          .doc(statusId)
          .set(statusModel.toMap());
      
      // Add to local lists
      _myStatuses.add(statusModel);
      _statusFeed.insert(0, statusModel); // Add to the top of the feed
      
      setUploading(false);
      onSuccess();
      notifyListeners();
      
    } catch (e) {
      setUploading(false);
      onError(e.toString());
    }
  }
  
  // Create a text status
  Future<void> createTextStatus({
    required UserModel currentUser,
    required String text,
    required String backgroundColor,
    required String textColor,
    required String fontStyle,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    setUploading(true);
    
    try {
      // Generate a unique status ID
      final statusId = const Uuid().v4();
      
      // Create a status model
      final statusModel = StatusModel(
        statusId: statusId,
        uid: currentUser.uid,
        userName: currentUser.name,
        userImage: currentUser.image,
        statusUrl: text, // For text status, URL contains the text
        caption: '',
        statusType: StatusType.text,
        createdAt: DateTime.now(),
        likedBy: [],
        viewedBy: [currentUser.uid], // Creator has seen their own status
        comments: [],
        backgroundColor: backgroundColor,
        textColor: textColor,
        fontStyle: fontStyle,
      );
      
      // Save status to Firestore
      await _firestore
          .collection('status')
          .doc(statusId)
          .set(statusModel.toMap());
      
      // Add to local lists
      _myStatuses.add(statusModel);
      _statusFeed.insert(0, statusModel); // Add to the top of the feed
      
      setUploading(false);
      onSuccess();
      notifyListeners();
      
    } catch (e) {
      setUploading(false);
      onError(e.toString());
    }
  }
  
  // Delete a status
  Future<void> deleteStatus({
    required String statusId,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    setLoading(true);
    
    try {
      // Find the status
      final statusIndex = _statusFeed.indexWhere((s) => s.statusId == statusId);
      if (statusIndex == -1) {
        throw 'Status not found';
      }
      
      final status = _statusFeed[statusIndex];
      
      // Delete media files from storage if not a text status
      if (status.statusType != StatusType.text) {
        try {
          // Delete main media
          final ref = _storage.refFromURL(status.statusUrl);
          await ref.delete();
          
          // Delete additional media if it's a multi-image status
          if (status.statusType == StatusType.multiImage && status.mediaUrls != null) {
            for (final url in status.mediaUrls!) {
              if (url != status.statusUrl) { // Skip main URL we already deleted
                final mediaRef = _storage.refFromURL(url);
                await mediaRef.delete();
              }
            }
          }
        } catch (e) {
          // Continue even if media deletion fails
          print('Error deleting media: $e');
        }
      }
      
      // Delete status from Firestore
      await _firestore.collection('status').doc(statusId).delete();
      
      // Remove from local lists
      _statusFeed.removeAt(statusIndex);
      _myStatuses.removeWhere((s) => s.statusId == statusId);
      
      setLoading(false);
      onSuccess();
      notifyListeners();
      
    } catch (e) {
      setLoading(false);
      onError(e.toString());
    }
  }
  
  // Add a comment to a status
  Future<void> addComment({
    required String statusId,
    required UserModel currentUser,
    required String commentText,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    setLoading(true);
    
    try {
      final String commentId = const Uuid().v4();
      
      final comment = CommentModel(
        commentId: commentId,
        uid: currentUser.uid,
        userName: currentUser.name,
        userImage: currentUser.image,
        text: commentText,
        createdAt: DateTime.now(),
      );
      
      // Get the status from Firestore
      final DocumentSnapshot doc = await _firestore.collection('status').doc(statusId).get();
      if (!doc.exists) {
        throw 'Status not found';
      }
      
      final statusData = doc.data() as Map<String, dynamic>;
      final status = StatusModel.fromMap(statusData);
      
      // Add comment to status
      final List<CommentModel> updatedComments = List.from(status.comments)..add(comment);
      
      // Update Firestore
      await _firestore.collection('status').doc(statusId).update({
        'comments': updatedComments.map((c) => c.toMap()).toList(),
      });
      
      // Update local lists
      _updateStatusWithNewComment(statusId, comment);
      
      setLoading(false);
      onSuccess();
      notifyListeners();
      
    } catch (e) {
      setLoading(false);
      onError(e.toString());
    }
  }
  
  // Like/unlike a status
  Future<void> toggleLike({
    required String statusId,
    required String userId,
    required String statusOwnerUid,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    try {
      // Get the status from Firestore
      final DocumentSnapshot doc = await _firestore.collection('status').doc(statusId).get();
      if (!doc.exists) {
        throw 'Status not found';
      }
      
      final statusData = doc.data() as Map<String, dynamic>;
      final status = StatusModel.fromMap(statusData);
      
      final List<String> updatedLikedBy = List.from(status.likedBy);
      
      // Toggle like
      if (updatedLikedBy.contains(userId)) {
        updatedLikedBy.remove(userId);
      } else {
        updatedLikedBy.add(userId);
      }
      
      // Update Firestore
      await _firestore.collection('status').doc(statusId).update({
        'likedBy': updatedLikedBy,
      });
      
      // Update local lists
      _updateStatusLikes(statusId, updatedLikedBy);
      
      onSuccess();
      notifyListeners();
      
    } catch (e) {
      onError(e.toString());
    }
  }
  
  // Mark a status as viewed
  Future<void> markStatusAsViewed({
    required String statusId,
    required String userId,
    required String statusOwnerUid,
  }) async {
    try {
      // Get the status from Firestore
      final DocumentSnapshot doc = await _firestore.collection('status').doc(statusId).get();
      if (!doc.exists) {
        return;
      }
      
      final statusData = doc.data() as Map<String, dynamic>;
      final status = StatusModel.fromMap(statusData);
      
      // Check if already viewed
      if (status.viewedBy.contains(userId)) {
        return;
      }
      
      final List<String> updatedViewedBy = List.from(status.viewedBy)..add(userId);
      
      // Update Firestore
      await _firestore.collection('status').doc(statusId).update({
        'viewedBy': updatedViewedBy,
      });
      
      // Update local lists
      _updateStatusViews(statusId, updatedViewedBy);
      
      notifyListeners();
      
    } catch (e) {
      print('Error marking status as viewed: $e');
    }
  }

  // Fetch status feed
  Future<void> fetchStatusFeed({
    required String currentUserId,
    required List<String> contactIds,
  }) async {
    setLoading(true);
    
    try {
      final List<StatusModel> feed = [];
      final List<StatusModel> userStatuses = [];
      
      // Fetch recent statuses from all users (public feed)
      final publicFeedQuery = await _firestore
          .collection('status')
          .orderBy('createdAt', descending: true)
          .limit(_defaultPostLimit)
          .get();
      
      for (final doc in publicFeedQuery.docs) {
        final status = StatusModel.fromMap(doc.data());
        
        // Add to the appropriate lists
        feed.add(status);
        
        // If this is the current user's status, add to personal list
        if (status.uid == currentUserId) {
          userStatuses.add(status);
        }
      }
      
      // Update local lists
      _statusFeed.clear();
      _statusFeed.addAll(feed);
      
      _myStatuses.clear();
      _myStatuses.addAll(userStatuses);
      
      _initialFeedLoaded = true;
      
      setLoading(false);
      notifyListeners();
      
    } catch (e) {
      setLoading(false);
      print('Error fetching status feed: $e');
    }
  }

  // Fetch more status posts for "infinite scrolling"
  Future<void> fetchMoreStatusPosts({
    required String currentUserId,
    required List<String> contactIds,
  }) async {
    if (_statusFeed.isEmpty) {
      return fetchStatusFeed(
        currentUserId: currentUserId,
        contactIds: contactIds,
      );
    }
    
    try {
      // Get timestamp of the oldest post in our feed
      final oldestTimestamp = _statusFeed.last.createdAt;
      
      // Fetch older posts
      final olderPostsQuery = await _firestore
          .collection('status')
          .orderBy('createdAt', descending: true)
          .where('createdAt', isLessThan: oldestTimestamp)
          .limit(15) // Fetch 15 more
          .get();
      
      final List<StatusModel> olderPosts = [];
      
      for (final doc in olderPostsQuery.docs) {
        final status = StatusModel.fromMap(doc.data());
        olderPosts.add(status);
      }
      
      // Add to the feed
      _statusFeed.addAll(olderPosts);
      
      notifyListeners();
      
    } catch (e) {
      print('Error fetching more status posts: $e');
    }
  }

  // Fetch statuses by a specific user
  Future<List<StatusModel>> fetchUserStatuses(String userId) async {
    try {
      final userStatusesQuery = await _firestore
          .collection('status')
          .where('uid', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      final List<StatusModel> userStatuses = [];
      
      for (final doc in userStatusesQuery.docs) {
        final status = StatusModel.fromMap(doc.data());
        userStatuses.add(status);
      }
      
      return userStatuses;
      
    } catch (e) {
      print('Error fetching user statuses: $e');
      return [];
    }
  }

  // Helper method to update a status with a new comment in local lists
  void _updateStatusWithNewComment(String statusId, CommentModel comment) {
    // Update in status feed
    for (int i = 0; i < _statusFeed.length; i++) {
      if (_statusFeed[i].statusId == statusId) {
        final updatedComments = List<CommentModel>.from(_statusFeed[i].comments)..add(comment);
        _statusFeed[i] = _statusFeed[i].copyWith(comments: updatedComments);
        break;
      }
    }
    
    // Update in my statuses
    for (int i = 0; i < _myStatuses.length; i++) {
      if (_myStatuses[i].statusId == statusId) {
        final updatedComments = List<CommentModel>.from(_myStatuses[i].comments)..add(comment);
        _myStatuses[i] = _myStatuses[i].copyWith(comments: updatedComments);
        break;
      }
    }
  }

  // Helper method to update status likes in local lists
  void _updateStatusLikes(String statusId, List<String> likedBy) {
    // Update in status feed
    for (int i = 0; i < _statusFeed.length; i++) {
      if (_statusFeed[i].statusId == statusId) {
        _statusFeed[i] = _statusFeed[i].copyWith(likedBy: likedBy);
        break;
      }
    }
    
    // Update in my statuses
    for (int i = 0; i < _myStatuses.length; i++) {
      if (_myStatuses[i].statusId == statusId) {
        _myStatuses[i] = _myStatuses[i].copyWith(likedBy: likedBy);
        break;
      }
    }
  }

  // Helper method to update status views in local lists
  void _updateStatusViews(String statusId, List<String> viewedBy) {
    // Update in status feed
    for (int i = 0; i < _statusFeed.length; i++) {
      if (_statusFeed[i].statusId == statusId) {
        _statusFeed[i] = _statusFeed[i].copyWith(viewedBy: viewedBy);
        break;
      }
    }
    
    // Update in my statuses
    for (int i = 0; i < _myStatuses.length; i++) {
      if (_myStatuses[i].statusId == statusId) {
        _myStatuses[i] = _myStatuses[i].copyWith(viewedBy: viewedBy);
        break;
      }
    }
  }
}
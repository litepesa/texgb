// lib/features/status/status_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/status_post_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

// Define FeedFilterType as a top-level enum outside the class
enum FeedFilterType { contacts, latest, trending }

class StatusProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();
  
  // Track if the app is in a fresh start
  bool _isAppFreshStart = true;
  bool get isAppFreshStart => _isAppFreshStart;
  
  // Track if the status tab is visible
  bool _isStatusTabVisible = false;
  bool get isStatusTabVisible => _isStatusTabVisible;
  
  // Track feed filter type
  FeedFilterType _currentFilter = FeedFilterType.latest;
  FeedFilterType get currentFilter => _currentFilter;
  
  // States for status feed
  List<StatusPostModel> _allStatusPosts = [];
  List<StatusPostModel> _filteredStatusPosts = [];
  bool _isLoading = false;
  String _searchQuery = '';
  
  // Getters
  List<StatusPostModel> get allStatusPosts => _allStatusPosts;
  List<StatusPostModel> get filteredStatusPosts => _filteredStatusPosts;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  
  // Set app fresh start state
  void setAppFreshStart(bool value) {
    _isAppFreshStart = value;
    notifyListeners();
  }
  
  // Set status tab visibility
  void setStatusTabVisible(bool value) {
    _isStatusTabVisible = value;
    notifyListeners();
  }
  
  // Set feed filter
  void setFeedFilter(FeedFilterType filterType) {
    _currentFilter = filterType;
    _applyFilters();
    notifyListeners();
  }
  
  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }
  
  // Apply filters and search to status posts
  void _applyFilters() {
    if (_allStatusPosts.isEmpty) return;
    
    var filtered = List<StatusPostModel>.from(_allStatusPosts);
    
    // Apply search if there's a query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((post) => 
        post.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        post.caption.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Apply filter type
    switch (_currentFilter) {
      case FeedFilterType.contacts:
        // Will be implemented when user's contacts are available
        break;
      case FeedFilterType.latest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case FeedFilterType.trending:
        filtered.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
    }
    
    _filteredStatusPosts = filtered;
  }
  
  // Fetch statuses from Firestore
  Future<void> fetchStatuses({
    required String currentUserId,
    required List<String> contactIds,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Get current time to filter out expired statuses
      final now = DateTime.now();
      
      // Query all statuses that haven't expired yet
      final snapshot = await _firestore
          .collection(Constants.statuses)
          .where('expiresAt', isGreaterThan: now.toIso8601String())
          .get();
      
      // Convert snapshots to StatusPostModel objects
      final List<StatusPostModel> posts = [];
      for (var doc in snapshot.docs) {
        final statusPost = StatusPostModel.fromMap(doc.data());
        
        // Filter based on privacy settings
        if (statusPost.uid == currentUserId) {
          // Current user can see their own posts
          posts.add(statusPost);
        } else if (!statusPost.isPrivate) {
          // Public post that everyone can see
          posts.add(statusPost);
        } else if (statusPost.isContactsOnly && contactIds.contains(statusPost.uid)) {
          // Contacts-only post and current user is a contact
          posts.add(statusPost);
        } else if (statusPost.allowedContactUIDs.contains(currentUserId)) {
          // Specific contacts post and current user is in the allowed list
          posts.add(statusPost);
        }
      }
      
      _allStatusPosts = posts;
      _applyFilters();
    } catch (e) {
      debugPrint('Error fetching statuses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Create a new status post
  Future<void> createStatusPost({
    required String uid,
    required String username,
    required String userImage,
    required List<File> mediaFiles,
    required String caption,
    required StatusType type,
    required bool isPrivate,
    required bool isContactsOnly,
    required List<String> allowedContactUIDs,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Generate unique status ID
      final statusId = _uuid.v4();
      
      // Upload media files to storage
      final List<String> mediaUrls = [];
      for (var file in mediaFiles) {
        final fileType = type == StatusType.video ? 'video' : 'image';
        final reference = 'statusFiles/$uid/$statusId/${mediaUrls.length}_$fileType';
        
        final url = await storeFileToStorage(
          file: file,
          reference: reference,
        );
        
        mediaUrls.add(url);
      }
      
      // Calculate expiry time (72 hours from now)
      final createdAt = DateTime.now();
      final expiresAt = createdAt.add(const Duration(hours: 72));
      
      // Create status post model
      final statusPost = StatusPostModel(
        statusId: statusId,
        uid: uid,
        username: username,
        userImage: userImage,
        mediaUrls: mediaUrls,
        caption: caption,
        type: type,
        createdAt: createdAt,
        expiresAt: expiresAt,
        viewerUIDs: [],
        viewCount: 0,
        likeUIDs: [],
        isPrivate: isPrivate,
        allowedContactUIDs: allowedContactUIDs,
        isContactsOnly: isContactsOnly,
      );
      
      // Save to Firestore
      await _firestore
          .collection(Constants.statuses)
          .doc(statusId)
          .set(statusPost.toMap());
      
      // Refresh status feed
      _allStatusPosts.add(statusPost);
      _applyFilters();
    } catch (e) {
      debugPrint('Error creating status post: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // View a status post
  Future<void> viewStatusPost({
    required String statusId,
    required String viewerUid,
  }) async {
    try {
      // Find the status post in local list
      final postIndex = _allStatusPosts.indexWhere((post) => post.statusId == statusId);
      if (postIndex == -1) return;
      
      final post = _allStatusPosts[postIndex];
      
      // Check if user has already viewed this post
      if (post.viewerUIDs.contains(viewerUid)) return;
      
      // Add viewer to the list
      final updatedViewerUIDs = List<String>.from(post.viewerUIDs)..add(viewerUid);
      final updatedViewCount = post.viewCount + 1;
      
      // Update Firestore
      await _firestore.collection(Constants.statuses).doc(statusId).update({
        'viewerUIDs': updatedViewerUIDs,
        Constants.statusViewCount: updatedViewCount,
      });
      
      // Update local state
      final updatedPost = post.copyWith(
        viewerUIDs: updatedViewerUIDs,
        viewCount: updatedViewCount,
      );
      
      _allStatusPosts[postIndex] = updatedPost;
      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Error viewing status post: $e');
    }
  }
  
  // Like/unlike a status post
  Future<void> toggleLikeStatusPost({
    required String statusId,
    required String userUid,
  }) async {
    try {
      // Find the status post in local list
      final postIndex = _allStatusPosts.indexWhere((post) => post.statusId == statusId);
      if (postIndex == -1) return;
      
      final post = _allStatusPosts[postIndex];
      
      // Toggle like status
      final isCurrentlyLiked = post.likeUIDs.contains(userUid);
      final List<String> updatedLikeUIDs = List<String>.from(post.likeUIDs);
      
      if (isCurrentlyLiked) {
        updatedLikeUIDs.remove(userUid);
      } else {
        updatedLikeUIDs.add(userUid);
      }
      
      // Update Firestore
      await _firestore.collection(Constants.statuses).doc(statusId).update({
        'likeUIDs': updatedLikeUIDs,
      });
      
      // Update local state
      final updatedPost = post.copyWith(
        likeUIDs: updatedLikeUIDs,
      );
      
      _allStatusPosts[postIndex] = updatedPost;
      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling like on status post: $e');
    }
  }
  
  // Add a comment to a status post
  Future<void> addComment({
    required String statusId,
    required String uid,
    required String username,
    required String userImage,
    required String text,
    String? parentCommentId,
  }) async {
    try {
      // Generate unique comment ID
      final commentId = _uuid.v4();
      
      // Create comment model
      final comment = StatusCommentModel(
        commentId: commentId,
        statusId: statusId,
        uid: uid,
        username: username,
        userImage: userImage,
        text: text,
        createdAt: DateTime.now(),
        parentCommentId: parentCommentId,
        likeUIDs: [],
      );
      
      // Save to Firestore
      await _firestore
          .collection(Constants.statusReplies)
          .doc(commentId)
          .set(comment.toMap());
      
      // No need to update local state as comments will be fetched separately
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }
  
  // Fetch comments for a status post
  Future<List<StatusCommentModel>> fetchComments({
    required String statusId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(Constants.statusReplies)
          .where(Constants.statusId, isEqualTo: statusId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => StatusCommentModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      return [];
    }
  }
  
  // Delete a status post (only for the creator)
  Future<void> deleteStatusPost({
    required String statusId,
    required String creatorUid,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Find the status post in local list
      final postIndex = _allStatusPosts.indexWhere((post) => post.statusId == statusId);
      if (postIndex == -1) return;
      
      final post = _allStatusPosts[postIndex];
      
      // Verify the user is the creator
      if (post.uid != creatorUid) {
        throw Exception('Only the creator can delete this post');
      }
      
      // Delete media files from storage
      for (var url in post.mediaUrls) {
        final ref = _storage.refFromURL(url);
        await ref.delete();
      }
      
      // Delete all comments
      final commentsSnapshot = await _firestore
          .collection(Constants.statusReplies)
          .where(Constants.statusId, isEqualTo: statusId)
          .get();
      
      for (var doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Delete status document
      await _firestore.collection(Constants.statuses).doc(statusId).delete();
      
      // Update local state
      _allStatusPosts.removeAt(postIndex);
      _applyFilters();
    } catch (e) {
      debugPrint('Error deleting status post: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<StatusPostModel>> fetchUserStatusPosts(String uid) async {
    try {
      // Query for all posts by this user (including expired ones)
      final snapshot = await _firestore
          .collection(Constants.statuses)
          .where(Constants.uid, isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => StatusPostModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching user status posts: $e');
      return [];
    }
  }
  
  // Check if user has posted today
  Future<bool> hasUserPostedToday(String uid) async {
    try {
      // Get the start of the current day
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      // Query for posts by this user created today
      final snapshot = await _firestore
          .collection(Constants.statuses)
          .where(Constants.uid, isEqualTo: uid)
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if user posted today: $e');
      return false;
    }
  }
}
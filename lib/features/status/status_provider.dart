// lib/features/status/status_provider.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/models/status_post_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:uuid/uuid.dart';

// Enum for feed filtering
enum FeedFilterType {
  latest,     // Most recent posts first
  trending,   // Posts with most engagement
  friends,    // Only posts from specific friends
}

class StatusProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  List<StatusPost> _allStatusPosts = [];
  List<StatusComment> _currentComments = [];
  StatusPost? _currentViewingPost;
  FeedFilterType _currentFilter = FeedFilterType.latest;
  bool _isLoading = false;
  bool _isStatusTabVisible = false; // Track if status tab is visible
  
  bool get isLoading => _isLoading;
  List<StatusPost> get allStatusPosts => _allStatusPosts;
  List<StatusComment> get currentComments => _currentComments;
  StatusPost? get currentViewingPost => _currentViewingPost;
  FeedFilterType get currentFilter => _currentFilter;
  bool get isStatusTabVisible => _isStatusTabVisible;
  
  // Set status tab visibility for video autoplay control
  void setStatusTabVisible(bool isVisible) {
    _isStatusTabVisible = isVisible;
    notifyListeners();
  }
  
  // Set feed filter type
  void setFeedFilter(FeedFilterType filter) {
    _currentFilter = filter;
    notifyListeners();
  }
  
  // Fetch all status posts from Firestore
  Future<void> fetchAllStatuses({
    required String currentUserId,
    required List<String> contactIds,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Get all status posts that should be visible to current user
      QuerySnapshot querySnapshot = await _firestore
          .collection(Constants.statusPosts)
          .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch)
          .orderBy('timestamp', descending: true)
          .get();
      
      List<StatusPost> posts = [];
      
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        StatusPost post = StatusPost.fromMap(data);
        
        // Privacy check
        bool shouldShow = false;
        
        // Posts by the current user are always visible
        if (post.userId == currentUserId) {
          shouldShow = true;
        } 
        // Check privacy settings for other users' posts
        else if (contactIds.contains(post.userId)) {
          switch (post.privacyType) {
            case StatusPrivacyType.all_contacts:
              shouldShow = true;
              break;
            case StatusPrivacyType.except:
              shouldShow = !post.hiddenFrom.contains(currentUserId);
              break;
            case StatusPrivacyType.only:
              shouldShow = post.visibleTo.contains(currentUserId);
              break;
          }
        }
        
        if (shouldShow) {
          posts.add(post);
        }
      }
      
      // Apply the current filter
      _filterPosts(posts);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      debugPrint('Error fetching status posts: $e');
      notifyListeners();
    }
  }
  
  // Filter posts based on current filter type
  void _filterPosts(List<StatusPost> posts) {
    switch (_currentFilter) {
      case FeedFilterType.latest:
        _allStatusPosts = posts;
        break;
      case FeedFilterType.trending:
        // Sort by engagement (likes + comments)
        posts.sort((a, b) {
          int aEngagement = a.likes.length + a.commentCount;
          int bEngagement = b.likes.length + b.commentCount;
          return bEngagement.compareTo(aEngagement);
        });
        _allStatusPosts = posts;
        break;
      case FeedFilterType.friends:
        // This would require additional logic to determine "close friends"
        // For now, just show all posts
        _allStatusPosts = posts;
        break;
    }
  }
  
  // Create new status post
  Future<bool> createStatusPost({
    required String userId,
    required String userName,
    required String userImage,
    required String content,
    required StatusType type,
    required StatusPrivacyType privacyType,
    List<String>? visibleTo,
    List<String>? hiddenFrom,
    Map<String, dynamic>? location,
    List<File>? mediaFiles,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final String postId = const Uuid().v4();
      List<String> mediaUrls = [];
      
      // Upload media files if any
      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        for (var i = 0; i < mediaFiles.length; i++) {
          File file = mediaFiles[i];
          String fileName = '$postId-$i';
          String reference = '${Constants.statusFiles}/$userId/$fileName';
          
          String url = await storeFileToStorage(
            file: file,
            reference: reference,
          );
          
          mediaUrls.add(url);
        }
      }
      
      // Create status post model
      StatusPost post = StatusPost(
        id: postId,
        userId: userId,
        userName: userName,
        userImage: userImage,
        content: content,
        mediaUrls: mediaUrls,
        type: type,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        likes: [],
        commentCount: 0,
        privacyType: privacyType,
        visibleTo: visibleTo ?? [],
        hiddenFrom: hiddenFrom ?? [],
        location: location,
      );
      
      // Save to Firestore
      await _firestore
          .collection(Constants.statusPosts)
          .doc(postId)
          .set(post.toMap());
      
      // Add to local list
      _allStatusPosts.insert(0, post);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      debugPrint('Error creating status post: $e');
      notifyListeners();
      return false;
    }
  }
  
  // Like/unlike a status post
  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    try {
      // Find post in local list
      int index = _allStatusPosts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        StatusPost post = _allStatusPosts[index];
        List<String> likes = List.from(post.likes);
        
        if (likes.contains(userId)) {
          likes.remove(userId);
        } else {
          likes.add(userId);
        }
        
        // Update local state
        _allStatusPosts[index] = post.copyWith(likes: likes);
        
        // If viewing this post, update the current viewing post
        if (_currentViewingPost?.id == postId) {
          _currentViewingPost = _currentViewingPost!.copyWith(likes: likes);
        }
        
        // Update in Firestore
        await _firestore.collection(Constants.statusPosts).doc(postId).update({
          'likes': likes,
        });
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }
  
  // Get post details
  Future<void> getPostDetails(String postId) async {
    _isLoading = true;
    _currentComments = [];
    notifyListeners();
    
    try {
      // Get post
      DocumentSnapshot postDoc = await _firestore
          .collection(Constants.statusPosts)
          .doc(postId)
          .get();
      
      if (postDoc.exists) {
        _currentViewingPost = StatusPost.fromMap(postDoc.data() as Map<String, dynamic>);
        
        // Get comments
        QuerySnapshot commentsSnapshot = await _firestore
            .collection(Constants.statusComments)
            .where('postId', isEqualTo: postId)
            .orderBy('timestamp', descending: true)
            .get();
        
        _currentComments = commentsSnapshot.docs
            .map((doc) => StatusComment.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      debugPrint('Error getting post details: $e');
      notifyListeners();
    }
  }
  
  // Add comment to a post
  Future<bool> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String userImage,
    required String content,
  }) async {
    try {
      final String commentId = const Uuid().v4();
      
      StatusComment comment = StatusComment(
        id: commentId,
        postId: postId,
        userId: userId,
        userName: userName,
        userImage: userImage,
        content: content,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        likes: [],
      );
      
      // Save to Firestore
      await _firestore
          .collection(Constants.statusComments)
          .doc(commentId)
          .set(comment.toMap());
      
      // Update comment count on post
      await _firestore.collection(Constants.statusPosts).doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });
      
      // Update local state
      _currentComments.insert(0, comment);
      
      // Update post comment count
      int postIndex = _allStatusPosts.indexWhere((post) => post.id == postId);
      if (postIndex != -1) {
        StatusPost post = _allStatusPosts[postIndex];
        _allStatusPosts[postIndex] = post.copyWith(
          commentCount: post.commentCount + 1,
        );
      }
      
      if (_currentViewingPost?.id == postId) {
        _currentViewingPost = _currentViewingPost!.copyWith(
          commentCount: _currentViewingPost!.commentCount + 1,
        );
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      return false;
    }
  }
  
  // Delete a status post
  Future<bool> deletePost(String postId) async {
    try {
      // Delete post from Firestore
      await _firestore.collection(Constants.statusPosts).doc(postId).delete();
      
      // Delete all comments related to this post
      QuerySnapshot commentsSnapshot = await _firestore
          .collection(Constants.statusComments)
          .where('postId', isEqualTo: postId)
          .get();
      
      for (var doc in commentsSnapshot.docs) {
        await _firestore.collection(Constants.statusComments).doc(doc.id).delete();
      }
      
      // Remove from local list
      _allStatusPosts.removeWhere((post) => post.id == postId);
      if (_currentViewingPost?.id == postId) {
        _currentViewingPost = null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting post: $e');
      return false;
    }
  }
  
  // Get user's posts
  Future<List<StatusPost>> getUserPosts(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(Constants.statusPosts)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => StatusPost.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting user posts: $e');
      return [];
    }
  }
}
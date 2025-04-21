import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:textgb/models/moment_model.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:uuid/uuid.dart';

class MomentsProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isUploading = false;
  final List<MomentModel> _userMoments = [];
  final List<MomentModel> _contactsMoments = [];
  final List<MomentModel> _forYouMoments = []; // For TikTok-style recommendations
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Default number of videos to load in For You feed
  final int _defaultVideoLimit = 30;
  
  // Flag to track if initial discovery feed has been loaded
  bool _initialDiscoveryLoaded = false;
  
  // Feed mode for TikTok-style feed
  FeedMode _currentFeedMode = FeedMode.forYou;

  // Getters
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  List<MomentModel> get userMoments => _userMoments;
  List<MomentModel> get contactsMoments => _contactsMoments;
  List<MomentModel> get forYouMoments => _forYouMoments;
  FeedMode get currentFeedMode => _currentFeedMode;
  bool get initialDiscoveryLoaded => _initialDiscoveryLoaded;
  
  // Get combined feed based on current mode
  List<MomentModel> get currentFeed {
    switch (_currentFeedMode) {
      case FeedMode.following:
        // Sort newer content first
        return [..._contactsMoments]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case FeedMode.forYou:
      default:
        // Enhanced algorithm: prioritize recent and popular content
        final allContent = [
          ..._userMoments,
          ..._contactsMoments,
          ..._forYouMoments,
        ];
        
        // Sort based on an engagement score: recency + popularity
        allContent.sort((a, b) {
          // Calculate engagement score (likes + comments + views)
          final scoreA = a.likedBy.length + a.comments.length + a.viewedBy.length;
          final scoreB = b.likedBy.length + b.comments.length + b.viewedBy.length;
          
          // Factor in recency (within past 48 hours gets a boost)
          final now = DateTime.now();
          final isRecentA = now.difference(a.createdAt).inHours < 48;
          final isRecentB = now.difference(b.createdAt).inHours < 48;
          
          final adjustedScoreA = isRecentA ? scoreA * 1.5 : scoreA;
          final adjustedScoreB = isRecentB ? scoreB * 1.5 : scoreB;
          
          // If scores are very close, use recency as tiebreaker
          if ((adjustedScoreA - adjustedScoreB).abs() < 5) {
            return b.createdAt.compareTo(a.createdAt);
          }
          
          return adjustedScoreB.compareTo(adjustedScoreA);
        });
        
        return allContent;
    }
  }
  
  // Toggle between Following and For You modes
  void toggleFeedMode() {
    _currentFeedMode = _currentFeedMode == FeedMode.forYou
        ? FeedMode.following
        : FeedMode.forYou;
    notifyListeners();
  }
  
  // Set feed mode
  void setFeedMode(FeedMode mode) {
    _currentFeedMode = mode;
    notifyListeners();
  }

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

  // Clear moments lists
  void clearMoments() {
    _userMoments.clear();
    _contactsMoments.clear();
    _forYouMoments.clear();
    _initialDiscoveryLoaded = false;
    notifyListeners();
  }

  // Update moments list
  void updateMomentsList(List<MomentModel> userMoments, List<MomentModel> contactsMoments) {
    _userMoments.clear();
    _userMoments.addAll(userMoments);
    
    _contactsMoments.clear();
    _contactsMoments.addAll(contactsMoments);
    
    notifyListeners();
  }

  // Upload a moment with multiple media files
  Future<void> uploadMoment({
    required UserModel currentUser,
    required String text,
    required List<File> mediaFiles,
    required bool isVideo,
    String location = '',
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    setUploading(true);
    
    try {
      final String momentId = const Uuid().v4();
      final List<String> mediaUrls = [];
      
      // Upload each media file
      for (int i = 0; i < mediaFiles.length; i++) {
        final File file = mediaFiles[i];
        final String mediaType = isVideo ? 'videos' : 'images';
        final String path = 'moments/$mediaType/${currentUser.uid}/${momentId}_$i';
        
        final String mediaUrl = await storeFileToStorage(file: file, reference: path);
        mediaUrls.add(mediaUrl);
      }
      
      // Create moment model
      final momentModel = MomentModel(
        momentId: momentId,
        uid: currentUser.uid,
        userName: currentUser.name,
        userImage: currentUser.image,
        text: text,
        mediaUrls: mediaUrls,
        isVideo: isVideo,
        createdAt: DateTime.now(),
        likedBy: [],
        viewedBy: [currentUser.uid], // Creator has seen their own moment
        comments: [],
        location: location,
      );
      
      // Save moment to Firestore
      await _firestore
          .collection('moments')
          .doc(momentId)
          .set(momentModel.toMap());
      
      // Add to local list
      _userMoments.add(momentModel);
      _userMoments.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Ensure chronological order
      
      setUploading(false);
      onSuccess();
      notifyListeners();
      
    } catch (e) {
      setUploading(false);
      onError(e.toString());
    }
  }

  // Delete a moment
  Future<void> deleteMoment({
    required String momentId,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    setLoading(true);
    
    try {
      // Get the moment
      final moment = _userMoments.firstWhere((m) => m.momentId == momentId);
      
      // Delete media files from storage
      for (final url in moment.mediaUrls) {
        try {
          final ref = _storage.refFromURL(url);
          await ref.delete();
        } catch (e) {
          // Continue even if some files fail to delete
          print('Error deleting media: $e');
        }
      }
      
      // Delete moment from Firestore
      await _firestore.collection('moments').doc(momentId).delete();
      
      // Remove from local list
      _userMoments.removeWhere((m) => m.momentId == momentId);
      
      setLoading(false);
      onSuccess();
      notifyListeners();
      
    } catch (e) {
      setLoading(false);
      onError(e.toString());
    }
  }

  // Add a comment to a moment
  Future<void> addComment({
    required String momentId,
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
      
      // Get the moment from Firestore
      final DocumentSnapshot doc = await _firestore.collection('moments').doc(momentId).get();
      if (!doc.exists) {
        throw 'Moment not found';
      }
      
      final momentData = doc.data() as Map<String, dynamic>;
      final moment = MomentModel.fromMap(momentData);
      
      // Add comment to moment
      final List<CommentModel> updatedComments = List.from(moment.comments)..add(comment);
      
      // Update Firestore
      await _firestore.collection('moments').doc(momentId).update({
        'comments': updatedComments.map((c) => c.toMap()).toList(),
      });
      
      // Update local lists
      _updateMomentWithNewComment(momentId, comment);
      
      setLoading(false);
      onSuccess();
      notifyListeners();
      
    } catch (e) {
      setLoading(false);
      onError(e.toString());
    }
  }

  // Like/unlike a moment
  Future<void> toggleLike({
    required String momentId,
    required String userId,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    try {
      // Get the moment from Firestore
      final DocumentSnapshot doc = await _firestore.collection('moments').doc(momentId).get();
      if (!doc.exists) {
        throw 'Moment not found';
      }
      
      final momentData = doc.data() as Map<String, dynamic>;
      final moment = MomentModel.fromMap(momentData);
      
      final List<String> updatedLikedBy = List.from(moment.likedBy);
      
      // Toggle like
      if (updatedLikedBy.contains(userId)) {
        updatedLikedBy.remove(userId);
      } else {
        updatedLikedBy.add(userId);
      }
      
      // Update Firestore
      await _firestore.collection('moments').doc(momentId).update({
        'likedBy': updatedLikedBy,
      });
      
      // Update local lists
      _updateMomentLikes(momentId, updatedLikedBy);
      
      onSuccess();
      notifyListeners();
      
    } catch (e) {
      onError(e.toString());
    }
  }

  // Mark a moment as viewed
  Future<void> markMomentAsViewed({
    required String momentId,
    required String userId,
  }) async {
    try {
      // Get the moment from Firestore
      final DocumentSnapshot doc = await _firestore.collection('moments').doc(momentId).get();
      if (!doc.exists) {
        return;
      }
      
      final momentData = doc.data() as Map<String, dynamic>;
      final moment = MomentModel.fromMap(momentData);
      
      // Check if already viewed
      if (moment.viewedBy.contains(userId)) {
        return;
      }
      
      final List<String> updatedViewedBy = List.from(moment.viewedBy)..add(userId);
      
      // Update Firestore
      await _firestore.collection('moments').doc(momentId).update({
        'viewedBy': updatedViewedBy,
      });
      
      // Update local lists
      _updateMomentViews(momentId, updatedViewedBy);
      
      notifyListeners();
      
    } catch (e) {
      print('Error marking moment as viewed: $e');
    }
  }

  // Fetch moments for current user and contacts
  Future<void> fetchMoments({
    required String currentUserId,
    required List<String> contactIds,
  }) async {
    setLoading(true);
    
    try {
      final List<MomentModel> userMoments = [];
      final List<MomentModel> contactsMoments = [];
      
      // Fetch user's moments
      final userMomentsQuery = await _firestore
          .collection('moments')
          .where('uid', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();
      
      for (final doc in userMomentsQuery.docs) {
        final moment = MomentModel.fromMap(doc.data());
        userMoments.add(moment);
      }
      
      // Fetch contacts' moments
      if (contactIds.isNotEmpty) {
        // Handle case where there are too many contacts by doing multiple queries if needed
        for (var i = 0; i < contactIds.length; i += 10) {
          final end = (i + 10 < contactIds.length) ? i + 10 : contactIds.length;
          final batchIds = contactIds.sublist(i, end);
          
          final contactsMomentsQuery = await _firestore
              .collection('moments')
              .where('uid', whereIn: batchIds)
              .orderBy('createdAt', descending: true)
              .get();
          
          for (final doc in contactsMomentsQuery.docs) {
            final moment = MomentModel.fromMap(doc.data());
            contactsMoments.add(moment);
          }
        }
      }
      
      // Update local lists
      _userMoments.clear();
      _userMoments.addAll(userMoments);
      
      _contactsMoments.clear();
      _contactsMoments.addAll(contactsMoments);
      
      // Always fetch discovery feed for all users
      await _loadDiscoveryFeed(currentUserId, contactIds);
      
      setLoading(false);
      notifyListeners();
      
    } catch (e) {
      setLoading(false);
      print('Error fetching moments: $e');
    }
  }
  
  // Load discovery feed - guaranteed content for all users
  Future<void> _loadDiscoveryFeed(String currentUserId, List<String> contactIds) async {
    try {
      if (_forYouMoments.isNotEmpty && _initialDiscoveryLoaded) {
        // Already loaded, just refresh in background
        _refreshDiscoveryFeedInBackground(currentUserId, contactIds);
        return;
      }
      
      final List<MomentModel> discoveryMoments = [];
      
      // First, get the most popular videos (most likes and comments)
      final popularQuery = await _firestore
          .collection('moments')
          .where('isVideo', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(_defaultVideoLimit)
          .get();
      
      final List<MomentModel> tempMoments = [];
      for (final doc in popularQuery.docs) {
        final moment = MomentModel.fromMap(doc.data());
        // Skip if this is from the current user (already in user's list)
        if (moment.uid != currentUserId) {
          tempMoments.add(moment);
        }
      }
      
      // Sort by engagement (likes + comments)
      tempMoments.sort((a, b) {
        final engagementA = a.likedBy.length + a.comments.length;
        final engagementB = b.likedBy.length + b.comments.length;
        return engagementB.compareTo(engagementA);
      });
      
      // Take top 15 most engaging videos
      if (tempMoments.length > 15) {
        discoveryMoments.addAll(tempMoments.sublist(0, 15));
      } else {
        discoveryMoments.addAll(tempMoments);
      }
      
      // Then get some recent videos to ensure fresh content
      final recentQuery = await _firestore
          .collection('moments')
          .where('isVideo', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(15)
          .get();
      
      for (final doc in recentQuery.docs) {
        final moment = MomentModel.fromMap(doc.data());
        // Skip if already added or from current user
        if (moment.uid != currentUserId && 
            !discoveryMoments.any((m) => m.momentId == moment.momentId)) {
          discoveryMoments.add(moment);
        }
      }
      
      // Make sure we have at least 10 videos for any user
      if (discoveryMoments.isEmpty) {
        // As a fallback, get any videos
        final fallbackQuery = await _firestore
            .collection('moments')
            .where('isVideo', isEqualTo: true)
            .limit(10)
            .get();
        
        for (final doc in fallbackQuery.docs) {
          discoveryMoments.add(MomentModel.fromMap(doc.data()));
        }
      }
      
      // Update local list
      _forYouMoments.clear();
      _forYouMoments.addAll(discoveryMoments);
      _initialDiscoveryLoaded = true;
      
    } catch (e) {
      print('Error loading discovery feed: $e');
      // Even on error, mark as initialized to avoid repeated failures
      _initialDiscoveryLoaded = true;
    }
  }
  
  // Refresh discovery feed in background without blocking UI
  Future<void> _refreshDiscoveryFeedInBackground(String currentUserId, List<String> contactIds) async {
    try {
      final List<MomentModel> newDiscoveryItems = [];
      
      // Get newer videos since our last refresh
      DateTime newestTimestamp = DateTime.now().subtract(const Duration(days: 7));
      if (_forYouMoments.isNotEmpty) {
        // Find the newest video timestamp we already have
        final newest = _forYouMoments.reduce((a, b) => 
          a.createdAt.isAfter(b.createdAt) ? a : b);
        newestTimestamp = newest.createdAt;
      }
      
      // Query for newer videos
      final newVideosQuery = await _firestore
          .collection('moments')
          .where('isVideo', isEqualTo: true)
          .where('createdAt', isGreaterThan: newestTimestamp)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      
      for (final doc in newVideosQuery.docs) {
        final moment = MomentModel.fromMap(doc.data());
        // Skip if this is from the current user (already in user's list)
        if (moment.uid != currentUserId && 
            !_forYouMoments.any((m) => m.momentId == moment.momentId)) {
          newDiscoveryItems.add(moment);
        }
      }
      
      // If we found new items, add them and notify
      if (newDiscoveryItems.isNotEmpty) {
        _forYouMoments.insertAll(0, newDiscoveryItems);
        notifyListeners();
      }
      
    } catch (e) {
      print('Error refreshing discovery feed: $e');
    }
  }
  
  // Fetch videos-only feed for TikTok-style experience with improved algorithm
  Future<void> fetchVideoFeed({
    required String currentUserId,
    required List<String> contactIds,
    int limit = 30,
  }) async {
    setLoading(true);
    
    try {
      final List<MomentModel> videoFeed = [];
      
      // 1. First, get the most recent videos
      final recentVideosQuery = await _firestore
          .collection('moments')
          .where('isVideo', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit ~/ 2) // Get half the limit from recent videos
          .get();
      
      for (final doc in recentVideosQuery.docs) {
        final moment = MomentModel.fromMap(doc.data());
        videoFeed.add(moment);
      }
      
      // 2. Then, get some popular videos based on engagement
      // We can't easily query directly by popularity, so we'll fetch more and sort client-side
      final popularVideosQuery = await _firestore
          .collection('moments')
          .where('isVideo', isEqualTo: true)
          .orderBy('createdAt', descending: true) // Get somewhat recent ones first
          .limit(limit) // Get more than we need for filtering
          .get();
      
      final List<MomentModel> popularCandidates = [];
      for (final doc in popularVideosQuery.docs) {
        final moment = MomentModel.fromMap(doc.data());
        // Skip if already in the feed
        if (!videoFeed.any((m) => m.momentId == moment.momentId)) {
          popularCandidates.add(moment);
        }
      }
      
      // Sort by engagement score
      popularCandidates.sort((a, b) {
        final scoreA = a.likedBy.length + a.comments.length + (a.viewedBy.length ~/ 2);
        final scoreB = b.likedBy.length + b.comments.length + (b.viewedBy.length ~/ 2);
        return scoreB.compareTo(scoreA);
      });
      
      // Add top popular videos to complete our feed
      final remainingSlots = limit - videoFeed.length;
      if (popularCandidates.length > remainingSlots) {
        videoFeed.addAll(popularCandidates.sublist(0, remainingSlots));
      } else {
        videoFeed.addAll(popularCandidates);
      }
      
      // 3. Shuffle slightly to avoid predictable ordering while maintaining quality
      final firstFew = videoFeed.take(3).toList(); // Keep the very best at the top
      final rest = videoFeed.skip(3).toList()..shuffle();
      
      final shuffledFeed = [...firstFew, ...rest];
      
      // Update local list
      _forYouMoments.clear();
      _forYouMoments.addAll(shuffledFeed);
      _initialDiscoveryLoaded = true;
      
      setLoading(false);
      notifyListeners();
      
    } catch (e) {
      setLoading(false);
      print('Error fetching video feed: $e');
    }
  }

  // Helper method to update a moment with a new comment in local lists
  void _updateMomentWithNewComment(String momentId, CommentModel comment) {
    // Update in user moments
    for (int i = 0; i < _userMoments.length; i++) {
      if (_userMoments[i].momentId == momentId) {
        final updatedComments = List<CommentModel>.from(_userMoments[i].comments)..add(comment);
        _userMoments[i] = _userMoments[i].copyWith(comments: updatedComments);
        break;
      }
    }
    
    // Update in contacts moments
    for (int i = 0; i < _contactsMoments.length; i++) {
      if (_contactsMoments[i].momentId == momentId) {
        final updatedComments = List<CommentModel>.from(_contactsMoments[i].comments)..add(comment);
        _contactsMoments[i] = _contactsMoments[i].copyWith(comments: updatedComments);
        break;
      }
    }
    
    // Update in for you moments
    for (int i = 0; i < _forYouMoments.length; i++) {
      if (_forYouMoments[i].momentId == momentId) {
        final updatedComments = List<CommentModel>.from(_forYouMoments[i].comments)..add(comment);
        _forYouMoments[i] = _forYouMoments[i].copyWith(comments: updatedComments);
        break;
      }
    }
  }

  // Helper method to update moment likes in local lists
  void _updateMomentLikes(String momentId, List<String> likedBy) {
    // Update in user moments
    for (int i = 0; i < _userMoments.length; i++) {
      if (_userMoments[i].momentId == momentId) {
        _userMoments[i] = _userMoments[i].copyWith(likedBy: likedBy);
        break;
      }
    }
    
    // Update in contacts moments
    for (int i = 0; i < _contactsMoments.length; i++) {
      if (_contactsMoments[i].momentId == momentId) {
        _contactsMoments[i] = _contactsMoments[i].copyWith(likedBy: likedBy);
        break;
      }
    }
    
    // Update in for you moments
    for (int i = 0; i < _forYouMoments.length; i++) {
      if (_forYouMoments[i].momentId == momentId) {
        _forYouMoments[i] = _forYouMoments[i].copyWith(likedBy: likedBy);
        break;
      }
    }
  }

  // Helper method to update moment views in local lists
  void _updateMomentViews(String momentId, List<String> viewedBy) {
    // Update in user moments
    for (int i = 0; i < _userMoments.length; i++) {
      if (_userMoments[i].momentId == momentId) {
        _userMoments[i] = _userMoments[i].copyWith(viewedBy: viewedBy);
        break;
      }
    }
    
    // Update in contacts moments
    for (int i = 0; i < _contactsMoments.length; i++) {
      if (_contactsMoments[i].momentId == momentId) {
        _contactsMoments[i] = _contactsMoments[i].copyWith(viewedBy: viewedBy);
        break;
      }
    }
    
    // Update in for you moments
    for (int i = 0; i < _forYouMoments.length; i++) {
      if (_forYouMoments[i].momentId == momentId) {
        _forYouMoments[i] = _forYouMoments[i].copyWith(viewedBy: viewedBy);
        break;
      }
    }
  }
}

// Enum for TikTok-style feed modes
enum FeedMode {
  following,  // Content from users you follow
  forYou,     // Recommended content (TikTok's default)
}
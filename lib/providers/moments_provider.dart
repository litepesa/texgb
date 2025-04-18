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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Getters
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  List<MomentModel> get userMoments => _userMoments;
  List<MomentModel> get contactsMoments => _contactsMoments;

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
        final contactsMomentsQuery = await _firestore
            .collection('moments')
            .where('uid', whereIn: contactIds)
            .orderBy('createdAt', descending: true)
            .get();
        
        for (final doc in contactsMomentsQuery.docs) {
          final moment = MomentModel.fromMap(doc.data());
          contactsMoments.add(moment);
        }
      }
      
      // Update local lists
      updateMomentsList(userMoments, contactsMoments);
      
      setLoading(false);
      
    } catch (e) {
      setLoading(false);
      print('Error fetching moments: $e');
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
  }

  // Get moment stream
  Stream<QuerySnapshot> getMomentsStream(List<String> contactIds) {
    // Include current user's ID in the query
    final List<String> allIds = [...contactIds];
    
    // Handle empty contacts case or when contactIds length exceeds Firestore limit
    if (allIds.isEmpty) {
      return _firestore
          .collection('moments')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots();
    }
    
    // Firestore has a limit on 'whereIn' clauses (usually 10)
    // For larger lists, we'd need to split into multiple queries and merge results
    if (allIds.length <= 10) {
      return _firestore
          .collection('moments')
          .where('uid', whereIn: allIds)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots();
    } else {
      // For simplicity in this implementation, we'll just limit to the first 10
      // In a real app, you'd implement pagination or batching
      return _firestore
          .collection('moments')
          .where('uid', whereIn: allIds.sublist(0, 10))
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots();
    }
  }
}
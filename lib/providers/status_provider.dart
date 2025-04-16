import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/models/status_model.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:uuid/uuid.dart';

class StatusProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isUploading = false;
  final List<StatusModel> _myStatuses = [];
  final Map<String, List<StatusModel>> _contactStatuses = {};
  
  // Getters
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  List<StatusModel> get myStatuses => _myStatuses;
  Map<String, List<StatusModel>> get contactStatuses => _contactStatuses;
  
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
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
  
  // Update the status lists
  void updateStatusLists({
    required List<StatusModel> myStatus,
    required Map<String, List<StatusModel>> contactStatus,
  }) {
    _myStatuses.clear();
    _myStatuses.addAll(myStatus);
    
    _contactStatuses.clear();
    _contactStatuses.addAll(contactStatus);
    
    notifyListeners();
  }
  
  // Create and upload a new image/video status
  Future<void> uploadMediaStatus({
    required UserModel currentUser,
    required File file,
    required StatusType statusType,
    String caption = '',
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
        uid: currentUser.uid,
        userName: currentUser.name,
        userImage: currentUser.image,
        statusId: statusId,
        statusUrl: statusUrl,
        caption: caption,
        statusType: statusType,
        createdAt: DateTime.now(),
        viewedBy: [currentUser.uid], // Creator has seen their own status
      );
      
      // Save status to Firestore
      await _firestore
          .collection('status')
          .doc(currentUser.uid)
          .collection('userStatus')
          .doc(statusId)
          .set(statusModel.toMap());
      
      // Update status timestamp in user document
      await _firestore.collection(Constants.users).doc(currentUser.uid).update({
        'lastStatusUpdate': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Add to local list
      _myStatuses.add(statusModel);
      
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
        uid: currentUser.uid,
        userName: currentUser.name,
        userImage: currentUser.image,
        statusId: statusId,
        statusUrl: text, // For text status, the content is stored directly
        caption: '',
        statusType: StatusType.text,
        createdAt: DateTime.now(),
        viewedBy: [currentUser.uid], // Creator has seen their own status
        backgroundColor: backgroundColor,
        textColor: textColor,
        fontStyle: fontStyle,
      );
      
      // Save status to Firestore
      await _firestore
          .collection('status')
          .doc(currentUser.uid)
          .collection('userStatus')
          .doc(statusId)
          .set(statusModel.toMap());
      
      // Update status timestamp in user document
      await _firestore.collection(Constants.users).doc(currentUser.uid).update({
        'lastStatusUpdate': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Add to local list
      _myStatuses.add(statusModel);
      
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
      // Get the current user's UID
      final currentUID = _myStatuses.first.uid;
      
      // Delete status from Firestore
      await _firestore
          .collection('status')
          .doc(currentUID)
          .collection('userStatus')
          .doc(statusId)
          .delete();
      
      // Remove from local list
      _myStatuses.removeWhere((status) => status.statusId == statusId);
      
      setLoading(false);
      onSuccess();
      notifyListeners();
      
    } catch (e) {
      setLoading(false);
      onError(e.toString());
    }
  }
  
  // Mark a status as viewed
  Future<void> markStatusAsViewed({
    required String statusOwnerUid,
    required String statusId,
    required String viewerUid,
  }) async {
    try {
      // Update the viewedBy array in Firestore
      await _firestore
          .collection('status')
          .doc(statusOwnerUid)
          .collection('userStatus')
          .doc(statusId)
          .update({
        'viewedBy': FieldValue.arrayUnion([viewerUid]),
      });
      
      // Update local data
      if (_contactStatuses.containsKey(statusOwnerUid)) {
        final index = _contactStatuses[statusOwnerUid]!
            .indexWhere((status) => status.statusId == statusId);
        
        if (index != -1) {
          _contactStatuses[statusOwnerUid]![index].viewedBy.add(viewerUid);
          notifyListeners();
        }
      }
      
    } catch (e) {
      debugPrint('Error marking status as viewed: $e');
    }
  }
  
  // Get all statuses for the current user and their friends
  Future<void> fetchAllStatuses({
    required String currentUserUid,
    required List<String> friendUids,
  }) async {
    setLoading(true);
    
    try {
      final List<StatusModel> myStatus = [];
      final Map<String, List<StatusModel>> friendsStatus = {};
      
      // Fetch current user's statuses
      final myStatusDocs = await _firestore
          .collection('status')
          .doc(currentUserUid)
          .collection('userStatus')
          .orderBy('createdAt', descending: true)
          .get();
      
      // Filter out expired statuses (older than 24 hours)
      final now = DateTime.now();
      for (var doc in myStatusDocs.docs) {
        final status = StatusModel.fromMap(doc.data());
        final difference = now.difference(status.createdAt);
        
        if (difference.inHours < 24) {
          myStatus.add(status);
        } else {
          // Delete expired status
          await doc.reference.delete();
        }
      }
      
      // Fetch friends' statuses
      for (var friendUid in friendUids) {
        final friendStatusDocs = await _firestore
            .collection('status')
            .doc(friendUid)
            .collection('userStatus')
            .orderBy('createdAt', descending: true)
            .get();
        
        final List<StatusModel> validStatuses = [];
        
        for (var doc in friendStatusDocs.docs) {
          final status = StatusModel.fromMap(doc.data());
          final difference = now.difference(status.createdAt);
          
          if (difference.inHours < 24) {
            validStatuses.add(status);
          } else {
            // Delete expired status
            await doc.reference.delete();
          }
        }
        
        // Only add friend to map if they have valid statuses
        if (validStatuses.isNotEmpty) {
          friendsStatus[friendUid] = validStatuses;
        }
      }
      
      // Update local lists
      updateStatusLists(
        myStatus: myStatus,
        contactStatus: friendsStatus,
      );
      
      setLoading(false);
      
    } catch (e) {
      setLoading(false);
      debugPrint('Error fetching statuses: $e');
    }
  }
  
  // Stream of users with recent status updates (for status list)
  Stream<QuerySnapshot> getUsersWithStatusStream() {
    // Get timestamp for 24 hours ago
    final twentyFourHoursAgo = DateTime.now()
        .subtract(const Duration(hours: 24))
        .millisecondsSinceEpoch;
    
    return _firestore
        .collection(Constants.users)
        .where('lastStatusUpdate', isGreaterThan: twentyFourHoursAgo)
        .orderBy('lastStatusUpdate', descending: true)
        .snapshots();
  }
  
  // Stream of status updates for a specific user
  Stream<QuerySnapshot> getUserStatusStream(String uid) {
    return _firestore
        .collection('status')
        .doc(uid)
        .collection('userStatus')
        .orderBy('createdAt', descending: false) // Oldest first
        .snapshots();
  }
}
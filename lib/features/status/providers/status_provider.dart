import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:uuid/uuid.dart';

class StatusProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  List<StatusModel> _statusList = [];
  bool _isLoading = false;
  bool _hasMoreStatuses = true;
  String? _lastStatusId;
  int _batchSize = 15; // Increased batch size for better initial load
  bool _isStatusTabVisible = true; // Property for tab visibility
  bool _isAppFreshStart = true; // Property for app fresh start state

  // Getters
  List<StatusModel> get statusList => _statusList;
  bool get isLoading => _isLoading;
  bool get hasMoreStatuses => _hasMoreStatuses;
  bool get isStatusTabVisible => _isStatusTabVisible;
  bool get isAppFreshStart => _isAppFreshStart;

  // Tab visibility setter
  void setStatusTabVisible(bool visible) {
    _isStatusTabVisible = visible;
    notifyListeners();
  }
  
  // App fresh start setter
  void setAppFreshStart(bool isFreshStart) {
    _isAppFreshStart = isFreshStart;
    notifyListeners();
  }

  // FETCH STATUSES - Optimized for better performance and pure chronological ordering
  Future<void> fetchStatuses({
    required String currentUserId,
    required List<String> contactIds,
    bool refresh = true,
  }) async {
    try {
      _isLoading = true;
      
      // Only notify at the beginning of the load if it's a fresh load
      if (refresh) {
        notifyListeners();
      }
      
      if (refresh) {
        _statusList = [];
        _lastStatusId = null;
        _hasMoreStatuses = true;
      }
      
      if (!_hasMoreStatuses) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Calculate expiration time (72 hours ago)
      final expirationTime = DateTime.now().subtract(const Duration(hours: 72));
      
      // Create the base query - fetch ALL statuses, not just from contacts
      // We'll sort by createdAt in descending order (newest first)
      Query query = _firestore.collection('statuses')
          .where('createdAt', isGreaterThan: expirationTime.millisecondsSinceEpoch)
          .orderBy('createdAt', descending: true)
          .limit(_batchSize);
      
      // Add pagination if not refreshing
      if (_lastStatusId != null && !refresh) {
        final lastStatusDoc = await _firestore
            .collection('statuses')
            .doc(_lastStatusId)
            .get();
        
        if (lastStatusDoc.exists) {
          query = query.startAfterDocument(lastStatusDoc);
        }
      }
      
      final statusDocs = await query.get();
      
      if (statusDocs.docs.isEmpty) {
        _hasMoreStatuses = false;
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Update _lastStatusId for pagination
      _lastStatusId = statusDocs.docs.last.id;
      
      // Convert documents to StatusModel objects
      final List<StatusModel> newStatuses = [];
      
      for (var doc in statusDocs.docs) {
        final statusData = doc.data() as Map<String, dynamic>;
        final status = StatusModel.fromMap(statusData);
        
        // Skip expired statuses
        if (status.isExpired) continue;
        
        newStatuses.add(status);
      }
      
      // Update local list - preserving pure chronological order
      if (refresh) {
        _statusList = newStatuses;
      } else {
        _statusList.addAll(newStatuses);
      }
      
      // Set hasMoreStatuses based on actual results
      _hasMoreStatuses = statusDocs.docs.length >= _batchSize;
      
    } catch (e) {
      debugPrint('Error fetching statuses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // LOAD MORE STATUSES
  Future<void> loadMoreStatuses({
    required String currentUserId,
    required List<String> contactIds,
  }) async {
    if (!_hasMoreStatuses || _isLoading) return;
    
    await fetchStatuses(
      currentUserId: currentUserId,
      contactIds: contactIds,
      refresh: false,
    );
  }

  // UPLOAD A NEW STATUS with support for multiple media files
  Future<StatusModel?> createStatus({
    required UserModel user,
    required String caption,
    StatusType statusType = StatusType.text,
    File? mediaFile, // Keep for backward compatibility
    List<File>? mediaFiles, // New parameter for multiple files
    String backgroundColor = '#000000',
    String textColor = '#FFFFFF',
    String fontStyle = 'normal',
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final statusId = const Uuid().v4();
      String statusUrl = '';
      List<String> mediaUrls = [];
      
      // Upload media files
      if (statusType != StatusType.text) {
        // Handle single file for backward compatibility
        if (mediaFile != null && (mediaFiles == null || mediaFiles.isEmpty)) {
          final String storagePath = 'statusFiles/${user.uid}/$statusId/0';
          statusUrl = await storeFileToStorage(
            file: mediaFile,
            reference: storagePath,
          );
          mediaUrls.add(statusUrl);
        } 
        // Handle multiple files
        else if (mediaFiles != null && mediaFiles.isNotEmpty) {
          for (int i = 0; i < mediaFiles.length; i++) {
            final String storagePath = 'statusFiles/${user.uid}/$statusId/$i';
            String url = await storeFileToStorage(
              file: mediaFiles[i],
              reference: storagePath,
            );
            mediaUrls.add(url);
          }
          
          // Set the first image as the main statusUrl for backward compatibility
          if (mediaUrls.isNotEmpty) {
            statusUrl = mediaUrls[0];
          }
        }
      }
      
      // Create the status model
      final newStatus = StatusModel(
        uid: user.uid,
        userName: user.name,
        userImage: user.image,
        statusId: statusId,
        statusUrl: statusUrl,
        mediaUrls: mediaUrls,
        caption: caption,
        statusType: statusType,
        createdAt: DateTime.now(),
        viewedBy: [user.uid], // Creator has seen their own status
        backgroundColor: backgroundColor,
        textColor: textColor,
        fontStyle: fontStyle,
      );
      
      // Save to Firestore
      await _firestore
          .collection('statuses')
          .doc(statusId)
          .set(newStatus.toMap());
      
      // Add to local list
      _statusList.insert(0, newStatus);
      notifyListeners();
      
      return newStatus;
    } catch (e) {
      debugPrint('Error creating status: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // DELETE A STATUS
  Future<bool> deleteStatus(String statusId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Find the status to get its URL (for storage cleanup)
      final statusIndex = _statusList.indexWhere((s) => s.statusId == statusId);
      if (statusIndex < 0) return false;
      
      final status = _statusList[statusIndex];
      
      // Delete from Firestore
      await _firestore.collection('statuses').doc(statusId).delete();
      
      // If it has media, delete from storage
      if (status.statusType != StatusType.text) {
        // Handle both legacy single URL and new multiple URLs
        List<String> urlsToDelete = [];
        
        if (status.statusUrl.isNotEmpty) {
          urlsToDelete.add(status.statusUrl);
        }
        
        if (status.mediaUrls.isNotEmpty) {
          // Add any URLs from mediaUrls that aren't already in the list
          for (String url in status.mediaUrls) {
            if (!urlsToDelete.contains(url)) {
              urlsToDelete.add(url);
            }
          }
        }
        
        // Delete all media files
        for (String url in urlsToDelete) {
          try {
            final storageRef = _storage.refFromURL(url);
            await storageRef.delete();
          } catch (e) {
            debugPrint('Error deleting status media: $e');
            // Continue with deletion even if media removal fails
          }
        }
      }
      
      // Remove from local list
      _statusList.removeAt(statusIndex);
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('Error deleting status: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // MARK STATUS AS VIEWED
  Future<void> markStatusAsViewed(String statusId) async {
    try {
      // Get current user ID
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      // Find status in local list
      final statusIndex = _statusList.indexWhere((s) => s.statusId == statusId);
      if (statusIndex < 0) return;
      
      final status = _statusList[statusIndex];
      
      // Check if user has already viewed this status
      if (status.viewedBy.contains(currentUser.uid)) return;
      
      // Update Firestore
      await _firestore.collection('statuses').doc(statusId).update({
        'viewedBy': FieldValue.arrayUnion([currentUser.uid]),
      });
      
      // Update local list
      final updatedViewedBy = List<String>.from(status.viewedBy)..add(currentUser.uid);
      final updatedStatus = status.copyWith(viewedBy: updatedViewedBy);
      
      _statusList[statusIndex] = updatedStatus;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking status as viewed: $e');
    }
  }
  
  // Navigate between media in multi-image status
  void updateStatusMediaIndex(String statusId, int newIndex) {
    try {
      // Find status in local list
      final statusIndex = _statusList.indexWhere((s) => s.statusId == statusId);
      if (statusIndex < 0) return;
      
      final status = _statusList[statusIndex];
      
      // Validate index is within bounds
      if (newIndex < 0 || newIndex >= status.mediaUrls.length) return;
      
      // Create updated status with new index
      final updatedStatus = status.copyWithIndex(newIndex);
      
      // Update local list
      _statusList[statusIndex] = updatedStatus;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating status media index: $e');
    }
  }

  // CLEAR PROVIDER STATE
  void reset() {
    _statusList = [];
    _isLoading = false;
    _hasMoreStatuses = true;
    _lastStatusId = null;
    _isAppFreshStart = true; // Reset fresh start state when provider is reset
    notifyListeners();
  }
}
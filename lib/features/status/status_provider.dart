// lib/features/status/status_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/status_post_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:path_provider/path_provider.dart';

enum FeedFilterType { latest, viewed, unviewed }

/// Status provider for managing status posts
class StatusProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();
  
  // State variables
  bool _isLoading = false;
  String _searchQuery = '';
  FeedFilterType _currentFilter = FeedFilterType.latest;
  
  // Status tab visibility tracking flags (needed for home_screen.dart)
  bool _isAppFreshStart = true;
  bool _isStatusTabVisible = false;
  
  // Status posts grouped by user
  Map<String, List<StatusPostModel>> _userStatusMap = {};
  
  // Status posts from current user
  List<StatusPostModel> _myStatuses = [];
  
  // Getters
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  FeedFilterType get currentFilter => _currentFilter;
  Map<String, List<StatusPostModel>> get userStatusMap => _userStatusMap;
  List<StatusPostModel> get myStatuses => _myStatuses;
  
  // Getters needed for home_screen.dart
  bool get isAppFreshStart => _isAppFreshStart;
  bool get isStatusTabVisible => _isStatusTabVisible;
  
  /// Get a list of users with active status posts
  List<String> get usersWithStatus => _userStatusMap.keys.toList();
  
  /// Set app fresh start flag
  void setAppFreshStart(bool value) {
    _isAppFreshStart = value;
    notifyListeners();
  }
  
  /// Set status tab visibility
  void setStatusTabVisible(bool value) {
    _isStatusTabVisible = value;
    notifyListeners();
  }
  
  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  /// Set feed filter
  void setFeedFilter(FeedFilterType filter) {
    _currentFilter = filter;
    notifyListeners();
  }
  
  /// Fetch all status posts that the current user can view
  Future<void> fetchAllStatuses({
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
      Map<String, List<StatusPostModel>> groupedStatuses = {};
      List<StatusPostModel> currentUserStatuses = [];
      
      for (var doc in snapshot.docs) {
        final statusPost = StatusPostModel.fromMap(doc.data());
        
        // Check if status is visible to current user
        bool canView = true; // Default visibility logic - can be enhanced
        
        if (canView) {
          if (statusPost.uid == currentUserId) {
            // Current user's own status
            currentUserStatuses.add(statusPost);
          } else {
            // Group other users' statuses by creator
            if (!groupedStatuses.containsKey(statusPost.uid)) {
              groupedStatuses[statusPost.uid] = [];
            }
            groupedStatuses[statusPost.uid]!.add(statusPost);
          }
        }
      }
      
      // Sort each user's statuses by creation time (oldest first)
      groupedStatuses.forEach((uid, statuses) {
        statuses.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      });
      
      // Sort current user's statuses by creation time (oldest first)
      currentUserStatuses.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      _userStatusMap = groupedStatuses;
      _myStatuses = currentUserStatuses;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching statuses: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Backward compatibility with home screen
  Future<void> fetchStatuses({
    required String currentUserId,
    required List<String> contactIds,
  }) async {
    return fetchAllStatuses(currentUserId: currentUserId, contactIds: contactIds);
  }

  /// Mark a status as viewed
  Future<void> viewStatus({
    required String statusId,
    required String viewerUid,
  }) async {
    try {
      // Find the status post
      StatusPostModel? targetStatus;
      String? targetUserUid;
      
      // Check if it's in current user's statuses
      final myStatusIndex = _myStatuses.indexWhere((post) => post.statusId == statusId);
      if (myStatusIndex != -1) {
        targetStatus = _myStatuses[myStatusIndex];
        targetUserUid = targetStatus.uid;
      }
      
      // If not found, check in other users' statuses
      if (targetStatus == null) {
        for (var entry in _userStatusMap.entries) {
          final statusIndex = entry.value.indexWhere((post) => post.statusId == statusId);
          if (statusIndex != -1) {
            targetStatus = entry.value[statusIndex];
            targetUserUid = entry.key;
            break;
          }
        }
      }
      
      // If status not found or already viewed, return
      if (targetStatus == null || targetStatus.viewerUIDs.contains(viewerUid)) {
        return;
      }
      
      // Add viewer to the list
      final updatedViewerUIDs = List<String>.from(targetStatus.viewerUIDs)..add(viewerUid);
      final updatedViewCount = targetStatus.viewCount + 1;
      
      // Update Firestore
      await _firestore.collection(Constants.statuses).doc(statusId).update({
        'viewerUIDs': updatedViewerUIDs,
        Constants.statusViewCount: updatedViewCount,
      });
      
      // Update local state
      if (myStatusIndex != -1) {
        _myStatuses[myStatusIndex] = _myStatuses[myStatusIndex].copyWith(
          viewerUIDs: updatedViewerUIDs,
          viewCount: updatedViewCount,
        );
      } else if (targetUserUid != null) {
        final userStatusIndex = _userStatusMap[targetUserUid]!.indexWhere((post) => post.statusId == statusId);
        if (userStatusIndex != -1) {
          _userStatusMap[targetUserUid]![userStatusIndex] = _userStatusMap[targetUserUid]![userStatusIndex].copyWith(
            viewerUIDs: updatedViewerUIDs,
            viewCount: updatedViewCount,
          );
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error viewing status: $e');
    }
  }
  
  /// Create a new media status post
  Future<void> createMediaStatus({
    required String uid,
    required String username,
    required String userImage,
    required List<File> mediaFiles,
    required StatusType type,
    String caption = '',
    required StatusPrivacyType privacyType,
    List<String> includedContactUIDs = const [],
    List<String> excludedContactUIDs = const [],
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
      
      // Calculate expiry time (24 hours from now)
      final createdAt = DateTime.now();
      final expiresAt = createdAt.add(const Duration(hours: 24));
      
      // Create status post model
      final statusPost = StatusPostModel(
        statusId: statusId,
        uid: uid,
        username: username,
        userImage: userImage,
        type: type,
        mediaUrls: mediaUrls,
        caption: caption,
        createdAt: createdAt,
        expiresAt: expiresAt,
        viewerUIDs: [],
        viewCount: 0,
        isPrivate: privacyType != StatusPrivacyType.all_contacts,
        isContactsOnly: privacyType == StatusPrivacyType.all_contacts || privacyType == StatusPrivacyType.except,
        allowedContactUIDs: includedContactUIDs,
      );
      
      // Save to Firestore
      await _firestore
          .collection(Constants.statuses)
          .doc(statusId)
          .set(statusPost.toMap());
      
      // Add to local state
      _myStatuses.add(statusPost);
      
      // Sort by creation time
      _myStatuses.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating media status: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  /// Create a new text status
  Future<void> createTextStatus({
    required String uid,
    required String username,
    required String userImage,
    required String text,
    required Color backgroundColor,
    String? fontName,
    required StatusPrivacyType privacyType,
    List<String> includedContactUIDs = const [],
    List<String> excludedContactUIDs = const [],
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Generate unique status ID
      final statusId = _uuid.v4();
      
      // Calculate expiry time (24 hours from now)
      final createdAt = DateTime.now();
      final expiresAt = createdAt.add(const Duration(hours: 24));
      
      // Create status post model with text type
      final statusPost = StatusPostModel(
        statusId: statusId,
        uid: uid,
        username: username,
        userImage: userImage,
        type: StatusType.text,
        mediaUrls: [],
        caption: text,
        createdAt: createdAt,
        expiresAt: expiresAt,
        viewerUIDs: [],
        viewCount: 0,
        isPrivate: privacyType != StatusPrivacyType.all_contacts,
        isContactsOnly: privacyType == StatusPrivacyType.all_contacts || privacyType == StatusPrivacyType.except,
        allowedContactUIDs: includedContactUIDs,
      );
      
      // Save to Firestore
      await _firestore
          .collection(Constants.statuses)
          .doc(statusId)
          .set(statusPost.toMap());
      
      // Add to local state
      _myStatuses.add(statusPost);
      
      // Sort by creation time
      _myStatuses.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating text status: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  /// Create a new link status
  Future<void> createLinkStatus({
    required String uid,
    required String username,
    required String userImage,
    required String linkUrl,
    String caption = '',
    required StatusPrivacyType privacyType,
    List<String> includedContactUIDs = const [],
    List<String> excludedContactUIDs = const [],
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Generate unique status ID
      final statusId = _uuid.v4();
      
      // Calculate expiry time (24 hours from now)
      final createdAt = DateTime.now();
      final expiresAt = createdAt.add(const Duration(hours: 24));
      
      // Create status post model with text type (using text for backward compatibility)
      final statusPost = StatusPostModel(
        statusId: statusId,
        uid: uid,
        username: username,
        userImage: userImage,
        type: StatusType.text,
        mediaUrls: [],
        caption: caption.isEmpty ? linkUrl : '$caption\n\n$linkUrl',
        createdAt: createdAt,
        expiresAt: expiresAt,
        viewerUIDs: [],
        viewCount: 0,
        isPrivate: privacyType != StatusPrivacyType.all_contacts,
        isContactsOnly: privacyType == StatusPrivacyType.all_contacts || privacyType == StatusPrivacyType.except,
        allowedContactUIDs: includedContactUIDs,
      );
      
      // Save to Firestore
      await _firestore
          .collection(Constants.statuses)
          .doc(statusId)
          .set(statusPost.toMap());
      
      // Add to local state
      _myStatuses.add(statusPost);
      
      // Sort by creation time
      _myStatuses.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating link status: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  /// Delete a status post
  Future<void> deleteStatus({
    required String statusId,
    required String creatorUid,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Find the status in local state
      final statusIndex = _myStatuses.indexWhere((post) => post.statusId == statusId);
      if (statusIndex == -1) {
        throw Exception('Status not found');
      }
      
      final status = _myStatuses[statusIndex];
      
      // Verify user is the creator
      if (status.uid != creatorUid) {
        throw Exception('Only the creator can delete their status');
      }
      
      // Delete media files from storage if they exist
      for (var url in status.mediaUrls) {
        try {
          final ref = _storage.refFromURL(url);
          await ref.delete();
        } catch (e) {
          debugPrint('Error deleting media file: $e');
          // Continue with deletion even if files can't be removed
        }
      }
      
      // Delete status document
      await _firestore
          .collection(Constants.statuses)
          .doc(statusId)
          .delete();
      
      // Update local state
      _myStatuses.removeAt(statusIndex);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting status: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  /// Check if user has posted today
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

// Privacy settings enum for StatusProvider (for backward compatibility)
enum StatusPrivacyType {
  all_contacts,    // All contacts can see
  except,          // All contacts except specific ones
  only,            // Only specific contacts can see
}
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:uuid/uuid.dart';

class StatusProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isSuccessful = false;
  bool _statusTabVisible = false;
  bool _appInFreshStart = true;
  
  // Statuses categorized by user
  Map<String, List<StatusModel>> _userStatuses = {}; 
  List<StatusModel> _myPrivateStatuses = [];
  List<StatusModel> _myPublicStatuses = [];
  List<StatusModel> _publicStatuses = [];
  
  // Status posting limits
  final int _maxPublicStatusPerDay = 3;
  
  // Current user
  String _currentUserId = '';

  // Firebase references
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Getters
  bool get isLoading => _isLoading;
  bool get isSuccessful => _isSuccessful;
  bool get statusTabVisible => _statusTabVisible;
  bool get appInFreshStart => _appInFreshStart;
  Map<String, List<StatusModel>> get userStatuses => _userStatuses;
  List<StatusModel> get myPrivateStatuses => _myPrivateStatuses;
  List<StatusModel> get myPublicStatuses => _myPublicStatuses;
  List<StatusModel> get publicStatuses => _publicStatuses;
  
  // Status posting limit
  int get maxPublicStatusPerDay => _maxPublicStatusPerDay;
  int get remainingPublicStatusToday => _maxPublicStatusPerDay - _getTodayPublicStatusCount();
  
  // Set status tab visibility
  void setStatusTabVisible(bool visible) {
    _statusTabVisible = visible;
    notifyListeners();
  }
  
  // Set app fresh start state
  void setAppFreshStart(bool freshStart) {
    _appInFreshStart = freshStart;
    notifyListeners();
  }
  
  // Initialize with user ID
  void initialize(String userId) {
    _currentUserId = userId;
  }
  
  // Create a new status
  Future<void> createStatus({
    required String userId,
    required String userName,
    required String userImage,
    String text = '',
    File? mediaFile,
    required StatusType type,
    required bool isPrivate,
    Map<String, String> backgroundInfo = const {},
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    try {
      _isLoading = true;
      _isSuccessful = false;
      notifyListeners();
      
      // Check public status limit if needed
      if (!isPrivate && remainingPublicStatusToday <= 0) {
        throw Exception('You have reached your daily limit for public statuses. Try again tomorrow or post a private status.');
      }
      
      // Generate a unique ID for the status
      final statusId = const Uuid().v4();
      
      // Upload media file if provided
      String mediaUrl = '';
      if (mediaFile != null) {
        final ref = '${Constants.statusFiles}/$userId/$statusId';
        mediaUrl = await storeFileToStorage(file: mediaFile, reference: ref);
      }
      
      // Create status model
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));
      
      final statusModel = StatusModel(
        statusId: statusId,
        uid: userId,
        userName: userName,
        userImage: userImage,
        text: text,
        mediaUrl: mediaUrl,
        type: type,
        createdAt: now,
        expiresAt: expiresAt,
        isPrivate: isPrivate,
        viewedBy: [],
        likedBy: [],
        backgroundInfo: backgroundInfo,
      );
      
      // Save to Firestore
      await _firestore
          .collection(Constants.statuses)
          .doc(statusId)
          .set(statusModel.toMap());
      
      // Add to local lists
      if (isPrivate) {
        _myPrivateStatuses.add(statusModel);
      } else {
        _myPublicStatuses.add(statusModel);
      }
      
      _isLoading = false;
      _isSuccessful = true;
      notifyListeners();
      
      onSuccess();
    } catch (e) {
      _isLoading = false;
      _isSuccessful = false;
      notifyListeners();
      
      onError(e.toString());
    }
  }
  
  // Fetch statuses
  Future<void> fetchStatuses({
    required String currentUserId,
    required List<String> contactIds,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Initialize with current user ID
      initialize(currentUserId);
      
      // Clear previous data
      _userStatuses.clear();
      _myPrivateStatuses.clear();
      _myPublicStatuses.clear();
      _publicStatuses.clear();
      
      // Get all unexpired statuses
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Fetch my statuses
      final myStatusesQuery = await _firestore
          .collection(Constants.statuses)
          .where(Constants.uid, isEqualTo: currentUserId)
          .where(Constants.createdAt, isGreaterThan: now - (24 * 60 * 60 * 1000)) // Last 24 hours
          .get();
      
      for (var doc in myStatusesQuery.docs) {
        final status = StatusModel.fromMap(doc.data());
        
        if (status.isPrivate) {
          _myPrivateStatuses.add(status);
        } else {
          _myPublicStatuses.add(status);
        }
      }
      
      // Sort by creation time (newest first)
      _myPrivateStatuses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _myPublicStatuses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Fetch contacts' private statuses
      if (contactIds.isNotEmpty) {
        final contactStatusesQuery = await _firestore
            .collection(Constants.statuses)
            .where(Constants.uid, whereIn: contactIds)
            .where('isPrivate', isEqualTo: true)
            .where(Constants.createdAt, isGreaterThan: now - (24 * 60 * 60 * 1000)) // Last 24 hours
            .get();
        
        for (var doc in contactStatusesQuery.docs) {
          final status = StatusModel.fromMap(doc.data());
          
          if (!status.isExpired) {
            final uid = status.uid;
            
            if (!_userStatuses.containsKey(uid)) {
              _userStatuses[uid] = [];
            }
            
            _userStatuses[uid]!.add(status);
          }
        }
        
        // Sort each user's statuses by creation time (oldest first for viewing order)
        _userStatuses.forEach((uid, statuses) {
          statuses.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        });
      }
      
      // Fetch public statuses (from all users)
      final publicStatusesQuery = await _firestore
          .collection(Constants.statuses)
          .where('isPrivate', isEqualTo: false)
          .where(Constants.createdAt, isGreaterThan: now - (24 * 60 * 60 * 1000)) // Last 24 hours
          .get();
      
      for (var doc in publicStatusesQuery.docs) {
        final status = StatusModel.fromMap(doc.data());
        
        if (!status.isExpired && status.uid != currentUserId) {
          _publicStatuses.add(status);
        }
      }
      
      // Sort public statuses by creation time (newest first)
      _publicStatuses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error fetching statuses: $e');
    }
  }
  
  // Mark status as viewed
  Future<void> markStatusAsViewed(StatusModel status) async {
    if (_currentUserId.isEmpty || status.isViewedBy(_currentUserId)) {
      return;
    }
    
    try {
      // Update on Firestore
      await _firestore
          .collection(Constants.statuses)
          .doc(status.statusId)
          .update({
        'viewedBy': FieldValue.arrayUnion([_currentUserId]),
      });
      
      // Update local model
      final updatedViewedBy = List<String>.from(status.viewedBy)..add(_currentUserId);
      
      // Update in appropriate collections
      if (status.uid == _currentUserId) {
        if (status.isPrivate) {
          final index = _myPrivateStatuses.indexWhere((s) => s.statusId == status.statusId);
          if (index >= 0) {
            _myPrivateStatuses[index] = status.copyWith(viewedBy: updatedViewedBy);
          }
        } else {
          final index = _myPublicStatuses.indexWhere((s) => s.statusId == status.statusId);
          if (index >= 0) {
            _myPublicStatuses[index] = status.copyWith(viewedBy: updatedViewedBy);
          }
        }
      } else {
        if (status.isPrivate) {
          if (_userStatuses.containsKey(status.uid)) {
            final index = _userStatuses[status.uid]!.indexWhere((s) => s.statusId == status.statusId);
            if (index >= 0) {
              _userStatuses[status.uid]![index] = status.copyWith(viewedBy: updatedViewedBy);
            }
          }
        } else {
          final index = _publicStatuses.indexWhere((s) => s.statusId == status.statusId);
          if (index >= 0) {
            _publicStatuses[index] = status.copyWith(viewedBy: updatedViewedBy);
          }
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking status as viewed: $e');
    }
  }
  
  // Like/unlike status
  Future<void> toggleStatusLike(StatusModel status) async {
    if (_currentUserId.isEmpty) {
      return;
    }
    
    final isLiked = status.isLikedBy(_currentUserId);
    
    try {
      // Update on Firestore
      await _firestore
          .collection(Constants.statuses)
          .doc(status.statusId)
          .update({
        'likedBy': isLiked
            ? FieldValue.arrayRemove([_currentUserId])
            : FieldValue.arrayUnion([_currentUserId]),
      });
      
      // Update local model
      List<String> updatedLikedBy;
      if (isLiked) {
        updatedLikedBy = List<String>.from(status.likedBy)..remove(_currentUserId);
      } else {
        updatedLikedBy = List<String>.from(status.likedBy)..add(_currentUserId);
      }
      
      // Update in appropriate collections
      if (status.uid == _currentUserId) {
        if (status.isPrivate) {
          final index = _myPrivateStatuses.indexWhere((s) => s.statusId == status.statusId);
          if (index >= 0) {
            _myPrivateStatuses[index] = status.copyWith(likedBy: updatedLikedBy);
          }
        } else {
          final index = _myPublicStatuses.indexWhere((s) => s.statusId == status.statusId);
          if (index >= 0) {
            _myPublicStatuses[index] = status.copyWith(likedBy: updatedLikedBy);
          }
        }
      } else {
        if (status.isPrivate) {
          if (_userStatuses.containsKey(status.uid)) {
            final index = _userStatuses[status.uid]!.indexWhere((s) => s.statusId == status.statusId);
            if (index >= 0) {
              _userStatuses[status.uid]![index] = status.copyWith(likedBy: updatedLikedBy);
            }
          }
        } else {
          final index = _publicStatuses.indexWhere((s) => s.statusId == status.statusId);
          if (index >= 0) {
            _publicStatuses[index] = status.copyWith(likedBy: updatedLikedBy);
          }
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling status like: $e');
    }
  }
  
  // Delete status
  Future<void> deleteStatus(StatusModel status) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Delete from Firestore
      await _firestore
          .collection(Constants.statuses)
          .doc(status.statusId)
          .delete();
      
      // Delete media if exists
      if (status.mediaUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(status.mediaUrl).delete();
        } catch (e) {
          debugPrint('Error deleting status media: $e');
        }
      }
      
      // Remove from local lists
      if (status.uid == _currentUserId) {
        if (status.isPrivate) {
          _myPrivateStatuses.removeWhere((s) => s.statusId == status.statusId);
        } else {
          _myPublicStatuses.removeWhere((s) => s.statusId == status.statusId);
        }
      } else {
        if (status.isPrivate) {
          if (_userStatuses.containsKey(status.uid)) {
            _userStatuses[status.uid]!.removeWhere((s) => s.statusId == status.statusId);
            
            // Remove empty user entries
            if (_userStatuses[status.uid]!.isEmpty) {
              _userStatuses.remove(status.uid);
            }
          }
        } else {
          _publicStatuses.removeWhere((s) => s.statusId == status.statusId);
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      
      debugPrint('Error deleting status: $e');
    }
  }
  
  // Get status by ID
  StatusModel? getStatusById(String statusId) {
    // Check in private statuses
    final privateStatus = _myPrivateStatuses.firstWhere(
      (s) => s.statusId == statusId,
      orElse: () => StatusModel(
        statusId: '',
        uid: '',
        userName: '',
        userImage: '',
        text: '',
        mediaUrl: '',
        type: StatusType.text,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now(),
        isPrivate: true,
        viewedBy: [],
        likedBy: [],
        backgroundInfo: {},
      ),
    );
    
    if (privateStatus.statusId.isNotEmpty) {
      return privateStatus;
    }
    
    // Check in public statuses
    final publicStatus = _myPublicStatuses.firstWhere(
      (s) => s.statusId == statusId,
      orElse: () => StatusModel(
        statusId: '',
        uid: '',
        userName: '',
        userImage: '',
        text: '',
        mediaUrl: '',
        type: StatusType.text,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now(),
        isPrivate: true,
        viewedBy: [],
        likedBy: [],
        backgroundInfo: {},
      ),
    );
    
    if (publicStatus.statusId.isNotEmpty) {
      return publicStatus;
    }
    
    // Check in user statuses
    for (final userStatusList in _userStatuses.values) {
      final status = userStatusList.firstWhere(
        (s) => s.statusId == statusId,
        orElse: () => StatusModel(
          statusId: '',
          uid: '',
          userName: '',
          userImage: '',
          text: '',
          mediaUrl: '',
          type: StatusType.text,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now(),
          isPrivate: true,
          viewedBy: [],
          likedBy: [],
          backgroundInfo: {},
        ),
      );
      
      if (status.statusId.isNotEmpty) {
        return status;
      }
    }
    
    // Check in public statuses from others
    final otherPublicStatus = _publicStatuses.firstWhere(
      (s) => s.statusId == statusId,
      orElse: () => StatusModel(
        statusId: '',
        uid: '',
        userName: '',
        userImage: '',
        text: '',
        mediaUrl: '',
        type: StatusType.text,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now(),
        isPrivate: true,
        viewedBy: [],
        likedBy: [],
        backgroundInfo: {},
      ),
    );
    
    if (otherPublicStatus.statusId.isNotEmpty) {
      return otherPublicStatus;
    }
    
    return null;
  }
  
  // Helper method to get the count of public statuses created today
  int _getTodayPublicStatusCount() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    return _myPublicStatuses.where((status) => 
      status.createdAt.isAfter(startOfDay)
    ).length;
  }
  
  // Stream of status updates (for real-time updates)
  Stream<QuerySnapshot> getStatusUpdatesStream() {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    return _firestore
        .collection(Constants.statuses)
        .where(Constants.createdAt, isGreaterThan: now - (24 * 60 * 60 * 1000)) // Last 24 hours
        .snapshots();
  }
}
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/status_model.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:uuid/uuid.dart';

class StatusProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  bool _isLoading = false;
  bool _isFetching = false;
  bool _statusTabVisible = false;
  bool _appFreshStart = true;
  
  List<StatusModel> _contactStatuses = [];
  StatusModel? _myStatus;
  
  // Getters
  bool get isLoading => _isLoading;
  bool get isFetching => _isFetching;
  bool get statusTabVisible => _statusTabVisible;
  bool get appFreshStart => _appFreshStart;
  List<StatusModel> get contactStatuses => _contactStatuses;
  StatusModel? get myStatus => _myStatus;
  
  // Setters
  void setStatusTabVisible(bool visible) {
    _statusTabVisible = visible;
    notifyListeners();
  }
  
  void setAppFreshStart(bool value) {
    _appFreshStart = value;
    notifyListeners();
  }
  
  // Create a new status
  Future<void> createStatus({
    required UserModel currentUser,
    required File mediaFile,
    required StatusType type,
    String? caption,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Generate unique IDs
      final String statusId = const Uuid().v4();
      final String itemId = const Uuid().v4();
      
      // Upload media to storage
      final String fileName = '$statusId/$itemId';
      final String storagePath = '${Constants.statuses}/${currentUser.uid}/$fileName';
      
      String mediaUrl = '';
      
      if (type != StatusType.text) {
        // Upload image or video
        mediaUrl = await storeFileToStorage(
          file: mediaFile,
          reference: storagePath,
        );
      } else {
        // For text status, use the caption as mediaUrl
        mediaUrl = caption ?? '';
      }
      
      // Create status item
      final StatusItemModel statusItem = StatusItemModel(
        itemId: itemId,
        mediaUrl: mediaUrl,
        caption: caption,
        timestamp: DateTime.now(),
        type: type,
        viewedBy: [currentUser.uid], // Creator has viewed it
        reactions: {},
      );
      
      // Check if user already has a status
      final DocumentSnapshot statusDoc = await _firestore
          .collection(Constants.statuses)
          .doc(currentUser.uid)
          .get();
      
      final DateTime now = DateTime.now();
      final DateTime expiryTime = now.add(const Duration(hours: 24));
      
      if (statusDoc.exists) {
        // Update existing status with new item
        final StatusModel existingStatus = StatusModel.fromMap(
          statusDoc.data() as Map<String, dynamic>
        );
        
        // Filter out expired items
        final List<StatusItemModel> activeItems = existingStatus.items
            .where((item) => now.difference(item.timestamp).inHours < 24)
            .toList();
        
        // Add new item
        activeItems.add(statusItem);
        
        // Update status
        await _firestore.collection(Constants.statuses).doc(currentUser.uid).update({
          'items': activeItems.map((e) => e.toMap()).toList(),
          'expiresAt': expiryTime.millisecondsSinceEpoch,
        });
      } else {
        // Create new status
        final StatusModel newStatus = StatusModel(
          statusId: statusId,
          uid: currentUser.uid,
          userName: currentUser.name,
          userImage: currentUser.image,
          items: [statusItem],
          createdAt: now,
          expiresAt: expiryTime,
        );
        
        // Save to Firestore
        await _firestore.collection(Constants.statuses)
            .doc(currentUser.uid)
            .set(newStatus.toMap());
      }
      
      _isLoading = false;
      notifyListeners();
      onSuccess();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      onError(e.toString());
    }
  }
  
  // Delete a status item
  Future<void> deleteStatusItem({
    required String userId,
    required String itemId,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Get the current status
      final DocumentSnapshot statusDoc = await _firestore
          .collection(Constants.statuses)
          .doc(userId)
          .get();
      
      if (!statusDoc.exists) {
        throw Exception('Status not found');
      }
      
      final StatusModel status = StatusModel.fromMap(
        statusDoc.data() as Map<String, dynamic>
      );
      
      // Find the item to delete
      final int index = status.items.indexWhere((item) => item.itemId == itemId);
      
      if (index == -1) {
        throw Exception('Status item not found');
      }
      
      // Get the item to delete its media if needed
      final StatusItemModel itemToDelete = status.items[index];
      
      // Delete media from storage if not a text status
      if (itemToDelete.type != StatusType.text && itemToDelete.mediaUrl.isNotEmpty) {
        try {
          final ref = _storage.refFromURL(itemToDelete.mediaUrl);
          await ref.delete();
        } catch (e) {
          // Just log it, don't stop execution
          debugPrint('Error deleting media: $e');
        }
      }
      
      // Remove the item from the list
      final List<StatusItemModel> updatedItems = List.from(status.items);
      updatedItems.removeAt(index);
      
      if (updatedItems.isEmpty) {
        // If no items left, delete the entire status
        await _firestore.collection(Constants.statuses).doc(userId).delete();
      } else {
        // Update with remaining items
        await _firestore.collection(Constants.statuses).doc(userId).update({
          'items': updatedItems.map((e) => e.toMap()).toList(),
        });
      }
      
      _isLoading = false;
      notifyListeners();
      onSuccess();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      onError(e.toString());
    }
  }
  
  // Fetch all statuses (my status + contacts' statuses)
  Future<void> fetchStatuses({
    required String currentUserId,
    required List<String> contactIds,
  }) async {
    try {
      _isFetching = true;
      notifyListeners();
      
      // Clear previous data
      _myStatus = null;
      _contactStatuses = [];
      
      // Current time to filter expired statuses
      final DateTime now = DateTime.now();
      
      // Fetch my status
      final DocumentSnapshot myStatusDoc = await _firestore
          .collection(Constants.statuses)
          .doc(currentUserId)
          .get();
      
      if (myStatusDoc.exists) {
        final StatusModel status = StatusModel.fromMap(
          myStatusDoc.data() as Map<String, dynamic>
        );
        
        // Filter out items older than 24 hours
        final List<StatusItemModel> activeItems = status.items
            .where((item) => now.difference(item.timestamp).inHours < 24)
            .toList();
        
        if (activeItems.isNotEmpty) {
          final StatusModel activeStatus = StatusModel(
            statusId: status.statusId,
            uid: status.uid,
            userName: status.userName,
            userImage: status.userImage,
            items: activeItems,
            createdAt: status.createdAt,
            expiresAt: status.expiresAt,
          );
          
          _myStatus = activeStatus;
        } else {
          // If all items are expired, delete the status
          await _firestore.collection(Constants.statuses).doc(currentUserId).delete();
        }
      }
      
      // Fetch contacts' statuses
      if (contactIds.isNotEmpty) {
        final QuerySnapshot statusesSnapshot = await _firestore
            .collection(Constants.statuses)
            .where('uid', whereIn: contactIds)
            .get();
        
        for (final doc in statusesSnapshot.docs) {
          final StatusModel status = StatusModel.fromMap(
            doc.data() as Map<String, dynamic>
          );
          
          // Filter out items older than 24 hours
          final List<StatusItemModel> activeItems = status.items
              .where((item) => now.difference(item.timestamp).inHours < 24)
              .toList();
          
          if (activeItems.isNotEmpty) {
            final StatusModel activeStatus = StatusModel(
              statusId: status.statusId,
              uid: status.uid,
              userName: status.userName,
              userImage: status.userImage,
              items: activeItems,
              createdAt: status.createdAt,
              expiresAt: status.expiresAt,
            );
            
            _contactStatuses.add(activeStatus);
          } else {
            // If all items are expired, delete the status
            await _firestore.collection(Constants.statuses).doc(status.uid).delete();
          }
        }
        
        // Sort by newest timestamp
        _contactStatuses.sort((a, b) {
          final DateTime latestA = a.items.map((e) => e.timestamp).reduce(
            (value, element) => value.isAfter(element) ? value : element
          );
          final DateTime latestB = b.items.map((e) => e.timestamp).reduce(
            (value, element) => value.isAfter(element) ? value : element
          );
          return latestB.compareTo(latestA);
        });
      }
      
      _isFetching = false;
      notifyListeners();
    } catch (e) {
      _isFetching = false;
      notifyListeners();
      debugPrint('Error fetching statuses: $e');
    }
  }
  
  // Mark status as viewed
  Future<void> markStatusAsViewed({
    required String statusOwnerId,
    required String statusItemId,
    required String viewerId,
  }) async {
    try {
      // Get the current status
      final DocumentSnapshot statusDoc = await _firestore
          .collection(Constants.statuses)
          .doc(statusOwnerId)
          .get();
      
      if (!statusDoc.exists) return;
      
      final StatusModel status = StatusModel.fromMap(
        statusDoc.data() as Map<String, dynamic>
      );
      
      // Find the specific status item
      final int index = status.items.indexWhere((item) => item.itemId == statusItemId);
      
      if (index == -1) return;
      
      // Check if already viewed
      if (status.items[index].viewedBy.contains(viewerId)) return;
      
      // Update viewedBy array
      final List<StatusItemModel> updatedItems = List.from(status.items);
      final StatusItemModel item = updatedItems[index];
      
      // Create updated item with viewer added
      final List<String> newViewedBy = List.from(item.viewedBy)..add(viewerId);
      
      final StatusItemModel updatedItem = StatusItemModel(
        itemId: item.itemId,
        mediaUrl: item.mediaUrl,
        caption: item.caption,
        timestamp: item.timestamp,
        type: item.type,
        viewedBy: newViewedBy,
        reactions: item.reactions,
      );
      
      updatedItems[index] = updatedItem;
      
      // Update Firestore
      await _firestore.collection(Constants.statuses).doc(statusOwnerId).update({
        'items': updatedItems.map((e) => e.toMap()).toList(),
      });
      
      // Update local state if needed
      if (statusOwnerId == _myStatus?.uid) {
        _myStatus = StatusModel(
          statusId: status.statusId,
          uid: status.uid,
          userName: status.userName,
          userImage: status.userImage,
          items: updatedItems,
          createdAt: status.createdAt,
          expiresAt: status.expiresAt,
        );
      } else {
        final int contactIndex = _contactStatuses.indexWhere((s) => s.uid == statusOwnerId);
        if (contactIndex != -1) {
          final List<StatusModel> updatedStatuses = List.from(_contactStatuses);
          updatedStatuses[contactIndex] = StatusModel(
            statusId: status.statusId,
            uid: status.uid,
            userName: status.userName,
            userImage: status.userImage,
            items: updatedItems,
            createdAt: status.createdAt,
            expiresAt: status.expiresAt,
          );
          _contactStatuses = updatedStatuses;
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking status as viewed: $e');
    }
  }
  
  // React to status
  Future<void> addReactionToStatus({
    required String statusOwnerId,
    required String statusItemId,
    required String reactorId,
    required String reactorName,
    required String reaction,
  }) async {
    try {
      // Get the current status
      final DocumentSnapshot statusDoc = await _firestore
          .collection(Constants.statuses)
          .doc(statusOwnerId)
          .get();
      
      if (!statusDoc.exists) return;
      
      final StatusModel status = StatusModel.fromMap(
        statusDoc.data() as Map<String, dynamic>
      );
      
      // Find the specific status item
      final int index = status.items.indexWhere((item) => item.itemId == statusItemId);
      
      if (index == -1) return;
      
      // Update reactions map
      final List<StatusItemModel> updatedItems = List.from(status.items);
      final StatusItemModel item = updatedItems[index];
      
      // Create or update reactions map
      Map<String, String> newReactions = item.reactions != null 
          ? Map.from(item.reactions!)
          : {};
      
      // Add reaction
      newReactions[reactorId] = reaction;
      
      final StatusItemModel updatedItem = StatusItemModel(
        itemId: item.itemId,
        mediaUrl: item.mediaUrl,
        caption: item.caption,
        timestamp: item.timestamp,
        type: item.type,
        viewedBy: item.viewedBy,
        reactions: newReactions,
      );
      
      updatedItems[index] = updatedItem;
      
      // Update Firestore
      await _firestore.collection(Constants.statuses).doc(statusOwnerId).update({
        'items': updatedItems.map((e) => e.toMap()).toList(),
      });
      
      // Update local state if needed
      if (statusOwnerId == _myStatus?.uid) {
        _myStatus = StatusModel(
          statusId: status.statusId,
          uid: status.uid,
          userName: status.userName,
          userImage: status.userImage,
          items: updatedItems,
          createdAt: status.createdAt,
          expiresAt: status.expiresAt,
        );
      } else {
        final int contactIndex = _contactStatuses.indexWhere((s) => s.uid == statusOwnerId);
        if (contactIndex != -1) {
          final List<StatusModel> updatedStatuses = List.from(_contactStatuses);
          updatedStatuses[contactIndex] = StatusModel(
            statusId: status.statusId,
            uid: status.uid,
            userName: status.userName,
            userImage: status.userImage,
            items: updatedItems,
            createdAt: status.createdAt,
            expiresAt: status.expiresAt,
          );
          _contactStatuses = updatedStatuses;
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding reaction to status: $e');
    }
  }
}
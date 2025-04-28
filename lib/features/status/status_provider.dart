// lib/features/status/providers/status_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/status/widgets/status_enums.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/status_post_model.dart';
import 'package:textgb/models/message_model.dart';
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
  
  /// Get a list of users with active status posts
  List<String> get usersWithStatus => _userStatusMap.keys.toList();
  
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
        
        // Filter based on privacy settings
        bool canView = statusPost.canBeViewedBy(currentUserId, contactIds);
        
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
      
      // Apply filter sorting to the map
      _applyFilterToMap(groupedStatuses, currentUserId);
      
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
  
  /// Apply filter sorting to the status map
  void _applyFilterToMap(Map<String, List<StatusPostModel>> map, String currentUserId) {
    // Convert to a list of entries for sorting
    List<MapEntry<String, List<StatusPostModel>>> entries = map.entries.toList();
    
    switch (_currentFilter) {
      case FeedFilterType.viewed:
        // Sort by viewed status - users whose statuses have been viewed first
        entries.sort((a, b) {
          bool aAllViewed = a.value.every((status) => status.isViewedBy(currentUserId));
          bool bAllViewed = b.value.every((status) => status.isViewedBy(currentUserId));
          
          if (aAllViewed && !bAllViewed) return 1;
          if (!aAllViewed && bAllViewed) return -1;
          
          // If both viewed or both unviewed, sort by most recent status
          DateTime aLatest = a.value.map((s) => s.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
          DateTime bLatest = b.value.map((s) => s.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
          
          return bLatest.compareTo(aLatest);
        });
        break;
        
      case FeedFilterType.unviewed:
        // Sort by unviewed status - users whose statuses haven't been viewed first
        entries.sort((a, b) {
          bool aHasUnviewed = a.value.any((status) => !status.isViewedBy(currentUserId));
          bool bHasUnviewed = b.value.any((status) => !status.isViewedBy(currentUserId));
          
          if (aHasUnviewed && !bHasUnviewed) return -1;
          if (!aHasUnviewed && bHasUnviewed) return 1;
          
          // If both have unviewed or both don't, sort by most recent status
          DateTime aLatest = a.value.map((s) => s.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
          DateTime bLatest = b.value.map((s) => s.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
          
          return bLatest.compareTo(aLatest);
        });
        break;
        
      case FeedFilterType.latest:
      default:
        // Sort by most recent status post
        entries.sort((a, b) {
          DateTime aLatest = a.value.map((s) => s.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
          DateTime bLatest = b.value.map((s) => s.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
          
          return bLatest.compareTo(aLatest);
        });
        break;
    }
    
    // Convert back to map
    map.clear();
    for (var entry in entries) {
      map[entry.key] = entry.value;
    }
  }
  
  /// Mark a status as viewed
  Future<void> viewStatus({
    required String statusId,
    required String viewerUid,
  }) async {
    try {
      // Find the status post in state
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
      final updatedStatus = targetStatus.copyWith(
        viewerUIDs: updatedViewerUIDs,
        viewCount: updatedViewCount,
      );
      
      if (myStatusIndex != -1) {
        _myStatuses[myStatusIndex] = updatedStatus;
      } else if (targetUserUid != null) {
        final userStatusIndex = _userStatusMap[targetUserUid]!.indexWhere((post) => post.statusId == statusId);
        if (userStatusIndex != -1) {
          _userStatusMap[targetUserUid]![userStatusIndex] = updatedStatus;
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error viewing status: $e');
    }
  }
  
  /// Create a new image/video status post
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
        privacyType: privacyType,
        includedContactUIDs: includedContactUIDs,
        excludedContactUIDs: excludedContactUIDs,
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
      
      // Create status post model
      final statusPost = StatusPostModel(
        statusId: statusId,
        uid: uid,
        username: username,
        userImage: userImage,
        type: StatusType.text,
        caption: text,
        backgroundColor: backgroundColor,
        fontName: fontName,
        createdAt: createdAt,
        expiresAt: expiresAt,
        privacyType: privacyType,
        includedContactUIDs: includedContactUIDs,
        excludedContactUIDs: excludedContactUIDs,
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
      
      // Extract link preview information (title, image)
      String? linkTitle;
      String? linkPreviewImage;
      
      try {
        // Fetch link content for preview
        final response = await http.get(Uri.parse(linkUrl));
        if (response.statusCode == 200) {
          final document = html_parser.parse(response.body);
          
          // Try to get title
          final titleElement = document.querySelector('title');
          if (titleElement != null) {
            linkTitle = titleElement.text;
          }
          
          // Try to get preview image
          final ogImageElement = document.querySelector('meta[property="og:image"]');
          if (ogImageElement != null) {
            final imgUrl = ogImageElement.attributes['content'];
            if (imgUrl != null) {
              // Download and store the preview image
              final imgResponse = await http.get(Uri.parse(imgUrl));
              if (imgResponse.statusCode == 200) {
                final tempDir = await getTemporaryDirectory();
                final tempFile = File('${tempDir.path}/link_preview_$statusId.jpg');
                await tempFile.writeAsBytes(imgResponse.bodyBytes);
                
                // Upload preview image to storage
                final reference = 'statusFiles/$uid/$statusId/link_preview.jpg';
                linkPreviewImage = await storeFileToStorage(
                  file: tempFile,
                  reference: reference,
                );
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error extracting link preview: $e');
        // Continue without preview
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
        type: StatusType.link,
        caption: caption,
        linkUrl: linkUrl,
        linkTitle: linkTitle,
        linkPreviewImage: linkPreviewImage,
        createdAt: createdAt,
        expiresAt: expiresAt,
        privacyType: privacyType,
        includedContactUIDs: includedContactUIDs,
        excludedContactUIDs: excludedContactUIDs,
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
      
      // Delete link preview image if it exists
      if (status.linkPreviewImage != null) {
        try {
          final ref = _storage.refFromURL(status.linkPreviewImage!);
          await ref.delete();
        } catch (e) {
          debugPrint('Error deleting link preview: $e');
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
  
  /// Send a reply to a status as a chat message
  Future<void> sendStatusReply({
    required String statusId,
    required String replyMessage,
    required String senderUid,
    required String senderName,
    required String senderImage,
    required String recipientUid,
    required String recipientName,
    required String recipientImage,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Find the status post
      StatusPostModel? targetStatus;
      
      // Check if it's one of the sender's statuses (unlikely but handle anyway)
      if (senderUid == recipientUid) {
        final statusIndex = _myStatuses.indexWhere((post) => post.statusId == statusId);
        if (statusIndex != -1) {
          targetStatus = _myStatuses[statusIndex];
        }
      } else {
        // Check in other users' statuses
        if (_userStatusMap.containsKey(recipientUid)) {
          final statusIndex = _userStatusMap[recipientUid]!.indexWhere((post) => post.statusId == statusId);
          if (statusIndex != -1) {
            targetStatus = _userStatusMap[recipientUid]![statusIndex];
          }
        }
      }
      
      if (targetStatus == null) {
        throw Exception('Status not found');
      }
      
      // Get thumbnail URL based on status type
      String? thumbnailUrl;
      if (targetStatus.type == StatusType.image || targetStatus.type == StatusType.video) {
        thumbnailUrl = targetStatus.mediaUrls.isNotEmpty ? targetStatus.mediaUrls.first : null;
      } else if (targetStatus.type == StatusType.link && targetStatus.linkPreviewImage != null) {
        thumbnailUrl = targetStatus.linkPreviewImage;
      }
      
      // Create a message ID
      final messageId = _uuid.v4();
      
      // Create a message model for the chat
      final messageModel = MessageModel(
        messageId: messageId,
        senderUID: senderUid,
        senderName: senderName,
        senderImage: senderImage,
        contactUID: recipientUid,
        message: replyMessage,
        messageType: MessageEnum.text,
        timeSent: DateTime.now(),
        isSeen: true,
        repliedMessage: '',
        repliedTo: '',
        repliedMessageType: null,
        reactions: [],
        isSeenBy: [senderUid],
        deletedBy: [],
        isStatusReply: true,
        statusId: statusId,
        statusItemId: targetStatus.statusId,
        statusThumbnailUrl: thumbnailUrl,
        statusCaption: targetStatus.caption,
      );
      
      // Save to Firestore using the structure in ChatProvider
      
      // 1. initialize last message data for the sender
      final Map<String, dynamic> senderLastMessageData = {
        Constants.senderUID: senderUid,
        Constants.contactUID: recipientUid,
        Constants.contactName: recipientName,
        Constants.contactImage: recipientImage,
        Constants.message: replyMessage,
        Constants.messageType: MessageEnum.text.name,
        Constants.timeSent: DateTime.now().millisecondsSinceEpoch,
        Constants.isSeen: true, // Always true for privacy
      };

      // 2. initialize last message data for the recipient
      final Map<String, dynamic> recipientLastMessageData = {
        Constants.senderUID: senderUid,
        Constants.contactUID: senderUid,
        Constants.contactName: senderName,
        Constants.contactImage: senderImage,
        Constants.message: replyMessage,
        Constants.messageType: MessageEnum.text.name,
        Constants.timeSent: DateTime.now().millisecondsSinceEpoch,
        Constants.isSeen: true, // Always true for privacy
      };
      
      // Run as a batch operation for better consistency
      final batch = _firestore.batch();
      
      // 3. send message to sender firestore location
      final senderMessageRef = _firestore
          .collection(Constants.users)
          .doc(senderUid)
          .collection(Constants.chats)
          .doc(recipientUid)
          .collection(Constants.messages)
          .doc(messageId);
          
      batch.set(senderMessageRef, messageModel.toMap());
      
      // 4. send message to recipient firestore location
      final recipientMessageRef = _firestore
          .collection(Constants.users)
          .doc(recipientUid)
          .collection(Constants.chats)
          .doc(senderUid)
          .collection(Constants.messages)
          .doc(messageId);
          
      batch.set(recipientMessageRef, messageModel.toMap());

      // 5. send the last message to sender firestore location
      final senderLastMessageRef = _firestore
          .collection(Constants.users)
          .doc(senderUid)
          .collection(Constants.chats)
          .doc(recipientUid);
          
      batch.set(senderLastMessageRef, senderLastMessageData, SetOptions(merge: true));

      // 6. send the last message to recipient firestore location
      final recipientLastMessageRef = _firestore
          .collection(Constants.users)
          .doc(recipientUid)
          .collection(Constants.chats)
          .doc(senderUid);
          
      batch.set(recipientLastMessageRef, recipientLastMessageData, SetOptions(merge: true));
      
      // Commit the batch
      await batch.commit();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error sending status reply: $e');
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
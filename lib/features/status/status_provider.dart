import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/status_model.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:uuid/uuid.dart';

part 'status_provider.g.dart';

// State class for status features
class StatusState {
  final bool isLoading;
  final bool isFetching;
  final bool statusTabVisible;
  final bool appFreshStart;
  final List<StatusModel> contactStatuses;
  final StatusModel? myStatus;
  final int unreadRepliesCount;
  final String? error;

  const StatusState({
    this.isLoading = false,
    this.isFetching = false,
    this.statusTabVisible = false,
    this.appFreshStart = true,
    this.contactStatuses = const [],
    this.myStatus,
    this.unreadRepliesCount = 0,
    this.error,
  });

  StatusState copyWith({
    bool? isLoading,
    bool? isFetching,
    bool? statusTabVisible,
    bool? appFreshStart,
    List<StatusModel>? contactStatuses,
    StatusModel? myStatus,
    int? unreadRepliesCount,
    String? error,
  }) {
    return StatusState(
      isLoading: isLoading ?? this.isLoading,
      isFetching: isFetching ?? this.isFetching,
      statusTabVisible: statusTabVisible ?? this.statusTabVisible,
      appFreshStart: appFreshStart ?? this.appFreshStart,
      contactStatuses: contactStatuses ?? this.contactStatuses,
      myStatus: myStatus,
      unreadRepliesCount: unreadRepliesCount ?? this.unreadRepliesCount,
      error: error,
    );
  }
}

@riverpod
class StatusNotifier extends _$StatusNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  FutureOr<StatusState> build() {
    return const StatusState();
  }

  // Set status tab visible
  void setStatusTabVisible(bool visible) {
    state = AsyncValue.data(state.value!.copyWith(statusTabVisible: visible));
  }
  
  // Set app fresh start
  void setAppFreshStart(bool value) {
    state = AsyncValue.data(state.value!.copyWith(appFreshStart: value));
  }

  // Create a text status
  Future<void> createTextStatus({
    required UserModel currentUser,
    required String text,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    try {
      state = AsyncValue.data(state.value!.copyWith(isLoading: true));
      
      if (text.trim().isEmpty) {
        state = AsyncValue.data(state.value!.copyWith(isLoading: false));
        onError('Text cannot be empty');
        return;
      }
      
      // Generate unique IDs
      final String statusId = const Uuid().v4();
      final String itemId = const Uuid().v4();
      
      // For text status, we use the text as the mediaUrl
      final StatusItemModel statusItem = StatusItemModel(
        itemId: itemId,
        mediaUrl: text,  // Text content goes here
        caption: null,   // No need for caption
        timestamp: DateTime.now(),
        type: StatusType.text,
        viewedBy: [currentUser.uid],  // Creator has viewed it
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
        final existingStatus = StatusModel.fromMap(
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
          'items': activeItems.map((item) => item.toMap()).toList(),
          'expiresAt': expiryTime.millisecondsSinceEpoch,
        });
        
        // Update local state
        final newMyStatus = StatusModel(
          statusId: existingStatus.statusId,
          uid: currentUser.uid,
          userName: currentUser.name,
          userImage: currentUser.image,
          items: activeItems,
          createdAt: existingStatus.createdAt,
          expiresAt: expiryTime,
        );
        
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
          myStatus: newMyStatus,
        ));
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
            
        // Update local state
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
          myStatus: newStatus,
        ));
      }
      
      onSuccess();
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
      onError(e.toString());
    }
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
      state = AsyncValue.data(state.value!.copyWith(isLoading: true));
      
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
        
        // Update local state
        final updatedStatus = StatusModel(
          statusId: existingStatus.statusId,
          uid: currentUser.uid,
          userName: currentUser.name,
          userImage: currentUser.image,
          items: activeItems,
          createdAt: existingStatus.createdAt,
          expiresAt: expiryTime,
        );
        
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
          myStatus: updatedStatus,
        ));
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
            
        // Update local state
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
          myStatus: newStatus,
        ));
      }
      
      onSuccess();
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
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
      state = AsyncValue.data(state.value!.copyWith(isLoading: true));
      
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
        // Update local state
        final currentState = state.value!;
        if (currentState.myStatus?.uid == userId) {
          state = AsyncValue.data(currentState.copyWith(
            isLoading: false, 
            myStatus: null,
          ));
        }
      } else {
        // Update with remaining items
        await _firestore.collection(Constants.statuses).doc(userId).update({
          'items': updatedItems.map((e) => e.toMap()).toList(),
        });
        
        // Update local state if needed
        final currentState = state.value!;
        if (currentState.myStatus?.uid == userId) {
          final updatedStatus = StatusModel(
            statusId: status.statusId,
            uid: status.uid,
            userName: status.userName,
            userImage: status.userImage,
            items: updatedItems,
            createdAt: status.createdAt,
            expiresAt: status.expiresAt,
          );
          
          state = AsyncValue.data(currentState.copyWith(
            isLoading: false,
            myStatus: updatedStatus,
          ));
        }
      }
      
      onSuccess();
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
      onError(e.toString());
    }
  }
  
  // Fetch all statuses (my status + contacts' statuses)
  Future<void> fetchStatuses({
    required String currentUserId,
    required List<String> contactIds,
  }) async {
    try {
      state = AsyncValue.data(state.value!.copyWith(isFetching: true));
      
      // Current time to filter expired statuses
      final DateTime now = DateTime.now();
      List<StatusModel> updatedContactStatuses = [];
      StatusModel? updatedMyStatus;
      
      // Fetch my status
      final DocumentSnapshot myStatusDoc = await _firestore
          .collection(Constants.statuses)
          .doc(currentUserId)
          .get();
      
      if (myStatusDoc.exists) {
        final StatusModel status = StatusModel.fromMap(
          myStatusDoc.data() as Map<String, dynamic>
        );
        
        // Check if the entire status is expired based on expiresAt
        if (now.isAfter(status.expiresAt)) {
          // If status is expired, delete it
          await _firestore.collection(Constants.statuses).doc(currentUserId).delete();
        } else {
          // Filter out individual items older than 24 hours
          final List<StatusItemModel> activeItems = status.items
              .where((item) => now.difference(item.timestamp).inHours < 24)
              .toList();
          
          if (activeItems.isNotEmpty) {
            updatedMyStatus = StatusModel(
              statusId: status.statusId,
              uid: status.uid,
              userName: status.userName,
              userImage: status.userImage,
              items: activeItems,
              createdAt: status.createdAt,
              expiresAt: status.expiresAt,
            );
          } else {
            // If all items are expired, delete the status
            await _firestore.collection(Constants.statuses).doc(currentUserId).delete();
          }
        }
      }
      
      // Fetch contacts' statuses only if there are contacts
      if (contactIds.isNotEmpty) {
        // Breaking up the contactIds into chunks of max size 10 due to Firestore limitations
        // Firestore 'in' queries can only handle up to 10 items at a time
        for (int i = 0; i < contactIds.length; i += 10) {
          final List<String> chunk = contactIds.sublist(i, 
              i + 10 < contactIds.length ? i + 10 : contactIds.length);
              
          final QuerySnapshot statusesSnapshot = await _firestore
              .collection(Constants.statuses)
              .where('uid', whereIn: chunk)
              .get();
          
          for (final doc in statusesSnapshot.docs) {
            final StatusModel status = StatusModel.fromMap(
              doc.data() as Map<String, dynamic>
            );
            
            // Check if the entire status is expired based on expiresAt
            if (now.isAfter(status.expiresAt)) {
              // If status is expired, delete it
              await _firestore.collection(Constants.statuses).doc(status.uid).delete();
              continue;
            }
            
            // Filter out individual items older than 24 hours
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
              
              updatedContactStatuses.add(activeStatus);
            } else {
              // If all items are expired, delete the status
              await _firestore.collection(Constants.statuses).doc(status.uid).delete();
            }
          }
        }
        
        // Sort by newest timestamp
        updatedContactStatuses.sort((a, b) {
          final DateTime latestA = a.items.map((e) => e.timestamp).reduce(
            (value, element) => value.isAfter(element) ? value : element
          );
          final DateTime latestB = b.items.map((e) => e.timestamp).reduce(
            (value, element) => value.isAfter(element) ? value : element
          );
          return latestB.compareTo(latestA);
        });
      }
      
      // Count unread replies for status owner
      int unreadCount = 0;
      if (updatedMyStatus != null) {
        unreadCount = await _countUnreadStatusReplies(currentUserId);
      }
      
      state = AsyncValue.data(state.value!.copyWith(
        isFetching: false,
        myStatus: updatedMyStatus,
        contactStatuses: updatedContactStatuses,
        unreadRepliesCount: unreadCount,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isFetching: false,
        error: e.toString(),
      ));
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
      final currentState = state.value!;
      if (statusOwnerId == currentState.myStatus?.uid) {
        final updatedStatus = StatusModel(
          statusId: status.statusId,
          uid: status.uid,
          userName: status.userName,
          userImage: status.userImage,
          items: updatedItems,
          createdAt: status.createdAt,
          expiresAt: status.expiresAt,
        );
        
        state = AsyncValue.data(currentState.copyWith(myStatus: updatedStatus));
      } else {
        final int contactIndex = currentState.contactStatuses.indexWhere((s) => s.uid == statusOwnerId);
        if (contactIndex != -1) {
          final List<StatusModel> updatedStatuses = List.from(currentState.contactStatuses);
          updatedStatuses[contactIndex] = StatusModel(
            statusId: status.statusId,
            uid: status.uid,
            userName: status.userName,
            userImage: status.userImage,
            items: updatedItems,
            createdAt: status.createdAt,
            expiresAt: status.expiresAt,
          );
          
          state = AsyncValue.data(currentState.copyWith(contactStatuses: updatedStatuses));
        }
      }
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
      final currentState = state.value!;
      if (statusOwnerId == currentState.myStatus?.uid) {
        final updatedStatus = StatusModel(
          statusId: status.statusId,
          uid: status.uid,
          userName: status.userName,
          userImage: status.userImage,
          items: updatedItems,
          createdAt: status.createdAt,
          expiresAt: status.expiresAt,
        );
        
        state = AsyncValue.data(currentState.copyWith(myStatus: updatedStatus));
      } else {
        final int contactIndex = currentState.contactStatuses.indexWhere((s) => s.uid == statusOwnerId);
        if (contactIndex != -1) {
          final List<StatusModel> updatedStatuses = List.from(currentState.contactStatuses);
          updatedStatuses[contactIndex] = StatusModel(
            statusId: status.statusId,
            uid: status.uid,
            userName: status.userName,
            userImage: status.userImage,
            items: updatedItems,
            createdAt: status.createdAt,
            expiresAt: status.expiresAt,
          );
          
          state = AsyncValue.data(currentState.copyWith(contactStatuses: updatedStatuses));
        }
      }
    } catch (e) {
      debugPrint('Error adding reaction to status: $e');
    }
  }
  
  // Reply to status (integrated with chat system)
  Future<void> replyToStatus({
    required String statusId,
    required String statusItemId,
    required String statusOwnerId,
    required StatusItemModel statusItem,
    required String senderId,
    required String senderName,
    required String senderImage,
    required String message,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    try {
      state = AsyncValue.data(state.value!.copyWith(isLoading: true));
      
      // Generate unique message ID
      final String messageId = const Uuid().v4();
      
      // Get status owner data
      DocumentSnapshot ownerDoc = await _firestore
          .collection(Constants.users)
          .doc(statusOwnerId)
          .get();
      
      if (!ownerDoc.exists) {
        throw Exception('Status owner not found');
      }
      
      UserModel statusOwner = UserModel.fromMap(ownerDoc.data() as Map<String, dynamic>);
      
      // Get sender data
      DocumentSnapshot senderDoc = await _firestore
          .collection(Constants.users)
          .doc(senderId)
          .get();
      
      if (!senderDoc.exists) {
        throw Exception('Sender not found');
      }
      
      UserModel sender = UserModel.fromMap(senderDoc.data() as Map<String, dynamic>);
      
      // Determine thumbnail URL based on status type
      String thumbnailUrl = statusItem.mediaUrl;
      
      // Current timestamp
      final DateTime now = DateTime.now();
      
      // 1. Create message object for sender
      final messageMapSender = {
        'senderUID': senderId,
        'senderName': senderName,
        'senderImage': senderImage,
        'contactUID': statusOwnerId,
        'message': message,
        'messageType': MessageEnum.text.name,
        'timeSent': now.millisecondsSinceEpoch,
        'messageId': messageId,
        'isSeen': false,
        'repliedMessage': '',
        'repliedTo': '',
        'repliedMessageType': MessageEnum.text.name,
        'reactions': [],
        'isSeenBy': [senderId],
        'deletedBy': [],
        // Status reference data
        'isStatusReply': true,
        'statusId': statusId,
        'statusItemId': statusItemId,
        'statusThumbnailUrl': thumbnailUrl,
        'statusCaption': statusItem.caption,
      };
      
      // 2. Create message object for receiver (status owner)
      final messageMapReceiver = {
        'senderUID': senderId,
        'senderName': senderName,
        'senderImage': senderImage,
        'contactUID': senderId,
        'message': message,
        'messageType': MessageEnum.text.name,
        'timeSent': now.millisecondsSinceEpoch,
        'messageId': messageId,
        'isSeen': false,
        'repliedMessage': '',
        'repliedTo': '',
        'repliedMessageType': MessageEnum.text.name,
        'reactions': [],
        'isSeenBy': [senderId],
        'deletedBy': [],
        // Status reference data
        'isStatusReply': true,
        'statusId': statusId,
        'statusItemId': statusItemId,
        'statusThumbnailUrl': thumbnailUrl,
        'statusCaption': statusItem.caption,
      };
      
      // 3. Create last message for sender
      final lastMessageMapSender = {
        'senderUID': senderId,
        'contactUID': statusOwnerId,
        'contactName': statusOwner.name,
        'contactImage': statusOwner.image,
        'message': message,
        'messageType': MessageEnum.text.name,
        'timeSent': now.millisecondsSinceEpoch,
        'isSeen': false,
      };
      
      // 4. Create last message for receiver
      final lastMessageMapReceiver = {
        'senderUID': senderId,
        'contactUID': senderId,
        'contactName': senderName,
        'contactImage': senderImage,
        'message': message,
        'messageType': MessageEnum.text.name,
        'timeSent': now.millisecondsSinceEpoch,
        'isSeen': false,
      };
      
      // 5. Use transaction to ensure all updates are atomic
      await _firestore.runTransaction((transaction) async {
        // Add message to sender's chat
        transaction.set(
          _firestore
              .collection(Constants.users)
              .doc(senderId)
              .collection(Constants.chats)
              .doc(statusOwnerId)
              .collection(Constants.messages)
              .doc(messageId),
          messageMapSender,
        );
        
        // Add message to receiver's chat
        transaction.set(
          _firestore
              .collection(Constants.users)
              .doc(statusOwnerId)
              .collection(Constants.chats)
              .doc(senderId)
              .collection(Constants.messages)
              .doc(messageId),
          messageMapReceiver,
        );
        
        // Update last message for sender
        transaction.set(
          _firestore
              .collection(Constants.users)
              .doc(senderId)
              .collection(Constants.chats)
              .doc(statusOwnerId),
          lastMessageMapSender,
        );
        
        // Update last message for receiver
        transaction.set(
          _firestore
              .collection(Constants.users)
              .doc(statusOwnerId)
              .collection(Constants.chats)
              .doc(senderId),
          lastMessageMapReceiver,
        );
      });
      
      state = AsyncValue.data(state.value!.copyWith(isLoading: false));
      onSuccess();
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
      onError(e.toString());
      debugPrint('Error replying to status: $e');
    }
  }
  
  // Count unread status replies for notification badge
  Future<int> _countUnreadStatusReplies(String userId) async {
    try {
      int count = 0;
      
      // Check all chats for the user
      final QuerySnapshot chatSnapshot = await _firestore
          .collection(Constants.users)
          .doc(userId)
          .collection(Constants.chats)
          .get();
      
      // For each chat, check for unread status replies
      for (final chatDoc in chatSnapshot.docs) {
        final contactId = chatDoc.id;
        
        // Get last 20 messages from this chat
        final QuerySnapshot messageSnapshot = await _firestore
            .collection(Constants.users)
            .doc(userId)
            .collection(Constants.chats)
            .doc(contactId)
            .collection(Constants.messages)
            .where('isStatusReply', isEqualTo: true)
            .where('isSeen', isEqualTo: false)
            .where('senderUID', isNotEqualTo: userId)
            .limit(20)
            .get();
        
        // Add to unread count
        count += messageSnapshot.docs.length;
      }
      
      return count;
    } catch (e) {
      debugPrint('Error counting unread status replies: $e');
      return 0;
    }
  }
}
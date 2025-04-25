import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/channels/channel_model.dart';
import 'package:textgb/features/channels/channel_post_model.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:uuid/uuid.dart';

class ChannelProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  List<ChannelModel> _subscribedChannels = [];
  List<ChannelModel> get subscribedChannels => _subscribedChannels;
  
  List<ChannelModel> _exploreChannels = [];
  List<ChannelModel> get exploreChannels => _exploreChannels;
  
  ChannelModel? _selectedChannel;
  ChannelModel? get selectedChannel => _selectedChannel;
  
  List<ChannelPostModel> _channelPosts = [];
  List<ChannelPostModel> get channelPosts => _channelPosts;
  
  void setSelectedChannel(ChannelModel channel) {
    _selectedChannel = channel;
    notifyListeners();
  }
  
  // Create a new channel
  Future<void> createChannel({
    required String name,
    required String description,
    required String creatorUID,
    required File? channelImage,
    required Function onSuccess,
    required Function(String) onFail,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Generate a unique ID for the channel
      String channelId = const Uuid().v4();
      
      // Default settings for a new channel
      Map<String, dynamic> settings = {
        'allowReactions': true,
        'showSubscriberCount': true,
      };
      
      String imageUrl = '';
      
      // Upload channel image if provided
      if (channelImage != null) {
        imageUrl = await storeFileToStorage(
          file: channelImage,
          reference: '${Constants.channelFiles}/$channelId',
        );
      }
      
      // Create channel model
      ChannelModel channelModel = ChannelModel(
        id: channelId,
        name: name,
        description: description,
        image: imageUrl,
        creatorUID: creatorUID,
        isVerified: false, // Only admin can verify channels
        subscribersUIDs: [creatorUID], // Creator is automatically a subscriber
        adminUIDs: [creatorUID], // Creator is automatically an admin
        createdAt: DateTime.now().millisecondsSinceEpoch.toString(),
        lastPostAt: DateTime.now().millisecondsSinceEpoch.toString(),
        settings: settings,
      );
      
      // Save channel to Firestore
      await _firestore
          .collection(Constants.channels)
          .doc(channelId)
          .set(channelModel.toMap());
      
      // Add channel to user's subscribed channels
      await _firestore
          .collection(Constants.users)
          .doc(creatorUID)
          .collection(Constants.subscribedChannels)
          .doc(channelId)
          .set({
        Constants.channelId: channelId,
        Constants.createdAt: DateTime.now().millisecondsSinceEpoch.toString(),
      });
      
      _isLoading = false;
      notifyListeners();
      onSuccess();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      onFail(e.toString());
    }
  }
  
  // Update channel information
  Future<void> updateChannel({
    required ChannelModel updatedChannel,
    File? newChannelImage,
    required Function onSuccess,
    required Function(String) onFail,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      String imageUrl = updatedChannel.image;
      
      // Upload new image if provided
      if (newChannelImage != null) {
        imageUrl = await storeFileToStorage(
          file: newChannelImage,
          reference: '${Constants.channelFiles}/${updatedChannel.id}',
        );
      }
      
      // Update with new image URL if changed
      ChannelModel finalUpdatedChannel = updatedChannel.copyWith(
        image: imageUrl,
      );
      
      // Update in Firestore
      await _firestore
          .collection(Constants.channels)
          .doc(updatedChannel.id)
          .update(finalUpdatedChannel.toMap());
      
      // Update selected channel if it's the one being edited
      if (_selectedChannel != null && _selectedChannel!.id == updatedChannel.id) {
        _selectedChannel = finalUpdatedChannel;
      }
      
      _isLoading = false;
      notifyListeners();
      onSuccess();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      onFail(e.toString());
    }
  }
  
  // Create a new post in a channel
  Future<void> createChannelPost({
    required String channelId,
    required String creatorUID,
    required String message,
    required MessageEnum messageType,
    required File? mediaFile,
    required Function onSuccess,
    required Function(String) onFail,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Generate a unique ID for the post
      String postId = const Uuid().v4();
      String mediaUrl = '';
      
      // Upload media file if provided
      if (mediaFile != null) {
        mediaUrl = await storeFileToStorage(
          file: mediaFile,
          reference: '${Constants.channelFiles}/$channelId/posts/$postId',
        );
      }
      
      // Create post model
      ChannelPostModel postModel = ChannelPostModel(
        id: postId,
        channelId: channelId,
        creatorUID: creatorUID,
        message: message,
        messageType: messageType,
        mediaUrl: mediaUrl,
        createdAt: DateTime.now().millisecondsSinceEpoch.toString(),
        reactions: {},
        viewCount: 0,
        isPinned: false,
      );
      
      // Save post to Firestore
      await _firestore
          .collection(Constants.channels)
          .doc(channelId)
          .collection(Constants.channelPosts)
          .doc(postId)
          .set(postModel.toMap());
      
      // Update channel's lastPostAt
      await _firestore
          .collection(Constants.channels)
          .doc(channelId)
          .update({
        Constants.lastPostAt: DateTime.now().millisecondsSinceEpoch.toString(),
      });
      
      // Refresh posts list if needed
      if (_selectedChannel != null && _selectedChannel!.id == channelId) {
        await fetchChannelPosts(channelId: channelId);
        
        // Update selected channel with new lastPostAt
        _selectedChannel = _selectedChannel!.copyWith(
          lastPostAt: DateTime.now().millisecondsSinceEpoch.toString(),
        );
      }
      
      _isLoading = false;
      notifyListeners();
      onSuccess();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      onFail(e.toString());
    }
  }
  
  // Subscribe to a channel
  Future<void> subscribeToChannel({
    required String channelId,
    required String userId,
    required Function onSuccess,
    required Function(String) onFail,
  }) async {
    try {
      // Add user to channel's subscribers
      await _firestore
          .collection(Constants.channels)
          .doc(channelId)
          .update({
        Constants.subscribersUIDs: FieldValue.arrayUnion([userId]),
      });
      
      // Add channel to user's subscribed channels
      await _firestore
          .collection(Constants.users)
          .doc(userId)
          .collection(Constants.subscribedChannels)
          .doc(channelId)
          .set({
        Constants.channelId: channelId,
        Constants.createdAt: DateTime.now().millisecondsSinceEpoch.toString(),
      });
      
      // Update local data if needed
      if (_selectedChannel != null && _selectedChannel!.id == channelId) {
        List<String> updatedSubscribers = List.from(_selectedChannel!.subscribersUIDs);
        updatedSubscribers.add(userId);
        
        _selectedChannel = _selectedChannel!.copyWith(
          subscribersUIDs: updatedSubscribers,
        );
      }
      
      // Refresh subscribed channels
      await fetchSubscribedChannels(userId: userId);
      
      notifyListeners();
      onSuccess();
    } catch (e) {
      onFail(e.toString());
    }
  }
  
  // Unsubscribe from a channel
  Future<void> unsubscribeFromChannel({
    required String channelId,
    required String userId,
    required Function onSuccess,
    required Function(String) onFail,
  }) async {
    try {
      // Remove user from channel's subscribers
      await _firestore
          .collection(Constants.channels)
          .doc(channelId)
          .update({
        Constants.subscribersUIDs: FieldValue.arrayRemove([userId]),
      });
      
      // Remove channel from user's subscribed channels
      await _firestore
          .collection(Constants.users)
          .doc(userId)
          .collection(Constants.subscribedChannels)
          .doc(channelId)
          .delete();
      
      // Update local data if needed
      if (_selectedChannel != null && _selectedChannel!.id == channelId) {
        List<String> updatedSubscribers = List.from(_selectedChannel!.subscribersUIDs);
        updatedSubscribers.remove(userId);
        
        _selectedChannel = _selectedChannel!.copyWith(
          subscribersUIDs: updatedSubscribers,
        );
      }
      
      // Refresh subscribed channels
      await fetchSubscribedChannels(userId: userId);
      
      notifyListeners();
      onSuccess();
    } catch (e) {
      onFail(e.toString());
    }
  }
  
  // Fetch channels that a user has subscribed to
  Future<void> fetchSubscribedChannels({
    required String userId,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Get IDs of subscribed channels
      QuerySnapshot subscribedSnapshot = await _firestore
          .collection(Constants.users)
          .doc(userId)
          .collection(Constants.subscribedChannels)
          .get();
      
      List<String> subscribedChannelIds = subscribedSnapshot.docs
          .map((doc) => doc[Constants.channelId] as String)
          .toList();
      
      // Fetch channel data for each ID
      _subscribedChannels = [];
      
      for (String channelId in subscribedChannelIds) {
        DocumentSnapshot channelDoc = await _firestore
            .collection(Constants.channels)
            .doc(channelId)
            .get();
        
        if (channelDoc.exists) {
          _subscribedChannels.add(
            ChannelModel.fromMap(channelDoc.data() as Map<String, dynamic>),
          );
        }
      }
      
      // Sort by lastPostAt (most recent first)
      _subscribedChannels.sort((a, b) {
        int timeA = int.parse(a.lastPostAt);
        int timeB = int.parse(b.lastPostAt);
        return timeB.compareTo(timeA);
      });
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error fetching subscribed channels: $e');
    }
  }
  
  // Fetch posts for a specific channel
  Future<void> fetchChannelPosts({
    required String channelId,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      QuerySnapshot postsSnapshot = await _firestore
          .collection(Constants.channels)
          .doc(channelId)
          .collection(Constants.channelPosts)
          .orderBy(Constants.createdAt, descending: true)
          .get();
      
      _channelPosts = postsSnapshot.docs
          .map((doc) => ChannelPostModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error fetching channel posts: $e');
    }
  }
  
  // Fetch popular/trending channels for explore page
  Future<void> fetchExploreChannels() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Fetch channels ordered by subscriber count (limit to 50)
      QuerySnapshot exploreSnapshot = await _firestore
          .collection(Constants.channels)
          .orderBy(Constants.subscribersUIDs, descending: true)
          .limit(50)
          .get();
      
      _exploreChannels = exploreSnapshot.docs
          .map((doc) => ChannelModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error fetching explore channels: $e');
    }
  }
  
  // React to a post
  Future<void> reactToPost({
    required String channelId,
    required String postId,
    required String userId,
    required String reaction,
    required Function onSuccess,
    required Function(String) onFail,
  }) async {
    try {
      // Update the post's reactions
      Map<String, dynamic> update = {
        '${Constants.reactions}.$userId': reaction,
      };
      
      await _firestore
          .collection(Constants.channels)
          .doc(channelId)
          .collection(Constants.channelPosts)
          .doc(postId)
          .update(update);
      
      // Update local data if needed
      int index = _channelPosts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        Map<String, String> updatedReactions = Map.from(_channelPosts[index].reactions);
        updatedReactions[userId] = reaction;
        
        _channelPosts[index] = _channelPosts[index].copyWith(
          reactions: updatedReactions,
        );
        
        notifyListeners();
      }
      
      onSuccess();
    } catch (e) {
      onFail(e.toString());
    }
  }
  
  // Remove a reaction from a post
  Future<void> removeReaction({
    required String channelId,
    required String postId,
    required String userId,
    required Function onSuccess,
    required Function(String) onFail,
  }) async {
    try {
      // Remove the user's reaction
      await _firestore
          .collection(Constants.channels)
          .doc(channelId)
          .collection(Constants.channelPosts)
          .doc(postId)
          .update({
        '${Constants.reactions}.$userId': FieldValue.delete(),
      });
      
      // Update local data if needed
      int index = _channelPosts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        Map<String, String> updatedReactions = Map.from(_channelPosts[index].reactions);
        updatedReactions.remove(userId);
        
        _channelPosts[index] = _channelPosts[index].copyWith(
          reactions: updatedReactions,
        );
        
        notifyListeners();
      }
      
      onSuccess();
    } catch (e) {
      onFail(e.toString());
    }
  }
  
  // Increment post view count
  Future<void> incrementPostViewCount({
    required String channelId,
    required String postId,
  }) async {
    try {
      await _firestore
          .collection(Constants.channels)
          .doc(channelId)
          .collection(Constants.channelPosts)
          .doc(postId)
          .update({
        Constants.postViewCount: FieldValue.increment(1),
      });
      
      // Update local data if needed
      int index = _channelPosts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        _channelPosts[index] = _channelPosts[index].copyWith(
          viewCount: _channelPosts[index].viewCount + 1,
        );
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }
  
  // Pin or unpin a post
  Future<void> togglePinPost({
    required String channelId,
    required String postId,
    required bool isPinned,
    required Function onSuccess,
    required Function(String) onFail,
  }) async {
    try {
      await _firestore
          .collection(Constants.channels)
          .doc(channelId)
          .collection(Constants.channelPosts)
          .doc(postId)
          .update({
        Constants.isPinned: isPinned,
      });
      
      // Update local data if needed
      int index = _channelPosts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        _channelPosts[index] = _channelPosts[index].copyWith(
          isPinned: isPinned,
        );
        
        // Re-sort posts to show pinned ones at the top
        _channelPosts.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          
          // If both have same pin status, sort by creation date (newest first)
          int timeA = int.parse(a.createdAt);
          int timeB = int.parse(b.createdAt);
          return timeB.compareTo(timeA);
        });
        
        notifyListeners();
      }
      
      onSuccess();
    } catch (e) {
      onFail(e.toString());
    }
  }
  
  // Check if user is admin of a channel
  bool isUserAdmin(String userId, String channelId) {
    // Check in selected channel
    if (_selectedChannel != null && _selectedChannel!.id == channelId) {
      return _selectedChannel!.adminUIDs.contains(userId);
    }
    
    // Check in subscribed channels
    int index = _subscribedChannels.indexWhere((channel) => channel.id == channelId);
    if (index != -1) {
      return _subscribedChannels[index].adminUIDs.contains(userId);
    }
    
    // Check in explore channels
    index = _exploreChannels.indexWhere((channel) => channel.id == channelId);
    if (index != -1) {
      return _exploreChannels[index].adminUIDs.contains(userId);
    }
    
    return false;
  }
  
  // Delete a channel post (admin only)
  Future<void> deleteChannelPost({
    required String channelId,
    required String postId,
    required Function onSuccess,
    required Function(String) onFail,
  }) async {
    try {
      // Delete the post
      await _firestore
          .collection(Constants.channels)
          .doc(channelId)
          .collection(Constants.channelPosts)
          .doc(postId)
          .delete();
      
      // Update local data
      _channelPosts.removeWhere((post) => post.id == postId);
      notifyListeners();
      
      onSuccess();
    } catch (e) {
      onFail(e.toString());
    }
  }
  
  // Search channels by name
  Future<List<ChannelModel>> searchChannels(String query) async {
    try {
      // Search for channels where name contains the query
      QuerySnapshot searchResults = await _firestore
          .collection(Constants.channels)
          .where(Constants.channelName, isGreaterThanOrEqualTo: query)
          .where(Constants.channelName, isLessThanOrEqualTo: query + '\uf8ff')
          .get();
      
      return searchResults.docs
          .map((doc) => ChannelModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error searching channels: $e');
      return [];
    }
  }
  
  // Get channel by ID
  Future<ChannelModel?> getChannelById(String channelId) async {
    try {
      DocumentSnapshot channelDoc = await _firestore
          .collection(Constants.channels)
          .doc(channelId)
          .get();
      
      if (channelDoc.exists) {
        return ChannelModel.fromMap(channelDoc.data() as Map<String, dynamic>);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting channel by ID: $e');
      return null;
    }
  }
  
  // Add admin to channel (creator only)
  Future<void> addChannelAdmin({
    required String channelId,
    required String adminId,
    required Function onSuccess,
    required Function(String) onFail,
  }) async {
    try {
      await _firestore
          .collection(Constants.channels)
          .doc(channelId)
          .update({
        Constants.adminUIDs: FieldValue.arrayUnion([adminId]),
      });
      
      // Update local data if needed
      if (_selectedChannel != null && _selectedChannel!.id == channelId) {
        List<String> updatedAdmins = List.from(_selectedChannel!.adminUIDs);
        updatedAdmins.add(adminId);
        
        _selectedChannel = _selectedChannel!.copyWith(
          adminUIDs: updatedAdmins,
        );
        
        notifyListeners();
      }
      
      onSuccess();
    } catch (e) {
      onFail(e.toString());
    }
  }
  
  // Remove admin from channel (creator only)
  Future<void> removeChannelAdmin({
    required String channelId,
    required String adminId,
    required String creatorId,
    required Function onSuccess,
    required Function(String) onFail,
  }) async {
    try {
      // Cannot remove the creator as admin
      if (adminId == creatorId) {
        onFail('Cannot remove the channel creator as admin');
        return;
      }
      
      await _firestore
          .collection(Constants.channels)
          .doc(channelId)
          .update({
        Constants.adminUIDs: FieldValue.arrayRemove([adminId]),
      });
      
      // Update local data if needed
      if (_selectedChannel != null && _selectedChannel!.id == channelId) {
        List<String> updatedAdmins = List.from(_selectedChannel!.adminUIDs);
        updatedAdmins.remove(adminId);
        
        _selectedChannel = _selectedChannel!.copyWith(
          adminUIDs: updatedAdmins,
        );
        
        notifyListeners();
      }
      
      onSuccess();
    } catch (e) {
      onFail(e.toString());
    }
  }
  
  // Get stream of channel updates
  Stream<DocumentSnapshot> channelStream(String channelId) {
    return _firestore
        .collection(Constants.channels)
        .doc(channelId)
        .snapshots();
  }
  
  // Get stream of channel posts
  Stream<QuerySnapshot> channelPostsStream(String channelId) {
    return _firestore
        .collection(Constants.channels)
        .doc(channelId)
        .collection(Constants.channelPosts)
        .orderBy(Constants.createdAt, descending: true)
        .snapshots();
  }
  
  // Get user data for a post
  Future<UserModel?> getUserForPost(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection(Constants.users)
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting user for post: $e');
      return null;
    }
  }
}
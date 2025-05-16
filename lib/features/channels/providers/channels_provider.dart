import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:uuid/uuid.dart';

// Define the channels state
class ChannelsState {
  final bool isLoading;
  final List<ChannelModel> channels;
  final List<String> followedChannels;
  final ChannelModel? userChannel;
  final String? error;
  final bool isCreatingChannel;
  final double uploadProgress;

  const ChannelsState({
    this.isLoading = false,
    this.channels = const [],
    this.followedChannels = const [],
    this.userChannel,
    this.error,
    this.isCreatingChannel = false,
    this.uploadProgress = 0.0,
  });

  ChannelsState copyWith({
    bool? isLoading,
    List<ChannelModel>? channels,
    List<String>? followedChannels,
    ChannelModel? userChannel,
    String? error,
    bool? isCreatingChannel,
    double? uploadProgress,
  }) {
    return ChannelsState(
      isLoading: isLoading ?? this.isLoading,
      channels: channels ?? this.channels,
      followedChannels: followedChannels ?? this.followedChannels,
      userChannel: userChannel ?? this.userChannel,
      error: error,
      isCreatingChannel: isCreatingChannel ?? this.isCreatingChannel,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

// Create the channels provider
class ChannelsNotifier extends StateNotifier<ChannelsState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  ChannelsNotifier() : super(const ChannelsState()) {
    // Initialize with empty state and load data
    loadChannels();
    loadUserChannel();
    loadFollowedChannels();
  }

  // Load channels from Firestore
  Future<void> loadChannels({bool forceRefresh = false}) async {
    // If not forcing refresh and we already have channels, just return
    if (!forceRefresh && state.channels.isNotEmpty) {
      return;
    }
    
    // Set loading state
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get all active channels
      final QuerySnapshot querySnapshot = await _firestore
          .collection(Constants.channels)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      
      List<ChannelModel> channels = [];
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        channels.add(ChannelModel.fromMap(data, doc.id));
      }
      
      // Update state with channels
      state = state.copyWith(
        channels: channels,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  // Load user's channel if they have one
  Future<void> loadUserChannel() async {
    if (_auth.currentUser == null) return;
    
    try {
      final uid = _auth.currentUser!.uid;
      
      // Get channels owned by the current user
      final QuerySnapshot querySnapshot = await _firestore
          .collection(Constants.channels)
          .where('ownerId', isEqualTo: uid)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        // User doesn't have a channel
        state = state.copyWith(userChannel: null);
        return;
      }
      
      // User has a channel
      final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
      final userChannel = ChannelModel.fromMap(data, querySnapshot.docs.first.id);
      
      state = state.copyWith(userChannel: userChannel);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Load channels followed by the user
  Future<void> loadFollowedChannels() async {
    if (_auth.currentUser == null) return;
    
    try {
      final uid = _auth.currentUser!.uid;
      final userDoc = await _firestore.collection(Constants.users).doc(uid).get();
      
      if (userDoc.exists && userDoc.data()!.containsKey('followedChannels')) {
        final followedChannels = List<String>.from(userDoc.data()!['followedChannels'] ?? []);
        state = state.copyWith(followedChannels: followedChannels);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Create a new channel
  Future<ChannelModel?> createChannel({
    required String name,
    required String description,
    required File? profileImage,
    required File? coverImage,
    List<String>? tags,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    if (_auth.currentUser == null) {
      onError('User not authenticated');
      return null;
    }
    
    // Check if user already has a channel
    await loadUserChannel();
    if (state.userChannel != null) {
      onError('You already have a channel');
      return null;
    }
    
    state = state.copyWith(isCreatingChannel: true, uploadProgress: 0.0);
    
    try {
      final uid = _auth.currentUser!.uid;
      final channelId = const Uuid().v4();
      
      // Get user info
      final userDoc = await _firestore.collection(Constants.users).doc(uid).get();
      final userData = userDoc.data();
      
      if (userData == null) {
        throw Exception('User data not found');
      }
      
      final userName = userData[Constants.name] ?? '';
      final userImage = userData[Constants.image] ?? '';
      
      // Upload profile image if provided
      String profileImageUrl = '';
      if (profileImage != null) {
        final storageRef = _storage.ref().child('channelImages/$channelId/profile.jpg');
        final uploadTask = storageRef.putFile(
          profileImage,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        
        // Monitor upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          state = state.copyWith(uploadProgress: progress * 0.5); // First half of progress
        });
        
        final snapshot = await uploadTask;
        profileImageUrl = await snapshot.ref.getDownloadURL();
      }
      
      // Upload cover image if provided
      String coverImageUrl = '';
      if (coverImage != null) {
        final storageRef = _storage.ref().child('channelImages/$channelId/cover.jpg');
        final uploadTask = storageRef.putFile(
          coverImage,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        
        // Monitor upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          state = state.copyWith(uploadProgress: 0.5 + progress * 0.5); // Second half of progress
        });
        
        final snapshot = await uploadTask;
        coverImageUrl = await snapshot.ref.getDownloadURL();
      }
      
      // Create channel model
      final ChannelModel channel = ChannelModel(
        id: channelId,
        ownerId: uid,
        ownerName: userName,
        ownerImage: userImage,
        name: name,
        description: description,
        profileImage: profileImageUrl,
        coverImage: coverImageUrl,
        followers: 0,
        videosCount: 0,
        likesCount: 0,
        isVerified: false,
        tags: tags ?? [],
        followerUIDs: [],
        createdAt: Timestamp.now(),
        isActive: true,
        isFeatured: false,
      );
      
      // Save to Firestore
      await _firestore
          .collection(Constants.channels)
          .doc(channelId)
          .set(channel.toMap());
      
      // Update user's owned channels
      await _firestore.collection(Constants.users).doc(uid).update({
        'ownedChannels': FieldValue.arrayUnion([channelId]),
      });
      
      // Update local state
      state = state.copyWith(
        userChannel: channel,
        isCreatingChannel: false,
        uploadProgress: 0.0,
        channels: [channel, ...state.channels],
      );
      
      onSuccess('Channel created successfully');
      return channel;
    } catch (e) {
      state = state.copyWith(
        isCreatingChannel: false,
        uploadProgress: 0.0,
        error: e.toString(),
      );
      
      onError(e.toString());
      return null;
    }
  }

  // Follow or unfollow a channel
  Future<void> toggleFollowChannel(String channelId) async {
    if (_auth.currentUser == null) return;
    
    try {
      final uid = _auth.currentUser!.uid;
      final channelDoc = _firestore.collection(Constants.channels).doc(channelId);
      
      // Get current followed channels
      List<String> followedChannels = List.from(state.followedChannels);
      bool isCurrentlyFollowed = followedChannels.contains(channelId);
      
      // Update local state first (optimistic update)
      if (isCurrentlyFollowed) {
        followedChannels.remove(channelId);
      } else {
        followedChannels.add(channelId);
      }
      
      // Update channels list with new follow status
      final updatedChannels = state.channels.map((channel) {
        if (channel.id == channelId) {
          return channel.copyWith(
            followers: isCurrentlyFollowed ? channel.followers - 1 : channel.followers + 1,
            followerUIDs: isCurrentlyFollowed
                ? (channel.followerUIDs..remove(uid))
                : (channel.followerUIDs..add(uid)),
          );
        }
        return channel;
      }).toList();
      
      state = state.copyWith(
        channels: updatedChannels,
        followedChannels: followedChannels,
      );
      
      // Update Firestore
      // 1. Update user's followed channels
      await _firestore.collection(Constants.users).doc(uid).update({
        'followedChannels': isCurrentlyFollowed
            ? FieldValue.arrayRemove([channelId])
            : FieldValue.arrayUnion([channelId]),
      });
      
      // 2. Update channel's followers count and list
      await channelDoc.update({
        'followers': isCurrentlyFollowed
            ? FieldValue.increment(-1)
            : FieldValue.increment(1),
        'followerUIDs': isCurrentlyFollowed
            ? FieldValue.arrayRemove([uid])
            : FieldValue.arrayUnion([uid]),
      });
      
    } catch (e) {
      state = state.copyWith(error: e.toString());
      
      // Revert the optimistic update on error
      loadChannels();
      loadFollowedChannels();
    }
  }

  // Get a specific channel by ID
  Future<ChannelModel?> getChannelById(String channelId) async {
    try {
      final docSnapshot = await _firestore
          .collection(Constants.channels)
          .doc(channelId)
          .get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      return ChannelModel.fromMap(docSnapshot.data()!, channelId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Update a channel
  Future<void> updateChannel({
    required ChannelModel channel,
    File? profileImage,
    File? coverImage,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    if (_auth.currentUser == null) {
      onError('User not authenticated');
      return;
    }
    
    if (channel.ownerId != _auth.currentUser!.uid) {
      onError('You can only update your own channel');
      return;
    }
    
    state = state.copyWith(isCreatingChannel: true, uploadProgress: 0.0);
    
    try {
      Map<String, dynamic> updates = channel.toMap();
      
      // Upload new profile image if provided
      if (profileImage != null) {
        final storageRef = _storage.ref().child('channelImages/${channel.id}/profile.jpg');
        final uploadTask = storageRef.putFile(
          profileImage,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          state = state.copyWith(uploadProgress: progress * 0.5);
        });
        
        final snapshot = await uploadTask;
        final profileImageUrl = await snapshot.ref.getDownloadURL();
        
        updates['profileImage'] = profileImageUrl;
      }
      
      // Upload new cover image if provided
      if (coverImage != null) {
        final storageRef = _storage.ref().child('channelImages/${channel.id}/cover.jpg');
        final uploadTask = storageRef.putFile(
          coverImage,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          state = state.copyWith(uploadProgress: 0.5 + progress * 0.5);
        });
        
        final snapshot = await uploadTask;
        final coverImageUrl = await snapshot.ref.getDownloadURL();
        
        updates['coverImage'] = coverImageUrl;
      }
      
      // Update in Firestore
      await _firestore
          .collection(Constants.channels)
          .doc(channel.id)
          .update(updates);
      
      // Update local state
      final updatedChannel = channel.copyWith(
        profileImage: updates['profileImage'] ?? channel.profileImage,
        coverImage: updates['coverImage'] ?? channel.coverImage,
      );
      
      // Update channels list
      final updatedChannels = state.channels.map((c) {
        if (c.id == channel.id) {
          return updatedChannel;
        }
        return c;
      }).toList();
      
      state = state.copyWith(
        userChannel: updatedChannel,
        channels: updatedChannels,
        isCreatingChannel: false,
        uploadProgress: 0.0,
      );
      
      onSuccess('Channel updated successfully');
    } catch (e) {
      state = state.copyWith(
        isCreatingChannel: false,
        uploadProgress: 0.0,
        error: e.toString(),
      );
      
      onError(e.toString());
    }
  }

  // Delete a channel (mark as inactive)
  Future<void> deleteChannel(String channelId) async {
    if (_auth.currentUser == null) return;
    
    try {
      final uid = _auth.currentUser!.uid;
      final channelDoc = await _firestore
          .collection(Constants.channels)
          .doc(channelId)
          .get();
      
      final data = channelDoc.data();
      if (data == null || data['ownerId'] != uid) {
        throw Exception('You can only delete your own channel');
      }
      
      // Mark channel as inactive instead of deleting
      await _firestore
          .collection(Constants.channels)
          .doc(channelId)
          .update({'isActive': false});
      
      // Remove from user's owned channels
      await _firestore.collection(Constants.users).doc(uid).update({
        'ownedChannels': FieldValue.arrayRemove([channelId]),
      });
      
      // Update local state
      final updatedChannels = state.channels.where((c) => c.id != channelId).toList();
      
      state = state.copyWith(
        userChannel: null,
        channels: updatedChannels,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Provider definition
final channelsProvider = StateNotifierProvider<ChannelsNotifier, ChannelsState>((ref) {
  return ChannelsNotifier();
});
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/models/video_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:video_compress/video_compress.dart';

class VideoProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  List<VideoModel> _feedVideos = [];
  int _currentVideoIndex = 0;

  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  List<VideoModel> get feedVideos => _feedVideos;
  int get currentVideoIndex => _currentVideoIndex;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Set current video index
  void setCurrentVideoIndex(int index) {
    _currentVideoIndex = index;
    notifyListeners();
  }

  // Fetch videos for feed
  Future<void> fetchFeedVideos() async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot videosSnapshot = await _firestore
          .collection(Constants.videos)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      _feedVideos = videosSnapshot.docs
          .map((doc) => VideoModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching videos: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Upload a new video
  Future<bool> uploadVideo({
    required File videoFile,
    required UserModel user,
    required String caption,
    required String songName,
    required Function(String) onFail,
  }) async {
    _isUploading = true;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      // Generate a unique ID for the video
      String videoId = const Uuid().v4();
      
      // Get video duration
      final videoPlayerController = VideoPlayerController.file(videoFile);
      await videoPlayerController.initialize();
      final duration = videoPlayerController.value.duration.inSeconds;
      videoPlayerController.dispose();

      // Upload the video file to Firebase Storage
      final String videoPath = '${Constants.videoFiles}/$videoId.mp4';
      final Reference ref = _storage.ref().child(videoPath);
      
      final UploadTask uploadTask = ref.putFile(
        videoFile,
        SettableMetadata(contentType: 'video/mp4'),
      );

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        notifyListeners();
      });

      // Wait for upload to complete
      final TaskSnapshot taskSnapshot = await uploadTask;
      final String videoUrl = await taskSnapshot.ref.getDownloadURL();

      // Create video document in Firestore
      final VideoModel newVideo = VideoModel(
        id: videoId,
        userId: user.uid,
        userName: user.name,
        userImage: user.image,
        videoUrl: videoUrl,
        caption: caption,
        songName: songName,
        likesCount: 0,
        commentsCount: 0,
        sharesCount: 0,
        likedBy: [],
        viewCount: 0,
        createdAt: DateTime.now().millisecondsSinceEpoch.toString(),
        duration: duration,
      );

      await _firestore.collection(Constants.videos).doc(videoId).set(newVideo.toMap());

      // Add video to local feed
      _feedVideos.insert(0, newVideo);
      
      _isUploading = false;
      _uploadProgress = 0.0;
      notifyListeners();
      return true;
    } catch (e) {
      _isUploading = false;
      _uploadProgress = 0.0;
      onFail('Error uploading video: $e');
      notifyListeners();
      return false;
    }
  }

  // Like/unlike a video
  Future<void> toggleLikeVideo(String videoId, String userId) async {
    try {
      // Get the video from firestore
      DocumentSnapshot videoDoc = await _firestore.collection(Constants.videos).doc(videoId).get();
      VideoModel video = VideoModel.fromMap(videoDoc.data() as Map<String, dynamic>);
      
      // Check if user has already liked the video
      bool isLiked = video.likedBy.contains(userId);
      
      // Update the video
      if (isLiked) {
        // Unlike
        await _firestore.collection(Constants.videos).doc(videoId).update({
          Constants.likedBy: FieldValue.arrayRemove([userId]),
          Constants.likesCount: FieldValue.increment(-1),
        });
        
        // Update local video
        int index = _feedVideos.indexWhere((v) => v.id == videoId);
        if (index != -1) {
          List<String> updatedLikedBy = List.from(_feedVideos[index].likedBy);
          updatedLikedBy.remove(userId);
          
          _feedVideos[index] = VideoModel(
            id: _feedVideos[index].id,
            userId: _feedVideos[index].userId,
            userName: _feedVideos[index].userName,
            userImage: _feedVideos[index].userImage,
            videoUrl: _feedVideos[index].videoUrl,
            caption: _feedVideos[index].caption,
            songName: _feedVideos[index].songName,
            likesCount: _feedVideos[index].likesCount - 1,
            commentsCount: _feedVideos[index].commentsCount,
            sharesCount: _feedVideos[index].sharesCount,
            likedBy: updatedLikedBy,
            viewCount: _feedVideos[index].viewCount,
            createdAt: _feedVideos[index].createdAt,
            duration: _feedVideos[index].duration,
          );
        }
      } else {
        // Like
        await _firestore.collection(Constants.videos).doc(videoId).update({
          Constants.likedBy: FieldValue.arrayUnion([userId]),
          Constants.likesCount: FieldValue.increment(1),
        });
        
        // Update local video
        int index = _feedVideos.indexWhere((v) => v.id == videoId);
        if (index != -1) {
          List<String> updatedLikedBy = List.from(_feedVideos[index].likedBy);
          updatedLikedBy.add(userId);
          
          _feedVideos[index] = VideoModel(
            id: _feedVideos[index].id,
            userId: _feedVideos[index].userId,
            userName: _feedVideos[index].userName,
            userImage: _feedVideos[index].userImage,
            videoUrl: _feedVideos[index].videoUrl,
            caption: _feedVideos[index].caption,
            songName: _feedVideos[index].songName,
            likesCount: _feedVideos[index].likesCount + 1,
            commentsCount: _feedVideos[index].commentsCount,
            sharesCount: _feedVideos[index].sharesCount,
            likedBy: updatedLikedBy,
            viewCount: _feedVideos[index].viewCount,
            createdAt: _feedVideos[index].createdAt,
            duration: _feedVideos[index].duration,
          );
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  // Increment video view count
  Future<void> incrementViewCount(String videoId) async {
    try {
      await _firestore.collection(Constants.videos).doc(videoId).update({
        Constants.viewCount: FieldValue.increment(1),
      });
      
      // Update local video
      int index = _feedVideos.indexWhere((v) => v.id == videoId);
      if (index != -1) {
        _feedVideos[index] = VideoModel(
          id: _feedVideos[index].id,
          userId: _feedVideos[index].userId,
          userName: _feedVideos[index].userName,
          userImage: _feedVideos[index].userImage,
          videoUrl: _feedVideos[index].videoUrl,
          caption: _feedVideos[index].caption,
          songName: _feedVideos[index].songName,
          likesCount: _feedVideos[index].likesCount,
          commentsCount: _feedVideos[index].commentsCount,
          sharesCount: _feedVideos[index].sharesCount,
          likedBy: _feedVideos[index].likedBy,
          viewCount: _feedVideos[index].viewCount + 1,
          createdAt: _feedVideos[index].createdAt,
          duration: _feedVideos[index].duration,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  // Get videos by user
  Future<List<VideoModel>> getUserVideos(String userId) async {
    try {
      QuerySnapshot videosSnapshot = await _firestore
          .collection(Constants.videos)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return videosSnapshot.docs
          .map((doc) => VideoModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching user videos: $e');
      return [];
    }
  }
}
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../domain/repositories/status_repository.dart';
import '../../domain/models/status_post.dart';
import '../../domain/models/status_comment.dart';
import '../../domain/models/status_reaction.dart';
import '../../domain/models/status_privacy.dart';
import '../../domain/models/status_media.dart';
import '../../core/failures.dart';
import '../dtos/status_post_dto.dart';
import '../dtos/status_comment_dto.dart';
import '../dtos/status_reaction_dto.dart';
import '../dtos/status_media_dto.dart';
import '../dtos/status_privacy_dto.dart';
import '../data_sources/media_upload_service.dart';

class FirebaseStatusRepository implements StatusRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final Uuid _uuid;
  final MediaUploadService _mediaUploadService;
  
  FirebaseStatusRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required Uuid uuid,
    required MediaUploadService mediaUploadService,
  }) : _firestore = firestore, 
       _storage = storage,
       _uuid = uuid,
       _mediaUploadService = mediaUploadService;
  
  // Collection references
  CollectionReference get _postsCollection => _firestore.collection('status_posts');
  CollectionReference get _commentsCollection => _firestore.collection('status_comments');
  CollectionReference get _reactionsCollection => _firestore.collection('status_reactions');
  CollectionReference get _usersCollection => _firestore.collection('users');
  
  @override
  Future<Either<Failure, List<StatusPost>>> getStatusFeed({
    required String userId,
    required List<String> contactIds,
    required List<String> mutedUserIds,
    int? limit,
    String? lastPostId,
  }) async {
    try {
      // Get current time to filter out expired statuses
      final now = DateTime.now();
      
      // Start with a query for all non-expired posts
      Query query = _postsCollection
          .where('expiresAt', isGreaterThan: now.toIso8601String());
      
      // Apply pagination if lastPostId is provided
      if (lastPostId != null) {
        final lastDocSnapshot = await _postsCollection.doc(lastPostId).get();
        query = query.startAfterDocument(lastDocSnapshot);
      }
      
      // Apply limit if provided
      if (limit != null) {
        query = query.limit(limit);
      }
      
      // Execute query
      final snapshot = await query.get();
      
      // Process results
      List<StatusPost> posts = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final postDto = StatusPostDTO.fromJson(data);
        final post = postDto.toDomain();
        
        // Filter based on privacy settings and muted users
        final canView = post.canBeViewedBy(userId, contactIds);
        final isNotMuted = !mutedUserIds.contains(post.authorId);
        
        if (canView && isNotMuted) {
          posts.add(post);
        }
      }
      
      // Sort posts by creation time (newest first)
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return Right(posts);
    } on FirebaseException catch (e) {
      return Left(Failure.serverError(e.message));
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, StatusPost>> getStatusPost(String postId) async {
    try {
      final doc = await _postsCollection.doc(postId).get();
      
      if (!doc.exists) {
        return const Left(Failure.notFoundError());
      }
      
      final data = doc.data() as Map<String, dynamic>;
      final postDto = StatusPostDTO.fromJson(data);
      final post = postDto.toDomain();
      
      return Right(post);
    } on FirebaseException catch (e) {
      return Left(Failure.serverError(e.message));
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, StatusPost>> createStatusPost({
    required String authorId,
    required String authorName,
    required String authorImage,
    required String content,
    required StatusPrivacy privacy,
    List<File>? mediaFiles,
    String? location,
    String? linkUrl,
  }) async {
    try {
      // Generate unique post ID
      final postId = _uuid.v4();
      
      // Set creation and expiry times
      final createdAt = DateTime.now();
      final expiresAt = createdAt.add(const Duration(hours: 24));
      
      // Upload media files if provided
      List<StatusMedia> mediaItems = [];
      
      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        for (var file in mediaFiles) {
          final mediaId = _uuid.v4();
          final mediaType = _detectMediaType(file.path);
          
          // Upload the file
          final mediaUrl = await _mediaUploadService.uploadFile(
            file: file,
            path: 'status/$authorId/$postId/$mediaId',
          );
          
          // Get media dimensions
          final metadata = await _mediaUploadService.getMediaMetadata(file);
          
          // Create media item
          final media = StatusMedia(
            id: mediaId,
            url: mediaUrl,
            type: mediaType,
            width: metadata.width,
            height: metadata.height,
            duration: metadata.duration,
            size: metadata.size,
            thumbnailUrl: mediaType == MediaType.video ? await _mediaUploadService.generateThumbnail(file) : null,
          );
          
          mediaItems.add(media);
        }
      }
      
      // Handle link preview if linkUrl is provided
      String? linkPreviewImage;
      String? linkPreviewTitle;
      String? linkPreviewDescription;
      
      if (linkUrl != null && linkUrl.isNotEmpty) {
        final preview = await _mediaUploadService.fetchLinkPreview(linkUrl);
        linkPreviewImage = preview.imageUrl;
        linkPreviewTitle = preview.title;
        linkPreviewDescription = preview.description;
      }
      
      // Create the status post
      final post = StatusPost(
        id: postId,
        authorId: authorId,
        authorName: authorName,
        authorImage: authorImage,
        createdAt: createdAt,
        expiresAt: expiresAt,
        content: content,
        media: mediaItems,
        privacy: privacy,
        comments: [],
        reactions: [],
        viewerIds: [],
        viewCount: 0,
        location: location,
        linkUrl: linkUrl,
        linkPreviewImage: linkPreviewImage,
        linkPreviewTitle: linkPreviewTitle,
        linkPreviewDescription: linkPreviewDescription,
      );
      
      // Convert to DTO and save to Firestore
      final postDto = StatusPostDTO.fromDomain(post);
      await _postsCollection.doc(postId).set(postDto.toJson());
      
      return Right(post);
    } on FirebaseException catch (e) {
      return Left(Failure.serverError(e.message));
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
  
  // Helper method to detect media type from file extension
  MediaType _detectMediaType(String path) {
    final extension = path.split('.').last.toLowerCase();
    
    if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension)) {
      return MediaType.video;
    } else if (['gif'].contains(extension)) {
      return MediaType.gif;
    } else {
      return MediaType.image;
    }
  }
  
  @override
  Future<Either<Failure, StatusPost>> updateStatusPost({
    required String postId,
    required String authorId,
    String? content,
    StatusPrivacy? privacy,
  }) async {
    try {
      // Get current post
      final postDoc = await _postsCollection.doc(postId).get();
      
      if (!postDoc.exists) {
        return const Left(Failure.notFoundError());
      }
      
      final data = postDoc.data() as Map<String, dynamic>;
      final postDto = StatusPostDTO.fromJson(data);
      final post = postDto.toDomain();
      
      // Check if user is the author
      if (post.authorId != authorId) {
        return const Left(Failure.permissionDenied());
      }
      
      // Create updated post
      final updatedPost = post.copyWith(
        content: content ?? post.content,
        privacy: privacy ?? post.privacy,
        isEdited: true,
      );
      
      // Convert to DTO and update in Firestore
      final updatedPostDto = StatusPostDTO.fromDomain(updatedPost);
      await _postsCollection.doc(postId).update(updatedPostDto.toJson());
      
      return Right(updatedPost);
    } on FirebaseException catch (e) {
      return Left(Failure.serverError(e.message));
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, Unit>> deleteStatusPost({
    required String postId,
    required String authorId,
  }) async {
    try {
      // Get current post
      final postDoc = await _postsCollection.doc(postId).get();
      
      if (!postDoc.exists) {
        return const Left(Failure.notFoundError());
      }
      
      final data = postDoc.data() as Map<String, dynamic>;
      final postDto = StatusPostDTO.fromJson(data);
      final post = postDto.toDomain();
      
      // Check if user is the author
      if (post.authorId != authorId) {
        return const Left(Failure.permissionDenied());
      }
      
      // Delete media files from storage
      for (var media in post.media) {
        try {
          await _storage.refFromURL(media.url).delete();
          if (media.thumbnailUrl != null) {
            await _storage.refFromURL(media.thumbnailUrl!).delete();
          }
        } catch (e) {
          // Continue even if file deletion fails
          print('Failed to delete media: ${e.toString()}');
        }
      }
      
      // Delete comments for this post
      final commentsSnapshot = await _commentsCollection
          .where('postId', isEqualTo: postId)
          .get();
      
      for (var doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Delete reactions for this post
      final reactionsSnapshot = await _reactionsCollection
          .where('postId', isEqualTo: postId)
          .get();
      
      for (var doc in reactionsSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Delete the post document
      await _postsCollection.doc(postId).delete();
      
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(Failure.serverError(e.message));
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, Unit>> viewStatusPost({
    required String postId,
    required String viewerId,
  }) async {
    try {
      // Get current post
      final postDoc = await _postsCollection.doc(postId).get();
      
      if (!postDoc.exists) {
        return const Left(Failure.notFoundError());
      }
      
      final data = postDoc.data() as Map<String, dynamic>;
      final postDto = StatusPostDTO.fromJson(data);
      final post = postDto.toDomain();
      
      // Check if already viewed
      if (post.viewerIds.contains(viewerId)) {
        return const Right(unit);
      }
      
      // Update viewerIds and viewCount
      final viewerIds = List<String>.from(post.viewerIds)..add(viewerId);
      final viewCount = post.viewCount + 1;
      
      // Update in Firestore
      await _postsCollection.doc(postId).update({
        'viewerIds': viewerIds,
        'viewCount': viewCount,
      });
      
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(Failure.serverError(e.message));
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, StatusComment>> addComment({
    required String postId, 
    required String userId,
    required String userName,
    required String userImage,
    required String content,
    String? replyToCommentId,
    String? replyToUserId,
    String? replyToUserName,
  }) async {
    try {
      // Generate unique comment ID
      final commentId = _uuid.v4();
      final createdAt = DateTime.now();
      
      // Create the comment
      final comment = StatusComment(
        id: commentId,
        postId: postId,
        userId: userId,
        userName: userName,
        userImage: userImage,
        content: content,
        createdAt: createdAt,
        replyToCommentId: replyToCommentId,
        replyToUserId: replyToUserId,
        replyToUserName: replyToUserName,
      );
      
      // Convert to DTO and save to Firestore
      final commentDto = StatusCommentDTO.fromDomain(comment);
      await _commentsCollection.doc(commentId).set(commentDto.toJson());
      
      return Right(comment);
    } on FirebaseException catch (e) {
      return Left(Failure.serverError(e.message));
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, Unit>> deleteComment({
    required String commentId,
    required String postId,
    required String userId,
  }) async {
    try {
      // Get current comment
      final commentDoc = await _commentsCollection.doc(commentId).get();
      
      if (!commentDoc.exists) {
        return const Left(Failure.notFoundError());
      }
      
      final data = commentDoc.data() as Map<String, dynamic>;
      final commentDto = StatusCommentDTO.fromJson(data);
      final comment = commentDto.toDomain();
      
      // Check if user is the comment author
      if (comment.userId != userId) {
        // Check if user is the post author (they can also delete comments)
        final postDoc = await _postsCollection.doc(postId).get();
        
        if (!postDoc.exists) {
          return const Left(Failure.notFoundError());
        }
        
        final postData = postDoc.data() as Map<String, dynamic>;
        final postAuthorId = postData['authorId'];
        
        if (userId != postAuthorId) {
          return const Left(Failure.permissionDenied());
        }
      }
      
      // Delete the comment
      await _commentsCollection.doc(commentId).delete();
      
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(Failure.serverError(e.message));
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, StatusReaction>> addReaction({
    required String postId,
    required String userId,
    required String userName,
    required String userImage, 
    required ReactionType reactionType,
  }) async {
    try {
      // Check if user already reacted
      final existingReactionSnapshot = await _reactionsCollection
          .where('postId', isEqualTo: postId)
          .where('userId', isEqualTo: userId)
          .get();
      
      // If user already reacted, remove the existing reaction
      if (existingReactionSnapshot.docs.isNotEmpty) {
        final existingReactionId = existingReactionSnapshot.docs.first.id;
        await _reactionsCollection.doc(existingReactionId).delete();
      }
      
      // Generate unique reaction ID
      final reactionId = _uuid.v4();
      final createdAt = DateTime.now();
      
      // Create the reaction
      final reaction = StatusReaction(
        id: reactionId,
        postId: postId,
        userId: userId,
        userName: userName,
        userImage: userImage,
        type: reactionType,
        createdAt: createdAt,
      );
      
      // Convert to DTO and save to Firestore
      final reactionDto = StatusReactionDTO.fromDomain(reaction);
      await _reactionsCollection.doc(reactionId).set(reactionDto.toJson());
      
      return Right(reaction);
    } on FirebaseException catch (e) {
      return Left(Failure.serverError(e.message));
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, Unit>> removeReaction({
    required String reactionId,
    required String postId,
    required String userId,
  }) async {
    try {
      // Get current reaction
      final reactionDoc = await _reactionsCollection.doc(reactionId).get();
      
      if (!reactionDoc.exists) {
        return const Left(Failure.notFoundError());
      }
      
      final data = reactionDoc.data() as Map<String, dynamic>;
      final reactionDto = StatusReactionDTO.fromJson(data);
      final reaction = reactionDto.toDomain();
      
      // Check if user is the reaction author
      if (reaction.userId != userId) {
        return const Left(Failure.permissionDenied());
      }
      
      // Delete the reaction
      await _reactionsCollection.doc(reactionId).delete();
      
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(Failure.serverError(e.message));
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, Unit>> updateMutedUsers({
    required String userId,
    required List<String> mutedUserIds,
  }) async {
    try {
      // Update the user's muted list in their profile
      await _usersCollection.doc(userId).update({
        'statusMutedUsers': mutedUserIds,
      });
      
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(Failure.serverError(e.message));
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, List<String>>> getMutedUsers(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      
      if (!userDoc.exists) {
        return const Left(Failure.notFoundError());
      }
      
      final data = userDoc.data() as Map<String, dynamic>;
      final mutedUsers = List<String>.from(data['statusMutedUsers'] ?? []);
      
      return Right(mutedUsers);
    } on FirebaseException catch (e) {
      return Left(Failure.serverError(e.message));
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, bool>> hasUserPostedRecently(String userId) async {
    try {
      // Get start of current day
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      // Query for posts by this user created today
      final snapshot = await _postsCollection
          .where('authorId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .get();
      
      return Right(snapshot.docs.isNotEmpty);
    } on FirebaseException catch (e) {
      return Left(Failure.serverError(e.message));
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }}
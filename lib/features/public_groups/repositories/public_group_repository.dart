// lib/features/public_groups/repositories/public_group_repository.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/public_groups/models/public_group_model.dart';
import 'package:textgb/features/public_groups/models/public_group_post_model.dart';
import 'package:textgb/features/public_groups/models/post_comment_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:uuid/uuid.dart';

class PublicGroupRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PublicGroupRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  /// Create a new public group
  Future<PublicGroupModel> createPublicGroup({
    required String groupName,
    required String groupDescription,
    required File? groupImage,
    required Map<String, dynamic> settings,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Validate group name
      if (groupName.trim().isEmpty || groupName.trim().length < 3) {
        throw Exception('Group name must be at least 3 characters');
      }

      // Generate group ID
      final groupId = const Uuid().v4();
      final createdAt = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Upload group image if provided
      String imageUrl = '';
      if (groupImage != null) {
        imageUrl = await storeFileToStorage(
          file: groupImage,
          reference: 'public_groups/$groupId/group_image',
        );
      }

      // Create public group model
      final publicGroup = PublicGroupModel(
        groupId: groupId,
        groupName: groupName.trim(),
        groupDescription: groupDescription.trim(),
        groupImage: imageUrl,
        creatorUID: currentUser.uid,
        isVerified: false,
        subscribersUIDs: [currentUser.uid], // Creator is auto-subscribed
        adminUIDs: [currentUser.uid], // Creator is auto-admin
        subscribersCount: 1,
        lastPostAt: '',
        createdAt: createdAt,
        groupSettings: settings,
      );

      // Use transaction for atomic operation
      await _firestore.runTransaction((transaction) async {
        // Create public group document
        transaction.set(
          _firestore.collection('public_groups').doc(groupId),
          publicGroup.toMap(),
        );

        // Update user's followed public groups
        transaction.update(
          _firestore.collection(Constants.users).doc(currentUser.uid),
          {
            'followedPublicGroups': FieldValue.arrayUnion([groupId]),
          },
        );
      });

      return publicGroup;
    } catch (e) {
      debugPrint('Error creating public group: $e');
      throw e.toString();
    }
  }

  /// Get public groups for current user (subscribed groups)
  Stream<List<PublicGroupModel>> getUserPublicGroups() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('public_groups')
        .where('subscribersUIDs', arrayContains: currentUser.uid)
        .orderBy('lastPostAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final groups = <PublicGroupModel>[];
          
          for (final doc in snapshot.docs) {
            try {
              final group = PublicGroupModel.fromMap(doc.data());
              groups.add(group);
            } catch (e) {
              debugPrint('Error parsing public group ${doc.id}: $e');
            }
          }
          
          return groups;
        });
  }

  /// Get a public group by ID
  Future<PublicGroupModel?> getPublicGroupById(String groupId) async {
    try {
      final doc = await _firestore.collection('public_groups').doc(groupId).get();
      if (!doc.exists) return null;

      return PublicGroupModel.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('Error getting public group: $e');
      return null;
    }
  }

  /// Subscribe to a public group
  Future<void> subscribeToPublicGroup(String groupId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.runTransaction((transaction) async {
        // Add user to subscribers
        transaction.update(
          _firestore.collection('public_groups').doc(groupId),
          {
            'subscribersUIDs': FieldValue.arrayUnion([currentUser.uid]),
            'subscribersCount': FieldValue.increment(1),
          },
        );

        // Update user's followed public groups
        transaction.update(
          _firestore.collection(Constants.users).doc(currentUser.uid),
          {
            'followedPublicGroups': FieldValue.arrayUnion([groupId]),
          },
        );
      });
    } catch (e) {
      debugPrint('Error subscribing to public group: $e');
      throw e.toString();
    }
  }

  /// Unsubscribe from a public group
  Future<void> unsubscribeFromPublicGroup(String groupId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.runTransaction((transaction) async {
        // Remove user from subscribers
        transaction.update(
          _firestore.collection('public_groups').doc(groupId),
          {
            'subscribersUIDs': FieldValue.arrayRemove([currentUser.uid]),
            'subscribersCount': FieldValue.increment(-1),
          },
        );

        // Update user's followed public groups
        transaction.update(
          _firestore.collection(Constants.users).doc(currentUser.uid),
          {
            'followedPublicGroups': FieldValue.arrayRemove([groupId]),
          },
        );
      });
    } catch (e) {
      debugPrint('Error unsubscribing from public group: $e');
      throw e.toString();
    }
  }

  /// Create a post in public group
  Future<PublicGroupPostModel> createPost({
    required String groupId,
    required String content,
    required MessageEnum postType,
    List<File>? mediaFiles,
    bool isPinned = false,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get user data for author info
      final userDoc = await _firestore.collection(Constants.users).doc(currentUser.uid).get();
      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      final userData = userDoc.data()!;
      final postId = const Uuid().v4();
      final createdAt = DateTime.now().millisecondsSinceEpoch.toString();

      // Upload media files if provided
      List<String> mediaUrls = [];
      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        for (int i = 0; i < mediaFiles.length; i++) {
          final file = mediaFiles[i];
          final mediaUrl = await storeFileToStorage(
            file: file,
            reference: 'public_groups/$groupId/posts/$postId/media_$i',
          );
          mediaUrls.add(mediaUrl);
        }
      }

      // Create post model
      final post = PublicGroupPostModel(
        postId: postId,
        groupId: groupId,
        authorUID: currentUser.uid,
        authorName: userData[Constants.name] ?? '',
        authorImage: userData[Constants.image] ?? '',
        content: content,
        mediaUrls: mediaUrls,
        postType: postType,
        createdAt: createdAt,
        reactions: {},
        commentsCount: 0,
        reactionsCount: 0,
        isPinned: isPinned,
        metadata: {},
      );

      // Use transaction for atomic operation
      await _firestore.runTransaction((transaction) async {
        // Create post document
        transaction.set(
          _firestore.collection('public_group_posts').doc(postId),
          post.toMap(),
        );

        // Update group's last post time
        transaction.update(
          _firestore.collection('public_groups').doc(groupId),
          {
            'lastPostAt': createdAt,
          },
        );
      });

      return post;
    } catch (e) {
      debugPrint('Error creating post: $e');
      throw e.toString();
    }
  }

  /// Get posts for a public group
  Future<List<PublicGroupPostModel>> getPublicGroupPosts(String groupId) async {
    try {
      final querySnapshot = await _firestore
          .collection('public_group_posts')
          .where('groupId', isEqualTo: groupId)
          .orderBy('isPinned', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs.map((doc) {
        return PublicGroupPostModel.fromMap(doc.data());
      }).toList();
    } catch (e) {
      debugPrint('Error getting public group posts: $e');
      return [];
    }
  }

  /// Get posts stream for a public group
  Stream<List<PublicGroupPostModel>> getPublicGroupPostsStream(String groupId) {
    return _firestore
        .collection('public_group_posts')
        .where('groupId', isEqualTo: groupId)
        .orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return PublicGroupPostModel.fromMap(doc.data());
          }).toList();
        });
  }

  /// Add reaction to post
  Future<void> addPostReaction(String postId, String emoji) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.runTransaction((transaction) async {
        final postRef = _firestore.collection('public_group_posts').doc(postId);
        final postDoc = await transaction.get(postRef);
        
        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        final currentReactions = Map<String, dynamic>.from(postDoc.data()!['reactions'] ?? {});
        currentReactions[currentUser.uid] = {
          'emoji': emoji,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        transaction.update(postRef, {
          'reactions': currentReactions,
          'reactionsCount': currentReactions.length,
        });
      });
    } catch (e) {
      debugPrint('Error adding post reaction: $e');
      throw e.toString();
    }
  }

  /// Remove reaction from post
  Future<void> removePostReaction(String postId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.runTransaction((transaction) async {
        final postRef = _firestore.collection('public_group_posts').doc(postId);
        final postDoc = await transaction.get(postRef);
        
        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        final currentReactions = Map<String, dynamic>.from(postDoc.data()!['reactions'] ?? {});
        currentReactions.remove(currentUser.uid);

        transaction.update(postRef, {
          'reactions': currentReactions,
          'reactionsCount': currentReactions.length,
        });
      });
    } catch (e) {
      debugPrint('Error removing post reaction: $e');
      throw e.toString();
    }
  }

  /// Add comment to post
  Future<PostCommentModel> addComment({
    required String postId,
    required String content,
    String? repliedToCommentId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get user data for author info
      final userDoc = await _firestore.collection(Constants.users).doc(currentUser.uid).get();
      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      final userData = userDoc.data()!;
      final commentId = const Uuid().v4();
      final createdAt = DateTime.now().millisecondsSinceEpoch.toString();

      // Get post data to find groupId
      final postDoc = await _firestore.collection('public_group_posts').doc(postId).get();
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }
      final postData = postDoc.data()!;

      // Get replied comment author name if this is a reply
      String? repliedToAuthorName;
      if (repliedToCommentId != null) {
        final repliedCommentDoc = await _firestore
            .collection('post_comments')
            .doc(repliedToCommentId)
            .get();
        if (repliedCommentDoc.exists) {
          repliedToAuthorName = repliedCommentDoc.data()!['authorName'];
        }
      }

      // Create comment model
      final comment = PostCommentModel(
        commentId: commentId,
        postId: postId,
        groupId: postData['groupId'],
        authorUID: currentUser.uid,
        authorName: userData[Constants.name] ?? '',
        authorImage: userData[Constants.image] ?? '',
        content: content,
        createdAt: createdAt,
        reactions: {},
        reactionsCount: 0,
        repliedToCommentId: repliedToCommentId,
        repliedToAuthorName: repliedToAuthorName,
      );

      // Use transaction for atomic operation
      await _firestore.runTransaction((transaction) async {
        // Create comment document
        transaction.set(
          _firestore.collection('post_comments').doc(commentId),
          comment.toMap(),
        );

        // Update post's comments count
        transaction.update(
          _firestore.collection('public_group_posts').doc(postId),
          {
            'commentsCount': FieldValue.increment(1),
          },
        );
      });

      return comment;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      throw e.toString();
    }
  }

  /// Get comments for a post
  Future<List<PostCommentModel>> getPostComments(String postId) async {
    try {
      final querySnapshot = await _firestore
          .collection('post_comments')
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        return PostCommentModel.fromMap(doc.data());
      }).toList();
    } catch (e) {
      debugPrint('Error getting post comments: $e');
      return [];
    }
  }

  /// Get comments stream for a post
  Stream<List<PostCommentModel>> getPostCommentsStream(String postId) {
    return _firestore
        .collection('post_comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return PostCommentModel.fromMap(doc.data());
          }).toList();
        });
  }

  /// Search public groups
  Future<List<PublicGroupModel>> searchPublicGroups(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final querySnapshot = await _firestore
          .collection('public_groups')
          .where('groupName', isGreaterThanOrEqualTo: query)
          .where('groupName', isLessThanOrEqualTo: query + '\uf8ff')
          .orderBy('subscribersCount', descending: true)
          .limit(20)
          .get();

      return querySnapshot.docs.map((doc) {
        return PublicGroupModel.fromMap(doc.data());
      }).toList();
    } catch (e) {
      debugPrint('Error searching public groups: $e');
      return [];
    }
  }

  /// Get trending public groups
  Future<List<PublicGroupModel>> getTrendingPublicGroups() async {
    try {
      final querySnapshot = await _firestore
          .collection('public_groups')
          .orderBy('subscribersCount', descending: true)
          .limit(20)
          .get();

      return querySnapshot.docs.map((doc) {
        return PublicGroupModel.fromMap(doc.data());
      }).toList();
    } catch (e) {
      debugPrint('Error getting trending public groups: $e');
      return [];
    }
  }

  /// Update public group
  Future<void> updatePublicGroup(PublicGroupModel updatedGroup, File? newGroupImage) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if user can edit this group
      if (!updatedGroup.canPost(currentUser.uid)) {
        throw Exception('You do not have permission to edit this group');
      }

      // Upload new group image if provided
      if (newGroupImage != null) {
        final imageUrl = await storeFileToStorage(
          file: newGroupImage,
          reference: 'public_groups/${updatedGroup.groupId}/group_image',
        );
        updatedGroup = updatedGroup.copyWith(groupImage: imageUrl);
      }

      await _firestore.collection('public_groups').doc(updatedGroup.groupId).update(updatedGroup.toMap());
    } catch (e) {
      debugPrint('Error updating public group: $e');
      throw e.toString();
    }
  }

  /// Toggle post pin status
  Future<void> togglePostPin(String postId, bool isPinned) async {
    try {
      await _firestore.collection('public_group_posts').doc(postId).update({
        'isPinned': isPinned,
      });
    } catch (e) {
      debugPrint('Error toggling post pin: $e');
      throw e.toString();
    }
  }

  /// Delete post
  Future<void> deletePost(String postId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get post to check ownership
      final postDoc = await _firestore.collection('public_group_posts').doc(postId).get();
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final postData = postDoc.data()!;
      if (postData['authorUID'] != currentUser.uid) {
        // Check if user is admin of the group
        final groupDoc = await _firestore.collection('public_groups').doc(postData['groupId']).get();
        if (groupDoc.exists) {
          final groupData = groupDoc.data()!;
          final adminUIDs = List<String>.from(groupData['adminUIDs'] ?? []);
          if (!adminUIDs.contains(currentUser.uid) && groupData['creatorUID'] != currentUser.uid) {
            throw Exception('You do not have permission to delete this post');
          }
        } else {
          throw Exception('You do not have permission to delete this post');
        }
      }

      await _firestore.runTransaction((transaction) async {
        // Delete post
        transaction.delete(_firestore.collection('public_group_posts').doc(postId));

        // Delete all comments for this post
        final commentsQuery = await _firestore
            .collection('post_comments')
            .where('postId', isEqualTo: postId)
            .get();
        
        for (final commentDoc in commentsQuery.docs) {
          transaction.delete(commentDoc.reference);
        }
      });
    } catch (e) {
      debugPrint('Error deleting post: $e');
      throw e.toString();
    }
  }

  /// Add reaction to comment
  Future<void> addCommentReaction(String commentId, String emoji) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.runTransaction((transaction) async {
        final commentRef = _firestore.collection('post_comments').doc(commentId);
        final commentDoc = await transaction.get(commentRef);
        
        if (!commentDoc.exists) {
          throw Exception('Comment not found');
        }

        final currentReactions = Map<String, dynamic>.from(commentDoc.data()!['reactions'] ?? {});
        currentReactions[currentUser.uid] = {
          'emoji': emoji,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        transaction.update(commentRef, {
          'reactions': currentReactions,
          'reactionsCount': currentReactions.length,
        });
      });
    } catch (e) {
      debugPrint('Error adding comment reaction: $e');
      throw e.toString();
    }
  }

  /// Remove reaction from comment
  Future<void> removeCommentReaction(String commentId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.runTransaction((transaction) async {
        final commentRef = _firestore.collection('post_comments').doc(commentId);
        final commentDoc = await transaction.get(commentRef);
        
        if (!commentDoc.exists) {
          throw Exception('Comment not found');
        }

        final currentReactions = Map<String, dynamic>.from(commentDoc.data()!['reactions'] ?? {});
        currentReactions.remove(currentUser.uid);

        transaction.update(commentRef, {
          'reactions': currentReactions,
          'reactionsCount': currentReactions.length,
        });
      });
    } catch (e) {
      debugPrint('Error removing comment reaction: $e');
      throw e.toString();
    }
  }

  /// Delete comment
  Future<void> deleteComment(String commentId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get comment to check ownership
      final commentDoc = await _firestore.collection('post_comments').doc(commentId).get();
      if (!commentDoc.exists) {
        throw Exception('Comment not found');
      }

      final commentData = commentDoc.data()!;
      if (commentData['authorUID'] != currentUser.uid) {
        // Check if user is admin of the group
        final groupDoc = await _firestore.collection('public_groups').doc(commentData['groupId']).get();
        if (groupDoc.exists) {
          final groupData = groupDoc.data()!;
          final adminUIDs = List<String>.from(groupData['adminUIDs'] ?? []);
          if (!adminUIDs.contains(currentUser.uid) && groupData['creatorUID'] != currentUser.uid) {
            throw Exception('You do not have permission to delete this comment');
          }
        } else {
          throw Exception('You do not have permission to delete this comment');
        }
      }

      await _firestore.runTransaction((transaction) async {
        // Delete comment
        transaction.delete(_firestore.collection('post_comments').doc(commentId));

        // Update post's comments count
        transaction.update(
          _firestore.collection('public_group_posts').doc(commentData['postId']),
          {
            'commentsCount': FieldValue.increment(-1),
          },
        );
      });
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      throw e.toString();
    }
  }

  /// Get public groups where user is admin/creator
  Future<List<PublicGroupModel>> getUserCreatedPublicGroups() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final querySnapshot = await _firestore
          .collection('public_groups')
          .where('creatorUID', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return PublicGroupModel.fromMap(doc.data());
      }).toList();
    } catch (e) {
      debugPrint('Error getting user created public groups: $e');
      return [];
    }
  }

  /// Add admin to public group
  Future<void> addAdmin(String groupId, String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if current user can add admins
      final groupDoc = await _firestore.collection('public_groups').doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final groupData = groupDoc.data()!;
      if (groupData['creatorUID'] != currentUser.uid) {
        throw Exception('Only the creator can add admins');
      }

      await _firestore.collection('public_groups').doc(groupId).update({
        'adminUIDs': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('Error adding admin: $e');
      throw e.toString();
    }
  }

  /// Remove admin from public group
  Future<void> removeAdmin(String groupId, String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if current user can remove admins
      final groupDoc = await _firestore.collection('public_groups').doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final groupData = groupDoc.data()!;
      if (groupData['creatorUID'] != currentUser.uid) {
        throw Exception('Only the creator can remove admins');
      }

      // Don't allow removing the creator as admin
      if (groupData['creatorUID'] == userId) {
        throw Exception('Cannot remove the creator as admin');
      }

      await _firestore.collection('public_groups').doc(groupId).update({
        'adminUIDs': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      debugPrint('Error removing admin: $e');
      throw e.toString();
    }
  }

  /// Get public group statistics
  Future<Map<String, dynamic>> getPublicGroupStats(String groupId) async {
    try {
      // Get group data
      final groupDoc = await _firestore.collection('public_groups').doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final groupData = groupDoc.data()!;

      // Get posts count
      final postsQuery = await _firestore
          .collection('public_group_posts')
          .where('groupId', isEqualTo: groupId)
          .get();

      // Get total reactions count
      int totalReactions = 0;
      int totalComments = 0;
      
      for (final postDoc in postsQuery.docs) {
        final postData = postDoc.data();
        totalReactions += (postData['reactionsCount'] as int? ?? 0);
        totalComments += (postData['commentsCount'] as int? ?? 0);
      }

      return {
        'subscribersCount': groupData['subscribersCount'] ?? 0,
        'postsCount': postsQuery.docs.length,
        'totalReactions': totalReactions,
        'totalComments': totalComments,
        'createdAt': groupData['createdAt'] ?? '',
        'lastPostAt': groupData['lastPostAt'] ?? '',
      };
    } catch (e) {
      debugPrint('Error getting public group stats: $e');
      return {};
    }
  }
}

// Provider for the public group repository
final publicGroupRepositoryProvider = Provider((ref) {
  return PublicGroupRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});
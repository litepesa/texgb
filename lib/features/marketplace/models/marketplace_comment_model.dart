// ===============================
// lib/features/marketplace/models/marketplace_comment_model.dart
// Twitter-Style Comment/Reply Model
// 
// FEATURES:
// 1. Nested replies (reply to reply to reply...)
// 2. Like comments
// 3. Reply chains
// 4. Rich interactions
// 5. Verification badges
// 6. Edit tracking
// 7. Pin comments (thread author can pin)
// 8. Sort options (Top, Latest, Oldest)
// 
// ANTI-SPAM MEASURES:
// - Character limit: 150 characters (TikTok-style)
// - Image limit: 0-1 image per comment (single image only)
// - User banning: Handled at user model level (canComment field)
// ===============================

import 'dart:convert';

class MarketplaceCommentModel {
  // Core identification
  final String id;
  final String threadId;              // Which thread this comment belongs to
  final String userId;                // Comment author
  final String userName;
  final String userImage;
  final bool isVerified;

  // Content
  final String content;

  // Media (optional - comments can have images like Twitter)
  final List<String> imageUrls;      // 0-1 image for comments (single image only)

  // Engagement metrics
  final int likes;
  final int replies;                 // Number of replies to this comment

  // Reply properties (nested threading)
  final bool isReply;                // Is this a reply to another comment?
  final String? parentCommentId;     // Comment being replied to
  final String? replyToUserId;
  final String? replyToUserName;

  // Comment properties
  final bool isPinned;               // Thread author can pin comment
  final bool isEdited;
  final String? editedAt;
  final bool isActive;               // Soft delete support

  // Timestamps
  final String createdAt;            // RFC3339 format
  final String updatedAt;

  // Runtime state (not stored in DB)
  final bool isLiked;                // Did current user like this?
  final bool isAuthor;               // Is current user the comment author?
  final bool isThreadAuthor;         // Is current user the thread author?
  final int depth;                   // Reply depth (0 = top-level, 1 = reply, 2 = reply to reply, etc.)
  final List<MarketplaceCommentModel> replyList; // Nested replies (for UI tree building)

  const MarketplaceCommentModel({
    required this.id,
    required this.threadId,
    required this.userId,
    required this.userName,
    required this.userImage,
    this.isVerified = false,
    required this.content,
    this.imageUrls = const [],
    this.likes = 0,
    this.replies = 0,
    this.isReply = false,
    this.parentCommentId,
    this.replyToUserId,
    this.replyToUserName,
    this.isPinned = false,
    this.isEdited = false,
    this.editedAt,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.isLiked = false,
    this.isAuthor = false,
    this.isThreadAuthor = false,
    this.depth = 0,
    this.replyList = const [],
  });

  // ===============================
  // FACTORY CONSTRUCTORS
  // ===============================

  factory MarketplaceCommentModel.fromJson(Map<String, dynamic> json) {
    try {
      return MarketplaceCommentModel(
        id: _parseString(json['id']),
        threadId: _parseString(json['threadId'] ?? json['thread_id']),
        userId: _parseString(json['userId'] ?? json['user_id']),
        userName: _parseString(json['userName'] ?? json['user_name']),
        userImage: _parseString(json['userImage'] ?? json['user_image']),
        isVerified: _parseBool(json['isVerified'] ?? json['is_verified'] ?? false),
        
        content: _parseString(json['content']),
        imageUrls: _parseStringList(json['imageUrls'] ?? json['image_urls']),
        
        likes: _parseCount(json['likes'] ?? json['likesCount'] ?? json['likes_count'] ?? 0),
        replies: _parseCount(json['replies'] ?? json['repliesCount'] ?? json['replies_count'] ?? 0),
        
        isReply: _parseBool(json['isReply'] ?? json['is_reply'] ?? false),
        parentCommentId: _parseStringOrNull(json['parentCommentId'] ?? json['parent_comment_id']),
        replyToUserId: _parseStringOrNull(json['replyToUserId'] ?? json['reply_to_user_id']),
        replyToUserName: _parseStringOrNull(json['replyToUserName'] ?? json['reply_to_user_name']),
        
        isPinned: _parseBool(json['isPinned'] ?? json['is_pinned'] ?? false),
        isEdited: _parseBool(json['isEdited'] ?? json['is_edited'] ?? false),
        editedAt: _parseStringOrNull(json['editedAt'] ?? json['edited_at']),
        isActive: _parseBool(json['isActive'] ?? json['is_active'] ?? true),
        
        createdAt: _parseTimestamp(json['createdAt'] ?? json['created_at']),
        updatedAt: _parseTimestamp(json['updatedAt'] ?? json['updated_at']),
        
        isLiked: _parseBool(json['isLiked'] ?? false),
        isAuthor: _parseBool(json['isAuthor'] ?? false),
        isThreadAuthor: _parseBool(json['isThreadAuthor'] ?? false),
        depth: _parseInt(json['depth'] ?? 0),
        replyList: _parseCommentList(json['replyList'] ?? json['reply_list']),
      );
    } catch (e) {
      print('❌ Error parsing MarketplaceCommentModel from JSON: $e');
      print('📄 JSON data: $json');
      
      // Return safe default
      return MarketplaceCommentModel(
        id: _parseString(json['id'] ?? ''),
        threadId: _parseString(json['threadId'] ?? ''),
        userId: _parseString(json['userId'] ?? ''),
        userName: _parseString(json['userName'] ?? 'Unknown'),
        userImage: '',
        content: _parseString(json['content'] ?? 'No content'),
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );
    }
  }

  // Factory for creating new comment
  factory MarketplaceCommentModel.create({
    required String threadId,
    required String userId,
    required String userName,
    required String userImage,
    bool isVerified = false,
    required String content,
    List<String>? imageUrls,
    String? parentCommentId,
    String? replyToUserId,
    String? replyToUserName,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();

    return MarketplaceCommentModel(
      id: '', // Will be set by backend
      threadId: threadId,
      userId: userId,
      userName: userName,
      userImage: userImage,
      isVerified: isVerified,
      content: content,
      imageUrls: imageUrls ?? [],
      isReply: parentCommentId != null,
      parentCommentId: parentCommentId,
      replyToUserId: replyToUserId,
      replyToUserName: replyToUserName,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ===============================
  // PARSING HELPERS
  // ===============================

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static String? _parseStringOrNull(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return false;
  }

  static int _parseCount(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value < 0 ? 0 : value;
    if (value is double) return value < 0 ? 0 : value.round();
    if (value is String) {
      if (value.trim().isEmpty) return 0;
      final parsed = int.tryParse(value.trim());
      return parsed != null && parsed >= 0 ? parsed : 0;
    }
    return 0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value < 0 ? 0 : value;
    if (value is double) return value < 0 ? 0 : value.round();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      return parsed != null && parsed >= 0 ? parsed : 0;
    }
    return 0;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    
    if (value is List) {
      final parsed = value
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      
      // Enforce single image limit
      return parsed.isEmpty ? [] : [parsed.first];
    }
    
    if (value is String && value.isNotEmpty) {
      final trimmed = value.trim();
      
      // PostgreSQL array format
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        final content = trimmed.substring(1, trimmed.length - 1);
        if (content.isEmpty) return [];
        
        final images = content
            .split(',')
            .map((item) {
              final cleaned = item.trim();
              if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
                return cleaned.substring(1, cleaned.length - 1);
              }
              return cleaned;
            })
            .where((s) => s.isNotEmpty)
            .toList();

        // Enforce single image limit
        return images.isEmpty ? [] : [images.first];
      }
      
      // JSON array format
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          final decoded = json.decode(trimmed);
          if (decoded is List) {
            final parsed = decoded
                .map((e) => e?.toString() ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
            
            // Enforce single image limit
            return parsed.isEmpty ? [] : [parsed.first];
          }
        } catch (e) {
          print('⚠️ Warning: Could not parse JSON array: $trimmed');
        }
      }
      
      // Single string - treat as single image URL
      return [trimmed];
    }
    
    return [];
  }

  static List<MarketplaceCommentModel> _parseCommentList(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value
          .map((e) {
            if (e is Map<String, dynamic>) {
              return MarketplaceCommentModel.fromJson(e);
            }
            return null;
          })
          .where((comment) => comment != null)
          .cast<MarketplaceCommentModel>()
          .toList();
    }

    if (value is String && value.isNotEmpty) {
      try {
        final decoded = json.decode(value);
        if (decoded is List) {
          return decoded
              .map((e) {
                if (e is Map<String, dynamic>) {
                  return MarketplaceCommentModel.fromJson(e);
                }
                return null;
              })
              .where((comment) => comment != null)
              .cast<MarketplaceCommentModel>()
              .toList();
        }
      } catch (e) {
        print('⚠️ Warning: Could not parse comment list: $value');
      }
    }

    return [];
  }

  static String _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now().toIso8601String();
    
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return DateTime.now().toIso8601String();
      
      try {
        final dateTime = DateTime.parse(trimmed);
        return dateTime.toIso8601String();
      } catch (e) {
        return DateTime.now().toIso8601String();
      }
    }
    
    if (value is DateTime) {
      return value.toIso8601String();
    }
    
    return DateTime.now().toIso8601String();
  }

  // ===============================
  // CONVERSION METHODS
  // ===============================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'threadId': threadId,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'isVerified': isVerified,
      'content': content,
      'imageUrls': imageUrls,
      'likes': likes,
      'replies': replies,
      'isReply': isReply,
      'parentCommentId': parentCommentId,
      'replyToUserId': replyToUserId,
      'replyToUserName': replyToUserName,
      'isPinned': isPinned,
      'isEdited': isEdited,
      'editedAt': editedAt,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isLiked': isLiked,
      'isAuthor': isAuthor,
      'isThreadAuthor': isThreadAuthor,
      'depth': depth,
      'replyList': replyList.map((c) => c.toJson()).toList(),
    };
  }

  MarketplaceCommentModel copyWith({
    String? id,
    String? threadId,
    String? userId,
    String? userName,
    String? userImage,
    bool? isVerified,
    String? content,
    List<String>? imageUrls,
    int? likes,
    int? replies,
    bool? isReply,
    String? parentCommentId,
    String? replyToUserId,
    String? replyToUserName,
    bool? isPinned,
    bool? isEdited,
    String? editedAt,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
    bool? isLiked,
    bool? isAuthor,
    bool? isThreadAuthor,
    int? depth,
    List<MarketplaceCommentModel>? replyList,
  }) {
    return MarketplaceCommentModel(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      isVerified: isVerified ?? this.isVerified,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      likes: likes ?? this.likes,
      replies: replies ?? this.replies,
      isReply: isReply ?? this.isReply,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replyToUserId: replyToUserId ?? this.replyToUserId,
      replyToUserName: replyToUserName ?? this.replyToUserName,
      isPinned: isPinned ?? this.isPinned,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLiked: isLiked ?? this.isLiked,
      isAuthor: isAuthor ?? this.isAuthor,
      isThreadAuthor: isThreadAuthor ?? this.isThreadAuthor,
      depth: depth ?? this.depth,
      replyList: replyList ?? this.replyList,
    );
  }

  // ===============================
  // CONTENT HELPERS
  // ===============================

  bool get hasImages => imageUrls.isNotEmpty;
  int get imageCount => imageUrls.length;
  
  bool get isTopLevel => !isReply; // Top-level comment (not a reply)
  bool get hasReplies => replies > 0;
  bool get isNested => depth > 0;
  bool get canReply => depth < 5; // Limit reply depth to 5 levels
  
  int get characterCount => content.length;
  
  // Extract mentions from content
  List<String> get mentionsInContent {
    final regex = RegExp(r'@(\w+)');
    final matches = regex.allMatches(content);
    return matches.map((m) => m.group(1)!).toList();
  }

  // ===============================
  // DISPLAY FORMATTING
  // ===============================

  String get formattedLikes => _formatCount(likes);
  String get formattedReplies => _formatCount(replies);

  static String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  // Timestamps
  DateTime get createdAtDateTime {
    try {
      return DateTime.parse(createdAt);
    } catch (e) {
      return DateTime.now();
    }
  }

  DateTime get updatedAtDateTime {
    try {
      return DateTime.parse(updatedAt);
    } catch (e) {
      return DateTime.now();
    }
  }

  DateTime? get editedAtDateTime {
    if (editedAt == null) return null;
    try {
      return DateTime.parse(editedAt!);
    } catch (e) {
      return null;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final created = createdAtDateTime;
    final difference = now.difference(created);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  // ===============================
  // INTERACTION METHODS
  // ===============================

  MarketplaceCommentModel toggleLike() {
    return copyWith(
      isLiked: !isLiked,
      likes: isLiked ? likes - 1 : likes + 1,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  MarketplaceCommentModel incrementReplies() {
    return copyWith(
      replies: replies + 1,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  MarketplaceCommentModel decrementReplies() {
    return copyWith(
      replies: replies > 0 ? replies - 1 : 0,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  MarketplaceCommentModel togglePin() {
    return copyWith(
      isPinned: !isPinned,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  MarketplaceCommentModel markAsEdited() {
    return copyWith(
      isEdited: true,
      editedAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  MarketplaceCommentModel deactivate() {
    return copyWith(
      isActive: false,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // Add reply to reply list
  MarketplaceCommentModel addReply(MarketplaceCommentModel reply) {
    final updatedReplyList = List<MarketplaceCommentModel>.from(replyList)..add(reply);
    return copyWith(
      replyList: updatedReplyList,
      replies: replies + 1,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // ===============================
  // VALIDATION
  // ===============================

  bool get isValid {
    return id.isNotEmpty &&
           threadId.isNotEmpty &&
           userId.isNotEmpty &&
           userName.isNotEmpty &&
           content.isNotEmpty &&
           content.length <= 150 &&
           imageUrls.length <= 1 &&
           depth <= 5;
  }

  List<String> get validationErrors {
    final errors = <String>[];
    
    if (id.isEmpty) errors.add('ID is required');
    if (threadId.isEmpty) errors.add('Thread ID is required');
    if (userId.isEmpty) errors.add('User ID is required');
    if (userName.isEmpty) errors.add('User name is required');
    if (content.isEmpty) errors.add('Content is required');
    if (content.length > 150) errors.add('Content exceeds 150 characters');
    if (imageUrls.length > 1) errors.add('Maximum 1 image allowed per comment');
    if (depth > 5) errors.add('Maximum reply depth is 5 levels');
    if (isReply && parentCommentId == null) errors.add('Parent comment ID required for replies');
    
    return errors;
  }

  // ===============================
  // DEBUG & DISPLAY
  // ===============================

  @override
  String toString() {
    final contentPreview = content.length > 30 ? "${content.substring(0, 30)}..." : content;
    return 'MarketplaceCommentModel(id: $id, user: $userName, content: "$contentPreview", likes: $likes, replies: $replies, depth: $depth)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MarketplaceCommentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ===============================
// EXTENSIONS FOR LISTS
// ===============================

extension MarketplaceCommentModelList on List<MarketplaceCommentModel> {
  // Filter by type
  List<MarketplaceCommentModel> get activeComments => where((c) => c.isActive).toList();
  List<MarketplaceCommentModel> get pinnedComments => where((c) => c.isPinned).toList();
  List<MarketplaceCommentModel> get topLevelComments => where((c) => c.isTopLevel).toList();
  List<MarketplaceCommentModel> get replies => where((c) => c.isReply).toList();
  List<MarketplaceCommentModel> get verifiedComments => where((c) => c.isVerified).toList();
  List<MarketplaceCommentModel> get commentsWithImages => where((c) => c.hasImages).toList();
  List<MarketplaceCommentModel> get commentsWithReplies => where((c) => c.hasReplies).toList();

  // Sorting
  List<MarketplaceCommentModel> sortByLikes({bool descending = true}) {
    final sorted = List<MarketplaceCommentModel>.from(this);
    sorted.sort((a, b) => descending ? b.likes.compareTo(a.likes) : a.likes.compareTo(b.likes));
    return sorted;
  }

  List<MarketplaceCommentModel> sortByReplies({bool descending = true}) {
    final sorted = List<MarketplaceCommentModel>.from(this);
    sorted.sort((a, b) => descending ? b.replies.compareTo(a.replies) : a.replies.compareTo(b.replies));
    return sorted;
  }

  List<MarketplaceCommentModel> sortByDate({bool descending = true}) {
    final sorted = List<MarketplaceCommentModel>.from(this);
    sorted.sort((a, b) => descending
        ? b.createdAtDateTime.compareTo(a.createdAtDateTime)
        : a.createdAtDateTime.compareTo(b.createdAtDateTime));
    return sorted;
  }

  // Twitter-style sorting
  List<MarketplaceCommentModel> get sortedByTop => sortByLikes(descending: true);
  List<MarketplaceCommentModel> get sortedByLatest => sortByDate(descending: true);
  List<MarketplaceCommentModel> get sortedByOldest => sortByDate(descending: false);

  // Filtering
  List<MarketplaceCommentModel> filterByUser(String userId) {
    return where((c) => c.userId == userId).toList();
  }

  List<MarketplaceCommentModel> filterByThread(String threadId) {
    return where((c) => c.threadId == threadId).toList();
  }

  List<MarketplaceCommentModel> filterByParent(String? parentCommentId) {
    if (parentCommentId == null) return topLevelComments;
    return where((c) => c.parentCommentId == parentCommentId).toList();
  }
  
  // Metrics
  int get totalLikes => fold<int>(0, (sum, c) => sum + c.likes);
  int get totalReplies => fold<int>(0, (sum, c) => sum + c.replies);
  
  // Build threaded comment tree
  List<MarketplaceCommentModel> buildTree() {
    // Get all top-level comments
    final topLevel = topLevelComments;

    // Build reply tree for each top-level comment
    return topLevel.map((comment) {
      return _buildReplyTree(comment, this);
    }).toList();
  }

  static MarketplaceCommentModel _buildReplyTree(MarketplaceCommentModel comment, List<MarketplaceCommentModel> allComments) {
    // Find direct replies to this comment
    final directReplies = allComments
        .where((c) => c.parentCommentId == comment.id)
        .toList();

    // Recursively build reply tree for each reply
    final replyTree = directReplies.map((reply) {
      return _buildReplyTree(
        reply.copyWith(depth: comment.depth + 1),
        allComments,
      );
    }).toList();

    return comment.copyWith(replyList: replyTree);
  }

  // Flatten tree back to list
  List<MarketplaceCommentModel> flattenTree() {
    final flattened = <MarketplaceCommentModel>[];

    void flatten(MarketplaceCommentModel comment) {
      flattened.add(comment);
      for (final reply in comment.replyList) {
        flatten(reply);
      }
    }

    for (final comment in this) {
      flatten(comment);
    }

    return flattened;
  }
}
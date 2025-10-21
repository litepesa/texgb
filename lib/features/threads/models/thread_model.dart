// ===============================
// lib/features/threads/models/thread_model.dart
// Complete Thread Model for Regular Posts (Replacing VideoModel)
// 
// FEATURES:
// 1. Text posts (up to 500 characters)
// 2. Image galleries (1-4 images)
// 3. Single video posts (up to 5 minutes)
// 4. Polls (verified users only, 2-4 options)
// 5. Full social interactions (likes, replies, reposts)
// 6. Hashtags for discovery
// 7. Link previews
// 8. Verification badges
// 9. All users can create (except polls = verified only)
// ===============================

import 'dart:convert';

// Poll Option Model
class PollOption {
  final String id;
  final String text;
  final int votes;
  
  const PollOption({
    required this.id,
    required this.text,
    this.votes = 0,
  });
  
  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      votes: json['votes'] is int ? json['votes'] : int.tryParse(json['votes']?.toString() ?? '0') ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'votes': votes,
    };
  }
  
  PollOption copyWith({String? id, String? text, int? votes}) {
    return PollOption(
      id: id ?? this.id,
      text: text ?? this.text,
      votes: votes ?? this.votes,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PollOption && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}

class ThreadModel {
  // Core identification
  final String id;
  final String userId;
  final String userName;
  final String userImage;
  final bool isVerified;
  
  // Content
  final String content;
  
  // Media (can have video + images together, like Threads app)
  final List<String> imageUrls;          // 0-4 images
  final String? videoUrl;                // Single video (5 min max)
  final String? videoThumbnailUrl;       // Video thumbnail
  final int? videoDurationSeconds;       // Video length in seconds (max 300)
  
  // Link preview (for URLs in content)
  final String? linkPreviewUrl;
  final String? linkPreviewTitle;
  final String? linkPreviewDescription;
  final String? linkPreviewImage;
  
  // Poll (VERIFIED USERS ONLY)
  final bool hasPoll;                    // Does thread have a poll?
  final String? pollQuestion;            // Poll question (optional, can use thread content)
  final List<PollOption> pollOptions;    // 2-4 poll options
  final int? pollDurationHours;          // Poll duration (24, 48, 72 hours, or 7 days)
  final String? pollEndsAt;              // When poll expires (RFC3339)
  final bool? pollAllowMultipleChoices;  // Allow voting for multiple options
  final int pollTotalVotes;              // Total votes cast
  
  // Engagement metrics
  final int likes;
  final int replies;
  final int reposts;
  final int views;
  
  // Categorization
  final List<String> tags;               // Hashtags for discovery
  
  // Thread properties
  final bool isActive;
  final bool isPinned;                   // Pin to user profile
  final bool isEdited;
  final String? editedAt;
  
  // Reply thread properties (for threaded conversations)
  final bool isReply;
  final String? parentThreadId;          // Original thread being replied to
  final String? replyToUserId;
  final String? replyToUserName;
  
  // Repost properties (sharing others' content)
  final bool isRepost;
  final String? originalThreadId;        // Original thread being shared
  final String? originalUserId;          // Original creator (CRITICAL for revenue)
  final String? originalUserName;
  final String? repostedAt;
  
  // Timestamps
  final String createdAt;                // RFC3339 format
  final String updatedAt;                // RFC3339 format

  // Runtime state (not stored in DB)
  final bool isLiked;                    // Did current user like this?
  final bool isReposted;                 // Did current user repost this?
  final bool isFollowing;                // Is current user following author?
  final String? userVotedOptionId;       // Which poll option did user vote for?

  const ThreadModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImage,
    this.isVerified = false,
    required this.content,
    this.imageUrls = const [],
    this.videoUrl,
    this.videoThumbnailUrl,
    this.videoDurationSeconds,
    this.linkPreviewUrl,
    this.linkPreviewTitle,
    this.linkPreviewDescription,
    this.linkPreviewImage,
    this.hasPoll = false,
    this.pollQuestion,
    this.pollOptions = const [],
    this.pollDurationHours,
    this.pollEndsAt,
    this.pollAllowMultipleChoices = false,
    this.pollTotalVotes = 0,
    this.likes = 0,
    this.replies = 0,
    this.reposts = 0,
    this.views = 0,
    this.tags = const [],
    this.isActive = true,
    this.isPinned = false,
    this.isEdited = false,
    this.editedAt,
    this.isReply = false,
    this.parentThreadId,
    this.replyToUserId,
    this.replyToUserName,
    this.isRepost = false,
    this.originalThreadId,
    this.originalUserId,
    this.originalUserName,
    this.repostedAt,
    required this.createdAt,
    required this.updatedAt,
    this.isLiked = false,
    this.isReposted = false,
    this.isFollowing = false,
    this.userVotedOptionId,
  });

  // ===============================
  // FACTORY CONSTRUCTORS
  // ===============================

  factory ThreadModel.fromJson(Map<String, dynamic> json) {
    try {
      return ThreadModel(
        id: _parseString(json['id']),
        userId: _parseString(json['userId'] ?? json['user_id']),
        userName: _parseString(json['userName'] ?? json['user_name']),
        userImage: _parseString(json['userImage'] ?? json['user_image']),
        isVerified: _parseBool(json['isVerified'] ?? json['is_verified'] ?? false),
        
        content: _parseString(json['content']),
        imageUrls: _parseStringList(json['imageUrls'] ?? json['image_urls']),
        videoUrl: _parseStringOrNull(json['videoUrl'] ?? json['video_url']),
        videoThumbnailUrl: _parseStringOrNull(json['videoThumbnailUrl'] ?? json['video_thumbnail_url']),
        videoDurationSeconds: _parseIntOrNull(json['videoDurationSeconds'] ?? json['video_duration_seconds']),
        
        linkPreviewUrl: _parseStringOrNull(json['linkPreviewUrl'] ?? json['link_preview_url']),
        linkPreviewTitle: _parseStringOrNull(json['linkPreviewTitle'] ?? json['link_preview_title']),
        linkPreviewDescription: _parseStringOrNull(json['linkPreviewDescription'] ?? json['link_preview_description']),
        linkPreviewImage: _parseStringOrNull(json['linkPreviewImage'] ?? json['link_preview_image']),
        
        hasPoll: _parseBool(json['hasPoll'] ?? json['has_poll'] ?? false),
        pollQuestion: _parseStringOrNull(json['pollQuestion'] ?? json['poll_question']),
        pollOptions: _parsePollOptions(json['pollOptions'] ?? json['poll_options']),
        pollDurationHours: _parseIntOrNull(json['pollDurationHours'] ?? json['poll_duration_hours']),
        pollEndsAt: _parseStringOrNull(json['pollEndsAt'] ?? json['poll_ends_at']),
        pollAllowMultipleChoices: _parseBoolOrNull(json['pollAllowMultipleChoices'] ?? json['poll_allow_multiple_choices']),
        pollTotalVotes: _parseCount(json['pollTotalVotes'] ?? json['poll_total_votes'] ?? 0),
        
        likes: _parseCount(json['likes'] ?? json['likesCount'] ?? json['likes_count'] ?? 0),
        replies: _parseCount(json['replies'] ?? json['repliesCount'] ?? json['replies_count'] ?? 0),
        reposts: _parseCount(json['reposts'] ?? json['repostsCount'] ?? json['reposts_count'] ?? 0),
        views: _parseCount(json['views'] ?? json['viewsCount'] ?? json['views_count'] ?? 0),
        
        tags: _parseStringList(json['tags']),
        
        isActive: _parseBool(json['isActive'] ?? json['is_active'] ?? true),
        isPinned: _parseBool(json['isPinned'] ?? json['is_pinned'] ?? false),
        isEdited: _parseBool(json['isEdited'] ?? json['is_edited'] ?? false),
        editedAt: _parseStringOrNull(json['editedAt'] ?? json['edited_at']),
        
        isReply: _parseBool(json['isReply'] ?? json['is_reply'] ?? false),
        parentThreadId: _parseStringOrNull(json['parentThreadId'] ?? json['parent_thread_id']),
        replyToUserId: _parseStringOrNull(json['replyToUserId'] ?? json['reply_to_user_id']),
        replyToUserName: _parseStringOrNull(json['replyToUserName'] ?? json['reply_to_user_name']),
        
        isRepost: _parseBool(json['isRepost'] ?? json['is_repost'] ?? false),
        originalThreadId: _parseStringOrNull(json['originalThreadId'] ?? json['original_thread_id']),
        originalUserId: _parseStringOrNull(json['originalUserId'] ?? json['original_user_id']),
        originalUserName: _parseStringOrNull(json['originalUserName'] ?? json['original_user_name']),
        repostedAt: _parseStringOrNull(json['repostedAt'] ?? json['reposted_at']),
        
        createdAt: _parseTimestamp(json['createdAt'] ?? json['created_at']),
        updatedAt: _parseTimestamp(json['updatedAt'] ?? json['updated_at']),
        
        isLiked: _parseBool(json['isLiked'] ?? false),
        isReposted: _parseBool(json['isReposted'] ?? false),
        isFollowing: _parseBool(json['isFollowing'] ?? false),
        userVotedOptionId: _parseStringOrNull(json['userVotedOptionId'] ?? json['user_voted_option_id']),
      );
    } catch (e) {
      print('❌ Error parsing ThreadModel from JSON: $e');
      print('📄 JSON data: $json');
      
      // Return safe default
      return ThreadModel(
        id: _parseString(json['id'] ?? ''),
        userId: _parseString(json['userId'] ?? json['user_id'] ?? ''),
        userName: _parseString(json['userName'] ?? json['user_name'] ?? 'Unknown'),
        userImage: '',
        content: _parseString(json['content'] ?? 'No content'),
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );
    }
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

  static bool? _parseBoolOrNull(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return null;
  }

  static int _parseCount(dynamic value) {
    if (value == null) return 0;
    
    if (value is int) return value < 0 ? 0 : value;
    if (value is double) return value < 0 ? 0 : value.round();
    
    if (value is String) {
      if (value.trim().isEmpty) return 0;
      
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed < 0 ? 0 : parsed;
      
      final parsedDouble = double.tryParse(value.trim());
      if (parsedDouble != null) return parsedDouble < 0 ? 0 : parsedDouble.round();
    }
    
    print('⚠️ Warning: Could not parse count value: $value');
    return 0;
  }

  static int? _parseIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value.trim());
    if (value is double) return value.round();
    return null;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    
    if (value is List) {
      return value
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    
    if (value is String && value.isNotEmpty) {
      final trimmed = value.trim();
      
      // PostgreSQL array format: {item1,item2}
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        final content = trimmed.substring(1, trimmed.length - 1);
        if (content.isEmpty) return [];
        
        return content
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
      }
      
      // JSON array format
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          final decoded = json.decode(trimmed);
          if (decoded is List) {
            return decoded
                .map((e) => e?.toString() ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
          }
        } catch (e) {
          print('⚠️ Warning: Could not parse JSON array: $trimmed');
        }
      }
      
      // Comma-separated
      if (trimmed.contains(',')) {
        return trimmed
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      
      return [trimmed];
    }
    
    return [];
  }

  static List<PollOption> _parsePollOptions(dynamic value) {
    if (value == null) return [];
    
    if (value is List) {
      return value
          .map((e) {
            if (e is Map<String, dynamic>) {
              return PollOption.fromJson(e);
            }
            return null;
          })
          .where((option) => option != null)
          .cast<PollOption>()
          .toList();
    }
    
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = json.decode(value);
        if (decoded is List) {
          return decoded
              .map((e) {
                if (e is Map<String, dynamic>) {
                  return PollOption.fromJson(e);
                }
                return null;
              })
              .where((option) => option != null)
              .cast<PollOption>()
              .toList();
        }
      } catch (e) {
        print('⚠️ Warning: Could not parse poll options: $value');
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
        print('⚠️ Warning: Could not parse timestamp: $trimmed');
        return DateTime.now().toIso8601String();
      }
    }
    
    if (value is DateTime) {
      return value.toIso8601String();
    }
    
    if (value is int) {
      try {
        final dateTime = DateTime.fromMillisecondsSinceEpoch(value);
        return dateTime.toIso8601String();
      } catch (e) {
        print('⚠️ Warning: Could not parse Unix timestamp: $value');
        return DateTime.now().toIso8601String();
      }
    }
    
    return DateTime.now().toIso8601String();
  }

  // ===============================
  // CONVERSION METHODS
  // ===============================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'isVerified': isVerified,
      'content': content,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'videoThumbnailUrl': videoThumbnailUrl,
      'videoDurationSeconds': videoDurationSeconds,
      'linkPreviewUrl': linkPreviewUrl,
      'linkPreviewTitle': linkPreviewTitle,
      'linkPreviewDescription': linkPreviewDescription,
      'linkPreviewImage': linkPreviewImage,
      'hasPoll': hasPoll,
      'pollQuestion': pollQuestion,
      'pollOptions': pollOptions.map((o) => o.toJson()).toList(),
      'pollDurationHours': pollDurationHours,
      'pollEndsAt': pollEndsAt,
      'pollAllowMultipleChoices': pollAllowMultipleChoices,
      'pollTotalVotes': pollTotalVotes,
      'likes': likes,
      'replies': replies,
      'reposts': reposts,
      'views': views,
      'tags': tags,
      'isActive': isActive,
      'isPinned': isPinned,
      'isEdited': isEdited,
      'editedAt': editedAt,
      'isReply': isReply,
      'parentThreadId': parentThreadId,
      'replyToUserId': replyToUserId,
      'replyToUserName': replyToUserName,
      'isRepost': isRepost,
      'originalThreadId': originalThreadId,
      'originalUserId': originalUserId,
      'originalUserName': originalUserName,
      'repostedAt': repostedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isLiked': isLiked,
      'isReposted': isReposted,
      'isFollowing': isFollowing,
      'userVotedOptionId': userVotedOptionId,
    };
  }

  ThreadModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userImage,
    bool? isVerified,
    String? content,
    List<String>? imageUrls,
    String? videoUrl,
    String? videoThumbnailUrl,
    int? videoDurationSeconds,
    String? linkPreviewUrl,
    String? linkPreviewTitle,
    String? linkPreviewDescription,
    String? linkPreviewImage,
    bool? hasPoll,
    String? pollQuestion,
    List<PollOption>? pollOptions,
    int? pollDurationHours,
    String? pollEndsAt,
    bool? pollAllowMultipleChoices,
    int? pollTotalVotes,
    int? likes,
    int? replies,
    int? reposts,
    int? views,
    List<String>? tags,
    bool? isActive,
    bool? isPinned,
    bool? isEdited,
    String? editedAt,
    bool? isReply,
    String? parentThreadId,
    String? replyToUserId,
    String? replyToUserName,
    bool? isRepost,
    String? originalThreadId,
    String? originalUserId,
    String? originalUserName,
    String? repostedAt,
    String? createdAt,
    String? updatedAt,
    bool? isLiked,
    bool? isReposted,
    bool? isFollowing,
    String? userVotedOptionId,
  }) {
    return ThreadModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      isVerified: isVerified ?? this.isVerified,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      videoThumbnailUrl: videoThumbnailUrl ?? this.videoThumbnailUrl,
      videoDurationSeconds: videoDurationSeconds ?? this.videoDurationSeconds,
      linkPreviewUrl: linkPreviewUrl ?? this.linkPreviewUrl,
      linkPreviewTitle: linkPreviewTitle ?? this.linkPreviewTitle,
      linkPreviewDescription: linkPreviewDescription ?? this.linkPreviewDescription,
      linkPreviewImage: linkPreviewImage ?? this.linkPreviewImage,
      hasPoll: hasPoll ?? this.hasPoll,
      pollQuestion: pollQuestion ?? this.pollQuestion,
      pollOptions: pollOptions ?? this.pollOptions,
      pollDurationHours: pollDurationHours ?? this.pollDurationHours,
      pollEndsAt: pollEndsAt ?? this.pollEndsAt,
      pollAllowMultipleChoices: pollAllowMultipleChoices ?? this.pollAllowMultipleChoices,
      pollTotalVotes: pollTotalVotes ?? this.pollTotalVotes,
      likes: likes ?? this.likes,
      replies: replies ?? this.replies,
      reposts: reposts ?? this.reposts,
      views: views ?? this.views,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
      isPinned: isPinned ?? this.isPinned,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isReply: isReply ?? this.isReply,
      parentThreadId: parentThreadId ?? this.parentThreadId,
      replyToUserId: replyToUserId ?? this.replyToUserId,
      replyToUserName: replyToUserName ?? this.replyToUserName,
      isRepost: isRepost ?? this.isRepost,
      originalThreadId: originalThreadId ?? this.originalThreadId,
      originalUserId: originalUserId ?? this.originalUserId,
      originalUserName: originalUserName ?? this.originalUserName,
      repostedAt: repostedAt ?? this.repostedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLiked: isLiked ?? this.isLiked,
      isReposted: isReposted ?? this.isReposted,
      isFollowing: isFollowing ?? this.isFollowing,
      userVotedOptionId: userVotedOptionId ?? this.userVotedOptionId,
    );
  }

  // ===============================
  // CONTENT TYPE HELPERS
  // ===============================

  bool get hasImages => imageUrls.isNotEmpty;
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
  bool get hasLinkPreview => linkPreviewUrl != null && linkPreviewUrl!.isNotEmpty;
  bool get hasMedia => hasImages || hasVideo || hasLinkPreview || hasPoll;
  
  bool get isTextOnly => !hasImages && !hasVideo && !hasLinkPreview && !hasPoll;
  bool get isImagePost => hasImages && !hasVideo && !hasPoll;
  bool get isVideoPost => hasVideo && !hasImages && !hasPoll;
  bool get isPollPost => hasPoll;
  bool get isMixedMediaPost => (hasVideo && hasImages) || (hasPoll && (hasImages || hasVideo));
  bool get hasMultipleImages => imageUrls.length > 1;
  
  int get imageCount => imageUrls.length;
  int get totalMediaCount => (hasVideo ? 1 : 0) + imageUrls.length + (hasPoll ? 1 : 0);
  
  // Video helpers
  String? get formattedVideoDuration {
    if (videoDurationSeconds == null) return null;
    final duration = Duration(seconds: videoDurationSeconds!);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
  
  bool get isVideoTooLong => videoDurationSeconds != null && videoDurationSeconds! > 300; // 5 min max

  // ===============================
  // POLL HELPERS
  // ===============================

  bool get isPollActive {
    if (!hasPoll || pollEndsAt == null) return false;
    try {
      final endsAt = DateTime.parse(pollEndsAt!);
      return DateTime.now().isBefore(endsAt);
    } catch (e) {
      return false;
    }
  }

  bool get isPollExpired => hasPoll && !isPollActive;

  bool get hasUserVoted => userVotedOptionId != null && userVotedOptionId!.isNotEmpty;

  int get pollOptionsCount => pollOptions.length;

  String get pollTimeRemaining {
    if (!hasPoll || pollEndsAt == null) return '';
    try {
      final endsAt = DateTime.parse(pollEndsAt!);
      final now = DateTime.now();
      if (now.isAfter(endsAt)) return 'Poll ended';
      
      final difference = endsAt.difference(now);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d left';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h left';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m left';
      } else {
        return 'Ending soon';
      }
    } catch (e) {
      return '';
    }
  }

  // Get poll option by ID
  PollOption? getPollOption(String optionId) {
    try {
      return pollOptions.firstWhere((option) => option.id == optionId);
    } catch (e) {
      return null;
    }
  }

  // Get vote percentage for option
  double getVotePercentage(String optionId) {
    if (pollTotalVotes == 0) return 0.0;
    final option = getPollOption(optionId);
    if (option == null) return 0.0;
    return (option.votes / pollTotalVotes) * 100;
  }

  String getFormattedVotePercentage(String optionId) {
    return '${getVotePercentage(optionId).toStringAsFixed(1)}%';
  }

  // Get winning option
  PollOption? get winningPollOption {
    if (pollOptions.isEmpty) return null;
    return pollOptions.reduce((a, b) => a.votes > b.votes ? a : b);
  }

  // Vote on poll
  ThreadModel voteOnPoll(String optionId) {
    if (!isPollActive) return this;
    if (hasUserVoted) return this; // Already voted
    
    final updatedOptions = pollOptions.map((option) {
      if (option.id == optionId) {
        return option.copyWith(votes: option.votes + 1);
      }
      return option;
    }).toList();
    
    return copyWith(
      pollOptions: updatedOptions,
      pollTotalVotes: pollTotalVotes + 1,
      userVotedOptionId: optionId,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // ===============================
  // DISPLAY FORMATTING
  // ===============================

  String get formattedLikes => _formatCount(likes);
  String get formattedReplies => _formatCount(replies);
  String get formattedReposts => _formatCount(reposts);
  String get formattedViews => _formatCount(views);
  String get formattedPollVotes => _formatCount(pollTotalVotes);

  static String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  // Engagement metrics
  double get engagementRate {
    if (views == 0) return 0.0;
    final totalEngagement = likes + replies + reposts + (hasPoll ? pollTotalVotes : 0);
    return (totalEngagement / views) * 100;
  }

  String get formattedEngagementRate {
    return '${engagementRate.toStringAsFixed(1)}%';
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
  // CONTENT ANALYSIS
  // ===============================

  int get characterCount => content.length;
  int get wordCount => content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  
  bool get isLongThread => characterCount > 280;
  bool get isShortThread => characterCount <= 140;
  
  // Extract hashtags from content
  List<String> get hashtagsInContent {
    final regex = RegExp(r'#(\w+)');
    final matches = regex.allMatches(content);
    return matches.map((m) => m.group(1)!).toList();
  }
  
  // Extract mentions from content
  List<String> get mentionsInContent {
    final regex = RegExp(r'@(\w+)');
    final matches = regex.allMatches(content);
    return matches.map((m) => m.group(1)!).toList();
  }
  
  // Extract URLs from content
  List<String> get urlsInContent {
    final regex = RegExp(r'https?://\S+');
    final matches = regex.allMatches(content);
    return matches.map((m) => m.group(0)!).toList();
  }

  // ===============================
  // INTERACTION METHODS
  // ===============================

  ThreadModel toggleLike() {
    return copyWith(
      isLiked: !isLiked,
      likes: isLiked ? likes - 1 : likes + 1,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  ThreadModel toggleRepost() {
    return copyWith(
      isReposted: !isReposted,
      reposts: isReposted ? reposts - 1 : reposts + 1,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  ThreadModel incrementViews() {
    return copyWith(
      views: views + 1,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  ThreadModel incrementReplies() {
    return copyWith(
      replies: replies + 1,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  ThreadModel markAsEdited() {
    return copyWith(
      isEdited: true,
      editedAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // ===============================
  // VALIDATION
  // ===============================

  bool get isValid {
    return id.isNotEmpty && 
           userId.isNotEmpty && 
           userName.isNotEmpty && 
           content.isNotEmpty &&
           content.length <= 500 &&
           imageUrls.length <= 4 &&
           (videoDurationSeconds == null || videoDurationSeconds! <= 300) &&
           (!hasPoll || (hasPoll && isVerified)) && // Polls require verification
           (!hasPoll || pollOptions.length >= 2) && // Polls need at least 2 options
           (!hasPoll || pollOptions.length <= 4); // Polls max 4 options
  }

  List<String> get validationErrors {
    final errors = <String>[];
    
    if (id.isEmpty) errors.add('ID is required');
    if (userId.isEmpty) errors.add('User ID is required');
    if (userName.isEmpty) errors.add('User name is required');
    if (content.isEmpty) errors.add('Content is required');
    if (content.length > 500) errors.add('Content exceeds 500 characters');
    
    if (imageUrls.length > 4) {
      errors.add('Maximum 4 images allowed per thread');
    }
    
    if (videoDurationSeconds != null && videoDurationSeconds! > 300) {
      errors.add('Video exceeds 5 minutes maximum');
    }
    
    if (isReply && parentThreadId == null) {
      errors.add('Parent thread ID required for replies');
    }
    
    if (isRepost && originalThreadId == null) {
      errors.add('Original thread ID required for reposts');
    }

    // Poll validation
    if (hasPoll && !isVerified) {
      errors.add('Only verified users can create polls');
    }
    
    if (hasPoll && pollOptions.length < 2) {
      errors.add('Polls require at least 2 options');
    }
    
    if (hasPoll && pollOptions.length > 4) {
      errors.add('Polls cannot have more than 4 options');
    }

    if (hasPoll && pollDurationHours != null) {
      if (![24, 48, 72, 168].contains(pollDurationHours)) {
        errors.add('Poll duration must be 24h, 48h, 72h, or 168h (7 days)');
      }
    }
    
    return errors;
  }

  // ===============================
  // SEARCH HELPERS
  // ===============================

  bool containsQuery(String query) {
    if (query.isEmpty) return true;
    
    final searchQuery = query.toLowerCase();
    
    return content.toLowerCase().contains(searchQuery) ||
           userName.toLowerCase().contains(searchQuery) ||
           tags.any((tag) => tag.toLowerCase().contains(searchQuery)) ||
           (hasPoll && pollQuestion != null && pollQuestion!.toLowerCase().contains(searchQuery));
  }

  bool hasTag(String tag) {
    return tags.any((t) => t.toLowerCase() == tag.toLowerCase());
  }

  // ===============================
  // DEBUG & DISPLAY
  // ===============================

  @override
  String toString() {
    final contentPreview = content.length > 30 ? "${content.substring(0, 30)}..." : content;
    return 'ThreadModel(id: $id, user: $userName, content: "$contentPreview", likes: $likes, replies: $replies, hasPoll: $hasPoll)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThreadModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ===============================
// EXTENSIONS FOR LISTS
// ===============================

extension ThreadModelList on List<ThreadModel> {
  // Filter by type
  List<ThreadModel> get activeThreads => where((t) => t.isActive).toList();
  List<ThreadModel> get pinnedThreads => where((t) => t.isPinned).toList();
  List<ThreadModel> get verifiedThreads => where((t) => t.isVerified).toList();
  List<ThreadModel> get replies => where((t) => t.isReply).toList();
  List<ThreadModel> get reposts => where((t) => t.isRepost).toList();
  List<ThreadModel> get originalThreads => where((t) => !t.isReply && !t.isRepost).toList();
  
  // Filter by content type
  List<ThreadModel> get textOnlyThreads => where((t) => t.isTextOnly).toList();
  List<ThreadModel> get imageThreads => where((t) => t.isImagePost).toList();
  List<ThreadModel> get videoThreads => where((t) => t.isVideoPost).toList();
  List<ThreadModel> get pollThreads => where((t) => t.isPollPost).toList();
  List<ThreadModel> get mixedMediaThreads => where((t) => t.isMixedMediaPost).toList();
  List<ThreadModel> get threadsWithMedia => where((t) => t.hasMedia).toList();
  
  // Poll filters
  List<ThreadModel> get activePolls => where((t) => t.hasPoll && t.isPollActive).toList();
  List<ThreadModel> get expiredPolls => where((t) => t.hasPoll && t.isPollExpired).toList();
  
  // Sorting
  List<ThreadModel> sortByLikes({bool descending = true}) {
    final sorted = List<ThreadModel>.from(this);
    sorted.sort((a, b) => descending ? b.likes.compareTo(a.likes) : a.likes.compareTo(b.likes));
    return sorted;
  }
  
  List<ThreadModel> sortByReplies({bool descending = true}) {
    final sorted = List<ThreadModel>.from(this);
    sorted.sort((a, b) => descending ? b.replies.compareTo(a.replies) : a.replies.compareTo(b.replies));
    return sorted;
  }
  
  List<ThreadModel> sortByEngagement({bool descending = true}) {
    final sorted = List<ThreadModel>.from(this);
    sorted.sort((a, b) => descending 
        ? b.engagementRate.compareTo(a.engagementRate) 
        : a.engagementRate.compareTo(b.engagementRate));
    return sorted;
  }
  
  List<ThreadModel> sortByDate({bool descending = true}) {
    final sorted = List<ThreadModel>.from(this);
    sorted.sort((a, b) => descending 
        ? b.createdAtDateTime.compareTo(a.createdAtDateTime)
        : a.createdAtDateTime.compareTo(b.createdAtDateTime));
    return sorted;
  }

  List<ThreadModel> sortByPollVotes({bool descending = true}) {
    final sorted = List<ThreadModel>.from(this);
    sorted.sort((a, b) => descending 
        ? b.pollTotalVotes.compareTo(a.pollTotalVotes) 
        : a.pollTotalVotes.compareTo(b.pollTotalVotes));
    return sorted;
  }
  
  // Filtering
  List<ThreadModel> filterByUser(String userId) {
    return where((t) => t.userId == userId).toList();
  }
  
  List<ThreadModel> filterByTag(String tag) {
    return where((t) => t.hasTag(tag)).toList();
  }
  
  List<ThreadModel> search(String query) {
    return where((t) => t.containsQuery(query)).toList();
  }
  
  // Metrics
  int get totalLikes => fold<int>(0, (sum, t) => sum + t.likes);
  int get totalReplies => fold<int>(0, (sum, t) => sum + t.replies);
  int get totalReposts => fold<int>(0, (sum, t) => sum + t.reposts);
  int get totalViews => fold<int>(0, (sum, t) => sum + t.views);
  int get totalPollVotes => fold<int>(0, (sum, t) => sum + t.pollTotalVotes);
  
  double get averageEngagementRate {
    if (isEmpty) return 0.0;
    final totalEngagement = fold<double>(0.0, (sum, t) => sum + t.engagementRate);
    return totalEngagement / length;
  }

  // Poll statistics
  int get totalPolls => where((t) => t.hasPoll).length;
  int get activePollsCount => activePolls.length;
  int get expiredPollsCount => expiredPolls.length;
  
  double get pollPercentage {
    if (isEmpty) return 0.0;
    return (totalPolls / length) * 100;
  }
}
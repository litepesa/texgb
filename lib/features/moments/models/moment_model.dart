// lib/features/moments/models/moment_model.dart - Updated with 24h expiration and simplified logic
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:textgb/constants.dart';

enum MomentType {
  video,
  images;

  String get name {
    switch (this) {
      case MomentType.video:
        return 'video';
      case MomentType.images:
        return 'images';
    }
  }

  static MomentType fromString(String value) {
    switch (value) {
      case 'video':
        return MomentType.video;
      case 'images':
        return MomentType.images;
      default:
        return MomentType.images;
    }
  }
}

enum MomentPrivacy {
  public,
  contacts,
  selectedContacts,
  exceptSelected;

  String get name {
    switch (this) {
      case MomentPrivacy.public:
        return 'public';
      case MomentPrivacy.contacts:
        return 'contacts';
      case MomentPrivacy.selectedContacts:
        return 'selectedContacts';
      case MomentPrivacy.exceptSelected:
        return 'exceptSelected';
    }
  }

  static MomentPrivacy fromString(String value) {
    switch (value) {
      case 'public':
        return MomentPrivacy.public;
      case 'contacts':
        return MomentPrivacy.contacts;
      case 'selectedContacts':
        return MomentPrivacy.selectedContacts;
      case 'exceptSelected':
        return MomentPrivacy.exceptSelected;
      default:
        return MomentPrivacy.public;
    }
  }

  String get displayName {
    switch (this) {
      case MomentPrivacy.public:
        return 'Public';
      case MomentPrivacy.contacts:
        return 'My contacts';
      case MomentPrivacy.selectedContacts:
        return 'Selected contacts';
      case MomentPrivacy.exceptSelected:
        return 'Hide from selected';
    }
  }

  String get description {
    switch (this) {
      case MomentPrivacy.public:
        return 'Anyone can see this moment';
      case MomentPrivacy.contacts:
        return 'Only your contacts can see this moment';
      case MomentPrivacy.selectedContacts:
        return 'Only selected contacts can see this moment';
      case MomentPrivacy.exceptSelected:
        return 'All contacts except selected ones can see this moment';
    }
  }
}

class MomentModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorImage;
  final String content; // Caption text
  final MomentType type;
  final String? videoUrl;
  final String? videoThumbnail;
  final List<String> imageUrls;
  final MomentPrivacy privacy;
  final List<String> selectedContacts; // For selectedContacts and exceptSelected privacy
  final DateTime createdAt;
  final DateTime expiresAt;
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final List<String> likedBy;
  final List<String> viewedBy;
  final bool isActive; // false if manually deleted or expired
  final Map<String, dynamic> metadata; // Additional data like video duration, etc.

  const MomentModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorImage,
    required this.content,
    required this.type,
    this.videoUrl,
    this.videoThumbnail,
    required this.imageUrls,
    required this.privacy,
    required this.selectedContacts,
    required this.createdAt,
    required this.expiresAt,
    required this.likesCount,
    required this.commentsCount,
    required this.viewsCount,
    required this.likedBy,
    required this.viewedBy,
    required this.isActive,
    required this.metadata,
  });

  factory MomentModel.fromMap(Map<String, dynamic> map) {
    return MomentModel(
      id: map[Constants.momentId]?.toString() ?? '',
      authorId: map[Constants.userId]?.toString() ?? '',
      authorName: map[Constants.authorName]?.toString() ?? '',
      authorImage: map[Constants.authorImage]?.toString() ?? '',
      content: map[Constants.momentContent]?.toString() ?? '',
      type: MomentType.fromString(map[Constants.momentMediaType]?.toString() ?? 'images'),
      videoUrl: map[Constants.videoUrl]?.toString(),
      videoThumbnail: map['videoThumbnail']?.toString(),
      imageUrls: List<String>.from(map[Constants.momentMediaUrls] ?? []),
      privacy: MomentPrivacy.fromString(map[Constants.momentPrivacy]?.toString() ?? 'public'),
      selectedContacts: List<String>.from(map[Constants.momentVisibleTo] ?? []),
      createdAt: (map[Constants.momentCreatedAt] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 24)), // Changed to 24h
      likesCount: map[Constants.momentLikesCount]?.toInt() ?? 0,
      commentsCount: map[Constants.momentCommentsCount]?.toInt() ?? 0,
      viewsCount: map['viewsCount']?.toInt() ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      viewedBy: List<String>.from(map['viewedBy'] ?? []),
      isActive: map['isActive'] ?? true,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      Constants.momentId: id,
      Constants.userId: authorId,
      Constants.authorName: authorName,
      Constants.authorImage: authorImage,
      Constants.momentContent: content,
      Constants.momentMediaType: type.name,
      Constants.videoUrl: videoUrl,
      'videoThumbnail': videoThumbnail,
      Constants.momentMediaUrls: imageUrls,
      Constants.momentPrivacy: privacy.name,
      Constants.momentVisibleTo: selectedContacts,
      Constants.momentCreatedAt: Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      Constants.momentLikesCount: likesCount,
      Constants.momentCommentsCount: commentsCount,
      'viewsCount': viewsCount,
      'likedBy': likedBy,
      'viewedBy': viewedBy,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  MomentModel copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorImage,
    String? content,
    MomentType? type,
    String? videoUrl,
    String? videoThumbnail,
    List<String>? imageUrls,
    MomentPrivacy? privacy,
    List<String>? selectedContacts,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? likesCount,
    int? commentsCount,
    int? viewsCount,
    List<String>? likedBy,
    List<String>? viewedBy,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return MomentModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorImage: authorImage ?? this.authorImage,
      content: content ?? this.content,
      type: type ?? this.type,
      videoUrl: videoUrl ?? this.videoUrl,
      videoThumbnail: videoThumbnail ?? this.videoThumbnail,
      imageUrls: imageUrls ?? this.imageUrls,
      privacy: privacy ?? this.privacy,
      selectedContacts: selectedContacts ?? this.selectedContacts,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      viewsCount: viewsCount ?? this.viewsCount,
      likedBy: likedBy ?? this.likedBy,
      viewedBy: viewedBy ?? this.viewedBy,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  bool get hasVideo => type == MomentType.video && videoUrl != null;
  
  bool get hasImages => type == MomentType.images && imageUrls.isNotEmpty;
  
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return Duration.zero;
    return expiresAt.difference(now);
  }
  
  String get timeRemainingText {
    final remaining = timeRemaining;
    if (remaining == Duration.zero) return 'Expired';
    
    if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m left';
    } else {
      return '${remaining.inMinutes}m left';
    }
  }

  bool isVisibleTo(String userId, List<String> userContacts) {
    if (!isActive || isExpired) return false;
    
    // Author can always see their own moments
    if (authorId == userId) return true;
    
    switch (privacy) {
      case MomentPrivacy.public:
        return true;
      case MomentPrivacy.contacts:
        return userContacts.contains(authorId);
      case MomentPrivacy.selectedContacts:
        return selectedContacts.contains(userId);
      case MomentPrivacy.exceptSelected:
        return userContacts.contains(authorId) && !selectedContacts.contains(userId);
    }
  }

  // Check if moment has been viewed by user
  bool hasUserViewed(String userId) => viewedBy.contains(userId);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MomentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MomentModel(id: $id, authorName: $authorName, type: $type, privacy: $privacy)';
  }
}

// Simplified helper class for grouping moments by user (chronological within user)
class UserMomentGroup {
  final String userId;
  final String userName;
  final String userImage;
  final List<MomentModel> moments;
  final bool isMyMoments;

  UserMomentGroup({
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.moments,
    this.isMyMoments = false,
  });

  // Get the earliest moment (for chronological display)
  MomentModel? get earliestMoment {
    if (moments.isEmpty) return null;
    return moments.reduce((a, b) => a.createdAt.isBefore(b.createdAt) ? a : b);
  }

  // Get the earliest unviewed moment, or earliest viewed if all viewed
  MomentModel? getEarliestMomentForUser(String currentUserId) {
    if (moments.isEmpty) return null;
    
    // Sort moments chronologically (earliest first)
    final sortedMoments = List<MomentModel>.from(moments);
    sortedMoments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    // Find earliest unviewed moment
    final unviewedMoments = sortedMoments
        .where((moment) => !moment.hasUserViewed(currentUserId))
        .toList();
    
    if (unviewedMoments.isNotEmpty) {
      return unviewedMoments.first; // Earliest unviewed
    }
    
    // If all viewed, return earliest moment
    return sortedMoments.first;
  }

  // Get active moments count
  int get activeMomentsCount {
    return moments.where((moment) => moment.isActive && !moment.isExpired).length;
  }

  // Get all unviewed moments sorted chronologically
  List<MomentModel> getUnviewedMomentsChronologically(String currentUserId) {
    final unviewedMoments = moments
        .where((moment) => !moment.hasUserViewed(currentUserId))
        .toList();
    
    // Sort chronologically (earliest first)
    unviewedMoments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return unviewedMoments;
  }

  // Get total unviewed moments count for this user
  int getUnviewedCount(String currentUserId) {
    return moments.where((moment) => !moment.hasUserViewed(currentUserId)).length;
  }

  // Check if there are any unviewed moments
  bool hasUnviewedMoments(String currentUserId) {
    return getUnviewedCount(currentUserId) > 0;
  }

  // Get time of earliest moment
  String get earliestMomentTime {
    final earliest = earliestMoment;
    if (earliest == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(earliest.createdAt);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '1d ago'; // Should not happen with 24h expiration
    }
  }

  UserMomentGroup copyWith({
    String? userId,
    String? userName,
    String? userImage,
    List<MomentModel>? moments,
    bool? isMyMoments,
  }) {
    return UserMomentGroup(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      moments: moments ?? this.moments,
      isMyMoments: isMyMoments ?? this.isMyMoments,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserMomentGroup && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() {
    return 'UserMomentGroup(userId: $userId, userName: $userName, momentsCount: ${moments.length})';
  }
}
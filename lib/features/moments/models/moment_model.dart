// lib/features/moments/models/moment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MomentModel {
  final String momentId;
  final String authorUID;
  final String authorName;
  final String authorImage;
  final String content;
  final List<String> mediaUrls;
  final String mediaType; // 'image', 'video', 'text', 'mixed'
  final DateTime createdAt;
  final List<String> likedBy;
  final int likesCount;
  final int commentsCount;
  final String? location;
  final MomentPrivacy privacy;
  final List<String> visibleTo; // For custom privacy
  final List<String> hiddenFrom; // For except privacy
  final bool isEdited;
  final DateTime? editedAt;
  final Map<String, dynamic>? metadata;

  MomentModel({
    required this.momentId,
    required this.authorUID,
    required this.authorName,
    required this.authorImage,
    required this.content,
    required this.mediaUrls,
    required this.mediaType,
    required this.createdAt,
    required this.likedBy,
    required this.likesCount,
    required this.commentsCount,
    this.location,
    required this.privacy,
    required this.visibleTo,
    required this.hiddenFrom,
    required this.isEdited,
    this.editedAt,
    this.metadata,
  });

  factory MomentModel.fromMap(Map<String, dynamic> map) {
    return MomentModel(
      momentId: map['momentId'] ?? '',
      authorUID: map['authorUID'] ?? '',
      authorName: map['authorName'] ?? '',
      authorImage: map['authorImage'] ?? '',
      content: map['content'] ?? '',
      mediaUrls: List<String>.from(map['mediaUrls'] ?? []),
      mediaType: map['mediaType'] ?? 'text',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      likedBy: List<String>.from(map['likedBy'] ?? []),
      likesCount: map['likesCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      location: map['location'],
      privacy: MomentPrivacy.fromString(map['privacy'] ?? 'all_contacts'),
      visibleTo: List<String>.from(map['visibleTo'] ?? []),
      hiddenFrom: List<String>.from(map['hiddenFrom'] ?? []),
      isEdited: map['isEdited'] ?? false,
      editedAt: map['editedAt'] != null ? (map['editedAt'] as Timestamp).toDate() : null,
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'momentId': momentId,
      'authorUID': authorUID,
      'authorName': authorName,
      'authorImage': authorImage,
      'content': content,
      'mediaUrls': mediaUrls,
      'mediaType': mediaType,
      'createdAt': Timestamp.fromDate(createdAt),
      'likedBy': likedBy,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'location': location,
      'privacy': privacy.name,
      'visibleTo': visibleTo,
      'hiddenFrom': hiddenFrom,
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'metadata': metadata,
    };
  }

  MomentModel copyWith({
    String? momentId,
    String? authorUID,
    String? authorName,
    String? authorImage,
    String? content,
    List<String>? mediaUrls,
    String? mediaType,
    DateTime? createdAt,
    List<String>? likedBy,
    int? likesCount,
    int? commentsCount,
    String? location,
    MomentPrivacy? privacy,
    List<String>? visibleTo,
    List<String>? hiddenFrom,
    bool? isEdited,
    DateTime? editedAt,
    Map<String, dynamic>? metadata,
  }) {
    return MomentModel(
      momentId: momentId ?? this.momentId,
      authorUID: authorUID ?? this.authorUID,
      authorName: authorName ?? this.authorName,
      authorImage: authorImage ?? this.authorImage,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      mediaType: mediaType ?? this.mediaType,
      createdAt: createdAt ?? this.createdAt,
      likedBy: likedBy ?? this.likedBy,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      location: location ?? this.location,
      privacy: privacy ?? this.privacy,
      visibleTo: visibleTo ?? this.visibleTo,
      hiddenFrom: hiddenFrom ?? this.hiddenFrom,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get hasMedia => mediaUrls.isNotEmpty;
  bool get hasMultipleMedia => mediaUrls.length > 1;
  bool get isTextOnly => mediaType == 'text' && !hasMedia;
  bool get hasImages => mediaType == 'image' || mediaType == 'mixed';
  bool get hasVideo => mediaType == 'video' || mediaType == 'mixed';
}

enum MomentPrivacy {
  allContacts,
  except,
  only,
  public;

  String get name {
    switch (this) {
      case MomentPrivacy.allContacts:
        return 'all_contacts';
      case MomentPrivacy.except:
        return 'except';
      case MomentPrivacy.only:
        return 'only';
      case MomentPrivacy.public:
        return 'public';
    }
  }

  String get displayName {
    switch (this) {
      case MomentPrivacy.allContacts:
        return 'All Contacts';
      case MomentPrivacy.except:
        return 'All Contacts Except...';
      case MomentPrivacy.only:
        return 'Only Share With...';
      case MomentPrivacy.public:
        return 'Public';
    }
  }

  static MomentPrivacy fromString(String value) {
    switch (value) {
      case 'except':
        return MomentPrivacy.except;
      case 'only':
        return MomentPrivacy.only;
      case 'public':
        return MomentPrivacy.public;
      case 'all_contacts':
      default:
        return MomentPrivacy.allContacts;
    }
  }
}

// Comment model for moments
class MomentCommentModel {
  final String commentId;
  final String momentId;
  final String authorUID;
  final String authorName;
  final String authorImage;
  final String content;
  final DateTime createdAt;
  final String? replyToUID;
  final String? replyToName;
  final List<String> likedBy;
  final int likesCount;

  MomentCommentModel({
    required this.commentId,
    required this.momentId,
    required this.authorUID,
    required this.authorName,
    required this.authorImage,
    required this.content,
    required this.createdAt,
    this.replyToUID,
    this.replyToName,
    required this.likedBy,
    required this.likesCount,
  });

  factory MomentCommentModel.fromMap(Map<String, dynamic> map) {
    return MomentCommentModel(
      commentId: map['commentId'] ?? '',
      momentId: map['momentId'] ?? '',
      authorUID: map['authorUID'] ?? '',
      authorName: map['authorName'] ?? '',
      authorImage: map['authorImage'] ?? '',
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      replyToUID: map['replyToUID'],
      replyToName: map['replyToName'],
      likedBy: List<String>.from(map['likedBy'] ?? []),
      likesCount: map['likesCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'momentId': momentId,
      'authorUID': authorUID,
      'authorName': authorName,
      'authorImage': authorImage,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'replyToUID': replyToUID,
      'replyToName': replyToName,
      'likedBy': likedBy,
      'likesCount': likesCount,
    };
  }

  bool get isReply => replyToUID != null;
}
// lib/features/moments/models/moment_model.dart
import 'package:textgb/enums/enums.dart';

class MomentModel {
  final String momentId;
  final String authorUID;
  final String authorName;
  final String authorImage;
  final String content;
  final List<String> mediaUrls;
  final MessageEnum mediaType;
  final DateTime createdAt;
  final List<String> likedBy;
  final List<String> viewedBy;
  final Map<String, dynamic> location;
  final List<String> taggedUsers;
  final MomentPrivacy privacy;
  final bool isEdited;
  final DateTime? editedAt;

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
    required this.viewedBy,
    required this.location,
    required this.taggedUsers,
    required this.privacy,
    this.isEdited = false,
    this.editedAt,
  });

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'momentId': momentId,
      'authorUID': authorUID,
      'authorName': authorName,
      'authorImage': authorImage,
      'content': content,
      'mediaUrls': mediaUrls,
      'mediaType': mediaType.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'likedBy': likedBy,
      'viewedBy': viewedBy,
      'location': location,
      'taggedUsers': taggedUsers,
      'privacy': privacy.name,
      'isEdited': isEdited,
      'editedAt': editedAt?.millisecondsSinceEpoch,
    };
  }

  // Create from Firestore map
  factory MomentModel.fromMap(Map<String, dynamic> map) {
    return MomentModel(
      momentId: map['momentId'] ?? '',
      authorUID: map['authorUID'] ?? '',
      authorName: map['authorName'] ?? '',
      authorImage: map['authorImage'] ?? '',
      content: map['content'] ?? '',
      mediaUrls: List<String>.from(map['mediaUrls'] ?? []),
      mediaType: (map['mediaType'] as String).toMessageEnum(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      likedBy: List<String>.from(map['likedBy'] ?? []),
      viewedBy: List<String>.from(map['viewedBy'] ?? []),
      location: Map<String, dynamic>.from(map['location'] ?? {}),
      taggedUsers: List<String>.from(map['taggedUsers'] ?? []),
      privacy: MomentPrivacyExtension.fromString(map['privacy'] ?? 'all_contacts'),
      isEdited: map['isEdited'] ?? false,
      editedAt: map['editedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['editedAt'])
          : null,
    );
  }

  // Helper getters
  int get likesCount => likedBy.length;
  int get viewsCount => viewedBy.length;
  bool get hasMedia => mediaUrls.isNotEmpty;
  bool get hasImages => mediaType == MessageEnum.image;
  bool get hasVideo => mediaType == MessageEnum.video;
  bool get hasLocation => location.isNotEmpty;

  // Copy with method
  MomentModel copyWith({
    String? momentId,
    String? authorUID,
    String? authorName,
    String? authorImage,
    String? content,
    List<String>? mediaUrls,
    MessageEnum? mediaType,
    DateTime? createdAt,
    List<String>? likedBy,
    List<String>? viewedBy,
    Map<String, dynamic>? location,
    List<String>? taggedUsers,
    MomentPrivacy? privacy,
    bool? isEdited,
    DateTime? editedAt,
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
      viewedBy: viewedBy ?? this.viewedBy,
      location: location ?? this.location,
      taggedUsers: taggedUsers ?? this.taggedUsers,
      privacy: privacy ?? this.privacy,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
    );
  }
}

class MomentComment {
  final String commentId;
  final String momentId;
  final String authorUID;
  final String authorName;
  final String authorImage;
  final String content;
  final DateTime createdAt;
  final String? replyToUID;
  final String? replyToName;

  MomentComment({
    required this.commentId,
    required this.momentId,
    required this.authorUID,
    required this.authorName,
    required this.authorImage,
    required this.content,
    required this.createdAt,
    this.replyToUID,
    this.replyToName,
  });

  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'momentId': momentId,
      'authorUID': authorUID,
      'authorName': authorName,
      'authorImage': authorImage,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'replyToUID': replyToUID,
      'replyToName': replyToName,
    };
  }

  factory MomentComment.fromMap(Map<String, dynamic> map) {
    return MomentComment(
      commentId: map['commentId'] ?? '',
      momentId: map['momentId'] ?? '',
      authorUID: map['authorUID'] ?? '',
      authorName: map['authorName'] ?? '',
      authorImage: map['authorImage'] ?? '',
      content: map['content'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      replyToUID: map['replyToUID'],
      replyToName: map['replyToName'],
    );
  }
}

enum MomentPrivacy {
  allContacts,
  onlyMe,
  customList,
}

extension MomentPrivacyExtension on MomentPrivacy {
  String get name {
    switch (this) {
      case MomentPrivacy.allContacts:
        return 'all_contacts';
      case MomentPrivacy.onlyMe:
        return 'only_me';
      case MomentPrivacy.customList:
        return 'custom_list';
    }
  }

  String get displayName {
    switch (this) {
      case MomentPrivacy.allContacts:
        return 'All Contacts';
      case MomentPrivacy.onlyMe:
        return 'Only Me';
      case MomentPrivacy.customList:
        return 'Custom List';
    }
  }

  static MomentPrivacy fromString(String value) {
    switch (value) {
      case 'only_me':
        return MomentPrivacy.onlyMe;
      case 'custom_list':
        return MomentPrivacy.customList;
      case 'all_contacts':
      default:
        return MomentPrivacy.allContacts;
    }
  }
}
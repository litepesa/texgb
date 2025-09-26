// lib/features/properties/models/property_engagement_models.dart

// Property Like Model (independent from main app likes)
class PropertyLikeModel {
  final String id;
  final String propertyId;
  final String userId;
  final String userName;
  final String userImage;
  final DateTime createdAt;

  const PropertyLikeModel({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.createdAt,
  });

  factory PropertyLikeModel.fromMap(Map<String, dynamic> map) {
    return PropertyLikeModel(
      id: map['id']?.toString() ?? '',
      propertyId: map['propertyId']?.toString() ?? map['property_id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? map['user_id']?.toString() ?? '',
      userName: map['userName']?.toString() ?? map['user_name']?.toString() ?? '',
      userImage: map['userImage']?.toString() ?? map['user_image']?.toString() ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'propertyId': propertyId,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  PropertyLikeModel copyWith({
    String? id,
    String? propertyId,
    String? userId,
    String? userName,
    String? userImage,
    DateTime? createdAt,
  }) {
    return PropertyLikeModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PropertyLikeModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PropertyLikeModel(id: $id, propertyId: $propertyId, userName: $userName)';
  }
}

// Property Comment Model (independent from main app comments)
class PropertyCommentModel {
  final String id;
  final String propertyId;
  final String authorId;
  final String authorName;
  final String authorImage;
  final String content;
  final int likesCount;
  final bool isLiked; // Current user's like status
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isReply;
  final String? parentCommentId;
  final String? repliedToAuthorName;
  final List<PropertyCommentModel> replies;

  const PropertyCommentModel({
    required this.id,
    required this.propertyId,
    required this.authorId,
    required this.authorName,
    required this.authorImage,
    required this.content,
    this.likesCount = 0,
    this.isLiked = false,
    required this.createdAt,
    required this.updatedAt,
    this.isReply = false,
    this.parentCommentId,
    this.repliedToAuthorName,
    this.replies = const [],
  });

  factory PropertyCommentModel.fromMap(Map<String, dynamic> map) {
    return PropertyCommentModel(
      id: map['id']?.toString() ?? '',
      propertyId: map['propertyId']?.toString() ?? map['property_id']?.toString() ?? '',
      authorId: map['authorId']?.toString() ?? map['author_id']?.toString() ?? '',
      authorName: map['authorName']?.toString() ?? map['author_name']?.toString() ?? '',
      authorImage: map['authorImage']?.toString() ?? map['author_image']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      likesCount: (map['likesCount'] ?? map['likes_count'] ?? 0).toInt(),
      isLiked: map['isLiked'] ?? map['is_liked'] ?? false,
      createdAt: DateTime.parse(map['createdAt'] ?? map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? map['updated_at'] ?? DateTime.now().toIso8601String()),
      isReply: map['isReply'] ?? map['is_reply'] ?? false,
      parentCommentId: map['parentCommentId']?.toString() ?? map['parent_comment_id']?.toString(),
      repliedToAuthorName: map['repliedToAuthorName']?.toString() ?? map['replied_to_author_name']?.toString(),
      replies: _parseReplies(map['replies']),
    );
  }

  static List<PropertyCommentModel> _parseReplies(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => e is Map<String, dynamic> ? PropertyCommentModel.fromMap(e) : null)
          .where((e) => e != null)
          .cast<PropertyCommentModel>()
          .toList();
    }
    return [];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'propertyId': propertyId,
      'authorId': authorId,
      'authorName': authorName,
      'authorImage': authorImage,
      'content': content,
      'likesCount': likesCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isReply': isReply,
      'parentCommentId': parentCommentId,
      'repliedToAuthorName': repliedToAuthorName,
      'replies': replies.map((reply) => reply.toMap()).toList(),
    };
  }

  PropertyCommentModel copyWith({
    String? id,
    String? propertyId,
    String? authorId,
    String? authorName,
    String? authorImage,
    String? content,
    int? likesCount,
    bool? isLiked,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isReply,
    String? parentCommentId,
    String? repliedToAuthorName,
    List<PropertyCommentModel>? replies,
  }) {
    return PropertyCommentModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorImage: authorImage ?? this.authorImage,
      content: content ?? this.content,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isReply: isReply ?? this.isReply,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      repliedToAuthorName: repliedToAuthorName ?? this.repliedToAuthorName,
      replies: replies ?? this.replies,
    );
  }

  // Helper methods
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  bool get hasReplies => replies.isNotEmpty;
  int get repliesCount => replies.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PropertyCommentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PropertyCommentModel(id: $id, propertyId: $propertyId, authorName: $authorName, content: ${content.length > 50 ? content.substring(0, 50) + '...' : content})';
  }
}

// Property Inquiry Model (for tracking WhatsApp inquiries)
class PropertyInquiryModel {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String hostId;
  final String inquirerId;
  final String inquirerName;
  final String inquirerImage;
  final String inquirerPhoneNumber;
  final DateTime inquiryDate;
  final String? message; // Optional custom message
  final bool wasRedirectedToWhatsApp;
  final String? additionalNotes;

  const PropertyInquiryModel({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.hostId,
    required this.inquirerId,
    required this.inquirerName,
    required this.inquirerImage,
    required this.inquirerPhoneNumber,
    required this.inquiryDate,
    this.message,
    this.wasRedirectedToWhatsApp = false,
    this.additionalNotes,
  });

  factory PropertyInquiryModel.fromMap(Map<String, dynamic> map) {
    return PropertyInquiryModel(
      id: map['id']?.toString() ?? '',
      propertyId: map['propertyId']?.toString() ?? map['property_id']?.toString() ?? '',
      propertyTitle: map['propertyTitle']?.toString() ?? map['property_title']?.toString() ?? '',
      hostId: map['hostId']?.toString() ?? map['host_id']?.toString() ?? '',
      inquirerId: map['inquirerId']?.toString() ?? map['inquirer_id']?.toString() ?? '',
      inquirerName: map['inquirerName']?.toString() ?? map['inquirer_name']?.toString() ?? '',
      inquirerImage: map['inquirerImage']?.toString() ?? map['inquirer_image']?.toString() ?? '',
      inquirerPhoneNumber: map['inquirerPhoneNumber']?.toString() ?? map['inquirer_phone_number']?.toString() ?? '',
      inquiryDate: DateTime.parse(map['inquiryDate'] ?? map['inquiry_date'] ?? DateTime.now().toIso8601String()),
      message: map['message']?.toString(),
      wasRedirectedToWhatsApp: map['wasRedirectedToWhatsApp'] ?? map['was_redirected_to_whatsapp'] ?? false,
      additionalNotes: map['additionalNotes']?.toString() ?? map['additional_notes']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'hostId': hostId,
      'inquirerId': inquirerId,
      'inquirerName': inquirerName,
      'inquirerImage': inquirerImage,
      'inquirerPhoneNumber': inquirerPhoneNumber,
      'inquiryDate': inquiryDate.toIso8601String(),
      'message': message,
      'wasRedirectedToWhatsApp': wasRedirectedToWhatsApp,
      'additionalNotes': additionalNotes,
    };
  }

  PropertyInquiryModel copyWith({
    String? id,
    String? propertyId,
    String? propertyTitle,
    String? hostId,
    String? inquirerId,
    String? inquirerName,
    String? inquirerImage,
    String? inquirerPhoneNumber,
    DateTime? inquiryDate,
    String? message,
    bool? wasRedirectedToWhatsApp,
    String? additionalNotes,
  }) {
    return PropertyInquiryModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      hostId: hostId ?? this.hostId,
      inquirerId: inquirerId ?? this.inquirerId,
      inquirerName: inquirerName ?? this.inquirerName,
      inquirerImage: inquirerImage ?? this.inquirerImage,
      inquirerPhoneNumber: inquirerPhoneNumber ?? this.inquirerPhoneNumber,
      inquiryDate: inquiryDate ?? this.inquiryDate,
      message: message ?? this.message,
      wasRedirectedToWhatsApp: wasRedirectedToWhatsApp ?? this.wasRedirectedToWhatsApp,
      additionalNotes: additionalNotes ?? this.additionalNotes,
    );
  }

  // Helper methods
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(inquiryDate);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PropertyInquiryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PropertyInquiryModel(id: $id, propertyId: $propertyId, inquirer: $inquirerName, date: ${inquiryDate.toIso8601String()})';
  }
}

// Property View Model (for tracking video views)
class PropertyViewModel {
  final String id;
  final String propertyId;
  final String? userId; // Null for anonymous views
  final String? userName;
  final String ipAddress; // For anonymous tracking
  final DateTime viewedAt;
  final int durationWatchedSeconds; // How long they watched
  final String userAgent;
  final String? referrer;

  const PropertyViewModel({
    required this.id,
    required this.propertyId,
    this.userId,
    this.userName,
    required this.ipAddress,
    required this.viewedAt,
    this.durationWatchedSeconds = 0,
    required this.userAgent,
    this.referrer,
  });

  factory PropertyViewModel.fromMap(Map<String, dynamic> map) {
    return PropertyViewModel(
      id: map['id']?.toString() ?? '',
      propertyId: map['propertyId']?.toString() ?? map['property_id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? map['user_id']?.toString(),
      userName: map['userName']?.toString() ?? map['user_name']?.toString(),
      ipAddress: map['ipAddress']?.toString() ?? map['ip_address']?.toString() ?? '',
      viewedAt: DateTime.parse(map['viewedAt'] ?? map['viewed_at'] ?? DateTime.now().toIso8601String()),
      durationWatchedSeconds: (map['durationWatchedSeconds'] ?? map['duration_watched_seconds'] ?? 0).toInt(),
      userAgent: map['userAgent']?.toString() ?? map['user_agent']?.toString() ?? '',
      referrer: map['referrer']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'propertyId': propertyId,
      'userId': userId,
      'userName': userName,
      'ipAddress': ipAddress,
      'viewedAt': viewedAt.toIso8601String(),
      'durationWatchedSeconds': durationWatchedSeconds,
      'userAgent': userAgent,
      'referrer': referrer,
    };
  }

  PropertyViewModel copyWith({
    String? id,
    String? propertyId,
    String? userId,
    String? userName,
    String? ipAddress,
    DateTime? viewedAt,
    int? durationWatchedSeconds,
    String? userAgent,
    String? referrer,
  }) {
    return PropertyViewModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      ipAddress: ipAddress ?? this.ipAddress,
      viewedAt: viewedAt ?? this.viewedAt,
      durationWatchedSeconds: durationWatchedSeconds ?? this.durationWatchedSeconds,
      userAgent: userAgent ?? this.userAgent,
      referrer: referrer ?? this.referrer,
    );
  }

  // Helper methods
  bool get isAuthenticated => userId != null;
  bool get isAnonymous => userId == null;
  
  String get durationText {
    if (durationWatchedSeconds < 60) {
      return '${durationWatchedSeconds}s';
    } else if (durationWatchedSeconds < 3600) {
      return '${(durationWatchedSeconds / 60).floor()}m ${durationWatchedSeconds % 60}s';
    } else {
      final hours = (durationWatchedSeconds / 3600).floor();
      final minutes = ((durationWatchedSeconds % 3600) / 60).floor();
      return '${hours}h ${minutes}m';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PropertyViewModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PropertyViewModel(id: $id, propertyId: $propertyId, user: ${userName ?? 'Anonymous'}, duration: $durationText)';
  }
}
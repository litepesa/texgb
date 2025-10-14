// lib/features/status/models/status_model.dart

enum StatusType {
  image('image'),
  video('video'),
  text('text');

  const StatusType(this.value);
  final String value;

  static StatusType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'video':
        return StatusType.video;
      case 'text':
        return StatusType.text;
      case 'image':
      default:
        return StatusType.image;
    }
  }
}

enum StatusPrivacy {
  everyone('everyone'),           // All contacts can view
  contactsOnly('contacts_only'),  // Only contacts can view
  selectedContacts('selected_contacts'), // Only selected contacts
  exceptContacts('except_contacts'); // All except selected contacts

  const StatusPrivacy(this.value);
  final String value;

  static StatusPrivacy fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'contacts_only':
        return StatusPrivacy.contactsOnly;
      case 'selected_contacts':
        return StatusPrivacy.selectedContacts;
      case 'except_contacts':
        return StatusPrivacy.exceptContacts;
      case 'everyone':
      default:
        return StatusPrivacy.everyone;
    }
  }
}

class StatusModel {
  final String id;
  final String userId;
  final String userName;
  final String userImage;
  
  // Status content
  final StatusType type;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? caption;
  final String? textContent; // For text-only status
  final String? backgroundColor; // For text status background color
  final String? textColor; // For text status text color
  
  // Media info
  final int? duration; // For video status in seconds
  final int? fileSize; // In bytes
  
  // Privacy settings
  final StatusPrivacy privacy;
  final List<String> selectedContactIds; // For selected/except contacts
  
  // Interactions
  final int viewsCount;
  
  // Status settings
  final bool isMuted; // User muted status updates
  
  // Timestamps
  final String createdAt;
  final String expiresAt; // Status expires after 24 hours
  
  const StatusModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.type,
    this.mediaUrl,
    this.thumbnailUrl,
    this.caption,
    this.textContent,
    this.backgroundColor,
    this.textColor,
    this.duration,
    this.fileSize,
    this.privacy = StatusPrivacy.everyone,
    this.selectedContactIds = const [],
    this.viewsCount = 0,
    this.isMuted = false,
    required this.createdAt,
    required this.expiresAt,
  });

  factory StatusModel.fromMap(Map<String, dynamic> map, String id) {
    return StatusModel(
      id: id,
      userId: map['userId'] ?? map['user_id'] ?? '',
      userName: map['userName'] ?? map['user_name'] ?? '',
      userImage: map['userImage'] ?? map['user_image'] ?? '',
      type: StatusType.fromString(map['type']),
      mediaUrl: map['mediaUrl'] ?? map['media_url'],
      thumbnailUrl: map['thumbnailUrl'] ?? map['thumbnail_url'],
      caption: map['caption'],
      textContent: map['textContent'] ?? map['text_content'],
      backgroundColor: map['backgroundColor'] ?? map['background_color'],
      textColor: map['textColor'] ?? map['text_color'],
      duration: map['duration'],
      fileSize: map['fileSize'] ?? map['file_size'],
      privacy: StatusPrivacy.fromString(map['privacy']),
      selectedContactIds: _parseStringList(map['selectedContactIds'] ?? map['selected_contact_ids']),
      viewsCount: map['viewsCount'] ?? map['views_count'] ?? 0,
      isMuted: map['isMuted'] ?? map['is_muted'] ?? false,
      createdAt: map['createdAt'] ?? map['created_at'] ?? '',
      expiresAt: map['expiresAt'] ?? map['expires_at'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'type': type.value,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'textContent': textContent,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'duration': duration,
      'fileSize': fileSize,
      'privacy': privacy.value,
      'selectedContactIds': selectedContactIds,
      'viewsCount': viewsCount,
      'isMuted': isMuted,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
    };
  }

  StatusModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userImage,
    StatusType? type,
    String? mediaUrl,
    String? thumbnailUrl,
    String? caption,
    String? textContent,
    String? backgroundColor,
    String? textColor,
    int? duration,
    int? fileSize,
    StatusPrivacy? privacy,
    List<String>? selectedContactIds,
    int? viewsCount,
    bool? isMuted,
    String? createdAt,
    String? expiresAt,
  }) {
    return StatusModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      textContent: textContent ?? this.textContent,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      duration: duration ?? this.duration,
      fileSize: fileSize ?? this.fileSize,
      privacy: privacy ?? this.privacy,
      selectedContactIds: selectedContactIds ?? this.selectedContactIds,
      viewsCount: viewsCount ?? this.viewsCount,
      isMuted: isMuted ?? this.isMuted,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  // Helper parsing methods
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }
    
    if (value is String) {
      if (value.isEmpty || value == '{}' || value == '[]') return [];
      String cleaned = value.replaceAll(RegExp(r'[{}"\[\]]'), '');
      if (cleaned.isEmpty) return [];
      return cleaned.split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    
    return [];
  }

  // Timestamp helpers
  DateTime get createdAtDateTime => DateTime.parse(createdAt);
  DateTime get expiresAtDateTime => DateTime.parse(expiresAt);

  // Status type helpers
  bool get isImage => type == StatusType.image;
  bool get isVideo => type == StatusType.video;
  bool get isText => type == StatusType.text;
  bool get isMediaStatus => isImage || isVideo;

  // Expiration helpers
  bool get isExpired {
    return DateTime.now().isAfter(expiresAtDateTime);
  }

  bool get isActive => !isExpired;

  Duration get timeUntilExpiration {
    final now = DateTime.now();
    if (isExpired) return Duration.zero;
    return expiresAtDateTime.difference(now);
  }

  String get timeRemainingText {
    final remaining = timeUntilExpiration;
    
    if (remaining.inHours > 0) {
      return '${remaining.inHours}h remaining';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m remaining';
    } else {
      return 'Expiring soon';
    }
  }

  // Time since posted
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAtDateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // View helpers
  bool get hasViews => viewsCount > 0;

  // Privacy helpers
  bool get isPublic => privacy == StatusPrivacy.everyone;
  bool get isContactsOnly => privacy == StatusPrivacy.contactsOnly;
  bool get isSelectedContacts => privacy == StatusPrivacy.selectedContacts;
  bool get isExceptContacts => privacy == StatusPrivacy.exceptContacts;
  bool get hasPrivacyRestrictions => !isPublic;

  bool canBeViewedBy(String userId, bool isContact) {
    switch (privacy) {
      case StatusPrivacy.everyone:
        return true;
      case StatusPrivacy.contactsOnly:
        return isContact;
      case StatusPrivacy.selectedContacts:
        return selectedContactIds.contains(userId);
      case StatusPrivacy.exceptContacts:
        return isContact && !selectedContactIds.contains(userId);
    }
  }

  // Duration formatting (for videos)
  String get formattedDuration {
    if (duration == null) return '';
    
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // File size formatting
  String get formattedFileSize {
    if (fileSize == null) return '';
    
    final size = fileSize!;
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StatusModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'StatusModel(id: $id, type: ${type.value}, userName: $userName, views: $viewsCount, isActive: $isActive)';
  }
}
// lib/features/users/models/user_model.dart

// User gender enum
enum UserGender {
  male('male'),
  female('female');

  const UserGender(this.value);
  final String value;

  static UserGender? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    switch (value.toLowerCase()) {
      case 'male':
        return UserGender.male;
      case 'female':
        return UserGender.female;
      default:
        return null;
    }
  }

  String get displayName {
    switch (this) {
      case UserGender.male:
        return 'Male';
      case UserGender.female:
        return 'Female';
    }
  }
}

// User preferences for video features
class UserPreferences {
  final bool autoPlay;
  final bool receiveNotifications;
  final bool darkMode;

  const UserPreferences({
    this.autoPlay = true,
    this.receiveNotifications = true,
    this.darkMode = false,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      autoPlay: map['autoPlay'] ?? map['auto_play'] ?? true,
      receiveNotifications:
          map['receiveNotifications'] ?? map['receive_notifications'] ?? true,
      darkMode: map['darkMode'] ?? map['dark_mode'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'autoPlay': autoPlay,
      'receiveNotifications': receiveNotifications,
      'darkMode': darkMode,
    };
  }

  UserPreferences copyWith({
    bool? autoPlay,
    bool? receiveNotifications,
    bool? darkMode,
  }) {
    return UserPreferences(
      autoPlay: autoPlay ?? this.autoPlay,
      receiveNotifications: receiveNotifications ?? this.receiveNotifications,
      darkMode: darkMode ?? this.darkMode,
    );
  }
}

class UserModel {
  // ===============================
  // CORE FIELDS
  // ===============================
  final String uid;
  final String phoneNumber;
  final String? mpesaNumber;
  final String name;
  final String bio;
  final String profileImage;
  final String coverImage;
  final int followers;
  final int following;
  final int videosCount;
  final int likesCount;
  final bool isVerified;

  // ===============================
  // PERMISSION FIELDS (Staff roles)
  // ===============================
  final bool isAdmin; // Platform administrator (full control)
  final bool isModerator; // Content moderator (can moderate content, ban users)

  // ===============================
  // BUSINESS/COMMERCE ROLE
  // ===============================
  final bool isSeller; // Marketplace seller (can list products for sale)

  // ===============================
  // NEW PROFILE FIELDS
  // ===============================
  final String? gender; // NEW: User gender (male/female)
  final String? location; // NEW: User location (e.g., "Nairobi, Kenya")
  final String?
      language; // NEW: User native language (e.g., "English", "Swahili")

  // ===============================
  // PAYMENT FIELDS (M-Pesa activation payment)
  // ===============================
  final bool hasPaid; // NEW: Has user paid KES 99 activation fee
  final String? paymentDate; // NEW: Date when user paid activation fee

  // ===============================
  // BAN/RESTRICTION FIELDS (Admin controlled)
  // ===============================
  final bool
      canComment; // NEW: Can user comment on threads? (true = yes, false = banned from commenting)
  final bool
      canPost; // NEW: Can user post videos? (true = yes, false = banned from posting)

  // ===============================
  // OTHER FIELDS
  // ===============================
  final List<String> tags;
  final List<String> followerUIDs;
  final List<String> followingUIDs;
  final List<String> likedVideos;
  final String createdAt;
  final String updatedAt;
  final String lastSeen;
  final bool isActive;
  final bool isFeatured;
  final bool isLive; // NEW: Track if user is currently live streaming
  final String? lastPostAt;
  final UserPreferences preferences;

  UserModel({
    required this.uid,
    required this.phoneNumber,
    this.mpesaNumber,
    required this.name,
    required this.bio,
    required this.profileImage,
    required this.coverImage,
    required this.followers,
    required this.following,
    required this.videosCount,
    required this.likesCount,
    required this.isVerified,
    this.isAdmin = false, // NEW: Default = false (not admin)
    this.isModerator = false, // NEW: Default = false (not moderator)
    this.isSeller = false, // NEW: Default = false (not seller)
    this.gender, // NEW
    this.location, // NEW
    this.language, // NEW
    this.hasPaid = true, // NEW: Default = true (grandfathered users)
    this.paymentDate, // NEW
    this.canComment = true, // NEW: Default = true (not banned)
    this.canPost = true, // NEW: Default = true (not banned)
    required this.tags,
    required this.followerUIDs,
    required this.followingUIDs,
    required this.likedVideos,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSeen,
    required this.isActive,
    required this.isFeatured,
    this.isLive = false, // NEW
    this.lastPostAt,
    this.preferences = const UserPreferences(),
  });

  // Factory constructor for creating user from backend data
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: _extractString(map['uid'] ?? map['id']) ?? '',
      phoneNumber:
          _extractString(map['phoneNumber'] ?? map['phone_number']) ?? '',
      mpesaNumber:
          _extractMpesaNumber(map['mpesaNumber'] ?? map['mpesa_number']),
      name: _extractString(map['name']) ?? '',
      bio: _extractString(map['bio']) ?? '',
      profileImage:
          _extractString(map['profileImage'] ?? map['profile_image']) ?? '',
      coverImage: _extractString(map['coverImage'] ?? map['cover_image']) ?? '',
      followers:
          _extractInt(map['followersCount'] ?? map['followers_count']) ?? 0,
      following:
          _extractInt(map['followingCount'] ?? map['following_count']) ?? 0,
      videosCount: _extractInt(map['videosCount'] ?? map['videos_count']) ?? 0,
      likesCount: _extractInt(map['likesCount'] ?? map['likes_count']) ?? 0,
      isVerified:
          _extractBool(map['isVerified'] ?? map['is_verified']) ?? false,
      // NEW: Extract admin/moderator/seller flags
      isAdmin: _extractBool(map['isAdmin'] ?? map['is_admin']) ?? false,
      isModerator:
          _extractBool(map['isModerator'] ?? map['is_moderator']) ?? false,
      isSeller: _extractBool(map['isSeller'] ?? map['is_seller']) ?? false,
      // NEW: Extract profile fields
      gender: _extractString(map['gender']),
      location: _extractString(map['location']),
      language: _extractString(map['language']),
      // NEW: Extract payment fields
      // NOTE: Default to true for grandfathered users (existing users without this field)
      hasPaid: _extractBool(map['hasPaid'] ?? map['has_paid']) ?? true,
      paymentDate: _extractString(map['paymentDate'] ?? map['payment_date']),
      // NEW: Extract ban/restriction fields
      canComment: _extractBool(map['canComment'] ?? map['can_comment']) ?? true,
      canPost: _extractBool(map['canPost'] ?? map['can_post']) ?? true,
      tags: _parseStringArray(map['tags']),
      followerUIDs: _parseStringArray(
          map['followerUIDs'] ?? map['follower_uids'] ?? map['follower_UIDs']),
      followingUIDs: _parseStringArray(map['followingUIDs'] ??
          map['following_uids'] ??
          map['following_UIDs']),
      likedVideos: _parseStringArray(map['likedVideos'] ?? map['liked_videos']),
      createdAt: _extractString(map['createdAt'] ?? map['created_at']) ?? '',
      updatedAt: _extractString(map['updatedAt'] ?? map['updated_at']) ?? '',
      lastSeen: _extractString(map['lastSeen'] ?? map['last_seen']) ?? '',
      isActive: _extractBool(map['isActive'] ?? map['is_active']) ?? true,
      isFeatured:
          _extractBool(map['isFeatured'] ?? map['is_featured']) ?? false,
      isLive: _extractBool(map['isLive'] ?? map['is_live']) ?? false, // NEW
      lastPostAt: _extractString(map['lastPostAt'] ?? map['last_post_at']),
      preferences: UserPreferences.fromMap(
        (map['preferences'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
    );
  }

  // Helper methods for safe type extraction
  static String? _extractString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    if (value is Map && value['url'] != null) return value['url'].toString();
    return value.toString();
  }

  static int? _extractInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.round();
    return null;
  }

  static bool? _extractBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    if (value is int) return value == 1;
    return null;
  }

  static String? _extractMpesaNumber(dynamic value) {
    if (value == null) return null;

    String? numberStr = _extractString(value);
    if (numberStr == null || numberStr.isEmpty) return null;

    String cleanedNumber = numberStr.replaceAll(RegExp(r'\D'), '');

    if (cleanedNumber.length == 12 && cleanedNumber.startsWith('254')) {
      return cleanedNumber;
    }

    if (cleanedNumber.length == 10 && cleanedNumber.startsWith('0')) {
      return '254${cleanedNumber.substring(1)}';
    }

    if (cleanedNumber.length == 9) {
      return '254$cleanedNumber';
    }

    return null;
  }

  static List<String> _parseStringArray(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }

    if (value is String) {
      if (value.isEmpty || value == '{}' || value == '[]') return [];
      String cleaned = value.replaceAll(RegExp(r'[{}"\[\]]'), '');
      if (cleaned.isEmpty) return [];
      return cleaned
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return [];
  }

  // Create method for new users
  factory UserModel.create({
    required String uid,
    required String name,
    required String phoneNumber,
    String? mpesaNumber,
    required String profileImage,
    required String bio,
    bool isAdmin = false, // NEW: Default false
    bool isModerator = false, // NEW: Default false
    bool isSeller = false, // NEW: Default false
    String? gender,
    String? location,
    String? language,
    bool hasPaid = false, // NEW: Default false for new users (must pay KES 100)
    bool canComment = true, // NEW: Default true
    bool canPost = true, // NEW: Default true
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    return UserModel(
      uid: uid,
      phoneNumber: phoneNumber,
      mpesaNumber: mpesaNumber,
      name: name,
      bio: bio,
      profileImage: profileImage,
      coverImage: '',
      followers: 0,
      following: 0,
      videosCount: 0,
      likesCount: 0,
      isVerified: false,
      isAdmin: isAdmin, // NEW
      isModerator: isModerator, // NEW
      isSeller: isSeller, // NEW
      gender: gender, // NEW
      location: location, // NEW
      language: language, // NEW
      hasPaid: hasPaid, // NEW: Explicitly set for new users
      canComment: canComment, // NEW
      canPost: canPost, // NEW
      tags: [],
      followerUIDs: [],
      followingUIDs: [],
      likedVideos: [],
      createdAt: now,
      updatedAt: now,
      lastSeen: now,
      isActive: true,
      isFeatured: false,
      isLive: false, // NEW
      lastPostAt: null,
      preferences: const UserPreferences(),
    );
  }

  // Convert to map for sending to backend
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phoneNumber': phoneNumber,
      'mpesaNumber': mpesaNumber,
      'profileImage': profileImage,
      'coverImage': coverImage,
      'bio': bio,
      'userType': 'user',
      'isAdmin': isAdmin, // NEW
      'isModerator': isModerator, // NEW
      'isSeller': isSeller, // NEW
      'gender': gender, // NEW
      'location': location, // NEW
      'language': language, // NEW
      'hasPaid': hasPaid, // NEW
      'paymentDate': paymentDate, // NEW
      'canComment': canComment, // NEW
      'canPost': canPost, // NEW
      'followersCount': followers,
      'followingCount': following,
      'videosCount': videosCount,
      'likesCount': likesCount,
      'isVerified': isVerified,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'isLive': isLive, // NEW
      'tags': _formatArrayForPostgreSQL(tags),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastSeen': lastSeen,
      'lastPostAt': lastPostAt,
      'preferences': preferences.toMap(),
    };
  }

  static dynamic _formatArrayForPostgreSQL(List<String> array) {
    if (array.isEmpty) {
      return <String>[];
    }
    return array;
  }

  // CopyWith method
  UserModel copyWith({
    String? uid,
    String? phoneNumber,
    String? mpesaNumber,
    String? name,
    String? bio,
    String? profileImage,
    String? coverImage,
    int? followers,
    int? following,
    int? videosCount,
    int? likesCount,
    bool? isVerified,
    bool? isAdmin, // NEW
    bool? isModerator, // NEW
    bool? isSeller, // NEW
    String? gender, // NEW
    String? location, // NEW
    String? language, // NEW
    bool? hasPaid, // NEW
    String? paymentDate, // NEW
    bool? canComment, // NEW
    bool? canPost, // NEW
    List<String>? tags,
    List<String>? followerUIDs,
    List<String>? followingUIDs,
    List<String>? likedVideos,
    String? createdAt,
    String? updatedAt,
    String? lastSeen,
    bool? isActive,
    bool? isFeatured,
    bool? isLive, // NEW
    String? lastPostAt,
    UserPreferences? preferences,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      mpesaNumber: mpesaNumber ?? this.mpesaNumber,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      profileImage: profileImage ?? this.profileImage,
      coverImage: coverImage ?? this.coverImage,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      videosCount: videosCount ?? this.videosCount,
      likesCount: likesCount ?? this.likesCount,
      isVerified: isVerified ?? this.isVerified,
      isAdmin: isAdmin ?? this.isAdmin, // NEW
      isModerator: isModerator ?? this.isModerator, // NEW
      isSeller: isSeller ?? this.isSeller, // NEW
      gender: gender ?? this.gender, // NEW
      location: location ?? this.location, // NEW
      language: language ?? this.language, // NEW
      hasPaid: hasPaid ?? this.hasPaid, // NEW
      paymentDate: paymentDate ?? this.paymentDate, // NEW
      canComment: canComment ?? this.canComment, // NEW
      canPost: canPost ?? this.canPost, // NEW
      tags: tags ?? this.tags,
      followerUIDs: followerUIDs ?? this.followerUIDs,
      followingUIDs: followingUIDs ?? this.followingUIDs,
      likedVideos: likedVideos ?? this.likedVideos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      isLive: isLive ?? this.isLive, // NEW
      lastPostAt: lastPostAt ?? this.lastPostAt,
      preferences: preferences ?? this.preferences,
    );
  }

  // ===============================
  // HELPER METHODS
  // ===============================
  String get id => uid;

  // NEW: Staff/Permission helper methods
  bool get isStaff => isAdmin || isModerator;
  bool get isSuperUser => isAdmin && isModerator;
  bool get canModerate => isAdmin || isModerator;
  bool get canAccessAdminPanel => isAdmin;
  bool get canManageUsers => isAdmin;
  bool get canManageContent => isAdmin || isModerator;

  String get userTypeDisplay {
    if (isAdmin && isModerator) return 'Super Admin';
    if (isAdmin) return 'Administrator';
    if (isModerator) return 'Moderator';
    if (isVerified) return 'Verified User';
    return 'User';
  }

  // NEW: Ban status helper methods
  bool get isBannedFromCommenting => !canComment;
  bool get isBannedFromPosting => !canPost;
  bool get isFullyBanned => !canComment && !canPost;
  bool get hasAnyRestrictions => !canComment || !canPost;

  String get banStatusDescription {
    if (isFullyBanned) return 'Banned from commenting and posting';
    if (isBannedFromCommenting) return 'Banned from commenting';
    if (isBannedFromPosting) return 'Banned from posting';
    return 'No restrictions';
  }

  // M-Pesa helper methods
  bool get hasMpesa => mpesaNumber != null && mpesaNumber!.isNotEmpty;

  String? get mpesaFormatted {
    if (!hasMpesa) return null;
    // Return formatted M-Pesa number for display
    return mpesaNumber;
  }

  String? get mpesaDisplayNumber {
    if (!hasMpesa) return null;
    // Convert 254XXXXXXXXX to 07XX XXX XXX format for better display
    if (mpesaNumber!.startsWith('254') && mpesaNumber!.length == 12) {
      final local = '0${mpesaNumber!.substring(3)}';
      return '${local.substring(0, 4)} ${local.substring(4, 7)} ${local.substring(7)}';
    }
    return mpesaNumber;
  }

  // NEW: Gender helper methods
  bool get hasGender => gender != null && gender!.isNotEmpty;

  UserGender? get genderEnum => UserGender.fromString(gender);

  String get genderDisplay {
    final g = genderEnum;
    return g?.displayName ?? 'Not specified';
  }

  bool get isMale => genderEnum == UserGender.male;
  bool get isFemale => genderEnum == UserGender.female;

  // NEW: Location helper methods
  bool get hasLocation => location != null && location!.isNotEmpty;

  String get locationDisplay => location ?? 'Location not set';

  // NEW: Language helper methods
  bool get hasLanguage => language != null && language!.isNotEmpty;

  String get languageDisplay => language ?? 'Language not set';

  // Timestamp helper methods
  DateTime get lastSeenDateTime => DateTime.parse(lastSeen);
  DateTime get createdAtDateTime => DateTime.parse(createdAt);
  DateTime get updatedAtDateTime => DateTime.parse(updatedAt);

  DateTime? get lastPostAtDateTime {
    if (lastPostAt == null || lastPostAt!.isEmpty) return null;
    try {
      return DateTime.parse(lastPostAt!);
    } catch (e) {
      return null;
    }
  }

  bool get hasPostedVideos => lastPostAt != null && lastPostAt!.isNotEmpty;

  String get lastPostTimeAgo {
    final lastPost = lastPostAtDateTime;
    if (lastPost == null) return 'Never posted';

    final now = DateTime.now();
    final difference = now.difference(lastPost);

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
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, isAdmin: $isAdmin, isModerator: $isModerator, isSeller: $isSeller, phoneNumber: $phoneNumber, isLive: $isLive, canComment: $canComment, canPost: $canPost)';
  }

  // ===============================
  // VALIDATION METHODS
  // ===============================
  Map<String, dynamic> toDebugMap() {
    return {
      ...toMap(),
      'debug_info': {
        'tags_length': tags.length,
        'tags_type': tags.runtimeType.toString(),
        'tags_formatted': _formatArrayForPostgreSQL(tags),
        'formatted_type':
            _formatArrayForPostgreSQL(tags).runtimeType.toString(),
        'lastPostAt_value': lastPostAt,
        'hasPostedVideos': hasPostedVideos,
        'lastPostTimeAgo': lastPostTimeAgo,
        'staff_info': {
          'is_admin': isAdmin,
          'is_moderator': isModerator,
          'is_staff': isStaff,
          'is_super_user': isSuperUser,
          'can_moderate': canModerate,
          'can_access_admin_panel': canAccessAdminPanel,
          'can_manage_users': canManageUsers,
          'can_manage_content': canManageContent,
          'user_type_display': userTypeDisplay,
        },
        'mpesa_info': {
          'has_mpesa': hasMpesa,
          'mpesa_formatted': mpesaFormatted,
          'mpesa_display_number': mpesaDisplayNumber,
        },
        'profile_info': {
          'has_gender': hasGender,
          'gender_display': genderDisplay,
          'has_location': hasLocation,
          'location_display': locationDisplay,
          'has_language': hasLanguage,
          'language_display': languageDisplay,
        },
        'live_status': {
          'is_live': isLive,
        },
        'ban_status': {
          'can_comment': canComment,
          'can_post': canPost,
          'is_banned_from_commenting': isBannedFromCommenting,
          'is_banned_from_posting': isBannedFromPosting,
          'is_fully_banned': isFullyBanned,
          'has_any_restrictions': hasAnyRestrictions,
          'ban_status_description': banStatusDescription,
        },
      },
    };
  }

  List<String> validate() {
    List<String> errors = [];

    if (uid.isEmpty) errors.add('UID cannot be empty');
    if (name.isEmpty) errors.add('Name cannot be empty');
    if (phoneNumber.isEmpty) errors.add('Phone number cannot be empty');
    if (name.length > 50) errors.add('Name cannot exceed 50 characters');
    if (bio.length > 160) errors.add('Bio cannot exceed 160 characters');

    // Validate M-Pesa number format if provided
    if (mpesaNumber != null && mpesaNumber!.isNotEmpty) {
      if (!RegExp(r'^254\d{9}$').hasMatch(mpesaNumber!)) {
        errors.add('M-Pesa number must be in format 254XXXXXXXXX');
      }
    }

    // NEW: Validate gender
    if (gender != null && gender!.isNotEmpty) {
      if (genderEnum == null) {
        errors.add('Gender must be either "male" or "female"');
      }
    }

    // NEW: Validate location length
    if (location != null && location!.length > 255) {
      errors.add('Location cannot exceed 255 characters');
    }

    // NEW: Validate language length
    if (language != null && language!.length > 100) {
      errors.add('Language cannot exceed 100 characters');
    }

    return errors;
  }

  bool get isValid => validate().isEmpty;
}

// lib/features/users/models/user_model.dart

// User role enum
enum UserRole {
  admin('admin'),
  host('host'), 
  guest('guest');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'host':
        return UserRole.host;
      case 'guest':
      default:
        return UserRole.guest;
    }
  }

  bool get canPost => this == UserRole.admin || this == UserRole.host;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.host:
        return 'Host';
      case UserRole.guest:
        return 'Guest';
    }
  }
}

// NEW: User gender enum
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
      receiveNotifications: map['receiveNotifications'] ?? map['receive_notifications'] ?? true,
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
  final String? whatsappNumber;
  final String name;
  final String bio;
  final String profileImage;
  final String coverImage;
  final int followers;
  final int following;
  final int videosCount;
  final int likesCount;
  final bool isVerified;
  final UserRole role;
  
  // ===============================
  // NEW PROFILE FIELDS
  // ===============================
  final String? gender;      // NEW: User gender (male/female)
  final String? location;    // NEW: User location (e.g., "Nairobi, Kenya")
  final String? language;    // NEW: User native language (e.g., "English", "Swahili")
  
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
  final bool isLive;         // NEW: Track if user is currently live streaming
  final String? lastPostAt;
  final UserPreferences preferences;

  UserModel({
    required this.uid,
    required this.phoneNumber,
    this.whatsappNumber,
    required this.name,
    required this.bio,
    required this.profileImage,
    required this.coverImage,
    required this.followers,
    required this.following,
    required this.videosCount,
    required this.likesCount,
    required this.isVerified,
    this.role = UserRole.guest,
    this.gender,      // NEW
    this.location,    // NEW
    this.language,    // NEW
    required this.tags,
    required this.followerUIDs,
    required this.followingUIDs,
    required this.likedVideos,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSeen,
    required this.isActive,
    required this.isFeatured,
    this.isLive = false,  // NEW
    this.lastPostAt,
    this.preferences = const UserPreferences(),
  });

  // Factory constructor for creating user from backend data
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: _extractString(map['uid'] ?? map['id']) ?? '',
      phoneNumber: _extractString(map['phoneNumber'] ?? map['phone_number']) ?? '',
      whatsappNumber: _extractWhatsAppNumber(map['whatsappNumber'] ?? map['whatsapp_number']),
      name: _extractString(map['name']) ?? '',
      bio: _extractString(map['bio']) ?? '',
      profileImage: _extractString(map['profileImage'] ?? map['profile_image']) ?? '',
      coverImage: _extractString(map['coverImage'] ?? map['cover_image']) ?? '',
      followers: _extractInt(map['followersCount'] ?? map['followers_count']) ?? 0,
      following: _extractInt(map['followingCount'] ?? map['following_count']) ?? 0,
      videosCount: _extractInt(map['videosCount'] ?? map['videos_count']) ?? 0,
      likesCount: _extractInt(map['likesCount'] ?? map['likes_count']) ?? 0,
      isVerified: _extractBool(map['isVerified'] ?? map['is_verified']) ?? false,
      role: UserRole.fromString(map['role'] ?? map['userRole'] ?? map['user_role']),
      // NEW: Extract profile fields
      gender: _extractString(map['gender']),
      location: _extractString(map['location']),
      language: _extractString(map['language']),
      tags: _parseStringArray(map['tags']),
      followerUIDs: _parseStringArray(map['followerUIDs'] ?? map['follower_uids'] ?? map['follower_UIDs']),
      followingUIDs: _parseStringArray(map['followingUIDs'] ?? map['following_uids'] ?? map['following_UIDs']),
      likedVideos: _parseStringArray(map['likedVideos'] ?? map['liked_videos']),
      createdAt: _extractString(map['createdAt'] ?? map['created_at']) ?? '',
      updatedAt: _extractString(map['updatedAt'] ?? map['updated_at']) ?? '',
      lastSeen: _extractString(map['lastSeen'] ?? map['last_seen']) ?? '',
      isActive: _extractBool(map['isActive'] ?? map['is_active']) ?? true,
      isFeatured: _extractBool(map['isFeatured'] ?? map['is_featured']) ?? false,
      isLive: _extractBool(map['isLive'] ?? map['is_live']) ?? false,  // NEW
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

  static String? _extractWhatsAppNumber(dynamic value) {
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

  // Create method for new users
  factory UserModel.create({
    required String uid,
    required String name,
    required String phoneNumber,
    String? whatsappNumber,
    required String profileImage,
    required String bio,
    UserRole role = UserRole.guest,
    String? gender,
    String? location,
    String? language,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    return UserModel(
      uid: uid,
      phoneNumber: phoneNumber,
      whatsappNumber: whatsappNumber,
      name: name,
      bio: bio,
      profileImage: profileImage,
      coverImage: '',
      followers: 0,
      following: 0,
      videosCount: 0,
      likesCount: 0,
      isVerified: false,
      role: role,
      gender: gender,        // NEW
      location: location,    // NEW
      language: language,    // NEW
      tags: [],
      followerUIDs: [],
      followingUIDs: [],
      likedVideos: [],
      createdAt: now,
      updatedAt: now,
      lastSeen: now,
      isActive: true,
      isFeatured: false,
      isLive: false,         // NEW
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
      'whatsappNumber': whatsappNumber,
      'profileImage': profileImage,
      'coverImage': coverImage,
      'bio': bio,
      'userType': 'user',
      'role': role.value,
      'gender': gender,      // NEW
      'location': location,  // NEW
      'language': language,  // NEW
      'followersCount': followers,
      'followingCount': following,
      'videosCount': videosCount,
      'likesCount': likesCount,
      'isVerified': isVerified,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'isLive': isLive,      // NEW
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
    String? whatsappNumber,
    String? name,
    String? bio,
    String? profileImage,
    String? coverImage,
    int? followers,
    int? following,
    int? videosCount,
    int? likesCount,
    bool? isVerified,
    UserRole? role,
    String? gender,      // NEW
    String? location,    // NEW
    String? language,    // NEW
    List<String>? tags,
    List<String>? followerUIDs,
    List<String>? followingUIDs,
    List<String>? likedVideos,
    String? createdAt,
    String? updatedAt,
    String? lastSeen,
    bool? isActive,
    bool? isFeatured,
    bool? isLive,        // NEW
    String? lastPostAt,
    UserPreferences? preferences,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      profileImage: profileImage ?? this.profileImage,
      coverImage: coverImage ?? this.coverImage,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      videosCount: videosCount ?? this.videosCount,
      likesCount: likesCount ?? this.likesCount,
      isVerified: isVerified ?? this.isVerified,
      role: role ?? this.role,
      gender: gender ?? this.gender,        // NEW
      location: location ?? this.location,  // NEW
      language: language ?? this.language,  // NEW
      tags: tags ?? this.tags,
      followerUIDs: followerUIDs ?? this.followerUIDs,
      followingUIDs: followingUIDs ?? this.followingUIDs,
      likedVideos: likedVideos ?? this.likedVideos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      isLive: isLive ?? this.isLive,        // NEW
      lastPostAt: lastPostAt ?? this.lastPostAt,
      preferences: preferences ?? this.preferences,
    );
  }

  // ===============================
  // HELPER METHODS
  // ===============================
  String get id => uid;

  // Role-based helper methods
  bool get canPost => role.canPost;
  bool get isAdmin => role == UserRole.admin;
  bool get isHost => role == UserRole.host;
  bool get isGuest => role == UserRole.guest;
  String get roleDisplayName => role.displayName;

  // WhatsApp helper methods
  bool get hasWhatsApp => whatsappNumber != null && whatsappNumber!.isNotEmpty;
  
  String? get whatsappLink {
    if (!hasWhatsApp) return null;
    return 'https://wa.me/$whatsappNumber';
  }
  
  String? get whatsappLinkWithMessage {
    if (!hasWhatsApp) return null;
    String message = Uri.encodeComponent('Hi $name! I found your profile on the app.');
    return 'https://wa.me/$whatsappNumber?text=$message';
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
    return 'UserModel(uid: $uid, name: $name, role: ${role.value}, phoneNumber: $phoneNumber, isLive: $isLive)';
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
        'formatted_type': _formatArrayForPostgreSQL(tags).runtimeType.toString(),
        'lastPostAt_value': lastPostAt,
        'hasPostedVideos': hasPostedVideos,
        'lastPostTimeAgo': lastPostTimeAgo,
        'role_info': {
          'role_value': role.value,
          'role_display': role.displayName,
          'can_post': canPost,
        },
        'whatsapp_info': {
          'has_whatsapp': hasWhatsApp,
          'whatsapp_link': whatsappLink,
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
    
    // Validate WhatsApp number format if provided
    if (whatsappNumber != null && whatsappNumber!.isNotEmpty) {
      if (!RegExp(r'^254\d{9}$').hasMatch(whatsappNumber!)) {
        errors.add('WhatsApp number must be in format 254XXXXXXXXX');
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
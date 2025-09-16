// lib/features/users/models/user_model.dart
// EXTENDED: Added drama support while preserving video functionality + lastPostAt
// FIXED: Backend field mapping compatibility

// User preferences for both video and drama features
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
  // EXISTING VIDEO FIELDS (preserved)
  // ===============================
  final String uid;
  final String phoneNumber;
  final String name;
  final String bio;
  final String profileImage;
  final String coverImage;
  final int followers;
  final int following;
  final int videosCount;
  final int likesCount;
  final bool isVerified;
  final List<String> tags;
  final List<String> followerUIDs;
  final List<String> followingUIDs;
  final List<String> likedVideos;
  final String createdAt;
  final String updatedAt;
  final String lastSeen;
  final bool isActive;
  final bool isFeatured;
  final String? lastPostAt; // UPDATED: Now a proper field instead of getter

  // ===============================
  // NEW DRAMA FIELDS (added)
  // ===============================
  final List<String> favoriteDramas;
  final List<String> watchHistory;
  final Map<String, int> dramaProgress;
  final List<String> unlockedDramas;
  final UserPreferences preferences;

  UserModel({
    // Existing video fields
    required this.uid,
    required this.phoneNumber,
    required this.name,
    required this.bio,
    required this.profileImage,
    required this.coverImage,
    required this.followers,
    required this.following,
    required this.videosCount,
    required this.likesCount,
    required this.isVerified,
    required this.tags,
    required this.followerUIDs,
    required this.followingUIDs,
    required this.likedVideos,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSeen,
    required this.isActive,
    required this.isFeatured,
    this.lastPostAt, // UPDATED: Now a constructor parameter
    // New drama fields with defaults
    this.favoriteDramas = const [],
    this.watchHistory = const [],
    this.dramaProgress = const {},
    this.unlockedDramas = const [],
    this.preferences = const UserPreferences(),
  });

  // FIXED: Factory constructor for creating user from backend data with proper field mapping
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      // FIXED: Handle both camelCase and snake_case field names from backend
      uid: _extractString(map['uid'] ?? map['id']) ?? '',
      phoneNumber: _extractString(map['phoneNumber'] ?? map['phone_number']) ?? '',
      name: _extractString(map['name']) ?? '',
      bio: _extractString(map['bio']) ?? '',
      profileImage: _extractString(map['profileImage'] ?? map['profile_image']) ?? '',
      coverImage: _extractString(map['coverImage'] ?? map['cover_image']) ?? '',
      followers: _extractInt(map['followersCount'] ?? map['followers_count']) ?? 0,
      following: _extractInt(map['followingCount'] ?? map['following_count']) ?? 0,
      videosCount: _extractInt(map['videosCount'] ?? map['videos_count']) ?? 0,
      likesCount: _extractInt(map['likesCount'] ?? map['likes_count']) ?? 0,
      isVerified: _extractBool(map['isVerified'] ?? map['is_verified']) ?? false,
      tags: _parseStringArray(map['tags']),
      followerUIDs: _parseStringArray(map['followerUIDs'] ?? map['follower_uids'] ?? map['follower_UIDs']),
      followingUIDs: _parseStringArray(map['followingUIDs'] ?? map['following_uids'] ?? map['following_UIDs']),
      likedVideos: _parseStringArray(map['likedVideos'] ?? map['liked_videos']),
      createdAt: _extractString(map['createdAt'] ?? map['created_at']) ?? '',
      updatedAt: _extractString(map['updatedAt'] ?? map['updated_at']) ?? '',
      lastSeen: _extractString(map['lastSeen'] ?? map['last_seen']) ?? '',
      isActive: _extractBool(map['isActive'] ?? map['is_active']) ?? true,
      isFeatured: _extractBool(map['isFeatured'] ?? map['is_featured']) ?? false,
      lastPostAt: _extractString(map['lastPostAt'] ?? map['last_post_at']), // FIXED: Added proper mapping
      // New drama field mappings (added)
      favoriteDramas: _parseStringArray(map['favoriteDramas'] ?? map['favorite_dramas']),
      watchHistory: _parseStringArray(map['watchHistory'] ?? map['watch_history']),
      dramaProgress: _parseIntMap(map['dramaProgress'] ?? map['drama_progress']),
      unlockedDramas: _parseStringArray(map['unlockedDramas'] ?? map['unlocked_dramas']),
      preferences: UserPreferences.fromMap(
        (map['preferences'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
    );
  }

  // FIXED: Helper methods for safe type extraction
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

  // Helper method to safely parse string arrays (existing with improvements)
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

  // FIXED: Helper method to safely parse int maps (for drama progress)
  static Map<String, int> _parseIntMap(dynamic value) {
    if (value == null) return {};
    
    if (value is Map) {
      final Map<String, int> result = {};
      value.forEach((key, val) {
        if (key != null && val != null) {
          final intVal = _extractInt(val);
          if (intVal != null) {
            result[key.toString()] = intVal;
          }
        }
      });
      return result;
    }
    
    return {};
  }

  // Create method for new users (PHONE-ONLY) - preserved with drama defaults
  factory UserModel.create({
    required String uid,
    required String name,
    required String phoneNumber,
    required String profileImage,
    required String bio,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    return UserModel(
      uid: uid,
      phoneNumber: phoneNumber,
      name: name,
      bio: bio,
      profileImage: profileImage,
      coverImage: '',
      followers: 0,
      following: 0,
      videosCount: 0,
      likesCount: 0,
      isVerified: false,
      tags: [],
      followerUIDs: [],
      followingUIDs: [],
      likedVideos: [],
      createdAt: now,
      updatedAt: now,
      lastSeen: now,
      isActive: true,
      isFeatured: false,
      lastPostAt: null, // UPDATED: New users haven't posted yet
      // Drama defaults for new users
      favoriteDramas: [],
      watchHistory: [],
      dramaProgress: {},
      unlockedDramas: [],
      preferences: const UserPreferences(),
    );
  }

  // Updated toMap method with drama fields
  Map<String, dynamic> toMap() {
    return {
      // Existing video fields (preserved)
      'uid': uid,
      'name': name,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'coverImage': coverImage,
      'bio': bio,
      'userType': 'user',
      'followersCount': followers,
      'followingCount': following,
      'videosCount': videosCount,
      'likesCount': likesCount,
      'isVerified': isVerified,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'tags': _formatArrayForPostgreSQL(tags),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastSeen': lastSeen,
      'lastPostAt': lastPostAt, // UPDATED: Added to serialization
      // New drama fields (added)
      'favoriteDramas': _formatArrayForPostgreSQL(favoriteDramas),
      'watchHistory': _formatArrayForPostgreSQL(watchHistory),
      'dramaProgress': dramaProgress,
      'unlockedDramas': _formatArrayForPostgreSQL(unlockedDramas),
      'preferences': preferences.toMap(),
    };
  }

  // Format arrays for PostgreSQL compatibility (existing)
  static dynamic _formatArrayForPostgreSQL(List<String> array) {
    if (array.isEmpty) {
      return <String>[];
    }
    return array;
  }

  // Updated copyWith method to include drama fields
  UserModel copyWith({
    String? uid,
    String? phoneNumber,
    String? name,
    String? bio,
    String? profileImage,
    String? coverImage,
    int? followers,
    int? following,
    int? videosCount,
    int? likesCount,
    bool? isVerified,
    List<String>? tags,
    List<String>? followerUIDs,
    List<String>? followingUIDs,
    List<String>? likedVideos,
    String? createdAt,
    String? updatedAt,
    String? lastSeen,
    bool? isActive,
    bool? isFeatured,
    String? lastPostAt, // UPDATED: Added to copyWith
    // New drama fields
    List<String>? favoriteDramas,
    List<String>? watchHistory,
    Map<String, int>? dramaProgress,
    List<String>? unlockedDramas,
    UserPreferences? preferences,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      profileImage: profileImage ?? this.profileImage,
      coverImage: coverImage ?? this.coverImage,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      videosCount: videosCount ?? this.videosCount,
      likesCount: likesCount ?? this.likesCount,
      isVerified: isVerified ?? this.isVerified,
      tags: tags ?? this.tags,
      followerUIDs: followerUIDs ?? this.followerUIDs,
      followingUIDs: followingUIDs ?? this.followingUIDs,
      likedVideos: likedVideos ?? this.likedVideos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      lastPostAt: lastPostAt ?? this.lastPostAt, // UPDATED: Added to copyWith
      // New drama fields
      favoriteDramas: favoriteDramas ?? List<String>.from(this.favoriteDramas),
      watchHistory: watchHistory ?? List<String>.from(this.watchHistory),
      dramaProgress: dramaProgress ?? Map<String, int>.from(this.dramaProgress),
      unlockedDramas: unlockedDramas ?? List<String>.from(this.unlockedDramas),
      preferences: preferences ?? this.preferences,
    );
  }

  // ===============================
  // EXISTING VIDEO HELPER METHODS (preserved)
  // ===============================
  String get id => uid; // Backward compatibility

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, phoneNumber: $phoneNumber)';
  }

  // ===============================
  // NEW DRAMA HELPER METHODS (added)
  // ===============================
  
  // Drama favorites
  bool hasFavorited(String dramaId) => favoriteDramas.contains(dramaId);
  
  // Watch history (for episodes)
  bool hasWatched(String episodeId) => watchHistory.contains(episodeId);
  
  // Drama unlock status
  bool hasUnlocked(String dramaId) => unlockedDramas.contains(dramaId);
  
  // Drama progress (episode number)
  int getDramaProgress(String dramaId) => dramaProgress[dramaId] ?? 0;

  // Timestamp helper methods
  DateTime get lastSeenDateTime => DateTime.parse(lastSeen);
  DateTime get createdAtDateTime => DateTime.parse(createdAt);
  DateTime get updatedAtDateTime => DateTime.parse(updatedAt);
  
  // UPDATED: lastPostAt helper methods with null safety
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

  // ===============================
  // EXISTING DEBUG/VALIDATION METHODS (preserved)
  // ===============================
  Map<String, dynamic> toDebugMap() {
    return {
      ...toMap(),
      'debug_info': {
        'tags_length': tags.length,
        'tags_type': tags.runtimeType.toString(),
        'tags_formatted': _formatArrayForPostgreSQL(tags),
        'formatted_type': _formatArrayForPostgreSQL(tags).runtimeType.toString(),
        // Drama debug info
        'favoriteDramas_length': favoriteDramas.length,
        'watchHistory_length': watchHistory.length,
        'dramaProgress_length': dramaProgress.length,
        'unlockedDramas_length': unlockedDramas.length,
        // lastPostAt debug info
        'lastPostAt_value': lastPostAt,
        'hasPostedVideos': hasPostedVideos,
        'lastPostTimeAgo': lastPostTimeAgo,
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
    
    return errors;
  }

  bool get isValid => validate().isEmpty;
}
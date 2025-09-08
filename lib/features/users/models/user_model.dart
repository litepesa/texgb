// lib/features/users/models/user_model.dart
// FIXED: Resolved PostgreSQL array literal problem for tags field

class UserModel {
  final String uid;  // Using uid to match Go backend
  final String phoneNumber;
  final String name;
  final String bio;  // Changed from 'about' to 'bio'
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
  final List<String> likedVideos;  // Added for Go backend
  final String createdAt;  // Changed to String for RFC3339 format
  final String updatedAt;  // Added for Go backend
  final String lastSeen;   // Added for Go backend
  final bool isActive;
  final bool isFeatured;

  UserModel({
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
  });

  // Factory constructor for creating user from Go backend data
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? map['id'] ?? '',  // Support both for compatibility
      phoneNumber: map['phoneNumber'] ?? '',
      name: map['name'] ?? '',
      bio: map['bio'] ?? '',
      profileImage: map['profileImage'] ?? '',
      coverImage: map['coverImage'] ?? '',
      followers: map['followersCount'] ?? 0,  // Updated mapping
      following: map['followingCount'] ?? 0,  // Updated mapping
      videosCount: map['videosCount'] ?? 0,
      likesCount: map['likesCount'] ?? 0,
      isVerified: map['isVerified'] ?? false,
      tags: _parseStringArray(map['tags']),  // 🔧 FIXED: Safe array parsing
      followerUIDs: _parseStringArray(map['followerUIDs']),  // 🔧 FIXED: Safe array parsing
      followingUIDs: _parseStringArray(map['followingUIDs']),  // 🔧 FIXED: Safe array parsing
      likedVideos: _parseStringArray(map['likedVideos']),  // 🔧 FIXED: Safe array parsing
      createdAt: map['createdAt'] ?? '',
      updatedAt: map['updatedAt'] ?? '',
      lastSeen: map['lastSeen'] ?? '',
      isActive: map['isActive'] ?? true,
      isFeatured: map['isFeatured'] ?? false,
    );
  }

  // 🔧 FIXED: Helper method to safely parse string arrays from various formats
  static List<String> _parseStringArray(dynamic value) {
    if (value == null) return [];
    
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }
    
    if (value is String) {
      // Handle PostgreSQL array format like '{tag1,tag2}' or '[]'
      if (value.isEmpty || value == '{}' || value == '[]') return [];
      
      // Remove curly braces and split by comma
      String cleaned = value.replaceAll(RegExp(r'[{}"\[\]]'), '');
      if (cleaned.isEmpty) return [];
      
      return cleaned.split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    
    return [];
  }

  // Create method for new users (PHONE-ONLY)
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
    );
  }

  // 🔧 CRITICAL FIX: Updated toMap method to handle PostgreSQL array format correctly
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'coverImage': coverImage,
      'bio': bio,
      'userType': 'user', // Add this field that Go backend expects
      'followersCount': followers,
      'followingCount': following,
      'videosCount': videosCount,
      'likesCount': likesCount,
      'isVerified': isVerified,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'tags': _formatArrayForPostgreSQL(tags), // 🔧 FIXED: PostgreSQL-compatible array format
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastSeen': lastSeen,
      // REMOVED these fields that don't exist in Go backend:
      // 'followerUIDs': followerUIDs,
      // 'followingUIDs': followingUIDs, 
      // 'likedVideos': likedVideos,
    };
  }

  // 🔧 CRITICAL FIX: Format arrays for PostgreSQL compatibility
  static dynamic _formatArrayForPostgreSQL(List<String> array) {
    if (array.isEmpty) {
      // Return empty list instead of empty PostgreSQL array literal
      // Go backend will handle the conversion to PostgreSQL format
      return <String>[];
    }
    
    // For non-empty arrays, return as regular Dart list
    // Go backend StringSlice.Value() will convert to PostgreSQL format
    return array;
  }

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
    );
  }

  // Getter for backward compatibility
  String get id => uid;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;

  get lastPostAt => null;

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, phoneNumber: $phoneNumber)';
  }

  // 🔧 ADDITIONAL FIX: Helper methods for debugging array formatting
  Map<String, dynamic> toDebugMap() {
    return {
      ...toMap(),
      'debug_info': {
        'tags_length': tags.length,
        'tags_type': tags.runtimeType.toString(),
        'tags_formatted': _formatArrayForPostgreSQL(tags),
        'formatted_type': _formatArrayForPostgreSQL(tags).runtimeType.toString(),
      },
    };
  }

  // Helper to validate model before sending to backend
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
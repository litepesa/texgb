// lib/models/user_model.dart
import 'package:textgb/constants.dart';

// User types
enum UserType {
  viewer,
  admin;

  String get name {
    switch (this) {
      case UserType.viewer: return 'viewer';
      case UserType.admin: return 'admin';
    }
  }

  static UserType fromString(String value) {
    switch (value) {
      case 'admin': return UserType.admin;
      default: return UserType.viewer;
    }
  }
}

// Simple user preferences
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
      autoPlay: map['autoPlay'] ?? true,
      receiveNotifications: map['receiveNotifications'] ?? true,
      darkMode: map['darkMode'] ?? false,
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
  final String uid;
  final String name;
  final String email;
  final String phoneNumber;
  final String profileImage;
  final String fcmToken;
  final String bio;
  final String lastSeen;
  final String createdAt;
  final String updatedAt;
  
  // User type - viewer or admin
  final UserType userType;
  
  // Simple drama tracking for viewers
  final List<String> favoriteDramas;
  final List<String> watchHistory;
  final Map<String, int> dramaProgress;
  final List<String> unlockedDramas;
  
  // Wallet system
  final int coinsBalance;
  
  // User preferences
  final UserPreferences preferences;

  const UserModel({
    required this.uid,
    required this.name,
    this.email = '',
    required this.phoneNumber,
    this.profileImage = '',
    this.fcmToken = '',
    this.bio = '',
    required this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
    this.userType = UserType.viewer,
    this.favoriteDramas = const [],
    this.watchHistory = const [],
    this.dramaProgress = const {},
    this.unlockedDramas = const [],
    this.coinsBalance = 0,
    this.preferences = const UserPreferences(),
  });

  // Helper method to create timestamps in RFC3339 format
  static String _createTimestamp() {
    return DateTime.now().toUtc().toIso8601String();
  }

  // Helper method to parse timestamp (handles both milliseconds and ISO strings)
  static String _parseTimestamp(dynamic value) {
    if (value == null) return _createTimestamp();
    
    final String stringValue = value.toString();
    
    // If it's a number (milliseconds), convert it
    if (RegExp(r'^\d+$').hasMatch(stringValue)) {
      try {
        final int milliseconds = int.parse(stringValue);
        // Handle both seconds and milliseconds timestamps
        final DateTime dateTime = milliseconds > 9999999999 
            ? DateTime.fromMillisecondsSinceEpoch(milliseconds)
            : DateTime.fromMillisecondsSinceEpoch(milliseconds * 1000);
        return dateTime.toUtc().toIso8601String();
      } catch (e) {
        return _createTimestamp();
      }
    }
    
    // If it's already an ISO string, validate and return
    try {
      DateTime.parse(stringValue);
      return stringValue;
    } catch (e) {
      return _createTimestamp();
    }
  }

  // Factory constructor for creating new users
  factory UserModel.create({
    required String uid,
    required String name,
    String email = '',
    required String phoneNumber,
    String profileImage = '',
    String fcmToken = '',
    String bio = '',
    UserType userType = UserType.viewer,
  }) {
    final timestamp = _createTimestamp();
    
    return UserModel(
      uid: uid,
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      profileImage: profileImage,
      fcmToken: fcmToken,
      bio: bio.isEmpty ? 'New to WeiBao, excited to watch amazing dramas!' : bio,
      lastSeen: timestamp,
      createdAt: timestamp,
      updatedAt: timestamp,
      userType: userType,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map[Constants.uid]?.toString() ?? '',
      name: map[Constants.name]?.toString() ?? '',
      email: map[Constants.email]?.toString() ?? '',
      phoneNumber: map[Constants.phoneNumber]?.toString() ?? '',
      profileImage: map[Constants.profileImage]?.toString() ?? '',
      fcmToken: map[Constants.fcmToken]?.toString() ?? '',
      bio: map[Constants.bio]?.toString() ?? '',
      lastSeen: _parseTimestamp(map[Constants.lastSeen]),
      createdAt: _parseTimestamp(map[Constants.createdAt]),
      updatedAt: _parseTimestamp(map[Constants.updatedAt]),
      userType: UserType.fromString(map[Constants.userType]?.toString() ?? 'viewer'),
      favoriteDramas: List<String>.from(map[Constants.favoriteDramas] ?? []),
      watchHistory: List<String>.from(map[Constants.watchHistory] ?? []),
      dramaProgress: Map<String, int>.from(map[Constants.dramaProgress] ?? {}),
      unlockedDramas: List<String>.from(map[Constants.unlockedDramas] ?? []),
      coinsBalance: map[Constants.coinsBalance]?.toInt() ?? 0,
      preferences: UserPreferences.fromMap(
        map[Constants.preferences] ?? <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      Constants.uid: uid,
      Constants.name: name,
      Constants.email: email,
      Constants.phoneNumber: phoneNumber,
      Constants.profileImage: profileImage,
      Constants.fcmToken: fcmToken,
      Constants.bio: bio,
      Constants.lastSeen: lastSeen,
      Constants.createdAt: createdAt,
      Constants.updatedAt: updatedAt,
      Constants.userType: userType.name,
      Constants.favoriteDramas: favoriteDramas,
      Constants.watchHistory: watchHistory,
      Constants.dramaProgress: dramaProgress,
      Constants.unlockedDramas: unlockedDramas,
      Constants.coinsBalance: coinsBalance,
      Constants.preferences: preferences.toMap(),
    };
  }

  // Method to create a copy with updated timestamp
  UserModel updateTimestamp() {
    return copyWith(updatedAt: _createTimestamp());
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImage,
    String? fcmToken,
    String? bio,
    String? lastSeen,
    String? createdAt,
    String? updatedAt,
    UserType? userType,
    List<String>? favoriteDramas,
    List<String>? watchHistory,
    Map<String, int>? dramaProgress,
    List<String>? unlockedDramas,
    int? coinsBalance,
    UserPreferences? preferences,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      fcmToken: fcmToken ?? this.fcmToken,
      bio: bio ?? this.bio,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userType: userType ?? this.userType,
      favoriteDramas: favoriteDramas ?? List<String>.from(this.favoriteDramas),
      watchHistory: watchHistory ?? List<String>.from(this.watchHistory),
      dramaProgress: dramaProgress ?? Map<String, int>.from(this.dramaProgress),
      unlockedDramas: unlockedDramas ?? List<String>.from(this.unlockedDramas),
      coinsBalance: coinsBalance ?? this.coinsBalance,
      preferences: preferences ?? this.preferences,
    );
  }

  // Helper methods
  bool get isAdmin => userType == UserType.admin;
  bool get isViewer => userType == UserType.viewer;
  
  bool hasFavorited(String dramaId) => favoriteDramas.contains(dramaId);
  bool hasWatched(String episodeId) => watchHistory.contains(episodeId);
  bool hasUnlocked(String dramaId) => unlockedDramas.contains(dramaId);
  int getDramaProgress(String dramaId) => dramaProgress[dramaId] ?? 0;

  bool get hasCoins => coinsBalance > 0;
  bool canAfford(int cost) => coinsBalance >= cost;

  // Timestamp helper methods
  DateTime get lastSeenDateTime => DateTime.parse(lastSeen);
  DateTime get createdAtDateTime => DateTime.parse(createdAt);
  DateTime get updatedAtDateTime => DateTime.parse(updatedAt);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, type: ${userType.name}, coins: $coinsBalance)';
  }
}
import 'package:textgb/constants.dart';

class UserModel {
  String uid;
  String name;
  String phoneNumber;
  String image;
  String token;
  String aboutMe;
  String lastSeen;
  String createdAt;
  // Removed isOnline field
  List<String> contactsUIDs;  
  List<String> blockedUIDs;
  List<String> statusMutedUsers;

  UserModel({
    required this.uid,
    required this.name,
    required this.phoneNumber,
    required this.image,
    required this.token,
    required this.aboutMe,
    required this.lastSeen,
    required this.createdAt,
    // Removed isOnline parameter
    required this.contactsUIDs,
    required this.blockedUIDs,
    this.statusMutedUsers = const [],
  });

  // from map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map[Constants.uid] ?? '',
      name: map[Constants.name] ?? '',
      phoneNumber: map[Constants.phoneNumber] ?? '',
      image: map[Constants.image] ?? '',
      token: map[Constants.token] ?? '',
      aboutMe: map[Constants.aboutMe] ?? '',
      lastSeen: map[Constants.lastSeen] ?? '',
      createdAt: map[Constants.createdAt] ?? '',
      // Removed isOnline field
      contactsUIDs: List<String>.from(map[Constants.contactsUIDs] ?? []),
      blockedUIDs: List<String>.from(map[Constants.blockedUIDs] ?? []),
      statusMutedUsers: List<String>.from(map[Constants.statusMutedUsers] ?? []),
    );
  }

  // Add copyWith method to create a copy with some fields changed
  UserModel copyWith({
    String? uid,
    String? name,
    String? phoneNumber,
    String? image,
    String? token,
    String? aboutMe,
    String? lastSeen,
    String? createdAt,
    // Removed isOnline parameter
    List<String>? contactsUIDs,
    List<String>? blockedUIDs,
    List<String>? statusMutedUsers,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      image: image ?? this.image,
      token: token ?? this.token,
      aboutMe: aboutMe ?? this.aboutMe,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      // Removed isOnline field
      contactsUIDs: contactsUIDs ?? List<String>.from(this.contactsUIDs),
      blockedUIDs: blockedUIDs ?? List<String>.from(this.blockedUIDs),
      statusMutedUsers: statusMutedUsers ?? List<String>.from(this.statusMutedUsers),
    );
  }

  // to map
  Map<String, dynamic> toMap() {
    return {
      Constants.uid: uid,
      Constants.name: name,
      Constants.phoneNumber: phoneNumber,
      Constants.image: image,
      Constants.token: token,
      Constants.aboutMe: aboutMe,
      Constants.lastSeen: lastSeen,
      Constants.createdAt: createdAt,
      // Removed isOnline field
      Constants.contactsUIDs: contactsUIDs,
      Constants.blockedUIDs: blockedUIDs,
      Constants.statusMutedUsers: statusMutedUsers,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode {
    return uid.hashCode;
  }
}
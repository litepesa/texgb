// lib/models/user_model.dart
import 'package:textgb/constants.dart';

// Privacy settings enums
enum MessagePermissionLevel {
  everyone,
  contactsOnly,
  selectedContacts,
  nobody;

  String get name {
    switch (this) {
      case MessagePermissionLevel.everyone: return 'everyone';
      case MessagePermissionLevel.contactsOnly: return 'contactsOnly';
      case MessagePermissionLevel.selectedContacts: return 'selectedContacts';
      case MessagePermissionLevel.nobody: return 'nobody';
    }
  }

  static MessagePermissionLevel fromString(String value) {
    switch (value) {
      case 'contactsOnly': return MessagePermissionLevel.contactsOnly;
      case 'selectedContacts': return MessagePermissionLevel.selectedContacts;
      case 'nobody': return MessagePermissionLevel.nobody;
      default: return MessagePermissionLevel.everyone;
    }
  }

  String get displayName {
    switch (this) {
      case MessagePermissionLevel.everyone: return 'Everyone';
      case MessagePermissionLevel.contactsOnly: return 'My contacts';
      case MessagePermissionLevel.selectedContacts: return 'Selected contacts';
      case MessagePermissionLevel.nobody: return 'Nobody';
    }
  }
}

enum ReadReceiptVisibility {
  everyone,
  contactsOnly,
  nobody;

  String get name {
    switch (this) {
      case ReadReceiptVisibility.everyone: return 'everyone';
      case ReadReceiptVisibility.contactsOnly: return 'contactsOnly';
      case ReadReceiptVisibility.nobody: return 'nobody';
    }
  }

  static ReadReceiptVisibility fromString(String value) {
    switch (value) {
      case 'contactsOnly': return ReadReceiptVisibility.contactsOnly;
      case 'nobody': return ReadReceiptVisibility.nobody;
      default: return ReadReceiptVisibility.everyone;
    }
  }

  String get displayName {
    switch (this) {
      case ReadReceiptVisibility.everyone: return 'Everyone';
      case ReadReceiptVisibility.contactsOnly: return 'My contacts';
      case ReadReceiptVisibility.nobody: return 'Nobody';
    }
  }
}

enum LastSeenVisibility {
  everyone,
  contactsOnly,
  nobody;

  String get name {
    switch (this) {
      case LastSeenVisibility.everyone: return 'everyone';
      case LastSeenVisibility.contactsOnly: return 'contactsOnly';
      case LastSeenVisibility.nobody: return 'nobody';
    }
  }

  static LastSeenVisibility fromString(String value) {
    switch (value) {
      case 'contactsOnly': return LastSeenVisibility.contactsOnly;
      case 'nobody': return LastSeenVisibility.nobody;
      default: return LastSeenVisibility.everyone;
    }
  }

  String get displayName {
    switch (this) {
      case LastSeenVisibility.everyone: return 'Everyone';
      case LastSeenVisibility.contactsOnly: return 'My contacts';
      case LastSeenVisibility.nobody: return 'Nobody';
    }
  }
}

enum ProfilePhotoVisibility {
  everyone,
  contactsOnly,
  nobody;

  String get name {
    switch (this) {
      case ProfilePhotoVisibility.everyone: return 'everyone';
      case ProfilePhotoVisibility.contactsOnly: return 'contactsOnly';
      case ProfilePhotoVisibility.nobody: return 'nobody';
    }
  }

  static ProfilePhotoVisibility fromString(String value) {
    switch (value) {
      case 'contactsOnly': return ProfilePhotoVisibility.contactsOnly;
      case 'nobody': return ProfilePhotoVisibility.nobody;
      default: return ProfilePhotoVisibility.everyone;
    }
  }

  String get displayName {
    switch (this) {
      case ProfilePhotoVisibility.everyone: return 'Everyone';
      case ProfilePhotoVisibility.contactsOnly: return 'My contacts';
      case ProfilePhotoVisibility.nobody: return 'Nobody';
    }
  }
}

// Privacy settings class
class UserPrivacySettings {
  final MessagePermissionLevel messagePermission;
  final List<String> allowedContactsList;
  final ReadReceiptVisibility readReceiptVisibility;
  final LastSeenVisibility lastSeenVisibility;
  final ProfilePhotoVisibility profilePhotoVisibility;
  final bool allowGroupInvites;
  final bool allowChannelInvites;
  final bool allowForwarding;
  final bool allowCallsFromContacts;
  final List<String> blockedFromCalls;

  const UserPrivacySettings({
    this.messagePermission = MessagePermissionLevel.everyone,
    this.allowedContactsList = const [],
    this.readReceiptVisibility = ReadReceiptVisibility.everyone,
    this.lastSeenVisibility = LastSeenVisibility.everyone,
    this.profilePhotoVisibility = ProfilePhotoVisibility.everyone,
    this.allowGroupInvites = true,
    this.allowChannelInvites = true,
    this.allowForwarding = true,
    this.allowCallsFromContacts = true,
    this.blockedFromCalls = const [],
  });

  factory UserPrivacySettings.fromMap(Map<String, dynamic> map) {
    return UserPrivacySettings(
      messagePermission: MessagePermissionLevel.fromString(
        map['messagePermission'] ?? 'everyone',
      ),
      allowedContactsList: List<String>.from(map['allowedContactsList'] ?? []),
      readReceiptVisibility: ReadReceiptVisibility.fromString(
        map['readReceiptVisibility'] ?? 'everyone',
      ),
      lastSeenVisibility: LastSeenVisibility.fromString(
        map['lastSeenVisibility'] ?? 'everyone',
      ),
      profilePhotoVisibility: ProfilePhotoVisibility.fromString(
        map['profilePhotoVisibility'] ?? 'everyone',
      ),
      allowGroupInvites: map['allowGroupInvites'] ?? true,
      allowChannelInvites: map['allowChannelInvites'] ?? true,
      allowForwarding: map['allowForwarding'] ?? true,
      allowCallsFromContacts: map['allowCallsFromContacts'] ?? true,
      blockedFromCalls: List<String>.from(map['blockedFromCalls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messagePermission': messagePermission.name,
      'allowedContactsList': allowedContactsList,
      'readReceiptVisibility': readReceiptVisibility.name,
      'lastSeenVisibility': lastSeenVisibility.name,
      'profilePhotoVisibility': profilePhotoVisibility.name,
      'allowGroupInvites': allowGroupInvites,
      'allowChannelInvites': allowChannelInvites,
      'allowForwarding': allowForwarding,
      'allowCallsFromContacts': allowCallsFromContacts,
      'blockedFromCalls': blockedFromCalls,
    };
  }

  UserPrivacySettings copyWith({
    MessagePermissionLevel? messagePermission,
    List<String>? allowedContactsList,
    ReadReceiptVisibility? readReceiptVisibility,
    LastSeenVisibility? lastSeenVisibility,
    ProfilePhotoVisibility? profilePhotoVisibility,
    bool? allowGroupInvites,
    bool? allowChannelInvites,
    bool? allowForwarding,
    bool? allowCallsFromContacts,
    List<String>? blockedFromCalls,
  }) {
    return UserPrivacySettings(
      messagePermission: messagePermission ?? this.messagePermission,
      allowedContactsList: allowedContactsList ?? this.allowedContactsList,
      readReceiptVisibility: readReceiptVisibility ?? this.readReceiptVisibility,
      lastSeenVisibility: lastSeenVisibility ?? this.lastSeenVisibility,
      profilePhotoVisibility: profilePhotoVisibility ?? this.profilePhotoVisibility,
      allowGroupInvites: allowGroupInvites ?? this.allowGroupInvites,
      allowChannelInvites: allowChannelInvites ?? this.allowChannelInvites,
      allowForwarding: allowForwarding ?? this.allowForwarding,
      allowCallsFromContacts: allowCallsFromContacts ?? this.allowCallsFromContacts,
      blockedFromCalls: blockedFromCalls ?? this.blockedFromCalls,
    );
  }

  // Helper methods for permission checking
  bool canReceiveMessagesFrom(String userId, bool isContact) {
    switch (messagePermission) {
      case MessagePermissionLevel.everyone:
        return true;
      case MessagePermissionLevel.contactsOnly:
        return isContact;
      case MessagePermissionLevel.selectedContacts:
        return allowedContactsList.contains(userId);
      case MessagePermissionLevel.nobody:
        return false;
    }
  }

  bool canSeeReadReceipts(String userId, bool isContact) {
    switch (readReceiptVisibility) {
      case ReadReceiptVisibility.everyone:
        return true;
      case ReadReceiptVisibility.contactsOnly:
        return isContact;
      case ReadReceiptVisibility.nobody:
        return false;
    }
  }

  bool canSeeLastSeen(String userId, bool isContact) {
    switch (lastSeenVisibility) {
      case LastSeenVisibility.everyone:
        return true;
      case LastSeenVisibility.contactsOnly:
        return isContact;
      case LastSeenVisibility.nobody:
        return false;
    }
  }

  bool canSeeProfilePhoto(String userId, bool isContact) {
    switch (profilePhotoVisibility) {
      case ProfilePhotoVisibility.everyone:
        return true;
      case ProfilePhotoVisibility.contactsOnly:
        return isContact;
      case ProfilePhotoVisibility.nobody:
        return false;
    }
  }
}

class UserModel {
  final String uid;
  final String name;
  final String phoneNumber;
  final String image;
  final String token;
  final String aboutMe;
  final String lastSeen;
  final String createdAt;
  final List<String> contactsUIDs;
  final List<String> blockedUIDs;
  final List<String> followedChannels;
  final int followingCount;
  final bool isAccountActivated;
  final String? paymentTransactionId;
  final String? paymentDate;
  final double? amountPaid;
  final UserPrivacySettings privacySettings;

  const UserModel({
    required this.uid,
    required this.name,
    required this.phoneNumber,
    required this.image,
    required this.token,
    required this.aboutMe,
    required this.lastSeen,
    required this.createdAt,
    required this.contactsUIDs,
    required this.blockedUIDs,
    this.followedChannels = const [],
    this.followingCount = 0,
    this.isAccountActivated = false,
    this.paymentTransactionId,
    this.paymentDate,
    this.amountPaid,
    this.privacySettings = const UserPrivacySettings(),
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map[Constants.uid]?.toString() ?? '',
      name: map[Constants.name]?.toString() ?? '',
      phoneNumber: map[Constants.phoneNumber]?.toString() ?? '',
      image: map[Constants.image]?.toString() ?? '',
      token: map[Constants.token]?.toString() ?? '',
      aboutMe: map[Constants.aboutMe]?.toString() ?? '',
      lastSeen: map[Constants.lastSeen]?.toString() ?? '',
      createdAt: map[Constants.createdAt]?.toString() ?? '',
      contactsUIDs: List<String>.from(map[Constants.contactsUIDs] ?? []),
      blockedUIDs: List<String>.from(map[Constants.blockedUIDs] ?? []),
      followedChannels: List<String>.from(map['followedChannels'] ?? []),
      followingCount: map['followingCount']?.toInt() ?? 0,
      privacySettings: UserPrivacySettings.fromMap(
        map['privacySettings'] ?? <String, dynamic>{},
      ),
    );
  }

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
      Constants.contactsUIDs: contactsUIDs,
      Constants.blockedUIDs: blockedUIDs,
      'followedChannels': followedChannels,
      'followingCount': followingCount,
      'privacySettings': privacySettings.toMap(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? phoneNumber,
    String? image,
    String? token,
    String? aboutMe,
    String? lastSeen,
    String? createdAt,
    List<String>? contactsUIDs,
    List<String>? blockedUIDs,
    List<String>? followedChannels,
    int? followingCount,
    bool? isAccountActivated,
    String? paymentTransactionId,
    String? paymentDate,
    double? amountPaid,
    UserPrivacySettings? privacySettings,
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
      contactsUIDs: contactsUIDs ?? List<String>.from(this.contactsUIDs),
      blockedUIDs: blockedUIDs ?? List<String>.from(this.blockedUIDs),
      followedChannels: followedChannels ?? List<String>.from(this.followedChannels),
      followingCount: followingCount ?? this.followingCount,
      isAccountActivated: isAccountActivated ?? this.isAccountActivated,
      paymentTransactionId: paymentTransactionId ?? this.paymentTransactionId,
      paymentDate: paymentDate ?? this.paymentDate,
      amountPaid: amountPaid ?? this.amountPaid,
      privacySettings: privacySettings ?? this.privacySettings,
    );
  }

  // Helper methods for privacy checking
  bool isContact(String userId) {
    return contactsUIDs.contains(userId);
  }

  bool isBlocked(String userId) {
    return blockedUIDs.contains(userId);
  }

  bool canReceiveMessagesFrom(String userId) {
    if (isBlocked(userId)) return false;
    return privacySettings.canReceiveMessagesFrom(userId, isContact(userId));
  }

  bool canSeeReadReceiptsTo(String userId) {
    return privacySettings.canSeeReadReceipts(userId, isContact(userId));
  }

  bool canSeeLastSeenTo(String userId) {
    return privacySettings.canSeeLastSeen(userId, isContact(userId));
  }

  bool canSeeProfilePhotoTo(String userId) {
    return privacySettings.canSeeProfilePhoto(userId, isContact(userId));
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
    return 'UserModel(uid: $uid, name: $name, phoneNumber: $phoneNumber)';
  }
}
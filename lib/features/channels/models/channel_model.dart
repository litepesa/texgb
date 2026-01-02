// lib/features/channels/models/channel_model.dart

/// Channel type enum
enum ChannelType {
  public,
  private,
  premium,
}

/// Channel model with all properties
class ChannelModel {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String? avatarUrl;
  final ChannelType type;
  final bool isVerified;
  final int subscriberCount;
  final int postCount;
  final int unreadCount; // Unread posts for current user

  // Premium channel settings
  final int? subscriptionPriceCoins; // Monthly subscription price for premium channels

  // Metadata
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // User's relationship to this channel
  final bool? isSubscribed;
  final bool? isAdmin;
  final bool? isOwner;
  final bool? hasNotificationsEnabled;

  const ChannelModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    this.avatarUrl,
    this.type = ChannelType.public,
    this.isVerified = false,
    this.subscriberCount = 0,
    this.postCount = 0,
    this.unreadCount = 0,
    this.subscriptionPriceCoins,
    this.createdAt,
    this.updatedAt,
    this.isSubscribed,
    this.isAdmin,
    this.isOwner,
    this.hasNotificationsEnabled,
  });

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String? ?? json['owner_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
      type: _channelTypeFromString(json['type'] as String?),
      isVerified: json['isVerified'] as bool? ?? json['is_verified'] as bool? ?? false,
      subscriberCount: json['subscriberCount'] as int? ?? json['subscriber_count'] as int? ?? 0,
      postCount: json['postCount'] as int? ?? json['post_count'] as int? ?? 0,
      unreadCount: json['unreadCount'] as int? ?? json['unread_count'] as int? ?? 0,
      subscriptionPriceCoins: json['subscriptionPriceCoins'] as int? ?? json['subscription_price_coins'] as int?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) :
                 (json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) :
                 (json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null),
      isSubscribed: json['isSubscribed'] as bool? ?? json['is_subscribed'] as bool?,
      isAdmin: json['isAdmin'] as bool? ?? json['is_admin'] as bool?,
      isOwner: json['isOwner'] as bool? ?? json['is_owner'] as bool?,
      hasNotificationsEnabled: json['hasNotificationsEnabled'] as bool? ?? json['has_notifications_enabled'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'avatarUrl': avatarUrl,
      'type': _channelTypeToString(type),
      'isVerified': isVerified,
      'subscriberCount': subscriberCount,
      'postCount': postCount,
      'unreadCount': unreadCount,
      'subscriptionPriceCoins': subscriptionPriceCoins,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isSubscribed': isSubscribed,
      'isAdmin': isAdmin,
      'isOwner': isOwner,
      'hasNotificationsEnabled': hasNotificationsEnabled,
    };
  }

  ChannelModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    String? avatarUrl,
    ChannelType? type,
    bool? isVerified,
    int? subscriberCount,
    int? postCount,
    int? unreadCount,
    int? subscriptionPriceCoins,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSubscribed,
    bool? isAdmin,
    bool? isOwner,
    bool? hasNotificationsEnabled,
  }) {
    return ChannelModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      type: type ?? this.type,
      isVerified: isVerified ?? this.isVerified,
      subscriberCount: subscriberCount ?? this.subscriberCount,
      postCount: postCount ?? this.postCount,
      unreadCount: unreadCount ?? this.unreadCount,
      subscriptionPriceCoins: subscriptionPriceCoins ?? this.subscriptionPriceCoins,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      isAdmin: isAdmin ?? this.isAdmin,
      isOwner: isOwner ?? this.isOwner,
      hasNotificationsEnabled: hasNotificationsEnabled ?? this.hasNotificationsEnabled,
    );
  }
}

/// Channel member model (for admins/moderators list)
class ChannelMember {
  final String id;
  final String channelId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final MemberRole role;
  final DateTime? addedAt;
  final DateTime? createdAt;
  final String? addedBy;

  const ChannelMember({
    required this.id,
    required this.channelId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    this.role = MemberRole.subscriber,
    this.addedAt,
    this.createdAt,
    this.addedBy,
  });

  factory ChannelMember.fromJson(Map<String, dynamic> json) {
    return ChannelMember(
      id: json['id'] as String,
      channelId: json['channelId'] as String? ?? json['channel_id'] as String,
      userId: json['userId'] as String? ?? json['user_id'] as String,
      userName: json['userName'] as String? ?? json['user_name'] as String,
      userAvatarUrl: json['userAvatarUrl'] as String? ?? json['user_avatar_url'] as String?,
      role: _memberRoleFromString(json['role'] as String?),
      addedAt: json['addedAt'] != null ? DateTime.parse(json['addedAt'] as String) :
               (json['added_at'] != null ? DateTime.parse(json['added_at'] as String) : null),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) :
                 (json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null),
      addedBy: json['addedBy'] as String? ?? json['added_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channelId': channelId,
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'role': _memberRoleToString(role),
      'addedAt': addedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'addedBy': addedBy,
    };
  }
}

/// Member role enum (simplified: owner, admin, subscriber only)
enum MemberRole {
  owner,
  admin,
  subscriber,
}

/// Extension for role permissions
extension MemberRoleExtension on MemberRole {
  bool get canPost => this == MemberRole.owner || this == MemberRole.admin;

  bool get canDeletePosts => this == MemberRole.owner || this == MemberRole.admin;

  bool get canDeleteComments => this == MemberRole.owner || this == MemberRole.admin;

  bool get canBanUsers => this == MemberRole.owner || this == MemberRole.admin;

  bool get canManageMembers => this == MemberRole.owner || this == MemberRole.admin;

  bool get canEditChannel => this == MemberRole.owner || this == MemberRole.admin;

  bool get canDeleteChannel => this == MemberRole.owner;

  String get displayName {
    switch (this) {
      case MemberRole.owner:
        return 'Owner';
      case MemberRole.admin:
        return 'Admin';
      case MemberRole.subscriber:
        return 'Subscriber';
    }
  }
}

// Helper functions for enum conversion
ChannelType _channelTypeFromString(String? value) {
  switch (value) {
    case 'public':
      return ChannelType.public;
    case 'private':
      return ChannelType.private;
    case 'premium':
      return ChannelType.premium;
    default:
      return ChannelType.public;
  }
}

String _channelTypeToString(ChannelType type) {
  switch (type) {
    case ChannelType.public:
      return 'public';
    case ChannelType.private:
      return 'private';
    case ChannelType.premium:
      return 'premium';
  }
}

MemberRole _memberRoleFromString(String? value) {
  switch (value) {
    case 'owner':
      return MemberRole.owner;
    case 'admin':
      return MemberRole.admin;
    case 'subscriber':
      return MemberRole.subscriber;
    default:
      return MemberRole.subscriber;
  }
}

String _memberRoleToString(MemberRole role) {
  switch (role) {
    case MemberRole.owner:
      return 'owner';
    case MemberRole.admin:
      return 'admin';
    case MemberRole.subscriber:
      return 'subscriber';
  }
}

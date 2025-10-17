// lib/features/groups/models/group_model.dart

enum GroupPrivacy {
  public('public'),     // Anyone can join
  private('private');   // Invite only

  const GroupPrivacy(this.value);
  final String value;

  static GroupPrivacy fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'private':
        return GroupPrivacy.private;
      case 'public':
      default:
        return GroupPrivacy.public;
    }
  }
}

enum MemberRole {
  admin('admin'),       // Can manage group, add/remove members, delete messages
  moderator('moderator'), // Can delete messages, mute members
  member('member');     // Regular member

  const MemberRole(this.value);
  final String value;

  static MemberRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'admin':
        return MemberRole.admin;
      case 'moderator':
        return MemberRole.moderator;
      case 'member':
      default:
        return MemberRole.member;
    }
  }

  bool get canManageGroup => this == MemberRole.admin;
  bool get canModerate => this == MemberRole.admin || this == MemberRole.moderator;
}

class GroupMember {
  final String userId;
  final String userName;
  final String userImage;
  final MemberRole role;
  final String joinedAt;
  final bool isMuted; // Muted by admins

  const GroupMember({
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.role,
    required this.joinedAt,
    this.isMuted = false,
  });

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      userId: map['userId'] ?? map['user_id'] ?? '',
      userName: map['userName'] ?? map['user_name'] ?? '',
      userImage: map['userImage'] ?? map['user_image'] ?? '',
      role: MemberRole.fromString(map['role']),
      joinedAt: map['joinedAt'] ?? map['joined_at'] ?? '',
      isMuted: map['isMuted'] ?? map['is_muted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'role': role.value,
      'joinedAt': joinedAt,
      'isMuted': isMuted,
    };
  }

  GroupMember copyWith({
    String? userId,
    String? userName,
    String? userImage,
    MemberRole? role,
    String? joinedAt,
    bool? isMuted,
  }) {
    return GroupMember(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  DateTime get joinedAtDateTime => DateTime.parse(joinedAt);

  bool get isAdmin => role == MemberRole.admin;
  bool get isModerator => role == MemberRole.moderator;
  bool get isMemberOnly => role == MemberRole.member;
  bool get canManage => role.canManageGroup;
  bool get canModerate => role.canModerate;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupMember && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String groupImage;
  final String coverImage;
  
  // Group settings
  final GroupPrivacy privacy;
  final int maxMembers; // Default 1024 (WhatsApp limit)
  final bool allowMemberPosts; // If false, only admins/moderators can post
  final bool requireApproval; // For public groups, require admin approval to join
  
  // Creator info
  final String creatorId;
  final String creatorName;
  
  // Members
  final List<GroupMember> members;
  final List<String> memberIds; // Quick lookup
  final List<String> adminIds; // Quick lookup for admins
  final List<String> moderatorIds; // Quick lookup for moderators
  
  // Pending requests (for approval-required groups)
  final List<String> pendingRequestIds;
  
  // Statistics
  final int membersCount;
  final int postsCount;
  final int todayPostsCount;
  
  // Group status
  final bool isActive;
  final bool isFeatured;
  final bool isVerified;
  
  // Timestamps
  final String createdAt;
  final String updatedAt;
  final String? lastActivityAt;

  const GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.groupImage,
    required this.coverImage,
    required this.privacy,
    this.maxMembers = 1024, // WhatsApp group limit
    this.allowMemberPosts = true,
    this.requireApproval = false,
    required this.creatorId,
    required this.creatorName,
    required this.members,
    required this.memberIds,
    required this.adminIds,
    required this.moderatorIds,
    this.pendingRequestIds = const [],
    required this.membersCount,
    required this.postsCount,
    this.todayPostsCount = 0,
    this.isActive = true,
    this.isFeatured = false,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastActivityAt,
  });

  factory GroupModel.fromMap(Map<String, dynamic> map, String id) {
    final membersList = _parseMembersList(map['members']);
    
    return GroupModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      groupImage: map['groupImage'] ?? map['group_image'] ?? '',
      coverImage: map['coverImage'] ?? map['cover_image'] ?? '',
      privacy: GroupPrivacy.fromString(map['privacy']),
      maxMembers: map['maxMembers'] ?? map['max_members'] ?? 1024, // WhatsApp limit
      allowMemberPosts: map['allowMemberPosts'] ?? map['allow_member_posts'] ?? true,
      requireApproval: map['requireApproval'] ?? map['require_approval'] ?? false,
      creatorId: map['creatorId'] ?? map['creator_id'] ?? '',
      creatorName: map['creatorName'] ?? map['creator_name'] ?? '',
      members: membersList,
      memberIds: _extractMemberIds(membersList),
      adminIds: _extractAdminIds(membersList),
      moderatorIds: _extractModeratorIds(membersList),
      pendingRequestIds: _parseStringList(map['pendingRequestIds'] ?? map['pending_request_ids']),
      membersCount: map['membersCount'] ?? map['members_count'] ?? membersList.length,
      postsCount: map['postsCount'] ?? map['posts_count'] ?? 0,
      todayPostsCount: map['todayPostsCount'] ?? map['today_posts_count'] ?? 0,
      isActive: map['isActive'] ?? map['is_active'] ?? true,
      isFeatured: map['isFeatured'] ?? map['is_featured'] ?? false,
      isVerified: map['isVerified'] ?? map['is_verified'] ?? false,
      createdAt: map['createdAt'] ?? map['created_at'] ?? '',
      updatedAt: map['updatedAt'] ?? map['updated_at'] ?? '',
      lastActivityAt: map['lastActivityAt'] ?? map['last_activity_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'groupImage': groupImage,
      'coverImage': coverImage,
      'privacy': privacy.value,
      'maxMembers': maxMembers,
      'allowMemberPosts': allowMemberPosts,
      'requireApproval': requireApproval,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'members': members.map((m) => m.toMap()).toList(),
      'memberIds': memberIds,
      'adminIds': adminIds,
      'moderatorIds': moderatorIds,
      'pendingRequestIds': pendingRequestIds,
      'membersCount': membersCount,
      'postsCount': postsCount,
      'todayPostsCount': todayPostsCount,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'isVerified': isVerified,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastActivityAt': lastActivityAt,
    };
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? groupImage,
    String? coverImage,
    GroupPrivacy? privacy,
    int? maxMembers,
    bool? allowMemberPosts,
    bool? requireApproval,
    String? creatorId,
    String? creatorName,
    List<GroupMember>? members,
    List<String>? memberIds,
    List<String>? adminIds,
    List<String>? moderatorIds,
    List<String>? pendingRequestIds,
    int? membersCount,
    int? postsCount,
    int? todayPostsCount,
    bool? isActive,
    bool? isFeatured,
    bool? isVerified,
    String? createdAt,
    String? updatedAt,
    String? lastActivityAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      groupImage: groupImage ?? this.groupImage,
      coverImage: coverImage ?? this.coverImage,
      privacy: privacy ?? this.privacy,
      maxMembers: maxMembers ?? this.maxMembers,
      allowMemberPosts: allowMemberPosts ?? this.allowMemberPosts,
      requireApproval: requireApproval ?? this.requireApproval,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      members: members ?? this.members,
      memberIds: memberIds ?? this.memberIds,
      adminIds: adminIds ?? this.adminIds,
      moderatorIds: moderatorIds ?? this.moderatorIds,
      pendingRequestIds: pendingRequestIds ?? this.pendingRequestIds,
      membersCount: membersCount ?? this.membersCount,
      postsCount: postsCount ?? this.postsCount,
      todayPostsCount: todayPostsCount ?? this.todayPostsCount,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
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

  static List<GroupMember> _parseMembersList(dynamic value) {
    if (value == null) return [];
    
    if (value is List) {
      return value.map((m) {
        if (m is Map<String, dynamic>) {
          return GroupMember.fromMap(m);
        }
        return null;
      }).whereType<GroupMember>().toList();
    }
    
    return [];
  }

  static List<String> _extractMemberIds(List<GroupMember> members) {
    return members.map((m) => m.userId).toList();
  }

  static List<String> _extractAdminIds(List<GroupMember> members) {
    return members.where((m) => m.isAdmin).map((m) => m.userId).toList();
  }

  static List<String> _extractModeratorIds(List<GroupMember> members) {
    return members.where((m) => m.isModerator).map((m) => m.userId).toList();
  }

  // Timestamp helpers
  DateTime get createdAtDateTime => DateTime.parse(createdAt);
  DateTime get updatedAtDateTime => DateTime.parse(updatedAt);
  DateTime? get lastActivityAtDateTime {
    if (lastActivityAt == null || lastActivityAt!.isEmpty) return null;
    try {
      return DateTime.parse(lastActivityAt!);
    } catch (e) {
      return null;
    }
  }

  // Privacy helpers
  bool get isPublic => privacy == GroupPrivacy.public;
  bool get isPrivate => privacy == GroupPrivacy.private;

  // Member helpers
  bool get hasMaxMembers => maxMembers > 0;
  bool get isAtMaxCapacity => membersCount >= maxMembers; // 1024 member limit
  bool get canAcceptMoreMembers => membersCount < maxMembers;
  
  bool isMember(String userId) {
    return memberIds.contains(userId);
  }

  bool isAdmin(String userId) {
    return adminIds.contains(userId);
  }

  bool isModerator(String userId) {
    return moderatorIds.contains(userId);
  }

  bool canManageGroup(String userId) {
    return isAdmin(userId);
  }

  bool canModerate(String userId) {
    return isAdmin(userId) || isModerator(userId);
  }

  bool canPost(String userId) {
    if (!isMember(userId)) return false;
    if (allowMemberPosts) return true;
    return canModerate(userId);
  }

  GroupMember? getMember(String userId) {
    try {
      return members.firstWhere((m) => m.userId == userId);
    } catch (e) {
      return null;
    }
  }

  MemberRole getMemberRole(String userId) {
    final member = getMember(userId);
    return member?.role ?? MemberRole.member;
  }

  bool isMemberMuted(String userId) {
    final member = getMember(userId);
    return member?.isMuted ?? false;
  }

  // Pending requests helpers
  bool get hasPendingRequests => pendingRequestIds.isNotEmpty;
  int get pendingRequestsCount => pendingRequestIds.length;
  
  bool hasPendingRequest(String userId) {
    return pendingRequestIds.contains(userId);
  }

  // Activity helpers
  String get lastActivityText {
    final activity = lastActivityAtDateTime;
    if (activity == null) return 'No recent activity';

    final now = DateTime.now();
    final difference = now.difference(activity);

    if (difference.inMinutes < 1) {
      return 'Active just now';
    } else if (difference.inMinutes < 60) {
      return 'Active ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Active ${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Active yesterday';
    } else if (difference.inDays < 7) {
      return 'Active ${difference.inDays}d ago';
    } else {
      return 'Active long ago';
    }
  }

  // Statistics helpers
  String get membersCountText {
    if (membersCount < 1000) return '$membersCount';
    if (membersCount < 1000000) return '${(membersCount / 1000).toStringAsFixed(1)}K';
    return '${(membersCount / 1000000).toStringAsFixed(1)}M';
  }

  String get postsCountText {
    if (postsCount < 1000) return '$postsCount';
    if (postsCount < 1000000) return '${(postsCount / 1000).toStringAsFixed(1)}K';
    return '${(postsCount / 1000000).toStringAsFixed(1)}M';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GroupModel(id: $id, name: $name, members: $membersCount, privacy: ${privacy.value})';
  }
}
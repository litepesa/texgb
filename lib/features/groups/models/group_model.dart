// lib/features/groups/models/group_model.dart
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';

class GroupModel {
  final String groupId;
  final String groupName;
  final String groupDescription;
  final String groupImage;
  final String creatorUID;
  final bool isPrivate;
  final bool editSettings;
  final bool approveMembers;
  final bool lockMessages;
  final bool requestToJoin;
  final List<String> membersUIDs;
  final List<String> adminsUIDs;
  final List<String> awaitingApprovalUIDs;
  final String lastMessage;
  final String lastMessageSender;
  final String lastMessageTime;
  final int unreadCount;
  final Map<String, int> unreadCountByUser;
  final String createdAt;

  GroupModel({
    required this.groupId,
    required this.groupName,
    required this.groupDescription,
    required this.groupImage,
    required this.creatorUID,
    required this.isPrivate,
    required this.editSettings,
    required this.approveMembers,
    required this.lockMessages,
    required this.requestToJoin,
    required this.membersUIDs,
    required this.adminsUIDs,
    required this.awaitingApprovalUIDs,
    this.lastMessage = '',
    this.lastMessageSender = '',
    this.lastMessageTime = '',
    this.unreadCount = 0,
    Map<String, int>? unreadCountByUser,
    required this.createdAt,
  }) : this.unreadCountByUser = unreadCountByUser ?? {};

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    try {
      return GroupModel(
        groupId: map[Constants.groupId]?.toString() ?? '',
        groupName: map[Constants.groupName]?.toString() ?? '',
        groupDescription: map[Constants.groupDescription]?.toString() ?? '',
        groupImage: map[Constants.groupImage]?.toString() ?? '',
        creatorUID: map[Constants.creatorUID]?.toString() ?? '',
        isPrivate: map[Constants.isPrivate] ?? false,
        editSettings: map[Constants.editSettings] ?? false,
        approveMembers: map[Constants.approveMembers] ?? false,
        lockMessages: map[Constants.lockMessages] ?? false,
        requestToJoin: map[Constants.requestToJoin] ?? false,
        // Fixed list type conversion
        membersUIDs: (map[Constants.membersUIDs] as List?)
            ?.map((item) => item.toString())
            .toList()
            .cast<String>() ?? [],
        adminsUIDs: (map[Constants.adminsUIDs] as List?)
            ?.map((item) => item.toString())
            .toList()
            .cast<String>() ?? [],
        awaitingApprovalUIDs: (map[Constants.awaitingApprovalUIDs] as List?)
            ?.map((item) => item.toString())
            .toList()
            .cast<String>() ?? [],
        lastMessage: map[Constants.lastMessage]?.toString() ?? '',
        lastMessageSender: map['lastMessageSender']?.toString() ?? '',
        lastMessageTime: map[Constants.timeSent]?.toString() ?? '',
        unreadCount: map['unreadCount'] is int ? map['unreadCount'] : 0,
        unreadCountByUser: map['unreadCountByUser'] != null
            ? Map<String, int>.from(
                (map['unreadCountByUser'] as Map).map(
                  (key, value) => MapEntry(
                    key.toString(),
                    value is int ? value : 0,
                  ),
                ),
              )
            : {},
        createdAt: map[Constants.createdAt]?.toString() ?? '',
      );
    } catch (e, stackTrace) {
      print('Error parsing GroupModel: $e');
      print('Map data: $map');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      Constants.groupId: groupId,
      Constants.groupName: groupName,
      Constants.groupDescription: groupDescription,
      Constants.groupImage: groupImage,
      Constants.creatorUID: creatorUID,
      Constants.isPrivate: isPrivate,
      Constants.editSettings: editSettings,
      Constants.approveMembers: approveMembers,
      Constants.lockMessages: lockMessages,
      Constants.requestToJoin: requestToJoin,
      Constants.membersUIDs: membersUIDs,
      Constants.adminsUIDs: adminsUIDs,
      Constants.awaitingApprovalUIDs: awaitingApprovalUIDs,
      Constants.lastMessage: lastMessage,
      'lastMessageSender': lastMessageSender,
      Constants.timeSent: lastMessageTime,
      'unreadCount': unreadCount,
      'unreadCountByUser': unreadCountByUser,
      Constants.createdAt: createdAt,
    };
  }

  GroupModel copyWith({
    String? groupId,
    String? groupName,
    String? groupDescription,
    String? groupImage,
    String? creatorUID,
    bool? isPrivate,
    bool? editSettings,
    bool? approveMembers,
    bool? lockMessages,
    bool? requestToJoin,
    List<String>? membersUIDs,
    List<String>? adminsUIDs,
    List<String>? awaitingApprovalUIDs,
    String? lastMessage,
    String? lastMessageSender,
    String? lastMessageTime,
    int? unreadCount,
    Map<String, int>? unreadCountByUser,
    String? createdAt,
  }) {
    return GroupModel(
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      groupDescription: groupDescription ?? this.groupDescription,
      groupImage: groupImage ?? this.groupImage,
      creatorUID: creatorUID ?? this.creatorUID,
      isPrivate: isPrivate ?? this.isPrivate,
      editSettings: editSettings ?? this.editSettings,
      approveMembers: approveMembers ?? this.approveMembers,
      lockMessages: lockMessages ?? this.lockMessages,
      requestToJoin: requestToJoin ?? this.requestToJoin,
      membersUIDs: membersUIDs ?? List.from(this.membersUIDs),
      adminsUIDs: adminsUIDs ?? List.from(this.adminsUIDs),
      awaitingApprovalUIDs: awaitingApprovalUIDs ?? List.from(this.awaitingApprovalUIDs),
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      unreadCountByUser: unreadCountByUser ?? Map.from(this.unreadCountByUser),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper method to check if user is a member
  bool isMember(String uid) {
    return membersUIDs.contains(uid);
  }

  // Helper method to check if user is an admin
  bool isAdmin(String uid) {
    return adminsUIDs.contains(uid);
  }

  // Helper method to check if user is the creator
  bool isCreator(String uid) {
    return creatorUID == uid;
  }

  // Helper method to check if user is awaiting approval
  bool isAwaitingApproval(String uid) {
    return awaitingApprovalUIDs.contains(uid);
  }

  // Helper method to get unread count for a specific user
  int getUnreadCountForUser(String userId) {
    return unreadCountByUser[userId] ?? 0;
  }

  // Helper to get group type
  GroupType getGroupType() {
    return isPrivate ? GroupType.private : GroupType.public;
  }
}
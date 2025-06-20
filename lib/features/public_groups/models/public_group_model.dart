// lib/features/public_groups/models/public_group_model.dart
import 'package:textgb/constants.dart';

class PublicGroupModel {
  final String groupId;
  final String groupName;
  final String groupDescription;
  final String groupImage;
  final String creatorUID;
  final bool isVerified;
  final List<String> subscribersUIDs;
  final List<String> adminUIDs;
  final int subscribersCount;
  final String lastPostAt;
  final String createdAt;
  final Map<String, dynamic> groupSettings;

  PublicGroupModel({
    required this.groupId,
    required this.groupName,
    required this.groupDescription,
    required this.groupImage,
    required this.creatorUID,
    required this.isVerified,
    required this.subscribersUIDs,
    required this.adminUIDs,
    required this.subscribersCount,
    required this.lastPostAt,
    required this.createdAt,
    required this.groupSettings,
  });

  factory PublicGroupModel.fromMap(Map<String, dynamic> map) {
    try {
      return PublicGroupModel(
        groupId: map['groupId']?.toString() ?? '',
        groupName: map['groupName']?.toString() ?? '',
        groupDescription: map['groupDescription']?.toString() ?? '',
        groupImage: map['groupImage']?.toString() ?? '',
        creatorUID: map['creatorUID']?.toString() ?? '',
        isVerified: map['isVerified'] ?? false,
        subscribersUIDs: (map['subscribersUIDs'] as List?)
            ?.map((item) => item.toString())
            .toList()
            .cast<String>() ?? [],
        adminUIDs: (map['adminUIDs'] as List?)
            ?.map((item) => item.toString())
            .toList()
            .cast<String>() ?? [],
        subscribersCount: map['subscribersCount'] is int 
            ? map['subscribersCount'] 
            : int.tryParse(map['subscribersCount']?.toString() ?? '0') ?? 0,
        lastPostAt: map['lastPostAt']?.toString() ?? '',
        createdAt: map['createdAt']?.toString() ?? '',
        groupSettings: Map<String, dynamic>.from(map['groupSettings'] ?? {}),
      );
    } catch (e, stackTrace) {
      print('Error parsing PublicGroupModel: $e');
      print('Map data: $map');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'groupDescription': groupDescription,
      'groupImage': groupImage,
      'creatorUID': creatorUID,
      'isVerified': isVerified,
      'subscribersUIDs': subscribersUIDs,
      'adminUIDs': adminUIDs,
      'subscribersCount': subscribersCount,
      'lastPostAt': lastPostAt,
      'createdAt': createdAt,
      'groupSettings': groupSettings,
    };
  }

  PublicGroupModel copyWith({
    String? groupId,
    String? groupName,
    String? groupDescription,
    String? groupImage,
    String? creatorUID,
    bool? isVerified,
    List<String>? subscribersUIDs,
    List<String>? adminUIDs,
    int? subscribersCount,
    String? lastPostAt,
    String? createdAt,
    Map<String, dynamic>? groupSettings,
  }) {
    return PublicGroupModel(
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      groupDescription: groupDescription ?? this.groupDescription,
      groupImage: groupImage ?? this.groupImage,
      creatorUID: creatorUID ?? this.creatorUID,
      isVerified: isVerified ?? this.isVerified,
      subscribersUIDs: subscribersUIDs ?? List.from(this.subscribersUIDs),
      adminUIDs: adminUIDs ?? List.from(this.adminUIDs),
      subscribersCount: subscribersCount ?? this.subscribersCount,
      lastPostAt: lastPostAt ?? this.lastPostAt,
      createdAt: createdAt ?? this.createdAt,
      groupSettings: groupSettings ?? Map.from(this.groupSettings),
    );
  }

  // Helper methods
  bool isSubscriber(String uid) {
    return subscribersUIDs.contains(uid);
  }

  bool isAdmin(String uid) {
    return adminUIDs.contains(uid);
  }

  bool isCreator(String uid) {
    return creatorUID == uid;
  }

  bool canPost(String uid) {
    return isCreator(uid) || isAdmin(uid);
  }

  String getSubscribersText() {
    if (subscribersCount == 0) return 'No followers';
    if (subscribersCount == 1) return '1 follower';
    if (subscribersCount < 1000) return '$subscribersCount followers';
    if (subscribersCount < 1000000) {
      return '${(subscribersCount / 1000).toStringAsFixed(1)}K followers';
    }
    return '${(subscribersCount / 1000000).toStringAsFixed(1)}M followers';
  }
}


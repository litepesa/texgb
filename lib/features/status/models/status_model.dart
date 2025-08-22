// lib/features/status/models/status_model.dart
import 'dart:ui';

import 'package:textgb/enums/enums.dart';

class StatusModel {
  final String id;
  final String uid;
  final String userName;
  final String userImage;
  final String phoneNumber;
  final List<StatusUpdate> updates;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final StatusPrivacyType privacy;
  final List<String> allowedViewers; // For 'only' privacy
  final List<String> excludedViewers; // For 'except' privacy

  const StatusModel({
    required this.id,
    required this.uid,
    required this.userName,
    required this.userImage,
    required this.phoneNumber,
    required this.updates,
    required this.createdAt,
    required this.lastUpdated,
    this.privacy = StatusPrivacyType.all_contacts,
    this.allowedViewers = const [],
    this.excludedViewers = const [],
  });

  factory StatusModel.fromMap(Map<String, dynamic> map) {
    return StatusModel(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      userName: map['userName'] ?? '',
      userImage: map['userImage'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      updates: (map['updates'] as List<dynamic>?)
          ?.map((update) => StatusUpdate.fromMap(update))
          .toList() ?? [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'] ?? 0),
      privacy: StatusPrivacyType.values.firstWhere(
        (p) => p.name == map['privacy'],
        orElse: () => StatusPrivacyType.all_contacts,
      ),
      allowedViewers: List<String>.from(map['allowedViewers'] ?? []),
      excludedViewers: List<String>.from(map['excludedViewers'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'userName': userName,
      'userImage': userImage,
      'phoneNumber': phoneNumber,
      'updates': updates.map((update) => update.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'privacy': privacy.name,
      'allowedViewers': allowedViewers,
      'excludedViewers': excludedViewers,
    };
  }

  StatusModel copyWith({
    String? id,
    String? uid,
    String? userName,
    String? userImage,
    String? phoneNumber,
    List<StatusUpdate>? updates,
    DateTime? createdAt,
    DateTime? lastUpdated,
    StatusPrivacyType? privacy,
    List<String>? allowedViewers,
    List<String>? excludedViewers,
  }) {
    return StatusModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      updates: updates ?? this.updates,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      privacy: privacy ?? this.privacy,
      allowedViewers: allowedViewers ?? this.allowedViewers,
      excludedViewers: excludedViewers ?? this.excludedViewers,
    );
  }

  // Helper methods
  bool get hasUnviewedUpdates => updates.any((update) => !update.isExpired);
  
  StatusUpdate? get latestUpdate => updates.isNotEmpty 
      ? updates.reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b)
      : null;

  int get totalUpdateCount => updates.length;
  
  int get unviewedUpdateCount => updates.where((update) => !update.isExpired).length;

  List<StatusUpdate> get activeUpdates => updates.where((update) => !update.isExpired).toList();
}

class StatusUpdate {
  final String id;
  final StatusType type;
  final String content; // Text content or caption
  final String? mediaUrl;
  final String? thumbnailUrl;
  final DateTime timestamp;
  final Duration duration; // For videos
  final Color? backgroundColor; // For text statuses
  final String? fontFamily; // For text statuses
  final List<StatusView> views;
  final bool isExpired;
  final Map<String, dynamic>? metadata; // Additional data

  const StatusUpdate({
    required this.id,
    required this.type,
    required this.content,
    this.mediaUrl,
    this.thumbnailUrl,
    required this.timestamp,
    this.duration = const Duration(seconds: 30),
    this.backgroundColor,
    this.fontFamily,
    this.views = const [],
    this.isExpired = false,
    this.metadata,
  });

  factory StatusUpdate.fromMap(Map<String, dynamic> map) {
    return StatusUpdate(
      id: map['id'] ?? '',
      type: StatusType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => StatusType.text,
      ),
      content: map['content'] ?? '',
      mediaUrl: map['mediaUrl'],
      thumbnailUrl: map['thumbnailUrl'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      duration: Duration(milliseconds: map['duration'] ?? 30000),
      backgroundColor: map['backgroundColor'] != null 
          ? Color(map['backgroundColor']) 
          : null,
      fontFamily: map['fontFamily'],
      views: (map['views'] as List<dynamic>?)
          ?.map((view) => StatusView.fromMap(view))
          .toList() ?? [],
      isExpired: map['isExpired'] ?? false,
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'content': content,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'duration': duration.inMilliseconds,
      'backgroundColor': backgroundColor?.value,
      'fontFamily': fontFamily,
      'views': views.map((view) => view.toMap()).toList(),
      'isExpired': isExpired,
      'metadata': metadata,
    };
  }

  StatusUpdate copyWith({
    String? id,
    StatusType? type,
    String? content,
    String? mediaUrl,
    String? thumbnailUrl,
    DateTime? timestamp,
    Duration? duration,
    Color? backgroundColor,
    String? fontFamily,
    List<StatusView>? views,
    bool? isExpired,
    Map<String, dynamic>? metadata,
  }) {
    return StatusUpdate(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      timestamp: timestamp ?? this.timestamp,
      duration: duration ?? this.duration,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontFamily: fontFamily ?? this.fontFamily,
      views: views ?? this.views,
      isExpired: isExpired ?? this.isExpired,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get hasExpired {
    return DateTime.now().difference(timestamp).inHours >= 24;
  }

  bool hasViewedBy(String userId) {
    return views.any((view) => view.viewerId == userId);
  }

  StatusView? getViewBy(String userId) {
    try {
      return views.firstWhere((view) => view.viewerId == userId);
    } catch (e) {
      return null;
    }
  }

  int get viewCount => views.length;

  String get displayDuration {
    if (type == StatusType.video) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '';
  }
}

class StatusView {
  final String viewerId;
  final String viewerName;
  final String? viewerImage;
  final DateTime viewedAt;

  const StatusView({
    required this.viewerId,
    required this.viewerName,
    this.viewerImage,
    required this.viewedAt,
  });

  factory StatusView.fromMap(Map<String, dynamic> map) {
    return StatusView(
      viewerId: map['viewerId'] ?? '',
      viewerName: map['viewerName'] ?? '',
      viewerImage: map['viewerImage'],
      viewedAt: DateTime.fromMillisecondsSinceEpoch(map['viewedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'viewerId': viewerId,
      'viewerName': viewerName,
      'viewerImage': viewerImage,
      'viewedAt': viewedAt.millisecondsSinceEpoch,
    };
  }

  StatusView copyWith({
    String? viewerId,
    String? viewerName,
    String? viewerImage,
    DateTime? viewedAt,
  }) {
    return StatusView(
      viewerId: viewerId ?? this.viewerId,
      viewerName: viewerName ?? this.viewerName,
      viewerImage: viewerImage ?? this.viewerImage,
      viewedAt: viewedAt ?? this.viewedAt,
    );
  }
}

// Helper class for status creation
class CreateStatusRequest {
  final StatusType type;
  final String content;
  final String? mediaPath; // Local file path
  final Duration? duration;
  final Color? backgroundColor;
  final String? fontFamily;
  final StatusPrivacyType privacy;
  final List<String> allowedViewers;
  final List<String> excludedViewers;

  const CreateStatusRequest({
    required this.type,
    required this.content,
    this.mediaPath,
    this.duration,
    this.backgroundColor,
    this.fontFamily,
    this.privacy = StatusPrivacyType.all_contacts,
    this.allowedViewers = const [],
    this.excludedViewers = const [],
  });

  CreateStatusRequest copyWith({
    StatusType? type,
    String? content,
    String? mediaPath,
    Duration? duration,
    Color? backgroundColor,
    String? fontFamily,
    StatusPrivacyType? privacy,
    List<String>? allowedViewers,
    List<String>? excludedViewers,
  }) {
    return CreateStatusRequest(
      type: type ?? this.type,
      content: content ?? this.content,
      mediaPath: mediaPath ?? this.mediaPath,
      duration: duration ?? this.duration,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontFamily: fontFamily ?? this.fontFamily,
      privacy: privacy ?? this.privacy,
      allowedViewers: allowedViewers ?? this.allowedViewers,
      excludedViewers: excludedViewers ?? this.excludedViewers,
    );
  }
}

// Status reaction model
class StatusReaction {
  final String id;
  final String statusId;
  final String statusUpdateId;
  final String userId;
  final String userName;
  final String? userImage;
  final String emoji;
  final DateTime timestamp;

  const StatusReaction({
    required this.id,
    required this.statusId,
    required this.statusUpdateId,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.emoji,
    required this.timestamp,
  });

  factory StatusReaction.fromMap(Map<String, dynamic> map) {
    return StatusReaction(
      id: map['id'] ?? '',
      statusId: map['statusId'] ?? '',
      statusUpdateId: map['statusUpdateId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userImage: map['userImage'],
      emoji: map['emoji'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'statusId': statusId,
      'statusUpdateId': statusUpdateId,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'emoji': emoji,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  StatusReaction copyWith({
    String? id,
    String? statusId,
    String? statusUpdateId,
    String? userId,
    String? userName,
    String? userImage,
    String? emoji,
    DateTime? timestamp,
  }) {
    return StatusReaction(
      id: id ?? this.id,
      statusId: statusId ?? this.statusId,
      statusUpdateId: statusUpdateId ?? this.statusUpdateId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      emoji: emoji ?? this.emoji,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
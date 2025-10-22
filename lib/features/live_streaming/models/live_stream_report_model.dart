// lib/features/live_streaming/models/live_stream_report_model.dart

// Report type enum
enum ReportType {
  stream,         // Reporting the entire live stream
  message,        // Reporting a specific chat message
  user;           // Reporting a specific user

  String get displayName {
    switch (this) {
      case ReportType.stream:
        return 'Live Stream';
      case ReportType.message:
        return 'Chat Message';
      case ReportType.user:
        return 'User';
    }
  }
}

// Report reason enum
enum ReportReason {
  inappropriate,      // Inappropriate content
  spam,              // Spam or scam
  harassment,        // Harassment or bullying
  violence,          // Violence or dangerous content
  hateSpeech,        // Hate speech or discrimination
  sexualContent,     // Sexual or explicit content
  falseInfo,         // False information or misinformation
  copyright,         // Copyright violation
  scam,              // Scam or fraud
  other;             // Other reason

  String get displayName {
    switch (this) {
      case ReportReason.inappropriate:
        return 'Inappropriate Content';
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.harassment:
        return 'Harassment or Bullying';
      case ReportReason.violence:
        return 'Violence or Dangerous Content';
      case ReportReason.hateSpeech:
        return 'Hate Speech';
      case ReportReason.sexualContent:
        return 'Sexual Content';
      case ReportReason.falseInfo:
        return 'False Information';
      case ReportReason.copyright:
        return 'Copyright Violation';
      case ReportReason.scam:
        return 'Scam or Fraud';
      case ReportReason.other:
        return 'Other';
    }
  }

  String get description {
    switch (this) {
      case ReportReason.inappropriate:
        return 'Content that violates community guidelines';
      case ReportReason.spam:
        return 'Repetitive or unwanted messages';
      case ReportReason.harassment:
        return 'Bullying, threats, or harassment';
      case ReportReason.violence:
        return 'Violent or dangerous activities';
      case ReportReason.hateSpeech:
        return 'Discrimination based on race, religion, etc.';
      case ReportReason.sexualContent:
        return 'Explicit sexual content';
      case ReportReason.falseInfo:
        return 'Misleading or false information';
      case ReportReason.copyright:
        return 'Unauthorized use of copyrighted material';
      case ReportReason.scam:
        return 'Fraudulent or deceptive practices';
      case ReportReason.other:
        return 'Other violations';
    }
  }

  String get emoji {
    switch (this) {
      case ReportReason.inappropriate:
        return '⚠️';
      case ReportReason.spam:
        return '🚫';
      case ReportReason.harassment:
        return '😡';
      case ReportReason.violence:
        return '⚔️';
      case ReportReason.hateSpeech:
        return '💢';
      case ReportReason.sexualContent:
        return '🔞';
      case ReportReason.falseInfo:
        return '❌';
      case ReportReason.copyright:
        return '©️';
      case ReportReason.scam:
        return '💰';
      case ReportReason.other:
        return '📝';
    }
  }
}

// Report status enum
enum ReportStatus {
  pending,        // Awaiting review
  reviewing,      // Under review by moderator
  resolved,       // Action taken
  dismissed,      // No action needed
  escalated;      // Escalated to admin

  String get displayName {
    switch (this) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.reviewing:
        return 'Under Review';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.dismissed:
        return 'Dismissed';
      case ReportStatus.escalated:
        return 'Escalated';
    }
  }

  String get emoji {
    switch (this) {
      case ReportStatus.pending:
        return '⏳';
      case ReportStatus.reviewing:
        return '🔍';
      case ReportStatus.resolved:
        return '✅';
      case ReportStatus.dismissed:
        return '❌';
      case ReportStatus.escalated:
        return '⬆️';
    }
  }
}

// Action taken enum
enum ReportAction {
  none,              // No action taken
  warningIssued,     // Warning issued to user
  contentRemoved,    // Content removed
  userMuted,         // User muted in chat
  userBanned,        // User banned from stream
  streamEnded,       // Stream ended by admin
  accountSuspended,  // User account suspended
  accountBanned;     // User account permanently banned

  String get displayName {
    switch (this) {
      case ReportAction.none:
        return 'No Action';
      case ReportAction.warningIssued:
        return 'Warning Issued';
      case ReportAction.contentRemoved:
        return 'Content Removed';
      case ReportAction.userMuted:
        return 'User Muted';
      case ReportAction.userBanned:
        return 'User Banned';
      case ReportAction.streamEnded:
        return 'Stream Ended';
      case ReportAction.accountSuspended:
        return 'Account Suspended';
      case ReportAction.accountBanned:
        return 'Account Banned';
    }
  }
}

// Main Live Stream Report Model
class LiveStreamReportModel {
  final String id;
  final ReportType type;
  final ReportReason reason;
  final ReportStatus status;
  
  // Reporter info
  final String reporterId;
  final String reporterName;
  final String reportedAt;
  
  // Reported content info
  final String? liveStreamId;        // If reporting stream
  final String? messageId;           // If reporting message
  final String? reportedUserId;      // User being reported
  final String? reportedUserName;
  
  // Report details
  final String description;          // User's description of issue
  final List<String>? screenshots;   // Screenshot URLs (future feature)
  final String? timestamp;           // When the incident occurred
  
  // Reported content snapshot
  final String? contentSnapshot;     // Copy of reported content
  final Map<String, dynamic>? metadata;  // Additional context
  
  // Review info
  final String? reviewedBy;          // Admin/moderator who reviewed
  final String? reviewedAt;
  final ReportAction actionTaken;
  final String? reviewNotes;         // Admin notes
  
  // Priority/severity
  final int severityScore;           // 1-10, higher = more severe
  final bool isUrgent;               // Requires immediate attention

  const LiveStreamReportModel({
    required this.id,
    required this.type,
    required this.reason,
    required this.status,
    required this.reporterId,
    required this.reporterName,
    required this.reportedAt,
    this.liveStreamId,
    this.messageId,
    this.reportedUserId,
    this.reportedUserName,
    required this.description,
    this.screenshots,
    this.timestamp,
    this.contentSnapshot,
    this.metadata,
    this.reviewedBy,
    this.reviewedAt,
    this.actionTaken = ReportAction.none,
    this.reviewNotes,
    this.severityScore = 5,
    this.isUrgent = false,
  });

  // Create new report for stream
  factory LiveStreamReportModel.reportStream({
    required String liveStreamId,
    required String reporterId,
    required String reporterName,
    required ReportReason reason,
    required String description,
    String? contentSnapshot,
  }) {
    return LiveStreamReportModel(
      id: '', // Will be set by backend
      type: ReportType.stream,
      reason: reason,
      status: ReportStatus.pending,
      reporterId: reporterId,
      reporterName: reporterName,
      reportedAt: DateTime.now().toUtc().toIso8601String(),
      liveStreamId: liveStreamId,
      description: description.trim(),
      contentSnapshot: contentSnapshot,
      timestamp: DateTime.now().toUtc().toIso8601String(),
      severityScore: _calculateSeverityScore(reason),
      isUrgent: _isUrgentReason(reason),
    );
  }

  // Create new report for chat message
  factory LiveStreamReportModel.reportMessage({
    required String liveStreamId,
    required String messageId,
    required String reporterId,
    required String reporterName,
    required String reportedUserId,
    required String reportedUserName,
    required ReportReason reason,
    required String description,
    required String contentSnapshot,
  }) {
    return LiveStreamReportModel(
      id: '',
      type: ReportType.message,
      reason: reason,
      status: ReportStatus.pending,
      reporterId: reporterId,
      reporterName: reporterName,
      reportedAt: DateTime.now().toUtc().toIso8601String(),
      liveStreamId: liveStreamId,
      messageId: messageId,
      reportedUserId: reportedUserId,
      reportedUserName: reportedUserName,
      description: description.trim(),
      contentSnapshot: contentSnapshot,
      timestamp: DateTime.now().toUtc().toIso8601String(),
      severityScore: _calculateSeverityScore(reason),
      isUrgent: _isUrgentReason(reason),
    );
  }

  // Create new report for user
  factory LiveStreamReportModel.reportUser({
    required String liveStreamId,
    required String reporterId,
    required String reporterName,
    required String reportedUserId,
    required String reportedUserName,
    required ReportReason reason,
    required String description,
  }) {
    return LiveStreamReportModel(
      id: '',
      type: ReportType.user,
      reason: reason,
      status: ReportStatus.pending,
      reporterId: reporterId,
      reporterName: reporterName,
      reportedAt: DateTime.now().toUtc().toIso8601String(),
      liveStreamId: liveStreamId,
      reportedUserId: reportedUserId,
      reportedUserName: reportedUserName,
      description: description.trim(),
      timestamp: DateTime.now().toUtc().toIso8601String(),
      severityScore: _calculateSeverityScore(reason),
      isUrgent: _isUrgentReason(reason),
    );
  }

  // Calculate severity score based on reason
  static int _calculateSeverityScore(ReportReason reason) {
    switch (reason) {
      case ReportReason.violence:
      case ReportReason.sexualContent:
      case ReportReason.hateSpeech:
        return 9; // High priority
      case ReportReason.harassment:
      case ReportReason.scam:
        return 7; // Medium-high priority
      case ReportReason.inappropriate:
      case ReportReason.falseInfo:
        return 5; // Medium priority
      case ReportReason.spam:
      case ReportReason.copyright:
        return 3; // Low-medium priority
      case ReportReason.other:
        return 2; // Low priority
    }
  }

  // Check if reason requires urgent attention
  static bool _isUrgentReason(ReportReason reason) {
    return reason == ReportReason.violence ||
           reason == ReportReason.sexualContent ||
           reason == ReportReason.hateSpeech ||
           reason == ReportReason.scam;
  }

  // From JSON (backend response)
  factory LiveStreamReportModel.fromJson(Map<String, dynamic> json) {
    return LiveStreamReportModel(
      id: json['id'] ?? '',
      type: ReportType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'stream'),
        orElse: () => ReportType.stream,
      ),
      reason: ReportReason.values.firstWhere(
        (e) => e.name == (json['reason'] ?? 'inappropriate'),
        orElse: () => ReportReason.inappropriate,
      ),
      status: ReportStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'pending'),
        orElse: () => ReportStatus.pending,
      ),
      reporterId: json['reporterId'] ?? json['reporter_id'] ?? '',
      reporterName: json['reporterName'] ?? json['reporter_name'] ?? '',
      reportedAt: json['reportedAt'] ?? json['reported_at'] ?? '',
      liveStreamId: json['liveStreamId'] ?? json['live_stream_id'],
      messageId: json['messageId'] ?? json['message_id'],
      reportedUserId: json['reportedUserId'] ?? json['reported_user_id'],
      reportedUserName: json['reportedUserName'] ?? json['reported_user_name'],
      description: json['description'] ?? '',
      screenshots: json['screenshots'] != null 
          ? List<String>.from(json['screenshots']) 
          : null,
      timestamp: json['timestamp'],
      contentSnapshot: json['contentSnapshot'] ?? json['content_snapshot'],
      metadata: json['metadata'] as Map<String, dynamic>?,
      reviewedBy: json['reviewedBy'] ?? json['reviewed_by'],
      reviewedAt: json['reviewedAt'] ?? json['reviewed_at'],
      actionTaken: ReportAction.values.firstWhere(
        (e) => e.name == (json['actionTaken'] ?? json['action_taken'] ?? 'none'),
        orElse: () => ReportAction.none,
      ),
      reviewNotes: json['reviewNotes'] ?? json['review_notes'],
      severityScore: json['severityScore'] ?? json['severity_score'] ?? 5,
      isUrgent: json['isUrgent'] ?? json['is_urgent'] ?? false,
    );
  }

  // To JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'reason': reason.name,
      'status': status.name,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reportedAt': reportedAt,
      'liveStreamId': liveStreamId,
      'messageId': messageId,
      'reportedUserId': reportedUserId,
      'reportedUserName': reportedUserName,
      'description': description,
      'screenshots': screenshots,
      'timestamp': timestamp,
      'contentSnapshot': contentSnapshot,
      'metadata': metadata,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt,
      'actionTaken': actionTaken.name,
      'reviewNotes': reviewNotes,
      'severityScore': severityScore,
      'isUrgent': isUrgent,
    };
  }

  // CopyWith method
  LiveStreamReportModel copyWith({
    String? id,
    ReportType? type,
    ReportReason? reason,
    ReportStatus? status,
    String? reporterId,
    String? reporterName,
    String? reportedAt,
    String? liveStreamId,
    String? messageId,
    String? reportedUserId,
    String? reportedUserName,
    String? description,
    List<String>? screenshots,
    String? timestamp,
    String? contentSnapshot,
    Map<String, dynamic>? metadata,
    String? reviewedBy,
    String? reviewedAt,
    ReportAction? actionTaken,
    String? reviewNotes,
    int? severityScore,
    bool? isUrgent,
  }) {
    return LiveStreamReportModel(
      id: id ?? this.id,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      reportedAt: reportedAt ?? this.reportedAt,
      liveStreamId: liveStreamId ?? this.liveStreamId,
      messageId: messageId ?? this.messageId,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      reportedUserName: reportedUserName ?? this.reportedUserName,
      description: description ?? this.description,
      screenshots: screenshots ?? this.screenshots,
      timestamp: timestamp ?? this.timestamp,
      contentSnapshot: contentSnapshot ?? this.contentSnapshot,
      metadata: metadata ?? this.metadata,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      actionTaken: actionTaken ?? this.actionTaken,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      severityScore: severityScore ?? this.severityScore,
      isUrgent: isUrgent ?? this.isUrgent,
    );
  }

  // Helper getters
  bool get isPending => status == ReportStatus.pending;
  bool get isReviewing => status == ReportStatus.reviewing;
  bool get isResolved => status == ReportStatus.resolved;
  bool get isDismissed => status == ReportStatus.dismissed;
  bool get isEscalated => status == ReportStatus.escalated;
  
  bool get hasBeenReviewed => reviewedBy != null && reviewedAt != null;
  bool get requiresAction => isPending || isReviewing;
  
  String get reportTypeText => type.displayName;
  String get reasonText => reason.displayName;
  String get statusText => status.displayName;
  String get actionText => actionTaken.displayName;

  String get priorityLabel {
    if (isUrgent) return 'URGENT';
    if (severityScore >= 8) return 'HIGH';
    if (severityScore >= 5) return 'MEDIUM';
    return 'LOW';
  }

  String get timeAgo {
    final reported = DateTime.parse(reportedAt);
    final now = DateTime.now();
    final difference = now.difference(reported);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiveStreamReportModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'LiveStreamReportModel(id: $id, type: ${type.name}, reason: ${reason.name}, status: ${status.name})';
  }
}

// Report statistics model (for admin dashboard)
class ReportStatistics {
  final int totalReports;
  final int pendingReports;
  final int resolvedReports;
  final int dismissedReports;
  final Map<ReportReason, int> reportsByReason;
  final Map<ReportAction, int> actionsTaken;
  final double averageResolutionTimeHours;

  const ReportStatistics({
    required this.totalReports,
    required this.pendingReports,
    required this.resolvedReports,
    required this.dismissedReports,
    required this.reportsByReason,
    required this.actionsTaken,
    required this.averageResolutionTimeHours,
  });

  factory ReportStatistics.fromJson(Map<String, dynamic> json) {
    return ReportStatistics(
      totalReports: json['totalReports'] ?? json['total_reports'] ?? 0,
      pendingReports: json['pendingReports'] ?? json['pending_reports'] ?? 0,
      resolvedReports: json['resolvedReports'] ?? json['resolved_reports'] ?? 0,
      dismissedReports: json['dismissedReports'] ?? json['dismissed_reports'] ?? 0,
      reportsByReason: (json['reportsByReason'] ?? json['reports_by_reason'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(
              ReportReason.values.firstWhere((e) => e.name == key),
              value as int)) ?? {},
      actionsTaken: (json['actionsTaken'] ?? json['actions_taken'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(
              ReportAction.values.firstWhere((e) => e.name == key),
              value as int)) ?? {},
      averageResolutionTimeHours: (json['averageResolutionTimeHours'] ?? 
          json['average_resolution_time_hours'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalReports': totalReports,
      'pendingReports': pendingReports,
      'resolvedReports': resolvedReports,
      'dismissedReports': dismissedReports,
      'reportsByReason': reportsByReason.map((key, value) => MapEntry(key.name, value)),
      'actionsTaken': actionsTaken.map((key, value) => MapEntry(key.name, value)),
      'averageResolutionTimeHours': averageResolutionTimeHours,
    };
  }

  String get resolutionTimeText {
    if (averageResolutionTimeHours < 1) {
      return '${(averageResolutionTimeHours * 60).round()} minutes';
    } else if (averageResolutionTimeHours < 24) {
      return '${averageResolutionTimeHours.toStringAsFixed(1)} hours';
    } else {
      return '${(averageResolutionTimeHours / 24).toStringAsFixed(1)} days';
    }
  }
}
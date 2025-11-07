// lib/features/calls/models/call_model.dart
// WebRTC Call Model for 1-on-1 Voice and Video Calls

enum CallType {
  voice,
  video,
}

enum CallStatus {
  ringing,      // Call initiated, waiting for answer
  connecting,   // Peer connection being established
  connected,    // Call in progress
  ended,        // Call ended normally
  declined,     // Call was declined by receiver
  missed,       // Call was not answered
  failed,       // Call failed due to error
  busy,         // Callee is already on another call
  timeout,      // Call timed out (no answer after 60s)
}

enum CallDirection {
  incoming,
  outgoing,
}

class CallModel {
  final String callId;
  final String chatId;
  final String callerId;
  final String callerName;
  final String callerAvatar;
  final String receiverId;
  final String receiverName;
  final String receiverAvatar;
  final CallType type;
  final CallStatus status;
  final CallDirection direction;
  final DateTime startedAt;
  final DateTime? connectedAt;
  final DateTime? endedAt;
  final int? duration; // in seconds
  final Map<String, dynamic>? metadata;

  const CallModel({
    required this.callId,
    required this.chatId,
    required this.callerId,
    required this.callerName,
    required this.callerAvatar,
    required this.receiverId,
    required this.receiverName,
    required this.receiverAvatar,
    required this.type,
    required this.status,
    required this.direction,
    required this.startedAt,
    this.connectedAt,
    this.endedAt,
    this.duration,
    this.metadata,
  });

  factory CallModel.fromMap(Map<String, dynamic> map) {
    return CallModel(
      callId: map['callId'] ?? '',
      chatId: map['chatId'] ?? '',
      callerId: map['callerId'] ?? '',
      callerName: map['callerName'] ?? '',
      callerAvatar: map['callerAvatar'] ?? '',
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      receiverAvatar: map['receiverAvatar'] ?? '',
      type: CallType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CallType.voice,
      ),
      status: CallStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CallStatus.ringing,
      ),
      direction: CallDirection.values.firstWhere(
        (e) => e.name == map['direction'],
        orElse: () => CallDirection.outgoing,
      ),
      startedAt: DateTime.parse(map['startedAt'] ?? DateTime.now().toIso8601String()),
      connectedAt: map['connectedAt'] != null ? DateTime.parse(map['connectedAt']) : null,
      endedAt: map['endedAt'] != null ? DateTime.parse(map['endedAt']) : null,
      duration: map['duration'],
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'callId': callId,
      'chatId': chatId,
      'callerId': callerId,
      'callerName': callerName,
      'callerAvatar': callerAvatar,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverAvatar': receiverAvatar,
      'type': type.name,
      'status': status.name,
      'direction': direction.name,
      'startedAt': startedAt.toUtc().toIso8601String(),
      'connectedAt': connectedAt?.toUtc().toIso8601String(),
      'endedAt': endedAt?.toUtc().toIso8601String(),
      'duration': duration,
      'metadata': metadata,
    };
  }

  CallModel copyWith({
    String? callId,
    String? chatId,
    String? callerId,
    String? callerName,
    String? callerAvatar,
    String? receiverId,
    String? receiverName,
    String? receiverAvatar,
    CallType? type,
    CallStatus? status,
    CallDirection? direction,
    DateTime? startedAt,
    DateTime? connectedAt,
    DateTime? endedAt,
    int? duration,
    Map<String, dynamic>? metadata,
  }) {
    return CallModel(
      callId: callId ?? this.callId,
      chatId: chatId ?? this.chatId,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerAvatar: callerAvatar ?? this.callerAvatar,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverAvatar: receiverAvatar ?? this.receiverAvatar,
      type: type ?? this.type,
      status: status ?? this.status,
      direction: direction ?? this.direction,
      startedAt: startedAt ?? this.startedAt,
      connectedAt: connectedAt ?? this.connectedAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isVoiceCall => type == CallType.voice;
  bool get isVideoCall => type == CallType.video;
  bool get isIncoming => direction == CallDirection.incoming;
  bool get isOutgoing => direction == CallDirection.outgoing;
  bool get isActive => status == CallStatus.connected;
  bool get isRinging => status == CallStatus.ringing;
  bool get isEnded => status == CallStatus.ended ||
                      status == CallStatus.declined ||
                      status == CallStatus.missed ||
                      status == CallStatus.failed ||
                      status == CallStatus.timeout;

  String get formattedDuration {
    if (duration == null) return '00:00';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get statusDisplay {
    switch (status) {
      case CallStatus.ringing:
        return isIncoming ? 'Incoming call...' : 'Ringing...';
      case CallStatus.connecting:
        return 'Connecting...';
      case CallStatus.connected:
        return formattedDuration;
      case CallStatus.ended:
        return duration != null ? formattedDuration : 'Ended';
      case CallStatus.declined:
        return 'Declined';
      case CallStatus.missed:
        return 'Missed call';
      case CallStatus.failed:
        return 'Failed';
      case CallStatus.busy:
        return 'Busy';
      case CallStatus.timeout:
        return 'No answer';
    }
  }

  String get callTypeIcon {
    switch (type) {
      case CallType.voice:
        return '📞';
      case CallType.video:
        return '📹';
    }
  }
}

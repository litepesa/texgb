// lib/features/live_streaming/models/websocket_event_models.dart

// WebSocket event type enum
enum WebSocketEventType {
  // Connection events
  connected,
  disconnected,
  error,
  
  // Viewer events
  viewerJoined,
  viewerLeft,
  viewerCountUpdate,
  
  // Chat events
  messageSent,
  messageDeleted,
  messagePinned,
  messageUnpinned,
  
  // Gift events
  giftSent,
  giftCombo,
  
  // Product events
  productAdded,
  productRemoved,
  productPinned,
  productUnpinned,
  
  // Stream control events
  streamStarted,
  streamEnded,
  streamPaused,
  streamResumed,
  
  // Moderation events
  userBlocked,
  userUnblocked,
  userPromoted,
  userDemoted,
  
  // System events
  announcement,
  notification,
  heartbeat;  // Keep-alive ping

  String get eventName => name;

  static WebSocketEventType fromString(String value) {
    return WebSocketEventType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WebSocketEventType.notification,
    );
  }
}

// Base WebSocket event model
abstract class WebSocketEvent {
  final WebSocketEventType type;
  final String timestamp;
  final Map<String, dynamic>? metadata;

  const WebSocketEvent({
    required this.type,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson();

  factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
    final type = WebSocketEventType.fromString(json['type'] ?? 'notification');
    final timestamp = json['timestamp'] ?? DateTime.now().toUtc().toIso8601String();
    final metadata = json['metadata'] as Map<String, dynamic>?;

    switch (type) {
      case WebSocketEventType.connected:
        return ConnectedEvent.fromJson(json);
      case WebSocketEventType.disconnected:
        return DisconnectedEvent.fromJson(json);
      case WebSocketEventType.error:
        return ErrorEvent.fromJson(json);
      case WebSocketEventType.viewerJoined:
        return ViewerJoinedEvent.fromJson(json);
      case WebSocketEventType.viewerLeft:
        return ViewerLeftEvent.fromJson(json);
      case WebSocketEventType.viewerCountUpdate:
        return ViewerCountUpdateEvent.fromJson(json);
      case WebSocketEventType.messageSent:
        return MessageSentEvent.fromJson(json);
      case WebSocketEventType.messageDeleted:
        return MessageDeletedEvent.fromJson(json);
      case WebSocketEventType.messagePinned:
        return MessagePinnedEvent.fromJson(json);
      case WebSocketEventType.messageUnpinned:
        return MessageUnpinnedEvent.fromJson(json);
      case WebSocketEventType.giftSent:
        return GiftSentEvent.fromJson(json);
      case WebSocketEventType.giftCombo:
        return GiftComboEvent.fromJson(json);
      case WebSocketEventType.productAdded:
        return ProductAddedEvent.fromJson(json);
      case WebSocketEventType.productRemoved:
        return ProductRemovedEvent.fromJson(json);
      case WebSocketEventType.productPinned:
        return ProductPinnedEvent.fromJson(json);
      case WebSocketEventType.productUnpinned:
        return ProductUnpinnedEvent.fromJson(json);
      case WebSocketEventType.streamStarted:
        return StreamStartedEvent.fromJson(json);
      case WebSocketEventType.streamEnded:
        return StreamEndedEvent.fromJson(json);
      case WebSocketEventType.streamPaused:
        return StreamPausedEvent.fromJson(json);
      case WebSocketEventType.streamResumed:
        return StreamResumedEvent.fromJson(json);
      case WebSocketEventType.userBlocked:
        return UserBlockedEvent.fromJson(json);
      case WebSocketEventType.userUnblocked:
        return UserUnblockedEvent.fromJson(json);
      case WebSocketEventType.userPromoted:
        return UserPromotedEvent.fromJson(json);
      case WebSocketEventType.userDemoted:
        return UserDemotedEvent.fromJson(json);
      case WebSocketEventType.announcement:
        return AnnouncementEvent.fromJson(json);
      case WebSocketEventType.notification:
        return NotificationEvent.fromJson(json);
      case WebSocketEventType.heartbeat:
        return HeartbeatEvent.fromJson(json);
    }
  }
}

// ============================================
// CONNECTION EVENTS
// ============================================

class ConnectedEvent extends WebSocketEvent {
  final String sessionId;
  final String userId;
  final String liveStreamId;

  const ConnectedEvent({
    required this.sessionId,
    required this.userId,
    required this.liveStreamId,
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.connected);

  factory ConnectedEvent.fromJson(Map<String, dynamic> json) {
    return ConnectedEvent(
      sessionId: json['sessionId'] ?? json['session_id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      liveStreamId: json['liveStreamId'] ?? json['live_stream_id'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'sessionId': sessionId,
      'userId': userId,
      'liveStreamId': liveStreamId,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

class DisconnectedEvent extends WebSocketEvent {
  final String sessionId;
  final String userId;
  final String reason;

  const DisconnectedEvent({
    required this.sessionId,
    required this.userId,
    required this.reason,
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.disconnected);

  factory DisconnectedEvent.fromJson(Map<String, dynamic> json) {
    return DisconnectedEvent(
      sessionId: json['sessionId'] ?? json['session_id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      reason: json['reason'] ?? 'unknown',
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'sessionId': sessionId,
      'userId': userId,
      'reason': reason,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

class ErrorEvent extends WebSocketEvent {
  final String code;
  final String message;

  const ErrorEvent({
    required this.code,
    required this.message,
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.error);

  factory ErrorEvent.fromJson(Map<String, dynamic> json) {
    return ErrorEvent(
      code: json['code'] ?? 'UNKNOWN_ERROR',
      message: json['message'] ?? 'An error occurred',
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'code': code,
      'message': message,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

// ============================================
// VIEWER EVENTS
// ============================================

class ViewerJoinedEvent extends WebSocketEvent {
  final String viewerId;
  final String userId;
  final String userName;
  final String userImage;
  final bool userIsVerified;
  final String viewerTier;
  final bool hasEntranceEffect;

  const ViewerJoinedEvent({
    required this.viewerId,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.userIsVerified,
    required this.viewerTier,
    this.hasEntranceEffect = false,
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.viewerJoined);

  factory ViewerJoinedEvent.fromJson(Map<String, dynamic> json) {
    return ViewerJoinedEvent(
      viewerId: json['viewerId'] ?? json['viewer_id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      userName: json['userName'] ?? json['user_name'] ?? '',
      userImage: json['userImage'] ?? json['user_image'] ?? '',
      userIsVerified: json['userIsVerified'] ?? json['user_is_verified'] ?? false,
      viewerTier: json['viewerTier'] ?? json['viewer_tier'] ?? 'regular',
      hasEntranceEffect: json['hasEntranceEffect'] ?? json['has_entrance_effect'] ?? false,
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'viewerId': viewerId,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'userIsVerified': userIsVerified,
      'viewerTier': viewerTier,
      'hasEntranceEffect': hasEntranceEffect,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

class ViewerLeftEvent extends WebSocketEvent {
  final String viewerId;
  final String userId;
  final String userName;
  final int watchDurationSeconds;

  const ViewerLeftEvent({
    required this.viewerId,
    required this.userId,
    required this.userName,
    required this.watchDurationSeconds,
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.viewerLeft);

  factory ViewerLeftEvent.fromJson(Map<String, dynamic> json) {
    return ViewerLeftEvent(
      viewerId: json['viewerId'] ?? json['viewer_id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      userName: json['userName'] ?? json['user_name'] ?? '',
      watchDurationSeconds: json['watchDurationSeconds'] ?? json['watch_duration_seconds'] ?? 0,
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'viewerId': viewerId,
      'userId': userId,
      'userName': userName,
      'watchDurationSeconds': watchDurationSeconds,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

class ViewerCountUpdateEvent extends WebSocketEvent {
  final int currentViewers;
  final int totalViewers;
  final int peakViewers;

  const ViewerCountUpdateEvent({
    required this.currentViewers,
    required this.totalViewers,
    required this.peakViewers,
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.viewerCountUpdate);

  factory ViewerCountUpdateEvent.fromJson(Map<String, dynamic> json) {
    return ViewerCountUpdateEvent(
      currentViewers: json['currentViewers'] ?? json['current_viewers'] ?? 0,
      totalViewers: json['totalViewers'] ?? json['total_viewers'] ?? 0,
      peakViewers: json['peakViewers'] ?? json['peak_viewers'] ?? 0,
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'currentViewers': currentViewers,
      'totalViewers': totalViewers,
      'peakViewers': peakViewers,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

// ============================================
// CHAT EVENTS
// ============================================

class MessageSentEvent extends WebSocketEvent {
  final String messageId;
  final String senderId;
  final String senderName;
  final String senderImage;
  final bool senderIsVerified;
  final bool senderIsHost;
  final bool senderIsModerator;
  final String message;
  final String messageType;

  const MessageSentEvent({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.senderImage,
    required this.senderIsVerified,
    required this.senderIsHost,
    required this.senderIsModerator,
    required this.message,
    this.messageType = 'text',
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.messageSent);

  factory MessageSentEvent.fromJson(Map<String, dynamic> json) {
    return MessageSentEvent(
      messageId: json['messageId'] ?? json['message_id'] ?? '',
      senderId: json['senderId'] ?? json['sender_id'] ?? '',
      senderName: json['senderName'] ?? json['sender_name'] ?? '',
      senderImage: json['senderImage'] ?? json['sender_image'] ?? '',
      senderIsVerified: json['senderIsVerified'] ?? json['sender_is_verified'] ?? false,
      senderIsHost: json['senderIsHost'] ?? json['sender_is_host'] ?? false,
      senderIsModerator: json['senderIsModerator'] ?? json['sender_is_moderator'] ?? false,
      message: json['message'] ?? '',
      messageType: json['messageType'] ?? json['message_type'] ?? 'text',
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'messageId': messageId,
      'senderId': senderId,
      'senderName': senderName,
      'senderImage': senderImage,
      'senderIsVerified': senderIsVerified,
      'senderIsHost': senderIsHost,
      'senderIsModerator': senderIsModerator,
      'message': message,
      'messageType': messageType,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

class MessageDeletedEvent extends WebSocketEvent {
  final String messageId;
  final String deletedBy;

  const MessageDeletedEvent({
    required this.messageId,
    required this.deletedBy,
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.messageDeleted);

  factory MessageDeletedEvent.fromJson(Map<String, dynamic> json) {
    return MessageDeletedEvent(
      messageId: json['messageId'] ?? json['message_id'] ?? '',
      deletedBy: json['deletedBy'] ?? json['deleted_by'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'messageId': messageId,
      'deletedBy': deletedBy,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

class MessagePinnedEvent extends WebSocketEvent {
  final String messageId;
  final String message;
  final String pinnedBy;

  const MessagePinnedEvent({
    required this.messageId,
    required this.message,
    required this.pinnedBy,
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.messagePinned);

  factory MessagePinnedEvent.fromJson(Map<String, dynamic> json) {
    return MessagePinnedEvent(
      messageId: json['messageId'] ?? json['message_id'] ?? '',
      message: json['message'] ?? '',
      pinnedBy: json['pinnedBy'] ?? json['pinned_by'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'messageId': messageId,
      'message': message,
      'pinnedBy': pinnedBy,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

class MessageUnpinnedEvent extends WebSocketEvent {
  final String messageId;

  const MessageUnpinnedEvent({
    required this.messageId,
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.messageUnpinned);

  factory MessageUnpinnedEvent.fromJson(Map<String, dynamic> json) {
    return MessageUnpinnedEvent(
      messageId: json['messageId'] ?? json['message_id'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'messageId': messageId,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

// ============================================
// GIFT EVENTS
// ============================================

class GiftSentEvent extends WebSocketEvent {
  final String giftId;
  final String senderId;
  final String senderName;
  final String senderImage;
  final bool senderIsVerified;
  final String receiverId;
  final String receiverName;
  final String giftName;
  final String giftEmoji;
  final double giftPrice;
  final int comboCount;

  const GiftSentEvent({
    required this.giftId,
    required this.senderId,
    required this.senderName,
    required this.senderImage,
    required this.senderIsVerified,
    required this.receiverId,
    required this.receiverName,
    required this.giftName,
    required this.giftEmoji,
    required this.giftPrice,
    this.comboCount = 1,
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.giftSent);

  factory GiftSentEvent.fromJson(Map<String, dynamic> json) {
    return GiftSentEvent(
      giftId: json['giftId'] ?? json['gift_id'] ?? '',
      senderId: json['senderId'] ?? json['sender_id'] ?? '',
      senderName: json['senderName'] ?? json['sender_name'] ?? '',
      senderImage: json['senderImage'] ?? json['sender_image'] ?? '',
      senderIsVerified: json['senderIsVerified'] ?? json['sender_is_verified'] ?? false,
      receiverId: json['receiverId'] ?? json['receiver_id'] ?? '',
      receiverName: json['receiverName'] ?? json['receiver_name'] ?? '',
      giftName: json['giftName'] ?? json['gift_name'] ?? '',
      giftEmoji: json['giftEmoji'] ?? json['gift_emoji'] ?? '🎁',
      giftPrice: (json['giftPrice'] ?? json['gift_price'] ?? 0).toDouble(),
      comboCount: json['comboCount'] ?? json['combo_count'] ?? 1,
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'giftId': giftId,
      'senderId': senderId,
      'senderName': senderName,
      'senderImage': senderImage,
      'senderIsVerified': senderIsVerified,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'giftName': giftName,
      'giftEmoji': giftEmoji,
      'giftPrice': giftPrice,
      'comboCount': comboCount,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

class GiftComboEvent extends WebSocketEvent {
  final String comboId;
  final String senderId;
  final String senderName;
  final String giftEmoji;
  final int totalCount;
  final double totalPrice;

  const GiftComboEvent({
    required this.comboId,
    required this.senderId,
    required this.senderName,
    required this.giftEmoji,
    required this.totalCount,
    required this.totalPrice,
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.giftCombo);

  factory GiftComboEvent.fromJson(Map<String, dynamic> json) {
    return GiftComboEvent(
      comboId: json['comboId'] ?? json['combo_id'] ?? '',
      senderId: json['senderId'] ?? json['sender_id'] ?? '',
      senderName: json['senderName'] ?? json['sender_name'] ?? '',
      giftEmoji: json['giftEmoji'] ?? json['gift_emoji'] ?? '🎁',
      totalCount: json['totalCount'] ?? json['total_count'] ?? 1,
      totalPrice: (json['totalPrice'] ?? json['total_price'] ?? 0).toDouble(),
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'comboId': comboId,
      'senderId': senderId,
      'senderName': senderName,
      'giftEmoji': giftEmoji,
      'totalCount': totalCount,
      'totalPrice': totalPrice,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

// ============================================
// PRODUCT EVENTS
// ============================================

class ProductAddedEvent extends WebSocketEvent {
  final String productId;
  final String productName;
  final String productImageUrl;
  final double productPrice;

  const ProductAddedEvent({
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.productPrice,
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.productAdded);

  factory ProductAddedEvent.fromJson(Map<String, dynamic> json) {
    return ProductAddedEvent(
      productId: json['productId'] ?? json['product_id'] ?? '',
      productName: json['productName'] ?? json['product_name'] ?? '',
      productImageUrl: json['productImageUrl'] ?? json['product_image_url'] ?? '',
      productPrice: (json['productPrice'] ?? json['product_price'] ?? 0).toDouble(),
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'productPrice': productPrice,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

class ProductRemovedEvent extends WebSocketEvent {
  final String productId;

  const ProductRemovedEvent({
    required this.productId,
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.productRemoved);

  factory ProductRemovedEvent.fromJson(Map<String, dynamic> json) {
    return ProductRemovedEvent(
      productId: json['productId'] ?? json['product_id'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'productId': productId,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

class ProductPinnedEvent extends WebSocketEvent {
  final String productId;
  final String productName;
  final double productPrice;

  const ProductPinnedEvent({
    required this.productId,
    required this.productName,
    required this.productPrice,
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.productPinned);

  factory ProductPinnedEvent.fromJson(Map<String, dynamic> json) {
    return ProductPinnedEvent(
      productId: json['productId'] ?? json['product_id'] ?? '',
      productName: json['productName'] ?? json['product_name'] ?? '',
      productPrice: (json['productPrice'] ?? json['product_price'] ?? 0).toDouble(),
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'productId': productId,
      'productName': productName,
      'productPrice': productPrice,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

class ProductUnpinnedEvent extends WebSocketEvent {
  final String productId;

  const ProductUnpinnedEvent({
    required this.productId,
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.productUnpinned);

  factory ProductUnpinnedEvent.fromJson(Map<String, dynamic> json) {
    return ProductUnpinnedEvent(
      productId: json['productId'] ?? json['product_id'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'productId': productId,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

// ============================================
// STREAM CONTROL EVENTS
// ============================================

class StreamStartedEvent extends WebSocketEvent {
  final String liveStreamId;
  final String hostId;
  final String hostName;
  final String title;

  const StreamStartedEvent({
    required this.liveStreamId,
    required this.hostId,
    required this.hostName,
    required this.title,
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.streamStarted);

  factory StreamStartedEvent.fromJson(Map<String, dynamic> json) {
    return StreamStartedEvent(
      liveStreamId: json['liveStreamId'] ?? json['live_stream_id'] ?? '',
      hostId: json['hostId'] ?? json['host_id'] ?? '',
      hostName: json['hostName'] ?? json['host_name'] ?? '',
      title: json['title'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'liveStreamId': liveStreamId,
      'hostId': hostId,
      'hostName': hostName,
      'title': title,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

class StreamEndedEvent extends WebSocketEvent {
  final String liveStreamId;
  final int totalViewers;
  final int peakViewers;
  final double totalRevenue;
  final String durationText;

  const StreamEndedEvent({
    required this.liveStreamId,
    required this.totalViewers,
    required this.peakViewers,
    required this.totalRevenue,
    required this.durationText,
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.streamEnded);

  factory StreamEndedEvent.fromJson(Map<String, dynamic> json) {
    return StreamEndedEvent(
      liveStreamId: json['liveStreamId'] ?? json['live_stream_id'] ?? '',
      totalViewers: json['totalViewers'] ?? json['total_viewers'] ?? 0,
      peakViewers: json['peakViewers'] ?? json['peak_viewers'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? json['total_revenue'] ?? 0).toDouble(),
      durationText: json['durationText'] ?? json['duration_text'] ?? '0:00',
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'liveStreamId': liveStreamId,
      'totalViewers': totalViewers,
      'peakViewers': peakViewers,
      'totalRevenue': totalRevenue,
      'durationText': durationText,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

class StreamPausedEvent extends WebSocketEvent {
  final String liveStreamId;

  const StreamPausedEvent({
    required this.liveStreamId,
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.streamPaused);

  factory StreamPausedEvent.fromJson(Map<String, dynamic> json) {
    return StreamPausedEvent(
      liveStreamId: json['liveStreamId'] ?? json['live_stream_id'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'liveStreamId': liveStreamId,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

class StreamResumedEvent extends WebSocketEvent {
  final String liveStreamId;

  const StreamResumedEvent({
    required this.liveStreamId,
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.streamResumed);

  factory StreamResumedEvent.fromJson(Map<String, dynamic> json) {
    return StreamResumedEvent(
      liveStreamId: json['liveStreamId'] ?? json['live_stream_id'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'liveStreamId': liveStreamId,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

// ============================================
// MODERATION EVENTS
// ============================================

class UserBlockedEvent extends WebSocketEvent {
  final String userId;
  final String userName;
  final String blockedBy;
  final String reason;

  const UserBlockedEvent({
    required this.userId,
    required this.userName,
    required this.blockedBy,
    required this.reason,
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.userBlocked);

  factory UserBlockedEvent.fromJson(Map<String, dynamic> json) {
    return UserBlockedEvent(
      userId: json['userId'] ?? json['user_id'] ?? '',
      userName: json['userName'] ?? json['user_name'] ?? '',
      blockedBy: json['blockedBy'] ?? json['blocked_by'] ?? '',
      reason: json['reason'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'userId': userId,
      'userName': userName,
      'blockedBy': blockedBy,
      'reason': reason,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

class UserUnblockedEvent extends WebSocketEvent {
  final String userId;
  final String userName;
  final String unblockedBy;

  const UserUnblockedEvent({
    required this.userId,
    required this.userName,
    required this.unblockedBy,
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.userUnblocked);

  factory UserUnblockedEvent.fromJson(Map<String, dynamic> json) {
    return UserUnblockedEvent(
      userId: json['userId'] ?? json['user_id'] ?? '',
      userName: json['userName'] ?? json['user_name'] ?? '',
      unblockedBy: json['unblockedBy'] ?? json['unblocked_by'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'userId': userId,
      'userName': userName,
      'unblockedBy': unblockedBy,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

class UserPromotedEvent extends WebSocketEvent {
  final String userId;
  final String userName;
  final String promotedBy;
  final String newRole;

  const UserPromotedEvent({
    required this.userId,
    required this.userName,
    required this.promotedBy,
    required this.newRole,
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.userPromoted);

  factory UserPromotedEvent.fromJson(Map<String, dynamic> json) {
    return UserPromotedEvent(
      userId: json['userId'] ?? json['user_id'] ?? '',
      userName: json['userName'] ?? json['user_name'] ?? '',
      promotedBy: json['promotedBy'] ?? json['promoted_by'] ?? '',
      newRole: json['newRole'] ?? json['new_role'] ?? 'moderator',
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'userId': userId,
      'userName': userName,
      'promotedBy': promotedBy,
      'newRole': newRole,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

class UserDemotedEvent extends WebSocketEvent {
  final String userId;
  final String userName;
  final String demotedBy;

  const UserDemotedEvent({
    required this.userId,
    required this.userName,
    required this.demotedBy,
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.userDemoted);

  factory UserDemotedEvent.fromJson(Map<String, dynamic> json) {
    return UserDemotedEvent(
      userId: json['userId'] ?? json['user_id'] ?? '',
      userName: json['userName'] ?? json['user_name'] ?? '',
      demotedBy: json['demotedBy'] ?? json['demoted_by'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'userId': userId,
      'userName': userName,
      'demotedBy': demotedBy,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

// ============================================
// SYSTEM EVENTS
// ============================================

class AnnouncementEvent extends WebSocketEvent {
  final String message;
  final String? title;
  final String severity; // 'info', 'warning', 'error'

  const AnnouncementEvent({
    required this.message,
    this.title,
    this.severity = 'info',
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.announcement);

  factory AnnouncementEvent.fromJson(Map<String, dynamic> json) {
    return AnnouncementEvent(
      message: json['message'] ?? '',
      title: json['title'],
      severity: json['severity'] ?? 'info',
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'message': message,
      'title': title,
      'severity': severity,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

class NotificationEvent extends WebSocketEvent {
  final String message;
  final String? actionUrl;
  final String notificationType;

  const NotificationEvent({
    required this.message,
    this.actionUrl,
    this.notificationType = 'general',
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.notification);

  factory NotificationEvent.fromJson(Map<String, dynamic> json) {
    return NotificationEvent(
      message: json['message'] ?? '',
      actionUrl: json['actionUrl'] ?? json['action_url'],
      notificationType: json['notificationType'] ?? json['notification_type'] ?? 'general',
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'message': message,
      'actionUrl': actionUrl,
      'notificationType': notificationType,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

class HeartbeatEvent extends WebSocketEvent {
  final String sessionId;

  const HeartbeatEvent({
    required this.sessionId,
    required super.timestamp,
    super.metadata,
  }) : super(type: WebSocketEventType.heartbeat);

  factory HeartbeatEvent.fromJson(Map<String, dynamic> json) {
    return HeartbeatEvent(
      sessionId: json['sessionId'] ?? json['session_id'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'sessionId': sessionId,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

// ============================================
// HELPER CLASSES
// ============================================

// WebSocket message wrapper (for sending/receiving)
class WebSocketMessage {
  final WebSocketEvent event;
  final String liveStreamId;

  const WebSocketMessage({
    required this.event,
    required this.liveStreamId,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      event: WebSocketEvent.fromJson(json['event'] ?? json),
      liveStreamId: json['liveStreamId'] ?? json['live_stream_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event': event.toJson(),
      'liveStreamId': liveStreamId,
    };
  }
}

// WebSocket connection state
enum WebSocketConnectionState {
  connecting,
  connected,
  disconnected,
  reconnecting,
  failed;

  String get displayName {
    switch (this) {
      case WebSocketConnectionState.connecting:
        return 'Connecting...';
      case WebSocketConnectionState.connected:
        return 'Connected';
      case WebSocketConnectionState.disconnected:
        return 'Disconnected';
      case WebSocketConnectionState.reconnecting:
        return 'Reconnecting...';
      case WebSocketConnectionState.failed:
        return 'Connection Failed';
    }
  }

  bool get isConnected => this == WebSocketConnectionState.connected;
  bool get isDisconnected => this == WebSocketConnectionState.disconnected;
  bool get isConnecting => this == WebSocketConnectionState.connecting || this == WebSocketConnectionState.reconnecting;
}
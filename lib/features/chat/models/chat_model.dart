import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';

class ChatModel {
  final String id;
  final String contactUID;
  final String contactName;
  final String contactImage;
  final String lastMessage;
  final MessageEnum lastMessageType;
  final String lastMessageTime;
  final int unreadCount;
  final bool isGroup;
  final String? groupId;

  ChatModel({
    required this.id,
    required this.contactUID,
    required this.contactName,
    required this.contactImage,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastMessageTime,
    required this.unreadCount,
    this.isGroup = false,
    this.groupId,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'] ?? '',
      contactUID: map[Constants.contactUID] ?? '',
      contactName: map[Constants.contactName] ?? '',
      contactImage: map[Constants.contactImage] ?? '',
      lastMessage: map[Constants.lastMessage] ?? '',
      lastMessageType: (map[Constants.messageType] as String? ?? 'text').toMessageEnum(),
      lastMessageTime: map[Constants.timeSent] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      unreadCount: map['unreadCount'] ?? 0,
      isGroup: map['isGroup'] ?? false,
      groupId: map[Constants.groupId],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      Constants.contactUID: contactUID,
      Constants.contactName: contactName,
      Constants.contactImage: contactImage,
      Constants.lastMessage: lastMessage,
      Constants.messageType: lastMessageType.name,
      Constants.timeSent: lastMessageTime,
      'unreadCount': unreadCount,
      'isGroup': isGroup,
      Constants.groupId: groupId,
    };
  }

  ChatModel copyWith({
    String? id,
    String? contactUID,
    String? contactName,
    String? contactImage,
    String? lastMessage,
    MessageEnum? lastMessageType,
    String? lastMessageTime,
    int? unreadCount,
    bool? isGroup,
    String? groupId,
  }) {
    return ChatModel(
      id: id ?? this.id,
      contactUID: contactUID ?? this.contactUID,
      contactName: contactName ?? this.contactName,
      contactImage: contactImage ?? this.contactImage,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isGroup: isGroup ?? this.isGroup,
      groupId: groupId ?? this.groupId,
    );
  }
}
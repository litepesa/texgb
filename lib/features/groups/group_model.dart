import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';

class GroupModel {
  String creatorUID;
  String groupName;
  String groupDescription;
  String groupImage;
  String groupId;
  String lastMessage;
  String senderUID;
  MessageEnum messageType;
  String messageId;
  DateTime timeSent;
  DateTime createdAt;
  bool onlyAdminsCanSendMessages;
  bool onlyAdminsCanEditInfo;
  List<String> membersUIDs;
  List<String> adminsUIDs;

  GroupModel({
    required this.creatorUID,
    required this.groupName,
    required this.groupDescription,
    required this.groupImage,
    required this.groupId,
    required this.lastMessage,
    required this.senderUID,
    required this.messageType,
    required this.messageId,
    required this.timeSent,
    required this.createdAt,
    required this.onlyAdminsCanSendMessages,
    required this.onlyAdminsCanEditInfo,
    required this.membersUIDs,
    required this.adminsUIDs,
  });

  // to map
  Map<String, dynamic> toMap() {
    return {
      Constants.creatorUID: creatorUID,
      Constants.groupName: groupName,
      Constants.groupDescription: groupDescription,
      Constants.groupImage: groupImage,
      Constants.groupId: groupId,
      Constants.lastMessage: lastMessage,
      Constants.senderUID: senderUID,
      Constants.messageType: messageType.name,
      Constants.messageId: messageId,
      Constants.timeSent: timeSent.millisecondsSinceEpoch,
      Constants.createdAt: createdAt.millisecondsSinceEpoch,
      Constants.lockMessages: onlyAdminsCanSendMessages,
      Constants.editSettings: onlyAdminsCanEditInfo,
      Constants.membersUIDs: membersUIDs,
      Constants.adminsUIDs: adminsUIDs,
    };
  }

  // from map
  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      creatorUID: map[Constants.creatorUID] ?? '',
      groupName: map[Constants.groupName] ?? '',
      groupDescription: map[Constants.groupDescription] ?? '',
      groupImage: map[Constants.groupImage] ?? '',
      groupId: map[Constants.groupId] ?? '',
      lastMessage: map[Constants.lastMessage] ?? '',
      senderUID: map[Constants.senderUID] ?? '',
      messageType: map[Constants.messageType].toString().toMessageEnum(),
      messageId: map[Constants.messageId] ?? '',
      timeSent: DateTime.fromMillisecondsSinceEpoch(
          map[Constants.timeSent] ?? DateTime.now().millisecondsSinceEpoch),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map[Constants.createdAt] ?? DateTime.now().millisecondsSinceEpoch),
      onlyAdminsCanSendMessages: map[Constants.lockMessages] ?? false,
      onlyAdminsCanEditInfo: map[Constants.editSettings] ?? true,
      membersUIDs: List<String>.from(map[Constants.membersUIDs] ?? []),
      adminsUIDs: List<String>.from(map[Constants.adminsUIDs] ?? []),
    );
  }
}
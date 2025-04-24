import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/chat/chat_provider.dart';
import 'package:textgb/features/status/status_model.dart';
import 'package:textgb/models/message_model.dart';
import 'package:textgb/models/user_model.dart';
import 'package:uuid/uuid.dart';

class StatusReplyHandler {
  /// Handles a reply to a status by sending a regular message to the status owner's chat
  /// This makes status replies appear in the normal chat thread, similar to WhatsApp
  static Future<void> replyToStatus({
    required BuildContext context,
    required StatusModel status,
    required StatusItemModel statusItem,
    required String message,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    try {
      final currentUser = context.read<AuthenticationProvider>().userModel!;
      final chatProvider = context.read<ChatProvider>();
      
      // Make sure we're not replying to our own status
      if (status.uid == currentUser.uid) {
        onError("You cannot reply to your own status");
        return;
      }
      
      // Set loading
      chatProvider.setLoading(true);
      
      final messageId = const Uuid().v4();
      
      // Create context text indicating this is a status reply
      final String statusContext = "Replied to ${status.userName}'s status";
      
      // Prepare the message model
      final messageModel = MessageModel(
        senderUID: currentUser.uid,
        senderName: currentUser.name,
        senderImage: currentUser.image,
        contactUID: status.uid,
        message: message,
        messageType: MessageEnum.text,
        timeSent: DateTime.now(),
        messageId: messageId,
        isSeen: false,
        repliedMessage: statusItem.mediaUrl,
        repliedTo: status.userName,
        repliedMessageType: statusItem.type.toMessageEnum(),
        reactions: [],
        isSeenBy: [currentUser.uid],
        deletedBy: [],
      );
      
      // Send the message using the regular chat provider
      await chatProvider.handleContactMessage(
        messageModel: messageModel,
        contactUID: status.uid,
        contactName: status.userName,
        contactImage: status.userImage,
        onSucess: () {
          chatProvider.setLoading(false);
          onSuccess();
        },
        onError: (error) {
          chatProvider.setLoading(false);
          onError(error);
        },
      );
      
      // Also store a reference in the status replies collection for tracking
      // (this is for backward compatibility and analytics)
      await _storeStatusReplyReference(
        currentUser: currentUser,
        status: status,
        statusItem: statusItem,
        message: message,
        messageId: messageId,
      );
    } catch (e) {
      context.read<ChatProvider>().setLoading(false);
      onError("Error sending reply: $e");
    }
  }
  
  // Private method to store a reference to the status reply for analytics
  static Future<void> _storeStatusReplyReference({
    required UserModel currentUser,
    required StatusModel status,
    required StatusItemModel statusItem,
    required String message,
    required String messageId,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final replyId = const Uuid().v4();
      
      final replyData = {
        'replyId': replyId,
        'messageId': messageId,
        'statusId': status.statusId,
        'statusItemId': statusItem.itemId,
        'statusOwnerId': status.uid,
        'senderId': currentUser.uid,
        'senderName': currentUser.name,
        'senderImage': currentUser.image,
        'message': message,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isRead': false,
        'statusType': statusItem.type.name,
        'statusThumbnailUrl': statusItem.mediaUrl,
        'statusCaption': statusItem.caption ?? '',
      };
      
      // Store in the status owner's collection
      await firestore
          .collection(Constants.statusReplies)
          .doc(status.uid)
          .collection('replies')
          .doc(replyId)
          .set(replyData);
      
      // Also store in sender's sent collection
      await firestore
          .collection(Constants.statusReplies)
          .doc(currentUser.uid)
          .collection('sent')
          .doc(replyId)
          .set(replyData);
    } catch (e) {
      debugPrint("Error storing status reply reference: $e");
      // Don't throw - this is a background operation and shouldn't block the UI
    }
  }
  
  /// Navigate to chat with the status owner
  static void navigateToChatWithStatusOwner({
    required BuildContext context,
    required StatusModel status,
  }) {
    Navigator.pushNamed(
      context,
      Constants.chatScreen,
      arguments: {
        Constants.contactUID: status.uid,
        Constants.contactName: status.userName,
        Constants.contactImage: status.userImage,
        Constants.groupId: '',
      },
    );
  }
}
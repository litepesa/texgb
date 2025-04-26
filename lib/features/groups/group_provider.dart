import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/groups/group_model.dart';
import 'package:textgb/models/message_model.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:uuid/uuid.dart';

class GroupProvider extends ChangeNotifier {
  bool _isLoading = false;
  
  GroupModel _groupModel = GroupModel(
    creatorUID: '',
    groupName: '',
    groupDescription: '',
    groupImage: '',
    groupId: '',
    lastMessage: '',
    senderUID: '',
    messageType: MessageEnum.text,
    messageId: '',
    timeSent: DateTime.now(),
    createdAt: DateTime.now(),
    onlyAdminsCanSendMessages: false,
    onlyAdminsCanEditInfo: true,
    membersUIDs: [],
    adminsUIDs: [],
  );
  
  final List<UserModel> _groupMembersList = [];
  final List<UserModel> _groupAdminsList = [];

  // getters
  bool get isLoading => _isLoading;
  GroupModel get groupModel => _groupModel;
  List<UserModel> get groupMembersList => _groupMembersList;
  List<UserModel> get groupAdminsList => _groupAdminsList;

  // firebase initialization
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // setters
  void setIsLoading({required bool value}) {
    _isLoading = value;
    notifyListeners();
  }

  void setOnlyAdminsCanEditInfo({required bool value}) {
    _groupModel.onlyAdminsCanEditInfo = value;
    notifyListeners();
    
    // return if groupID is empty - meaning we are creating a new group
    if (_groupModel.groupId.isEmpty) return;
    updateGroupDataInFireStore();
  }

  void setOnlyAdminsCanSendMessages({required bool value}) {
    _groupModel.onlyAdminsCanSendMessages = value;
    notifyListeners();
    
    // return if groupID is empty - meaning we are creating a new group
    if (_groupModel.groupId.isEmpty) return;
    updateGroupDataInFireStore();
  }

  // update group settings in firestore
  Future<void> updateGroupDataInFireStore() async {
    try {
      await _firestore
          .collection(Constants.groups)
          .doc(_groupModel.groupId)
          .update(groupModel.toMap());
    } catch (e) {
      debugPrint('Error updating group data: ${e.toString()}');
    }
  }

  // add a group member
  void addMemberToGroup({required UserModel groupMember}) {
    if (!_groupMembersList.contains(groupMember)) {
      _groupMembersList.add(groupMember);
      _groupModel.membersUIDs.add(groupMember.uid);
      notifyListeners();

      // return if groupID is empty - meaning we are creating a new group
      if (_groupModel.groupId.isEmpty) return;
      updateGroupDataInFireStore();
    }
  }

  // add a member as an admin
  void addMemberToAdmins({required UserModel groupAdmin}) {
    if (!_groupAdminsList.contains(groupAdmin)) {
      _groupAdminsList.add(groupAdmin);
      _groupModel.adminsUIDs.add(groupAdmin.uid);
      notifyListeners();

      // return if groupID is empty - meaning we are creating a new group
      if (_groupModel.groupId.isEmpty) return;
      updateGroupDataInFireStore();
    }
  }

  Future<void> setGroupModel({required GroupModel groupModel}) async {
    _groupModel = groupModel;
    notifyListeners();
  }

  // remove member from group
  Future<void> removeGroupMember({required UserModel groupMember}) async {
    _groupMembersList.removeWhere((member) => member.uid == groupMember.uid);
    // also remove this member from admins list if they are an admin
    _groupAdminsList.removeWhere((admin) => admin.uid == groupMember.uid);
    _groupModel.membersUIDs.remove(groupMember.uid);
    _groupModel.adminsUIDs.remove(groupMember.uid);
    notifyListeners();

    // return if groupID is empty - meaning we are creating a new group
    if (_groupModel.groupId.isEmpty) return;
    updateGroupDataInFireStore();
  }

  // remove admin from group but keep as member
  void removeGroupAdmin({required UserModel groupAdmin}) {
    _groupAdminsList.removeWhere((admin) => admin.uid == groupAdmin.uid);
    _groupModel.adminsUIDs.remove(groupAdmin.uid);
    notifyListeners();

    // return if groupID is empty - meaning we are creating a new group
    if (_groupModel.groupId.isEmpty) return;
    updateGroupDataInFireStore();
  }

  // get a list of group members data from firestore
  Future<List<UserModel>> getGroupMembersDataFromFirestore({
    required bool isAdmin,
  }) async {
    try {
      List<UserModel> membersData = [];

      // get the list of membersUIDs
      List<String> membersUIDs = 
          isAdmin ? _groupModel.adminsUIDs : _groupModel.membersUIDs;

      for (var uid in membersUIDs) {
        var user = await _firestore.collection(Constants.users).doc(uid).get();
        if (user.exists) {
          membersData.add(UserModel.fromMap(user.data()!));
        }
      }

      return membersData;
    } catch (e) {
      debugPrint('Error fetching group members: ${e.toString()}');
      return [];
    }
  }

  // update the groupMembersList
  Future<void> updateGroupMembersList() async {
    _groupMembersList.clear();
    _groupMembersList.addAll(
        await getGroupMembersDataFromFirestore(isAdmin: false));
    notifyListeners();
  }

  // update the groupAdminsList
  Future<void> updateGroupAdminsList() async {
    _groupAdminsList.clear();
    _groupAdminsList.addAll(
        await getGroupMembersDataFromFirestore(isAdmin: true));
    notifyListeners();
  }

  // clear group model and lists
  Future<void> clearGroupData() async {
    _groupMembersList.clear();
    _groupAdminsList.clear();
    _groupModel = GroupModel(
      creatorUID: '',
      groupName: '',
      groupDescription: '',
      groupImage: '',
      groupId: '',
      lastMessage: '',
      senderUID: '',
      messageType: MessageEnum.text,
      messageId: '',
      timeSent: DateTime.now(),
      createdAt: DateTime.now(),
      onlyAdminsCanSendMessages: false,
      onlyAdminsCanEditInfo: true,
      membersUIDs: [],
      adminsUIDs: [],
    );
    notifyListeners();
  }

  // get a list UIDs from group members list
  List<String> getGroupMembersUIDs() {
    return _groupMembersList.map((e) => e.uid).toList();
  }

  // get a list UIDs from group admins list
  List<String> getGroupAdminsUIDs() {
    return _groupAdminsList.map((e) => e.uid).toList();
  }

  // stream group data
  Stream<DocumentSnapshot> groupStream({required String groupId}) {
    return _firestore.collection(Constants.groups).doc(groupId).snapshots();
  }

  // stream users data from fireStore
  Stream<List<DocumentSnapshot>> streamGroupMembersData({
    required List<String> membersUIDs,
  }) {
    return Stream.fromFuture(Future.wait<DocumentSnapshot>(
      membersUIDs.map<Future<DocumentSnapshot>>((uid) async {
        return await _firestore.collection(Constants.users).doc(uid).get();
      }),
    ));
  }

  // create group
  Future<void> createGroup({
    required GroupModel newGroupModel,
    required File? fileImage,
    required Function onSuccess,
    required Function(String) onFail,
  }) async {
    setIsLoading(value: true);

    try {
      var groupId = const Uuid().v4();
      newGroupModel.groupId = groupId;

      // check if the file image is null
      if (fileImage != null) {
        // upload image to firebase storage
        final String imageUrl = await storeFileToStorage(
            file: fileImage, reference: '${Constants.groupImages}/$groupId');
        newGroupModel.groupImage = imageUrl;
      }

      // add the group admins
      newGroupModel.adminsUIDs = [
        newGroupModel.creatorUID,
        ...getGroupAdminsUIDs()
      ];

      // add the group members
      newGroupModel.membersUIDs = [
        newGroupModel.creatorUID,
        ...getGroupMembersUIDs()
      ];

      // update the global groupModel
      setGroupModel(groupModel: newGroupModel);

      // add group to firebase
      await _firestore
          .collection(Constants.groups)
          .doc(groupId)
          .set(groupModel.toMap());

      // set loading
      setIsLoading(value: false);
      // set onSuccess
      onSuccess();
    } catch (e) {
      setIsLoading(value: false);
      onFail(e.toString());
    }
  }

  // get all user groups
  Stream<List<GroupModel>> getUserGroupsStream({required String userId}) {
    return _firestore
        .collection(Constants.groups)
        .where(Constants.membersUIDs, arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      List<GroupModel> groups = [];
      for (var doc in snapshot.docs) {
        groups.add(GroupModel.fromMap(doc.data()));
      }
      return groups;
    });
  }

  // check if is sender or admin
  bool isSenderOrAdmin({required MessageModel message, required String uid}) {
    if (message.senderUID == uid) {
      return true;
    } else if (_groupModel.adminsUIDs.contains(uid)) {
      return true;
    } else {
      return false;
    }
  }

  // exit group
  Future<void> exitGroup({
    required String uid,
  }) async {
    // check if the user is the admin of the group
    bool isAdmin = _groupModel.adminsUIDs.contains(uid);
    
    // Check if user is the only admin
    bool isOnlyAdmin = _groupModel.adminsUIDs.length == 1 && isAdmin;
    
    // If user is the only admin and there are other members, make someone else admin
    if (isOnlyAdmin && _groupModel.membersUIDs.length > 1) {
      // Find the first non-admin member to promote
      String? newAdminId;
      for (String memberId in _groupModel.membersUIDs) {
        if (memberId != uid) {
          newAdminId = memberId;
          break;
        }
      }
      
      if (newAdminId != null) {
        _groupModel.adminsUIDs.add(newAdminId);
      }
    }

    await _firestore
        .collection(Constants.groups)
        .doc(_groupModel.groupId)
        .update({
      Constants.membersUIDs: FieldValue.arrayRemove([uid]),
      Constants.adminsUIDs: isAdmin ? FieldValue.arrayRemove([uid]) : _groupModel.adminsUIDs,
    });

    // remove the user from group members list
    _groupMembersList.removeWhere((element) => element.uid == uid);
    // remove the user from group members uid
    _groupModel.membersUIDs.remove(uid);
    if (isAdmin) {
      // remove the user from group admins list
      _groupAdminsList.removeWhere((element) => element.uid == uid);
      // remove the user from group admins uid
      _groupModel.adminsUIDs.remove(uid);
    }
    notifyListeners();
  }

  // Get group by ID
  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      final doc = await _firestore.collection(Constants.groups).doc(groupId).get();
      if (!doc.exists) return null;
      return GroupModel.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('Error getting group: $e');
      return null;
    }
  }
  
  // Delete whole group
  Future<void> deleteGroup({required String groupId}) async {
    try {
      await _firestore.collection(Constants.groups).doc(groupId).delete();
      // You might also want to delete all group messages
      await _firestore.collection(Constants.chats).doc(groupId).delete();
      // And delete subcollection of messages
      var messagesRef = _firestore.collection(Constants.chats).doc(groupId).collection(Constants.messages);
      var messagesSnapshot = await messagesRef.get();
      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error deleting group: $e');
    }
  }
  
  // Update group info (name, description, image)
  Future<void> updateGroupInfo({
    String? groupName,
    String? groupDescription,
    File? groupImage,
  }) async {
    try {
      setIsLoading(value: true);
      
      Map<String, dynamic> updateData = {};
      
      if (groupName != null && groupName.isNotEmpty) {
        updateData[Constants.groupName] = groupName;
        _groupModel.groupName = groupName;
      }
      
      if (groupDescription != null && groupDescription.isNotEmpty) {
        updateData[Constants.groupDescription] = groupDescription;
        _groupModel.groupDescription = groupDescription;
      }
      
      if (groupImage != null) {
        final String imageUrl = await storeFileToStorage(
          file: groupImage, 
          reference: '${Constants.groupImages}/${_groupModel.groupId}'
        );
        updateData[Constants.groupImage] = imageUrl;
        _groupModel.groupImage = imageUrl;
      }
      
      if (updateData.isNotEmpty) {
        await _firestore
            .collection(Constants.groups)
            .doc(_groupModel.groupId)
            .update(updateData);
      }
      
      setIsLoading(value: false);
      notifyListeners();
    } catch (e) {
      setIsLoading(value: false);
      debugPrint('Error updating group info: $e');
    }
  }
}
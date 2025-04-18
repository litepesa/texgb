import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/utilities/global_methods.dart';

class AuthenticationProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isSuccessful = false;
  String? _uid;
  String? _phoneNumber;
  UserModel? _userModel;

  bool get isLoading => _isLoading;
  bool get isSuccessful => _isSuccessful;
  String? get uid => _uid;
  String? get phoneNumber => _phoneNumber;
  UserModel? get userModel => _userModel;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // check authentication state
  Future<bool> checkAuthenticationState() async {
    bool isSignedIn = false;
    await Future.delayed(const Duration(seconds: 2));

    if (_auth.currentUser != null) {
      _uid = _auth.currentUser!.uid;
      // get user data from firestore
      await getUserDataFromFireStore();

      // save user data to shared preferences
      await saveUserDataToSharedPreferences();

      notifyListeners();

      isSignedIn = true;
    } else {
      isSignedIn = false;
    }

    return isSignedIn;
  }

  // check if user exists
  Future<bool> checkUserExists() async {
    DocumentSnapshot documentSnapshot =
        await _firestore.collection(Constants.users).doc(_uid).get();
    if (documentSnapshot.exists) {
      return true;
    } else {
      return false;
    }
  }

  // update user status
  Future<void> updateUserStatus({required bool value}) async {
    await _firestore
        .collection(Constants.users)
        .doc(_auth.currentUser!.uid)
        .update({Constants.isOnline: value});
  }

  // get user data from firestore
  Future<void> getUserDataFromFireStore() async {
    DocumentSnapshot documentSnapshot =
        await _firestore.collection(Constants.users).doc(_uid).get();
    _userModel =
        UserModel.fromMap(documentSnapshot.data() as Map<String, dynamic>);
    notifyListeners();
  }

  // save user data to shared preferences
  Future<void> saveUserDataToSharedPreferences() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString(
        Constants.userModel, jsonEncode(userModel!.toMap()));
  }

  // get data from shared preferences
  Future<void> getUserDataFromSharedPreferences() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String userModelString =
        sharedPreferences.getString(Constants.userModel) ?? '';
    _userModel = UserModel.fromMap(jsonDecode(userModelString));
    _uid = _userModel!.uid;
    notifyListeners();
  }

  // sign in with phone number
  Future<void> signInWithPhoneNumber({
    required String phoneNumber,
    required BuildContext context,
  }) async {
    _isLoading = true;
    notifyListeners();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential).then((value) async {
          _uid = value.user!.uid;
          _phoneNumber = value.user!.phoneNumber;
          _isSuccessful = true;
          _isLoading = false;
          notifyListeners();
        });
      },
      verificationFailed: (FirebaseAuthException e) {
        _isSuccessful = false;
        _isLoading = false;
        notifyListeners();
        showSnackBar(context, e.toString());
      },
      codeSent: (String verificationId, int? resendToken) async {
        _isLoading = false;
        notifyListeners();
        // navigate to otp screen
        Navigator.of(context).pushNamed(
          Constants.otpScreen,
          arguments: {
            Constants.verificationId: verificationId,
            Constants.phoneNumber: phoneNumber,
          },
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // verify otp code
  Future<void> verifyOTPCode({
    required String verificationId,
    required String otpCode,
    required BuildContext context,
    required Function onSuccess,
  }) async {
    _isLoading = true;
    notifyListeners();

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otpCode,
    );

    await _auth.signInWithCredential(credential).then((value) async {
      _uid = value.user!.uid;
      _phoneNumber = value.user!.phoneNumber;
      _isSuccessful = true;
      _isLoading = false;
      onSuccess();
      notifyListeners();
    }).catchError((e) {
      _isSuccessful = false;
      _isLoading = false;
      notifyListeners();
      showSnackBar(context, e.toString());
    });
  }

  // save user data to firestore
  void saveUserDataToFireStore({
    required UserModel userModel,
    required File? fileImage,
    required Function onSuccess,
    required Function onFail,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (fileImage != null) {
        // upload image to storage
        String imageUrl = await storeFileToStorage(
            file: fileImage,
            reference: '${Constants.userImages}/${userModel.uid}');

        userModel.image = imageUrl;
      }

      userModel.lastSeen = DateTime.now().microsecondsSinceEpoch.toString();
      userModel.createdAt = DateTime.now().microsecondsSinceEpoch.toString();

      _userModel = userModel;
      _uid = userModel.uid;

      // save user data to firestore
      await _firestore
          .collection(Constants.users)
          .doc(userModel.uid)
          .set(userModel.toMap());

      _isLoading = false;
      onSuccess();
      notifyListeners();
    } on FirebaseException catch (e) {
      _isLoading = false;
      notifyListeners();
      onFail(e.toString());
    }
  }

  // get user stream
  Stream<DocumentSnapshot> userStream({required String userID}) {
    return _firestore.collection(Constants.users).doc(userID).snapshots();
  }

  // get all users stream
  Stream<QuerySnapshot> getAllUsersStream({required String userID}) {
    return _firestore
        .collection(Constants.users)
        .where(Constants.uid, isNotEqualTo: userID)
        .snapshots();
  }

  // Add contact to user's contacts
  Future<void> addContact({
    required String contactID,
  }) async {
    try {
      // Add contact to user's contacts list
      await _firestore.collection(Constants.users).doc(_uid).update({
        Constants.contactsUIDs: FieldValue.arrayUnion([contactID]),
      });
      
      // Update local model
      _userModel!.contactsUIDs.add(contactID);
      notifyListeners();
    } on FirebaseException catch (e) {
      debugPrint(e.toString());
    }
  }

  // Remove contact from user's contacts
  Future<void> removeContact({required String contactID}) async {
    try {
      // Remove contact from user's contacts list
      await _firestore.collection(Constants.users).doc(_uid).update({
        Constants.contactsUIDs: FieldValue.arrayRemove([contactID]),
      });
      
      // Update local model
      _userModel!.contactsUIDs.remove(contactID);
      notifyListeners();
    } on FirebaseException catch (e) {
      debugPrint(e.toString());
    }
  }

  // Block a contact
  Future<void> blockContact({required String contactID}) async {
    try {
      // Add contact to blocked list
      await _firestore.collection(Constants.users).doc(_uid).update({
        Constants.blockedUIDs: FieldValue.arrayUnion([contactID]),
      });
      
      // Update local model
      _userModel!.blockedUIDs.add(contactID);
      notifyListeners();
    } on FirebaseException catch (e) {
      debugPrint(e.toString());
    }
  }

  // Unblock a contact
  Future<void> unblockContact({required String contactID}) async {
    try {
      // Remove contact from blocked list
      await _firestore.collection(Constants.users).doc(_uid).update({
        Constants.blockedUIDs: FieldValue.arrayRemove([contactID]),
      });
      
      // Update local model
      _userModel!.blockedUIDs.remove(contactID);
      notifyListeners();
    } on FirebaseException catch (e) {
      debugPrint(e.toString());
    }
  }

  // Get a list of contacts
  Future<List<UserModel>> getContactsList(
    String uid,
    List<String> groupMembersUIDs,
  ) async {
    List<UserModel> contactsList = [];

    DocumentSnapshot documentSnapshot =
        await _firestore.collection(Constants.users).doc(uid).get();

    List<dynamic> contactsUIDs = documentSnapshot.get(Constants.contactsUIDs);

    for (String contactUID in contactsUIDs) {
      // If groupMembersUIDs list is not empty and contains the contactUID we skip this contact
      if (groupMembersUIDs.isNotEmpty && groupMembersUIDs.contains(contactUID)) {
        continue;
      }
      DocumentSnapshot documentSnapshot =
          await _firestore.collection(Constants.users).doc(contactUID).get();
      UserModel contact =
          UserModel.fromMap(documentSnapshot.data() as Map<String, dynamic>);
      contactsList.add(contact);
    }

    return contactsList;
  }

  // Get a list of blocked contacts
  Future<List<UserModel>> getBlockedContactsList({
    required String uid,
  }) async {
    List<UserModel> blockedContactsList = [];

    DocumentSnapshot documentSnapshot =
        await _firestore.collection(Constants.users).doc(uid).get();

    List<dynamic> blockedUIDs = documentSnapshot.get(Constants.blockedUIDs);

    for (String blockedUID in blockedUIDs) {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection(Constants.users)
          .doc(blockedUID)
          .get();
      UserModel blockedContact =
          UserModel.fromMap(documentSnapshot.data() as Map<String, dynamic>);
      blockedContactsList.add(blockedContact);
    }

    return blockedContactsList;
  }

  // Search for users by phone number
  Future<UserModel?> searchUserByPhoneNumber({
    required String phoneNumber,
  }) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(Constants.users)
          .where(Constants.phoneNumber, isEqualTo: phoneNumber)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      return UserModel.fromMap(
          querySnapshot.docs.first.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error searching user: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.clear();
    notifyListeners();
  }

  // Add this method to your AuthenticationProvider class in lib/providers/authentication_provider.dart

  // Update user profile data in Firestore
  Future<void> updateUserProfile(UserModel updatedUser) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Update user data in Firestore
      await _firestore
          .collection(Constants.users)
          .doc(updatedUser.uid)
          .update(updatedUser.toMap());

      // Update local user model
      _userModel = updatedUser;

      // Save updated user data to shared preferences
      await saveUserDataToSharedPreferences();

      _isLoading = false;
      notifyListeners();
    } on FirebaseException catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e.toString();
    }
  }

} 
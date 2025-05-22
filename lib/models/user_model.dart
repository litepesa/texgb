import 'package:textgb/constants.dart';

class UserModel {
  String uid;
  String name;
  String phoneNumber;
  String image;
  String token;
  String aboutMe;
  String lastSeen;
  String createdAt;
  List<String> contactsUIDs;  
  List<String> blockedUIDs;
  List<String> statusMutedUsers;
  
  // New payment-related fields
  bool isAccountActivated;
  String? paymentTransactionId;
  String? paymentDate;
  double? amountPaid;

  UserModel({
    required this.uid,
    required this.name,
    required this.phoneNumber,
    required this.image,
    required this.token,
    required this.aboutMe,
    required this.lastSeen,
    required this.createdAt,
    required this.contactsUIDs,
    required this.blockedUIDs,
    this.statusMutedUsers = const [],
    this.isAccountActivated = false,  // Default to false
    this.paymentTransactionId,
    this.paymentDate,
    this.amountPaid,
  });

  // Update factory method
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map[Constants.uid] ?? '',
      name: map[Constants.name] ?? '',
      phoneNumber: map[Constants.phoneNumber] ?? '',
      image: map[Constants.image] ?? '',
      token: map[Constants.token] ?? '',
      aboutMe: map[Constants.aboutMe] ?? '',
      lastSeen: map[Constants.lastSeen] ?? '',
      createdAt: map[Constants.createdAt] ?? '',
      contactsUIDs: List<String>.from(map[Constants.contactsUIDs] ?? []),
      blockedUIDs: List<String>.from(map[Constants.blockedUIDs] ?? []),
      statusMutedUsers: List<String>.from(map[Constants.statusMutedUsers] ?? []),
      isAccountActivated: map[Constants.isAccountActivated] ?? false,
      paymentTransactionId: map[Constants.paymentTransactionId],
      paymentDate: map[Constants.paymentDate],
      amountPaid: map[Constants.amountPaid]?.toDouble(),
    );
  }

  // Update copyWith method
  UserModel copyWith({
    String? uid,
    String? name,
    String? phoneNumber,
    String? image,
    String? token,
    String? aboutMe,
    String? lastSeen,
    String? createdAt,
    List<String>? contactsUIDs,
    List<String>? blockedUIDs,
    List<String>? statusMutedUsers,
    bool? isAccountActivated,
    String? paymentTransactionId,
    String? paymentDate,
    double? amountPaid,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      image: image ?? this.image,
      token: token ?? this.token,
      aboutMe: aboutMe ?? this.aboutMe,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      contactsUIDs: contactsUIDs ?? List<String>.from(this.contactsUIDs),
      blockedUIDs: blockedUIDs ?? List<String>.from(this.blockedUIDs),
      statusMutedUsers: statusMutedUsers ?? List<String>.from(this.statusMutedUsers),
      isAccountActivated: isAccountActivated ?? this.isAccountActivated,
      paymentTransactionId: paymentTransactionId ?? this.paymentTransactionId,
      paymentDate: paymentDate ?? this.paymentDate,
      amountPaid: amountPaid ?? this.amountPaid,
    );
  }

  // Update toMap method
  Map<String, dynamic> toMap() {
    return {
      Constants.uid: uid,
      Constants.name: name,
      Constants.phoneNumber: phoneNumber,
      Constants.image: image,
      Constants.token: token,
      Constants.aboutMe: aboutMe,
      Constants.lastSeen: lastSeen,
      Constants.createdAt: createdAt,
      Constants.contactsUIDs: contactsUIDs,
      Constants.blockedUIDs: blockedUIDs,
      Constants.statusMutedUsers: statusMutedUsers,
      Constants.isAccountActivated: isAccountActivated,
      Constants.paymentTransactionId: paymentTransactionId,
      Constants.paymentDate: paymentDate,
      Constants.amountPaid: amountPaid,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode {
    return uid.hashCode;
  }
}
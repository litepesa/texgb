import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/user_model.dart';
import 'package:permission_handler/permission_handler.dart';

// Result class for contact synchronization
class ContactSyncResult {
  final List<UserModel> registeredContacts;
  final List<Contact> unregisteredContacts;

  ContactSyncResult({
    required this.registeredContacts,
    required this.unregisteredContacts,
  });
}

class ContactsRepository {
  final FirebaseFirestore _firestore;
  
  ContactsRepository({required FirebaseFirestore firestore}) 
      : _firestore = firestore;

  // Get device contacts
  Future<List<Contact>> getDeviceContacts() async {
    // Request contacts permission
    final status = await Permission.contacts.request();
    if (status.isGranted) {
      try {
        // Get all contacts with their phone numbers
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false,
          withThumbnail: false,
          withAccounts: true,
          withGroups: false,
        );
        
        // Filter out contacts without phone numbers
        return contacts.where((contact) => 
          contact.phones.isNotEmpty).toList();
      } catch (e) {
        debugPrint('Error fetching contacts: $e');
        throw Exception('Failed to fetch contacts: $e');
      }
    } else {
      throw Exception('Contacts permission denied');
    }
  }

  // Get single contact details
  Future<Contact?> getContactDetails(String contactId) async {
    try {
      return await FlutterContacts.getContact(contactId);
    } catch (e) {
      debugPrint('Error fetching contact details: $e');
      return null;
    }
  }

  // Standardize phone number format
  String standardizePhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String digits = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // If number doesn't start with +, assume it's a local number and add default country code
    if (!digits.startsWith('+')) {
      // Add your default country code here
      digits = '+1$digits'; // Default to US +1, change as needed
    }
    
    return digits;
  }

  // Search for registered users by phone numbers
  Future<List<UserModel>> findRegisteredUsers(List<String> phoneNumbers) async {
    try {
      List<UserModel> registeredUsers = [];
      
      // Split queries into chunks to avoid large queries
      final chunks = _chunkList(phoneNumbers, 10);
      
      for (final chunk in chunks) {
        final snapshot = await _firestore
            .collection(Constants.users)
            .where(Constants.phoneNumber, whereIn: chunk)
            .get();
            
        final users = snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList();
            
        registeredUsers.addAll(users);
      }
      
      return registeredUsers;
    } catch (e) {
      debugPrint('Error finding registered users: $e');
      throw Exception('Failed to find registered users: $e');
    }
  }

  // Sync phone contacts with Firebase
  Future<ContactSyncResult> syncContactsWithFirebase({
    required List<Contact> deviceContacts,
    required UserModel currentUser,
  }) async {
    try {
      // Extract phone numbers from device contacts
      List<String> contactPhoneNumbers = [];
      Map<String, Contact> phoneToContactMap = {};
      
      for (final contact in deviceContacts) {
        for (final phone in contact.phones) {
          final standardized = standardizePhoneNumber(phone.number);
          contactPhoneNumbers.add(standardized);
          phoneToContactMap[standardized] = contact;
        }
      }
      
      // Find registered users with these phone numbers
      final registeredUsers = await findRegisteredUsers(contactPhoneNumbers);
      
      // Filter out user's own number
      registeredUsers.removeWhere((user) => user.uid == currentUser.uid);
      
      // Create a list of registered and unregistered contacts
      List<Contact> unregisteredContacts = [];
      List<String> registeredPhoneNumbers = registeredUsers.map((user) => user.phoneNumber).toList();
      
      Set<String> processedContactIds = {};
      
      for (final phoneNumber in contactPhoneNumbers) {
        if (!registeredPhoneNumbers.contains(phoneNumber)) {
          final contact = phoneToContactMap[phoneNumber];
          if (contact != null && !processedContactIds.contains(contact.id)) {
            unregisteredContacts.add(contact);
            processedContactIds.add(contact.id);
          }
        }
      }
      
      // Remove duplicates from unregistered contacts
      unregisteredContacts = _removeDuplicateContacts(unregisteredContacts);
      
      // Return the result
      return ContactSyncResult(
        registeredContacts: registeredUsers,
        unregisteredContacts: unregisteredContacts,
      );
    } catch (e) {
      debugPrint('Error syncing contacts: $e');
      throw Exception('Failed to sync contacts: $e');
    }
  }
  
  // Helper method to remove duplicate contacts
  List<Contact> _removeDuplicateContacts(List<Contact> contacts) {
    Map<String, Contact> uniqueContacts = {};
    
    for (var contact in contacts) {
      final key = contact.displayName.toLowerCase();
      if (!uniqueContacts.containsKey(key)) {
        uniqueContacts[key] = contact;
      }
    }
    
    return uniqueContacts.values.toList();
  }
  
  // Helper method to chunk list for batch processing
  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    List<List<T>> chunks = [];
    
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
          i, 
          i + chunkSize > list.length ? list.length : i + chunkSize
        )
      );
    }
    
    return chunks;
  }
}

// Provider for ContactsRepository
final contactsRepositoryProvider = Provider<ContactsRepository>((ref) {
  return ContactsRepository(
    firestore: FirebaseFirestore.instance,
  );
});
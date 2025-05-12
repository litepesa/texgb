import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/user_model.dart';
import 'package:permission_handler/permission_handler.dart';

// Result class for contact synchronization
class ContactSyncResult {
  final List<UserModel> registeredContacts;
  final List<Contact> unregisteredContacts;
  final DateTime syncTime;

  ContactSyncResult({
    required this.registeredContacts,
    required this.unregisteredContacts,
    required this.syncTime,
  });
}

class ContactsRepository {
  final FirebaseFirestore _firestore;
  static const String _lastSyncTimeKey = 'last_contacts_sync_time';
  static const String _registeredContactsKey = 'registered_contacts';
  static const String _unregisteredContactsKey = 'unregistered_contacts';
  
  // Sync frequency constants
  static const Duration syncThreshold = Duration(hours: 6); // Consider contacts stale after 6 hours
  
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

  // Check if sync is needed based on last sync time
  Future<bool> isSyncNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncTimeString = prefs.getString(_lastSyncTimeKey);
    
    if (lastSyncTimeString == null) {
      return true; // Never synced before
    }
    
    final lastSyncTime = DateTime.parse(lastSyncTimeString);
    final now = DateTime.now();
    
    return now.difference(lastSyncTime) > syncThreshold;
  }

  // Load contacts from local storage
  Future<ContactSyncResult?> loadContactsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get last sync time
      final lastSyncTimeString = prefs.getString(_lastSyncTimeKey);
      if (lastSyncTimeString == null) {
        return null; // No saved data
      }
      
      // Get registered contacts
      final registeredContactsJson = prefs.getStringList(_registeredContactsKey);
      if (registeredContactsJson == null) {
        return null;
      }
      
      List<UserModel> registeredContacts = registeredContactsJson
          .map((json) => UserModel.fromMap(jsonDecode(json)))
          .toList();
      
      // Get unregistered contacts (store only essential info)
      final unregisteredContactsJson = prefs.getStringList(_unregisteredContactsKey);
      List<Contact> unregisteredContacts = [];
      
      // Unregistered contacts need to be refreshed from device 
      // since we can't fully serialize/deserialize Contact objects
      if (unregisteredContactsJson != null) {
        final deviceContacts = await getDeviceContacts();
        final unregisteredIds = unregisteredContactsJson.map((json) => jsonDecode(json)['id'] as String).toSet();
        
        unregisteredContacts = deviceContacts
            .where((contact) => unregisteredIds.contains(contact.id))
            .toList();
      }
      
      return ContactSyncResult(
        registeredContacts: registeredContacts,
        unregisteredContacts: unregisteredContacts,
        syncTime: DateTime.parse(lastSyncTimeString),
      );
    } catch (e) {
      debugPrint('Error loading contacts from storage: $e');
      return null;
    }
  }
  
  // Save contacts to local storage
  Future<void> saveContactsToStorage(ContactSyncResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save last sync time
      await prefs.setString(_lastSyncTimeKey, result.syncTime.toIso8601String());
      
      // Save registered contacts
      final registeredContactsJson = result.registeredContacts
          .map((contact) => jsonEncode(contact.toMap()))
          .toList();
      await prefs.setStringList(_registeredContactsKey, registeredContactsJson);
      
      // Save unregistered contacts (minimal info)
      final unregisteredContactsJson = result.unregisteredContacts
          .map((contact) => jsonEncode({'id': contact.id, 'name': contact.displayName}))
          .toList();
      await prefs.setStringList(_unregisteredContactsKey, unregisteredContactsJson);
      
      debugPrint('Contacts saved to local storage successfully');
    } catch (e) {
      debugPrint('Error saving contacts to storage: $e');
    }
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
    bool forceSync = false,
  }) async {
    try {
      // Check if we can use cached data
      if (!forceSync) {
        final cachedResult = await loadContactsFromStorage();
        final syncNeeded = await isSyncNeeded();
        
        if (cachedResult != null && !syncNeeded) {
          debugPrint('Using cached contacts data from ${cachedResult.syncTime}');
          return cachedResult;
        }
      }
      
      debugPrint('Performing full contacts sync with Firebase...');
      
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
      
      // Create the result with current timestamp
      final result = ContactSyncResult(
        registeredContacts: registeredUsers,
        unregisteredContacts: unregisteredContacts,
        syncTime: DateTime.now(),
      );
      
      // Save to local storage
      await saveContactsToStorage(result);
      
      return result;
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
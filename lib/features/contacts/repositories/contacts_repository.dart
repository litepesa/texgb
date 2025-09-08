// lib/features/contacts/repositories/contacts_repository.dart
// Consolidated contacts repository with all functionality - no Firebase dependencies
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/shared/services/http_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:crypto/crypto.dart';

// ========================================
// CACHE MANAGER
// ========================================

// Enhanced cache manager for contact-related data
class ContactCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'contactCache';
  
  static ContactCacheManager? _instance;
  
  factory ContactCacheManager() {
    return _instance ??= ContactCacheManager._();
  }
  
  ContactCacheManager._() : super(
    Config(
      key,
      stalePeriod: const Duration(hours: 6),
      maxNrOfCacheObjects: 1000,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}

// ========================================
// EXCEPTIONS
// ========================================

// Base exception class for contacts operations
class ContactsRepositoryException implements Exception {
  final String message;
  const ContactsRepositoryException(this.message);
  
  @override
  String toString() => 'ContactsRepositoryException: $message';
}

// Permission related exceptions
class ContactsPermissionException extends ContactsRepositoryException {
  const ContactsPermissionException(String message) : super(message);
  
  @override
  String toString() => 'ContactsPermissionException: $message';
}

// Sync related exceptions
class ContactsSyncException extends ContactsRepositoryException {
  const ContactsSyncException(String message) : super(message);
  
  @override
  String toString() => 'ContactsSyncException: $message';
}

// Network related exceptions
class ContactsNetworkException extends ContactsRepositoryException {
  const ContactsNetworkException(String message) : super(message);
  
  @override
  String toString() => 'ContactsNetworkException: $message';
}

// Cache related exceptions
class ContactsCacheException extends ContactsRepositoryException {
  const ContactsCacheException(String message) : super(message);
  
  @override
  String toString() => 'ContactsCacheException: $message';
}

// Device contacts related exceptions
class DeviceContactsException extends ContactsRepositoryException {
  const DeviceContactsException(String message) : super(message);
  
  @override
  String toString() => 'DeviceContactsException: $message';
}

// Search related exceptions
class ContactsSearchException extends ContactsRepositoryException {
  const ContactsSearchException(String message) : super(message);
  
  @override
  String toString() => 'ContactsSearchException: $message';
}

// Block/Unblock related exceptions
class ContactsBlockException extends ContactsRepositoryException {
  const ContactsBlockException(String message) : super(message);
  
  @override
  String toString() => 'ContactsBlockException: $message';
}

// ========================================
// MODELS
// ========================================

// Result class for contact synchronization with metadata
class ContactSyncResult {
  final List<UserModel> registeredContacts;
  final List<Contact> unregisteredContacts;
  final DateTime syncTime;
  final String syncVersion; // For cache invalidation
  final Map<String, String> contactHashes; // For change detection

  ContactSyncResult({
    required this.registeredContacts,
    required this.unregisteredContacts,
    required this.syncTime,
    required this.syncVersion,
    required this.contactHashes,
  });

  Map<String, dynamic> toJson() => {
    'registeredContacts': registeredContacts.map((c) => c.toMap()).toList(),
    'unregisteredContacts': unregisteredContacts.map((c) => {
      'id': c.id,
      'displayName': c.displayName,
      'phones': c.phones.map((p) => {
        'number': p.number,
        'label': p.label.name,
      }).toList(),
    }).toList(),
    'syncTime': syncTime.toIso8601String(),
    'syncVersion': syncVersion,
    'contactHashes': contactHashes,
  };

  factory ContactSyncResult.fromJson(Map<String, dynamic> json) {
    return ContactSyncResult(
      registeredContacts: (json['registeredContacts'] as List)
          .map((c) => UserModel.fromMap(c))
          .toList(),
      unregisteredContacts: (json['unregisteredContacts'] as List)
          .map((c) => Contact()
            ..id = c['id']
            ..displayName = c['displayName']
            ..phones = (c['phones'] as List).map((p) => Phone(
              p['number'],
              label: PhoneLabel.values.firstWhere(
                (label) => label.name == p['label'],
                orElse: () => PhoneLabel.mobile,
              ),
            )).toList())
          .toList(),
      syncTime: DateTime.parse(json['syncTime']),
      syncVersion: json['syncVersion'] ?? '',
      contactHashes: Map<String, String>.from(json['contactHashes'] ?? {}),
    );
  }
}

// ========================================
// MAIN REPOSITORY CLASS
// ========================================

// Enhanced contacts repository with HTTP service - no Firebase dependencies
class ContactsRepository {
  final HttpClientService _httpClient;
  final ContactCacheManager _cacheManager;
  static const String _lastSyncTimeKey = 'last_contacts_sync_time';
  static const String _contactDataKey = 'contact_sync_data';
  static const String _deviceContactsHashKey = 'device_contacts_hash';
  
  // Sync frequency constants
  static const Duration syncThreshold = Duration(hours: 6);
  static const Duration backgroundSyncThreshold = Duration(hours: 1);
  
  ContactsRepository({
    required HttpClientService httpClient,
    ContactCacheManager? cacheManager,
  }) : _httpClient = httpClient,
       _cacheManager = cacheManager ?? ContactCacheManager();

  // ========================================
  // DEVICE CONTACTS METHODS
  // ========================================

  // Enhanced device contacts retrieval with change detection
  Future<List<Contact>> getDeviceContacts({bool useCache = true}) async {
    try {
      // Check permission first
      final status = await Permission.contacts.request();
      if (!status.isGranted) {
        throw const ContactsPermissionException('Contacts permission denied');
      }

      // Generate hash of current device contacts for change detection
      final currentHash = await _generateDeviceContactsHash();
      
      if (useCache) {
        final prefs = await SharedPreferences.getInstance();
        final cachedHash = prefs.getString(_deviceContactsHashKey);
        
        if (cachedHash == currentHash) {
          final cachedData = await _loadCachedDeviceContacts();
          if (cachedData != null) {
            debugPrint('Using cached device contacts');
            return cachedData;
          }
        }
      }

      debugPrint('Fetching fresh device contacts');
      
      // Get all contacts with optimized properties
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
        withThumbnail: false,
        withAccounts: false,
        withGroups: false,
      );
      
      // Filter and process contacts
      final validContacts = contacts
          .where((contact) => contact.phones.isNotEmpty)
          .toList();
      
      // Cache the contacts and hash
      await _cacheDeviceContacts(validContacts, currentHash);
      
      return validContacts;
    } catch (e) {
      debugPrint('Error fetching contacts: $e');
      if (e is ContactsPermissionException) {
        rethrow;
      }
      throw DeviceContactsException('Failed to fetch contacts: $e');
    }
  }

  // Generate hash for device contacts change detection
  Future<String> _generateDeviceContactsHash() async {
    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: false, // Only get basic info for hashing
      );
      
      final contactData = contacts
          .map((c) => '${c.id}:${c.displayName}:${c.phones.length}')
          .join('|');
      
      return sha256.convert(utf8.encode(contactData)).toString();
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  // Cache device contacts locally
  Future<void> _cacheDeviceContacts(List<Contact> contacts, String hash) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Store hash for change detection
      await prefs.setString(_deviceContactsHashKey, hash);
      
      // Store essential contact data
      final contactData = contacts.map((contact) => {
        'id': contact.id,
        'displayName': contact.displayName,
        'phones': contact.phones.map((phone) => {
          'number': phone.number,
          'label': phone.label.name,
        }).toList(),
      }).toList();
      
      await prefs.setString('cached_device_contacts', jsonEncode(contactData));
    } catch (e) {
      debugPrint('Error caching device contacts: $e');
      throw ContactsCacheException('Failed to cache device contacts: $e');
    }
  }

  // Load cached device contacts
  Future<List<Contact>?> _loadCachedDeviceContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_device_contacts');
      
      if (cachedData == null) return null;
      
      final contactList = jsonDecode(cachedData) as List;
      
      return contactList.map((data) {
        final contact = Contact()
          ..id = data['id']
          ..displayName = data['displayName'];
        
        contact.phones = (data['phones'] as List).map((phoneData) {
          return Phone(
            phoneData['number'],
            label: PhoneLabel.values.firstWhere(
              (label) => label.name == phoneData['label'],
              orElse: () => PhoneLabel.mobile,
            ),
          );
        }).toList();
        
        return contact;
      }).toList();
    } catch (e) {
      debugPrint('Error loading cached device contacts: $e');
      throw ContactsCacheException('Failed to load cached device contacts: $e');
    }
  }

  // ========================================
  // SYNC MANAGEMENT METHODS
  // ========================================

  // Enhanced sync checking with intelligent algorithms
  Future<bool> isSyncNeeded({bool isBackground = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncTimeString = prefs.getString(_lastSyncTimeKey);
      
      if (lastSyncTimeString == null) {
        return true; // Never synced before
      }
      
      final lastSyncTime = DateTime.parse(lastSyncTimeString);
      final now = DateTime.now();
      final threshold = isBackground ? backgroundSyncThreshold : syncThreshold;
      
      // Check time-based sync need
      final timeSyncNeeded = now.difference(lastSyncTime) > threshold;
      
      // Check if device contacts changed
      final deviceContactsChanged = await _haveDeviceContactsChanged();
      
      return timeSyncNeeded || deviceContactsChanged;
    } catch (e) {
      debugPrint('Error checking sync status: $e');
      throw ContactsSyncException('Failed to check sync status: $e');
    }
  }

  // Check if device contacts have changed since last sync
  Future<bool> _haveDeviceContactsChanged() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastKnownHash = prefs.getString(_deviceContactsHashKey);
      
      if (lastKnownHash == null) return true;
      
      final currentHash = await _generateDeviceContactsHash();
      return currentHash != lastKnownHash;
    } catch (e) {
      return true; // Assume changed if we can't determine
    }
  }

  // ========================================
  // CACHE MANAGEMENT METHODS
  // ========================================

  // Enhanced contact loading with cache manager
  Future<ContactSyncResult?> loadContactsFromStorage() async {
    try {
      // Try cache manager first
      final cacheKey = 'contacts_sync_data';
      final fileInfo = await _cacheManager.getFileFromCache(cacheKey);
      
      if (fileInfo != null) {
        final content = await fileInfo.file.readAsString();
        final data = jsonDecode(content);
        return ContactSyncResult.fromJson(data);
      }
      
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_contactDataKey);
      
      if (cachedData != null) {
        final data = jsonDecode(cachedData);
        return ContactSyncResult.fromJson(data);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error loading contacts from storage: $e');
      throw ContactsCacheException('Failed to load contacts from storage: $e');
    }
  }
  
  // Enhanced contact saving with cache manager
  Future<void> saveContactsToStorage(ContactSyncResult result) async {
    try {
      final data = jsonEncode(result.toJson());
      
      // Save to cache manager
      final cacheKey = 'contacts_sync_data';
      final bytes = utf8.encode(data);
      await _cacheManager.putFile(
        cacheKey, 
        bytes,
        maxAge: syncThreshold,
      );
      
      // Also save to SharedPreferences as backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_contactDataKey, data);
      await prefs.setString(_lastSyncTimeKey, result.syncTime.toIso8601String());
      
      debugPrint('Contacts saved to storage successfully');
    } catch (e) {
      debugPrint('Error saving contacts to storage: $e');
      throw ContactsCacheException('Failed to save contacts to storage: $e');
    }
  }

  // Clear all contact cache
  Future<void> clearCache() async {
    try {
      await _cacheManager.emptyCache();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_contactDataKey);
      await prefs.remove(_lastSyncTimeKey);
      await prefs.remove(_deviceContactsHashKey);
      await prefs.remove('cached_device_contacts');
      debugPrint('Contact cache cleared');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
      throw ContactsCacheException('Failed to clear contacts cache: $e');
    }
  }

  // ========================================
  // BACKEND SYNC METHODS
  // ========================================

  // Enhanced user search with batching and caching using HTTP service
  Future<List<UserModel>> findRegisteredUsers(List<String> phoneNumbers) async {
    try {
      if (phoneNumbers.isEmpty) return [];
      
      // Create cache key for this phone number set
      final phoneSet = phoneNumbers.toSet().toList()..sort();
      final cacheKey = 'registered_users_${sha256.convert(utf8.encode(phoneSet.join(','))).toString()}';
      
      // Try cache first
      final fileInfo = await _cacheManager.getFileFromCache(cacheKey);
      if (fileInfo != null) {
        try {
          final content = await fileInfo.file.readAsString();
          final data = jsonDecode(content) as List;
          return data.map((item) => UserModel.fromMap(item)).toList();
        } catch (e) {
          // Cache corrupted, continue with fresh fetch
        }
      }
      
      List<UserModel> registeredUsers = [];
      
      // Process in smaller batches for better performance
      final chunks = _chunkList(phoneNumbers.toSet().toList(), 10);
      
      for (final chunk in chunks) {
        final response = await _httpClient.post('/contacts/search', body: {
          'phoneNumbers': chunk,
        });
        
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          final List<dynamic> usersData = responseData['users'] ?? [];
          final users = usersData
              .map((userData) => UserModel.fromMap(userData as Map<String, dynamic>))
              .toList();
          registeredUsers.addAll(users);
        } else {
          throw ContactsNetworkException('Failed to search users: ${response.body}');
        }
      }
      
      // Cache the results
      final cacheData = registeredUsers.map((user) => user.toMap()).toList();
      final bytes = utf8.encode(jsonEncode(cacheData));
      await _cacheManager.putFile(
        cacheKey,
        bytes,
        maxAge: const Duration(hours: 1), // Shorter cache for user data
      );
      
      return registeredUsers;
    } catch (e) {
      debugPrint('Error finding registered users: $e');
      if (e is ContactsNetworkException) {
        rethrow;
      }
      throw ContactsSearchException('Failed to find registered users: $e');
    }
  }

  // Enhanced sync with better performance and change detection using HTTP service
  Future<ContactSyncResult> syncContactsWithBackend({
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
      
      debugPrint('Performing full contacts sync with backend...');
      
      // Extract and standardize phone numbers
      final phoneToContactMap = <String, Contact>{};
      final contactPhoneNumbers = <String>[];
      
      for (final contact in deviceContacts) {
        for (final phone in contact.phones) {
          final standardized = standardizePhoneNumber(phone.number);
          contactPhoneNumbers.add(standardized);
          phoneToContactMap[standardized] = contact;
        }
      }
      
      // Find registered users efficiently using HTTP service
      final registeredUsers = await findRegisteredUsers(contactPhoneNumbers);
      
      // Filter out user's own number
      registeredUsers.removeWhere((user) => user.uid == currentUser.uid);
      
      // Create unregistered contacts list
      final registeredPhoneNumbers = registeredUsers.map((user) => user.phoneNumber).toSet();
      final processedContactIds = <String>{};
      final unregisteredContacts = <Contact>[];
      
      for (final phoneNumber in contactPhoneNumbers) {
        if (!registeredPhoneNumbers.contains(phoneNumber)) {
          final contact = phoneToContactMap[phoneNumber];
          if (contact != null && !processedContactIds.contains(contact.id)) {
            unregisteredContacts.add(contact);
            processedContactIds.add(contact.id);
          }
        }
      }
      
      // Generate contact hashes for change detection
      final contactHashes = <String, String>{};
      for (final contact in [...registeredUsers.map((u) => u.uid), ...unregisteredContacts.map((c) => c.id)]) {
        contactHashes[contact] = sha256.convert(utf8.encode(contact)).toString();
      }
      
      // Create result with version for cache invalidation
      final result = ContactSyncResult(
        registeredContacts: registeredUsers,
        unregisteredContacts: _removeDuplicateContacts(unregisteredContacts),
        syncTime: DateTime.now(),
        syncVersion: DateTime.now().millisecondsSinceEpoch.toString(),
        contactHashes: contactHashes,
      );
      
      // Save to storage
      await saveContactsToStorage(result);
      
      return result;
    } catch (e) {
      debugPrint('Error syncing contacts: $e');
      if (e is ContactsNetworkException || e is ContactsSearchException) {
        rethrow;
      }
      throw ContactsSyncException('Failed to sync contacts: $e');
    }
  }

  // Background sync for better UX
  Future<bool> performBackgroundSync({
    required UserModel currentUser,
  }) async {
    try {
      if (!await isSyncNeeded(isBackground: true)) {
        return false; // No sync needed
      }
      
      final deviceContacts = await getDeviceContacts();
      await syncContactsWithBackend(
        deviceContacts: deviceContacts,
        currentUser: currentUser,
        forceSync: false,
      );
      
      return true;
    } catch (e) {
      debugPrint('Background sync failed: $e');
      return false;
    }
  }

  // ========================================
  // USER SEARCH AND MANAGEMENT METHODS
  // ========================================

  // Search user by phone number using HTTP service
  Future<UserModel?> searchUserByPhoneNumber(String phoneNumber) async {
    try {
      final standardized = standardizePhoneNumber(phoneNumber);
      final response = await _httpClient.get('/users/search?phoneNumber=${Uri.encodeComponent(standardized)}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['user'] != null) {
          return UserModel.fromMap(responseData['user'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error searching user by phone number: $e');
      throw ContactsSearchException('Failed to search user by phone number: $e');
    }
  }

  // Block contact using HTTP service
  Future<void> blockContact(String contactUid) async {
    try {
      final response = await _httpClient.post('/contacts/block', body: {
        'contactId': contactUid,
      });
      
      if (response.statusCode != 200) {
        throw ContactsNetworkException('Failed to block contact: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error blocking contact: $e');
      if (e is ContactsNetworkException) {
        rethrow;
      }
      throw ContactsBlockException('Failed to block contact: $e');
    }
  }

  // Unblock contact using HTTP service
  Future<void> unblockContact(String contactUid) async {
    try {
      final response = await _httpClient.post('/contacts/unblock', body: {
        'contactId': contactUid,
      });
      
      if (response.statusCode != 200) {
        throw ContactsNetworkException('Failed to unblock contact: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error unblocking contact: $e');
      if (e is ContactsNetworkException) {
        rethrow;
      }
      throw ContactsBlockException('Failed to unblock contact: $e');
    }
  }

  // Get blocked contacts using HTTP service
  Future<List<UserModel>> getBlockedContacts() async {
    try {
      final response = await _httpClient.get('/contacts/blocked');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> blockedData = responseData['blockedContacts'] ?? [];
        return blockedData
            .map((contactData) => UserModel.fromMap(contactData as Map<String, dynamic>))
            .toList();
      } else {
        throw ContactsNetworkException('Failed to get blocked contacts: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error getting blocked contacts: $e');
      if (e is ContactsNetworkException) {
        rethrow;
      }
      throw ContactsSearchException('Failed to get blocked contacts: $e');
    }
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  // Standardize phone number with better international support
  String standardizePhoneNumber(String phoneNumber) {
    // Remove all non-digit characters except +
    String digits = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // Handle different country codes more intelligently
    if (!digits.startsWith('+')) {
      // Add country code based on locale or user preference
      // For now, defaulting to US +1, but this should be configurable
      if (digits.startsWith('1') && digits.length == 11) {
        digits = '+$digits';
      } else if (digits.length == 10) {
        digits = '+1$digits';
      } else {
        digits = '+1$digits'; // Fallback
      }
    }
    
    return digits;
  }

  // Helper method to remove duplicate contacts (enhanced)
  List<Contact> _removeDuplicateContacts(List<Contact> contacts) {
    final seen = <String>{};
    final uniqueContacts = <Contact>[];
    
    for (final contact in contacts) {
      // Create a unique key based on name and primary phone
      final primaryPhone = contact.phones.isNotEmpty 
          ? standardizePhoneNumber(contact.phones.first.number)
          : '';
      final key = '${contact.displayName.toLowerCase().trim()}:$primaryPhone';
      
      if (!seen.contains(key)) {
        seen.add(key);
        uniqueContacts.add(contact);
      }
    }
    
    return uniqueContacts;
  }
  
  // Helper method to chunk list for batch processing
  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    
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

// ========================================
// PROVIDERS
// ========================================

// Enhanced provider with HTTP service
final contactCacheManagerProvider = Provider<ContactCacheManager>((ref) {
  return ContactCacheManager();
});

final contactsRepositoryProvider = Provider<ContactsRepository>((ref) {
  return ContactsRepository(
    httpClient: HttpClientService(),
    cacheManager: ref.read(contactCacheManagerProvider),
  );
});
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

part 'contacts_provider.g.dart';

// Define state class for contacts management
class ContactsState {
  final List<Contact> deviceContacts;
  final List<UserModel> appContacts;
  final List<UserModel> suggestedContacts;
  final bool isLoading;
  final bool hasPermission;
  final bool isSyncing;
  final String? error;

  const ContactsState({
    this.deviceContacts = const [],
    this.appContacts = const [],
    this.suggestedContacts = const [],
    this.isLoading = false,
    this.hasPermission = false,
    this.isSyncing = false,
    this.error,
  });

  ContactsState copyWith({
    List<Contact>? deviceContacts,
    List<UserModel>? appContacts,
    List<UserModel>? suggestedContacts,
    bool? isLoading,
    bool? hasPermission,
    bool? isSyncing,
    String? error,
  }) {
    return ContactsState(
      deviceContacts: deviceContacts ?? this.deviceContacts,
      appContacts: appContacts ?? this.appContacts,
      suggestedContacts: suggestedContacts ?? this.suggestedContacts,
      isLoading: isLoading ?? this.isLoading,
      hasPermission: hasPermission ?? this.hasPermission,
      isSyncing: isSyncing ?? this.isSyncing,
      error: error,
    );
  }
}

@riverpod
class ContactsNotifier extends _$ContactsNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  FutureOr<ContactsState> build() async {
    // Initialize with default state
    return const ContactsState();
  }

  // Request contacts permission
  Future<void> requestContactsPermission() async {
    state = const AsyncLoading();
    
    try {
      final status = await Permission.contacts.request();
      final hasPermission = status.isGranted;
      
      // Update state with permission status
      state = AsyncData(
        ContactsState(
          hasPermission: hasPermission,
          deviceContacts: state.valueOrNull?.deviceContacts ?? [],
          appContacts: state.valueOrNull?.appContacts ?? [],
          suggestedContacts: state.valueOrNull?.suggestedContacts ?? [],
        ),
      );
      
      if (hasPermission) {
        await loadContacts();
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  // Check permission status
  Future<bool> checkContactsPermission() async {
    final status = await Permission.contacts.status;
    final hasPermission = status.isGranted;
    
    // Update state with permission status
    state = AsyncData(
      state.valueOrNull!.copyWith(
        hasPermission: hasPermission,
      ),
    );
    
    return hasPermission;
  }

  // Load and sync contacts
  Future<void> loadContacts() async {
    if (!state.hasValue) return;
    
    state = AsyncData(state.value!.copyWith(isLoading: true));
    
    try {
      final currentUserID = ref.read(currentUserProvider)?.uid;
      if (currentUserID == null) {
        throw Exception('User not authenticated');
      }
      
      // Load app contacts (users already in contact list)
      final appContacts = await _getAppContacts(currentUserID);
      
      // Update state with app contacts
      state = AsyncData(
        state.value!.copyWith(
          appContacts: appContacts,
          isLoading: false,
        ),
      );
      
      // Check if we have permission to access device contacts
      final hasPermission = await checkContactsPermission();
      
      if (hasPermission) {
        await syncContacts();
      }
    } catch (e) {
      debugPrint('Error loading contacts: $e');
      state = AsyncData(
        state.value!.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  // Get app contacts from Firestore
  Future<List<UserModel>> _getAppContacts(String uid) async {
    try {
      DocumentSnapshot documentSnapshot =
          await _firestore.collection(Constants.users).doc(uid).get();

      List<dynamic> contactsUIDs = documentSnapshot.get(Constants.contactsUIDs);
      List<UserModel> contacts = [];

      for (String contactUID in contactsUIDs) {
        DocumentSnapshot documentSnapshot =
            await _firestore.collection(Constants.users).doc(contactUID).get();
        UserModel contact =
            UserModel.fromMap(documentSnapshot.data() as Map<String, dynamic>);
        contacts.add(contact);
      }

      return contacts;
    } catch (e) {
      debugPrint('Error getting app contacts: $e');
      return [];
    }
  }

  // Sync device contacts with app users
  Future<void> syncContacts() async {
    if (!state.hasValue) return;
    
    state = AsyncData(state.value!.copyWith(isSyncing: true));
    
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Load device contacts
      final deviceContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withThumbnail: false,
      );
      
      // Create a batch of phone numbers to check
      List<String> phoneNumbers = [];
      Set<String> processedNumbers = {};
      
      for (var contact in deviceContacts) {
        if (contact.phones.isEmpty) continue;
        
        for (var phone in contact.phones) {
          // Normalize phone number (remove spaces, brackets, etc.)
          String normalizedNumber = _normalizePhoneNumber(phone.number);
          
          // Skip if we've already processed this number
          if (processedNumbers.contains(normalizedNumber) || 
              normalizedNumber.isEmpty) {
            continue;
          }
          
          processedNumbers.add(normalizedNumber);
          
          // Generate different formats of the number to check
          final phoneFormats = _generatePhoneFormats(normalizedNumber);
          phoneNumbers.addAll(phoneFormats);
        }
      }
      
      // Clear previous suggested contacts
      List<UserModel> suggestedContacts = [];
      
      // Get registered users from Firebase that match these numbers
      if (phoneNumbers.isNotEmpty) {
        // Firebase has limits on in queries, so we might need to batch
        const batchSize = 10;
        List<Future<QuerySnapshot>> queries = [];
        
        for (int i = 0; i < phoneNumbers.length; i += batchSize) {
          final endIndex = (i + batchSize < phoneNumbers.length) ? i + batchSize : phoneNumbers.length;
          final batch = phoneNumbers.sublist(i, endIndex);
          
          queries.add(
            _firestore
                .collection(Constants.users)
                .where(Constants.phoneNumber, whereIn: batch)
                .get()
          );
        }
        
        final results = await Future.wait(queries);
        
        // Process all results
        for (var snapshot in results) {
          for (var doc in snapshot.docs) {
            final userData = doc.data() as Map<String, dynamic>;
            final user = UserModel.fromMap(userData);
            
            // Skip the current user
            if (user.uid == currentUser.uid) continue;
            
            // Skip users already in contacts
            if (state.value!.appContacts.any((contact) => contact.uid == user.uid)) continue;
            
            // Skip users already in suggested contacts
            if (suggestedContacts.any((contact) => contact.uid == user.uid)) continue;
            
            // Add to suggested contacts
            suggestedContacts.add(user);
          }
        }
      }
      
      // Update state with the results
      state = AsyncData(
        state.value!.copyWith(
          deviceContacts: deviceContacts,
          suggestedContacts: suggestedContacts,
          isSyncing: false,
        ),
      );
    } catch (e) {
      debugPrint('Error syncing contacts: $e');
      state = AsyncData(
        state.value!.copyWith(
          isSyncing: false,
          error: e.toString(),
        ),
      );
    }
  }

  // Normalize phone number to strip special characters and standardize format
  String _normalizePhoneNumber(String phoneNumber) {
    // Remove everything except digits
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
    
    if (digitsOnly.isEmpty) return '';
    
    // Handle different formats
    if (digitsOnly.length < 7) return ''; // Too short to be valid
    
    return digitsOnly;
  }

  // Generate different possible formats of a phone number
  List<String> _generatePhoneFormats(String phoneNumber) {
    final formats = <String>[];
    
    // Original normalized number
    formats.add(phoneNumber);
    
    // With country code (common formats)
    if (phoneNumber.length >= 10) {
      if (!phoneNumber.startsWith('+')) {
        formats.add('+$phoneNumber');
      }
      
      // Common country codes
      final countryCodes = ['+1', '+44', '+91', '+61', '+254']; // US, UK, India, Australia, Kenya
      
      for (var code in countryCodes) {
        if (!phoneNumber.startsWith(code.substring(1))) {
          formats.add('$code$phoneNumber');
        }
      }
    }
    
    return formats;
  }
  
  // Add contact from suggestions
  Future<void> addSuggestedContact(UserModel user) async {
    if (!state.hasValue) return;
    
    // Add contact to Firebase
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Add the contact to the user's contacts list
      await _firestore.collection(Constants.users).doc(currentUser.uid).update({
        Constants.contactsUIDs: FieldValue.arrayUnion([user.uid]),
      });
      
      // Update local lists
      final updatedAppContacts = [...state.value!.appContacts, user];
      final updatedSuggestedContacts = state.value!.suggestedContacts
          .where((contact) => contact.uid != user.uid)
          .toList();
      
      state = AsyncData(
        state.value!.copyWith(
          appContacts: updatedAppContacts,
          suggestedContacts: updatedSuggestedContacts,
        ),
      );
    } catch (e) {
      debugPrint('Error adding contact: $e');
      state = AsyncData(
        state.value!.copyWith(
          error: e.toString(),
        ),
      );
    }
  }
  
  // Add all suggested contacts at once
  Future<void> addAllSuggestedContacts() async {
    if (!state.hasValue) return;
    
    state = AsyncData(state.value!.copyWith(isLoading: true));
    
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      final suggestedContacts = state.value!.suggestedContacts;
      final uidsToAdd = suggestedContacts.map((user) => user.uid).toList();
      
      if (uidsToAdd.isNotEmpty) {
        // Add all contacts at once
        await _firestore.collection(Constants.users).doc(currentUser.uid).update({
          Constants.contactsUIDs: FieldValue.arrayUnion(uidsToAdd),
        });
      }
      
      // Update local lists
      final updatedAppContacts = [
        ...state.value!.appContacts,
        ...suggestedContacts,
      ];
      
      state = AsyncData(
        state.value!.copyWith(
          appContacts: updatedAppContacts,
          suggestedContacts: [],
          isLoading: false,
        ),
      );
    } catch (e) {
      debugPrint('Error adding all contacts: $e');
      state = AsyncData(
        state.value!.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }
}

// Convenience providers
@riverpod
List<Contact> deviceContacts(DeviceContactsRef ref) {
  final contactsState = ref.watch(contactsNotifierProvider);
  return contactsState.valueOrNull?.deviceContacts ?? [];
}

@riverpod
List<UserModel> appContacts(AppContactsRef ref) {
  final contactsState = ref.watch(contactsNotifierProvider);
  return contactsState.valueOrNull?.appContacts ?? [];
}

@riverpod
List<UserModel> suggestedContacts(SuggestedContactsRef ref) {
  final contactsState = ref.watch(contactsNotifierProvider);
  return contactsState.valueOrNull?.suggestedContacts ?? [];
}

@riverpod
bool hasContactsPermission(HasContactsPermissionRef ref) {
  final contactsState = ref.watch(contactsNotifierProvider);
  return contactsState.valueOrNull?.hasPermission ?? false;
}

@riverpod
bool isContactsLoading(IsContactsLoadingRef ref) {
  final contactsState = ref.watch(contactsNotifierProvider);
  return contactsState.isLoading || contactsState.valueOrNull?.isLoading == true;
}

@riverpod
bool isContactsSyncing(IsContactsSyncingRef ref) {
  final contactsState = ref.watch(contactsNotifierProvider);
  return contactsState.valueOrNull?.isSyncing ?? false;
}

@riverpod
String? contactsError(ContactsErrorRef ref) {
  final contactsState = ref.watch(contactsNotifierProvider);
  return contactsState.valueOrNull?.error;
}
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/contacts/repositories/contacts_repository.dart';
import 'package:textgb/models/user_model.dart';

part 'contacts_provider.g.dart';

// State class for contacts management
class ContactsState {
  final bool isLoading;
  final bool isSuccessful;
  final List<Contact> deviceContacts;
  final List<UserModel> registeredContacts;
  final List<Contact> unregisteredContacts;
  final List<UserModel> blockedContacts;
  final String? error;
  final bool syncInProgress;
  final DateTime? lastSyncTime;
  final SyncStatus syncStatus;

  const ContactsState({
    this.isLoading = false,
    this.isSuccessful = false,
    this.deviceContacts = const [],
    this.registeredContacts = const [],
    this.unregisteredContacts = const [],
    this.blockedContacts = const [],
    this.error,
    this.syncInProgress = false,
    this.lastSyncTime,
    this.syncStatus = SyncStatus.unknown,
  });

  ContactsState copyWith({
    bool? isLoading,
    bool? isSuccessful,
    List<Contact>? deviceContacts,
    List<UserModel>? registeredContacts,
    List<Contact>? unregisteredContacts,
    List<UserModel>? blockedContacts,
    String? error,
    bool? syncInProgress,
    DateTime? lastSyncTime,
    SyncStatus? syncStatus,
  }) {
    return ContactsState(
      isLoading: isLoading ?? this.isLoading,
      isSuccessful: isSuccessful ?? this.isSuccessful,
      deviceContacts: deviceContacts ?? this.deviceContacts,
      registeredContacts: registeredContacts ?? this.registeredContacts,
      unregisteredContacts: unregisteredContacts ?? this.unregisteredContacts,
      blockedContacts: blockedContacts ?? this.blockedContacts,
      error: error,
      syncInProgress: syncInProgress ?? this.syncInProgress,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

// Define sync status enum for better state management
enum SyncStatus {
  unknown,      // Initial state
  upToDate,     // Recently synced, data is fresh
  stale,        // Sync needed, data is outdated
  neverSynced,  // No sync has been performed yet
  failed, synced, pending,       // Sync attempt failed
}

@riverpod
class ContactsNotifier extends _$ContactsNotifier {
  late ContactsRepository _contactsRepository;
  
  @override
  FutureOr<ContactsState> build() async {
    _contactsRepository = ref.read(contactsRepositoryProvider);
    
    // Initialize with empty state
    final initialState = const ContactsState(
      syncStatus: SyncStatus.unknown,
    );
    
    // Try to load cached contacts first
    return _loadCachedContacts(initialState);
  }

  // Load cached contacts from local storage
  Future<ContactsState> _loadCachedContacts(ContactsState currentState) async {
    try {
      // Check if we need to sync based on time threshold
      final syncNeeded = await _contactsRepository.isSyncNeeded();
      final cachedData = await _contactsRepository.loadContactsFromStorage();
      
      if (cachedData == null) {
        // No cached data, we need a full sync
        return currentState.copyWith(
          syncStatus: SyncStatus.neverSynced,
        );
      }
      
      // Determine sync status
      final syncStatus = syncNeeded ? SyncStatus.stale : SyncStatus.upToDate;
      
      // Update state with cached data
      return currentState.copyWith(
        registeredContacts: cachedData.registeredContacts,
        unregisteredContacts: cachedData.unregisteredContacts,
        lastSyncTime: cachedData.syncTime,
        syncStatus: syncStatus,
        isSuccessful: true,
      );
    } catch (e) {
      debugPrint('Error loading cached contacts: $e');
      return currentState.copyWith(
        syncStatus: SyncStatus.failed,
        error: 'Failed to load cached contacts: $e',
      );
    }
  }

  // Load device contacts
  Future<void> loadDeviceContacts() async {
    if (!state.hasValue) return;
    
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      final contacts = await _contactsRepository.getDeviceContacts();
      state = AsyncValue.data(state.value!.copyWith(
        deviceContacts: contacts,
        isLoading: false,
        isSuccessful: true,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Synchronize contacts with the app - with smart sync option
  Future<void> syncContacts({bool forceSync = false}) async {
    if (!state.hasValue) return;
    
    state = AsyncValue.data(state.value!.copyWith(
      syncInProgress: true,
      error: null,
    ));

    try {
      // Load device contacts if not already loaded
      List<Contact> deviceContacts = state.value!.deviceContacts;
      if (deviceContacts.isEmpty) {
        deviceContacts = await _contactsRepository.getDeviceContacts();
        state = AsyncValue.data(state.value!.copyWith(
          deviceContacts: deviceContacts,
        ));
      }

      // Get current user
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel == null) {
        throw Exception('User not authenticated');
      }

      // Check if we need to sync
      final syncNeeded = forceSync || 
                         state.value!.syncStatus == SyncStatus.stale || 
                         state.value!.syncStatus == SyncStatus.neverSynced ||
                         state.value!.syncStatus == SyncStatus.failed;
      
      // If no sync needed and not forced, use cached data
      if (!syncNeeded && !forceSync && 
          state.value!.registeredContacts.isNotEmpty && 
          state.value!.lastSyncTime != null) {
        
        debugPrint('Using cached contacts data from ${state.value!.lastSyncTime}');
        
        // Just update the state to show we checked
        state = AsyncValue.data(state.value!.copyWith(
          syncInProgress: false,
          syncStatus: SyncStatus.upToDate,
          isSuccessful: true,
        ));
        
        return;
      }

      // Sync contacts with Firebase
      final result = await _contactsRepository.syncContactsWithFirebase(
        deviceContacts: deviceContacts,
        currentUser: authState.userModel!,
        forceSync: forceSync,
      );

      // Update state with results
      state = AsyncValue.data(state.value!.copyWith(
        registeredContacts: result.registeredContacts,
        unregisteredContacts: result.unregisteredContacts,
        syncInProgress: false,
        lastSyncTime: result.syncTime,
        syncStatus: SyncStatus.upToDate,
        isSuccessful: true,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        syncInProgress: false,
        syncStatus: SyncStatus.failed,
        error: e.toString(),
      ));
    }
  }

  // Check if sync is needed and update status
  Future<bool> checkSyncStatus() async {
    if (!state.hasValue) return true;
    
    try {
      final syncNeeded = await _contactsRepository.isSyncNeeded();
      
      // Update sync status based on check
      state = AsyncValue.data(state.value!.copyWith(
        syncStatus: syncNeeded ? SyncStatus.stale : SyncStatus.upToDate,
      ));
      
      return syncNeeded;
    } catch (e) {
      debugPrint('Error checking sync status: $e');
      return true; // Default to needing sync if check fails
    }
  }

  // Add contact to user's contacts
  Future<void> addContact(UserModel contactUser) async {
    if (!state.hasValue) return;
    
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      await ref.read(authenticationProvider.notifier).addContact(
        contactID: contactUser.uid,
      );

      // Update local state
      final updatedContacts = List<UserModel>.from(state.value!.registeredContacts);
      if (!updatedContacts.any((contact) => contact.uid == contactUser.uid)) {
        updatedContacts.add(contactUser);
      }

      state = AsyncValue.data(state.value!.copyWith(
        registeredContacts: updatedContacts,
        isLoading: false,
        isSuccessful: true,
      ));
      
      // Update local storage with new contact list
      _updateLocalStorage();
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Remove contact from user's contacts
  Future<void> removeContact(UserModel contactUser) async {
    if (!state.hasValue) return;
    
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      await ref.read(authenticationProvider.notifier).removeContact(
        contactID: contactUser.uid,
      );

      // Update local state
      final updatedContacts = List<UserModel>.from(state.value!.registeredContacts)
        ..removeWhere((contact) => contact.uid == contactUser.uid);

      state = AsyncValue.data(state.value!.copyWith(
        registeredContacts: updatedContacts,
        isLoading: false,
        isSuccessful: true,
      ));
      
      // Update local storage with new contact list
      _updateLocalStorage();
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Block a contact
  Future<void> blockContact(UserModel contactUser) async {
    if (!state.hasValue) return;
    
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      await ref.read(authenticationProvider.notifier).blockContact(
        contactID: contactUser.uid,
      );

      // Update local state
      final updatedBlockedContacts = List<UserModel>.from(state.value!.blockedContacts);
      if (!updatedBlockedContacts.any((contact) => contact.uid == contactUser.uid)) {
        updatedBlockedContacts.add(contactUser);
      }

      state = AsyncValue.data(state.value!.copyWith(
        blockedContacts: updatedBlockedContacts,
        isLoading: false,
        isSuccessful: true,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Unblock a contact
  Future<void> unblockContact(UserModel contactUser) async {
    if (!state.hasValue) return;
    
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      await ref.read(authenticationProvider.notifier).unblockContact(
        contactID: contactUser.uid,
      );

      // Update local state
      final updatedBlockedContacts = List<UserModel>.from(state.value!.blockedContacts)
        ..removeWhere((contact) => contact.uid == contactUser.uid);

      state = AsyncValue.data(state.value!.copyWith(
        blockedContacts: updatedBlockedContacts,
        isLoading: false,
        isSuccessful: true,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Load user's blocked contacts
  Future<void> loadBlockedContacts() async {
    if (!state.hasValue) return;
    
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      // Get current user
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel == null) {
        throw Exception('User not authenticated');
      }

      final blockedContacts = await ref.read(authenticationProvider.notifier)
          .getBlockedContactsList(uid: authState.userModel!.uid);

      state = AsyncValue.data(state.value!.copyWith(
        blockedContacts: blockedContacts,
        isLoading: false,
        isSuccessful: true,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Search for a contact by phone number
  Future<UserModel?> searchUserByPhoneNumber(String phoneNumber) async {
    try {
      return await ref.read(authenticationProvider.notifier)
          .searchUserByPhoneNumber(phoneNumber: phoneNumber);
    } catch (e) {
      debugPrint('Error searching user: $e');
      return null;
    }
  }

  // Helper method to update local storage after contact list changes
  Future<void> _updateLocalStorage() async {
    if (!state.hasValue || !state.value!.isSuccessful) return;
    
    try {
      final result = ContactSyncResult(
        registeredContacts: state.value!.registeredContacts,
        unregisteredContacts: state.value!.unregisteredContacts,
        syncTime: state.value!.lastSyncTime ?? DateTime.now(),
      );
      
      await _contactsRepository.saveContactsToStorage(result);
    } catch (e) {
      debugPrint('Error updating local storage: $e');
    }
  }

  // Invite unregistered contact - generates share text for app invitation
  String generateInviteMessage() {
    return 'Hey! I\'m using TexGB to chat. It\'s a secure messaging app with great features. Download it here: [App Store Link]';
  }
}
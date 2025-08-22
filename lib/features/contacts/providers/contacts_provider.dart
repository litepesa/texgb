// Enhanced contacts_provider.dart with better performance and caching
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/contacts/repositories/contacts_repository.dart';
import 'package:textgb/models/user_model.dart';

part 'contacts_provider.g.dart';

// Enhanced state class with better organization
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
  final bool hasPermission;
  final String? syncVersion;
  final Map<String, UserModel> contactsMap; // For faster lookups
  final bool backgroundSyncAvailable;

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
    this.hasPermission = false,
    this.syncVersion,
    this.contactsMap = const {},
    this.backgroundSyncAvailable = false,
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
    bool? hasPermission,
    String? syncVersion,
    Map<String, UserModel>? contactsMap,
    bool? backgroundSyncAvailable,
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
      hasPermission: hasPermission ?? this.hasPermission,
      syncVersion: syncVersion ?? this.syncVersion,
      contactsMap: contactsMap ?? this.contactsMap,
      backgroundSyncAvailable: backgroundSyncAvailable ?? this.backgroundSyncAvailable,
    );
  }

  // Helper method to create contacts map from list
  Map<String, UserModel> _createContactsMap(List<UserModel> contacts) {
    return {for (var contact in contacts) contact.uid: contact};
  }

  // Update registered contacts and rebuild map
  ContactsState withUpdatedRegisteredContacts(List<UserModel> contacts) {
    return copyWith(
      registeredContacts: contacts,
      contactsMap: _createContactsMap(contacts),
    );
  }
}

// Enhanced sync status enum
enum SyncStatus {
  unknown,
  upToDate,
  stale,
  neverSynced,
  failed,
  synced,
  pending,
  backgroundSyncing,
  permissionDenied,
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
    
    // Check permissions first
    final hasPermission = await _checkPermissions();
    
    if (!hasPermission) {
      return initialState.copyWith(
        syncStatus: SyncStatus.permissionDenied,
        hasPermission: false,
        error: 'Contacts permission required',
      );
    }
    
    // Try to load cached contacts first
    return _loadCachedContacts(initialState.copyWith(hasPermission: true));
  }

  // Check and request permissions
  Future<bool> _checkPermissions() async {
    try {
      final status = await Permission.contacts.status;
      if (status.isGranted) {
        return true;
      } else if (status.isDenied) {
        final result = await Permission.contacts.request();
        return result.isGranted;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      return false;
    }
  }

  // Enhanced cached contacts loading
  Future<ContactsState> _loadCachedContacts(ContactsState currentState) async {
    try {
      // Check if we need to sync based on time threshold
      final syncNeeded = await _contactsRepository.isSyncNeeded();
      final cachedData = await _contactsRepository.loadContactsFromStorage();
      
      if (cachedData == null) {
        // No cached data, we need a full sync
        return currentState.copyWith(
          syncStatus: SyncStatus.neverSynced,
          backgroundSyncAvailable: true,
        );
      }
      
      // Determine sync status
      final syncStatus = syncNeeded ? SyncStatus.stale : SyncStatus.upToDate;
      
      // Create contacts map for efficient lookups
      final contactsMap = {
        for (var contact in cachedData.registeredContacts) 
          contact.uid: contact
      };
      
      // Update state with cached data
      return currentState.copyWith(
        registeredContacts: cachedData.registeredContacts,
        unregisteredContacts: cachedData.unregisteredContacts,
        lastSyncTime: cachedData.syncTime,
        syncStatus: syncStatus,
        isSuccessful: true,
        syncVersion: cachedData.syncVersion,
        contactsMap: contactsMap,
        backgroundSyncAvailable: syncNeeded,
      );
    } catch (e) {
      debugPrint('Error loading cached contacts: $e');
      return currentState.copyWith(
        syncStatus: SyncStatus.failed,
        error: 'Failed to load cached contacts: $e',
      );
    }
  }

  // Enhanced device contacts loading with caching
  Future<void> loadDeviceContacts({bool useCache = true}) async {
    if (!state.hasValue) return;
    
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      final contacts = await _contactsRepository.getDeviceContacts(useCache: useCache);
      state = AsyncValue.data(state.value!.copyWith(
        deviceContacts: contacts,
        isLoading: false,
        isSuccessful: true,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
        syncStatus: e.toString().contains('permission') 
            ? SyncStatus.permissionDenied 
            : SyncStatus.failed,
      ));
    }
  }

  // Enhanced sync with background sync support
  Future<void> syncContacts({
    bool forceSync = false,
    bool isBackground = false,
  }) async {
    if (!state.hasValue) return;
    
    // Don't sync if no permission
    if (!state.value!.hasPermission) {
      await requestPermission();
      return;
    }
    
    state = AsyncValue.data(state.value!.copyWith(
      syncInProgress: true,
      error: null,
      syncStatus: isBackground ? SyncStatus.backgroundSyncing : SyncStatus.pending,
    ));

    try {
      // Load device contacts if not already loaded or if forced
      List<Contact> deviceContacts = state.value!.deviceContacts;
      if (deviceContacts.isEmpty || forceSync) {
        deviceContacts = await _contactsRepository.getDeviceContacts(useCache: !forceSync);
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
        
        state = AsyncValue.data(state.value!.copyWith(
          syncInProgress: false,
          syncStatus: SyncStatus.upToDate,
          isSuccessful: true,
          backgroundSyncAvailable: false,
        ));
        
        return;
      }

      // Sync contacts with Firebase
      final result = await _contactsRepository.syncContactsWithFirebase(
        deviceContacts: deviceContacts,
        currentUser: authState.userModel!,
        forceSync: forceSync,
      );

      // Create contacts map for efficient lookups
      final contactsMap = {
        for (var contact in result.registeredContacts) 
          contact.uid: contact
      };

      // Update state with results
      state = AsyncValue.data(state.value!.copyWith(
        registeredContacts: result.registeredContacts,
        unregisteredContacts: result.unregisteredContacts,
        syncInProgress: false,
        lastSyncTime: result.syncTime,
        syncStatus: SyncStatus.upToDate,
        isSuccessful: true,
        syncVersion: result.syncVersion,
        contactsMap: contactsMap,
        backgroundSyncAvailable: false,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        syncInProgress: false,
        syncStatus: SyncStatus.failed,
        error: e.toString(),
        backgroundSyncAvailable: true, // Allow retry
      ));
    }
  }

  // Background sync method for better UX
  Future<void> performBackgroundSync() async {
    if (!state.hasValue || !state.value!.hasPermission) return;
    
    try {
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel == null) return;
      
      final success = await _contactsRepository.performBackgroundSync(
        currentUser: authState.userModel!,
      );
      
      if (success) {
        // Reload the cached data
        final updatedState = await _loadCachedContacts(state.value!);
        state = AsyncValue.data(updatedState);
      }
    } catch (e) {
      debugPrint('Background sync failed: $e');
    }
  }

  // Request permissions
  Future<void> requestPermission() async {
    if (!state.hasValue) return;
    
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      final hasPermission = await _checkPermissions();
      
      if (hasPermission) {
        state = AsyncValue.data(state.value!.copyWith(
          hasPermission: true,
          isLoading: false,
          syncStatus: SyncStatus.unknown,
        ));
        
        // Auto-load contacts after permission granted
        await syncContacts();
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          hasPermission: false,
          isLoading: false,
          syncStatus: SyncStatus.permissionDenied,
          error: 'Contacts permission is required to sync contacts',
        ));
      }
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Enhanced sync status checking
  Future<bool> checkSyncStatus() async {
    if (!state.hasValue) return true;
    
    try {
      final syncNeeded = await _contactsRepository.isSyncNeeded();
      
      // Update sync status based on check
      state = AsyncValue.data(state.value!.copyWith(
        syncStatus: syncNeeded ? SyncStatus.stale : SyncStatus.upToDate,
        backgroundSyncAvailable: syncNeeded,
      ));
      
      return syncNeeded;
    } catch (e) {
      debugPrint('Error checking sync status: $e');
      return true;
    }
  }

  // Optimized contact operations with local state updates
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

      // Optimistic update - add to local state immediately
      final updatedContacts = List<UserModel>.from(state.value!.registeredContacts);
      if (!updatedContacts.any((contact) => contact.uid == contactUser.uid)) {
        updatedContacts.add(contactUser);
      }

      // Update contacts map
      final updatedMap = Map<String, UserModel>.from(state.value!.contactsMap);
      updatedMap[contactUser.uid] = contactUser;

      state = AsyncValue.data(state.value!.copyWith(
        registeredContacts: updatedContacts,
        contactsMap: updatedMap,
        isLoading: false,
        isSuccessful: true,
      ));
      
      // Update local storage
      await _updateLocalStorage();
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Optimized contact removal
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

      // Optimistic update - remove from local state immediately
      final updatedContacts = List<UserModel>.from(state.value!.registeredContacts)
        ..removeWhere((contact) => contact.uid == contactUser.uid);

      final updatedMap = Map<String, UserModel>.from(state.value!.contactsMap);
      updatedMap.remove(contactUser.uid);

      state = AsyncValue.data(state.value!.copyWith(
        registeredContacts: updatedContacts,
        contactsMap: updatedMap,
        isLoading: false,
        isSuccessful: true,
      ));
      
      await _updateLocalStorage();
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Enhanced contact blocking with local updates
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

      // Update blocked contacts list
      final updatedBlockedContacts = List<UserModel>.from(state.value!.blockedContacts);
      if (!updatedBlockedContacts.any((contact) => contact.uid == contactUser.uid)) {
        updatedBlockedContacts.add(contactUser);
      }

      // Remove from regular contacts if present
      final updatedContacts = List<UserModel>.from(state.value!.registeredContacts)
        ..removeWhere((contact) => contact.uid == contactUser.uid);

      final updatedMap = Map<String, UserModel>.from(state.value!.contactsMap);
      updatedMap.remove(contactUser.uid);

      state = AsyncValue.data(state.value!.copyWith(
        blockedContacts: updatedBlockedContacts,
        registeredContacts: updatedContacts,
        contactsMap: updatedMap,
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

  // Enhanced contact unblocking
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

      // Remove from blocked contacts
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

  // Enhanced blocked contacts loading
  Future<void> loadBlockedContacts() async {
    if (!state.hasValue) return;
    
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
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

  // Enhanced user search with caching
  Future<UserModel?> searchUserByPhoneNumber(String phoneNumber) async {
    try {
      return await ref.read(authenticationProvider.notifier)
          .searchUserByPhoneNumber(phoneNumber: phoneNumber);
    } catch (e) {
      debugPrint('Error searching user: $e');
      return null;
    }
  }

  // Fast contact lookup using the contacts map
  UserModel? getContactByUid(String uid) {
    if (!state.hasValue) return null;
    return state.value!.contactsMap[uid];
  }

  // Get filtered contacts for search
  List<UserModel> getFilteredContacts(String query) {
    if (!state.hasValue) return [];
    
    if (query.isEmpty) return state.value!.registeredContacts;
    
    final lowerQuery = query.toLowerCase();
    return state.value!.registeredContacts.where((contact) =>
      contact.name.toLowerCase().contains(lowerQuery) ||
      contact.phoneNumber.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  // Check if contact exists
  bool isContactRegistered(String uid) {
    if (!state.hasValue) return false;
    return state.value!.contactsMap.containsKey(uid);
  }

  // Clear all cache
  Future<void> clearCache() async {
    try {
      await _contactsRepository.clearCache();
      
      // Reset state to initial
      state = AsyncValue.data(const ContactsState(
        syncStatus: SyncStatus.neverSynced,
        hasPermission: true,
      ));
      
      debugPrint('Contacts cache cleared');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  // Helper method to update local storage
  Future<void> _updateLocalStorage() async {
    if (!state.hasValue || !state.value!.isSuccessful) return;
    
    try {
      final result = ContactSyncResult(
        registeredContacts: state.value!.registeredContacts,
        unregisteredContacts: state.value!.unregisteredContacts,
        syncTime: state.value!.lastSyncTime ?? DateTime.now(),
        syncVersion: state.value!.syncVersion ?? DateTime.now().millisecondsSinceEpoch.toString(),
        contactHashes: {},
      );
      
      await _contactsRepository.saveContactsToStorage(result);
    } catch (e) {
      debugPrint('Error updating local storage: $e');
    }
  }

  // Enhanced invite message generation
  String generateInviteMessage({String? customMessage}) {
    return customMessage ?? 
           'Hey! I\'m using TexGB to chat. It\'s a secure messaging app with great features. Download it here: [App Store Link]';
  }

  // Get sync status info for UI
  Map<String, dynamic> getSyncInfo() {
    if (!state.hasValue) return {};
    
    final currentState = state.value!;
    return {
      'lastSyncTime': currentState.lastSyncTime,
      'syncStatus': currentState.syncStatus.name,
      'isStale': currentState.syncStatus == SyncStatus.stale,
      'canSync': currentState.hasPermission && !currentState.syncInProgress,
      'backgroundSyncAvailable': currentState.backgroundSyncAvailable,
      'totalContacts': currentState.registeredContacts.length,
      'unregisteredCount': currentState.unregisteredContacts.length,
    };
  }
}
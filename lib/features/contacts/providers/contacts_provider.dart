// lib/features/contacts/providers/contacts_provider.dart
// Consolidated contacts provider with all functionality
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/contacts/repositories/contacts_repository.dart';
import 'package:textgb/features/users/models/user_model.dart';

part 'contacts_provider.g.dart';

// Enhanced state class with all functionality
class ContactsState {
  final bool isLoading;
  final bool isSuccessful;
  final List<Contact> deviceContacts;
  final List<SyncedContact> registeredContacts; // Changed to SyncedContact
  final List<Contact> unregisteredContacts;
  final List<UserModel> blockedContacts;
  final String? error;
  final bool syncInProgress;
  final DateTime? lastSyncTime;
  final SyncStatus syncStatus;
  final bool hasPermission;
  final String? syncVersion;
  final Map<String, SyncedContact> contactsMap; // Changed to SyncedContact
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
    List<SyncedContact>? registeredContacts,
    List<Contact>? unregisteredContacts,
    List<UserModel>? blockedContacts,
    String? error,
    bool? syncInProgress,
    DateTime? lastSyncTime,
    SyncStatus? syncStatus,
    bool? hasPermission,
    String? syncVersion,
    Map<String, SyncedContact>? contactsMap,
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
      backgroundSyncAvailable:
          backgroundSyncAvailable ?? this.backgroundSyncAvailable,
    );
  }

  // Update registered contacts and rebuild map
  ContactsState withUpdatedRegisteredContacts(List<SyncedContact> contacts) {
    return copyWith(
      registeredContacts: contacts,
      contactsMap: {for (var contact in contacts) contact.user.uid: contact},
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

      // Create contacts map for efficient lookups (using user.uid as key)
      final contactsMap = {
        for (var contact in cachedData.registeredContacts)
          contact.user.uid: contact
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
      final contacts =
          await _contactsRepository.getDeviceContacts(useCache: useCache);
      state = AsyncValue.data(state.value!.copyWith(
        deviceContacts: contacts,
        isLoading: false,
        isSuccessful: true,
      ));
    } on ContactsPermissionException catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.message,
        syncStatus: SyncStatus.permissionDenied,
      ));
    } on ContactsRepositoryException catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.message,
        syncStatus: SyncStatus.failed,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
        syncStatus: SyncStatus.failed,
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
      syncStatus:
          isBackground ? SyncStatus.backgroundSyncing : SyncStatus.pending,
    ));

    try {
      // Load device contacts if not already loaded or if forced
      List<Contact> deviceContacts = state.value!.deviceContacts;
      if (deviceContacts.isEmpty || forceSync) {
        deviceContacts =
            await _contactsRepository.getDeviceContacts(useCache: !forceSync);
        state = AsyncValue.data(state.value!.copyWith(
          deviceContacts: deviceContacts,
        ));
      }

      // Get current user from new auth system
      final authState = ref.read(authenticationProvider).value;
      if (authState?.currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if we need to sync
      final syncNeeded = forceSync ||
          state.value!.syncStatus == SyncStatus.stale ||
          state.value!.syncStatus == SyncStatus.neverSynced ||
          state.value!.syncStatus == SyncStatus.failed;

      // If no sync needed and not forced, use cached data
      if (!syncNeeded &&
          !forceSync &&
          state.value!.registeredContacts.isNotEmpty &&
          state.value!.lastSyncTime != null) {
        debugPrint(
            'Using cached contacts data from ${state.value!.lastSyncTime}');

        state = AsyncValue.data(state.value!.copyWith(
          syncInProgress: false,
          syncStatus: SyncStatus.upToDate,
          isSuccessful: true,
          backgroundSyncAvailable: false,
        ));

        return;
      }

      // Sync contacts with backend
      final result = await _contactsRepository.syncContactsWithBackend(
        deviceContacts: deviceContacts,
        currentUser: authState!.currentUser!,
        forceSync: forceSync,
      );

      // Create contacts map for efficient lookups (using user.uid as key)
      final contactsMap = {
        for (var contact in result.registeredContacts) contact.user.uid: contact
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
    } on ContactsRepositoryException catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        syncInProgress: false,
        syncStatus: SyncStatus.failed,
        error: e.message,
        backgroundSyncAvailable: true, // Allow retry
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
      final authState = ref.read(authenticationProvider).value;
      if (authState?.currentUser == null) return;

      final success = await _contactsRepository.performBackgroundSync(
        currentUser: authState!.currentUser!,
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

  // Updated contact operations using new backend repository
  Future<void> addContact(UserModel contactUser, {String? localName}) async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      // Use the authentication provider's follow user method instead
      await ref
          .read(authenticationProvider.notifier)
          .followUser(contactUser.uid);

      // Create SyncedContact with local name (or use registered name as fallback)
      final syncedContact = SyncedContact(
        user: contactUser,
        localContactName: localName ?? contactUser.name,
      );

      // Optimistic update - add to local state immediately
      final updatedContacts =
          List<SyncedContact>.from(state.value!.registeredContacts);
      if (!updatedContacts
          .any((contact) => contact.user.uid == contactUser.uid)) {
        updatedContacts.add(syncedContact);
      }

      // Update contacts map
      final updatedMap =
          Map<String, SyncedContact>.from(state.value!.contactsMap);
      updatedMap[contactUser.uid] = syncedContact;

      state = AsyncValue.data(state.value!.copyWith(
        registeredContacts: updatedContacts,
        contactsMap: updatedMap,
        isLoading: false,
        isSuccessful: true,
      ));

      // Update local storage
      await _updateLocalStorage();
    } on ContactsRepositoryException catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.message,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Updated contact removal
  Future<void> removeContact(UserModel contactUser) async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      // Use the authentication provider's unfollow user method
      await ref
          .read(authenticationProvider.notifier)
          .followUser(contactUser.uid);

      // Optimistic update - remove from local state immediately
      final updatedContacts =
          List<SyncedContact>.from(state.value!.registeredContacts)
            ..removeWhere((contact) => contact.user.uid == contactUser.uid);

      final updatedMap =
          Map<String, SyncedContact>.from(state.value!.contactsMap);
      updatedMap.remove(contactUser.uid);

      state = AsyncValue.data(state.value!.copyWith(
        registeredContacts: updatedContacts,
        contactsMap: updatedMap,
        isLoading: false,
        isSuccessful: true,
      ));

      await _updateLocalStorage();
    } on ContactsRepositoryException catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.message,
      ));
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
      // Block contact using the repository
      await _contactsRepository.blockContact(contactUser.uid);

      // Update blocked contacts list
      final updatedBlockedContacts =
          List<UserModel>.from(state.value!.blockedContacts);
      if (!updatedBlockedContacts
          .any((contact) => contact.uid == contactUser.uid)) {
        updatedBlockedContacts.add(contactUser);
      }

      // Remove from regular contacts if present
      final updatedContacts =
          List<SyncedContact>.from(state.value!.registeredContacts)
            ..removeWhere((contact) => contact.user.uid == contactUser.uid);

      final updatedMap =
          Map<String, SyncedContact>.from(state.value!.contactsMap);
      updatedMap.remove(contactUser.uid);

      state = AsyncValue.data(state.value!.copyWith(
        blockedContacts: updatedBlockedContacts,
        registeredContacts: updatedContacts,
        contactsMap: updatedMap,
        isLoading: false,
        isSuccessful: true,
      ));
    } on ContactsRepositoryException catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.message,
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
      // Unblock contact using the repository
      await _contactsRepository.unblockContact(contactUser.uid);

      // Remove from blocked contacts
      final updatedBlockedContacts =
          List<UserModel>.from(state.value!.blockedContacts)
            ..removeWhere((contact) => contact.uid == contactUser.uid);

      state = AsyncValue.data(state.value!.copyWith(
        blockedContacts: updatedBlockedContacts,
        isLoading: false,
        isSuccessful: true,
      ));
    } on ContactsRepositoryException catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.message,
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
      final authState = ref.read(authenticationProvider).value;
      if (authState?.currentUser == null) {
        throw Exception('User not authenticated');
      }

      final blockedContacts = await _contactsRepository.getBlockedContacts();

      state = AsyncValue.data(state.value!.copyWith(
        blockedContacts: blockedContacts,
        isLoading: false,
        isSuccessful: true,
      ));
    } on ContactsRepositoryException catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.message,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Enhanced user search with backend
  Future<UserModel?> searchUserByPhoneNumber(String phoneNumber) async {
    try {
      return await _contactsRepository.searchUserByPhoneNumber(phoneNumber);
    } on ContactsRepositoryException catch (e) {
      debugPrint('Error searching user: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Error searching user: $e');
      return null;
    }
  }

  // Fast contact lookup using the contacts map
  SyncedContact? getContactByUid(String uid) {
    if (!state.hasValue) return null;
    return state.value!.contactsMap[uid];
  }

  // Get filtered contacts for search (uses displayName which is the local contact name)
  List<SyncedContact> getFilteredContacts(String query) {
    if (!state.hasValue) return [];

    if (query.isEmpty) return state.value!.registeredContacts;

    final lowerQuery = query.toLowerCase();
    return state.value!.registeredContacts
        .where((contact) =>
            contact.displayName.toLowerCase().contains(lowerQuery) ||
            contact.user.phoneNumber.toLowerCase().contains(lowerQuery))
        .toList();
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
        syncVersion: state.value!.syncVersion ??
            DateTime.now().millisecondsSinceEpoch.toString(),
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
      'blockedCount': currentState.blockedContacts.length,
      'hasPermission': currentState.hasPermission,
      'isLoading': currentState.isLoading,
      'error': currentState.error,
    };
  }
}

// ========================================
// CONVENIENCE PROVIDERS (All in one file)
// ========================================

// Convenience provider to get registered contacts as SyncedContact (includes local names)
@riverpod
List<SyncedContact> registeredContacts(RegisteredContactsRef ref) {
  final contactsState = ref.watch(contactsNotifierProvider);
  return contactsState.value?.registeredContacts ?? [];
}

// Convenience provider to get registered contacts as UserModel (for backward compatibility)
@riverpod
List<UserModel> registeredContactUsers(RegisteredContactUsersRef ref) {
  final contactsState = ref.watch(contactsNotifierProvider);
  return contactsState.value?.registeredContacts.map((c) => c.user).toList() ??
      [];
}

// Convenience provider to get unregistered contacts
@riverpod
List<Contact> unregisteredContacts(UnregisteredContactsRef ref) {
  final contactsState = ref.watch(contactsNotifierProvider);
  return contactsState.value?.unregisteredContacts ?? [];
}

// Convenience provider to get blocked contacts
@riverpod
List<UserModel> blockedContacts(BlockedContactsRef ref) {
  final contactsState = ref.watch(contactsNotifierProvider);
  return contactsState.value?.blockedContacts ?? [];
}

// Convenience provider to get device contacts
@riverpod
List<Contact> deviceContacts(DeviceContactsRef ref) {
  final contactsState = ref.watch(contactsNotifierProvider);
  return contactsState.value?.deviceContacts ?? [];
}

// Convenience provider to check if contacts are loading
@riverpod
bool isContactsLoading(IsContactsLoadingRef ref) {
  final contactsState = ref.watch(contactsNotifierProvider);
  return contactsState.value?.isLoading ?? false;
}

// Convenience provider to check if sync is in progress
@riverpod
bool isSyncInProgress(IsSyncInProgressRef ref) {
  final contactsState = ref.watch(contactsNotifierProvider);
  return contactsState.value?.syncInProgress ?? false;
}

// Convenience provider to get sync status
@riverpod
SyncStatus contactsSyncStatus(ContactsSyncStatusRef ref) {
  final contactsState = ref.watch(contactsNotifierProvider);
  return contactsState.value?.syncStatus ?? SyncStatus.unknown;
}

// Convenience provider to check if contacts permission is granted
@riverpod
bool hasContactsPermission(HasContactsPermissionRef ref) {
  final contactsState = ref.watch(contactsNotifierProvider);
  return contactsState.value?.hasPermission ?? false;
}

// Convenience provider to get contacts error
@riverpod
String? contactsError(ContactsErrorRef ref) {
  final contactsState = ref.watch(contactsNotifierProvider);
  return contactsState.value?.error;
}

// Convenience provider to get last sync time
@riverpod
DateTime? lastContactsSyncTime(LastContactsSyncTimeRef ref) {
  final contactsState = ref.watch(contactsNotifierProvider);
  return contactsState.value?.lastSyncTime;
}

// Convenience provider to check if background sync is available
@riverpod
bool isBackgroundSyncAvailable(IsBackgroundSyncAvailableRef ref) {
  final contactsState = ref.watch(contactsNotifierProvider);
  return contactsState.value?.backgroundSyncAvailable ?? false;
}

// Helper methods as providers
@riverpod
bool isContactRegistered(IsContactRegisteredRef ref, String uid) {
  final contactsState = ref.watch(contactsNotifierProvider);
  return contactsState.value?.contactsMap.containsKey(uid) ?? false;
}

@riverpod
SyncedContact? getContactByUid(GetContactByUidRef ref, String uid) {
  final contactsState = ref.watch(contactsNotifierProvider);
  return contactsState.value?.contactsMap[uid];
}

// Get just the UserModel for a contact (for backward compatibility)
@riverpod
UserModel? getContactUserByUid(GetContactUserByUidRef ref, String uid) {
  final contactsState = ref.watch(contactsNotifierProvider);
  return contactsState.value?.contactsMap[uid]?.user;
}

@riverpod
bool isContactBlocked(IsContactBlockedRef ref, String uid) {
  final blockedContacts = ref.watch(blockedContactsProvider);
  return blockedContacts.any((contact) => contact.uid == uid);
}

// Filtered contacts provider for search (uses displayName which is the local contact name)
@riverpod
List<SyncedContact> filteredRegisteredContacts(
    FilteredRegisteredContactsRef ref, String query) {
  final contacts = ref.watch(registeredContactsProvider);

  if (query.isEmpty) return contacts;

  final lowerQuery = query.toLowerCase();
  return contacts
      .where((contact) =>
          contact.displayName.toLowerCase().contains(lowerQuery) ||
          contact.user.phoneNumber.toLowerCase().contains(lowerQuery))
      .toList();
}

@riverpod
List<Contact> filteredUnregisteredContacts(
    FilteredUnregisteredContactsRef ref, String query) {
  final contacts = ref.watch(unregisteredContactsProvider);

  if (query.isEmpty) return contacts;

  final lowerQuery = query.toLowerCase();
  return contacts
      .where((contact) =>
          contact.displayName.toLowerCase().contains(lowerQuery) ||
          contact.phones
              .any((phone) => phone.number.toLowerCase().contains(lowerQuery)))
      .toList();
}

// Counts providers
@riverpod
int registeredContactsCount(RegisteredContactsCountRef ref) {
  final contacts = ref.watch(registeredContactsProvider);
  return contacts.length;
}

@riverpod
int unregisteredContactsCount(UnregisteredContactsCountRef ref) {
  final contacts = ref.watch(unregisteredContactsProvider);
  return contacts.length;
}

@riverpod
int blockedContactsCount(BlockedContactsCountRef ref) {
  final contacts = ref.watch(blockedContactsProvider);
  return contacts.length;
}

// Sync info provider
@riverpod
Map<String, dynamic> contactsSyncInfo(ContactsSyncInfoRef ref) {
  final contactsState = ref.watch(contactsNotifierProvider);

  if (contactsState.value == null) return {};

  final state = contactsState.value!;
  return {
    'lastSyncTime': state.lastSyncTime,
    'syncStatus': state.syncStatus.name,
    'isStale': state.syncStatus == SyncStatus.stale,
    'canSync': state.hasPermission && !state.syncInProgress,
    'backgroundSyncAvailable': state.backgroundSyncAvailable,
    'totalContacts': state.registeredContacts.length,
    'unregisteredCount': state.unregisteredContacts.length,
    'blockedCount': state.blockedContacts.length,
    'hasPermission': state.hasPermission,
    'isLoading': state.isLoading,
    'error': state.error,
  };
}

// ========================================
// EXCEPTIONS (All in one file)
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
  const ContactsPermissionException(super.message);

  @override
  String toString() => 'ContactsPermissionException: $message';
}

// Sync related exceptions
class ContactsSyncException extends ContactsRepositoryException {
  const ContactsSyncException(super.message);

  @override
  String toString() => 'ContactsSyncException: $message';
}

// Network related exceptions
class ContactsNetworkException extends ContactsRepositoryException {
  const ContactsNetworkException(super.message);

  @override
  String toString() => 'ContactsNetworkException: $message';
}

// Cache related exceptions
class ContactsCacheException extends ContactsRepositoryException {
  const ContactsCacheException(super.message);

  @override
  String toString() => 'ContactsCacheException: $message';
}

// Device contacts related exceptions
class DeviceContactsException extends ContactsRepositoryException {
  const DeviceContactsException(super.message);

  @override
  String toString() => 'DeviceContactsException: $message';
}

// Search related exceptions
class ContactsSearchException extends ContactsRepositoryException {
  const ContactsSearchException(super.message);

  @override
  String toString() => 'ContactsSearchException: $message';
}

// Block/Unblock related exceptions
class ContactsBlockException extends ContactsRepositoryException {
  const ContactsBlockException(super.message);

  @override
  String toString() => 'ContactsBlockException: $message';
}

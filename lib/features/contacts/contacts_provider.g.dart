// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contacts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$contactsNotifierHash() => r'e7d094bf4c5a82ad5d87c5f6cad06c04ca01f2d3';

/// See also [ContactsNotifier].
@ProviderFor(ContactsNotifier)
final contactsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ContactsNotifier, ContactsState>.internal(
  ContactsNotifier.new,
  name: r'contactsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$contactsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ContactsNotifier = AutoDisposeAsyncNotifier<ContactsState>;
String _$deviceContactsHash() => r'46caa82c67b65d5a65d2fc47b0edac81a82e37fb';

/// See also [deviceContacts].
@ProviderFor(deviceContacts)
final deviceContactsProvider = AutoDisposeProvider<List<Contact>>.internal(
  deviceContacts,
  name: r'deviceContactsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$deviceContactsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DeviceContactsRef = AutoDisposeProviderRef<List<Contact>>;
String _$appContactsHash() => r'82a2d99a12c09876845e3ceb9a85492a71fe3fa7';

/// See also [appContacts].
@ProviderFor(appContacts)
final appContactsProvider = AutoDisposeProvider<List<UserModel>>.internal(
  appContacts,
  name: r'appContactsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appContactsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AppContactsRef = AutoDisposeProviderRef<List<UserModel>>;
String _$suggestedContactsHash() => r'e5b5f8acde37a9c4546fbaa2c4aa09e3e29bd845';

/// See also [suggestedContacts].
@ProviderFor(suggestedContacts)
final suggestedContactsProvider = AutoDisposeProvider<List<UserModel>>.internal(
  suggestedContacts,
  name: r'suggestedContactsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$suggestedContactsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SuggestedContactsRef = AutoDisposeProviderRef<List<UserModel>>;
String _$hasContactsPermissionHash() =>
    r'aba0d26f36a9451c9cb5b2abf7d5a8e0e90a1f7a';

/// See also [hasContactsPermission].
@ProviderFor(hasContactsPermission)
final hasContactsPermissionProvider = AutoDisposeProvider<bool>.internal(
  hasContactsPermission,
  name: r'hasContactsPermissionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasContactsPermissionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef HasContactsPermissionRef = AutoDisposeProviderRef<bool>;
String _$isContactsLoadingHash() => r'fb6de89af99ea7be3f8ef9ca01d467e65878aa1e';

/// See also [isContactsLoading].
@ProviderFor(isContactsLoading)
final isContactsLoadingProvider = AutoDisposeProvider<bool>.internal(
  isContactsLoading,
  name: r'isContactsLoadingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isContactsLoadingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef IsContactsLoadingRef = AutoDisposeProviderRef<bool>;
String _$isContactsSyncingHash() => r'0e3a4f3a89e2df58fc3a55bf88dd34b4b5fa80c6';

/// See also [isContactsSyncing].
@ProviderFor(isContactsSyncing)
final isContactsSyncingProvider = AutoDisposeProvider<bool>.internal(
  isContactsSyncing,
  name: r'isContactsSyncingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isContactsSyncingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef IsContactsSyncingRef = AutoDisposeProviderRef<bool>;
String _$contactsErrorHash() => r'5b45a9fbab304efce72a3c91adf92ec87d7ce3a4';

/// See also [contactsError].
@ProviderFor(contactsError)
final contactsErrorProvider = AutoDisposeProvider<String?>.internal(
  contactsError,
  name: r'contactsErrorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$contactsErrorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ContactsErrorRef = AutoDisposeProviderRef<String?>;
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$propertyRepositoryHash() =>
    r'0551dea7c9b63fe10b093ddf36b443578f0c67a9';

/// See also [propertyRepository].
@ProviderFor(propertyRepository)
final propertyRepositoryProvider =
    AutoDisposeProvider<PropertyRepository>.internal(
  propertyRepository,
  name: r'propertyRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$propertyRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PropertyRepositoryRef = AutoDisposeProviderRef<PropertyRepository>;
String _$propertyByIdHash() => r'ff3183d8e819ba8b5cc4f19c4b65ca843a60b180';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [propertyById].
@ProviderFor(propertyById)
const propertyByIdProvider = PropertyByIdFamily();

/// See also [propertyById].
class PropertyByIdFamily extends Family<AsyncValue<PropertyListingModel?>> {
  /// See also [propertyById].
  const PropertyByIdFamily();

  /// See also [propertyById].
  PropertyByIdProvider call(
    String propertyId,
  ) {
    return PropertyByIdProvider(
      propertyId,
    );
  }

  @override
  PropertyByIdProvider getProviderOverride(
    covariant PropertyByIdProvider provider,
  ) {
    return call(
      provider.propertyId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'propertyByIdProvider';
}

/// See also [propertyById].
class PropertyByIdProvider
    extends AutoDisposeFutureProvider<PropertyListingModel?> {
  /// See also [propertyById].
  PropertyByIdProvider(
    String propertyId,
  ) : this._internal(
          (ref) => propertyById(
            ref as PropertyByIdRef,
            propertyId,
          ),
          from: propertyByIdProvider,
          name: r'propertyByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$propertyByIdHash,
          dependencies: PropertyByIdFamily._dependencies,
          allTransitiveDependencies:
              PropertyByIdFamily._allTransitiveDependencies,
          propertyId: propertyId,
        );

  PropertyByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.propertyId,
  }) : super.internal();

  final String propertyId;

  @override
  Override overrideWith(
    FutureOr<PropertyListingModel?> Function(PropertyByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PropertyByIdProvider._internal(
        (ref) => create(ref as PropertyByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        propertyId: propertyId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<PropertyListingModel?> createElement() {
    return _PropertyByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PropertyByIdProvider && other.propertyId == propertyId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, propertyId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PropertyByIdRef on AutoDisposeFutureProviderRef<PropertyListingModel?> {
  /// The parameter `propertyId` of this provider.
  String get propertyId;
}

class _PropertyByIdProviderElement
    extends AutoDisposeFutureProviderElement<PropertyListingModel?>
    with PropertyByIdRef {
  _PropertyByIdProviderElement(super.provider);

  @override
  String get propertyId => (origin as PropertyByIdProvider).propertyId;
}

String _$propertyCommentsHash() => r'd05c31f8977ebf7c1ba1738dc687163e2f62ed17';

/// See also [propertyComments].
@ProviderFor(propertyComments)
const propertyCommentsProvider = PropertyCommentsFamily();

/// See also [propertyComments].
class PropertyCommentsFamily
    extends Family<AsyncValue<List<PropertyCommentModel>>> {
  /// See also [propertyComments].
  const PropertyCommentsFamily();

  /// See also [propertyComments].
  PropertyCommentsProvider call(
    String propertyId,
  ) {
    return PropertyCommentsProvider(
      propertyId,
    );
  }

  @override
  PropertyCommentsProvider getProviderOverride(
    covariant PropertyCommentsProvider provider,
  ) {
    return call(
      provider.propertyId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'propertyCommentsProvider';
}

/// See also [propertyComments].
class PropertyCommentsProvider
    extends AutoDisposeFutureProvider<List<PropertyCommentModel>> {
  /// See also [propertyComments].
  PropertyCommentsProvider(
    String propertyId,
  ) : this._internal(
          (ref) => propertyComments(
            ref as PropertyCommentsRef,
            propertyId,
          ),
          from: propertyCommentsProvider,
          name: r'propertyCommentsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$propertyCommentsHash,
          dependencies: PropertyCommentsFamily._dependencies,
          allTransitiveDependencies:
              PropertyCommentsFamily._allTransitiveDependencies,
          propertyId: propertyId,
        );

  PropertyCommentsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.propertyId,
  }) : super.internal();

  final String propertyId;

  @override
  Override overrideWith(
    FutureOr<List<PropertyCommentModel>> Function(PropertyCommentsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PropertyCommentsProvider._internal(
        (ref) => create(ref as PropertyCommentsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        propertyId: propertyId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<PropertyCommentModel>> createElement() {
    return _PropertyCommentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PropertyCommentsProvider && other.propertyId == propertyId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, propertyId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PropertyCommentsRef
    on AutoDisposeFutureProviderRef<List<PropertyCommentModel>> {
  /// The parameter `propertyId` of this provider.
  String get propertyId;
}

class _PropertyCommentsProviderElement
    extends AutoDisposeFutureProviderElement<List<PropertyCommentModel>>
    with PropertyCommentsRef {
  _PropertyCommentsProviderElement(super.provider);

  @override
  String get propertyId => (origin as PropertyCommentsProvider).propertyId;
}

String _$propertyLikesHash() => r'51185b79b376a9cdc30f1bba5c5bf3222f257449';

/// See also [propertyLikes].
@ProviderFor(propertyLikes)
const propertyLikesProvider = PropertyLikesFamily();

/// See also [propertyLikes].
class PropertyLikesFamily extends Family<AsyncValue<List<PropertyLikeModel>>> {
  /// See also [propertyLikes].
  const PropertyLikesFamily();

  /// See also [propertyLikes].
  PropertyLikesProvider call(
    String propertyId,
  ) {
    return PropertyLikesProvider(
      propertyId,
    );
  }

  @override
  PropertyLikesProvider getProviderOverride(
    covariant PropertyLikesProvider provider,
  ) {
    return call(
      provider.propertyId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'propertyLikesProvider';
}

/// See also [propertyLikes].
class PropertyLikesProvider
    extends AutoDisposeFutureProvider<List<PropertyLikeModel>> {
  /// See also [propertyLikes].
  PropertyLikesProvider(
    String propertyId,
  ) : this._internal(
          (ref) => propertyLikes(
            ref as PropertyLikesRef,
            propertyId,
          ),
          from: propertyLikesProvider,
          name: r'propertyLikesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$propertyLikesHash,
          dependencies: PropertyLikesFamily._dependencies,
          allTransitiveDependencies:
              PropertyLikesFamily._allTransitiveDependencies,
          propertyId: propertyId,
        );

  PropertyLikesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.propertyId,
  }) : super.internal();

  final String propertyId;

  @override
  Override overrideWith(
    FutureOr<List<PropertyLikeModel>> Function(PropertyLikesRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PropertyLikesProvider._internal(
        (ref) => create(ref as PropertyLikesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        propertyId: propertyId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<PropertyLikeModel>> createElement() {
    return _PropertyLikesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PropertyLikesProvider && other.propertyId == propertyId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, propertyId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PropertyLikesRef
    on AutoDisposeFutureProviderRef<List<PropertyLikeModel>> {
  /// The parameter `propertyId` of this provider.
  String get propertyId;
}

class _PropertyLikesProviderElement
    extends AutoDisposeFutureProviderElement<List<PropertyLikeModel>>
    with PropertyLikesRef {
  _PropertyLikesProviderElement(super.provider);

  @override
  String get propertyId => (origin as PropertyLikesProvider).propertyId;
}

String _$isPropertyLikedHash() => r'f48c27754bd3da9c809ecf31f67aeb48af1f8c8d';

/// See also [isPropertyLiked].
@ProviderFor(isPropertyLiked)
const isPropertyLikedProvider = IsPropertyLikedFamily();

/// See also [isPropertyLiked].
class IsPropertyLikedFamily extends Family<AsyncValue<bool>> {
  /// See also [isPropertyLiked].
  const IsPropertyLikedFamily();

  /// See also [isPropertyLiked].
  IsPropertyLikedProvider call(
    String propertyId,
  ) {
    return IsPropertyLikedProvider(
      propertyId,
    );
  }

  @override
  IsPropertyLikedProvider getProviderOverride(
    covariant IsPropertyLikedProvider provider,
  ) {
    return call(
      provider.propertyId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'isPropertyLikedProvider';
}

/// See also [isPropertyLiked].
class IsPropertyLikedProvider extends AutoDisposeFutureProvider<bool> {
  /// See also [isPropertyLiked].
  IsPropertyLikedProvider(
    String propertyId,
  ) : this._internal(
          (ref) => isPropertyLiked(
            ref as IsPropertyLikedRef,
            propertyId,
          ),
          from: isPropertyLikedProvider,
          name: r'isPropertyLikedProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isPropertyLikedHash,
          dependencies: IsPropertyLikedFamily._dependencies,
          allTransitiveDependencies:
              IsPropertyLikedFamily._allTransitiveDependencies,
          propertyId: propertyId,
        );

  IsPropertyLikedProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.propertyId,
  }) : super.internal();

  final String propertyId;

  @override
  Override overrideWith(
    FutureOr<bool> Function(IsPropertyLikedRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsPropertyLikedProvider._internal(
        (ref) => create(ref as IsPropertyLikedRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        propertyId: propertyId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _IsPropertyLikedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsPropertyLikedProvider && other.propertyId == propertyId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, propertyId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsPropertyLikedRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `propertyId` of this provider.
  String get propertyId;
}

class _IsPropertyLikedProviderElement
    extends AutoDisposeFutureProviderElement<bool> with IsPropertyLikedRef {
  _IsPropertyLikedProviderElement(super.provider);

  @override
  String get propertyId => (origin as IsPropertyLikedProvider).propertyId;
}

String _$availableCitiesHash() => r'fca95f871cbd19f01e3a995ab1b9cf12954f1da2';

/// See also [availableCities].
@ProviderFor(availableCities)
final availableCitiesProvider =
    AutoDisposeFutureProvider<List<String>>.internal(
  availableCities,
  name: r'availableCitiesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$availableCitiesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AvailableCitiesRef = AutoDisposeFutureProviderRef<List<String>>;
String _$propertiesByCityHash() => r'4f568253c70fad9a96b2bac8b4eb557b4bd98362';

/// See also [propertiesByCity].
@ProviderFor(propertiesByCity)
const propertiesByCityProvider = PropertiesByCityFamily();

/// See also [propertiesByCity].
class PropertiesByCityFamily
    extends Family<AsyncValue<List<PropertyListingModel>>> {
  /// See also [propertiesByCity].
  const PropertiesByCityFamily();

  /// See also [propertiesByCity].
  PropertiesByCityProvider call(
    String city,
  ) {
    return PropertiesByCityProvider(
      city,
    );
  }

  @override
  PropertiesByCityProvider getProviderOverride(
    covariant PropertiesByCityProvider provider,
  ) {
    return call(
      provider.city,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'propertiesByCityProvider';
}

/// See also [propertiesByCity].
class PropertiesByCityProvider
    extends AutoDisposeFutureProvider<List<PropertyListingModel>> {
  /// See also [propertiesByCity].
  PropertiesByCityProvider(
    String city,
  ) : this._internal(
          (ref) => propertiesByCity(
            ref as PropertiesByCityRef,
            city,
          ),
          from: propertiesByCityProvider,
          name: r'propertiesByCityProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$propertiesByCityHash,
          dependencies: PropertiesByCityFamily._dependencies,
          allTransitiveDependencies:
              PropertiesByCityFamily._allTransitiveDependencies,
          city: city,
        );

  PropertiesByCityProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.city,
  }) : super.internal();

  final String city;

  @override
  Override overrideWith(
    FutureOr<List<PropertyListingModel>> Function(PropertiesByCityRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PropertiesByCityProvider._internal(
        (ref) => create(ref as PropertiesByCityRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        city: city,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<PropertyListingModel>> createElement() {
    return _PropertiesByCityProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PropertiesByCityProvider && other.city == city;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, city.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PropertiesByCityRef
    on AutoDisposeFutureProviderRef<List<PropertyListingModel>> {
  /// The parameter `city` of this provider.
  String get city;
}

class _PropertiesByCityProviderElement
    extends AutoDisposeFutureProviderElement<List<PropertyListingModel>>
    with PropertiesByCityRef {
  _PropertiesByCityProviderElement(super.provider);

  @override
  String get city => (origin as PropertiesByCityProvider).city;
}

String _$trendingPropertiesHash() =>
    r'f5102fe814d928cb87a400102f8f7485cffdd4dd';

/// See also [trendingProperties].
@ProviderFor(trendingProperties)
final trendingPropertiesProvider =
    AutoDisposeFutureProvider<List<PropertyListingModel>>.internal(
  trendingProperties,
  name: r'trendingPropertiesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trendingPropertiesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TrendingPropertiesRef
    = AutoDisposeFutureProviderRef<List<PropertyListingModel>>;
String _$featuredPropertiesHash() =>
    r'435f897a0840ca5d60f64c8bf2f88da090273721';

/// See also [featuredProperties].
@ProviderFor(featuredProperties)
final featuredPropertiesProvider =
    AutoDisposeFutureProvider<List<PropertyListingModel>>.internal(
  featuredProperties,
  name: r'featuredPropertiesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$featuredPropertiesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FeaturedPropertiesRef
    = AutoDisposeFutureProviderRef<List<PropertyListingModel>>;
String _$propertyAnalyticsHash() => r'bc212ce05dcb88e021b9fa26a33c3f26a26a3a41';

/// See also [propertyAnalytics].
@ProviderFor(propertyAnalytics)
const propertyAnalyticsProvider = PropertyAnalyticsFamily();

/// See also [propertyAnalytics].
class PropertyAnalyticsFamily extends Family<AsyncValue<Map<String, dynamic>>> {
  /// See also [propertyAnalytics].
  const PropertyAnalyticsFamily();

  /// See also [propertyAnalytics].
  PropertyAnalyticsProvider call(
    String propertyId,
  ) {
    return PropertyAnalyticsProvider(
      propertyId,
    );
  }

  @override
  PropertyAnalyticsProvider getProviderOverride(
    covariant PropertyAnalyticsProvider provider,
  ) {
    return call(
      provider.propertyId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'propertyAnalyticsProvider';
}

/// See also [propertyAnalytics].
class PropertyAnalyticsProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>> {
  /// See also [propertyAnalytics].
  PropertyAnalyticsProvider(
    String propertyId,
  ) : this._internal(
          (ref) => propertyAnalytics(
            ref as PropertyAnalyticsRef,
            propertyId,
          ),
          from: propertyAnalyticsProvider,
          name: r'propertyAnalyticsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$propertyAnalyticsHash,
          dependencies: PropertyAnalyticsFamily._dependencies,
          allTransitiveDependencies:
              PropertyAnalyticsFamily._allTransitiveDependencies,
          propertyId: propertyId,
        );

  PropertyAnalyticsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.propertyId,
  }) : super.internal();

  final String propertyId;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>> Function(PropertyAnalyticsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PropertyAnalyticsProvider._internal(
        (ref) => create(ref as PropertyAnalyticsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        propertyId: propertyId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>> createElement() {
    return _PropertyAnalyticsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PropertyAnalyticsProvider && other.propertyId == propertyId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, propertyId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PropertyAnalyticsRef
    on AutoDisposeFutureProviderRef<Map<String, dynamic>> {
  /// The parameter `propertyId` of this provider.
  String get propertyId;
}

class _PropertyAnalyticsProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>>
    with PropertyAnalyticsRef {
  _PropertyAnalyticsProviderElement(super.provider);

  @override
  String get propertyId => (origin as PropertyAnalyticsProvider).propertyId;
}

String _$hostAnalyticsHash() => r'a34e10aa84fff898a4d8a372c14feb147af4caad';

/// See also [hostAnalytics].
@ProviderFor(hostAnalytics)
const hostAnalyticsProvider = HostAnalyticsFamily();

/// See also [hostAnalytics].
class HostAnalyticsFamily extends Family<AsyncValue<Map<String, dynamic>>> {
  /// See also [hostAnalytics].
  const HostAnalyticsFamily();

  /// See also [hostAnalytics].
  HostAnalyticsProvider call(
    String hostId,
  ) {
    return HostAnalyticsProvider(
      hostId,
    );
  }

  @override
  HostAnalyticsProvider getProviderOverride(
    covariant HostAnalyticsProvider provider,
  ) {
    return call(
      provider.hostId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'hostAnalyticsProvider';
}

/// See also [hostAnalytics].
class HostAnalyticsProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>> {
  /// See also [hostAnalytics].
  HostAnalyticsProvider(
    String hostId,
  ) : this._internal(
          (ref) => hostAnalytics(
            ref as HostAnalyticsRef,
            hostId,
          ),
          from: hostAnalyticsProvider,
          name: r'hostAnalyticsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$hostAnalyticsHash,
          dependencies: HostAnalyticsFamily._dependencies,
          allTransitiveDependencies:
              HostAnalyticsFamily._allTransitiveDependencies,
          hostId: hostId,
        );

  HostAnalyticsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.hostId,
  }) : super.internal();

  final String hostId;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>> Function(HostAnalyticsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HostAnalyticsProvider._internal(
        (ref) => create(ref as HostAnalyticsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        hostId: hostId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>> createElement() {
    return _HostAnalyticsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HostAnalyticsProvider && other.hostId == hostId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, hostId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HostAnalyticsRef on AutoDisposeFutureProviderRef<Map<String, dynamic>> {
  /// The parameter `hostId` of this provider.
  String get hostId;
}

class _HostAnalyticsProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>>
    with HostAnalyticsRef {
  _HostAnalyticsProviderElement(super.provider);

  @override
  String get hostId => (origin as HostAnalyticsProvider).hostId;
}

String _$hostInquiriesHash() => r'45378042c06274682167e87313576374dd4406b5';

/// See also [hostInquiries].
@ProviderFor(hostInquiries)
final hostInquiriesProvider =
    AutoDisposeFutureProvider<List<PropertyInquiryModel>>.internal(
  hostInquiries,
  name: r'hostInquiriesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hostInquiriesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HostInquiriesRef
    = AutoDisposeFutureProviderRef<List<PropertyInquiryModel>>;
String _$canCreatePropertyHash() => r'5d3f6bc02d8dd5ea8cddd036e16c18c35433a734';

/// See also [canCreateProperty].
@ProviderFor(canCreateProperty)
final canCreatePropertyProvider = AutoDisposeProvider<bool>.internal(
  canCreateProperty,
  name: r'canCreatePropertyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$canCreatePropertyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CanCreatePropertyRef = AutoDisposeProviderRef<bool>;
String _$hostPropertiesCountHash() =>
    r'cefa58daf2b87bb4b33ce89aa1cdb3b4d1de1322';

/// See also [hostPropertiesCount].
@ProviderFor(hostPropertiesCount)
final hostPropertiesCountProvider = AutoDisposeProvider<int>.internal(
  hostPropertiesCount,
  name: r'hostPropertiesCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hostPropertiesCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HostPropertiesCountRef = AutoDisposeProviderRef<int>;
String _$activeHostPropertiesHash() =>
    r'8253065c937823fdf3aaad1f3bb464ea31a1c95c';

/// See also [activeHostProperties].
@ProviderFor(activeHostProperties)
final activeHostPropertiesProvider =
    AutoDisposeProvider<List<PropertyListingModel>>.internal(
  activeHostProperties,
  name: r'activeHostPropertiesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeHostPropertiesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveHostPropertiesRef
    = AutoDisposeProviderRef<List<PropertyListingModel>>;
String _$pendingHostPropertiesHash() =>
    r'c2996e8c545801d6fe21892322d6d3ad7e097a7a';

/// See also [pendingHostProperties].
@ProviderFor(pendingHostProperties)
final pendingHostPropertiesProvider =
    AutoDisposeProvider<List<PropertyListingModel>>.internal(
  pendingHostProperties,
  name: r'pendingHostPropertiesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingHostPropertiesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingHostPropertiesRef
    = AutoDisposeProviderRef<List<PropertyListingModel>>;
String _$draftHostPropertiesHash() =>
    r'328bd0715c7b97cbb0c0f8bb67fcd60d1164500a';

/// See also [draftHostProperties].
@ProviderFor(draftHostProperties)
final draftHostPropertiesProvider =
    AutoDisposeProvider<List<PropertyListingModel>>.internal(
  draftHostProperties,
  name: r'draftHostPropertiesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$draftHostPropertiesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DraftHostPropertiesRef
    = AutoDisposeProviderRef<List<PropertyListingModel>>;
String _$isPropertyTitleAvailableHash() =>
    r'8c22bafb700e12583d5c1b766b9c7a2b2959470b';

/// See also [isPropertyTitleAvailable].
@ProviderFor(isPropertyTitleAvailable)
const isPropertyTitleAvailableProvider = IsPropertyTitleAvailableFamily();

/// See also [isPropertyTitleAvailable].
class IsPropertyTitleAvailableFamily extends Family<AsyncValue<bool>> {
  /// See also [isPropertyTitleAvailable].
  const IsPropertyTitleAvailableFamily();

  /// See also [isPropertyTitleAvailable].
  IsPropertyTitleAvailableProvider call(
    String title,
    String hostId, {
    String? excludePropertyId,
  }) {
    return IsPropertyTitleAvailableProvider(
      title,
      hostId,
      excludePropertyId: excludePropertyId,
    );
  }

  @override
  IsPropertyTitleAvailableProvider getProviderOverride(
    covariant IsPropertyTitleAvailableProvider provider,
  ) {
    return call(
      provider.title,
      provider.hostId,
      excludePropertyId: provider.excludePropertyId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'isPropertyTitleAvailableProvider';
}

/// See also [isPropertyTitleAvailable].
class IsPropertyTitleAvailableProvider extends AutoDisposeFutureProvider<bool> {
  /// See also [isPropertyTitleAvailable].
  IsPropertyTitleAvailableProvider(
    String title,
    String hostId, {
    String? excludePropertyId,
  }) : this._internal(
          (ref) => isPropertyTitleAvailable(
            ref as IsPropertyTitleAvailableRef,
            title,
            hostId,
            excludePropertyId: excludePropertyId,
          ),
          from: isPropertyTitleAvailableProvider,
          name: r'isPropertyTitleAvailableProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isPropertyTitleAvailableHash,
          dependencies: IsPropertyTitleAvailableFamily._dependencies,
          allTransitiveDependencies:
              IsPropertyTitleAvailableFamily._allTransitiveDependencies,
          title: title,
          hostId: hostId,
          excludePropertyId: excludePropertyId,
        );

  IsPropertyTitleAvailableProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.title,
    required this.hostId,
    required this.excludePropertyId,
  }) : super.internal();

  final String title;
  final String hostId;
  final String? excludePropertyId;

  @override
  Override overrideWith(
    FutureOr<bool> Function(IsPropertyTitleAvailableRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsPropertyTitleAvailableProvider._internal(
        (ref) => create(ref as IsPropertyTitleAvailableRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        title: title,
        hostId: hostId,
        excludePropertyId: excludePropertyId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _IsPropertyTitleAvailableProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsPropertyTitleAvailableProvider &&
        other.title == title &&
        other.hostId == hostId &&
        other.excludePropertyId == excludePropertyId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, title.hashCode);
    hash = _SystemHash.combine(hash, hostId.hashCode);
    hash = _SystemHash.combine(hash, excludePropertyId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsPropertyTitleAvailableRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `title` of this provider.
  String get title;

  /// The parameter `hostId` of this provider.
  String get hostId;

  /// The parameter `excludePropertyId` of this provider.
  String? get excludePropertyId;
}

class _IsPropertyTitleAvailableProviderElement
    extends AutoDisposeFutureProviderElement<bool>
    with IsPropertyTitleAvailableRef {
  _IsPropertyTitleAvailableProviderElement(super.provider);

  @override
  String get title => (origin as IsPropertyTitleAvailableProvider).title;
  @override
  String get hostId => (origin as IsPropertyTitleAvailableProvider).hostId;
  @override
  String? get excludePropertyId =>
      (origin as IsPropertyTitleAvailableProvider).excludePropertyId;
}

String _$propertyFeedHash() => r'9afb0e16cbc5e2a2d0ebf1f769ba66c1e6bdb7f9';

abstract class _$PropertyFeed
    extends BuildlessAutoDisposeAsyncNotifier<PropertyFeedState> {
  late final String? city;
  late final double? maxRate;
  late final double? minRate;
  late final PropertyType? propertyType;

  FutureOr<PropertyFeedState> build({
    String? city,
    double? maxRate,
    double? minRate,
    PropertyType? propertyType,
  });
}

/// See also [PropertyFeed].
@ProviderFor(PropertyFeed)
const propertyFeedProvider = PropertyFeedFamily();

/// See also [PropertyFeed].
class PropertyFeedFamily extends Family<AsyncValue<PropertyFeedState>> {
  /// See also [PropertyFeed].
  const PropertyFeedFamily();

  /// See also [PropertyFeed].
  PropertyFeedProvider call({
    String? city,
    double? maxRate,
    double? minRate,
    PropertyType? propertyType,
  }) {
    return PropertyFeedProvider(
      city: city,
      maxRate: maxRate,
      minRate: minRate,
      propertyType: propertyType,
    );
  }

  @override
  PropertyFeedProvider getProviderOverride(
    covariant PropertyFeedProvider provider,
  ) {
    return call(
      city: provider.city,
      maxRate: provider.maxRate,
      minRate: provider.minRate,
      propertyType: provider.propertyType,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'propertyFeedProvider';
}

/// See also [PropertyFeed].
class PropertyFeedProvider extends AutoDisposeAsyncNotifierProviderImpl<
    PropertyFeed, PropertyFeedState> {
  /// See also [PropertyFeed].
  PropertyFeedProvider({
    String? city,
    double? maxRate,
    double? minRate,
    PropertyType? propertyType,
  }) : this._internal(
          () => PropertyFeed()
            ..city = city
            ..maxRate = maxRate
            ..minRate = minRate
            ..propertyType = propertyType,
          from: propertyFeedProvider,
          name: r'propertyFeedProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$propertyFeedHash,
          dependencies: PropertyFeedFamily._dependencies,
          allTransitiveDependencies:
              PropertyFeedFamily._allTransitiveDependencies,
          city: city,
          maxRate: maxRate,
          minRate: minRate,
          propertyType: propertyType,
        );

  PropertyFeedProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.city,
    required this.maxRate,
    required this.minRate,
    required this.propertyType,
  }) : super.internal();

  final String? city;
  final double? maxRate;
  final double? minRate;
  final PropertyType? propertyType;

  @override
  FutureOr<PropertyFeedState> runNotifierBuild(
    covariant PropertyFeed notifier,
  ) {
    return notifier.build(
      city: city,
      maxRate: maxRate,
      minRate: minRate,
      propertyType: propertyType,
    );
  }

  @override
  Override overrideWith(PropertyFeed Function() create) {
    return ProviderOverride(
      origin: this,
      override: PropertyFeedProvider._internal(
        () => create()
          ..city = city
          ..maxRate = maxRate
          ..minRate = minRate
          ..propertyType = propertyType,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        city: city,
        maxRate: maxRate,
        minRate: minRate,
        propertyType: propertyType,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<PropertyFeed, PropertyFeedState>
      createElement() {
    return _PropertyFeedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PropertyFeedProvider &&
        other.city == city &&
        other.maxRate == maxRate &&
        other.minRate == minRate &&
        other.propertyType == propertyType;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, city.hashCode);
    hash = _SystemHash.combine(hash, maxRate.hashCode);
    hash = _SystemHash.combine(hash, minRate.hashCode);
    hash = _SystemHash.combine(hash, propertyType.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PropertyFeedRef
    on AutoDisposeAsyncNotifierProviderRef<PropertyFeedState> {
  /// The parameter `city` of this provider.
  String? get city;

  /// The parameter `maxRate` of this provider.
  double? get maxRate;

  /// The parameter `minRate` of this provider.
  double? get minRate;

  /// The parameter `propertyType` of this provider.
  PropertyType? get propertyType;
}

class _PropertyFeedProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<PropertyFeed,
        PropertyFeedState> with PropertyFeedRef {
  _PropertyFeedProviderElement(super.provider);

  @override
  String? get city => (origin as PropertyFeedProvider).city;
  @override
  double? get maxRate => (origin as PropertyFeedProvider).maxRate;
  @override
  double? get minRate => (origin as PropertyFeedProvider).minRate;
  @override
  PropertyType? get propertyType =>
      (origin as PropertyFeedProvider).propertyType;
}

String _$globalPropertyUpdatesHash() =>
    r'515312ea361d02a0ab757773a56054204cb26006';

/// See also [GlobalPropertyUpdates].
@ProviderFor(GlobalPropertyUpdates)
final globalPropertyUpdatesProvider = AutoDisposeAsyncNotifierProvider<
    GlobalPropertyUpdates, Map<String, PropertyListingModel>>.internal(
  GlobalPropertyUpdates.new,
  name: r'globalPropertyUpdatesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$globalPropertyUpdatesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GlobalPropertyUpdates
    = AutoDisposeAsyncNotifier<Map<String, PropertyListingModel>>;
String _$hostPropertiesHash() => r'ac23b950da28e5b74db101ba30bfd67db0a801d8';

/// See also [HostProperties].
@ProviderFor(HostProperties)
final hostPropertiesProvider = AutoDisposeAsyncNotifierProvider<HostProperties,
    HostPropertyState>.internal(
  HostProperties.new,
  name: r'hostPropertiesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hostPropertiesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$HostProperties = AutoDisposeAsyncNotifier<HostPropertyState>;
String _$propertyEngagementHash() =>
    r'64b214b62c4ed236244720064594cb0b566bb0d3';

/// See also [PropertyEngagement].
@ProviderFor(PropertyEngagement)
final propertyEngagementProvider = AutoDisposeAsyncNotifierProvider<
    PropertyEngagement, Map<String, dynamic>>.internal(
  PropertyEngagement.new,
  name: r'propertyEngagementProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$propertyEngagementHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PropertyEngagement = AutoDisposeAsyncNotifier<Map<String, dynamic>>;
String _$propertySearchHash() => r'a8b881faf617a466d2c40fafbeca58b3983a5c76';

abstract class _$PropertySearch
    extends BuildlessAutoDisposeAsyncNotifier<List<PropertyListingModel>> {
  late final String query;

  FutureOr<List<PropertyListingModel>> build(
    String query,
  );
}

/// See also [PropertySearch].
@ProviderFor(PropertySearch)
const propertySearchProvider = PropertySearchFamily();

/// See also [PropertySearch].
class PropertySearchFamily
    extends Family<AsyncValue<List<PropertyListingModel>>> {
  /// See also [PropertySearch].
  const PropertySearchFamily();

  /// See also [PropertySearch].
  PropertySearchProvider call(
    String query,
  ) {
    return PropertySearchProvider(
      query,
    );
  }

  @override
  PropertySearchProvider getProviderOverride(
    covariant PropertySearchProvider provider,
  ) {
    return call(
      provider.query,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'propertySearchProvider';
}

/// See also [PropertySearch].
class PropertySearchProvider extends AutoDisposeAsyncNotifierProviderImpl<
    PropertySearch, List<PropertyListingModel>> {
  /// See also [PropertySearch].
  PropertySearchProvider(
    String query,
  ) : this._internal(
          () => PropertySearch()..query = query,
          from: propertySearchProvider,
          name: r'propertySearchProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$propertySearchHash,
          dependencies: PropertySearchFamily._dependencies,
          allTransitiveDependencies:
              PropertySearchFamily._allTransitiveDependencies,
          query: query,
        );

  PropertySearchProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  FutureOr<List<PropertyListingModel>> runNotifierBuild(
    covariant PropertySearch notifier,
  ) {
    return notifier.build(
      query,
    );
  }

  @override
  Override overrideWith(PropertySearch Function() create) {
    return ProviderOverride(
      origin: this,
      override: PropertySearchProvider._internal(
        () => create()..query = query,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<PropertySearch,
      List<PropertyListingModel>> createElement() {
    return _PropertySearchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PropertySearchProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PropertySearchRef
    on AutoDisposeAsyncNotifierProviderRef<List<PropertyListingModel>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _PropertySearchProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<PropertySearch,
        List<PropertyListingModel>> with PropertySearchRef {
  _PropertySearchProviderElement(super.provider);

  @override
  String get query => (origin as PropertySearchProvider).query;
}

String _$propertyFileUploadHash() =>
    r'3403d7c73563c2084e18bfe28b13ea7821ebc351';

/// See also [PropertyFileUpload].
@ProviderFor(PropertyFileUpload)
final propertyFileUploadProvider = AutoDisposeAsyncNotifierProvider<
    PropertyFileUpload, Map<String, dynamic>>.internal(
  PropertyFileUpload.new,
  name: r'propertyFileUploadProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$propertyFileUploadHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PropertyFileUpload = AutoDisposeAsyncNotifier<Map<String, dynamic>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

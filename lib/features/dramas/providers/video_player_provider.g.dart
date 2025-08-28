// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_player_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$isVideoPlayingHash() => r'85bf85c483aadf570b99cd7501d4c57a8f12e850';

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

/// See also [isVideoPlaying].
@ProviderFor(isVideoPlaying)
const isVideoPlayingProvider = IsVideoPlayingFamily();

/// See also [isVideoPlaying].
class IsVideoPlayingFamily extends Family<bool> {
  /// See also [isVideoPlaying].
  const IsVideoPlayingFamily();

  /// See also [isVideoPlaying].
  IsVideoPlayingProvider call(
    String dramaId,
  ) {
    return IsVideoPlayingProvider(
      dramaId,
    );
  }

  @override
  IsVideoPlayingProvider getProviderOverride(
    covariant IsVideoPlayingProvider provider,
  ) {
    return call(
      provider.dramaId,
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
  String? get name => r'isVideoPlayingProvider';
}

/// See also [isVideoPlaying].
class IsVideoPlayingProvider extends AutoDisposeProvider<bool> {
  /// See also [isVideoPlaying].
  IsVideoPlayingProvider(
    String dramaId,
  ) : this._internal(
          (ref) => isVideoPlaying(
            ref as IsVideoPlayingRef,
            dramaId,
          ),
          from: isVideoPlayingProvider,
          name: r'isVideoPlayingProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isVideoPlayingHash,
          dependencies: IsVideoPlayingFamily._dependencies,
          allTransitiveDependencies:
              IsVideoPlayingFamily._allTransitiveDependencies,
          dramaId: dramaId,
        );

  IsVideoPlayingProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.dramaId,
  }) : super.internal();

  final String dramaId;

  @override
  Override overrideWith(
    bool Function(IsVideoPlayingRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsVideoPlayingProvider._internal(
        (ref) => create(ref as IsVideoPlayingRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        dramaId: dramaId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _IsVideoPlayingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsVideoPlayingProvider && other.dramaId == dramaId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, dramaId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsVideoPlayingRef on AutoDisposeProviderRef<bool> {
  /// The parameter `dramaId` of this provider.
  String get dramaId;
}

class _IsVideoPlayingProviderElement extends AutoDisposeProviderElement<bool>
    with IsVideoPlayingRef {
  _IsVideoPlayingProviderElement(super.provider);

  @override
  String get dramaId => (origin as IsVideoPlayingProvider).dramaId;
}

String _$videoProgressHash() => r'fb115da2f7b5e6f2806306dcc78fa397fd8658c5';

/// See also [videoProgress].
@ProviderFor(videoProgress)
const videoProgressProvider = VideoProgressFamily();

/// See also [videoProgress].
class VideoProgressFamily extends Family<double> {
  /// See also [videoProgress].
  const VideoProgressFamily();

  /// See also [videoProgress].
  VideoProgressProvider call(
    String dramaId,
  ) {
    return VideoProgressProvider(
      dramaId,
    );
  }

  @override
  VideoProgressProvider getProviderOverride(
    covariant VideoProgressProvider provider,
  ) {
    return call(
      provider.dramaId,
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
  String? get name => r'videoProgressProvider';
}

/// See also [videoProgress].
class VideoProgressProvider extends AutoDisposeProvider<double> {
  /// See also [videoProgress].
  VideoProgressProvider(
    String dramaId,
  ) : this._internal(
          (ref) => videoProgress(
            ref as VideoProgressRef,
            dramaId,
          ),
          from: videoProgressProvider,
          name: r'videoProgressProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$videoProgressHash,
          dependencies: VideoProgressFamily._dependencies,
          allTransitiveDependencies:
              VideoProgressFamily._allTransitiveDependencies,
          dramaId: dramaId,
        );

  VideoProgressProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.dramaId,
  }) : super.internal();

  final String dramaId;

  @override
  Override overrideWith(
    double Function(VideoProgressRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: VideoProgressProvider._internal(
        (ref) => create(ref as VideoProgressRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        dramaId: dramaId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<double> createElement() {
    return _VideoProgressProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VideoProgressProvider && other.dramaId == dramaId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, dramaId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin VideoProgressRef on AutoDisposeProviderRef<double> {
  /// The parameter `dramaId` of this provider.
  String get dramaId;
}

class _VideoProgressProviderElement extends AutoDisposeProviderElement<double>
    with VideoProgressRef {
  _VideoProgressProviderElement(super.provider);

  @override
  String get dramaId => (origin as VideoProgressProvider).dramaId;
}

String _$currentEpisodeTitleHash() =>
    r'5a249afc78620219308169cfca059e8f35d3db86';

/// See also [currentEpisodeTitle].
@ProviderFor(currentEpisodeTitle)
const currentEpisodeTitleProvider = CurrentEpisodeTitleFamily();

/// See also [currentEpisodeTitle].
class CurrentEpisodeTitleFamily extends Family<String> {
  /// See also [currentEpisodeTitle].
  const CurrentEpisodeTitleFamily();

  /// See also [currentEpisodeTitle].
  CurrentEpisodeTitleProvider call(
    String dramaId,
  ) {
    return CurrentEpisodeTitleProvider(
      dramaId,
    );
  }

  @override
  CurrentEpisodeTitleProvider getProviderOverride(
    covariant CurrentEpisodeTitleProvider provider,
  ) {
    return call(
      provider.dramaId,
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
  String? get name => r'currentEpisodeTitleProvider';
}

/// See also [currentEpisodeTitle].
class CurrentEpisodeTitleProvider extends AutoDisposeProvider<String> {
  /// See also [currentEpisodeTitle].
  CurrentEpisodeTitleProvider(
    String dramaId,
  ) : this._internal(
          (ref) => currentEpisodeTitle(
            ref as CurrentEpisodeTitleRef,
            dramaId,
          ),
          from: currentEpisodeTitleProvider,
          name: r'currentEpisodeTitleProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$currentEpisodeTitleHash,
          dependencies: CurrentEpisodeTitleFamily._dependencies,
          allTransitiveDependencies:
              CurrentEpisodeTitleFamily._allTransitiveDependencies,
          dramaId: dramaId,
        );

  CurrentEpisodeTitleProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.dramaId,
  }) : super.internal();

  final String dramaId;

  @override
  Override overrideWith(
    String Function(CurrentEpisodeTitleRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CurrentEpisodeTitleProvider._internal(
        (ref) => create(ref as CurrentEpisodeTitleRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        dramaId: dramaId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<String> createElement() {
    return _CurrentEpisodeTitleProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentEpisodeTitleProvider && other.dramaId == dramaId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, dramaId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CurrentEpisodeTitleRef on AutoDisposeProviderRef<String> {
  /// The parameter `dramaId` of this provider.
  String get dramaId;
}

class _CurrentEpisodeTitleProviderElement
    extends AutoDisposeProviderElement<String> with CurrentEpisodeTitleRef {
  _CurrentEpisodeTitleProviderElement(super.provider);

  @override
  String get dramaId => (origin as CurrentEpisodeTitleProvider).dramaId;
}

String _$canPlayNextHash() => r'a0a1f22e0ee7535c72dfad2b0736e953b048a5fa';

/// See also [canPlayNext].
@ProviderFor(canPlayNext)
const canPlayNextProvider = CanPlayNextFamily();

/// See also [canPlayNext].
class CanPlayNextFamily extends Family<bool> {
  /// See also [canPlayNext].
  const CanPlayNextFamily();

  /// See also [canPlayNext].
  CanPlayNextProvider call(
    String dramaId,
  ) {
    return CanPlayNextProvider(
      dramaId,
    );
  }

  @override
  CanPlayNextProvider getProviderOverride(
    covariant CanPlayNextProvider provider,
  ) {
    return call(
      provider.dramaId,
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
  String? get name => r'canPlayNextProvider';
}

/// See also [canPlayNext].
class CanPlayNextProvider extends AutoDisposeProvider<bool> {
  /// See also [canPlayNext].
  CanPlayNextProvider(
    String dramaId,
  ) : this._internal(
          (ref) => canPlayNext(
            ref as CanPlayNextRef,
            dramaId,
          ),
          from: canPlayNextProvider,
          name: r'canPlayNextProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$canPlayNextHash,
          dependencies: CanPlayNextFamily._dependencies,
          allTransitiveDependencies:
              CanPlayNextFamily._allTransitiveDependencies,
          dramaId: dramaId,
        );

  CanPlayNextProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.dramaId,
  }) : super.internal();

  final String dramaId;

  @override
  Override overrideWith(
    bool Function(CanPlayNextRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CanPlayNextProvider._internal(
        (ref) => create(ref as CanPlayNextRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        dramaId: dramaId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _CanPlayNextProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CanPlayNextProvider && other.dramaId == dramaId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, dramaId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CanPlayNextRef on AutoDisposeProviderRef<bool> {
  /// The parameter `dramaId` of this provider.
  String get dramaId;
}

class _CanPlayNextProviderElement extends AutoDisposeProviderElement<bool>
    with CanPlayNextRef {
  _CanPlayNextProviderElement(super.provider);

  @override
  String get dramaId => (origin as CanPlayNextProvider).dramaId;
}

String _$canPlayPreviousHash() => r'7618abf55dec9bbde400905cccd84e2cd925e13b';

/// See also [canPlayPrevious].
@ProviderFor(canPlayPrevious)
const canPlayPreviousProvider = CanPlayPreviousFamily();

/// See also [canPlayPrevious].
class CanPlayPreviousFamily extends Family<bool> {
  /// See also [canPlayPrevious].
  const CanPlayPreviousFamily();

  /// See also [canPlayPrevious].
  CanPlayPreviousProvider call(
    String dramaId,
  ) {
    return CanPlayPreviousProvider(
      dramaId,
    );
  }

  @override
  CanPlayPreviousProvider getProviderOverride(
    covariant CanPlayPreviousProvider provider,
  ) {
    return call(
      provider.dramaId,
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
  String? get name => r'canPlayPreviousProvider';
}

/// See also [canPlayPrevious].
class CanPlayPreviousProvider extends AutoDisposeProvider<bool> {
  /// See also [canPlayPrevious].
  CanPlayPreviousProvider(
    String dramaId,
  ) : this._internal(
          (ref) => canPlayPrevious(
            ref as CanPlayPreviousRef,
            dramaId,
          ),
          from: canPlayPreviousProvider,
          name: r'canPlayPreviousProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$canPlayPreviousHash,
          dependencies: CanPlayPreviousFamily._dependencies,
          allTransitiveDependencies:
              CanPlayPreviousFamily._allTransitiveDependencies,
          dramaId: dramaId,
        );

  CanPlayPreviousProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.dramaId,
  }) : super.internal();

  final String dramaId;

  @override
  Override overrideWith(
    bool Function(CanPlayPreviousRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CanPlayPreviousProvider._internal(
        (ref) => create(ref as CanPlayPreviousRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        dramaId: dramaId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _CanPlayPreviousProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CanPlayPreviousProvider && other.dramaId == dramaId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, dramaId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CanPlayPreviousRef on AutoDisposeProviderRef<bool> {
  /// The parameter `dramaId` of this provider.
  String get dramaId;
}

class _CanPlayPreviousProviderElement extends AutoDisposeProviderElement<bool>
    with CanPlayPreviousRef {
  _CanPlayPreviousProviderElement(super.provider);

  @override
  String get dramaId => (origin as CanPlayPreviousProvider).dramaId;
}

String _$videoControllerHash() => r'73fdc0ffc553817061ba124505cff73e691210a1';

/// See also [videoController].
@ProviderFor(videoController)
const videoControllerProvider = VideoControllerFamily();

/// See also [videoController].
class VideoControllerFamily extends Family<VideoPlayerController?> {
  /// See also [videoController].
  const VideoControllerFamily();

  /// See also [videoController].
  VideoControllerProvider call(
    String dramaId,
  ) {
    return VideoControllerProvider(
      dramaId,
    );
  }

  @override
  VideoControllerProvider getProviderOverride(
    covariant VideoControllerProvider provider,
  ) {
    return call(
      provider.dramaId,
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
  String? get name => r'videoControllerProvider';
}

/// See also [videoController].
class VideoControllerProvider
    extends AutoDisposeProvider<VideoPlayerController?> {
  /// See also [videoController].
  VideoControllerProvider(
    String dramaId,
  ) : this._internal(
          (ref) => videoController(
            ref as VideoControllerRef,
            dramaId,
          ),
          from: videoControllerProvider,
          name: r'videoControllerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$videoControllerHash,
          dependencies: VideoControllerFamily._dependencies,
          allTransitiveDependencies:
              VideoControllerFamily._allTransitiveDependencies,
          dramaId: dramaId,
        );

  VideoControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.dramaId,
  }) : super.internal();

  final String dramaId;

  @override
  Override overrideWith(
    VideoPlayerController? Function(VideoControllerRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: VideoControllerProvider._internal(
        (ref) => create(ref as VideoControllerRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        dramaId: dramaId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<VideoPlayerController?> createElement() {
    return _VideoControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VideoControllerProvider && other.dramaId == dramaId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, dramaId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin VideoControllerRef on AutoDisposeProviderRef<VideoPlayerController?> {
  /// The parameter `dramaId` of this provider.
  String get dramaId;
}

class _VideoControllerProviderElement
    extends AutoDisposeProviderElement<VideoPlayerController?>
    with VideoControllerRef {
  _VideoControllerProviderElement(super.provider);

  @override
  String get dramaId => (origin as VideoControllerProvider).dramaId;
}

String _$currentEpisodeNumberHash() =>
    r'f52d988342aff315de18d9d8a8dcf6b188156881';

/// See also [currentEpisodeNumber].
@ProviderFor(currentEpisodeNumber)
const currentEpisodeNumberProvider = CurrentEpisodeNumberFamily();

/// See also [currentEpisodeNumber].
class CurrentEpisodeNumberFamily extends Family<int?> {
  /// See also [currentEpisodeNumber].
  const CurrentEpisodeNumberFamily();

  /// See also [currentEpisodeNumber].
  CurrentEpisodeNumberProvider call(
    String dramaId,
  ) {
    return CurrentEpisodeNumberProvider(
      dramaId,
    );
  }

  @override
  CurrentEpisodeNumberProvider getProviderOverride(
    covariant CurrentEpisodeNumberProvider provider,
  ) {
    return call(
      provider.dramaId,
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
  String? get name => r'currentEpisodeNumberProvider';
}

/// See also [currentEpisodeNumber].
class CurrentEpisodeNumberProvider extends AutoDisposeProvider<int?> {
  /// See also [currentEpisodeNumber].
  CurrentEpisodeNumberProvider(
    String dramaId,
  ) : this._internal(
          (ref) => currentEpisodeNumber(
            ref as CurrentEpisodeNumberRef,
            dramaId,
          ),
          from: currentEpisodeNumberProvider,
          name: r'currentEpisodeNumberProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$currentEpisodeNumberHash,
          dependencies: CurrentEpisodeNumberFamily._dependencies,
          allTransitiveDependencies:
              CurrentEpisodeNumberFamily._allTransitiveDependencies,
          dramaId: dramaId,
        );

  CurrentEpisodeNumberProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.dramaId,
  }) : super.internal();

  final String dramaId;

  @override
  Override overrideWith(
    int? Function(CurrentEpisodeNumberRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CurrentEpisodeNumberProvider._internal(
        (ref) => create(ref as CurrentEpisodeNumberRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        dramaId: dramaId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<int?> createElement() {
    return _CurrentEpisodeNumberProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentEpisodeNumberProvider && other.dramaId == dramaId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, dramaId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CurrentEpisodeNumberRef on AutoDisposeProviderRef<int?> {
  /// The parameter `dramaId` of this provider.
  String get dramaId;
}

class _CurrentEpisodeNumberProviderElement
    extends AutoDisposeProviderElement<int?> with CurrentEpisodeNumberRef {
  _CurrentEpisodeNumberProviderElement(super.provider);

  @override
  String get dramaId => (origin as CurrentEpisodeNumberProvider).dramaId;
}

String _$videoPlayerNotifierHash() =>
    r'6d543d3fd145ea1838255e2a348151ff6f0ce7bb';

abstract class _$VideoPlayerNotifier
    extends BuildlessAutoDisposeNotifier<VideoPlayerState> {
  late final String dramaId;

  VideoPlayerState build(
    String dramaId,
  );
}

/// See also [VideoPlayerNotifier].
@ProviderFor(VideoPlayerNotifier)
const videoPlayerNotifierProvider = VideoPlayerNotifierFamily();

/// See also [VideoPlayerNotifier].
class VideoPlayerNotifierFamily extends Family<VideoPlayerState> {
  /// See also [VideoPlayerNotifier].
  const VideoPlayerNotifierFamily();

  /// See also [VideoPlayerNotifier].
  VideoPlayerNotifierProvider call(
    String dramaId,
  ) {
    return VideoPlayerNotifierProvider(
      dramaId,
    );
  }

  @override
  VideoPlayerNotifierProvider getProviderOverride(
    covariant VideoPlayerNotifierProvider provider,
  ) {
    return call(
      provider.dramaId,
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
  String? get name => r'videoPlayerNotifierProvider';
}

/// See also [VideoPlayerNotifier].
class VideoPlayerNotifierProvider extends AutoDisposeNotifierProviderImpl<
    VideoPlayerNotifier, VideoPlayerState> {
  /// See also [VideoPlayerNotifier].
  VideoPlayerNotifierProvider(
    String dramaId,
  ) : this._internal(
          () => VideoPlayerNotifier()..dramaId = dramaId,
          from: videoPlayerNotifierProvider,
          name: r'videoPlayerNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$videoPlayerNotifierHash,
          dependencies: VideoPlayerNotifierFamily._dependencies,
          allTransitiveDependencies:
              VideoPlayerNotifierFamily._allTransitiveDependencies,
          dramaId: dramaId,
        );

  VideoPlayerNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.dramaId,
  }) : super.internal();

  final String dramaId;

  @override
  VideoPlayerState runNotifierBuild(
    covariant VideoPlayerNotifier notifier,
  ) {
    return notifier.build(
      dramaId,
    );
  }

  @override
  Override overrideWith(VideoPlayerNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: VideoPlayerNotifierProvider._internal(
        () => create()..dramaId = dramaId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        dramaId: dramaId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<VideoPlayerNotifier, VideoPlayerState>
      createElement() {
    return _VideoPlayerNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VideoPlayerNotifierProvider && other.dramaId == dramaId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, dramaId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin VideoPlayerNotifierRef
    on AutoDisposeNotifierProviderRef<VideoPlayerState> {
  /// The parameter `dramaId` of this provider.
  String get dramaId;
}

class _VideoPlayerNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<VideoPlayerNotifier,
        VideoPlayerState> with VideoPlayerNotifierRef {
  _VideoPlayerNotifierProviderElement(super.provider);

  @override
  String get dramaId => (origin as VideoPlayerNotifierProvider).dramaId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

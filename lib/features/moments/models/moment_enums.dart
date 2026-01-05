// ===============================
// Moment Feature Enums
// ===============================

/// Visibility level for a moment post
enum MomentVisibility {
  all, // Visible to all mutual contacts
  private, // Only visible to post owner
  custom, // Custom whitelist/blacklist
}

/// Media type for moment content
enum MomentMediaType {
  text, // Text only
  images, // One or more images (max 9)
  video, // Single video
}

/// Timeline visibility settings (for user profile)
enum TimelineVisibility {
  all, // Show all moments
  lastThreeDays, // Only show last 3 days
  lastSixMonths, // Only show last 6 months
}

/// Moment interaction type
enum MomentInteractionType {
  like,
  comment,
}

/// Extensions for enum serialization
extension MomentVisibilityExtension on MomentVisibility {
  String toJson() {
    switch (this) {
      case MomentVisibility.all:
        return 'public';
      case MomentVisibility.private:
        return 'private';
      case MomentVisibility.custom:
        return 'friends';
    }
  }

  String get displayName {
    switch (this) {
      case MomentVisibility.all:
        return 'Public';
      case MomentVisibility.private:
        return 'Private';
      case MomentVisibility.custom:
        return 'Custom';
    }
  }

  static MomentVisibility fromJson(String value) {
    switch (value.toLowerCase()) {
      case 'all':
      case 'public':
        return MomentVisibility.all;
      case 'private':
        return MomentVisibility.private;
      case 'custom':
      case 'friends':
        return MomentVisibility.custom;
      default:
        return MomentVisibility.all;
    }
  }
}

extension MomentMediaTypeExtension on MomentMediaType {
  String toJson() {
    switch (this) {
      case MomentMediaType.text:
        return 'text';
      case MomentMediaType.images:
        return 'images';
      case MomentMediaType.video:
        return 'video';
    }
  }

  static MomentMediaType fromJson(String value) {
    switch (value.toLowerCase()) {
      case 'text':
        return MomentMediaType.text;
      case 'images':
        return MomentMediaType.images;
      case 'video':
        return MomentMediaType.video;
      default:
        return MomentMediaType.text;
    }
  }
}

extension TimelineVisibilityExtension on TimelineVisibility {
  String toJson() {
    switch (this) {
      case TimelineVisibility.all:
        return 'all';
      case TimelineVisibility.lastThreeDays:
        return 'last_3_days';
      case TimelineVisibility.lastSixMonths:
        return 'last_6_months';
    }
  }

  static TimelineVisibility fromJson(String value) {
    switch (value.toLowerCase()) {
      case 'all':
        return TimelineVisibility.all;
      case 'last_3_days':
        return TimelineVisibility.lastThreeDays;
      case 'last_6_months':
        return TimelineVisibility.lastSixMonths;
      default:
        return TimelineVisibility.all;
    }
  }
}

// ===============================
// Privacy Selection Result
// Holds both visibility type and contact IDs
// ===============================

class PrivacySelection {
  final MomentVisibility visibility;
  final List<String> visibleTo;
  final List<String> hiddenFrom;

  const PrivacySelection({
    required this.visibility,
    this.visibleTo = const [],
    this.hiddenFrom = const [],
  });

  PrivacySelection copyWith({
    MomentVisibility? visibility,
    List<String>? visibleTo,
    List<String>? hiddenFrom,
  }) {
    return PrivacySelection(
      visibility: visibility ?? this.visibility,
      visibleTo: visibleTo ?? this.visibleTo,
      hiddenFrom: hiddenFrom ?? this.hiddenFrom,
    );
  }

  bool get hasCustomPrivacy => visibleTo.isNotEmpty || hiddenFrom.isNotEmpty;

  String get displayText {
    if (hiddenFrom.isNotEmpty) {
      return 'Hidden from ${hiddenFrom.length} contact${hiddenFrom.length > 1 ? 's' : ''}';
    }
    if (visibleTo.isNotEmpty) {
      return 'Visible to ${visibleTo.length} contact${visibleTo.length > 1 ? 's' : ''}';
    }
    return visibility.displayName;
  }
}

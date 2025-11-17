// ===============================
// Status Enums
// Enums for status feature
// ===============================

// ===============================
// STATUS MEDIA TYPE
// ===============================

enum StatusMediaType {
  text,
  image,
  video,
}

extension StatusMediaTypeExtension on StatusMediaType {
  String toJson() {
    switch (this) {
      case StatusMediaType.text:
        return 'text';
      case StatusMediaType.image:
        return 'image';
      case StatusMediaType.video:
        return 'video';
    }
  }

  static StatusMediaType fromJson(String json) {
    switch (json.toLowerCase()) {
      case 'text':
        return StatusMediaType.text;
      case 'image':
        return StatusMediaType.image;
      case 'video':
        return StatusMediaType.video;
      default:
        return StatusMediaType.text;
    }
  }

  String get displayName {
    switch (this) {
      case StatusMediaType.text:
        return 'Text';
      case StatusMediaType.image:
        return 'Image';
      case StatusMediaType.video:
        return 'Video';
    }
  }

  bool get isMedia => this == StatusMediaType.image || this == StatusMediaType.video;
  bool get isText => this == StatusMediaType.text;
  bool get isImage => this == StatusMediaType.image;
  bool get isVideo => this == StatusMediaType.video;
}

// ===============================
// STATUS VISIBILITY
// ===============================

enum StatusVisibility {
  all,
  closeFriends,
  custom,
  onlyMe,
}

extension StatusVisibilityExtension on StatusVisibility {
  String toJson() {
    switch (this) {
      case StatusVisibility.all:
        return 'all';
      case StatusVisibility.closeFriends:
        return 'close_friends';
      case StatusVisibility.custom:
        return 'custom';
      case StatusVisibility.onlyMe:
        return 'only_me';
    }
  }

  static StatusVisibility fromJson(String json) {
    switch (json.toLowerCase()) {
      case 'all':
        return StatusVisibility.all;
      case 'close_friends':
      case 'closefriends':
        return StatusVisibility.closeFriends;
      case 'custom':
        return StatusVisibility.custom;
      case 'only_me':
      case 'onlyme':
        return StatusVisibility.onlyMe;
      default:
        return StatusVisibility.all;
    }
  }

  String get displayName {
    switch (this) {
      case StatusVisibility.all:
        return 'All Contacts';
      case StatusVisibility.closeFriends:
        return 'Close Friends';
      case StatusVisibility.custom:
        return 'Custom';
      case StatusVisibility.onlyMe:
        return 'Only Me';
    }
  }

  String get description {
    switch (this) {
      case StatusVisibility.all:
        return 'Share with all your contacts';
      case StatusVisibility.closeFriends:
        return 'Share with close friends only';
      case StatusVisibility.custom:
        return 'Choose specific contacts';
      case StatusVisibility.onlyMe:
        return 'Only you can see this status';
    }
  }
}

// ===============================
// TEXT STATUS BACKGROUND
// ===============================

enum TextStatusBackground {
  gradient1,
  gradient2,
  gradient3,
  gradient4,
  gradient5,
  gradient6,
  solid1,
  solid2,
  solid3,
  solid4,
}

extension TextStatusBackgroundExtension on TextStatusBackground {
  String toJson() {
    return name;
  }

  static TextStatusBackground fromJson(String json) {
    return TextStatusBackground.values.firstWhere(
      (e) => e.name == json,
      orElse: () => TextStatusBackground.gradient1,
    );
  }

  List<String> get colors {
    switch (this) {
      case TextStatusBackground.gradient1:
        return ['#FF6B6B', '#FF8E53']; // Red to Orange
      case TextStatusBackground.gradient2:
        return ['#4FACFE', '#00F2FE']; // Blue to Cyan
      case TextStatusBackground.gradient3:
        return ['#43E97B', '#38F9D7']; // Green to Teal
      case TextStatusBackground.gradient4:
        return ['#FA709A', '#FEE140']; // Pink to Yellow
      case TextStatusBackground.gradient5:
        return ['#A8EDEA', '#FED6E3']; // Mint to Pink
      case TextStatusBackground.gradient6:
        return ['#FF9A56', '#FF6A88']; // Orange to Pink
      case TextStatusBackground.solid1:
        return ['#1E3A8A', '#1E3A8A']; // Navy Blue
      case TextStatusBackground.solid2:
        return ['#7C3AED', '#7C3AED']; // Purple
      case TextStatusBackground.solid3:
        return ['#059669', '#059669']; // Green
      case TextStatusBackground.solid4:
        return ['#DC2626', '#DC2626']; // Red
    }
  }

  bool get isGradient => index < 6;
}

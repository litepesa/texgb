// ===============================
// Status Theme
// Consistent styling for status feature
// ===============================

import 'package:flutter/material.dart';

class StatusTheme {
  StatusTheme._();

  // ===============================
  // COLORS
  // ===============================

  // Primary colors
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryPurple = Color(0xFF8B5CF6);

  // Ring gradient colors
  static const List<Color> unviewedRingGradient = [
    Color(0xFFFF6B6B), // Red
    Color(0xFF4ECDC4), // Teal
  ];

  static const List<Color> viewedRingGradient = [
    Color(0xFF9CA3AF), // Gray
    Color(0xFF9CA3AF), // Gray
  ];

  static const List<Color> myStatusRingGradient = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
  ];

  // Background colors
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkOverlay = Color(0x80000000); // 50% black

  // Text colors
  static const Color lightText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFB3B3B3);
  static const Color mutedText = Color(0xFF666666);

  // Interaction button gradients
  static const List<Color> giftGradient = [
    Color(0xFFFFD700), // Gold
    Color(0xFFFF8C00), // Orange
  ];

  static const List<Color> saveGradient = [
    Color(0xFF10B981), // Green
    Color(0xFF059669), // Dark Green
  ];

  static const List<Color> likeGradient = [
    Color(0xFFFF5252), // Red
    Color(0xFFFF1744), // Dark Red
  ];

  static const List<Color> dmGradient = [
    Color(0xFF7E57C2), // Purple
    Color(0xFF5E35B1), // Dark Purple
  ];

  // Status bar colors
  static const Color progressActive = Color(0xFFFFFFFF);
  static const Color progressInactive = Color(0x4DFFFFFF); // 30% white

  // ===============================
  // SIZES
  // ===============================

  // Ring sizes
  static const double ringAvatarSize = 64.0;
  static const double ringBorderWidth = 3.0;
  static const double ringSpacing = 12.0;
  static const double ringPadding = 8.0;

  // My status special ring size (larger)
  static const double myStatusAvatarSize = 72.0;

  // Status viewer
  static const double viewerProgressHeight = 2.0;
  static const double viewerProgressSpacing = 4.0;
  static const double viewerPadding = 16.0;
  static const double viewerTopPadding = 48.0; // Include status bar

  // Interaction buttons
  static const double interactionButtonSize = 48.0;
  static const double interactionIconSize = 28.0;
  static const double interactionSpacing = 12.0;
  static const double interactionBottomPadding = 24.0;

  // Text status
  static const double textStatusMaxWidth = 340.0;
  static const double textStatusMinFontSize = 20.0;
  static const double textStatusMaxFontSize = 32.0;
  static const double textStatusPadding = 24.0;

  // Viewer info section
  static const double avatarSize = 36.0;
  static const double iconSize = 24.0;
  static const double smallIconSize = 16.0;

  // ===============================
  // TEXT STYLES
  // ===============================

  static const TextStyle userNameStyle = TextStyle(
    color: lightText,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    shadows: [
      Shadow(
        color: Color(0x80000000),
        offset: Offset(0, 1),
        blurRadius: 4,
      ),
    ],
  );

  static const TextStyle timeStyle = TextStyle(
    color: secondaryText,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    shadows: [
      Shadow(
        color: Color(0x80000000),
        offset: Offset(0, 1),
        blurRadius: 4,
      ),
    ],
  );

  static const TextStyle viewCountStyle = TextStyle(
    color: secondaryText,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle interactionLabelStyle = TextStyle(
    color: lightText,
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle textStatusStyle = TextStyle(
    color: lightText,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle ringLabelStyle = TextStyle(
    color: Color(0xFF1F2937),
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle ringTimeStyle = TextStyle(
    color: Color(0xFF6B7280),
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );

  // ===============================
  // GRADIENTS
  // ===============================

  static const LinearGradient unviewedRingGradientShader = LinearGradient(
    colors: unviewedRingGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient viewedRingGradientShader = LinearGradient(
    colors: viewedRingGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient myStatusRingGradientShader = LinearGradient(
    colors: myStatusRingGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient giftGradientShader = LinearGradient(
    colors: giftGradient,
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient saveGradientShader = LinearGradient(
    colors: saveGradient,
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient likeGradientShader = LinearGradient(
    colors: likeGradient,
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient dmGradientShader = LinearGradient(
    colors: dmGradient,
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ===============================
  // SHADOWS
  // ===============================

  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0x40000000),
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  static const List<BoxShadow> textShadow = [
    BoxShadow(
      color: Color(0x80000000),
      offset: Offset(0, 1),
      blurRadius: 4,
    ),
  ];

  // ===============================
  // ANIMATIONS
  // ===============================

  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const Duration progressAnimationDuration = Duration(milliseconds: 50);

  static const Curve defaultAnimationCurve = Curves.easeInOut;
  static const Curve fastAnimationCurve = Curves.easeOut;

  // ===============================
  // HELPER METHODS
  // ===============================

  /// Create gradient for ring border based on view status
  static LinearGradient getRingGradient({
    required bool isViewed,
    required bool isMyStatus,
  }) {
    if (isMyStatus) return myStatusRingGradientShader;
    if (isViewed) return viewedRingGradientShader;
    return unviewedRingGradientShader;
  }

  /// Create gradient for interaction button
  static LinearGradient getInteractionGradient(String type) {
    switch (type) {
      case 'gift':
        return giftGradientShader;
      case 'save':
        return saveGradientShader;
      case 'like':
        return likeGradientShader;
      case 'dm':
        return dmGradientShader;
      default:
        return likeGradientShader;
    }
  }

  /// Create interaction button decoration
  static BoxDecoration getInteractionButtonDecoration(String type) {
    return BoxDecoration(
      gradient: getInteractionGradient(type),
      shape: BoxShape.circle,
      boxShadow: buttonShadow,
    );
  }

  /// Create text background gradient for text status
  static LinearGradient getTextBackgroundGradient(List<String> colors) {
    return LinearGradient(
      colors: colors.map((c) => _parseColor(c)).toList(),
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static Color _parseColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}

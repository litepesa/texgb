// ===============================
// Moments Feature Theme
// Light-based theme for feed, dark theme for media viewer
// ===============================

import 'package:flutter/material.dart';

class MomentsTheme {
  // ===============================
  // LIGHT THEME (Feed/Timeline)
  // ===============================

  static const Color lightBackground = Color(0xFFF7F7F7); // Light gray background
  static const Color lightSurface = Color(0xFFFFFFFF); // White cards
  static const Color lightDivider = Color(0xFFE5E5E5); // Subtle dividers
  static const Color lightBorder = Color(0xFFDDDDDD); // Borders

  // Text colors (light mode)
  static const Color lightTextPrimary = Color(0xFF1A1A1A); // Dark text
  static const Color lightTextSecondary = Color(0xFF666666); // Gray text
  static const Color lightTextTertiary = Color(0xFF999999); // Light gray text

  // Interactive colors
  static const Color primaryBlue = Color(0xFF576B95); // WeChat blue
  static const Color primaryBlueLight = Color(0xFF7D8FB3); // Lighter blue
  static const Color likeRed = Color(0xFFEB445A); // Like/heart color

  // Action colors
  static const Color commentColor = Color(0xFF888888);
  static const Color shareColor = Color(0xFF888888);

  // Status colors
  static const Color successGreen = Color(0xFF07C160); // WeChat green
  static const Color warningOrange = Color(0xFFFA9D3B);
  static const Color errorRed = Color(0xFFEB445A);

  // ===============================
  // DARK THEME (Media Viewer)
  // ===============================

  static const Color darkBackground = Color(0xFF000000); // Pure black
  static const Color darkSurface = Color(0xFF1A1A1A); // Dark gray
  static const Color darkDivider = Color(0xFF333333);

  // Text colors (dark mode)
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFCCCCCC);
  static const Color darkTextTertiary = Color(0xFF888888);

  // ===============================
  // COMPONENT STYLES
  // ===============================

  // Card style for moments
  static BoxDecoration momentCardDecoration = BoxDecoration(
    color: lightSurface,
    borderRadius: BorderRadius.circular(0),
    border: Border(
      bottom: BorderSide(color: lightDivider, width: 8),
    ),
  );

  // Image grid border radius
  static const double imageGridRadius = 4.0;
  static const double imageBorderRadius = 8.0;
  static const double imageGridSpacing = 4.0;

  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 12.0;
  static const double paddingLarge = 16.0;
  static const double paddingXLarge = 20.0;

  // Avatar sizes
  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeMedium = 40.0;
  static const double avatarSizeLarge = 60.0;

  // Icon sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeLarge = 24.0;

  // ===============================
  // TEXT STYLES
  // ===============================

  // User name
  static const TextStyle userNameStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: lightTextPrimary,
    height: 1.4,
  );

  // Content text
  static const TextStyle contentStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: lightTextPrimary,
    height: 1.6,
  );

  // Timestamp
  static const TextStyle timestampStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: lightTextTertiary,
  );

  // Comment text
  static const TextStyle commentStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: lightTextSecondary,
    height: 1.5,
  );

  // Comment author name
  static const TextStyle commentAuthorStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: primaryBlue,
  );

  // Interaction count
  static const TextStyle interactionCountStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: lightTextSecondary,
  );

  // Privacy label
  static const TextStyle privacyLabelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: lightTextTertiary,
  );

  // ===============================
  // BUTTON STYLES
  // ===============================

  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryBlue,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    ),
  );

  static ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primaryBlue,
    side: const BorderSide(color: primaryBlue, width: 1),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    ),
  );

  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryBlue,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  );

  // ===============================
  // SHADOWS
  // ===============================

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> modalShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // ===============================
  // THEME DATA
  // ===============================

  static ThemeData lightThemeData = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,
    cardColor: lightSurface,
    dividerColor: lightDivider,
    primaryColor: primaryBlue,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: successGreen,
      surface: lightSurface,
      error: errorRed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightSurface,
      foregroundColor: lightTextPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: lightTextPrimary,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: contentStyle,
      bodyMedium: commentStyle,
      titleMedium: userNameStyle,
      labelSmall: timestampStyle,
    ),
    iconTheme: const IconThemeData(
      color: lightTextSecondary,
      size: iconSizeMedium,
    ),
  );

  static ThemeData darkThemeData = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    cardColor: darkSurface,
    dividerColor: darkDivider,
    primaryColor: primaryBlue,
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      secondary: successGreen,
      surface: darkSurface,
      error: errorRed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      foregroundColor: darkTextPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    iconTheme: const IconThemeData(
      color: darkTextSecondary,
      size: iconSizeMedium,
    ),
  );
}

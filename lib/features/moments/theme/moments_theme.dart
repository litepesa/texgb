// ===============================
// Moments Feature Theme
// Facebook-inspired light theme (2025)
// Independent of app theme colors
// ===============================

import 'package:flutter/material.dart';

class MomentsTheme {
  // ===============================
  // FACEBOOK LIGHT THEME (2025)
  // ===============================

  // Main Background & Surface Colors
  static const Color lightBackground = Color(0xFFF0F2F5); // Athens Gray - Facebook background
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure white cards/posts
  static const Color lightDivider = Color(0xFFE4E6EB); // Facebook divider/border
  static const Color lightBorder = Color(0xFFE4E6EB); // Facebook borders

  // Text colors (Facebook standard)
  static const Color lightTextPrimary = Color(0xFF050505); // Near-black for main text
  static const Color lightTextSecondary = Color(0xFF65676B); // Mid-gray for metadata
  static const Color lightTextTertiary = Color(0xFF8A8D91); // Light gray for subtle info

  // Interactive colors (Facebook blue)
  static const Color primaryBlue = Color(0xFF1877F2); // Azure Radiance - Facebook blue
  static const Color primaryBlueLight = Color(0xFF4B93F1); // Lighter Facebook blue
  static const Color likeRed = Color(0xFFEB445A); // Like/heart color

  // Action colors
  static const Color commentColor = Color(0xFF65676B); // Match secondary text
  static const Color shareColor = Color(0xFF65676B); // Match secondary text

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
  // COMPONENT STYLES (Facebook-inspired)
  // ===============================

  // Card style for moments - Facebook uses subtle elevation
  static BoxDecoration momentCardDecoration = BoxDecoration(
    color: lightSurface,
    borderRadius: BorderRadius.circular(8), // Rounded corners like Facebook
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 1,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 2,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Image grid border radius
  static const double imageGridRadius = 4.0;
  static const double imageBorderRadius = 8.0;
  static const double imageGridSpacing = 4.0;

  // Spacing (Facebook-style)
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 12.0;
  static const double paddingLarge = 16.0;
  static const double paddingXLarge = 20.0;
  static const double cardSpacing = 12.0; // Space between cards

  // Avatar sizes (Facebook standard)
  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeMedium = 40.0;
  static const double avatarSizeLarge = 60.0;

  // Icon sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeLarge = 24.0;

  // ===============================
  // TEXT STYLES (Facebook-inspired)
  // ===============================

  // User name (bold, near-black)
  static const TextStyle userNameStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: lightTextPrimary,
    height: 1.3333,
  );

  // Content text (regular, near-black)
  static const TextStyle contentStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: lightTextPrimary,
    height: 1.3333,
    letterSpacing: 0,
  );

  // Timestamp (small, light gray)
  static const TextStyle timestampStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: lightTextSecondary,
    height: 1.2308,
  );

  // Comment text
  static const TextStyle commentStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: lightTextPrimary,
    height: 1.3571,
  );

  // Comment author name (Facebook blue)
  static const TextStyle commentAuthorStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: lightTextPrimary,
  );

  // Interaction count (mid-gray)
  static const TextStyle interactionCountStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: lightTextSecondary,
  );

  // Privacy label
  static const TextStyle privacyLabelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: lightTextSecondary,
  );

  // ===============================
  // BUTTON STYLES (Facebook-inspired)
  // ===============================

  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryBlue,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    ),
    textStyle: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
  );

  static ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: lightTextSecondary,
    backgroundColor: lightBackground,
    side: BorderSide.none,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    ),
    textStyle: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
  );

  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryBlue,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    textStyle: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
  );

  // ===============================
  // SHADOWS (Facebook-style subtle elevation)
  // ===============================

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 1,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 2,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> modalShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // ===============================
  // THEME DATA (Facebook-inspired)
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
      elevation: 0.5, // Subtle elevation like Facebook
      shadowColor: Colors.black12,
      centerTitle: false, // Left-aligned like Facebook
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: lightTextPrimary,
        letterSpacing: 0,
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

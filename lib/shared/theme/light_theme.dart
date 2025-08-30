import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'modern_colors.dart';
import 'theme_extensions.dart';

ThemeData modernLightTheme() {
  final ThemeData base = ThemeData.light();
  
  // Define font styles with Google Fonts
  final textTheme = _createTextTheme();
  
  // Light theme colors - modern and fresh
  const primaryGreen = Color(0xFF00A884);  // Slightly adjusted green
  const lightBackground = Color(0xFFF6F6F6); // Light gray background
  const lightSurface = Color(0xFFFFFFFF);   // Pure white surface
  const lightSurfaceVariant = Color(0xFFF0F0F0); // Light gray for surface variants
  const darkText = Color(0xFF121212);      // Nearly black text
  const secondaryText = Color(0xFF6A6A6A); // Dark gray secondary text
  const tertiaryText = Color(0xFF8E8E8E);  // Medium gray tertiary text
  
  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.light,
      primary: primaryGreen,
      secondary: const Color(0xFF128C7E), // Darker green for secondary
      background: lightBackground,
      surface: lightSurface,
      onBackground: darkText,
      onSurface: darkText,
      surfaceTint: Colors.transparent, // Disable surface tint in Material 3
    ),
    scaffoldBackgroundColor: lightBackground,
    
    // Extensions
    extensions: [
      const ModernThemeExtension(
        backgroundColor: lightBackground,
        surfaceColor: lightSurface,
        surfaceVariantColor: lightSurfaceVariant,
        appBarColor: lightSurface,
        textColor: darkText,
        textSecondaryColor: secondaryText,
        textTertiaryColor: tertiaryText,
        dividerColor: Color(0xFFE0E0E0),
        primaryColor: primaryGreen,
        secondaryColor: Color(0xFF128C7E),
        accentColor: primaryGreen,
        borderColor: Color(0xFFE0E0E0),
      ),
      ChatThemeExtension(
        chatBackgroundColor: const Color(0xFFE5DDD5), // Classic light chat background with subtle pattern
        senderBubbleColor: const Color(0xFFDCF8C6), // Light green sender bubble
        receiverBubbleColor: lightSurface,
        senderTextColor: darkText,
        receiverTextColor: darkText,
        systemMessageColor: lightSurfaceVariant,
        systemMessageTextColor: secondaryText,
        timestampColor: tertiaryText,
        inputBackgroundColor: lightSurface,
        senderBubbleRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(4),
        ),
        receiverBubbleRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(16),
        ),
      ),
      const ResponsiveThemeExtension(),
      const AnimationThemeExtension(),
    ],
    
    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: lightSurface,
      foregroundColor: darkText,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.05),
      surfaceTintColor: Colors.transparent, // Important - removes Material 3 tint
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: darkText,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Dark icons for light background
      ),
      iconTheme: const IconThemeData(
        color: primaryGreen,
        size: 24,
      ),
    ),
    
    // Text Theme
    textTheme: textTheme,
    
    // Bottom Navigation Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lightSurface,
      selectedItemColor: primaryGreen,
      unselectedItemColor: secondaryText,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 4, // Add shadow for depth
    ),
    
    // Tab Bar Theme
    tabBarTheme: const TabBarTheme(
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          color: primaryGreen,
          width: 2,
        ),
      ),
      labelColor: primaryGreen,
      unselectedLabelColor: secondaryText,
      unselectedLabelStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      labelStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    
    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 1, // Subtle elevation
        shadowColor: Colors.black.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryGreen,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side: const BorderSide(color: primaryGreen, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryGreen,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    // Card Theme
    cardTheme: CardTheme(
      color: lightSurface,
      elevation: 1, // Add subtle elevation
      shadowColor: Colors.black.withOpacity(0.1),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    ),
    
    // Modal and Dialog Themes
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: lightSurface,
      modalBackgroundColor: lightSurface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 8, // Add more elevation for bottom sheets
      shadowColor: Colors.black.withOpacity(0.1),
    ),
    
    dialogBackgroundColor: lightSurface,
    dialogTheme: DialogTheme(
      backgroundColor: lightSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4, // Add elevation for dialogs
      shadowColor: Colors.black.withOpacity(0.1),
      titleTextStyle: const TextStyle(
        color: darkText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: const TextStyle(
        color: darkText,
        fontSize: 16,
      ),
    ),
    
    // FAB Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 2,
      highlightElevation: 4,
      splashColor: Colors.white.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    // List Tile Theme
    listTileTheme: ListTileThemeData(
      iconColor: secondaryText,
      textColor: darkText,
      tileColor: lightSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      minLeadingWidth: 20,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      selectedTileColor: primaryGreen.withOpacity(0.1),
      selectedColor: primaryGreen,
    ),
    
    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryGreen;
        }
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryGreen.withOpacity(0.3);
        }
        return Colors.grey.withOpacity(0.3);
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.transparent;
        }
        return Colors.transparent;
      }),
    ),
    
    // Checkbox Theme
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryGreen;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.resolveWith((states) {
        return Colors.white;
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      side: const BorderSide(
        color: secondaryText,
        width: 1.5,
      ),
    ),
    
    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0E0E0),
      thickness: 1,
      indent: 16,
      endIndent: 16,
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: secondaryText,
      size: 24,
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: ModernColors.error, width: 1.5),
      ),
      hintStyle: const TextStyle(color: tertiaryText),
      labelStyle: const TextStyle(color: secondaryText),
      helperStyle: const TextStyle(color: tertiaryText, fontSize: 12),
      errorStyle: const TextStyle(color: ModernColors.error, fontSize: 12),
      prefixIconColor: secondaryText,
      suffixIconColor: secondaryText,
    ),
    
    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: lightSurfaceVariant,
      disabledColor: lightSurfaceVariant.withOpacity(0.5),
      selectedColor: primaryGreen.withOpacity(0.2),
      secondarySelectedColor: primaryGreen,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: const TextStyle(
        color: darkText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
    ),
    
    // Slider Theme
    sliderTheme: const SliderThemeData(
      activeTrackColor: primaryGreen,
      inactiveTrackColor: Color(0xFFDCDCDC),
      thumbColor: primaryGreen,
      overlayColor: Color(0x2925D366),
      trackHeight: 4.0,
    ),
    
    // Progress Indicator Theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryGreen,
      circularTrackColor: Color(0xFFE0E0E0),
      linearTrackColor: Color(0xFFE0E0E0),
    ),
    
    // Page Transitions Theme
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    
    // Snack Bar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF303030),
      contentTextStyle: const TextStyle(color: Colors.white),
      actionTextColor: primaryGreen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    
    // Banner Theme
    bannerTheme: const MaterialBannerThemeData(
      backgroundColor: lightSurfaceVariant,
      contentTextStyle: TextStyle(color: darkText),
      padding: EdgeInsets.all(16),
    ),
    
    // Bottom App Bar Theme
    bottomAppBarTheme: BottomAppBarTheme(
      color: lightSurface,
      elevation: 2, // Add subtle elevation
      shadowColor: Colors.black.withOpacity(0.1),
      surfaceTintColor: Colors.transparent,
      shape: const CircularNotchedRectangle(),
    ),
  );
}

TextTheme _createTextTheme() {
  const darkText = Color(0xFF121212);
  const secondaryText = Color(0xFF6A6A6A);
  
  return TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 57, 
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      color: darkText,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 45, 
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: darkText,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 36, 
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: darkText,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: 32, 
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: darkText,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 28, 
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: darkText,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 24, 
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: darkText,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 22, 
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: darkText,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16, 
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      color: darkText,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14, 
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: darkText,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16, 
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      color: darkText,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14, 
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: darkText,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12, 
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      color: secondaryText,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14, 
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: darkText,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12, 
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: darkText,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11, 
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: secondaryText,
    ),
  );
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'modern_colors.dart';
import 'theme_extensions.dart';

ThemeData modernDarkTheme() {
  final ThemeData base = ThemeData.dark();
  
  // Define font styles with Google Fonts
  final textTheme = _createTextTheme();
  
  // WhatsApp Messenger dark theme colors
  const newPrimaryGreen = Color(0xFF00A884);  // WhatsApp green dark
  const newBackground = Color(0xFF111B21);    // WhatsApp dark background
  const newSurface = Color(0xFF202C33);       // WhatsApp grey background
  const pureWhite = Colors.white;             // Pure white for text
  
  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: newPrimaryGreen,
      brightness: Brightness.dark,
      primary: newPrimaryGreen,
      secondary: ModernColors.accentBlue,
      background: newBackground,
      surface: newSurface,
      surfaceTint: Colors.transparent, // Disable surface tint in Material 3
    ),
    scaffoldBackgroundColor: newBackground,
    
    // Extensions
    extensions: [
      ModernThemeExtension.darkMode,
      ChatThemeExtension.darkMode,
      const ResponsiveThemeExtension(),
      const AnimationThemeExtension(),
      WhatsAppThemeExtension.darkMode,
    ],
    
    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: newSurface,
      foregroundColor: pureWhite,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent, // Important - removes Material 3 tint
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: pureWhite,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      iconTheme: const IconThemeData(
        color: newPrimaryGreen,
        size: 24,
      ),
    ),
    
    // Text Theme
    textTheme: textTheme.apply(
      bodyColor: pureWhite,
      displayColor: pureWhite,
    ),
    
    // Bottom Navigation Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: newSurface,
      selectedItemColor: newPrimaryGreen,
      unselectedItemColor: Color(0xFF8696A0), // WhatsApp grey dark
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    
    // Tab Bar Theme
    tabBarTheme: const TabBarTheme(
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          color: newPrimaryGreen,
          width: 2,
        ),
      ),
      unselectedLabelColor: Color(0xFF8696A0), // WhatsApp grey dark
      labelColor: newPrimaryGreen,
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
        backgroundColor: newPrimaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
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
        foregroundColor: newPrimaryGreen,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side: const BorderSide(color: newPrimaryGreen, width: 1.5),
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
        foregroundColor: newPrimaryGreen,
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
      color: newSurface,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    ),
    
    // Modal and Dialog Themes
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: newSurface,
      modalBackgroundColor: newSurface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shadowColor: Colors.transparent,
    ),
    
    dialogBackgroundColor: newSurface,
    dialogTheme: DialogTheme(
      backgroundColor: newSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      titleTextStyle: const TextStyle(
        color: pureWhite,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: const TextStyle(
        color: pureWhite,
        fontSize: 16,
      ),
    ),
    
    // FAB Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: newPrimaryGreen,
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
      iconColor: const Color(0xFF8696A0), // WhatsApp grey dark
      textColor: pureWhite,
      tileColor: newSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      minLeadingWidth: 20,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      selectedTileColor: newPrimaryGreen.withOpacity(0.15),
      selectedColor: newPrimaryGreen,
    ),
    
    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return newPrimaryGreen;
        }
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return newPrimaryGreen.withOpacity(0.3);
        }
        return const Color(0xFF8696A0).withOpacity(0.3); // WhatsApp grey dark
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
          return newPrimaryGreen;
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
        color: Color(0xFF8696A0), // WhatsApp grey dark
        width: 1.5,
      ),
    ),
    
    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: Color(0xFF2A3942), // WhatsApp dark divider
      thickness: 1,
      indent: 16,
      endIndent: 16,
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: Color(0xFF8696A0), // WhatsApp grey dark
      size: 24,
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: newSurface, // WhatsApp grey background
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
        borderSide: const BorderSide(color: newPrimaryGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: ModernColors.error, width: 1.5),
      ),
      hintStyle: const TextStyle(color: Color(0xFF667781)), // WhatsApp grey light
      labelStyle: const TextStyle(color: Color(0xFF8696A0)), // WhatsApp grey dark
      helperStyle: const TextStyle(color: Color(0xFF667781), fontSize: 12),
      errorStyle: const TextStyle(color: ModernColors.error, fontSize: 12),
      prefixIconColor: const Color(0xFF8696A0), // WhatsApp grey dark
      suffixIconColor: const Color(0xFF8696A0), // WhatsApp grey dark
    ),
    
    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: newSurface, // WhatsApp grey background
      disabledColor: newSurface.withOpacity(0.5),
      selectedColor: newPrimaryGreen.withOpacity(0.3),
      secondarySelectedColor: newPrimaryGreen,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: const TextStyle(
        color: pureWhite,
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
      activeTrackColor: newPrimaryGreen,
      inactiveTrackColor: Color(0xFF2A3942), // WhatsApp dark divider
      thumbColor: newPrimaryGreen,
      overlayColor: Color(0x2900A884), // WhatsApp green with opacity
      trackHeight: 4.0,
    ),

    // Progress Indicator Theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: newPrimaryGreen,
      circularTrackColor: newSurface, // WhatsApp grey background
      linearTrackColor: newSurface,
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
      backgroundColor: newSurface, // WhatsApp grey background
      contentTextStyle: const TextStyle(color: pureWhite),
      actionTextColor: newPrimaryGreen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // Banner Theme
    bannerTheme: MaterialBannerThemeData(
      backgroundColor: newSurface, // WhatsApp grey background
      contentTextStyle: const TextStyle(color: pureWhite),
      padding: const EdgeInsets.all(16),
    ),
    
    // Bottom App Bar Theme
    bottomAppBarTheme: const BottomAppBarTheme(
      color: newSurface,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: CircularNotchedRectangle(),
    ),
  );
}

TextTheme _createTextTheme() {
  const pureWhite = Colors.white;
  const secondaryText = Color(0xFF8696A0); // WhatsApp grey dark
  
  return TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 57, 
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      color: pureWhite,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 45, 
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: pureWhite,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 36, 
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: pureWhite,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: 32, 
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: pureWhite,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 28, 
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: pureWhite,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 24, 
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: pureWhite,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 22, 
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: pureWhite,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16, 
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      color: pureWhite,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14, 
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: pureWhite,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16, 
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      color: pureWhite,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14, 
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: pureWhite,
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
      color: pureWhite,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12, 
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: pureWhite,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11, 
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: secondaryText,
    ),
  );
}
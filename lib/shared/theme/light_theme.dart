import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'modern_colors.dart';
import 'theme_extensions.dart';

ThemeData modernLightTheme() {
  final ThemeData base = ThemeData.light();
  
  // Define font styles with Google Fonts
  final textTheme = _createTextTheme();
  
  // Updated colors for better visibility and contrast
  const newPrimaryGreen = Color(0xFF1E9E1E);  // More vibrant green for better visibility
  const newBackground = Color(0xFFF8F7F2);    // Slightly darker off-white background
  const newSurface = Color(0xFFFFFFFF);       // Pure white surface for better contrast
  const darkText = Color(0xFF121212);         // Nearly black text
  
  return base.copyWith(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: newPrimaryGreen,
      brightness: Brightness.light,
      primary: newPrimaryGreen,
      secondary: ModernColors.accentTealBlue,
      background: newBackground,
      surface: newSurface,
      surfaceTint: Colors.transparent, // Disable surface tint in Material 3
    ),
    scaffoldBackgroundColor: newBackground,
    
    // Extensions
    extensions: [
      ModernThemeExtension.lightMode,
      ChatThemeExtension.lightMode,
      const ResponsiveThemeExtension(),
      const AnimationThemeExtension(),
    ],
    
    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: newSurface,
      foregroundColor: darkText,
      elevation: 1, // Very subtle elevation
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
        statusBarIconBrightness: Brightness.dark,
      ),
      iconTheme: const IconThemeData(
        color: newPrimaryGreen,
        size: 24,
      ),
    ),
    
    // Text Theme
    textTheme: textTheme,
    
    // Bottom Navigation Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: newSurface,
      selectedItemColor: newPrimaryGreen,
      unselectedItemColor: Color(0xFF555555), // Darker for better contrast
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 2, // Add subtle shadow for depth
    ),
    
    // Tab Bar Theme
    tabBarTheme: const TabBarTheme(
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          color: newPrimaryGreen,
          width: 2,
        ),
      ),
      unselectedLabelColor: Color(0xFF303030), // Darker for better contrast
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
      elevation: 1, // Add subtle elevation
      shadowColor: Colors.black.withOpacity(0.1),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: const Color(0xFFE8E8E8), width: 1), // Slightly darker border
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
      elevation: 8, // Add more elevation for bottom sheets
      shadowColor: Colors.black.withOpacity(0.1),
    ),
    
    dialogBackgroundColor: newSurface,
    dialogTheme: DialogTheme(
      backgroundColor: newSurface,
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
      iconColor: const Color(0xFF303030), // Darker for better contrast
      textColor: darkText,
      tileColor: newSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      minLeadingWidth: 20,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      selectedTileColor: newPrimaryGreen.withOpacity(0.1), // More visible selection
      selectedColor: newPrimaryGreen,
    ),
    
    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return newPrimaryGreen;
        }
        return Colors.white;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return newPrimaryGreen.withOpacity(0.3);
        }
        return const Color(0xFF555555).withOpacity(0.3); // Darker for better contrast
      }),
      trackOutlineColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.transparent;
        }
        return Colors.transparent;
      }),
    ),
    
    // Checkbox Theme
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return newPrimaryGreen;
        }
        return Colors.transparent;
      }),
      checkColor: MaterialStateProperty.resolveWith((states) {
        return Colors.white;
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      side: const BorderSide(
        color: Color(0xFF555555), // Darker for better contrast
        width: 1.5,
      ),
    ),
    
    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: Color(0xFFD8D8D8), // Darker dividers for better visibility
      thickness: 1,
      indent: 16,
      endIndent: 16,
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: Color(0xFF303030), // Darker for better contrast
      size: 24,
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFEAE9E3), // Darker input background for better visibility
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
      hintStyle: const TextStyle(color: Color(0xFF666666)), // Darker hints
      labelStyle: const TextStyle(color: Color(0xFF303030)), // Darker labels
      helperStyle: const TextStyle(color: Color(0xFF666666), fontSize: 12), // Darker helper text
      errorStyle: const TextStyle(color: ModernColors.error, fontSize: 12),
      prefixIconColor: const Color(0xFF303030), // Darker icons
      suffixIconColor: const Color(0xFF303030), // Darker icons
    ),
    
    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFEAE9E3), // Darker chip background
      disabledColor: const Color(0xFFEAE9E3).withOpacity(0.5),
      selectedColor: newPrimaryGreen.withOpacity(0.2),
      secondarySelectedColor: newPrimaryGreen,
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
      activeTrackColor: newPrimaryGreen,
      inactiveTrackColor: Color(0xFF999999), // Darker track for better visibility
      thumbColor: newPrimaryGreen,
      overlayColor: Color(0x291E9E1E),
      trackHeight: 4.0,
    ),
    
    // Progress Indicator Theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: newPrimaryGreen,
      circularTrackColor: Color(0xFFEAE9E3), // Darker track for better visibility
      linearTrackColor: Color(0xFFEAE9E3), // Darker track for better visibility
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
      backgroundColor: const Color(0xFF303030), // Darker background for better contrast
      contentTextStyle: const TextStyle(color: Colors.white),
      actionTextColor: ModernColors.primaryGreen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    
    // Banner Theme
    bannerTheme: const MaterialBannerThemeData(
      backgroundColor: Color(0xFFEAE9E3), // Darker banner background
      contentTextStyle: TextStyle(color: darkText),
      padding: EdgeInsets.all(16),
    ),
    
    // Bottom App Bar Theme
    bottomAppBarTheme: BottomAppBarTheme(
      color: newSurface,
      elevation: 2, // Add subtle elevation
      shadowColor: Colors.black.withOpacity(0.1),
      surfaceTintColor: Colors.transparent,
      shape: const CircularNotchedRectangle(),
    ),
  );
}

TextTheme _createTextTheme() {
  const darkText = Color(0xFF121212);
  const secondaryText = Color(0xFF303030);  // Darker for better contrast
  
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
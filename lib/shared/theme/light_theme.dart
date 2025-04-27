import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'modern_colors.dart';
import 'theme_extensions.dart';

ThemeData modernLightTheme() {
  final ThemeData base = ThemeData.light();
  
  // Define font styles with Google Fonts
  final textTheme = _createTextTheme();
  
  // New color scheme using the provided colors
  const newBackground = Color(0xFF131C21);      // Dark background
  const newSurface = Color(0xFF1F2C34);         // Surface color
  const newAccent = Color(0xFF00A783);          // Accent green
  const newSurfaceVariant = Color(0xFF252D31);  // Surface variant
  const lightText = Color(0xFFF1F1F2);          // Light text color
  const secondaryText = Colors.grey;            // Secondary text
  
  return base.copyWith(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: newAccent,
      brightness: Brightness.light,
      primary: newAccent,
      secondary: const Color(0xFF056062),
      background: newBackground,
      surface: newSurface,
      onBackground: lightText,
      onSurface: lightText,
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
      backgroundColor: const Color(0xFF1F2C34),
      foregroundColor: lightText,
      elevation: 1, // Very subtle elevation
      shadowColor: Colors.black.withOpacity(0.05),
      surfaceTintColor: Colors.transparent, // Important - removes Material 3 tint
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: lightText,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Changed to light for dark background
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF00A783),
        size: 24,
      ),
    ),
    
    // Text Theme
    textTheme: textTheme,
    
    // Bottom Navigation Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1F2C34),
      selectedItemColor: Color(0xFF00A783),
      unselectedItemColor: Colors.grey,
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
          color: Color(0xFF00A783),
          width: 2,
        ),
      ),
      unselectedLabelColor: Colors.grey,
      labelColor: Color(0xFF00A783),
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
        backgroundColor: const Color(0xFF00A783),
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
        foregroundColor: const Color(0xFF00A783),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side: const BorderSide(color: Color(0xFF00A783), width: 1.5),
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
        foregroundColor: const Color(0xFF00A783),
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
      color: const Color(0xFF1F2C34),
      elevation: 1, // Add subtle elevation
      shadowColor: Colors.black.withOpacity(0.1),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF323739), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    ),
    
    // Modal and Dialog Themes
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: const Color(0xFF1F2C34),
      modalBackgroundColor: const Color(0xFF1F2C34),
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
    
    dialogBackgroundColor: const Color(0xFF1F2C34),
    dialogTheme: DialogTheme(
      backgroundColor: const Color(0xFF1F2C34),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4, // Add elevation for dialogs
      shadowColor: Colors.black.withOpacity(0.1),
      titleTextStyle: TextStyle(
        color: lightText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(
        color: lightText,
        fontSize: 16,
      ),
    ),
    
    // FAB Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF00A783),
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
      iconColor: Colors.grey,
      textColor: lightText,
      tileColor: const Color(0xFF1F2C34),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      minLeadingWidth: 20,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      selectedTileColor: const Color(0xFF00A783).withOpacity(0.1),
      selectedColor: const Color(0xFF00A783),
    ),
    
    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const Color(0xFF00A783);
        }
        return Colors.white;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const Color(0xFF00A783).withOpacity(0.3);
        }
        return Colors.grey.withOpacity(0.3);
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
          return const Color(0xFF00A783);
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
        color: Colors.grey,
        width: 1.5,
      ),
    ),
    
    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: Color(0xFF323739),
      thickness: 1,
      indent: 16,
      endIndent: 16,
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: Colors.grey,
      size: 24,
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF252D31),
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
        borderSide: const BorderSide(color: Color(0xFF00A783), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: ModernColors.error, width: 1.5),
      ),
      hintStyle: const TextStyle(color: Colors.grey),
      labelStyle: TextStyle(color: lightText),
      helperStyle: const TextStyle(color: Colors.grey, fontSize: 12),
      errorStyle: const TextStyle(color: ModernColors.error, fontSize: 12),
      prefixIconColor: Colors.grey,
      suffixIconColor: Colors.grey,
    ),
    
    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF252D31),
      disabledColor: const Color(0xFF252D31).withOpacity(0.5),
      selectedColor: const Color(0xFF00A783).withOpacity(0.2),
      secondarySelectedColor: const Color(0xFF00A783),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: TextStyle(
        color: lightText,
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
      activeTrackColor: Color(0xFF00A783),
      inactiveTrackColor: Colors.grey,
      thumbColor: Color(0xFF00A783),
      overlayColor: Color(0x2900A783),
      trackHeight: 4.0,
    ),
    
    // Progress Indicator Theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xFF00A783),
      circularTrackColor: Color(0xFF252D31),
      linearTrackColor: Color(0xFF252D31),
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
      backgroundColor: const Color(0xFF252D32),
      contentTextStyle: const TextStyle(color: Colors.white),
      actionTextColor: const Color(0xFF00A783),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    
    // Banner Theme
    bannerTheme: MaterialBannerThemeData(
      backgroundColor: const Color(0xFF252D31),
      contentTextStyle: TextStyle(color: lightText),
      padding: const EdgeInsets.all(16),
    ),
    
    // Bottom App Bar Theme
    bottomAppBarTheme: BottomAppBarTheme(
      color: const Color(0xFF1F2C34),
      elevation: 2, // Add subtle elevation
      shadowColor: Colors.black.withOpacity(0.1),
      surfaceTintColor: Colors.transparent,
      shape: const CircularNotchedRectangle(),
    ),
  );
}

TextTheme _createTextTheme() {
  const lightText = Color(0xFFF1F1F2);
  const secondaryText = Colors.grey;
  
  return TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 57, 
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      color: lightText,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 45, 
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: lightText,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 36, 
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: lightText,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: 32, 
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: lightText,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 28, 
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: lightText,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 24, 
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: lightText,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 22, 
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: lightText,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16, 
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      color: lightText,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14, 
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: lightText,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16, 
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      color: lightText,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14, 
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: lightText,
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
      color: lightText,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12, 
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: lightText,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11, 
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: secondaryText,
    ),
  );
}